import 'package:flutter/material.dart';

import 'package:provider/provider.dart';

import '../../core/strings.dart';
import '../../core/theme.dart';
import '../providers/settings_provider.dart';
import '../../domain/entities/anime.dart';
import '../screens/detail_screen.dart';
import 'poster_image.dart';

class AnimeCard extends StatelessWidget {
  const AnimeCard({super.key, required this.anime});
  final Anime anime;

  @override
  Widget build(BuildContext context) {
    final ar = context.watch<SettingsProvider>().isArabic;
    final pal = context.watch<SettingsProvider>().palette;
    final s = S(ar);
    return GestureDetector(
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => DetailScreen(anime: anime)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Stack(fit: StackFit.expand, children: [
              PosterImage(url: anime.imageUrl),
              if (anime.score != null)
                Positioned(
                  top: 6,
                  left: 6,
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                    decoration: BoxDecoration(
                      color: pal.bg.withAlpha(204),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(mainAxisSize: MainAxisSize.min, children: [
                      Icon(Icons.star_rounded,
                          size: 13, color: pal.star),
                      const SizedBox(width: 2),
                      Text(anime.score!.toStringAsFixed(1),
                          style: const TextStyle(
                              fontSize: 11, fontWeight: FontWeight.w600)),
                    ]),
                  ),
                ),
            ]),
          ),
          const SizedBox(height: 6),
          Text(
            anime.titleFor(ar),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w500),
          ),
          Text(
            [if (anime.type != null) s.type(anime.type), if (anime.year != null) '${anime.year}']
                .join(' • '),
            style: TextStyle(fontSize: 11, color: pal.textDim),
          ),
        ],
      ),
    );
  }
}
