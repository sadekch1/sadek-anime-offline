import 'package:flutter/material.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:provider/provider.dart';

import '../../core/strings.dart';
import '../../core/theme.dart';
import '../../data/remote/firebase_sync.dart';
import '../../domain/repositories/anime_repository.dart';
import '../providers/settings_provider.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});
  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late Future<Map<String, int>> _stats;
  late final TextEditingController _key;
  late final TextEditingController _css;

  @override
  void initState() {
    super.initState();
    _stats = context.read<AnimeRepository>().stats();
    _key = TextEditingController(text: context.read<SettingsProvider>().userKey);
    _css = TextEditingController(text: context.read<SettingsProvider>().customCss);
  }

  @override
  void dispose() {
    _key.dispose();
    _css.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsProvider>();
    final pal = settings.palette;
    final s = S(settings.isArabic);
    final sync = context.watch<FirebaseSync>();
    return SafeArea(
      child: ListView(padding: const EdgeInsets.all(16), children: [
        Text(s.settings,
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: pal.text)),
        const SizedBox(height: 16),
        _card(pal, [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(s.language,
                  style: TextStyle(fontWeight: FontWeight.w700, color: pal.text)),
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                child: SegmentedButton<String>(
                  segments: const [
                    ButtonSegment(value: 'ar', label: Text('العربية')),
                    ButtonSegment(value: 'en', label: Text('English')),
                  ],
                  selected: {settings.isArabic ? 'ar' : 'en'},
                  onSelectionChanged: (v) => settings.setLang(v.first),
                ),
              ),
            ]),
          ),
        ]),
        const SizedBox(height: 12),
        // ---- v2: themes ----
        _card(pal, [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(s.themes,
                  style: TextStyle(fontWeight: FontWeight.w700, color: pal.text)),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: appThemes.map((t) {
                  final selected = settings.themeId == t.id;
                  return ChoiceChip(
                    label: Text(settings.isArabic ? t.nameAr : t.nameEn),
                    selected: selected,
                    avatar: CircleAvatar(
                        radius: 7, backgroundColor: t.palette.accent),
                    onSelected: (_) => settings.setTheme(t.id),
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),
              Text(s.customTheme,
                  style: TextStyle(fontWeight: FontWeight.w700, color: pal.text)),
              const SizedBox(height: 8),
              TextField(
                controller: _css,
                maxLines: 8,
                textDirection: TextDirection.ltr,
                style: TextStyle(fontFamily: 'monospace', color: pal.text),
                decoration: InputDecoration(
                  isDense: true,
                  filled: true,
                  fillColor: pal.surfaceHi,
                  hintText: cssThemeExample,
                  hintStyle: TextStyle(color: pal.textDim),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Text(s.customThemeHelp,
                  style: TextStyle(fontSize: 12, color: pal.textDim)),
              const SizedBox(height: 8),
              Row(children: [
                TextButton(
                  onPressed: () => setState(() => _css.text = cssThemeExample),
                  child: Text(s.customThemeExample),
                ),
                const Spacer(),
                TextButton(
                  onPressed: () async {
                    await settings.clearCustomCss();
                    if (mounted) setState(() => _css.clear());
                  },
                  child: Text(s.resetTheme),
                ),
                FilledButton(
                  onPressed: () async {
                    final messenger = ScaffoldMessenger.of(context);
                    await settings.setCustomCss(_css.text);
                    messenger.showSnackBar(SnackBar(content: Text(s.themeApplied)));
                  },
                  child: Text(s.save),
                ),
              ]),
            ]),
          ),
        ]),
        const SizedBox(height: 12),
        // ---- v2: Google sign-in / sync ----
        _card(pal, [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(s.googleSignIn,
                  style: TextStyle(fontWeight: FontWeight.w700, color: pal.text)),
              const SizedBox(height: 8),
              if (!sync.available)
                Text(s.firebaseNotConfigured,
                    style: TextStyle(fontSize: 12.5, color: pal.textDim))
              else if (sync.signedIn)
                Text('${s.signedInAs} ${sync.userEmail ?? ''}',
                    style: TextStyle(fontSize: 13, color: pal.text))
              else
                Text(s.notSignedIn,
                    style: TextStyle(fontSize: 12.5, color: pal.textDim)),
              const SizedBox(height: 10),
              Row(children: [
                if (sync.available && !sync.signedIn)
                  FilledButton.icon(
                    onPressed: () async {
                      final ok = await sync.signInWithGoogle();
                      if (!mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                          content: Text(ok ? s.syncDone : s.syncFailed)));
                    },
                    icon: const Icon(Icons.login_rounded),
                    label: Text(s.googleSignIn),
                  ),
                if (sync.available && sync.signedIn) ...[
                  FilledButton.icon(
                    onPressed: () async {
                      final ok = await sync.syncNow();
                      if (!mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                          content: Text(ok ? s.syncDone : s.syncFailed)));
                    },
                    icon: const Icon(Icons.sync_rounded),
                    label: Text(s.syncNow),
                  ),
                  const SizedBox(width: 8),
                  OutlinedButton(
                    onPressed: () => sync.signOut(),
                    child: Text(s.googleSignOut),
                  ),
                ],
              ]),
            ]),
          ),
        ]),
        const SizedBox(height: 12),
        _card(pal, [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(s.tmdbKeyLabel,
                  style: TextStyle(fontWeight: FontWeight.w700, color: pal.text)),
              const SizedBox(height: 10),
              TextField(
                controller: _key,
                textDirection: TextDirection.ltr,
                decoration: InputDecoration(
                  isDense: true,
                  filled: true,
                  fillColor: pal.surfaceHi,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Text(s.tmdbKeyHelp,
                  style: TextStyle(fontSize: 12, color: pal.textDim)),
              const SizedBox(height: 8),
              Align(
                alignment: AlignmentDirectional.centerEnd,
                child: FilledButton(
                  onPressed: () async {
                    final messenger = ScaffoldMessenger.of(context);
                    await settings.setTmdbKey(_key.text);
                    messenger.showSnackBar(SnackBar(content: Text(s.saved)));
                  },
                  child: Text(s.save),
                ),
              ),
            ]),
          ),
        ]),
        const SizedBox(height: 12),
        FutureBuilder<Map<String, int>>(
          future: _stats,
          builder: (_, snap) {
            final d = snap.data;
            return _card(pal, [
              _row(pal, s.dbCount, '${d?['anime'] ?? '…'}'),
              _row(pal, s.detailedCount, '${d?['detailed'] ?? '…'}'),
              _row(pal, s.arabicCount, '${d?['arabic'] ?? '…'}'),
              _row(pal, s.charsCount, '${d?['characters'] ?? '…'}'),
            ]);
          },
        ),
        const SizedBox(height: 12),
        _card(pal, [
          ListTile(
            leading: const Icon(Icons.refresh_rounded),
            title: Text(s.refreshStats, style: TextStyle(color: pal.text)),
            onTap: () => setState(
                () => _stats = context.read<AnimeRepository>().stats()),
          ),
          ListTile(
            leading: const Icon(Icons.delete_outline_rounded),
            title: Text(s.clearImages, style: TextStyle(color: pal.text)),
            subtitle: Text(s.clearImagesSub),
            onTap: () async {
              final messenger = ScaffoldMessenger.of(context);
              await DefaultCacheManager().emptyCache();
              messenger.showSnackBar(SnackBar(content: Text(s.imagesCleared)));
            },
          ),
        ]),
        const SizedBox(height: 12),
        _card(pal, [
          ListTile(
            leading: const Icon(Icons.info_outline_rounded),
            title: const Text('sadek-anime-offline', textDirection: TextDirection.ltr),
            subtitle: Text(s.about),
          ),
        ]),
      ]),
    );
  }

  Widget _card(AppPalette pal, List<Widget> children) => Container(
        decoration: BoxDecoration(
          color: pal.surface,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(children: children),
      );

  Widget _row(AppPalette pal, String k, String v) => ListTile(
        title: Text(k, style: TextStyle(color: pal.text)),
        trailing: Text(v,
            style: TextStyle(color: pal.accent, fontWeight: FontWeight.w700)),
      );
}
