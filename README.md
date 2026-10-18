# MedBox · दवा बॉक्स

Medicine expiry tracker for Indian homes. Flutter, dark glass UI, lots of animation, English + Hindi.

## APK without a laptop

Push this folder to a GitHub repository. The workflow in `.github/workflows/build-apk.yml` builds the APK in the cloud on every push (about 8–10 minutes) and publishes it under **Releases** as `MedBox.apk`. Open the repository's Releases page on your phone, download `MedBox.apk` and install it (Android will ask you to allow installs from your browser once).

The workflow also adds the Android project files, the internet permission and the app icon, then runs the analyzer and tests, so a code error shows up in the **Actions** tab.

## Running on a computer (optional)

With Flutter 3.27 or newer:

```bash
flutter create . --project-name medbox --platforms android
flutter pub get
dart run flutter_launcher_icons
flutter run
```

## Screens

| File | Screen |
|---|---|
| `screens/splash_screen.dart` | Animated logo intro |
| `screens/home_screen.dart` | Box health ring, "use first" alert, expiring list |
| `screens/scan_screen.dart` | Scanner with laser line, detection pop, result sheet |
| `screens/box_screen.dart` | All medicines, search, animated filter chips |
| `screens/detail_screen.dart` | Countdown ring, info grid, duplicate-pack tip |
| `screens/alerts_screen.dart` | Expired card, upcoming timeline, safe disposal steps |
| `screens/settings_screen.dart` | Language cards, reminder window, notifications |
| `screens/compare_screen.dart` | Quick compare: pharmacies list, cheapest you found, savings |
| `screens/browser_screen.dart` | In-app pharmacy pages with tabs and a price bar |

## Language

All text lives in `lib/core/strings.dart` (`en` and `hi`). Tap **EN | हिं** on any screen or pick a card in Settings; the whole app switches instantly.

## What is demo-only right now

- **Scanner**: the camera view is a styled placeholder and detection is simulated after 2.6 s. To make it real, add the `camera` and `google_mlkit_text_recognition` packages, show `CameraPreview` in place of `_CameraMock`, and parse the `EXP MM/YYYY` text (see the comment at the top of `scan_screen.dart`).
- **Data**: medicines, settings, language and saved prices are stored on the phone (`lib/data/storage.dart`). First launch shows sample medicines.
- **Notifications** switch is UI only. Use `flutter_local_notifications` to schedule the daily reminder.
- **Price compare (Quick compare)** needs no server. Each pharmacy's real search page opens inside the app (`webview_flutter`); the user reads the price and saves it, and the app ranks what they found. Saved prices are stored on the phone. Check the search URLs in `pharmacies` on each live site before release.
