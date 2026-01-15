import 'package:flutter/material.dart';
import 'package:app_template/src/core/extensions/context_mq_extension.dart';

class MainMenu extends StatelessWidget {
  const MainMenu({super.key});

  @override
  Widget build(BuildContext context) {
    final bool isLandscape = context.scrnIsLandscape;

    return Scaffold(
      floatingActionButton: FloatingActionButton(
        backgroundColor: isLandscape
            ? Colors.green
            : Color.fromARGB(156, 80, 99, 255),
        child: context.scrnIsLandscape
            ? Text('LANDSCAPE', style: TextStyle(fontSize: 9))
            : Text('PORTRAIT', style: TextStyle(fontSize: 9)),
        onPressed: () {},
      ),
      body: Center(child: Text('Hello World.')),
    );
  }
}
