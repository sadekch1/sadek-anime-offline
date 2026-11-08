import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../domain/entities/anime.dart';

class JikanClient {
  JikanClient([http.Client? client]) : _http = client ?? http.Client();
  final http.Client _http;
  static const _base = 'https://api.jikan.moe/v4';

  Future<Map<String, dynamic>?> _get(String path, {bool retry = true}) async {
    final res = await _http
        .get(Uri.parse('$_base$path'))
        .timeout(const Duration(seconds: 8));
    if (res.statusCode == 429 && retry) {
      await Future.delayed(const Duration(milliseconds: 1200));
      return _get(path, retry: false);
    }
    if (res.statusCode != 200) return null;
    return jsonDecode(res.body) as Map<String, dynamic>;
  }

  Future<List<Anime>> search(String q) async {
    final j = await _get(
        '/anime?q=${Uri.encodeQueryComponent(q)}&limit=25&sfw=true');
    return _list(j);
  }

  Future<List<Anime>> top({String? filter, String? type}) async {
    final params = ['limit=20', 'sfw=true'];
    if (filter != null) params.add('filter=$filter');
    if (type != null) params.add('type=$type');
    return _list(await _get('/top/anime?${params.join('&')}'));
  }

  Future<Anime?> fullAnime(int id) async {
    final j = await _get('/anime/$id/full');
    final d = j?['data'];
    return d is Map<String, dynamic> ? _parse(d) : null;
  }

  Future<List<AnimeCharacter>> characters(int id) async {
    final j = await _get('/anime/$id/characters');
    final data = (j?['data'] as List?) ?? const [];
    final list = <AnimeCharacter>[];
    for (final e in data) {
      final c = e['character'];
      if (c == null) continue;
      list.add(AnimeCharacter(
        id: c['mal_id'] as int,
        name: (c['name'] ?? '') as String,
        role: e['role'] as String?,
        imageUrl: (c['images']?['webp']?['image_url'] ??
            c['images']?['jpg']?['image_url']) as String?,
      ));
    }
    list.sort((a, b) =>
        (a.role == 'Main' ? 0 : 1).compareTo(b.role == 'Main' ? 0 : 1));
    return list.take(24).toList();
  }

  List<Anime> _list(Map<String, dynamic>? j) {
    final data = (j?['data'] as List?) ?? const [];
    return data
        .whereType<Map<String, dynamic>>()
        .map(_parse)
        .toList();
  }

  Anime _parse(Map<String, dynamic> j) {
    String? status;
    switch (j['status']) {
      case 'Finished Airing':
        status = 'FINISHED';
        break;
      case 'Currently Airing':
        status = 'ONGOING';
        break;
      case 'Not yet aired':
        status = 'UPCOMING';
        break;
    }
    List<String> names(dynamic l) =>
        ((l as List?) ?? const []).map((e) => e['name'] as String).toList();
    final img = (j['images']?['webp'] ?? j['images']?['jpg']);
    final synopsis = j['synopsis'] as String?;
    return Anime(
      malId: j['mal_id'] as int,
      title: (j['title'] ?? '') as String,
      titleEn: j['title_english'] as String?,
      type: (j['type'] as String?)?.toUpperCase(),
      episodes: j['episodes'] as int?,
      status: status,
      year: j['year'] as int?,
      season: (j['season'] as String?)?.toUpperCase(),
      score: (j['score'] as num?)?.toDouble(),
      genres: names(j['genres']),
      studios: names(j['studios']),
      synopsis: synopsis,
      imageUrl: (img?['large_image_url'] ?? img?['image_url']) as String?,
      thumbUrl: img?['small_image_url'] as String?,
      detailed: synopsis != null && synopsis.isNotEmpty,
    );
  }
}
