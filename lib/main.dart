import 'package:flutter/material.dart';

import 'app/app_orientation.dart';
import 'app/app_theme.dart';
import 'screens/loading_screen.dart';
import 'services/audio_service.dart';
import 'services/storage_service.dart';
import 'state/game_progress.dart';

late final GameProgress progress;

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await setOrientationsForLoadingScreens();

  final storage = await StorageService.create();
  progress = GameProgress(storage);

  await AudioService.init(progress);

  runApp(const FortressBlitzApp());
}

class FortressBlitzApp extends StatelessWidget {
  const FortressBlitzApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Fortress Blitz',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: AppColors.sky,
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppColors.accent,
          brightness: Brightness.light,
        ),
      ),
      home: const LoadingScreen(),
    );
  }
}
