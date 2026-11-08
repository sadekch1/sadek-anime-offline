import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/strings.dart';
import '../../domain/entities/anime_filter.dart';
import '../../domain/repositories/anime_repository.dart';
import '../providers/filter_provider.dart';
import '../providers/settings_provider.dart';

/// Opens the advanced-filter bottom sheet.
///
/// [query] is the current search text, so the live result count matches
/// what the search tab will show. Applying updates the app-wide
/// [FilterProvider] and closes the sheet.
Future<void> showFilterSheet(BuildContext context, String query) {
  final pal = context.read<SettingsProvider>().palette;
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: pal.surface,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (_) => _FilterSheet(query: query),
  );
}

class _FilterSheet extends StatefulWidget {
  const _FilterSheet({required this.query});
  final String query;

  @override
  State<_FilterSheet> createState() => _FilterSheetState();
}

class _FilterSheetState extends State<_FilterSheet> {
  late AnimeFilter _draft;
  late AnimeRepository _repo;
  Timer? _debounce;
  int _seq = 0;
  int _count = 0;

  @override
  void initState() {
    super.initState();
    _draft = context.read<FilterProvider>().filter;
    _repo = context.read<AnimeRepository>();
    _refreshCount();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }

  void _scheduleCount() {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), _refreshCount);
  }

  Future<void> _refreshCount() async {
    final id = ++_seq;
    int n;
    try {
      n = await _repo.countFiltered(widget.query, _draft);
    } catch (_) {
      n = 0;
    }
    if (!mounted || id != _seq) return;
    setState(() => _count = n);
  }

  void _change(AnimeFilter next) {
    setState(() => _draft = next);
    _scheduleCount();
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

  void _apply() {
    final fp = context.read<FilterProvider>();
    fp.update(_draft);
    Navigator.of(context).pop();
    fp.refreshCount(widget.query);
  }

  void _clear() {
    _change(AnimeFilter.empty);
  }

  @override
  Widget build(BuildContext context) {
    final pal = context.watch<SettingsProvider>().palette;
    final t = S.of(context);
    final selectedBg = pal.accent.withAlpha(51);

    Widget sectionTitle(String title, [String? value]) => Padding(
          padding: const EdgeInsets.only(top: 20, bottom: 8),
          child: Row(children: [
            Text(title,
                style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: pal.text)),
            if (value != null) ...[
              const SizedBox(width: 8),
              Text(value,
                  style: TextStyle(fontSize: 13, color: pal.textDim)),
            ],
          ]),
        );

    Widget multiChips({
      required List<String> options,
      required List<String> selected,
      required String Function(String) label,
      required void Function(String) onToggle,
    }) =>
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: options.map((v) {
            final isSel = selected.contains(v);
            return FilterChip(
              label: Text(label(v)),
              selected: isSel,
              onSelected: (_) => onToggle(v),
              selectedColor: selectedBg,
              backgroundColor: pal.surfaceHi,
              checkmarkColor: pal.accent,
              labelStyle: TextStyle(
                  color: isSel ? pal.text : pal.textDim, fontSize: 13),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
                side: BorderSide(
                    color: isSel ? pal.accent : pal.surfaceHi),
              ),
            );
          }).toList(),
        );

    Widget singleChips({
      required List<String> options,
      required String? selected,
      required String Function(String) label,
      required void Function(String, bool) onSelected,
    }) =>
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: options.map((v) {
            final isSel = selected == v;
            return ChoiceChip(
              label: Text(label(v)),
              selected: isSel,
              onSelected: (sel) => onSelected(v, sel),
              selectedColor: selectedBg,
              backgroundColor: pal.surfaceHi,
              labelStyle: TextStyle(
                  color: isSel ? pal.text : pal.textDim, fontSize: 13),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
                side: BorderSide(
                    color: isSel ? pal.accent : pal.surfaceHi),
              ),
            );
          }).toList(),
        );

    String yearStartLabel() =>
        _draft.yearStart <= AnimeFilter.minYear
            ? t.before1980
            : '${_draft.yearStart}';

    String episodeLabel(String v) {
      switch (v) {
        case 'short':
          return t.shortEps;
        case 'medium':
          return t.mediumEps;
        case 'long':
        default:
          return t.longEps;
      }
    }

    String sortLabel(String v) {
      switch (v) {
        case 'newest':
          return t.sortNewest;
        case 'oldest':
          return t.sortOldest;
        case 'name':
          return t.sortName;
        case 'score':
        default:
          return t.sortScore;
      }
    }

    return DraggableScrollableSheet(
      initialChildSize: 0.92,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, scrollController) => ListView(
        controller: scrollController,
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: pal.surfaceHi,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Row(children: [
            Text(t.advancedFilter,
                style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: pal.text)),
            const Spacer(),
            IconButton(
              icon: Icon(Icons.close_rounded, color: pal.textDim),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ]),
          sectionTitle(t.genres),
          multiChips(
            options: FilterProvider.allGenres,
            selected: _draft.genres,
            label: (g) => t.genre(g),
            onToggle: (g) =>
                _change(_draft.copyWith(genres: _toggled(_draft.genres, g))),
          ),
          const SizedBox(height: 12),
          SegmentedButton<bool>(
            segments: [
              ButtonSegment<bool>(value: true, label: Text(t.genresAll)),
              ButtonSegment<bool>(value: false, label: Text(t.genresAny)),
            ],
            selected: {_draft.genreMatchAll},
            onSelectionChanged: (s) =>
                _change(_draft.copyWith(genreMatchAll: s.first)),
          ),
          sectionTitle(t.typeLabel),
          multiChips(
            options: FilterProvider.allTypes,
            selected: _draft.types,
            label: (v) => t.type(v),
            onToggle: (v) =>
                _change(_draft.copyWith(types: _toggled(_draft.types, v))),
          ),
          sectionTitle(t.statusLabel),
          multiChips(
            options: FilterProvider.allStatuses,
            selected: _draft.statuses,
            label: (v) => t.status(v),
            onToggle: (v) => _change(
                _draft.copyWith(statuses: _toggled(_draft.statuses, v))),
          ),
          sectionTitle(t.seasonLabel),
          multiChips(
            options: FilterProvider.allSeasons,
            selected: _draft.seasons,
            label: (v) => t.season(v),
            onToggle: (v) => _change(
                _draft.copyWith(seasons: _toggled(_draft.seasons, v))),
          ),
          sectionTitle(t.years, '${yearStartLabel()} – ${_draft.yearEnd}'),
          RangeSlider(
            min: AnimeFilter.minYear.toDouble(),
            max: AnimeFilter.maxYear.toDouble(),
            divisions:
                AnimeFilter.maxYear - AnimeFilter.minYear,
            values: RangeValues(
                _draft.yearStart.toDouble(), _draft.yearEnd.toDouble()),
            labels: RangeLabels(yearStartLabel(), '${_draft.yearEnd}'),
            activeColor: pal.accent,
            inactiveColor: pal.surfaceHi,
            onChanged: (v) => _change(_draft.copyWith(
              yearStart: v.start.round(),
              yearEnd: v.end.round(),
            )),
          ),
          sectionTitle(t.minScore, _draft.minScore.toStringAsFixed(1)),
          Slider(
            min: 0,
            max: 10,
            divisions: 20,
            value: _draft.minScore,
            label: _draft.minScore.toStringAsFixed(1),
            activeColor: pal.accent,
            inactiveColor: pal.surfaceHi,
            onChanged: (v) => _change(_draft.copyWith(minScore: v)),
          ),
          sectionTitle(t.episodeLength),
          singleChips(
            options: FilterProvider.allEpisodeLengths,
            selected: _draft.episodeLength,
            label: episodeLabel,
            onSelected: (v, sel) => _change(_draft.copyWith(
              episodeLength: sel ? v : null,
              clearEpisodeLength: !sel,
            )),
          ),
          sectionTitle(t.sortBy),
          singleChips(
            options: FilterProvider.allSorts,
            selected: _draft.sort,
            label: sortLabel,
            onSelected: (v, sel) {
              if (sel) _change(_draft.copyWith(sort: v));
            },
          ),
          const SizedBox(height: 12),
          SwitchListTile(
            title: Text(t.onlyFavorites,
                style: TextStyle(color: pal.text)),
            value: _draft.onlyFavorites,
            activeColor: pal.accent,
            contentPadding: EdgeInsets.zero,
            onChanged: (v) => _change(_draft.copyWith(onlyFavorites: v)),
          ),
          SwitchListTile(
            title:
                Text(t.hideWatched, style: TextStyle(color: pal.text)),
            value: _draft.hideWatched,
            activeColor: pal.accent,
            contentPadding: EdgeInsets.zero,
            onChanged: (v) => _change(_draft.copyWith(hideWatched: v)),
          ),
          const SizedBox(height: 16),
          Row(children: [
            TextButton(
              onPressed: _clear,
              child: Text(t.clearAll,
                  style: TextStyle(color: pal.accent)),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: pal.accent,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: _apply,
                child: Text(t.resultsCount(_count),
                    style: const TextStyle(
                        fontSize: 15, fontWeight: FontWeight.w700)),
              ),
            ),
          ]),
        ],
      ),
    );
  }
}
