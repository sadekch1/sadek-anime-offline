import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/strings.dart';
import '../../core/theme.dart';
import '../../domain/entities/anime.dart';
import '../../domain/entities/library_entry.dart';
import '../../domain/repositories/anime_repository.dart';
import '../providers/library_provider.dart';
import '../providers/settings_provider.dart';
import '../widgets/info_chip.dart';
import '../widgets/poster_image.dart';

class DetailScreen extends StatefulWidget {
  const DetailScreen({super.key, required this.anime});
  final Anime anime;

  @override
  State<DetailScreen> createState() => _DetailScreenState();
}

class _DetailScreenState extends State<DetailScreen> {
  late Anime _a = widget.anime;
  bool _loadingEn = true;
  bool _loadingAr = false;
  bool _loadingChars = true;
  String? _arError;
  List<AnimeCharacter> _chars = const [];
  LibraryEntry? _entry;

  @override
  void initState() {
    super.initState();
    _load();
    _loadLibrary();
  }

  void _retry() {
    setState(() {
      _loadingEn = true;
      _loadingChars = true;
      _arError = null;
    });
    _load();
  }

  Future<void> _load() async {
    final repo = context.read<AnimeRepository>();
    final ar = context.read<SettingsProvider>().isArabic;

    final a = await repo.getDetail(widget.anime);
    if (!mounted) return;
    setState(() {
      _a = a;
      _loadingEn = false;
    });

    // Arabic story and characters load in parallel (different servers).
    await Future.wait([
      if (ar) _loadArabic(repo, a),
      _loadChars(repo),
    ]);
  }

  Future<void> _loadLibrary() async {
    final repo = context.read<AnimeRepository>();
    final e = await repo.getLibraryEntry(widget.anime.malId);
    if (!mounted) return;
    setState(() => _entry = e);
  }

