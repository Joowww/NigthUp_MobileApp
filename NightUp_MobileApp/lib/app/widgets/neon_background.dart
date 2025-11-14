import 'package:flutter/material.dart';
import '../themes/app_colors.dart';

class NeonBackground extends StatelessWidget {
  final Widget child;

  const NeonBackground({
    Key? key,
    required this.child,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Fondo base
        Container(
          decoration: const BoxDecoration(
            gradient: AppColors.backgroundGradient,
          ),
        ),
        
        // Círculos de neón animados
        Positioned(
          top: -100,
          right: -100,
          child: Container(
            width: 300,
            height: 300,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  AppColors.neonPink.withOpacity(0.2),
                  Colors.transparent,
                ],
              ),
            ),
          ),
        ),
        
        Positioned(
          bottom: -150,
          left: -100,
          child: Container(
            width: 400,
            height: 400,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  AppColors.neonBlue.withOpacity(0.15),
                  Colors.transparent,
                ],
              ),
            ),
          ),
        ),
        
        Positioned(
          top: 200,
          left: 50,
          child: Container(
            width: 200,
            height: 200,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  AppColors.neonPurple.withOpacity(0.1),
                  Colors.transparent,
                ],
              ),
            ),
          ),
        ),
        
        // Contenido
        child,
      ],
    );
  }
}