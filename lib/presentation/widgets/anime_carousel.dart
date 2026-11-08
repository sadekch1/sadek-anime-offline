import 'package:flutter/material.dart';

import '../../domain/entities/anime.dart';
import 'anime_card.dart';

class AnimeCarousel extends StatelessWidget {
  const AnimeCarousel({super.key, required this.title, required this.items});
  final String title;
  final List<Anime> items;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 20, 16, 10),
          child: Text(title,
              style:
                  const TextStyle(fontSize: 19, fontWeight: FontWeight.w700)),
        ),
        SizedBox(
          height: 245,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: items.length,
            separatorBuilder: (_, __) => const SizedBox(width: 12),
            itemBuilder: (_, i) =>
                SizedBox(width: 128, child: AnimeCard(anime: items[i])),
          ),
        ),
      ],
    );
  }
}
