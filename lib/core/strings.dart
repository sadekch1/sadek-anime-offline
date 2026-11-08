import 'package:flutter/widgets.dart';
import 'package:provider/provider.dart';

import '../presentation/providers/settings_provider.dart';

/// Hand-written Arabic/English UI strings (no machine translation).
class S {
  final bool ar;
  const S(this.ar);
  static S of(BuildContext c) => S(c.watch<SettingsProvider>().isArabic);

  String _t(String a, String e) => ar ? a : e;

  String get home => _t('الرئيسية', 'Home');
  String get search => _t('بحث', 'Search');
  String get settings => _t('الإعدادات', 'Settings');
  String get tagline => _t('مكتبتك للأنمي بدون إنترنت', 'Your offline anime library');
  String get trending => _t('يُعرض الآن', 'Trending Now');
  String get topRated => _t('الأعلى تقييماً', 'Top Rated');
  String get topMovies => _t('أفضل الأفلام', 'Top Movies');
  String get noLocalData => _t(
      'لا توجد بيانات محلية بعد.\nاتصل بالإنترنت ثم اسحب للتحديث.',
      'No local data yet.\nConnect to the internet and pull to refresh.');
  String get searchHint => _t('ابحث في أكثر من 20,000 أنمي…', 'Search 20,000+ anime…');
  String get searchEmpty =>
      _t('اكتب اسم الأنمي للبحث الفوري', 'Type a title to search instantly');
  String get searchingOnline => _t('جارٍ البحث عبر الإنترنت…', 'Searching online…');
  String get noResults => _t('لا توجد نتائج', 'No results');
  String get synopsis => _t('القصة', 'Synopsis');
  String get characters => _t('الشخصيات', 'Characters');
  String get noCharacters => _t('لا توجد شخصيات محفوظة.', 'No characters cached.');
  String get loading => _t('جارٍ التحميل…', 'Loading…');
  String get noSynopsis => _t(
      'لم تُحفظ القصة بعد. افتح هذا الأنمي مرة واحدة وأنت متصل بالإنترنت لتُحفظ للاستخدام بدون إنترنت.',
      'Synopsis not cached yet. Open this title once while online and it will be saved for offline use.');
  String get noArabicSynopsis => _t(
      'لا يوجد ملخص عربي لهذا العمل في المصدر، والملخص التالي بالإنجليزية.',
      'No Arabic synopsis is available for this title; showing the English one.');
  String get needKey => _t(
      'لعرض القصص بالعربية أضف مفتاح TMDB من الإعدادات. الملخص التالي بالإنجليزية.',
      'To get Arabic stories, add a TMDB key in Settings. Showing English for now.');
  String studio(String names) =>
      _t('الاستوديو: \u2066$names\u2069', 'Studio: $names');
  String episodes(int n) => _t('$n حلقة', '$n eps');

  // settings
  String get language => _t('اللغة', 'Language');
  String get dbCount => _t('عدد الأنمي في القاعدة المحلية', 'Anime in local database');
  String get detailedCount => _t('أعمال محفوظة بتفاصيلها', 'Titles with full details cached');
  String get arabicCount => _t('أعمال محفوظة بقصة عربية', 'Titles with Arabic synopsis');
  String get charsCount => _t('شخصيات محفوظة', 'Characters cached');
  String get refreshStats => _t('تحديث الإحصائيات', 'Refresh statistics');
  String get clearImages => _t('مسح ذاكرة الصور', 'Clear image cache');
  String get clearImagesSub => _t(
      'ستُحمَّل الصور من جديد عند الاتصال بالإنترنت', 'Posters will be re-downloaded when online');
  String get imagesCleared => _t('تم مسح ذاكرة الصور', 'Image cache cleared');
  String get tmdbKeyLabel => _t('مفتاح TMDB (للقصص العربية)', 'TMDB API key (Arabic stories)');
  String get tmdbKeyHelp => _t(
      'مجاني من themoviedb.org ← الإعدادات ← API. القصص العربية مكتوبة من مجتمع TMDB وليست ترجمة آلية، وقد لا تتوفر لكل الأعمال.',
      'Free at themoviedb.org → Settings → API. Arabic text is community-written, not machine-translated, and may not exist for every title.');
  String get save => _t('حفظ', 'Save');
  String get saved => _t('تم الحفظ', 'Saved');
  String get about => _t(
      'بيانات الأنمي محفوظة محلياً. المصادر عند الحاجة: Jikan (MyAnimeList) وTMDB. الصور تُخزَّن بصيغة WebP.',
      'Offline-first anime metadata. Fallback sources: Jikan (MyAnimeList) and TMDB. Posters are cached as WebP.');

