Flutter port of the FakeStore JS app

Overview

- This folder is a Flutter app (based on Gracelium64/app_template) ported from a small JavaScript/Vite project.
- It includes `Shop` and `Cart` pages, an API client (`ApiService`) targeting https://fakestoreapi.com, and local cart persistence using `shared_preferences` (`CartStorage`).

Quick requirements

- Install Flutter SDK (stable channel) and add to PATH.
- For Android builds: Android SDK + emulator or device.
- For iOS/macOS builds: Xcode installed (macOS host required for iOS/macOS builds).
- For Windows builds: a Windows host with Visual Studio (required to build desktop).

Run locally (web)

```bash
cd flutter_app
flutter pub get
flutter run -d chrome
```

Build (web)

```bash
cd flutter_app
flutter build web
# built files in build/web
```

Run on macOS (developer machine must be macOS)

```bash
cd flutter_app
flutter run -d macos
# or build
flutter build macos
```

Build APK (Android)

```bash
cd flutter_app
flutter build apk
```

Build for iOS (requires Xcode & signing)

```bash
cd flutter_app
flutter build ios
```

Windows build note

- Building a Windows desktop app must be performed on a Windows machine with Visual Studio installed. The repository already contains a `windows/` folder.

Firebase note

- The template includes `firebase_core` in `pubspec.yaml`. The app's `lib/main.dart` wraps `Firebase.initializeApp()` in a try/catch so it will run even without Firebase configured. To enable Firebase features on each platform, initialize using the FlutterFire CLI to generate `firebase_options.dart` and follow platform-specific setup.

Assets

- Empty asset folders were created: `assets/document/`, `assets/img/`, `assets/sound/`, `assets/icons/`. Copy images and other assets into `assets/img/` as needed and update `pubspec.yaml` if adding files.

Notes and next steps

- Desktop/web smoke test: `flutter build web` succeeded in this environment.
- Remaining work: polish UI to precisely match original styles (CSS -> Flutter styling), add images/assets, add onboarding and any missing interactions, configure CI for cross-platform builds.

Contact

- If you want, I can continue by copying assets from the JS `public/` folder into Flutter assets, refine UI to match exact layout, and add automated build scripts.
