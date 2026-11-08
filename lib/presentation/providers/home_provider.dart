import 'package:flutter/foundation.dart';

import '../../domain/entities/anime.dart';
import '../../domain/repositories/anime_repository.dart';

class HomeProvider extends ChangeNotifier {
  HomeProvider(this._repo) {
    load();
  }
  final AnimeRepository _repo;

  List<Anime> trending = [];
  List<Anime> topRated = [];
  List<Anime> movies = [];
  bool loading = true;

  bool get isEmpty => trending.isEmpty && topRated.isEmpty && movies.isEmpty;

  Future<void> load() async {
    loading = true;
    notifyListeners();
    // Sequential on purpose: respects Jikan's rate limit when falling back.
    trending = await _repo.trending();
    topRated = await _repo.topRated();
    movies = await _repo.topMovies();
    loading = false;
    notifyListeners();
  }
}
