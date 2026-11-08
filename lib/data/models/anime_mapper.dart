import '../../domain/entities/anime.dart';

List<String> _split(String? s) =>
    (s == null || s.isEmpty) ? const [] : s.split('|');

Anime animeFromRow(Map<String, Object?> r) => Anime(
      malId: r['mal_id'] as int,
      title: r['title'] as String,
      titleEn: r['title_en'] as String?,
      titleAr: r['title_ar'] as String?,
      type: r['type'] as String?,
      episodes: r['episodes'] as int?,
      status: r['status'] as String?,
      year: r['year'] as int?,
      season: r['season'] as String?,
      score: (r['score'] as num?)?.toDouble(),
      genres: _split(r['genres'] as String?),
      studios: _split(r['studios'] as String?),
      synopsis: r['synopsis'] as String?,
      synopsisAr: r['synopsis_ar'] as String?,
      imageUrl: r['image_url'] as String?,
      thumbUrl: r['thumb_url'] as String?,
      detailed: ((r['detailed'] as int?) ?? 0) == 1,
      arChecked: ((r['ar_checked'] as int?) ?? 0) == 1,
    );

Map<String, Object?> animeToRow(Anime a) => {
      'mal_id': a.malId,
      'title': a.title,
      'title_en': a.titleEn,
      'search': '${a.title} ${a.titleEn ?? ''}'.toLowerCase(),
      'type': a.type,
      'episodes': a.episodes,
      'status': a.status,
      'year': a.year,
      'season': a.season,
      'score': a.score,
      'genres': a.genres.join('|'),
      'studios': a.studios.join('|'),
      'synopsis': a.synopsis,
      'image_url': a.imageUrl,
      'thumb_url': a.thumbUrl,
      'detailed': a.detailed ? 1 : 0,
    };
