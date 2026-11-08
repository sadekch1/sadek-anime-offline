import 'package:flutter/material.dart';

/// A theme palette: every colour the UI uses. All screens must read colours
/// from the active palette (via SettingsProvider.palette) — never hard-code
/// a colour in a screen/widget. The old static [AppColors] values below are
/// kept only as the dark-theme defaults for code that has no BuildContext.
class AppPalette {
  final Color bg;
  final Color surface;
  final Color surfaceHi;
  final Color accent;
  final Color accent2;
  final Color text;
  final Color textDim;
  final Color star;
  const AppPalette({
    required this.bg,
    required this.surface,
    required this.surfaceHi,
    required this.accent,
    required this.accent2,
    required this.text,
    required this.textDim,
    required this.star,
  });

  AppPalette copyWith({
    Color? bg,
    Color? surface,
    Color? surfaceHi,
    Color? accent,
    Color? accent2,
    Color? text,
    Color? textDim,
    Color? star,
  }) =>
      AppPalette(
        bg: bg ?? this.bg,
        surface: surface ?? this.surface,
        surfaceHi: surfaceHi ?? this.surfaceHi,
        accent: accent ?? this.accent,
        accent2: accent2 ?? this.accent2,
        text: text ?? this.text,
        textDim: textDim ?? this.textDim,
        star: star ?? this.star,
      );
}

class AppThemeDef {
  final String id;
  final String nameAr;
  final String nameEn;
  final bool isDark;
  final AppPalette palette;
  const AppThemeDef({
    required this.id,
    required this.nameAr,
    required this.nameEn,
    required this.isDark,
    required this.palette,
  });
}

const _darkPalette = AppPalette(
  bg: Color(0xFF0F1015),
  surface: Color(0xFF181A22),
  surfaceHi: Color(0xFF22252F),
  accent: Color(0xFF6366F1),
  accent2: Color(0xFF8B5CF6),
  text: Colors.white,
  textDim: Color(0xFF9CA3AF),
  star: Color(0xFFFBBF24),
);

const _lightPalette = AppPalette(
  bg: Color(0xFFF6F7FB),
  surface: Color(0xFFFFFFFF),
  surfaceHi: Color(0xFFE9ECF3),
  accent: Color(0xFF4F46E5),
  accent2: Color(0xFF7C3AED),
  text: Color(0xFF111827),
  textDim: Color(0xFF6B7280),
  star: Color(0xFFD97706),
);

const _crimsonPalette = AppPalette(
  bg: Color(0xFF160A0E),
  surface: Color(0xFF221014),
  surfaceHi: Color(0xFF2E151B),
  accent: Color(0xFFE11D48),
  accent2: Color(0xFFF43F5E),
  text: Colors.white,
  textDim: Color(0xFFD6A5B0),
  star: Color(0xFFFBBF24),
);

const _oceanPalette = AppPalette(
  bg: Color(0xFF071418),
  surface: Color(0xFF0D2229),
  surfaceHi: Color(0xFF12303A),
  accent: Color(0xFF06B6D4),
  accent2: Color(0xFF0EA5E9),
  text: Colors.white,
  textDim: Color(0xFF9DB8C0),
  star: Color(0xFFFBBF24),
);

const _forestPalette = AppPalette(
  bg: Color(0xFF0B130C),
  surface: Color(0xFF142015),
  surfaceHi: Color(0xFF1C2E1E),
  accent: Color(0xFF22C55E),
  accent2: Color(0xFF84CC16),
  text: Colors.white,
  textDim: Color(0xFFA8BFA9),
  star: Color(0xFFFBBF24),
);

