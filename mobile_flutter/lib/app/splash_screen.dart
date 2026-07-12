import 'package:flutter/material.dart';

import 'package:mobile_flutter/app/theme/palette.dart';

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(child: CircularProgressIndicator(color: Palette.accent)),
    );
  }
}
