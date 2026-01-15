import 'dart:math';

import 'package:flutter/material.dart';

abstract class Palette {
  static final Color peasantGrey1 = const Color.fromARGB(255, 65, 63, 63);
  static final Color peasantGrey1Opacity = const Color.fromARGB(
    200,
    65,
    63,
    63,
  );
  static final Color peasantGrey2 = const Color.fromARGB(255, 90, 90, 90);
  static final Color monarchPurple1 = const Color.fromARGB(255, 66, 39, 70);
  static final Color monarchPurple1Opacity = const Color.fromARGB(
    200,
    66,
    39,
    70,
  );
  static final Color monarchPurple2 = const Color.fromARGB(255, 90, 51, 95);
  static final Color fieldBg = const Color.fromARGB(255, 141, 132, 132);
  static final Color basicBitchBlack = const Color.fromARGB(255, 18, 18, 18);
  static final Color basicBitchWhite = const Color.fromARGB(255, 235, 235, 235);
  static final Color neonPurple = const Color.fromARGB(255, 91, 0, 255);
  static final Color darkTeal = const Color.fromARGB(255, 0, 43, 54);
  static final Color lightTeal = const Color.fromARGB(255, 1, 112, 143);
  static final Color fadedGreen = const Color.fromARGB(255, 21, 143, 16);
  static final Color neonGreen = const Color.fromARGB(255, 24, 208, 17);
  static final Color neonPink = const Color.fromARGB(255, 222, 0, 255);
  static final Color mediocreBlue = const Color.fromARGB(255, 0, 25, 255);
  static final Color neonLightBlue = const Color.fromARGB(255, 0, 255, 250);
  static final Color neonRed = const Color.fromARGB(255, 255, 0, 5);
  static final Color highlight = const Color.fromARGB(255, 75, 44, 79);
  static final Color boxShadow1 = const Color.fromARGB(63, 17, 17, 17);
  static final Color boxShadow2 = const Color.fromARGB(51, 238, 238, 238);

  static final Color random = Color(Random().nextInt(0xffffff) | 0xff000000);
}
