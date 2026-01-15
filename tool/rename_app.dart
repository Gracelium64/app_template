import 'dart:convert';
import 'dart:io';

void main(List<String> args) {
  final options = _Options.tryParse(args);
  if (options == null) {
    exitCode = 2;
    return;
  }

  if (options.showHelp) {
    stdout.writeln(_usage);
    return;
  }

  final pubspecFile = File('pubspec.yaml');
  if (!pubspecFile.existsSync()) {
    stderr.writeln(
      'ERROR: Run this from the repository root (pubspec.yaml not found).',
    );
    stderr.writeln(
      'Example: cd <your_repo> && dart run tool/rename_app.dart ...',
    );
    exitCode = 2;
    return;
  }

  final pubspecText = pubspecFile.readAsStringSync();
  final oldDartPackage = _extractPubspecName(pubspecText);
  if (oldDartPackage == null) {
    stderr.writeln(
      'ERROR: Could not find pubspec name (expected: name: something).',
    );
    exitCode = 2;
    return;
  }

  final developer = options.developer;
  final app = options.app;

  final bundleId = 'shadowapp.$developer.$app';
  final dartPackage = options.dartPackage ?? _defaultDartPackage(app);
  final displayName = options.displayName ?? _defaultDisplayName(app);

  final validationError = _validateInputs(
    developer: developer,
    app: app,
    dartPackage: dartPackage,
    displayName: displayName,
  );
  if (validationError != null) {
    stderr.writeln('ERROR: $validationError');
    exitCode = 2;
    return;
  }

  final planned = <_PlannedChange>[];

  void planFileChange(String path, String Function(String text) transform) {
    final file = File(path);
    if (!file.existsSync()) return;
    final before = file.readAsStringSync();
    final after = transform(before);
    if (before != after) {
      planned.add(_PlannedChange(path: path, after: after));
    }
  }

  void planRegexReplace(String path, RegExp pattern, String replacement) {
    planFileChange(path, (text) => text.replaceAll(pattern, replacement));
  }

  // --- pubspec.yaml ---
  planRegexReplace(
    'pubspec.yaml',
    RegExp(r'^name:\s*[^\s]+\s*$', multiLine: true),
    'name: $dartPackage',
  );

  // --- Dart imports ---
  for (final dartFile in _listFiles(Directory('lib'), endsWith: '.dart')) {
    planFileChange(dartFile.path, (text) {
      var updated = text;
      updated = updated.replaceAll(
        'package:localhost/',
        'package:$dartPackage/',
      );
      updated = updated.replaceAll(
        'package:app_template/',
        'package:$dartPackage/',
      );
      updated = updated.replaceAll(
        'package:$oldDartPackage/',
        'package:$dartPackage/',
      );
      return updated;
    });
  }

  // --- Android ---
  planRegexReplace(
    'android/app/build.gradle.kts',
    RegExp(r'\bnamespace\s*=\s*"[^"]+"'),
    'namespace = "$bundleId"',
  );
  planRegexReplace(
    'android/app/build.gradle.kts',
    RegExp(r'\bapplicationId\s*=\s*"[^"]+"'),
    'applicationId = "$bundleId"',
  );
  planRegexReplace(
    'android/app/src/main/AndroidManifest.xml',
    RegExp(r'android:label\s*=\s*"[^"]*"'),
    'android:label="$displayName"',
  );

  final mainActivity = _findFirstFile(
    Directory('android/app/src/main/kotlin'),
    fileName: 'MainActivity.kt',
  );
  if (mainActivity != null) {
    planRegexReplace(
      mainActivity.path,
      RegExp(r'^package\s+[^\s]+\s*$', multiLine: true),
      'package $bundleId',
    );
  }

  // --- Linux ---
  planRegexReplace(
    'linux/CMakeLists.txt',
    RegExp(r'set\(BINARY_NAME\s+"[^"]+"\)'),
    'set(BINARY_NAME "$app")',
  );
  planRegexReplace(
    'linux/CMakeLists.txt',
    RegExp(r'set\(APPLICATION_ID\s+"[^"]+"\)'),
    'set(APPLICATION_ID "$bundleId")',
  );
  planFileChange('linux/runner/my_application.cc', (text) {
    var updated = text;
    updated = updated.replaceAll('"app_template"', jsonEncode(displayName));
    updated = updated.replaceAll('"App Template"', jsonEncode(displayName));
    return updated;
  });

  // --- Windows ---
  planRegexReplace(
    'windows/CMakeLists.txt',
    RegExp(r'^project\([^\s\)]+\s+LANGUAGES\s+CXX\)\s*$', multiLine: true),
    'project($app LANGUAGES CXX)',
  );
  planRegexReplace(
    'windows/CMakeLists.txt',
    RegExp(r'set\(BINARY_NAME\s+"[^"]+"\)'),
    'set(BINARY_NAME "$app")',
  );
  planFileChange('windows/runner/main.cpp', (text) {
    return text.replaceAll(
      RegExp(r'window\.Create\(L"[^"]+"'),
      'window.Create(L"${_escapeForWindowsWideString(displayName)}"',
    );
  });
  planFileChange('windows/runner/Runner.rc', (text) {
    final exe = '$app.exe';
    var updated = text;
    updated = updated.replaceAll('"app_template.exe"', '"$exe"');
    updated = updated.replaceAll('"app_template"', '"$app"');
    return updated;
  });

  // --- Web ---
  planFileChange('web/manifest.json', (text) {
    var updated = text;
    updated = updated.replaceAll(
      RegExp(r'"name"\s*:\s*"[^"]*"'),
      '"name": "${_escapeJsonString(displayName)}"',
    );
    updated = updated.replaceAll(
      RegExp(r'"short_name"\s*:\s*"[^"]*"'),
      '"short_name": "${_escapeJsonString(app)}"',
    );
    return updated;
  });
  planFileChange('web/index.html', (text) {
    var updated = text;
    // Use explicit replacements for the default template content.
    updated = updated.replaceAll(
      RegExp(r'<meta\s+name="apple-mobile-web-app-title"\s+content="[^"]*">'),
      '<meta name="apple-mobile-web-app-title" content="$displayName">',
    );
    updated = updated.replaceAll(
      RegExp(r'<title>[^<]*</title>'),
      '<title>$displayName</title>',
    );
    return updated;
  });

  // --- iOS ---
  planFileChange('ios/Runner/Info.plist', (text) {
    var updated = text;
    updated = _replacePlistStringValue(
      updated,
      'CFBundleDisplayName',
      displayName,
    );
    updated = _replacePlistStringValue(updated, 'CFBundleName', dartPackage);
    return updated;
  });
  planFileChange('ios/Runner.xcodeproj/project.pbxproj', (text) {
    return text.replaceAll('com.example.appTemplate', bundleId);
  });

  // --- macOS ---
  planFileChange('macos/Runner/Configs/AppInfo.xcconfig', (text) {
    final year = DateTime.now().year;
    var updated = text;
    updated = updated.replaceAll(
      RegExp(r'^PRODUCT_NAME\s*=\s*.*$', multiLine: true),
      'PRODUCT_NAME = $app',
    );
    updated = updated.replaceAll(
      RegExp(r'^PRODUCT_BUNDLE_IDENTIFIER\s*=\s*.*$', multiLine: true),
      'PRODUCT_BUNDLE_IDENTIFIER = $bundleId',
    );
    updated = updated.replaceAll(
      RegExp(r'^PRODUCT_COPYRIGHT\s*=\s*.*$', multiLine: true),
      'PRODUCT_COPYRIGHT = Copyright © $year shadowapp.$developer. All rights reserved.',
    );
    return updated;
  });
  planFileChange('macos/Runner.xcodeproj/project.pbxproj', (text) {
    var updated = text;
    updated = updated.replaceAll('com.example.appTemplate', bundleId);
    updated = updated.replaceAll('app_template.app', '$app.app');
    updated = updated.replaceAll('app_template', app);
    return updated;
  });
  planFileChange(
    'macos/Runner.xcodeproj/xcshareddata/xcschemes/Runner.xcscheme',
    (text) {
      var updated = text;
      updated = updated.replaceAll('app_template.app', '$app.app');
      updated = updated.replaceAll('app_template', app);
      return updated;
    },
  );

  // --- Kotlin folder move (MainActivity.kt) ---
  final kotlinMove = _planKotlinMainActivityMove(
    mainActivityPath: mainActivity?.path,
    bundleId: bundleId,
  );

  // --- Summary ---
  if (planned.isEmpty && kotlinMove == null) {
    stdout.writeln('No changes needed.');
    return;
  }

  stdout.writeln('Planned changes (${planned.length} files):');
  for (final change in planned) {
    stdout.writeln('- ${change.path}');
  }
  if (kotlinMove != null) {
    stdout.writeln('- ${kotlinMove.from} -> ${kotlinMove.to}');
  }

  if (options.dryRun) {
    stdout.writeln('\nDry run enabled; no files were modified.');
    return;
  }

  for (final change in planned) {
    File(change.path).writeAsStringSync(change.after);
  }
  if (kotlinMove != null) {
    _applyKotlinMainActivityMove(kotlinMove);
  }

  stdout.writeln('\nDone.');
  stdout.writeln('Bundle/application id: $bundleId');
  stdout.writeln('Dart package name: $dartPackage');
  stdout.writeln('Display name: $displayName');
}

