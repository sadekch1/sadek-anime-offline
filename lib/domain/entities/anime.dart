class Anime {
  final int malId;
  final String title;
  final String? titleEn;
  final String? titleAr;
  final String? type;
  final int? episodes;
  final String? status;
  final int? year;
  final String? season;
  final double? score;
  final List<String> genres;
  final List<String> studios;
  final String? synopsis;
  final String? synopsisAr;
  final String? imageUrl;
  final String? thumbUrl;
  final bool detailed;
  final bool arChecked;

  const Anime({
    required this.malId,
    required this.title,
    this.titleEn,
    this.titleAr,
    this.type,
    this.episodes,
    this.status,
    this.year,
    this.season,
    this.score,
    this.genres = const [],
    this.studios = const [],
    this.synopsis,
    this.synopsisAr,
    this.imageUrl,
    this.thumbUrl,
    this.detailed = false,
    this.arChecked = false,
  });

  String get displayTitle =>
      (titleEn != null && titleEn!.isNotEmpty) ? titleEn! : title;

  String titleFor(bool arabic) =>
      (arabic && titleAr != null && titleAr!.isNotEmpty) ? titleAr! : displayTitle;
}

class AnimeCharacter {
  final int id;
  final String name;
  final String? role;
  final String? imageUrl;
  const AnimeCharacter({
    required this.id,
    required this.name,
    this.role,
    this.imageUrl,
  });
}

class ArabicResult {
  final Anime anime;
  final String? error; // null = ok (or nothing to do)
  const ArabicResult(this.anime, this.error);
}