  String get retry => _t('إعادة المحاولة', 'Retry');
  String get fetchingArabic => _t('جارٍ جلب القصة العربية…', 'Fetching Arabic synopsis…');
  String arabicError(String e) => _t(
      'تعذّر جلب القصة العربية ($e). تحقق من المفتاح ومن الاتصال بالإنترنت.',
      'Could not fetch the Arabic synopsis ($e). Check the key and your connection.');


  // ---- v2: filter ----
  String get filter => _t('الفلتر', 'Filter');
  String get advancedFilter => _t('الفلتر المتقدم', 'Advanced filter');
  String get apply => _t('تطبيق', 'Apply');
  String resultsCount(int n) => _t('عرض $n نتيجة', 'Show $n results');
  String get clearAll => _t('مسح الكل', 'Clear all');
  String get genres => _t('التصنيفات', 'Genres');
  String get genresAll => _t('كلها معاً', 'All together');
  String get genresAny => _t('أي واحد منها', 'Any of them');
  String get typeLabel => _t('النوع', 'Type');
  String get statusLabel => _t('الحالة', 'Status');
  String get seasonLabel => _t('الموسم', 'Season');
  String get years => _t('السنوات', 'Years');
  String get before1980 => _t('قبل 1980', 'Before 1980');
  String get minScore => _t('التقييم الأدنى', 'Minimum score');
  String get episodeLength => _t('عدد الحلقات', 'Episode count');
  String get shortEps => _t('قصير (حتى 13)', 'Short (up to 13)');
  String get mediumEps => _t('متوسط (حتى 26)', 'Medium (up to 26)');
  String get longEps => _t('طويل (أكثر من 26)', 'Long (more than 26)');
  String get sortBy => _t('الترتيب', 'Sort by');
  String get sortScore => _t('الأعلى تقييماً', 'Top rated');
  String get sortNewest => _t('الأحدث', 'Newest');
  String get sortOldest => _t('الأقدم', 'Oldest');
  String get sortName => _t('حسب الاسم', 'By name');
  String get onlyFavorites => _t('المفضلة فقط', 'Favorites only');
  String get hideWatched => _t('إخفاء ما شاهدته', 'Hide watched');
  String get browseAll => _t('تصفح الكل — اختر فلاتر فقط بدون كلمة بحث', 'Browse all — pick filters without a search word');
  String get allTypes => _t('كل الأنواع', 'All types');
  String get allStatuses => _t('كل الحالات', 'All statuses');
  String get allSeasons => _t('كل المواسم', 'All seasons');

  // ---- v2: my library ----
  String get library => _t('مكتبتي', 'My Library');
  String get favorite => _t('مفضلة', 'Favorite');
  String get favorites => _t('المفضلة', 'Favorites');
  String get watching => _t('أشاهده الآن', 'Watching');
  String get planToWatch => _t('سأشاهده', 'Plan to watch');
  String get watched => _t('شاهدته', 'Watched');
  String get addToLibrary => _t('أضف إلى مكتبتي', 'Add to library');
  String get removeFromLibrary => _t('إزالة من مكتبتي', 'Remove from library');
  String get lastEpisode => _t('آخر حلقة', 'Last episode');
  String episodeProgress(int done, int total) => _t('$done / $total حلقة', '$done / $total eps');
  String get emptyLibrary => _t('القائمة فارغة بعد. أضف أنمي من صفحة التفاصيل.', 'This list is empty yet. Add anime from its detail page.');
  String get addedToLibrary => _t('تمت الإضافة إلى مكتبتي', 'Added to library');
  String get removedFromLibrary => _t('تمت الإزالة من مكتبتي', 'Removed from library');

  // ---- v2: themes ----
  String get theme => _t('الثيم', 'Theme');
  String get themes => _t('الثيمات', 'Themes');
  String get customTheme => _t('ثيم مخصص (CSS)', 'Custom theme (CSS)');
  String get customThemeHelp => _t('الصق متغيرات CSS مثل --bg: #0F1015; وسيُطبَّق الثيم فوراً. اتركه فارغاً للعودة للثيم المختار.', 'Paste CSS variables like --bg: #0F1015; and the theme applies instantly. Leave empty to go back to the chosen theme.');
  String get customThemeExample => _t('مثال جاهز', 'Use example');
  String get resetTheme => _t('إعادة تعيين الثيم', 'Reset theme');
  String get themeApplied => _t('تم تطبيق الثيم', 'Theme applied');
  String themeName(String id) {
    switch (id) {
      case 'light': return _t('فاتح', 'Light');
      case 'crimson': return _t('قرمزي', 'Crimson');
      case 'ocean': return _t('محيطي', 'Ocean');
      case 'forest': return _t('غابة', 'Forest');
      case 'dark': default: return _t('داكن', 'Dark');
    }
  }

