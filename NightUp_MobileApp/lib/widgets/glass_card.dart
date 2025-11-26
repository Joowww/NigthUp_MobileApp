import 'package:flutter/material.dart';
import 'dart:ui';
import '../theme/colors.dart';

class GlassCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final BorderRadiusGeometry borderRadius;
  final double blurRadius;
  
  const GlassCard({
    super.key,
    required this.child,
    this.padding = EdgeInsets.zero,
    this.borderRadius = const BorderRadius.all(Radius.circular(16)),
    this.blurRadius = 10.0,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: borderRadius,
        border: Border.all(color: AppColors.glassBorder),
        color: AppColors.glassWhite,
      ),
      child: ClipRRect(
        borderRadius: borderRadius,
        child: BackdropFilter(
          filter: ImageFilter.blur(
            sigmaX: blurRadius,
            sigmaY: blurRadius,
          ),
          child: Padding(
            padding: padding,
            child: child,
          ),
        ),
      ),
    );
  }
}