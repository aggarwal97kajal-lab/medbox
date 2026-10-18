import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'core/strings.dart';
import 'core/theme.dart';
import 'data/medicine.dart';
import 'data/prices.dart';
import 'data/storage.dart';
import 'screens/splash_screen.dart';

/// Last error seen anywhere in the app; shown in a red strip so problems are
/// visible on the phone instead of the app silently hanging.
final lastError = ValueNotifier<String?>(null);

void _report(Object error, StackTrace? stack) {
  debugPrint('MEDBOX ERROR: $error\n$stack');
  lastError.value = '$error';
}

Future<void> _loadSavedData() async {
  try {
    await Storage.init().timeout(const Duration(seconds: 4));
  } catch (e, s) {
    _report('Storage: $e', s);
  }
  try {
    final lang = Storage.getString('lang');
    if (lang == 'hi' || lang == 'en') appLocale.value = Locale(lang!);
    appLocale.addListener(() => Storage.setString('lang', appLocale.value.languageCode));
    store.load();
    priceBook.load();
  } catch (e, s) {
    _report('Saved data: $e', s);
  }
}

void main() {
  runZonedGuarded(() async {
    WidgetsFlutterBinding.ensureInitialized();
    FlutterError.onError = (details) {
      FlutterError.presentError(details);
      _report(details.exceptionAsString(), details.stack);
    };
    ErrorWidget.builder = (details) => Material(
          color: const Color(0xFF2A0F14),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Text(
              details.exceptionAsString(),
              style: const TextStyle(color: Colors.white, fontSize: 12),
            ),
          ),
        );
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: AppColors.bg,
      systemNavigationBarIconBrightness: Brightness.light,
    ));
    await _loadSavedData();
    runApp(const MedBoxApp());
  }, _report);
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
        builder: (context, child) => Stack(children: [
          if (child != null) child,
          ValueListenableBuilder<String?>(
            valueListenable: lastError,
            builder: (context, err, _) => err == null
                ? const SizedBox.shrink()
                : Positioned(
                    left: 12,
                    right: 12,
                    bottom: 24,
                    child: Material(
                      color: const Color(0xFFB42335),
                      borderRadius: BorderRadius.circular(12),
                      child: InkWell(
                        onTap: () => lastError.value = null,
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Text(
                            'Error: $err',
                            maxLines: 6,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(color: Colors.white, fontSize: 12),
                          ),
                        ),
                      ),
                    ),
                  ),
          ),
        ]),
        home: const SplashScreen(),
      ),
    );
  }
}
