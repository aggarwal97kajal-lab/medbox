import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'core/strings.dart';
import 'core/theme.dart';
import 'data/medicine.dart';
import 'data/prices.dart';
import 'data/storage.dart';
import 'screens/splash_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Storage.init();
  final lang = Storage.getString('lang');
  if (lang == 'hi' || lang == 'en') appLocale.value = Locale(lang!);
  appLocale.addListener(() => Storage.setString('lang', appLocale.value.languageCode));
  store.load();
  priceBook.load();
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
    systemNavigationBarColor: AppColors.bg,
    systemNavigationBarIconBrightness: Brightness.light,
  ));
  runApp(const MedBoxApp());
}

class MedBoxApp extends StatelessWidget {
  const MedBoxApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Changing appLocale rebuilds MaterialApp with a new locale; every widget
    // that calls context.tr(...) depends on Localizations, so it re-renders
    // in the new language without losing navigation state.
    return ValueListenableBuilder<Locale>(
      valueListenable: appLocale,
      builder: (context, locale, _) => MaterialApp(
        title: 'MedBox',
        debugShowCheckedModeBanner: false,
        theme: buildTheme(),
        locale: locale,
        supportedLocales: const [Locale('en'), Locale('hi')],
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        home: const SplashScreen(),
      ),
    );
  }
}
