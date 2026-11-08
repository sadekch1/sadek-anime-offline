import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/theme.dart';

class SettingsProvider extends ChangeNotifier {
  SettingsProvider(this._prefs)
      : _lang = _prefs.getString('lang') ?? 'ar',
        _userKey = _prefs.getString('tmdb_key') ?? '',
        _themeId = _prefs.getString('theme_id') ?? 'dark',
        _customCss = _prefs.getString('custom_css') ?? '';
  final SharedPreferences _prefs;
  String _lang;
  String _userKey;
  String _themeId;
  String _customCss;

  bool get isArabic => _lang == 'ar';
  Locale get locale => Locale(_lang);
  String get userKey => _userKey;

  /// Key typed in Settings wins; otherwise the one baked in at build time.
  String get tmdbKey =>
      _userKey.isNotEmpty ? _userKey : const String.fromEnvironment('TMDB_API_KEY');

  // ---- Themes (v2) ----
  String get themeId => _themeId;
  String get customCss => _customCss;
  bool get hasCustomCss => _customCss.trim().isNotEmpty;
  AppThemeDef get themeDef => themeById(_themeId);
  bool get isDark => themeDef.isDark;

  /// Active palette: custom CSS (if any) applied over the chosen base theme.
  AppPalette get palette => hasCustomCss
      ? paletteFromCss(_customCss, themeDef.palette)
      : themeDef.palette;

  Future<void> setTheme(String id) async {
    _themeId = id;
    await _prefs.setString('theme_id', id);
    notifyListeners();
  }

  Future<void> setCustomCss(String css) async {
    _customCss = css;
    await _prefs.setString('custom_css', css);
    notifyListeners();
  }

  Future<void> clearCustomCss() async {
    _customCss = '';
    await _prefs.remove('custom_css');
    notifyListeners();
  }

  Future<void> setLang(String lang) async {
    _lang = lang;
    await _prefs.setString('lang', lang);
    notifyListeners();
  }

  Future<void> setTmdbKey(String key) async {
    _userKey = key.trim();
    await _prefs.setString('tmdb_key', _userKey);
    notifyListeners();
  }
}