  // ---- v2: Firebase / Google sign-in ----
  String get googleSignIn => _t('تسجيل الدخول بجوجل', 'Sign in with Google');
  String get googleSignOut => _t('تسجيل الخروج', 'Sign out');
  String get syncNow => _t('مزامنة الآن', 'Sync now');
  String get syncDone => _t('تمت المزامنة', 'Sync done');
  String get syncFailed => _t('تعذّرت المزامنة — ستظل قوائمك محفوظة محلياً', 'Sync failed — your lists stay saved locally');
  String get firebaseNotConfigured => _t('المزامنة غير مفعّلة بعد: أضف ملف google-services.json من Firebase (انظر README) — القوائم تعمل محلياً بدونها.', 'Sync is not set up yet: add google-services.json from Firebase (see README) — lists work locally without it.');
  String get signedInAs => _t('مسجَّل كـ', 'Signed in as');
  String get notSignedIn => _t('غير مسجَّل — القوائم محفوظة على هذا الهاتف فقط', 'Not signed in — lists are saved on this phone only');

  String type(String? t) {
    if (!ar || t == null) return t ?? '';
    const m = {
      'TV': 'مسلسل', 'MOVIE': 'فيلم', 'OVA': 'أوفا', 'ONA': 'أونا',
      'SPECIAL': 'حلقة خاصة', 'MUSIC': 'موسيقي',
    };
    return m[t] ?? t;
  }

  String status(String? s) {
    switch (s) {
      case 'FINISHED':
        return _t('مكتمل', 'Finished');
      case 'ONGOING':
        return _t('يُعرض حالياً', 'Airing');
      case 'UPCOMING':
        return _t('قريباً', 'Upcoming');
      default:
        return _t('غير معروف', 'Unknown');
    }
  }

  String season(String? s) {
    if (!ar || s == null) return s == null ? '' : s[0] + s.substring(1).toLowerCase();
    const m = {'WINTER': 'شتاء', 'SPRING': 'ربيع', 'SUMMER': 'صيف', 'FALL': 'خريف'};
    return m[s.toUpperCase()] ?? s;
  }

  static const _genres = {
    'action': 'أكشن', 'adventure': 'مغامرة', 'comedy': 'كوميديا', 'drama': 'دراما',
    'fantasy': 'فانتازيا', 'horror': 'رعب', 'mystery': 'غموض', 'romance': 'رومانسي',
    'sci-fi': 'خيال علمي', 'sci fi': 'خيال علمي', 'science fiction': 'خيال علمي',
    'slice of life': 'شريحة من الحياة', 'sports': 'رياضة', 'supernatural': 'خوارق',
    'thriller': 'إثارة', 'suspense': 'تشويق', 'psychological': 'نفسي', 'mecha': 'ميكا',
    'music': 'موسيقى', 'school': 'مدرسي', 'historical': 'تاريخي', 'military': 'عسكري',
    'magic': 'سحر', 'martial arts': 'فنون قتالية', 'shounen': 'شونين', 'shoujo': 'شوجو',
    'seinen': 'سينين', 'josei': 'جوسي', 'isekai': 'إيسيكاي', 'ecchi': 'إيتشي',
    'harem': 'حريم', 'game': 'ألعاب', 'super power': 'قوى خارقة', 'vampire': 'مصاصو دماء',
    'demons': 'شياطين', 'space': 'فضاء', 'police': 'شرطة', 'parody': 'محاكاة ساخرة',
    'samurai': 'ساموراي', 'kids': 'أطفال', 'award winning': 'حائز على جوائز',
    'avant garde': 'تجريبي', 'gourmet': 'طعام', 'cars': 'سيارات', 'gore': 'دموي',
    'post-apocalyptic': 'ما بعد نهاية العالم', 'time travel': 'السفر عبر الزمن',
    'reincarnation': 'تناسخ', 'survival': 'بقاء', 'revenge': 'انتقام',
    'friendship': 'صداقة', 'family life': 'حياة عائلية', 'coming of age': 'النضوج',
    'work life': 'حياة العمل', 'idols': 'آيدول', 'cyberpunk': 'سايبربانك',
    'ninja': 'نينجا', 'pirates': 'قراصنة', 'zombies': 'زومبي', 'detective': 'محقق',
    'dark fantasy': 'فانتازيا مظلمة', 'mythology': 'أساطير', 'crime': 'جريمة',
    'war': 'حرب', 'dystopia': 'ديستوبيا', 'virtual world': 'عالم افتراضي',
  };

  String genre(String g) => ar ? (_genres[g.toLowerCase()] ?? g) : g;
}
