import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'core/theme.dart';
import 'data/local/database_helper.dart';
import 'data/remote/anilist_client.dart';
import 'data/remote/firebase_sync.dart';
import 'data/remote/jikan_client.dart';
import 'data/remote/tmdb_client.dart';
import 'data/repositories/anime_repository_impl.dart';
import 'domain/repositories/anime_repository.dart';
import 'presentation/providers/filter_provider.dart';
import 'presentation/providers/home_provider.dart';
import 'presentation/providers/library_provider.dart';
import 'presentation/providers/search_provider.dart';
import 'presentation/providers/settings_provider.dart';
import 'presentation/screens/root_shell.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final prefs = await SharedPreferences.getInstance();
  // Firebase is optional: init() never throws — without google-services.json
  // the app simply runs without sync (see firebase_sync.dart).
  final firebaseSync = FirebaseSync(DatabaseHelper.instance);
  await firebaseSync.init();
  runApp(SadekApp(prefs: prefs, firebaseSync: firebaseSync));
}

class SadekApp extends StatelessWidget {
  const SadekApp({super.key, required this.prefs, required this.firebaseSync});
  final SharedPreferences prefs;
  final FirebaseSync firebaseSync;

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<SettingsProvider>(
            create: (_) => SettingsProvider(prefs)),
        ChangeNotifierProvider<FirebaseSync>.value(value: firebaseSync),
        Provider<AnimeRepository>(
          create: (c) => AnimeRepositoryImpl(
            DatabaseHelper.instance,
            JikanClient(),
            AniListClient(),
            TmdbClient(() => c.read<SettingsProvider>().tmdbKey),
          ),
        ),
        ChangeNotifierProvider<HomeProvider>(
            create: (c) => HomeProvider(c.read<AnimeRepository>())),
        ChangeNotifierProvider<SearchProvider>(
            create: (c) => SearchProvider(c.read<AnimeRepository>())),
        ChangeNotifierProvider<FilterProvider>(
            create: (c) => FilterProvider(c.read<AnimeRepository>())),
        ChangeNotifierProvider<LibraryProvider>(
            create: (c) => LibraryProvider(
                  c.read<AnimeRepository>(),
                  firebaseSync,
                )..load()),
      ],
      child: Consumer<SettingsProvider>(
        builder: (context, settings, _) => MaterialApp(
          title: 'sadek-anime-offline',
          debugShowCheckedModeBanner: false,
          theme: buildTheme(settings.palette, settings.isDark),
          locale: settings.locale,
          supportedLocales: const [Locale('ar'), Locale('en')],
          localizationsDelegates: const [
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          home: const RootShell(),
        ),
      ),
    );
  }
}
