import 'package:flutter/material.dart';

import '../../domain/entities/anime_filter.dart';
import '../../domain/repositories/anime_repository.dart';

/// Holds the draft/applied advanced filter for the search tab.
///
/// Provided app-wide from main.dart as `FilterProvider(c.read<AnimeRepository>())`.
class FilterProvider extends ChangeNotifier {
  FilterProvider(this._repo);
  final AnimeRepository _repo;

  AnimeFilter _filter = AnimeFilter.empty;

  /// Live result count for the current filter (refreshed by the sheet).
  int resultCount = 0;

  AnimeFilter get filter => _filter;

  bool get hasActive => _filter.isActive;

  /// All genre keys shown in the sheet. Display names come from S.genre(g).
  static const List<String> allGenres = [
    'action',
    'adventure',
    'comedy',
    'drama',
    'fantasy',
    'horror',
    'mystery',
    'romance',
    'sci-fi',
    'slice of life',
    'sports',
    'supernatural',
    'thriller',
    'psychological',
    'mecha',
    'music',
    'school',
    'historical',
    'military',
    'magic',
    'martial arts',
    'shounen',
    'shoujo',
    'seinen',
    'josei',
    'isekai',
    'ecchi',
    'harem',
    'super power',
    'vampire',
    'demons',
    'space',
    'police',
    'parody',
    'samurai',
    'kids',
    'gourmet',
    'suspense',
    'game',
    'war',
    'crime',
  ];

  static const List<String> allTypes = [
    'TV',
    'MOVIE',
    'OVA',
    'ONA',
    'SPECIAL',
  ];

  static const List<String> allStatuses = [
    'ONGOING',
    'FINISHED',
    'UPCOMING',
  ];

  static const List<String> allSeasons = [
    'WINTER',
    'SPRING',
    'SUMMER',
    'FALL',
  ];

  static const List<String> allSorts = [
    'score',
    'newest',
    'oldest',
    'name',
  ];

  static const List<String> allEpisodeLengths = [
    'short',
    'medium',
    'long',
  ];

  void update(AnimeFilter f) {
    _filter = f;
    notifyListeners();
  }

  List<String> _toggled(List<String> list, String value) {
    final next = List<String>.from(list);
    if (next.contains(value)) {
      next.remove(value);
    } else {
      next.add(value);
    }
    return next;
  }

  void toggleGenre(String genre) {
    _filter = _filter.copyWith(genres: _toggled(_filter.genres, genre));
    notifyListeners();
  }

  void toggleType(String type) {
    _filter = _filter.copyWith(types: _toggled(_filter.types, type));
    notifyListeners();
  }

  void toggleStatus(String status) {
    _filter = _filter.copyWith(statuses: _toggled(_filter.statuses, status));
    notifyListeners();
  }

  void toggleSeason(String season) {
    _filter = _filter.copyWith(seasons: _toggled(_filter.seasons, season));
    notifyListeners();
  }

  void setYears(RangeValues years) {
    _filter = _filter.copyWith(
      yearStart: years.start.round(),
      yearEnd: years.end.round(),
    );
    notifyListeners();
  }

  void setMinScore(double score) {
    _filter = _filter.copyWith(minScore: score);
    notifyListeners();
  }

  void setEpisodeLength(String? length) {
    _filter = _filter.copyWith(
      episodeLength: length,
      clearEpisodeLength: length == null,
    );
    notifyListeners();
  }

  void setSort(String sort) {
    _filter = _filter.copyWith(sort: sort);
    notifyListeners();
  }

  void toggleGenreMatch() {
    _filter = _filter.copyWith(genreMatchAll: !_filter.genreMatchAll);
    notifyListeners();
  }

  void setOnlyFavorites(bool value) {
    _filter = _filter.copyWith(onlyFavorites: value);
    notifyListeners();
  }

  void setHideWatched(bool value) {
    _filter = _filter.copyWith(hideWatched: value);
    notifyListeners();
  }

  void clear() {
    _filter = AnimeFilter.empty;
    resultCount = 0;
    notifyListeners();
  }

  /// Live result count for the current filter, using the stored repo.
  Future<void> refreshCount(String query) async {
    try {
      resultCount = await _repo.countFiltered(query, _filter);
    } catch (_) {
      resultCount = 0;
    }
    notifyListeners();
  }

  /// Same count, but against an explicitly supplied repo (e.g. tests).
  Future<void> refreshCountWithRepo(AnimeRepository repo, String query) async {
    try {
      resultCount = await repo.countFiltered(query, _filter);
    } catch (_) {
      resultCount = 0;
    }
    notifyListeners();
  }
}
