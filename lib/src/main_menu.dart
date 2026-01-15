import 'package:flutter/material.dart';
import 'package:app_template/src/core/extensions/context_mq_extension.dart';

class MainMenu extends StatelessWidget {
  const MainMenu({super.key});

  @override
  Widget build(BuildContext context) {
    final screenHeight = context.scrnHeight;
    final screenWidth = context.scrnWidth;

    return Scaffold(body: Center(child: Text('Hello World!')));
  }
}
