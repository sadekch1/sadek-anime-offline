import 'package:flutter/foundation.dart';

import '../../data/remote/firebase_sync.dart';
import '../../domain/entities/anime.dart';
import '../../domain/entities/library_entry.dart';
import '../../domain/repositories/anime_repository.dart';

/// My Library state (v2). Local SQLite (via [AnimeRepository]) is the
/// source of truth; after every successful local mutation the change is
/// pushed to Firebase best-effort via [FirebaseSync.pushLocal], which
/// never throws (no-op when not signed in / not configured).
class LibraryProvider extends ChangeNotifier {
  LibraryProvider(this._repo, this._sync);

  final AnimeRepository _repo;
  final FirebaseSync _sync;

  Map<int, LibraryEntry> entries = {};
  Map<String, int> counts = {};
  bool loading = false;

  final Map<String, List<Anime>> _listsCache = {};

  LibraryEntry? entryFor(int malId) => entries[malId];

  bool isFavorite(int malId) => entries[malId]?.isFavorite ?? false;

  /// Anime titles for one library status, cached per status until the
  /// next reload (mutations clear the cache).
  Future<List<Anime>> animeFor(String status) async {
    final cached = _listsCache[status];
    if (cached != null) return cached;
    final list = await _repo.libraryAnime(status);
    _listsCache[status] = list;
    return list;
  }

  Future<void> load() async {
    if (loading) return;
    loading = true;
    notifyListeners();
    await _reload();
    loading = false;
    notifyListeners();
  }

  Future<void> _reload() async {
    entries = await _repo.getLibrary();
    counts = await _repo.libraryCounts();
    _listsCache.clear();
    notifyListeners();
  }

  Future<void> _afterMutation() async {
    try {
      await _sync.pushLocal();
    } catch (_) {}
    await _reload();
  }

  Future<void> setStatus(Anime anime, String status) async {
    await _repo.setLibraryStatus(anime.malId, status);
    await _afterMutation();
  }

  Future<void> toggleFavorite(Anime anime) async {
    if (isFavorite(anime.malId)) {
      await remove(anime);
      return;
    }
    await setStatus(anime, 'favorite');
  }

  Future<void> setEpisode(Anime anime, int episode) async {
    final max = anime.episodes ?? 9999;
    var clamped = episode;
    if (clamped < 0) clamped = 0;
    if (clamped > max) clamped = max;
    await _repo.setLastEpisode(anime.malId, clamped);
    await _afterMutation();
  }

  Future<void> bumpEpisode(Anime anime, int delta) async {
    final current = entries[anime.malId]?.lastEpisode ?? 0;
    await setEpisode(anime, current + delta);
  }

  Future<void> remove(Anime anime) async {
    await _repo.removeFromLibrary(anime.malId);
    await _afterMutation();
  }
}
