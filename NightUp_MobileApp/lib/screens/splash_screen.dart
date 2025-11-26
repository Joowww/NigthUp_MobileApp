import 'package:flutter/material.dart';
import '../theme/colors.dart';

class SplashScreen extends StatefulWidget {
  final VoidCallback onComplete;
  
  const SplashScreen({super.key, required this.onComplete});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _rotationAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    );
    
    _scaleAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.elasticOut),
    );
    
    _rotationAnimation = Tween<double>(begin: 0.0, end: 2.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
    
    _controller.forward();
    
    Future.delayed(const Duration(seconds: 3), widget.onComplete);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Center(
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            return Transform.scale(
              scale: _scaleAnimation.value,
              child: Transform.rotate(
                angle: _rotationAnimation.value * 3.14,
                child: _buildDiscoBall(),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildDiscoBall() {
    return Container(
      width: 192,
      height: 192,
      decoration: BoxDecoration(
        gradient: const RadialGradient(
          colors: [
            Color(0xFFEC4899),
            Color(0xFFDB2777),
            Color(0xFFC026D3),
          ],
          stops: [0.0, 0.5, 1.0],
        ),
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Colors.pink.withOpacity(0.5),
            blurRadius: 30,
            spreadRadius: 10,
          ),
        ],
      ),
      child: Stack(
        children: [
          // Facetas del disco ball
          ...List.generate(8, (index) => _buildFacet(index)),
          // Rayos de luz
          ...List.generate(12, (index) => _buildLightRay(index)),
        ],
      ),
    );
  }

  Widget _buildFacet(int index) {
    return Positioned(
      top: index * 24.0,
      left: 0,
      right: 0,
      child: Container(
        height: 1,
        color: Colors.white.withOpacity(0.3),
      ),
    );
  }

  Widget _buildLightRay(int index) {
    return Positioned(
      top: 96,
      left: 96,
      child: Transform.rotate(
        angle: index * (3.14 / 6),
        child: AnimatedContainer(
          duration: Duration(milliseconds: 1000 + index * 50),
          width: 1,
          height: 128,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                index % 2 == 0 ? AppColors.primary : AppColors.accent,
                Colors.transparent,
              ],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
        ),
      ),
    );
  }
}