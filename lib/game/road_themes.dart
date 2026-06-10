import 'package:flutter/material.dart';

/// Cosmetic colour palettes for the tower. The [id] maps directly to
/// TowerSkin.byIndex so the shop preview matches the in-game skin.
class RoadTheme {
  const RoadTheme({
    required this.id,
    required this.name,
    required this.price,
    required this.color,
    required this.glow,
  });

  final int id;
  final String name;
  final int price; // 0 = owned by default
  final Color color;
  final Color glow;
}

const List<RoadTheme> roadThemes = [
  RoadTheme(id: 0, name: 'Neon', price: 0, color: Color(0xFF27E5F2), glow: Color(0xFF1899B3)),
  RoadTheme(id: 1, name: 'Sunset', price: 250, color: Color(0xFFFF8A5C), glow: Color(0xFFD84315)),
  RoadTheme(id: 2, name: 'Aurora', price: 450, color: Color(0xFF5CFFD0), glow: Color(0xFF1DE9B6)),
  RoadTheme(id: 3, name: 'Mono', price: 700, color: Color(0xFFCBD5FF), glow: Color(0xFF8FA0E0)),
  RoadTheme(id: 4, name: 'Magma', price: 1000, color: Color(0xFFFF5C3C), glow: Color(0xFFD84315)),
  RoadTheme(id: 5, name: 'Toxic', price: 1500, color: Color(0xFF8CFF3C), glow: Color(0xFF5BA814)),
];

RoadTheme roadThemeById(int id) => roadThemes.firstWhere(
      (t) => t.id == id,
      orElse: () => roadThemes.first,
    );
