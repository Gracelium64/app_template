import 'package:test_app/src/data/databaserepository.dart';
import 'package:test_app/src/theme/app_theme.dart';
import 'package:device_preview/device_preview.dart';
import 'package:flutter/material.dart';
import 'package:test_app/src/main_menu.dart';

class App extends StatelessWidget {
  final DataBaseRepository db;

  const App(this.db, {super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: "Test App",
      locale: DevicePreview.locale(context),
      builder: DevicePreview.appBuilder,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.dark,

      home: MainMenu(db),
    );
  }
}
