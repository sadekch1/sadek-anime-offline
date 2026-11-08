import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/strings.dart';
import '../../core/theme.dart';
import '../providers/settings_provider.dart';
import '../providers/home_provider.dart';
import '../widgets/anime_carousel.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final h = context.watch<HomeProvider>();
    final pal = context.watch<SettingsProvider>().palette;
    final s = S.of(context);
    return SafeArea(
      child: RefreshIndicator(
        color: pal.accent,
        onRefresh: h.load,
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            SliverToBoxAdapter(child: _header(s, pal)),
            if (h.loading && h.isEmpty)
              const SliverFillRemaining(
                  hasScrollBody: false,
                  child: Center(child: CircularProgressIndicator()))
            else if (h.isEmpty)
              SliverFillRemaining(
                hasScrollBody: false,
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.all(32),
                    child: Text(s.noLocalData,
                        textAlign: TextAlign.center,
                        style: TextStyle(color: pal.textDim)),
                  ),
                ),
              )
            else ...[
              SliverToBoxAdapter(
                  child: AnimeCarousel(title: s.trending, items: h.trending)),
              SliverToBoxAdapter(
                  child: AnimeCarousel(title: s.topRated, items: h.topRated)),
              SliverToBoxAdapter(
                  child: AnimeCarousel(title: s.topMovies, items: h.movies)),
              const SliverToBoxAdapter(child: SizedBox(height: 24)),
            ],
          ],
        ),
      ),
    );
  }

  Widget _header(S s, AppPalette pal) => Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
        child: Row(children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              gradient: LinearGradient(
                  colors: [pal.accent, pal.accent2]),
            ),
            child: const Icon(Icons.auto_awesome, color: Colors.white),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('sadek-anime-offline',
                    textDirection: TextDirection.ltr,
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
                Text(s.tagline,
                    style: TextStyle(fontSize: 12, color: pal.textDim)),
              ],
            ),
          ),
        ]),
      );
}
