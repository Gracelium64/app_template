# ShadowApp Template

<!--  -->
<!--  -->
<!--  -->

TL;DR - see tool/rename_app.dart at the bottom of the file for instructions

<!--  -->
<!--  -->
<!--  -->

Use this repository as a **GitHub Template Repository** to create new Flutter apps that start from this codebase.

## Create a new app from this template

1. On GitHub, open this repository.
2. Click **Use this template** → **Create a new repository**.
3. Clone the newly created repo locally.

After cloning, you must rename identifiers (package name, bundle IDs, window titles, etc.).

## Naming scheme (standard)

This template uses the following standard identifier scheme:

- **Bundle / application ID (Android, iOS, macOS, Linux):** `shadowapp.<developerName>.<appName>`
  - Example: `shadowapp.grace64.notes`
- **Dart / pub package name:** usually `<appName>` (snake_case)
  - Example: `notes` or `shadow_notes`

Notes:

- `developerName` and `appName` in the bundle/application ID should be **lowercase letters + digits only**.
- The Dart package name must be **lowercase** and can contain **underscores**.

## Rename (recommended): automated script

This repo includes a renaming tool that updates all the important identifiers across Android/iOS/macOS/web/windows/linux + Dart imports.

From the repository root:

1. Dry run first:
   - `dart run tool/rename_app.dart --developer <developerName> --app <appName> --dry-run`

2. Apply changes:
   - `dart run tool/rename_app.dart --developer <developerName> --app <appName>`

Optional arguments:

- `--display-name "My App"` (defaults to a title-cased version of `appName`)
- `--dart-package my_app` (defaults to `appName`)

After renaming:

- Run `flutter clean` (optional but recommended)
- Run `flutter pub get`
- Build/run the app

## Rename (manual): detailed checklist

If you prefer to do it manually (or want to verify what the script changes), here is the checklist.

### Dart / pub package

- Update `name:` in `pubspec.yaml`
- Update all Dart imports that reference the old package name:
  - Search for `package:app_template/` and replace with `package:<your_dart_package>/`

### Android

- Update app id + namespace:
  - `android/app/build.gradle.kts`
    - `namespace = "com.example.app_template"` → `namespace = "shadowapp.<developerName>.<appName>"`
    - `applicationId = "com.example.app_template"` → `applicationId = "shadowapp.<developerName>.<appName>"`
- Update app label:
  - `android/app/src/main/AndroidManifest.xml`
    - `android:label="app_template"` → your display name
- Update Kotlin package + folder:
  - `android/app/src/main/kotlin/com/example/app_template/MainActivity.kt`
    - `package com.example.app_template` → `package shadowapp.<developerName>.<appName>`
  - Move the file to match the package:
    - `android/app/src/main/kotlin/shadowapp/<developerName>/<appName>/MainActivity.kt`

### iOS

- Update display name:
  - `ios/Runner/Info.plist`
    - `CFBundleDisplayName` (what appears under the icon)
    - `CFBundleName` (internal name)
- Update bundle identifier:
  - `ios/Runner.xcodeproj/project.pbxproj`
    - Replace `PRODUCT_BUNDLE_IDENTIFIER = com.example.appTemplate;` with `shadowapp.<developerName>.<appName>`
    - Replace `PRODUCT_BUNDLE_IDENTIFIER = com.example.appTemplate.RunnerTests;` with `shadowapp.<developerName>.<appName>.RunnerTests`

### macOS

- Update bundle identifier + product name:
  - `macos/Runner/Configs/AppInfo.xcconfig`
    - `PRODUCT_NAME = app_template` → (usually your `appName`)
    - `PRODUCT_BUNDLE_IDENTIFIER = com.example.appTemplate` → `shadowapp.<developerName>.<appName>`
- Update Xcode project references (app product name):
  - `macos/Runner.xcodeproj/project.pbxproj` (references to `app_template.app`)
  - `macos/Runner.xcodeproj/xcshareddata/xcschemes/Runner.xcscheme`

### Web

- Update app name + title:
  - `web/index.html`
    - `<title>app_template</title>`
    - `<meta name="apple-mobile-web-app-title" content="app_template">`
  - `web/manifest.json`
    - `name`
    - `short_name`

### Windows

- Update executable / project names:
  - `windows/CMakeLists.txt`
    - `project(app_template LANGUAGES CXX)`
    - `set(BINARY_NAME "app_template")`
- Update window title:
  - `windows/runner/main.cpp` (`window.Create(L"app_template", ...)`)
- Update version info:
  - `windows/runner/Runner.rc` (ProductName, FileDescription, etc.)

### Linux

- Update executable name + application id:
  - `linux/CMakeLists.txt`
    - `set(BINARY_NAME "app_template")`
    - `set(APPLICATION_ID "com.example.app_template")` → `shadowapp.<developerName>.<appName>`
- Update window title:
  - `linux/runner/my_application.cc` (`gtk_window_set_title(..., "app_template")`)
