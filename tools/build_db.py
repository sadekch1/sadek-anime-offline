#!/usr/bin/env python3
"""Builds assets/db/anime.db from manami-project/anime-offline-database.

Usage: python tools/build_db.py [path/to/local.json]
Fails soft: if the download fails, the placeholder DB is kept and the app
falls back to the Jikan API at runtime.

Synopsis preload (build time, no per-title Jikan calls):
  * English synopsis for ALL titles via AniList GraphQL, in batches of 50
    MAL ids per query. A batch/title that fails after retries simply stays
    without a synopsis; the build never aborts for this.
  * Arabic synopsis/title via TMDB, only when TMDB_API_KEY is set in the
    environment. To keep CI time sane, TMDB is only attempted for titles
    with score >= 7.0 OR type MOVIE with score >= 6.5 OR year >= 2015.
"""
import json, os, re, sqlite3, sys, time, urllib.request, urllib.error, urllib.parse

URLS = [
    "https://github.com/manami-project/anime-offline-database/releases/latest/download/anime-offline-database-minified.json",
    "https://raw.githubusercontent.com/manami-project/anime-offline-database/master/anime-offline-database-minified.json",
]
OUT = os.path.join(os.path.dirname(__file__), "..", "assets", "db", "anime.db")
MAIN = {"action","adventure","comedy","drama","fantasy","horror","mystery","romance",
    "sci-fi","slice of life","sports","supernatural","thriller","psychological","mecha",
    "music","school","historical","military","magic","martial arts","shounen","shoujo",
    "seinen","josei","isekai","ecchi","harem","super power","vampire","demons","space",
    "police","parody","samurai","kids","gourmet","suspense","game","war","crime"}
MAL = re.compile(r"myanimelist\.net/anime/(\d+)")
ARABIC_RE = re.compile(r"[\u0600-\u06FF]")

ANILIST_URL = "https://graphql.anilist.co"
ANILIST_QUERY = """query($ids:[Int]){Page(perPage:50){media(idMal_in:$ids,type:ANIME){idMal description(asHtml:false)}}}"""
TMDB_BASE = "https://api.themoviedb.org/3"


def load():
    if len(sys.argv) > 1:
        with open(sys.argv[1], encoding="utf-8") as f:
            return json.load(f)
    for url in URLS:
        try:
            print("Downloading", url)
            req = urllib.request.Request(url, headers={"User-Agent": "sadek-anime-offline"})
            with urllib.request.urlopen(req, timeout=120) as r:
                return json.loads(r.read().decode("utf-8"))
        except Exception as e:
            print("  failed:", e)
    return None

def score_of(e):
    s = e.get("score")
    if isinstance(s, dict):
        s = s.get("arithmeticMean") or s.get("arithmeticGeometricMean") or s.get("median")
    return round(float(s), 2) if isinstance(s, (int, float)) and s > 0 else None


def clean_anilist_description(text):
    """Strip HTML tags from an AniList description (<br> -> newline)."""
    if not text:
        return ""
    text = re.sub(r"(?i)<br\s*/?>", "\n", text)
    text = re.sub(r"<[^>]+>", "", text)
    text = re.sub(r"\n{3,}", "\n\n", text)
    return text.strip()


def _anilist_post(payload):
    data = json.dumps(payload).encode("utf-8")
    req = urllib.request.Request(
        ANILIST_URL, data=data,
        headers={"User-Agent": "sadek-anime-offline",
                 "Content-Type": "application/json",
                 "Accept": "application/json"},
        method="POST")
    with urllib.request.urlopen(req, timeout=30) as r:
        return json.loads(r.read().decode("utf-8"))


