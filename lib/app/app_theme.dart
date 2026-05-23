import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppColors {
  // Sky / environment
  static const sky = Color(0xFF87CEEB);
  static const skyDark = Color(0xFF4DA8C7);

  // Accent gold
  static const accent = Color(0xFFFFC233);
  static const accentDeep = Color(0xFFE07B00);

  // UI
  static const danger = Color(0xFFFF4757);
  static const panel = Color(0xCC1A1A2E);
  static const panelSolid = Color(0xFF1A1A2E);
  static const panelLight = Color(0xFFFFF5DA);
  static const card = Color(0xFF16213E);
  static const cardBorder = Color(0xFF0F3460);

  // Text
  static const text = Color(0xFFF0E6FF);
  static const textMuted = Color(0xFF9090B0);
  static const textDark = Color(0xFF1A1A2E);

  // Gradients
  static const menuBgTop = Color(0xFF0D0D1F);
  static const menuBgBottom = Color(0xFF1A1035);

  // Button secondary
  static const btnSecTop = Color(0xFF533483);
  static const btnSecBottom = Color(0xFF2D1B5E);
  static const btnSecBorder = Color(0xFF7B4FD4);
}

class AppTextStyles {
  // Big display title — Nunito ExtraBold
  static TextStyle title({double size = 38, Color color = AppColors.text}) =>
      GoogleFonts.nunito(
        fontSize: size,
        color: color,
        fontWeight: FontWeight.w900,
        letterSpacing: -0.5,
        shadows: const [
          Shadow(blurRadius: 12, color: Color(0x88000000), offset: Offset(0, 4)),
        ],
      );

  // Buttons & section labels — Nunito Black
  static TextStyle button({double size = 22, Color color = AppColors.text}) =>
      GoogleFonts.nunito(
        fontSize: size,
        color: color,
        fontWeight: FontWeight.w800,
        letterSpacing: 0.3,
      );

  // Body / subtitles — Nunito SemiBold
  static TextStyle body({double size = 16, Color color = AppColors.text}) =>
      GoogleFonts.nunito(
        fontSize: size,
        color: color,
        fontWeight: FontWeight.w600,
      );

  // Score — Bangers (kept for HUD impact)
  static TextStyle score({double size = 28, Color color = AppColors.text}) =>
      GoogleFonts.bangers(
        fontSize: size,
        color: color,
        letterSpacing: 1.5,
        shadows: const [
          Shadow(blurRadius: 8, color: Color(0xCC000000), offset: Offset(2, 2)),
        ],
      );

  // Headline accent (used in level complete, big numbers)
  static TextStyle headline({double size = 48, Color color = AppColors.accent}) =>
      GoogleFonts.bangers(
        fontSize: size,
        color: color,
        letterSpacing: 2.0,
        shadows: const [
          Shadow(blurRadius: 16, color: Color(0xAAFF8800), offset: Offset(0, 2)),
        ],
      );
}
