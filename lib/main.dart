import 'package:flutter/material.dart';

import 'app/app_orientation.dart';
import 'app/skyline.dart';
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

  runApp(const StackoTowerApp());
}

class StackoTowerApp extends StatelessWidget {
  const StackoTowerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Stacko Tower: Balance',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: Sky.bg0,
        colorScheme: ColorScheme.fromSeed(
          seedColor: Sky.cyan,
          brightness: Brightness.dark,
        ),
      ),
      home: const LoadingScreen(),
    );
  }
}
