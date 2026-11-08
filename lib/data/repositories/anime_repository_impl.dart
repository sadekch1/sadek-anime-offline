import 'dart:async';

import '../../domain/entities/anime.dart';
import '../../domain/entities/anime_filter.dart';
import '../../domain/entities/library_entry.dart';
import '../../domain/repositories/anime_repository.dart';
import '../local/database_helper.dart';
import '../remote/anilist_client.dart';
import '../remote/jikan_client.dart';
import '../remote/tmdb_client.dart';

class AnimeRepositoryImpl implements AnimeRepository {
  AnimeRepositoryImpl(this._db, this._api, this._anilist, this._tmdb);
  final DatabaseHelper _db;
  final JikanClient _api;
  final AniListClient _anilist;
  final TmdbClient _tmdb;

  Future<List<Anime>> _withFallback(
    Future<List<Anime>> local,
    Future<List<Anime>> Function() remote,
  ) async {
    final l = await local;
    if (l.length >= 10) return l;
    try {
      final r = await remote();
      await _db.upsertAll(r);
      return r.isEmpty ? l : r;
    } catch (_) {
      return l;
    }
  }

  @override
  Future<List<Anime>> trending() => _withFallback(
        _db.query(
            where: "status = 'ONGOING' AND score IS NOT NULL",
            orderBy: 'score DESC',
            limit: 20),
        () => _api.top(filter: 'airing'),
      );

  @override
  Future<List<Anime>> topRated() => _withFallback(
        _db.query(
            where: "type = 'TV' AND score IS NOT NULL",
            orderBy: 'score DESC',
            limit: 20),
        () => _api.top(),
      );

  @override
  Future<List<Anime>> topMovies() => _withFallback(
        _db.query(
            where: "type = 'MOVIE' AND score IS NOT NULL",
            orderBy: 'score DESC',
            limit: 20),
        () => _api.top(type: 'movie'),
      );

  @override
  Future<List<Anime>> searchLocal(String query) => _db.search(query);

  @override
  Future<List<Anime>> searchOnline(String query) async {
    try {
      final list = await _api.search(query);
      await _db.upsertAll(list);
      return list;
    } catch (_) {
      return [];
    }
  }

  /// English details: Jikan first, AniList as backup.
  @override
  Future<Anime> getDetail(Anime base) async {
    var a = await _db.byId(base.malId) ?? base;
    // v2: synopses are preloaded in the DB at build time — if the cached
    // title already has a synopsis, return it at once, no network.
    if (a.detailed) return a;
    if (a.synopsis != null && a.synopsis!.isNotEmpty) return a;
    Anime? full;
    try {
      full = await _api.fullAnime(base.malId);
    } catch (_) {}
    if (full == null || !full.detailed) {
      try {
        final al = await _anilist.detail(full ?? a);
        if (al != null && al.detailed) full = al;
      } catch (_) {}
    }
    if (full != null) {
      await _db.upsert(full);
      a = await _db.byId(base.malId) ?? full;
    }
    return a;
  }

  @override
  Future<ArabicResult> getArabic(Anime a) async {
    if (a.arChecked || !_tmdb.enabled) return ArabicResult(a, null);
    try {
      final info = await _tmdb.find(a);
      await _db.saveArabic(a.malId, info?.title, info?.overview);
      return ArabicResult(await _db.byId(a.malId) ?? a, null);
    } catch (e) {
      final msg = e is StateError
          ? e.message
          : (e is TimeoutException ? 'timeout' : 'network');
      return ArabicResult(a, msg);
    }
  }

  @override
  Future<List<AnimeCharacter>> getCharacters(int animeId) async {
    final local = await _db.characters(animeId);
    if (local.isNotEmpty) return local;
    var remote = <AnimeCharacter>[];
    try {
      remote = await _api.characters(animeId);
    } catch (_) {}
    if (remote.isEmpty) {
      try {
        remote = await _anilist.characters(animeId);
      } catch (_) {}
    }
    if (remote.isNotEmpty) await _db.saveCharacters(animeId, remote);
    return remote;
  }


  @override
  Future<List<Anime>> searchFiltered(String query, AnimeFilter filter,
          {int limit = 120}) =>
      _db.searchFiltered(query, filter, limit: limit);

  @override
  Future<int> countFiltered(String query, AnimeFilter filter) =>
      _db.countFiltered(query, filter);

  @override
  Future<Map<int, LibraryEntry>> getLibrary() => _db.getLibrary();

  @override
  Future<LibraryEntry?> getLibraryEntry(int malId) =>
      _db.getLibraryEntry(malId);

  @override
  Future<void> setLibraryStatus(int malId, String status) =>
      _db.setLibraryStatus(malId, status);

  @override
  Future<void> setLastEpisode(int malId, int episode) =>
      _db.setLastEpisode(malId, episode);

  @override
  Future<void> removeFromLibrary(int malId) => _db.removeFromLibrary(malId);

  @override
  Future<Map<String, int>> libraryCounts() => _db.libraryCounts();

  @override
  Future<List<Anime>> libraryAnime(String status) => _db.libraryAnime(status);

  @override
  Future<Map<String, int>> stats() => _db.stats();
}
