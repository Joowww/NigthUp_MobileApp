import 'package:flutter/material.dart';
import '../theme/colors.dart'; // Asegúrate de que esta ruta sea correcta

class SplashScreen extends StatefulWidget {
  final VoidCallback onComplete;

  const SplashScreen({super.key, required this.onComplete});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late AnimationController _mainController;
  late AnimationController _colorController;

  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;
  late Animation<Color?> _colorAnimation;

  @override
  void initState() {
    super.initState();

    // 1. Controlador Principal: Maneja la entrada, el pulso y la salida
    _mainController = AnimationController(
      duration: const Duration(seconds: 4),
      vsync: this,
    );

    // Animación de escala con efecto "respira" en el medio
    _scaleAnimation = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween<double>(
          begin: 0.0,
          end: 1.1,
        ).chain(CurveTween(curve: Curves.easeOutBack)),
        weight: 25, // Aparece
      ),
      TweenSequenceItem(
        tween: Tween<double>(
          begin: 1.1,
          end: 1.0,
        ).chain(CurveTween(curve: Curves.easeInOut)),
        weight: 15, // Asienta
      ),
      TweenSequenceItem(
        tween: Tween<double>(
          begin: 1.0,
          end: 1.08,
        ).chain(CurveTween(curve: Curves.easeInOut)),
        weight: 20, // Pulso/Respiro
      ),
      TweenSequenceItem(
        tween: Tween<double>(
          begin: 1.08,
          end: 0.0,
        ).chain(CurveTween(curve: Curves.easeInBack)),
        weight: 25, // Desaparece
      ),
    ]).animate(_mainController);

    // Animación de opacidad (Fade In -> Stay -> Fade Out)
    _fadeAnimation = TweenSequence<double>([
      TweenSequenceItem(tween: Tween<double>(begin: 0.0, end: 1.0), weight: 20),
      TweenSequenceItem(tween: ConstantTween<double>(1.0), weight: 60),
      TweenSequenceItem(tween: Tween<double>(begin: 1.0, end: 0.0), weight: 20),
    ]).animate(_mainController);

    // 2. Controlador de Color: Para que el neón exterior cambie suavemente
    _colorController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );

    // Oscila entre tu rosa neón y tu cian secundario
    _colorAnimation =
        ColorTween(begin: AppColors.neonPink, end: AppColors.secondary).animate(
          CurvedAnimation(parent: _colorController, curve: Curves.easeInOut),
        );

    // Iniciar animaciones
    _mainController.forward();
    _colorController.repeat(reverse: true);

    // Escuchar el final para navegar
    _mainController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        widget.onComplete();
      }
    });
  }

  @override
  void dispose() {
    _mainController.dispose();
    _colorController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background, // Usando tu color de fondo
      body: Center(
        child: AnimatedBuilder(
          animation: _mainController,
          builder: (context, child) {
            return Opacity(
              opacity: _fadeAnimation.value,
              child: Transform.scale(
                scale: _scaleAnimation.value,
                child: _buildLogo(),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildLogo() {
    return AnimatedBuilder(
      animation: _colorController,
      builder: (context, child) {
        return Container(
          width: 280,
          height: 280,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            boxShadow: [
              // Efecto de resplandor neón dinámico
              BoxShadow(
                color: _colorAnimation.value!.withOpacity(0.5),
                blurRadius: 45,
                spreadRadius: 8,
              ),
              // Un segundo brillo más pequeño para dar profundidad
              BoxShadow(
                color: _colorAnimation.value!.withOpacity(0.3),
                blurRadius: 20,
                spreadRadius: 2,
              ),
            ],
          ),
          child: child,
        );
      },
      child: Image.asset(
        'assets/images/default-disco-removebg-preview.png',
        fit: BoxFit.contain,
        errorBuilder: (context, error, stackTrace) {
          return const Icon(Icons.local_bar, size: 100, color: AppColors.white);
        },
      ),
    );
  }
}
