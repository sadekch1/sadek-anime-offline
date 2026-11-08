import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/strings.dart';
import '../../domain/entities/anime.dart';
import '../../domain/entities/library_entry.dart';
import '../providers/library_provider.dart';
import '../providers/settings_provider.dart';
import '../screens/detail_screen.dart';
import '../widgets/anime_card.dart';
import '../widgets/poster_image.dart';

/// My Library: one tab per status (favorite / watching / plan / watched).
class LibraryScreen extends StatefulWidget {
  const LibraryScreen({super.key});

  @override
  State<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends State<LibraryScreen> {
  @override
  void initState() {
    super.initState();
    final lib = context.read<LibraryProvider>();
    if (lib.entries.isEmpty && !lib.loading) lib.load();
  }

  String _statusLabel(S s, String status) {
    switch (status) {
      case 'favorite':
        return s.favorites;
      case 'watching':
        return s.watching;
      case 'plan':
        return s.planToWatch;
      case 'watched':
      default:
        return s.watched;
    }
  }

  @override
  Widget build(BuildContext context) {
    final pal = context.watch<SettingsProvider>().palette;
    final s = S.of(context);
    final counts = context.watch<LibraryProvider>().counts;
    return DefaultTabController(
      length: libraryStatuses.length,
      child: Scaffold(
        backgroundColor: pal.bg,
        appBar: AppBar(
          backgroundColor: pal.bg,
          title: Text(s.library,
              style: TextStyle(color: pal.text, fontWeight: FontWeight.w800)),
          bottom: TabBar(
            labelColor: pal.text,
            unselectedLabelColor: pal.textDim,
            indicatorColor: pal.accent,
            isScrollable: true,
            tabs: libraryStatuses
                .map((st) => Tab(
                    text:
                        '${_statusLabel(s, st)} (${counts[st] ?? 0})'))
                .toList(),
          ),
        ),
        body: TabBarView(
          children: libraryStatuses
              .map((st) => _StatusTab(status: st, watchingTab: st == 'watching'))
              .toList(),
        ),
      ),
    );
  }
}

class _StatusTab extends StatefulWidget {
  const _StatusTab({required this.status, required this.watchingTab});
  final String status;
  final bool watchingTab;

  @override
  State<_StatusTab> createState() => _StatusTabState();
}

class _StatusTabState extends State<_StatusTab> {
  Future<List<Anime>>? _future;
  Map<int, LibraryEntry>? _lastEntries;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Re-fetch only when the library entries actually changed (a new map
    // identity is published on every reload); otherwise keep the cached
    // future so +/- taps don't flash a spinner.
    final lib = context.watch<LibraryProvider>();
    if (_future == null || !identical(_lastEntries, lib.entries)) {
      _lastEntries = lib.entries;
      _future = lib.animeFor(widget.status);
    }
  }

  @override
  Widget build(BuildContext context) {
    final pal = context.watch<SettingsProvider>().palette;
    final s = S.of(context);
    final lib = context.watch<LibraryProvider>();
    final status = widget.status;
    final watchingTab = widget.watchingTab;
    return FutureBuilder<List<Anime>>(
      future: _future,
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting && !snap.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        final list = snap.data ?? const <Anime>[];
        if (list.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.bookmark_outline_rounded,
                      size: 48, color: pal.textDim),
                  const SizedBox(height: 12),
                  Text(s.emptyLibrary,
                      textAlign: TextAlign.center,
                      style: TextStyle(color: pal.textDim)),
                ],
              ),
            ),
          );
        }
        if (watchingTab) {
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: list.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (_, i) => _WatchingRow(
                anime: list[i], entry: lib.entryFor(list[i].malId)),
          );
        }
        return GridView.builder(
          padding: const EdgeInsets.all(16),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            childAspectRatio: 0.62,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
          ),
          itemCount: list.length,
          itemBuilder: (_, i) => AnimeCard(anime: list[i]),
        );
      },
    );
  }
}

class _WatchingRow extends StatelessWidget {
  const _WatchingRow({required this.anime, required this.entry});
  final Anime anime;
  final LibraryEntry? entry;

  @override
  Widget build(BuildContext context) {
    final pal = context.watch<SettingsProvider>().palette;
    final s = S.of(context);
    final lib = context.read<LibraryProvider>();
    final last = entry?.lastEpisode ?? 0;
    final total = anime.episodes ?? 0;
    final progress =
        total > 0 ? (last / total).clamp(0.0, 1.0).toDouble() : 0.0;
    return GestureDetector(
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => DetailScreen(anime: anime)),
      ),
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: pal.surface,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(children: [
          SizedBox(
            width: 56,
            height: 80,
            child: PosterImage(url: anime.imageUrl, radius: 8),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(anime.titleFor(context.watch<SettingsProvider>().isArabic),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                        color: pal.text, fontWeight: FontWeight.w600)),
                const SizedBox(height: 6),
                Text(
                  total > 0
                      ? s.episodeProgress(last, total)
                      : '${s.lastEpisode}: $last',
                  style: TextStyle(color: pal.textDim, fontSize: 12),
                ),
                const SizedBox(height: 6),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: progress,
                    minHeight: 5,
                    backgroundColor: pal.surfaceHi,
                    valueColor: AlwaysStoppedAnimation<Color>(pal.accent),
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () => lib.bumpEpisode(anime, -1),
            icon: Icon(Icons.remove_rounded, color: pal.text),
            visualDensity: VisualDensity.compact,
          ),
          IconButton(
            onPressed: () => lib.bumpEpisode(anime, 1),
            icon: Icon(Icons.add_rounded, color: pal.accent),
            visualDensity: VisualDensity.compact,
          ),
        ]),
      ),
    );
  }
}
