import 'package:flutter/material.dart';

class AppColors {
  static const Color background = Color(0xFF121212);
  static const Color surface = Color(0xFF1E1E1E);
  static const Color primary = Color(0xFF8A2BE2);
  static const Color secondary = Color(0xFF00BCD4);
  static const Color accent = Color(0xFF00FFFF);
  static const Color error = Color(0xFFCF6679);
  static const Color success = Color(0xFF4CAF50);
  
  static const Color glassWhite = Color(0x15FFFFFF);
  static const Color glassBorder = Color(0x20FFFFFF);
  
  static const Gradient primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF8A2BE2), Color(0xFFBA68C8)],
  );
  
  static const Gradient secondaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF00BCD4), Color(0xFF00FFFF)],
  );

  // NUEVOS COLORES NEÓN ROSA (añadidos sin modificar los existentes)
  static const Color neonPink = Color(0xFFFF00FF);
  static const Color neonMagenta = Color(0xFFFF1493);
  static const Color neonPurple = Color(0xFF9D00FF);
  static const Color softPink = Color(0xFFFF69B4);
  static const Color neonBlue = Color(0xFF00BFFF);  
  static const Color neonGreen = Color(0xFF39FF14);  

  // Nuevos gradientes neón
  static const Gradient neonGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [neonPink, neonPurple],
  );
  
  static const Gradient neonMagentaGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [neonMagenta, neonPink],
  );
  
  static const Gradient neonButtonGradient = LinearGradient(
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
    colors: [neonPink, neonMagenta],
  );

  // Gradiente que combina los colores existentes con los nuevos neón
  static const Gradient mixedGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF8A2BE2), neonPink, Color(0xFF00FFFF)],
  );
}