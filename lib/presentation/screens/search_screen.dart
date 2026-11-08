import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/strings.dart';
import '../../core/theme.dart';
import '../../domain/entities/anime.dart';
import '../../domain/entities/anime_filter.dart';
import '../../domain/repositories/anime_repository.dart';
import '../providers/filter_provider.dart';
import '../providers/settings_provider.dart';
import '../widgets/anime_card.dart';
import '../widgets/filter_sheet.dart';

/// Search tab: text search + advanced filter.
///
/// Uses the app-wide [FilterProvider] (provided in main.dart) and
/// [AnimeRepository] directly. An empty query still searches (browse all)
/// whenever a filter is active; the "type to search" hint only shows when
/// the query is empty AND no filter is active.
class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final _controller = TextEditingController();
  Timer? _timer;
  int _seq = 0;
  String _query = '';
  List<Anime> _results = [];
  bool _searchingOnline = false;
  bool _loading = false;
  AnimeFilter? _lastFilter;

  @override
  void dispose() {
    _controller.dispose();
    _timer?.cancel();
    super.dispose();
  }

  void _onQueryChanged(String text) {
    _query = text.trim();
    _scheduleRun();
  }

  void _scheduleRun() {
    _timer?.cancel();
    _timer = Timer(const Duration(milliseconds: 180), _run);
  }

  Future<void> _run() async {
    final repo = context.read<AnimeRepository>();
    final filter = context.read<FilterProvider>().filter;
    final q = _query;
    if (q.isEmpty && !filter.isActive) {
      if (!mounted) return;
      setState(() {
        _results = [];
        _searchingOnline = false;
        _loading = false;
      });
      return;
    }
    final id = ++_seq;
    setState(() => _loading = true);
    final local = await repo.searchFiltered(q, filter);
    if (!mounted || id != _seq) return;
    setState(() {
      _results = local;
      _loading = false;
      _searchingOnline = q.isNotEmpty && local.length < 5;
    });

    if (q.isNotEmpty && local.length < 5) {
      final online = await repo.searchOnline(q);
      if (!mounted || id != _seq) return;
      final seen = _results.map((a) => a.malId).toSet();
      setState(() {
        _results = [
          ..._results,
          ...online.where((a) => !seen.contains(a.malId)),
        ];
        _searchingOnline = false;
      });
    }
  }

  List<Widget> _activeChips(FilterProvider fp, S t, AppPalette pal) {
    final f = fp.filter;
    final chips = <Widget>[];

    Widget chip(String label, VoidCallback onDeleted) => InputChip(
          label: Text(label,
              style: TextStyle(color: pal.text, fontSize: 12)),
          backgroundColor: pal.surfaceHi,
          deleteIconColor: pal.textDim,
          onDeleted: onDeleted,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: BorderSide(color: pal.surfaceHi),
          ),
        );

    for (final g in f.genres) {
      chips.add(chip(t.genre(g), () => fp.toggleGenre(g)));
    }
    for (final v in f.types) {
      chips.add(chip(t.type(v), () => fp.toggleType(v)));
    }
    for (final v in f.statuses) {
      chips.add(chip(t.status(v), () => fp.toggleStatus(v)));
    }
    for (final v in f.seasons) {
      chips.add(chip(t.season(v), () => fp.toggleSeason(v)));
    }
    if (f.yearStart > AnimeFilter.minYear || f.yearEnd < AnimeFilter.maxYear) {
      final start = f.yearStart <= AnimeFilter.minYear
          ? t.before1980
          : '${f.yearStart}';
      chips.add(chip('$start – ${f.yearEnd}',
          () => fp.setYears(const RangeValues(1980, 2026))));
    }
    if (f.minScore > 0) {
      chips.add(chip('${t.minScore}: ${f.minScore.toStringAsFixed(1)}',
          () => fp.setMinScore(0)));
    }
    if (f.episodeLength != null) {
      final label = f.episodeLength == 'short'
          ? t.shortEps
          : f.episodeLength == 'medium'
              ? t.mediumEps
              : t.longEps;
      chips.add(chip(label, () => fp.setEpisodeLength(null)));
    }
    if (f.sort != 'score') {
      final label = f.sort == 'newest'
          ? t.sortNewest
          : f.sort == 'oldest'
              ? t.sortOldest
              : t.sortName;
      chips.add(chip(label, () => fp.setSort('score')));
    }
    if (f.onlyFavorites) {
      chips.add(chip(t.onlyFavorites, () => fp.setOnlyFavorites(false)));
    }
    if (f.hideWatched) {
      chips.add(chip(t.hideWatched, () => fp.setHideWatched(false)));
    }
    return chips;
  }

  @override
  Widget build(BuildContext context) {
    final fp = context.watch<FilterProvider>();
    final pal = context.watch<SettingsProvider>().palette;
    final t = S.of(context);

    // Re-run the search whenever the applied filter object changes
    // (FilterProvider creates a new AnimeFilter on every change).
    if (_lastFilter != fp.filter) {
      _lastFilter = fp.filter;
      WidgetsBinding.instance
          .addPostFrameCallback((_) => _scheduleRun());
    }

    final activeChips = _activeChips(fp, t, pal);

    return SafeArea(
      child: Column(children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Row(children: [
            Expanded(
              child: TextField(
                controller: _controller,
                onChanged: _onQueryChanged,
                textInputAction: TextInputAction.search,
                style: TextStyle(color: pal.text),
                decoration: InputDecoration(
                  hintText: t.searchHint,
                  hintStyle: TextStyle(color: pal.textDim),
                  prefixIcon: Icon(Icons.search_rounded, color: pal.textDim),
                  filled: true,
                  fillColor: pal.surface,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Stack(children: [
              IconButton(
                icon: Icon(Icons.tune_rounded, color: pal.text),
                tooltip: t.filter,
                onPressed: () => showFilterSheet(context, _query),
              ),
              if (fp.hasActive)
                Positioned(
                  top: 10,
                  right: 10,
                  child: Container(
                    width: 9,
                    height: 9,
                    decoration: BoxDecoration(
                      color: pal.accent,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
            ]),
          ]),
        ),
        if (activeChips.isNotEmpty)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: Align(
              alignment: Alignment.centerRight,
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: activeChips,
              ),
            ),
          ),
        if (_loading || _searchingOnline)
          LinearProgressIndicator(
            minHeight: 2,
            color: pal.accent,
            backgroundColor: pal.surfaceHi,
          ),
        Expanded(child: _body(fp, t, pal)),
      ]),
    );
  }

  Widget _body(FilterProvider fp, S t, AppPalette pal) {
    if (_query.isEmpty && !fp.hasActive) {
      return Center(
        child: Text(t.searchEmpty,
            style: TextStyle(color: pal.textDim)),
      );
    }
    if (_loading && _results.isEmpty) {
      return Center(child: CircularProgressIndicator(color: pal.accent));
    }
    if (_results.isEmpty) {
      return Center(
        child: Text(_searchingOnline ? t.searchingOnline : t.noResults,
            style: TextStyle(color: pal.textDim)),
      );
    }
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 140,
        childAspectRatio: 0.5,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: _results.length,
      itemBuilder: (_, i) => AnimeCard(anime: _results[i]),
    );
  }
}
