import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_translate/flutter_translate.dart';
// import 'package:flutter/foundation.dart' show kIsWeb;
// import 'dart:js' as js;
import '../app.dart';
import '../controllers/auth_controller.dart';
import '../theme/colors.dart';
import '../widgets/glass_card.dart';
import '../widgets/gradient_button.dart';
import '../services/storage_service.dart';

class LoginScreen extends StatefulWidget {
  final VoidCallback onLogin;
  final VoidCallback onRegister;
  final VoidCallback onForgotPassword;

  const LoginScreen({
    super.key,
    required this.onLogin,
    required this.onRegister,
    required this.onForgotPassword,
  });

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final AuthController _authController = Get.find<AuthController>();

  bool _rememberMe = false;
  bool _obscurePassword = true;
  // bool _isGoogleInitialized = false;

  @override
  void initState() {
    super.initState();
    _loadSavedCredentials();
    // Removed legacy manual web initialization
  }

  void _loadSavedCredentials() {
    final storage = Get.find<StorageService>();
    final savedUsername = storage.read('remembered_username');
    final rememberMe = storage.read('remember_me') ?? false;

    if (rememberMe && savedUsername != null) {
      setState(() {
        _emailController.text = savedUsername;
        _rememberMe = true;
      });
    }
  }

  // Removed _registerGlobalHandler as it used dart:js

  void _login() async {
    if (_emailController.text.isEmpty || _passwordController.text.isEmpty) {
      _showErrorDialog(translate('login.validation_error'));
      return;
    }

    print('🔐 Attempting normal login with: ${_emailController.text}');

    final success = await _authController.login(
      _emailController.text.trim(),
      _passwordController.text,
    );

    if (success) {
      // Save or clear credentials
      final storage = Get.find<StorageService>();
      if (_rememberMe) {
        await storage.write(
          'remembered_username',
          _emailController.text.trim(),
        );
        await storage.write('remember_me', true);
      } else {
        await storage.remove('remembered_username');
        await storage.write('remember_me', false);
      }

      // Siempre ir al home, intereses deshabilitados
      Get.offAll(() => const App());
    } else {
      _showErrorDialog(_authController.error);
    }
  }

  // Removed _handleGISCredential
  // Removed _initializeGoogleGIS
  // Removed _loadAndInitializeGIS
  // Removed _initializeGIS

