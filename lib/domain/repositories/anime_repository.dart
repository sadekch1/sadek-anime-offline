import '../entities/anime.dart';
import '../entities/anime_filter.dart';
import '../entities/library_entry.dart';

abstract class AnimeRepository {
  Future<List<Anime>> trending();
  Future<List<Anime>> topRated();
  Future<List<Anime>> topMovies();
  Future<List<Anime>> searchLocal(String query);

  /// Hybrid fallback: queries Jikan (if online) and caches results locally.
  Future<List<Anime>> searchOnline(String query);
  Future<Anime> getDetail(Anime base);
  Future<ArabicResult> getArabic(Anime a);
  Future<List<AnimeCharacter>> getCharacters(int animeId);
  Future<Map<String, int>> stats();

  // ---- v2: advanced filter (offline, local SQLite) ----
  Future<List<Anime>> searchFiltered(String query, AnimeFilter filter,
      {int limit = 120});
  Future<int> countFiltered(String query, AnimeFilter filter);

  // ---- v2: my library (local SQLite, source of truth) ----
  Future<Map<int, LibraryEntry>> getLibrary();
  Future<LibraryEntry?> getLibraryEntry(int malId);
  Future<void> setLibraryStatus(int malId, String status);
  Future<void> setLastEpisode(int malId, int episode);
  Future<void> removeFromLibrary(int malId);
  Future<Map<String, int>> libraryCounts();
  Future<List<Anime>> libraryAnime(String status);
}
