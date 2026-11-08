import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../domain/entities/anime.dart';
import '../../domain/repositories/anime_repository.dart';

class SearchProvider extends ChangeNotifier {
  SearchProvider(this._repo);
  final AnimeRepository _repo;

  Timer? _timer;
  int _seq = 0;
  String query = '';
  List<Anime> results = [];
  bool searchingOnline = false;

  void onChanged(String text) {
    query = text.trim();
    _timer?.cancel();
    if (query.isEmpty) {
      _seq++;
      results = [];
      searchingOnline = false;
      notifyListeners();
      return;
    }
    _timer = Timer(const Duration(milliseconds: 180), () => _run(query));
  }

  Future<void> _run(String q) async {
    final id = ++_seq;
    final local = await _repo.searchLocal(q);
    if (id != _seq) return;
    results = local;
    searchingOnline = local.length < 5;
    notifyListeners();

    if (local.length < 5) {
      final online = await _repo.searchOnline(q);
      if (id != _seq) return;
      final seen = results.map((a) => a.malId).toSet();
      results = [...results, ...online.where((a) => !seen.contains(a.malId))];
      searchingOnline = false;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}