  void _showErrorDialog(String error) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.black87,
        title: Text(
          translate('error.title'),
          style: const TextStyle(color: Colors.white),
        ),
        content: Text(error, style: const TextStyle(color: Colors.white70)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              translate('common.ok'),
              style: const TextStyle(color: AppColors.neonPink),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          _buildBackgroundGradients(),

          // 🔥 CAMBIO 1: Usamos Positioned.fill para el contenido principal
          Positioned.fill(
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24.0,
                  vertical: 60,
                ),
                child: Column(
                  children: [
                    _buildLogo(),
                    const SizedBox(height: 40),
                    _buildLoginForm(),

                    // 🔥 CAMBIO 2: Espacio extra al final para que los botones
                    // fijos de abajo no tapen el formulario si la pantalla es pequeña
                    const SizedBox(height: 150),
                  ],
                ),
              ),
            ),
          ),

          // 🔥 CAMBIO 3: Botones "flotantes" pegados abajo con SafeArea
          // Esto soluciona el problema de clics en Samsung/Android
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              // Opcional: un degradado negro suave para que se lean mejor
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                  colors: [Colors.black, Colors.transparent],
                  stops: [0.2, 1.0],
                ),
              ),
              child: SafeArea(
                top: false,
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 20.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Botón Olvidé Contraseña (Movido aquí)
                      TextButton(
                        onPressed: widget.onForgotPassword,
                        child: Text(
                          translate('login.forgot_password'),
                          style: const TextStyle(
                            color: AppColors.neonPink,
                            fontWeight: FontWeight.w600,
                            shadows: [
                              Shadow(blurRadius: 5, color: Color(0x80FF00FF)),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 10),

                      // Botón Registrarme (Movido aquí)
                      _buildRegisterPrompt(),
                    ],
                  ),
                ),
              ),
            ),
          ),

          if (_authController.isLoading) _buildLoadingOverlay(),
        ],
      ),
    );
  }

  Widget _buildLoadingOverlay() {
    return Container(
      color: Colors.black54,
      child: const Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(AppColors.neonPink),
        ),
      ),
    );
  }

  Widget _buildBackgroundGradients() {
    return Stack(
      children: [
        Positioned(
          top: -100,
          right: -100,
          child: Container(
            width: 250,
            height: 250,
            decoration: const BoxDecoration(
              gradient: RadialGradient(
                colors: [AppColors.neonPink, AppColors.neonPurple],
                radius: 1.0,
              ),
              shape: BoxShape.circle,
            ),
          ),
        ),
        Positioned(
          bottom: -100,
          left: -100,
          child: Container(
            width: 250,
            height: 250,
            decoration: const BoxDecoration(
              gradient: RadialGradient(
                colors: [AppColors.neonMagenta, AppColors.primary],
                radius: 1.0,
              ),
              shape: BoxShape.circle,
            ),
          ),
        ),
        _buildNeonParticles(),
      ],
    );
  }

  Widget _buildNeonParticles() {
    final particles = [
      [const Color(0x66FF00FF), 50.0, 100.0],
      [const Color(0x99FF00FF), 150.0, 200.0],
      [const Color(0x4DFF00FF), 300.0, 80.0],
      [const Color(0x80FF00FF), 80.0, 400.0],
      [const Color(0x66FF00FF), 250.0, 350.0],
      [const Color(0x99FF00FF), 320.0, 150.0],
    ];

    return Stack(
      children: particles
          .map(
            (p) => _buildNeonParticle(
              p[0] as Color,
              p[1] as double,
              p[2] as double,
            ),
          )
          .toList(),
    );
  }

  Widget _buildNeonParticle(Color color, double left, double top) {
    return Positioned(
      left: left,
      top: top,
      child: Container(
        width: 6,
        height: 6,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          boxShadow: [BoxShadow(color: color, blurRadius: 8, spreadRadius: 2)],
        ),
      ),
    );
  }

  Widget _buildLogo() {
    return Column(
      children: [
        ShaderMask(
          shaderCallback: (bounds) => const LinearGradient(
            colors: [
              AppColors.neonPink,
              AppColors.neonMagenta,
              AppColors.primary,
            ],
            stops: [0.0, 0.5, 1.0],
          ).createShader(bounds),
          child: Text(
            translate('app.name'),
            style: const TextStyle(
              fontSize: 42,
              fontWeight: FontWeight.bold,
              color: Colors.white,
              shadows: [
                Shadow(blurRadius: 10, color: AppColors.neonPink),
                Shadow(blurRadius: 20, color: AppColors.neonPink),
              ],
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          translate('app.slogan'),
          style: const TextStyle(
            color: Color(0xCCFFFFFF),
            fontSize: 16,
            shadows: [Shadow(blurRadius: 5, color: Color(0x80FF00FF))],
          ),
        ),
      ],
    );
  }

  Widget _buildLoginForm() {
    return GlassCard(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            _buildEmailField(),
            const SizedBox(height: 16),
            _buildPasswordField(),
            const SizedBox(height: 16),
            _buildRememberMeOnly(), // 🔥 CAMBIO 4: Renombrado, ya solo tiene el checkbox
            const SizedBox(height: 16),
            GradientButton(
              onPressed: _login,
              text: translate('login.login_button'),
            ),
            const SizedBox(height: 16),
            _buildGoogleMobileButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildEmailField() {
    return TextField(
      controller: _emailController,
      decoration: InputDecoration(
        labelText: translate('login.email_label'),
        labelStyle: const TextStyle(color: Color(0xB3FFFFFF)),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.glassBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.neonPink),
        ),
        prefixIcon: const Icon(Icons.person, color: Color(0xB3FFFFFF)),
      ),
      style: const TextStyle(color: Colors.white),
    );
  }

  Widget _buildPasswordField() {
    return TextField(
      controller: _passwordController,
      obscureText: _obscurePassword,
      decoration: InputDecoration(
        labelText: translate('login.password_label'),
        labelStyle: const TextStyle(color: Color(0xB3FFFFFF)),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.glassBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.neonPink),
        ),
        prefixIcon: const Icon(Icons.lock, color: Color(0xB3FFFFFF)),
        suffixIcon: IconButton(
          icon: Icon(
            _obscurePassword ? Icons.visibility_off : Icons.visibility,
            color: const Color(0xB3FFFFFF),
          ),
          onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
        ),
      ),
      style: const TextStyle(color: Colors.white),
    );
  }

  // 🔥 CAMBIO 5: Modificado para quitar el botón de "olvidé contraseña"
  // Ahora solo se encarga del Checkbox "Recordarme"
  Widget _buildRememberMeOnly() {
    return Row(
      children: [
        Theme(
          data: ThemeData(
            checkboxTheme: const CheckboxThemeData(
              fillColor: MaterialStatePropertyAll(AppColors.neonPink),
            ),
          ),
          child: Checkbox(
            value: _rememberMe,
            onChanged: (value) => setState(() => _rememberMe = value!),
          ),
        ),
        Text(
          translate('login.remember_me'),
          style: const TextStyle(
            color: Color(0xCCFFFFFF),
            shadows: [Shadow(blurRadius: 5, color: Color(0x4DFF00FF))],
          ),
        ),
      ],
    );
  }

  Widget _buildGoogleMobileButton() {
    return OutlinedButton(
      onPressed: () async {
        final success = await _authController.googleLogin();
        if (success) {
          widget.onLogin();
        } else {
          _showErrorDialog(_authController.error);
        }
      },
      style: OutlinedButton.styleFrom(
        foregroundColor: Colors.white,
        side: const BorderSide(color: AppColors.glassBorder),
        backgroundColor: AppColors.glassWhite,
        minimumSize: const Size(double.infinity, 48),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Image.asset('assets/images/google.png', width: 20, height: 20),
          const SizedBox(width: 8),
          Text(
            translate('login.google_login'),
            style: const TextStyle(
              shadows: [Shadow(blurRadius: 5, color: Color(0x4DFF00FF))],
            ),
          ),
        ],
      ),
    );
  }

  // Removed _buildGoogleWebButton
  // Removed _showGoogleSignInModal

  Widget _buildRegisterPrompt() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          translate('login.no_account'),
          style: const TextStyle(
            color: Color(0xCCFFFFFF),
            shadows: [Shadow(blurRadius: 5, color: Color(0x4DFF00FF))],
          ),
        ),
        const SizedBox(width: 5),
        GestureDetector(
          onTap: widget.onRegister,
          // Aumentamos el área de toque para que sea más fácil pulsar en móvil
          behavior: HitTestBehavior.opaque,
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Text(
              translate('login.register_here'),
              style: const TextStyle(
                color: AppColors.neonPink,
                fontWeight: FontWeight.w600,
                shadows: [
                  Shadow(blurRadius: 8, color: Color(0x99FF00FF)),
                  Shadow(blurRadius: 15, color: Color(0x4DFF00FF)),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  // Removed _handleOAuthResponse
}
