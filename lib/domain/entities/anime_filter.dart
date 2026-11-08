/// Advanced filter for the offline SQLite database (v2).
///
/// Year rule: [yearStart] is the left handle of the range slider (1980..2026).
/// When it is at its minimum (1980) there is NO lower bound — titles from
/// before 1980 (and titles with no year) are included. That is the
/// "قبل 1980" behaviour agreed with the user.
class AnimeFilter {
  final List<String> genres;
  final bool genreMatchAll; // true = "كلها معاً" (AND), false = "أي واحد منها" (OR)
  final List<String> types; // TV, MOVIE, OVA, ONA, SPECIAL
  final List<String> statuses; // ONGOING, FINISHED, UPCOMING
  final List<String> seasons; // WINTER, SPRING, SUMMER, FALL
  final int yearStart;
  final int yearEnd;
  final double minScore; // 0 = no minimum
  final String? episodeLength; // 'short' (<=13), 'medium' (<=26), 'long' (>26)
  final String sort; // 'score', 'newest', 'oldest', 'name'
  final bool onlyFavorites;
  final bool hideWatched;

  const AnimeFilter({
    this.genres = const [],
    this.genreMatchAll = true,
    this.types = const [],
    this.statuses = const [],
    this.seasons = const [],
    this.yearStart = 1980,
    this.yearEnd = 2026,
    this.minScore = 0,
    this.episodeLength,
    this.sort = 'score',
    this.onlyFavorites = false,
    this.hideWatched = false,
  });

  static const int minYear = 1980;
  static const int maxYear = 2026;

  bool get isActive =>
      genres.isNotEmpty ||
      types.isNotEmpty ||
      statuses.isNotEmpty ||
      seasons.isNotEmpty ||
      yearStart > minYear ||
      yearEnd < maxYear ||
      minScore > 0 ||
      episodeLength != null ||
      sort != 'score' ||
      onlyFavorites ||
      hideWatched;

  /// Lower year bound, or null when the slider is at "قبل 1980".
  int? get effectiveYearStart => yearStart <= minYear ? null : yearStart;

  AnimeFilter copyWith({
    List<String>? genres,
    bool? genreMatchAll,
    List<String>? types,
    List<String>? statuses,
    List<String>? seasons,
    int? yearStart,
    int? yearEnd,
    double? minScore,
    String? episodeLength,
    bool clearEpisodeLength = false,
    String? sort,
    bool? onlyFavorites,
    bool? hideWatched,
  }) =>
      AnimeFilter(
        genres: genres ?? this.genres,
        genreMatchAll: genreMatchAll ?? this.genreMatchAll,
        types: types ?? this.types,
        statuses: statuses ?? this.statuses,
        seasons: seasons ?? this.seasons,
        yearStart: yearStart ?? this.yearStart,
        yearEnd: yearEnd ?? this.yearEnd,
        minScore: minScore ?? this.minScore,
        episodeLength:
            clearEpisodeLength ? null : (episodeLength ?? this.episodeLength),
        sort: sort ?? this.sort,
        onlyFavorites: onlyFavorites ?? this.onlyFavorites,
        hideWatched: hideWatched ?? this.hideWatched,
      );

  static const empty = AnimeFilter();
}
