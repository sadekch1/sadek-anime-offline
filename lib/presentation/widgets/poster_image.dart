import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../../core/image_utils.dart';
import '../../core/theme.dart';
import 'package:provider/provider.dart';
import '../providers/settings_provider.dart';

/// Fetches WebP posters on demand and caches them on disk for offline use.
class PosterImage extends StatelessWidget {
  const PosterImage({
    super.key,
    required this.url,
    this.fit = BoxFit.cover,
    this.radius = 12,
  });
  final String? url;
  final BoxFit fit;
  final double radius;

  Widget _placeholder(BuildContext context, IconData? icon) {
    final pal = context.watch<SettingsProvider>().palette;
    return Container(
      color: pal.surfaceHi,
      alignment: Alignment.center,
      child: icon == null ? null : Icon(icon, color: pal.textDim),
    );
  }

  @override
  Widget build(BuildContext context) {
    final u = optimizedImageUrl(url);
    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: u == null
          ? _placeholder(context, Icons.image_not_supported_outlined)
          : CachedNetworkImage(
              imageUrl: u,
              fit: fit,
              memCacheWidth: 500,
              fadeInDuration: const Duration(milliseconds: 150),
              placeholder: (_, __) => _placeholder(context, null),
              errorWidget: (_, __, ___) =>
                  _placeholder(context, Icons.broken_image_outlined),
            ),
    );
  }
}
