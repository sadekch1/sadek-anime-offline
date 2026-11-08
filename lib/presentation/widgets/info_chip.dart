import 'package:flutter/material.dart';

import 'package:provider/provider.dart';

import '../providers/settings_provider.dart';

class InfoChip extends StatelessWidget {
  const InfoChip(this.text, {super.key, this.icon});
  final String text;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final pal = context.watch<SettingsProvider>().palette;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: pal.surfaceHi,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        if (icon != null) ...[
          Icon(icon, size: 14, color: pal.accent),
          const SizedBox(width: 4),
        ],
        Text(text, style: const TextStyle(fontSize: 12)),
      ]),
    );
  }
}
