import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../domain/entities/anime.dart';

class ArabicInfo {
  final String? title;
  final String overview;
  const ArabicInfo(this.title, this.overview);
}

/// Fetches community-written Arabic titles/synopses from TMDB.
/// No machine translation: if TMDB has no Arabic text, nothing is returned.
class TmdbClient {
  TmdbClient(this._key, [http.Client? client]) : _http = client ?? http.Client();
  final String Function() _key;
  final http.Client _http;
  static const _base = 'https://api.themoviedb.org/3';
  static final _arabic = RegExp(r'[\u0600-\u06FF]');

  bool get enabled => _key().isNotEmpty;

  Future<Map<String, dynamic>> _get(String path) async {
    final sep = path.contains('?') ? '&' : '?';
    final res = await _http
        .get(Uri.parse('$_base$path${sep}api_key=${_key()}'))
        .timeout(const Duration(seconds: 8));
    if (res.statusCode != 200) {
      throw StateError('TMDB ${res.statusCode}'); // not "checked": retry later
    }
    return jsonDecode(res.body) as Map<String, dynamic>;
  }

  String _clean(String t) => t
      .replaceAll(
          RegExp(r'\s*[:\-]?\s*(season|part|cour)\s*\d+.*', caseSensitive: false), '')
      .replaceAll(RegExp(r'\s*\d+(st|nd|rd|th)\s+season.*', caseSensitive: false), '')
      .trim();

  /// Returns null when TMDB has no matching entry with Arabic text.
  /// Throws on network/auth errors so the caller can retry later.
  Future<ArabicInfo?> find(Anime a) async {
    final isMovie = a.type == 'MOVIE';
    final kind = isMovie ? 'movie' : 'tv';
    final queries = <String>{
      if (a.titleEn != null && a.titleEn!.isNotEmpty) _clean(a.titleEn!),
      _clean(a.title),
    }..removeWhere((q) => q.isEmpty);

    for (final q in queries) {
      final res = await _get(
          '/search/$kind?query=${Uri.encodeQueryComponent(q)}&language=ar&include_adult=false');
      final results = ((res['results'] as List?) ?? const []).take(8);
      for (final r in results) {
        final genres = ((r['genre_ids'] as List?) ?? const []).cast<int>();
        if (!genres.contains(16)) continue; // must be Animation
        if (r['original_language'] != 'ja') continue; // must be Japanese
        final date =
            (isMovie ? r['release_date'] : r['first_air_date']) as String?;
        final y = (date != null && date.length >= 4)
            ? int.tryParse(date.substring(0, 4))
            : null;
        if (a.year != null && y != null) {
          if (isMovie ? (y - a.year!).abs() > 1 : y > a.year! + 1) continue;
        }
        final overview = ((r['overview'] ?? '') as String).trim();
        if (!_arabic.hasMatch(overview)) continue; // real Arabic text only
        final t = (isMovie ? r['title'] : r['name']) as String?;
        return ArabicInfo(t != null && _arabic.hasMatch(t) ? t : null, overview);
      }
    }
    return null;
  }
}