String? _extractPubspecName(String pubspecText) {
  final match = RegExp(
    r'^name:\s*([a-z0-9_]+)\s*$',
    multiLine: true,
  ).firstMatch(pubspecText);
  return match?.group(1);
}

String? _validateInputs({
  required String developer,
  required String app,
  required String dartPackage,
  required String displayName,
}) {
  final segment = RegExp(r'^[a-z][a-z0-9]*$');
  if (!segment.hasMatch(developer)) {
    return '--developer must be lowercase letters+digits and start with a letter (example: grace64).';
  }
  if (!segment.hasMatch(app)) {
    return '--app must be lowercase letters+digits and start with a letter (example: notes).';
  }

  final dartPkg = RegExp(r'^[a-z][a-z0-9_]*$');
  if (!dartPkg.hasMatch(dartPackage)) {
    return '--dart-package must be a valid pub package name (lowercase letters/digits/underscore).';
  }

  if (displayName.trim().isEmpty) {
    return '--display-name cannot be empty.';
  }

  return null;
}

String _defaultDartPackage(String app) => app;

String _defaultDisplayName(String app) {
  final words = app
      .replaceAll('-', ' ')
      .replaceAll('_', ' ')
      .split(RegExp(r'\s+'))
      .where((w) => w.isNotEmpty)
      .toList();
  if (words.isEmpty) return app;
  return words
      .map((w) => w.substring(0, 1).toUpperCase() + w.substring(1))
      .join(' ');
}

