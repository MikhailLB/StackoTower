import 'package:flutter/material.dart';

/// Cosmetic colour themes for the paved road line.
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
  RoadTheme(
    id: 0,
    name: 'Classic Gold',
    price: 0,
    color: Color(0xFFFFC233),
    glow: Color(0xFFFF8800),
  ),
  RoadTheme(
    id: 1,
    name: 'Cyan Pulse',
    price: 250,
    color: Color(0xFF35E0E0),
    glow: Color(0xFF1899B3),
  ),
  RoadTheme(
    id: 2,
    name: 'Magenta Flux',
    price: 450,
    color: Color(0xFFE356C8),
    glow: Color(0xFF9C27B0),
  ),
  RoadTheme(
    id: 3,
    name: 'Lime Circuit',
    price: 700,
    color: Color(0xFFA8E05A),
    glow: Color(0xFF5BA814),
  ),
  RoadTheme(
    id: 4,
    name: 'Sunset Drive',
    price: 1000,
    color: Color(0xFFFF7E5F),
    glow: Color(0xFFD84315),
  ),
  RoadTheme(
    id: 5,
    name: 'Arctic Line',
    price: 1500,
    color: Color(0xFFB3E5FC),
    glow: Color(0xFF4FC3F7),
  ),
];

RoadTheme roadThemeById(int id) => roadThemes.firstWhere(
      (t) => t.id == id,
      orElse: () => roadThemes.first,
    );
