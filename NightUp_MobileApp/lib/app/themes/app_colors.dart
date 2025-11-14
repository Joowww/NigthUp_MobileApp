import 'package:flutter/material.dart';

class AppColors {
  // Colores principales de neón
  static const Color neonPink = Color(0xFFFF006E);
  static const Color neonBlue = Color(0xFF00F5FF);
  static const Color neonPurple = Color(0xFFB967FF);
  static const Color neonGreen = Color(0xFF05FFA1);
  static const Color neonOrange = Color(0xFFFF9E00);
  
  // Colores de fondo oscuros
  static const Color darkBackground = Color(0xFF0A0A0F);
  static const Color darkCard = Color(0xFF1A1A2E);
  static const Color darkInput = Color(0xFF16162A);
  
  // Gradientes
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [neonPink, neonPurple],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  
  static const LinearGradient secondaryGradient = LinearGradient(
    colors: [neonBlue, neonPurple],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  
  static const LinearGradient backgroundGradient = LinearGradient(
    colors: [darkBackground, Color(0xFF1A0E2E)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );
  
  // Colores de texto
  static const Color textPrimary = Colors.white;
  static const Color textSecondary = Color(0xFFB0B0B0);
  static const Color textHint = Color(0xFF666666);
  
  // Colores de estado
  static const Color success = Color(0xFF05FFA1);
  static const Color error = Color(0xFFFF006E);
  static const Color warning = Color(0xFFFF9E00);
  static const Color info = Color(0xFF00F5FF);
}