def fetch_anilist_synopses(mal_ids, budget_seconds=1500):
    """Fetch English synopses from AniList for MAL ids, in batches of 50.

    Returns dict[int, str] (only ids that returned a non-empty description).
    Soft-fails: a batch that fails after retries is skipped, never raises.

    Safeguards (AniList can hang/time out from some datacenter IPs — seen
    live in 2026-11-08 testing, where POSTs timed out even though the site
    itself loads): a global time budget (default 25 min) and an abort after
    3 consecutive failed batches, so a blocked/slow AniList can never make
    the CI build grind for hours. Whatever was fetched is kept.
    """
    ids = sorted({int(i) for i in mal_ids if i})
    result = {}
    if not ids:
        return result
    total_batches = (len(ids) + 49) // 50
    deadline = time.time() + budget_seconds
    consecutive_failures = 0
    for bi in range(total_batches):
        if time.time() > deadline:
            print(f"AniList: time budget ({budget_seconds}s) reached, stopping with {len(result)} synopses")
            break
        batch = ids[bi * 50:(bi + 1) * 50]
        payload = {"query": ANILIST_QUERY, "variables": {"ids": batch}}
        data = None
        # Retry up to 2 attempts total, backoff 2s.
        for attempt in range(2):
            try:
                data = _anilist_post(payload)
                break
            except Exception as e:
                print(f"  AniList batch {bi + 1}/{total_batches} attempt {attempt + 1} failed: {e}")
                if attempt < 1:
                    time.sleep(2)
        if data is None:
            consecutive_failures += 1
            if consecutive_failures >= 3:
                print("AniList: 3 consecutive batches failed, aborting AniList fetch "
                      f"with {len(result)} synopses (app falls back to on-demand fetch)")
                break
            continue
        consecutive_failures = 0
        if data:
            try:
                for m in (data.get("data") or {}).get("Page", {}).get("media") or []:
                    mid = m.get("idMal")
                    desc = clean_anilist_description(m.get("description") or "")
                    if mid and desc:
                        result[int(mid)] = desc
            except Exception as e:
                print(f"  AniList batch {bi + 1}/{total_batches} parse failed: {e}")
        if (bi + 1) % 10 == 0 or bi + 1 == total_batches:
            print(f"AniList: {len(result)}/{len(ids)} synopses ({bi + 1}/{total_batches} batches)")
        if bi + 1 < total_batches:
            time.sleep(0.7)  # AniList rate limit ~90/min
    return result


def tmdb_eligible(score, media_type, year):
    """TMDB is only attempted for: score >= 7.0, or MOVIE with score >= 6.5,
    or year >= 2015. (Keeps CI time sane; the rest keep English only.)"""
    if score is not None and score >= 7.0:
        return True
    if media_type == "MOVIE" and score is not None and score >= 6.5:
        return True
    if year is not None and year >= 2015:
        return True
    return False


def _tmdb_get(url):
    """GET a TMDB URL; retry once on 429/5xx after a 3s wait. Returns parsed JSON or None."""
    req = urllib.request.Request(url, headers={"User-Agent": "sadek-anime-offline"})
    try:
        with urllib.request.urlopen(req, timeout=30) as r:
            return json.loads(r.read().decode("utf-8"))
    except urllib.error.HTTPError as e:
        if e.code in (429, 500, 502, 503, 504):
            time.sleep(3)
            try:
                with urllib.request.urlopen(req, timeout=30) as r:
                    return json.loads(r.read().decode("utf-8"))
            except Exception as e2:
                print(f"  TMDB retry failed: {e2}")
                return None
        return None
    except Exception as e:
        print(f"  TMDB request failed: {e}")
        return None


def fetch_tmdb_arabic(title, media_type, year, api_key=None):
    """Look up one title on TMDB (Arabic). Returns (title_ar, synopsis_ar).

    title_ar is set only if the TMDB name is Arabic; synopsis_ar only if the
    overview contains Arabic chars. Returns (None, None) with no key, on
    no match, or on any failure -- never raises.
    """
    if not api_key or not title:
        return (None, None)
    is_movie = (media_type == "MOVIE")
    endpoint = "/search/movie" if is_movie else "/search/tv"
    params = {"api_key": api_key, "query": title, "language": "ar", "page": 1}
    url = TMDB_BASE + endpoint + "?" + urllib.parse.urlencode(params)
    try:
        data = _tmdb_get(url)
    except Exception:
        return (None, None)
    if not data:
        return (None, None)
    for cand in data.get("results") or []:
        # Must be animation, Japanese original.
        if 16 not in (cand.get("genre_ids") or []):
            continue
        if cand.get("original_language") != "ja":
            continue
        # Year check: movies within 1 year; TV not more than 1 year after.
        date_str = cand.get("release_date") or cand.get("first_air_date") or ""
        cand_year = None
        if date_str and len(date_str) >= 4 and date_str[:4].isdigit():
            cand_year = int(date_str[:4])
        if year is not None and cand_year is not None:
            if is_movie:
                if abs(cand_year - year) > 1:
                    continue
            else:
                if cand_year > year + 1:
                    continue
        overview = (cand.get("overview") or "").strip()
        if not overview or not ARABIC_RE.search(overview):
            continue
        name = (cand.get("title") or cand.get("name") or "").strip()
        title_ar = name if name and ARABIC_RE.search(name) else None
        return (title_ar, overview)
    return (None, None)