Iterable<File> _listFiles(Directory dir, {required String endsWith}) sync* {
  if (!dir.existsSync()) return;
  for (final entity in dir.listSync(recursive: true, followLinks: false)) {
    if (entity is File && entity.path.endsWith(endsWith)) {
      yield entity;
    }
  }
}

File? _findFirstFile(Directory dir, {required String fileName}) {
  if (!dir.existsSync()) return null;
  for (final entity in dir.listSync(recursive: true, followLinks: false)) {
    if (entity is File) {
      final name = entity.uri.pathSegments.isEmpty
          ? ''
          : entity.uri.pathSegments.last;
      if (name == fileName) return entity;
    }
  }
  return null;
}

String _escapeJsonString(String value) {
  final encoded = jsonEncode(value);
  return encoded.substring(1, encoded.length - 1);
}

String _escapeForWindowsWideString(String value) {
  return value.replaceAll('"', r'\"');
}

String _replacePlistStringValue(String plistXml, String key, String newValue) {
  final pattern = RegExp(
    '<key>${RegExp.escape(key)}</key>\s*\n\s*<string>[^<]*</string>',
    multiLine: true,
  );
  if (!pattern.hasMatch(plistXml)) return plistXml;
  return plistXml.replaceFirst(
    pattern,
    '<key>$key</key>\n\t<string>${_escapeXml(newValue)}</string>',
  );
}

String _escapeXml(String value) {
  return value
      .replaceAll('&', '&amp;')
      .replaceAll('<', '&lt;')
      .replaceAll('>', '&gt;')
      .replaceAll('"', '&quot;')
      .replaceAll("'", '&apos;');
}

