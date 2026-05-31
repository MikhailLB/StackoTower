import 'package:flutter/material.dart';
import '../screens/main_menu_screen.dart';

/// Entry point into the StackoTower game from the gray gate.
/// SplashGate navigates here when the backend decides the user is organic.
/// Do NOT add any gate/ imports in this file or in the game code.
class WhitePartEntry extends StatelessWidget {
  const WhitePartEntry({super.key});

  @override
  Widget build(BuildContext context) {
    // Navigate directly to MainMenuScreen — SplashGate already served as
    // the loading experience. Returning LoadingScreen would cause a double
    // loading animation.
    return const MainMenuScreen();
  }
}
