import 'package:flutter/material.dart';

class LogHours extends StatelessWidget {
  const LogHours({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          Text('// 19.12.25 - 4 Hours logged //'), // not for billing
        ],
      ),
    );
  }
}
