import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../domain/entities/anime.dart';

/// Backup source when Jikan is slow/blocked. Looks anime up by its MAL id.
class AniListClient {
  AniListClient([http.Client? client]) : _http = client ?? http.Client();
  final http.Client _http;

  static const _query = r'''
query($id:Int){Media(idMal:$id,type:ANIME){
  description(asHtml:false) genres
  studios(isMain:true){nodes{name}}
  characters(sort:[ROLE,RELEVANCE],perPage:24){edges{role node{id name{full} image{medium}}}}
}}''';

  Future<Map<String, dynamic>?> _media(int malId) async {
    final res = await _http
        .post(
          Uri.parse('https://graphql.anilist.co'),
          headers: {'Content-Type': 'application/json', 'Accept': 'application/json'},
          body: jsonEncode({'query': _query, 'variables': {'id': malId}}),
        )
        .timeout(const Duration(seconds: 10));
    if (res.statusCode != 200) return null;
    final j = jsonDecode(res.body) as Map<String, dynamic>;
    return j['data']?['Media'] as Map<String, dynamic>?;
  }

  String? _clean(String? s) {
    if (s == null) return null;
    final t = s
        .replaceAll(RegExp(r'<br\s*/?>', caseSensitive: false), '\n')
        .replaceAll(RegExp(r'<[^>]+>'), '')
        .replaceAll(RegExp(r'\n{3,}'), '\n\n')
        .trim();
    return t.isEmpty ? null : t;
  }

  /// Returns [a] enriched with synopsis/genres/studios.
  Future<Anime?> detail(Anime a) async {
    final m = await _media(a.malId);
    if (m == null) return null;
    final desc = _clean(m['description'] as String?);
    final genres = ((m['genres'] as List?) ?? const []).cast<String>();
    final studios = ((m['studios']?['nodes'] as List?) ?? const [])
        .map((e) => e['name'] as String)
        .toList();
    return Anime(
      malId: a.malId,
      title: a.title,
      titleEn: a.titleEn,
      type: a.type,
      episodes: a.episodes,
      status: a.status,
      year: a.year,
      season: a.season,
      score: a.score,
      genres: genres.isNotEmpty ? genres : a.genres,
      studios: studios.isNotEmpty ? studios : a.studios,
      synopsis: desc,
      imageUrl: a.imageUrl,
      thumbUrl: a.thumbUrl,
      detailed: desc != null,
    );
  }

  Future<List<AnimeCharacter>> characters(int malId) async {
    final m = await _media(malId);
    final edges = (m?['characters']?['edges'] as List?) ?? const [];
    return edges.map<AnimeCharacter>((e) {
      final n = e['node'];
      return AnimeCharacter(
        id: n['id'] as int,
        name: (n['name']?['full'] ?? '') as String,
        role: e['role'] == 'MAIN' ? 'Main' : 'Supporting',
        imageUrl: n['image']?['medium'] as String?,
      );
    }).toList();
  }
}
