import 'package:flutter/material.dart';

import 'package:flutter_application_1/core/theme/pawstay_theme.dart';
import 'package:flutter_application_1/screens/auth/splash_screen.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'PawStay',
      theme: PawStayTheme.lightTheme,
      home: const SplashScreen(),
    );
  }
}