const List<AppThemeDef> appThemes = [
  AppThemeDef(
      id: 'dark', nameAr: 'داكن', nameEn: 'Dark', isDark: true, palette: _darkPalette),
  AppThemeDef(
      id: 'light', nameAr: 'فاتح', nameEn: 'Light', isDark: false, palette: _lightPalette),
  AppThemeDef(
      id: 'crimson',
      nameAr: 'قرمزي',
      nameEn: 'Crimson',
      isDark: true,
      palette: _crimsonPalette),
  AppThemeDef(
      id: 'ocean',
      nameAr: 'محيطي',
      nameEn: 'Ocean',
      isDark: true,
      palette: _oceanPalette),
  AppThemeDef(
      id: 'forest',
      nameAr: 'غابة',
      nameEn: 'Forest',
      isDark: true,
      palette: _forestPalette),
];

AppThemeDef themeById(String id) =>
    appThemes.firstWhere((t) => t.id == id, orElse: () => appThemes.first);

/// Example custom-CSS theme, pre-filled in Settings.
const String cssThemeExample = '''--bg: #0F1015;
--surface: #181A22;
--surface-hi: #22252F;
--accent: #6366F1;
--accent2: #8B5CF6;
--text: #FFFFFF;
--text-dim: #9CA3AF;
--star: #FBBF24;''';

/// Parses CSS custom properties: `--name: #hex;` (also accepts lines
/// without a trailing `;` and `/* comments */`). Unknown names are ignored.
/// Returns a map of name -> raw value (e.g. {'bg': '#0F1015'}).
Map<String, String> parseCssVariables(String css) {
  final out = <String, String>{};
  final noComments =
      css.replaceAll(RegExp(r'/\*.*?\*/', dotAll: true), ' ');
  final re = RegExp(r'--([a-zA-Z0-9_-]+)\s*:\s*([^;}\n]+)');
  for (final m in re.allMatches(noComments)) {
    out[m.group(1)!.trim().toLowerCase()] = m.group(2)!.trim();
  }
  return out;
}

Color? _parseHex(String raw) {
  var s = raw.trim();
  if (s.startsWith('#')) s = s.substring(1);
  if (s.length == 3) s = s.split('').map((c) => '$c$c').join();
  if (s.length == 6) s = 'FF$s';
  if (s.length != 8) return null;
  final v = int.tryParse(s, radix: 16);
  return v == null ? null : Color(v);
}

/// Applies CSS variables over [base] (missing/invalid values keep the base).
AppPalette paletteFromCss(String css, AppPalette base) {
  final vars = parseCssVariables(css);
  Color? c(String name) {
    final v = vars[name];
    return v == null ? null : _parseHex(v);
  }

  return base.copyWith(
    bg: c('bg'),
    surface: c('surface'),
    surfaceHi: c('surface-hi') ?? c('surfacehi') ?? c('surface_hi'),
    accent: c('accent'),
    accent2: c('accent2') ?? c('accent-2'),
    text: c('text'),
    textDim: c('text-dim') ?? c('textdim') ?? c('text_dim'),
    star: c('star'),
  );
}

/// Legacy defaults (dark theme) for code without a BuildContext.
/// New code must use SettingsProvider.palette instead.
class AppColors {
  static const bg = Color(0xFF0F1015);
  static const surface = Color(0xFF181A22);
  static const surfaceHi = Color(0xFF22252F);
  static const accent = Color(0xFF6366F1);
  static const accent2 = Color(0xFF8B5CF6);
  static const textDim = Color(0xFF9CA3AF);
}

ThemeData buildTheme([AppPalette p = _darkPalette, bool isDark = true]) {
  final scheme = ColorScheme.fromSeed(
    seedColor: p.accent,
    brightness: isDark ? Brightness.dark : Brightness.light,
  ).copyWith(primary: p.accent, surface: p.surface);
  return ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    scaffoldBackgroundColor: p.bg,
    appBarTheme: AppBarTheme(
      backgroundColor: p.bg,
      elevation: 0,
      scrolledUnderElevation: 0,
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: p.surface,
      indicatorColor: p.accent.withAlpha(80),
    ),
    textTheme: (isDark ? Typography.whiteMountainView : Typography.blackMountainView)
        .apply(bodyColor: p.text, displayColor: p.text),
  );
}
