import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:soundboard_app/config/app_config.dart';
import 'package:soundboard_app/screens/home_screen.dart';

void main() {
  runApp(const ProviderScope(child: SoundboardApp()));
}

class SoundboardApp extends StatelessWidget {
  const SoundboardApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: AppConfig.appName,
      theme: AppConfig.getThemeData(context),
      home: const HomeScreen(),
    );
  }
}
