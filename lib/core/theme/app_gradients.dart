import 'package:flutter/material.dart';

import 'app_palette.dart';

class AppGradients {
  static const LinearGradient primary = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [AppPalette.primaryA, AppPalette.primaryB],
  );

  static const LinearGradient indigoToCyan = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF4F46E5), AppPalette.primaryB],
  );

  static const LinearGradient deepPurpleToBlue = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF2E1065), Color(0xFF1D4ED8)],
  );
}

