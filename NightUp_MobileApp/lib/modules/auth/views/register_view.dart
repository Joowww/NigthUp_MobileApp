import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_translate/flutter_translate.dart';
import 'dart:math';
import '../../../app/themes/app_colors.dart';
import '../../../app/widgets/neon_background.dart';
import '../../../app/widgets/custom_text_field.dart';
import '../../../app/widgets/gradient_button.dart';
import '../controllers/auth_controller.dart';

class RegisterView extends StatefulWidget {
  const RegisterView({Key? key}) : super(key: key);

  @override
  State<RegisterView> createState() => _RegisterViewState();
}

class _RegisterViewState extends State<RegisterView> with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _birthdayController = TextEditingController();
  final AuthController _authController = Get.find<AuthController>();
  
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _setupAnimations();
  }

  void _setupAnimations() {
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: const Interval(0.0, 0.5, curve: Curves.easeOut),
    ));

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: const Interval(0.3, 1.0, curve: Curves.easeOut),
    ));

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _usernameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _birthdayController.dispose();
    super.dispose();
  }

  void _handleRegister() async {
    if (_formKey.currentState!.validate()) {
      final success = await _authController.register(
        username: _usernameController.text.trim(),
        email: _emailController.text.trim(),
        password: _passwordController.text,
        birthday: _birthdayController.text.isNotEmpty 
            ? _birthdayController.text 
            : null,
      );

      if (success) {
        // Después del registro exitoso, ir a la pantalla de login
        Get.offAllNamed('/login');
      }
    }
  }

  void _generatePassword() {
    const chars = 'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789!@#\$%^&*';
    final random = Random.secure();
    final password = List.generate(12, (index) => chars[random.nextInt(chars.length)]).join();
    
    setState(() {
      _passwordController.text = password;
      _confirmPasswordController.text = password;
    });

    Get.snackbar(
      'Contraseña generada',
      'Se ha generado una contraseña segura',
      backgroundColor: AppColors.success.withOpacity(0.9),
      colorText: Colors.white,
      snackPosition: SnackPosition.BOTTOM,
      margin: const EdgeInsets.all(16),
      borderRadius: 12,
      duration: const Duration(seconds: 2),
    );
  }

  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().subtract(const Duration(days: 6570)), // 18 años
      firstDate: DateTime(1950),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: ThemeData.dark().copyWith(
            colorScheme: const ColorScheme.dark(
              primary: AppColors.neonPink,
              onPrimary: Colors.white,
              surface: AppColors.darkCard,
              onSurface: Colors.white,
            ),
            dialogBackgroundColor: AppColors.darkCard,
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _birthdayController.text = "${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}";
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: NeonBackground(
        child: SafeArea(
          child: Column(
            children: [
              // AppBar personalizado
              _buildAppBar(),
              
              // Formulario
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: FadeTransition(
                    opacity: _fadeAnimation,
                    child: SlideTransition(
                      position: _slideAnimation,
                      child: Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            // Título
                            _buildTitle(),
                            const SizedBox(height: 30),
                            
                            // Username field
                            CustomTextField(
                              controller: _usernameController,
                              label: translate('register.username'),
                              hint: translate('register.username'),
                              prefixIcon: const Icon(
                                Icons.person_outline,
                                color: AppColors.neonPink,
                              ),
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'El usuario es requerido';
                                }
                                if (value.length < 3) {
                                  return 'El usuario debe tener al menos 3 caracteres';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 20),
                            
                            // Email field
                            CustomTextField(
                              controller: _emailController,
                              label: translate('register.email'),
                              hint: translate('register.email'),
                              keyboardType: TextInputType.emailAddress,
                              prefixIcon: const Icon(
                                Icons.email_outlined,
                                color: AppColors.neonBlue,
                              ),
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'El email es requerido';
                                }
                                if (!GetUtils.isEmail(value)) {
                                  return 'Email inválido';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 20),
                            
                            // Birthday field
                            CustomTextField(
                              controller: _birthdayController,
                              label: translate('register.birthday'),
                              hint: translate('register.birthday_format'),
                              readOnly: true,
                              onTap: _selectDate,
                              prefixIcon: const Icon(
                                Icons.cake_outlined,
                                color: AppColors.neonPurple,
                              ),
                              suffixIcon: IconButton(
                                icon: const Icon(
                                  Icons.calendar_today,
                                  color: AppColors.neonPurple,
                                ),
                                onPressed: _selectDate,
                              ),
                            ),
                            const SizedBox(height: 20),
                            
                            // Password field con generador
                            CustomTextField(
                              controller: _passwordController,
                              label: translate('register.password'),
                              hint: translate('register.password'),
                              isPassword: true,
                              prefixIcon: const Icon(
                                Icons.lock_outline,
                                color: AppColors.neonOrange,
                              ),
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'La contraseña es requerida';
                                }
                                if (value.length < 6) {
                                  return 'La contraseña debe tener al menos 6 caracteres';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 12),
                            
                            // Botón generar contraseña
                            Align(
                              alignment: Alignment.centerRight,
                              child: TextButton.icon(
                                onPressed: _generatePassword,
                                icon: const Icon(
                                  Icons.auto_awesome,
                                  color: AppColors.neonOrange,
                                  size: 18,
                                ),
                                label: Text(
                                  translate('register.generate_password'),
                                  style: const TextStyle(
                                    color: AppColors.neonOrange,
                                    fontFamily: 'Poppins',
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 8),
                            
                            // Confirm password field
                            CustomTextField(
                              controller: _confirmPasswordController,
                              label: translate('register.confirm_password'),
                              hint: translate('register.confirm_password'),
                              isPassword: true,
                              prefixIcon: const Icon(
                                Icons.lock_outline,
                                color: AppColors.neonGreen,
                              ),
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Confirma tu contraseña';
                                }
                                if (value != _passwordController.text) {
                                  return 'Las contraseñas no coinciden';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 40),
                            
                            // Register button
                            Obx(() => GradientButton(
                              text: translate('register.register_button'),
                              onPressed: _handleRegister,
                              isLoading: _authController.isLoading.value,
                              gradient: AppColors.secondaryGradient,
                            )),
                            const SizedBox(height: 30),
                            
                            // Login link
                            _buildLoginLink(),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAppBar() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Container(
            decoration: BoxDecoration(
              color: AppColors.darkCard.withOpacity(0.5),
              borderRadius: BorderRadius.circular(12),
            ),
            child: IconButton(
              icon: const Icon(
                Icons.arrow_back_ios_new,
                color: AppColors.textPrimary,
              ),
              onPressed: () => Get.back(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTitle() {
    return Column(
      children: [
        Text(
          translate('register.title'),
          style: const TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
            fontFamily: 'Poppins',
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        Text(
          translate('register.subtitle'),
          style: const TextStyle(
            fontSize: 16,
            color: AppColors.textSecondary,
            fontFamily: 'Poppins',
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildLoginLink() {
    return Center(
      child: Wrap(
        alignment: WrapAlignment.center,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          Text(
            translate('register.has_account'),
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 14,
              fontFamily: 'Poppins',
            ),
          ),
          GestureDetector(
            onTap: () => Get.back(),
            child: ShaderMask(
              shaderCallback: (bounds) => AppColors.secondaryGradient.createShader(bounds),
              child: Text(
                translate('register.login_link'),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Poppins',
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}