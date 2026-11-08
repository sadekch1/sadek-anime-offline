import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sadek_anime_offline/core/theme.dart';

void main() {
  test('parseCssVariables reads --name: #hex; pairs', () {
    final vars = parseCssVariables('''
      /* comment */
      --bg: #0F1015;
      --accent: #6366F1;
      --text-dim: #9CA3AF;
      --star: #FBBF24
    ''');
    expect(vars['bg'], '#0F1015');
    expect(vars['accent'], '#6366F1');
    expect(vars['text-dim'], '#9CA3AF');
    expect(vars['star'], '#FBBF24');
    expect(vars.containsKey('comment'), isFalse);
  });

  test('paletteFromCss applies the example CSS over dark', () {
    final pal = paletteFromCss(cssThemeExample, themeById('dark').palette);
    expect(pal.bg, const Color(0xFF0F1015));
    expect(pal.accent, const Color(0xFF6366F1));
    expect(pal.text, const Color(0xFFFFFFFF));
    expect(pal.star, const Color(0xFFFBBF24));
  });

  test('paletteFromCss keeps base for missing/invalid values', () {
    final base = themeById('crimson').palette;
    final pal = paletteFromCss('--accent: #00FF00;\n--bg: not-a-color;', base);
    expect(pal.accent, const Color(0xFF00FF00));
    expect(pal.bg, base.bg);
    expect(pal.surface, base.surface);
  });

  test('paletteFromCss handles 3-digit hex', () {
    final pal = paletteFromCss('--accent: #F00;', themeById('dark').palette);
    expect(pal.accent, const Color(0xFFFF0000));
  });

  test('five built-in themes exist with distinct accents', () {
    expect(appThemes.length, 5);
    expect(appThemes.map((t) => t.id).toSet().length, 5);
    expect(appThemes.map((t) => t.palette.accent).toSet().length, 5);
  });
}