  Future<void> _setStatus(String status) async {
    final s = S(context.read<SettingsProvider>().isArabic);
    final lib = context.read<LibraryProvider>();
    await lib.setStatus(_a, status);
    if (!mounted) return;
    setState(() => _entry = lib.entryFor(widget.anime.malId));
    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(s.addedToLibrary)));
  }

  Future<void> _toggleFavorite() async {
    final s = S(context.read<SettingsProvider>().isArabic);
    final lib = context.read<LibraryProvider>();
    await lib.toggleFavorite(_a);
    if (!mounted) return;
    setState(() => _entry = lib.entryFor(widget.anime.malId));
    if (!mounted) return;
    final fav = lib.isFavorite(widget.anime.malId);
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(fav ? s.addedToLibrary : s.removedFromLibrary)));
  }

  Future<void> _removeFromLibrary() async {
    final s = S(context.read<SettingsProvider>().isArabic);
    final lib = context.read<LibraryProvider>();
    await lib.remove(_a);
    if (!mounted) return;
    setState(() => _entry = null);
    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(s.removedFromLibrary)));
  }

  Future<void> _bumpEpisode(int delta) async {
    final lib = context.read<LibraryProvider>();
    await lib.bumpEpisode(_a, delta);
    if (!mounted) return;
    setState(() => _entry = lib.entryFor(widget.anime.malId));
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

  Widget _librarySection(BuildContext context, Anime a) {
    final pal = context.watch<SettingsProvider>().palette;
    final ar = context.watch<SettingsProvider>().isArabic;
    final s = S(ar);
    final entry = _entry;
    final fav = entry?.isFavorite ?? false;
    final last = entry?.lastEpisode ?? 0;
    final total = a.episodes ?? 0;
    final progress =
        total > 0 ? (last / total).clamp(0.0, 1.0).toDouble() : 0.0;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: pal.surface,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            IconButton(
              onPressed: _toggleFavorite,
              icon: Icon(
                  fav
                      ? Icons.favorite_rounded
                      : Icons.favorite_border_rounded,
                  color: fav ? pal.accent : pal.textDim),
            ),
            Expanded(
              child: Text(
                entry == null ? s.addToLibrary : _statusLabel(s, entry.status),
                style:
                    TextStyle(color: pal.text, fontWeight: FontWeight.w700),
              ),
            ),
            if (entry != null)
              TextButton.icon(
                onPressed: _removeFromLibrary,
                icon: Icon(Icons.delete_outline_rounded,
                    size: 18, color: pal.textDim),
                label: Text(s.removeFromLibrary,
                    style: TextStyle(color: pal.textDim)),
              ),
          ]),
          const SizedBox(height: 4),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final st in libraryStatuses)
                ChoiceChip(
                  label: Text(_statusLabel(s, st)),
                  selected: entry?.status == st,
                  onSelected: (selected) {
                    if (selected) {
                      _setStatus(st);
                    } else {
                      _removeFromLibrary();
                    }
                  },
                  selectedColor: pal.accent,
                  backgroundColor: pal.surfaceHi,
                  labelStyle: TextStyle(color: pal.text),
                ),
            ],
          ),
          if (entry?.status == 'watching') ...[
            const SizedBox(height: 12),
            Row(children: [
              IconButton(
                onPressed: () => _bumpEpisode(-1),
                icon: Icon(Icons.remove_rounded, color: pal.text),
                visualDensity: VisualDensity.compact,
              ),
              Expanded(
                child: Text(
                  total > 0
                      ? s.episodeProgress(last, total)
                      : '${s.lastEpisode}: $last',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: pal.text),
                ),
              ),
              IconButton(
                onPressed: () => _bumpEpisode(1),
                icon: Icon(Icons.add_rounded, color: pal.accent),
                visualDensity: VisualDensity.compact,
              ),
            ]),
            const SizedBox(height: 4),
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
        ],
      ),
    );
  }

  Future<void> _loadArabic(AnimeRepository repo, Anime a) async {
    if (a.arChecked) return;
    setState(() => _loadingAr = true);
    final r = await repo.getArabic(a);
    if (!mounted) return;
    setState(() {
      _a = r.anime;
      _arError = r.error;
      _loadingAr = false;
    });
  }

  Future<void> _loadChars(AnimeRepository repo) async {
    final list = await repo.getCharacters(widget.anime.malId);
    if (!mounted) return;
    setState(() {
      _chars = list;
      _loadingChars = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final a = _a;
    final pal = context.watch<SettingsProvider>().palette;
    return Scaffold(
      backgroundColor: pal.bg,
      body: CustomScrollView(slivers: [
        SliverAppBar(
          pinned: true,
          expandedHeight: 440,
          backgroundColor: pal.bg,
          flexibleSpace: FlexibleSpaceBar(
            background: Stack(fit: StackFit.expand, children: [
              PosterImage(url: a.imageUrl, radius: 0),
              DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      const Color(0x00000000),
                      pal.bg.withAlpha(102),
                      pal.bg,
                    ],
                    stops: const [0.35, 0.7, 1.0],
                  ),
                ),
              ),
            ]),
          ),
        ),
        SliverToBoxAdapter(child: _content(context, a)),
      ]),
    );
  }

  Widget _synopsis(BuildContext context, Anime a) {
    final settings = context.watch<SettingsProvider>();
    final pal = settings.palette;
    final ar = settings.isArabic;
    final s = S(ar);
    final hasEn = a.synopsis != null && a.synopsis!.isNotEmpty;
    final children = <Widget>[];

    if (ar && (a.synopsisAr?.isNotEmpty ?? false)) {
      return Text(a.synopsisAr!,
          style: TextStyle(
              height: 1.8, fontSize: 15.5, color: pal.text));
    }

    if (ar) {
      String? note;
      if (_loadingAr) {
        note = s.fetchingArabic;
      } else if (!_loadingEn) {
        if (settings.tmdbKey.isEmpty) {
          note = s.needKey;
        } else if (_arError != null) {
          note = s.arabicError(_arError!);
        } else if (hasEn) {
          note = s.noArabicSynopsis;
        }
      }
      if (note != null) {
        children.add(Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Text(note,
              style: TextStyle(fontSize: 12.5, color: pal.accent)),
        ));
      }
    }

    if (_loadingEn || _loadingAr) {
      children.add(const Padding(
        padding: EdgeInsets.only(bottom: 10),
        child: LinearProgressIndicator(minHeight: 2),
      ));
    }

    if (hasEn) {
      children.add(Text(a.synopsis!,
          textDirection: TextDirection.ltr,
          textAlign: TextAlign.left,
          style: TextStyle(height: 1.5, color: pal.text)));
    } else if (!_loadingEn) {
      children.add(Text(s.noSynopsis,
          style: TextStyle(color: pal.textDim)));
      children.add(const SizedBox(height: 8));
      children.add(OutlinedButton.icon(
        onPressed: _retry,
        icon: const Icon(Icons.refresh_rounded),
        label: Text(s.retry),
      ));
    }
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: children);
  }

  Widget _content(BuildContext context, Anime a) {
    final ar = context.watch<SettingsProvider>().isArabic;
    final pal = context.watch<SettingsProvider>().palette;
    final s = S(ar);
    final title = a.titleFor(ar);
    final sub = (ar && title != a.displayTitle)
        ? a.displayTitle
        : (a.title != title ? a.title : null);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(title,
            style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w800)),
        if (sub != null)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(sub,
                textDirection: TextDirection.ltr,
                style: TextStyle(color: pal.textDim)),
          ),
        const SizedBox(height: 14),
        Wrap(spacing: 8, runSpacing: 8, children: [
          if (a.score != null)
            InfoChip(a.score!.toStringAsFixed(2), icon: Icons.star_rounded),
          if (a.type != null) InfoChip(s.type(a.type), icon: Icons.tv_rounded),
          if (a.episodes != null && a.episodes! > 0)
            InfoChip(s.episodes(a.episodes!), icon: Icons.list_rounded),
          InfoChip(s.status(a.status), icon: Icons.circle),
          if (a.year != null)
            InfoChip(
                a.season != null ? '${s.season(a.season)} ${a.year}' : '${a.year}',
                icon: Icons.calendar_today_rounded),
        ]),
        const SizedBox(height: 16),
        _librarySection(context, a),
        if (a.genres.isNotEmpty) ...[
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: a.genres
                .map((g) => Chip(
                      label: Text(s.genre(g), style: const TextStyle(fontSize: 12)),
                      backgroundColor: pal.accent.withAlpha(50),
                      side: BorderSide.none,
                      visualDensity: VisualDensity.compact,
                    ))
                .toList(),
          ),
        ],
        const SizedBox(height: 20),
        Text(s.synopsis,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
        const SizedBox(height: 8),
        _synopsis(context, a),
        if (a.studios.isNotEmpty) ...[
          const SizedBox(height: 16),
          Text(s.studio(a.studios.join(ar ? '، ' : ', ')),
              style: TextStyle(color: pal.textDim)),
        ],
        const SizedBox(height: 24),
        Text(s.characters,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
        const SizedBox(height: 12),
        SizedBox(height: 128, child: _charList(s, pal)),
      ]),
    );
  }

  Widget _charList(S s, AppPalette pal) {
    if (_chars.isEmpty) {
      return Text(_loadingChars || _loadingEn ? s.loading : s.noCharacters,
          style: TextStyle(color: pal.textDim));
    }
    return ListView.separated(
      scrollDirection: Axis.horizontal,
      itemCount: _chars.length,
      separatorBuilder: (_, __) => const SizedBox(width: 14),
      itemBuilder: (_, i) => SizedBox(
        width: 80,
        child: Column(children: [
          SizedBox(
            width: 80,
            height: 80,
            child: PosterImage(url: _chars[i].imageUrl, radius: 40),
          ),
          const SizedBox(height: 6),
          Text(_chars[i].name,
              maxLines: 2,
              textAlign: TextAlign.center,
              textDirection: TextDirection.ltr,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 11)),
        ]),
      ),
    );
  }
}