_KotlinMove? _planKotlinMainActivityMove({
  required String? mainActivityPath,
  required String bundleId,
}) {
  if (mainActivityPath == null) return null;

  final newDir = Directory(
    'android/app/src/main/kotlin/${bundleId.replaceAll('.', '/')}',
  );
  final newPath = '${newDir.path}/MainActivity.kt';
  if (mainActivityPath.replaceAll('\\', '/') == newPath.replaceAll('\\', '/')) {
    return null;
  }
  return _KotlinMove(from: mainActivityPath, to: newPath);
}

void _applyKotlinMainActivityMove(_KotlinMove move) {
  final fromFile = File(move.from);
  if (!fromFile.existsSync()) return;

  final toFile = File(move.to);
  toFile.parent.createSync(recursive: true);
  fromFile.renameSync(move.to);

  final kotlinRoot = Directory('android/app/src/main/kotlin').absolute.path;
  var current = Directory(File(move.from).parent.path).absolute;
  while (current.path.startsWith(kotlinRoot) && current.path != kotlinRoot) {
    final entries = current.listSync(followLinks: false);
    if (entries.isNotEmpty) break;
    final parent = current.parent;
    current.deleteSync();
    current = parent;
  }
}

class _KotlinMove {
  _KotlinMove({required this.from, required this.to});

  final String from;
  final String to;
}

class _PlannedChange {
  _PlannedChange({required this.path, required this.after});

  final String path;
  final String after;
}

class _Options {
  _Options({
    required this.showHelp,
    required this.dryRun,
    required this.developer,
    required this.app,
    required this.dartPackage,
    required this.displayName,
  });

  static _Options? tryParse(List<String> args) {
    String? developer;
    String? app;
    String? dartPackage;
    String? displayName;
    var dryRun = false;
    var showHelp = false;

    try {
      for (var i = 0; i < args.length; i++) {
        final a = args[i];
        switch (a) {
          case '-h':
          case '--help':
            showHelp = true;
            break;
          case '--dry-run':
            dryRun = true;
            break;
          case '--developer':
            developer = _requireValue(args, ++i, a);
            break;
          case '--app':
            app = _requireValue(args, ++i, a);
            break;
          case '--dart-package':
            dartPackage = _requireValue(args, ++i, a);
            break;
          case '--display-name':
            displayName = _requireValue(args, ++i, a);
            break;
          default:
            stderr.writeln('Unknown argument: $a');
            showHelp = true;
            break;
        }
      }
    } on FormatException catch (e) {
      stderr.writeln('ERROR: ${e.message}');
      stderr.writeln(_usage);
      return null;
    }

    if (!showHelp && (developer == null || app == null)) {
      stderr.writeln('ERROR: Missing required arguments.');
      stderr.writeln(_usage);
      return null;
    }

    return _Options(
      showHelp: showHelp,
      dryRun: dryRun,
      developer: developer ?? '',
      app: app ?? '',
      dartPackage: dartPackage,
      displayName: displayName,
    );
  }

  final bool showHelp;
  final bool dryRun;
  final String developer;
  final String app;
  final String? dartPackage;
  final String? displayName;
}

String _requireValue(List<String> args, int index, String flag) {
  if (index >= args.length) {
    throw FormatException('Missing value for $flag');
  }
  return args[index];
}

const String _usage = r'''
ShadowApp renamer

Usage:
	dart run tool/rename_app.dart --developer <developerName> --app <appName> [options]

Standard bundle/application id scheme:
	shadowapp.<developerName>.<appName>

Required:
	--developer   Lowercase letters+digits, starts with a letter (example: grace64)
	--app         Lowercase letters+digits, starts with a letter (example: notes)

Options:
	--dart-package   Pub/Dart package name (default: <appName>)
	--display-name   Human-readable name (default: Title Case of <appName>)
	--dry-run        Print what would change, but don't modify files
	-h, --help       Show help

Examples:
	dart run tool/rename_app.dart --developer grace64 --app notes --dry-run
	dart run tool/rename_app.dart --developer grace64 --app notes --display-name "Shadow Notes"
''';