def enrich_with_tmdb(rows, api_key=None):
    """Fill title_ar/synopsis_ar/ar_checked on eligible rows (list of lists).

    Row layout (see main): index 1=title, 4=type, 7=year, 9=score, 12=synopsis,
    15=detailed, 16=title_ar, 17=synopsis_ar, 18=ar_checked. Returns (attempted, with_arabic).
    With no key, prints the skip message and returns (0, 0).
    """
    if not api_key:
        print("TMDB: no key, skipping Arabic synopses")
        return (0, 0)
    attempted = 0
    with_arabic = 0
    for row in rows:
        title, media_type, year, score = row[1], row[4], row[7], row[9]
        if not tmdb_eligible(score, media_type, year):
            continue
        attempted += 1
        title_ar, syn_ar = fetch_tmdb_arabic(title, media_type, year, api_key)
        row[18] = 1  # ar_checked: TMDB was attempted for this title
        if syn_ar:
            row[16] = title_ar
            row[17] = syn_ar
            with_arabic += 1
        if attempted % 100 == 0:
            print(f"TMDB: {attempted} attempted, {with_arabic} with Arabic synopsis")
        time.sleep(0.25)  # pause between TMDB calls
    print(f"TMDB: {attempted} attempted, {with_arabic} with Arabic synopsis")
    return (attempted, with_arabic)


def main():
    raw = load()
    if not raw:
        print("WARNING: could not build database; keeping placeholder (app will use Jikan).")
        return 0
    items = raw.get("data", raw) if isinstance(raw, dict) else raw

    if os.path.exists(OUT):
        os.remove(OUT)
    db = sqlite3.connect(OUT)
    # NOTE: title_ar / synopsis_ar / ar_checked were NOT in the original
    # schema; they are added here (synopsis preload, see module docstring).
    db.executescript("""
    CREATE TABLE anime(
      mal_id INTEGER PRIMARY KEY, title TEXT NOT NULL, title_en TEXT,
      search TEXT NOT NULL, type TEXT, episodes INTEGER, status TEXT,
      year INTEGER, season TEXT, score REAL, genres TEXT, studios TEXT,
      synopsis TEXT, image_url TEXT, thumb_url TEXT,
      detailed INTEGER NOT NULL DEFAULT 0,
      title_ar TEXT, synopsis_ar TEXT, ar_checked INTEGER NOT NULL DEFAULT 0);
    CREATE TABLE characters(
      anime_id INTEGER NOT NULL, char_id INTEGER NOT NULL, name TEXT NOT NULL,
      role TEXT, image_url TEXT, PRIMARY KEY(anime_id, char_id));
    """)
    rows = []
    for e in items:
        m = next((MAL.search(s) for s in e.get("sources", []) if MAL.search(s)), None)
        title = e.get("title")
        if not m or not title:
            continue
        season = e.get("animeSeason") or {}
        year = season.get("year") or None
        studios = e.get("studios") or []
        studios = [(s if isinstance(s, str) else s.get("name", "")).title() for s in studios]
        raw = e.get("tags") or []
        chosen = [t for t in raw if t.lower() in MAIN][:6] or raw[:3]
        tags = [t.title() for t in chosen]
        syn = " ".join(e.get("synonyms") or [])
        rows.append([
            int(m.group(1)), title, None, f"{title} {syn}".lower(),
            e.get("type"), e.get("episodes") or None, e.get("status"),
            year, (season.get("season") if season.get("season") != "UNDEFINED" else None),
            score_of(e), "|".join(tags), "|".join(s for s in studios if s),
            None, e.get("picture"), e.get("thumbnail"), 0,
            None, None, 0,
        ])
    # English synopses for all titles via AniList (soft-fail, never aborts).
    mal_ids = [r[0] for r in rows]
    synopses = fetch_anilist_synopses(mal_ids)
    n_en = 0
    for r in rows:
        s = synopses.get(r[0])
        if s:
            r[12] = s  # synopsis
            r[15] = 1  # detailed=1 where a synopsis was found
            n_en += 1
    # Arabic synopses/titles via TMDB when a key is present (skips otherwise).
    _, n_ar = enrich_with_tmdb(rows, api_key=os.environ.get("TMDB_API_KEY") or None)
    db.executemany("INSERT OR REPLACE INTO anime VALUES (?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?)", rows)
    db.executescript("""
    CREATE INDEX idx_anime_search ON anime(search);
    CREATE INDEX idx_anime_score ON anime(score DESC);
    CREATE INDEX idx_anime_status ON anime(status, score);
    PRAGMA user_version = 1;
    """)
    db.commit()
    db.execute("VACUUM")
    db.close()
    print(f"Built {len(rows)} anime ({n_en} with English synopsis, {n_ar} with Arabic synopsis) -> {os.path.getsize(OUT)/1e6:.1f} MB")
    return 0

if __name__ == "__main__":
    sys.exit(main())
