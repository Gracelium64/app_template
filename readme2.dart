/*

What you need installed (macOS + VS Code)
Required
* Flutter SDK (includes Dart)
* VS Code + extensions:
  * Flutter (installs Dart extension as dependency)
* Git (for Flutter + packages)
* Google Chrome (for web debugging)

iOS Simulator (iPhone)
* Xcode (from Mac App Store)
* Xcode Command Line Tools
* CocoaPods (for iOS plugin builds)

Android Emulator (Android “simulator”)
* Android Studio (for SDK + Emulator/AVD Manager)
* Android SDK components (installed via Android Studio):
  * Android SDK Platform (e.g., API 34+)
  * Android SDK Platform-Tools (adb)
  * Android Emulator
  * Command-line Tools

Project entrypoint is main() in main.dart. Dependencies are in pubspec.yaml.


Install + configure Flutter (recommended path)
1. Install Flutter SDK
* Download Flutter SDK (stable) and unzip somewhere like ~/development/flutter
* Add Flutter to your PATH (zsh default on macOS)

* ** # add to ~/.zshrc (example) 
* ** export PATH="$HOME/development/flutter/bin:$PATH"


2. Verify Flutter
* ** flutter --version
* ** flutter doctor



Configure iOS (iPhone Simulator)
1. Install Xcode
* Install from App Store
* Open Xcode once (it finishes setup)

2. Accept licenses / select Xcode
* ** sudo xcodebuild -license accept
* ** sudo xcode-select --switch /Applications/Xcode.app/Contents/Developer

3. Install CocoaPods
* ** sudo gem install cocoapods
* ** pod --version

4. Re-check
* ** flutter doctor

Configure Android (Emulator)
1. Install Android Studio
* Install Android Studio
* Open it → install suggested components

2. Install SDK pieces
In Android Studio:
* Settings/Preferences → Appearance & Behavior → System Settings → Android SDK
  * Install an SDK Platform (e.g., API 34)
  * Install Platform-Tools, Build-Tools, Command-line Tools, Emulator
3. Accept Android licenses
* ** flutter doctor --android-licenses
* ** flutter doctor

4. Create an emulator
Android Studio → Device Manager → create an AVD (Pixel + Google APIs image)

Configure Web (Chrome)
1. Enable web support
* ** flutter config --enable-web
* ** flutter doctor

2. Ensure Chrome is detected
* ** flutter devices


Prepare the project (once)
From repo root (where pubspec.yaml exists):
* ** flutter clean
* ** flutter pub get


Run debug from VS Code (Mac)
Common VS Code setup
* Open the repository folder in VS Code
* Install Flutter extension
* Cmd+Shift+P → Flutter: Select Device

Android Emulator debug
1. Start an emulator:
* Android Studio → Device Manager → “Play”
  * or:
* ** flutter emulators
* ** flutter emulators --launch <emulator_id>

2. In VS Code:
* Select the Android device
* Press F5 (Run → Start Debugging)

Terminal equivalent:
* ** flutter run -d <android_device_id>

iPhone Simulator debug
1. Start Simulator:
* ** open -a Simulator

2. In VS Code:
* Select an iOS Simulator device
  * Press F5

Terminal equivalent:
* ** flutter run -d "iPhone 15"   # example name; use flutter devices to see yours


Web (Chrome) debug
1. In VS Code:
* Select Chrome
  * Press F5

Terminal equivalent:
* ** flutter run -d chrome


Settings that may need to be set in VS Code
If Flutter isn’t auto-detected:

VS Code Settings → search Flutter SDK Path
set dart.flutterSdkPath to your Flutter folder (e.g. ~/development/flutter)

*/


/*

“Copilot agent” prompt to initiate required installs
If anything fails at flutter doctor, the agent should propose the minimal fix and re-run flutter doctor.
Paste this into your GitHub Copilot agent:

You are setting up a Flutter dev environment on a macOS MacBook for this workspace (Flutter app with entrypoint main.dart).
Goal: run debug in VS Code on Android Emulator, iPhone Simulator, and Web (Chrome).
Use Homebrew where appropriate.
Do the following:

Check/install prerequisites: xcode-select, Xcode CLI tools, Git, Homebrew.
Install: Flutter SDK (stable), VS Code extensions (Flutter/Dart), Google Chrome, CocoaPods, Android Studio.
Configure: add Flutter to PATH (zsh), run flutter doctor, fix all doctor issues; run flutter doctor --android-licenses; enable web via flutter config --enable-web.
Android: ensure Android SDK + platform-tools + emulator + an AVD exist; show commands to list/launch emulators.
iOS: ensure Xcode license accepted, Simulator runs, CocoaPods installed; verify flutter doctor iOS section is green.
Project: run flutter clean and flutter pub get in repo root.
Provide final “how to debug” commands and VS Code steps for: Android (flutter run -d ...), iOS simulator (flutter run -d "iPhone ...") and web (flutter run -d chrome).
Output a concise checklist + exact terminal commands.

*/