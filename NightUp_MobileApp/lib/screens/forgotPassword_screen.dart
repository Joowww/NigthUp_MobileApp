import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_translate/flutter_translate.dart';
import '../controllers/auth_controller.dart';
import '../services/api_service.dart';
import '../theme/colors.dart';
import '../widgets/glass_card.dart';
import '../widgets/gradient_button.dart';

class ForgotPasswordScreen extends StatefulWidget {
  final VoidCallback onBack;

  const ForgotPasswordScreen({super.key, required this.onBack});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _emailController = TextEditingController();
  final _securityAnswerController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  late final AuthController _authController;
  String? _selectedSecurityQuestion;
  int _currentStep = 0;
  double _passwordStrength = 0;
  bool _passwordsMatch = true;
  String? _resetToken;
  String? _userEmail;

  @override
  void initState() {
    super.initState();
    if (Get.isRegistered<AuthController>()) {
      _authController = Get.find<AuthController>();
    } else {
      if (!Get.isRegistered<ApiService>()) {
        Get.put(ApiService());
      }
      _authController = Get.put(AuthController());
    }
  }

  void _updatePasswordStrength() {
    final password = _newPasswordController.text;
    double strength = 0;

    if (password.length >= 8) strength += 0.3;
    if (password.contains(RegExp(r'[A-Z]'))) strength += 0.3;
    if (password.contains(RegExp(r'[0-9]'))) strength += 0.3;
    if (password.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]'))) strength += 0.1;

    setState(() {
      _passwordStrength = strength.clamp(0.0, 1.0);
    });
  }

  void _validatePasswordMatch() {
    setState(() {
      _passwordsMatch =
          _newPasswordController.text == _confirmPasswordController.text ||
          _confirmPasswordController.text.isEmpty;
    });
  }

  Color _getPasswordStrengthColor() {
    if (_passwordStrength < 0.4) return Colors.red;
    if (_passwordStrength < 0.7) return Colors.orange;
    return Colors.green;
  }

  void _checkEmail() async {
    if (_emailController.text.isEmpty) {
      _showErrorDialog(translate('forgot_password.email_required'));
      return;
    }

    final result = await _authController.forgotPasswordFlow(
      email: _emailController.text.trim(),
    );

    if (result['success'] == true) {
      setState(() {
        _currentStep = 1;
        _selectedSecurityQuestion = result['securityQuestionKey'];
        _userEmail = result['email'];
      });
    } else {
      _showErrorDialog(result['error'] ?? translate('error.unknown'));
    }
  }

  void _verifySecurityAnswer() async {
    if (_securityAnswerController.text.isEmpty) {
      _showErrorDialog(translate('forgot_password.answer_required'));
      return;
    }

    final result = await _authController.forgotPasswordFlow(
      email: _userEmail!,
      securityAnswer: _securityAnswerController.text.trim(),
    );

    if (result['success'] == true) {
      setState(() {
        _currentStep = 2;
        _resetToken = result['resetToken'];
      });
    } else {
      _showErrorDialog(result['error'] ?? translate('error.unknown'));
    }
  }

  void _resetPassword() async {
    if (_newPasswordController.text.isEmpty ||
        _confirmPasswordController.text.isEmpty) {
      _showErrorDialog(translate('forgot_password.password_required'));
      return;
    }

    if (!_passwordsMatch) {
      _showErrorDialog(translate('register.password_match_error'));
      return;
    }

    if (_passwordStrength < 0.4) {
      _showErrorDialog(translate('forgot_password.password_weak'));
      return;
    }

    final result = await _authController.forgotPasswordFlow(
      email: _userEmail!,
      securityAnswer: _securityAnswerController.text.trim(),
      newPassword: _newPasswordController.text,
      resetToken: _resetToken!,
    );

    if (result['success'] == true) {
      _showSuccessDialog();
    } else {
      _showErrorDialog(result['error'] ?? translate('error.unknown'));
    }
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.black87,
        title: Text(
          translate('Cambiar contraseña'),
          style: const TextStyle(color: Colors.white),
        ),
        content: Text(
          translate('Contraseña cambiada correctamente'),
          style: const TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              widget.onBack();
            },
            child: Text(
              translate('common.ok'),
              style: const TextStyle(color: AppColors.neonPink),
            ),
          ),
        ],
      ),
    );
  }

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
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          _buildBackgroundGradients(),
          Positioned.fill(
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24.0,
                  vertical: 80, // Más espacio arriba para el botón de atrás
                ),
                child: Column(
                  children: [
                    // _buildBackButton(), // Lo quitamos de aquí para ponerlo flotante
                    _buildTitle(),
                    const SizedBox(height: 30),
                    _buildForgotPasswordForm(),
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            top: 0,
            left: 0,
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: GestureDetector(
                  onTap: widget.onBack,
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0x1AFFFFFF),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.arrow_back,
                      color: Colors.white,
                      size: 24,
                    ),
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
          left: -100,
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
          right: -100,
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
    return Stack(
      children: [
        _buildNeonParticle(const Color(0x66FF00FF), 50.0, 100.0),
        _buildNeonParticle(const Color(0x99FF00FF), 150.0, 200.0),
        _buildNeonParticle(const Color(0x4DFF00FF), 300.0, 80.0),
        _buildNeonParticle(const Color(0x80FF00FF), 80.0, 400.0),
        _buildNeonParticle(const Color(0x66FF00FF), 250.0, 350.0),
        _buildNeonParticle(const Color(0x99FF00FF), 320.0, 150.0),
      ],
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

  Widget _buildBackButton() {
    return Align(
      alignment: Alignment.topLeft,
      child: GestureDetector(
        onTap: widget.onBack,
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0x1AFFFFFF),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(Icons.arrow_back, color: Colors.white, size: 24),
        ),
      ),
    );
  }

  Widget _buildTitle() {
    return Column(
      children: [
        Text(
          translate('forgot_password.title'),
          style: const TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: Colors.white,
            shadows: [
              Shadow(blurRadius: 10, color: AppColors.neonPink),
              Shadow(blurRadius: 20, color: AppColors.neonPink),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Text(
          _currentStep == 0
              ? translate('forgot_password.step1_message')
              : _currentStep == 1
              ? translate('forgot_password.step2_message')
              : translate('forgot_password.step3_message'),
          style: const TextStyle(
            color: Color(0xCCFFFFFF),
            fontSize: 16,
            shadows: [Shadow(blurRadius: 5, color: Color(0x80FF00FF))],
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildForgotPasswordForm() {
    return GlassCard(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            if (_currentStep == 0) ...[
              TextField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: InputDecoration(
                  labelText: translate('forgot_password.email_label'),
                  labelStyle: const TextStyle(color: Color(0xB3FFFFFF)),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: AppColors.glassBorder),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: AppColors.neonPink),
                  ),
                  prefixIcon: const Icon(Icons.email, color: Color(0xB3FFFFFF)),
                ),
                style: const TextStyle(color: Colors.white),
              ),
              const SizedBox(height: 20),
              GradientButton(
                onPressed: _checkEmail,
                text: translate('forgot_password.continue_button'),
              ),
            ] else if (_currentStep == 1) ...[
              Text(
                translate('forgot_password.security_question_label'),
                style: const TextStyle(
                  color: Color(0xCCFFFFFF),
                  fontSize: 16,
                  shadows: [Shadow(blurRadius: 5, color: Color(0x80FF00FF))],
                ),
              ),
              const SizedBox(height: 8),
              if (_selectedSecurityQuestion != null &&
                  _selectedSecurityQuestion!.isNotEmpty) ...[
                Text(
                  _getSecurityQuestionText(_selectedSecurityQuestion!),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    shadows: [Shadow(blurRadius: 5, color: Color(0x80FF00FF))],
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _securityAnswerController,
                  decoration: InputDecoration(
                    labelText: translate(
                      'forgot_password.security_answer_label',
                    ),
                    labelStyle: const TextStyle(color: Color(0xB3FFFFFF)),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(
                        color: AppColors.glassBorder,
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: AppColors.neonPink),
                    ),
                    prefixIcon: const Icon(
                      Icons.question_answer,
                      color: Color(0xB3FFFFFF),
                    ),
                  ),
                  style: const TextStyle(color: Colors.white),
                ),
                const SizedBox(height: 20),
                GradientButton(
                  onPressed: _verifySecurityAnswer,
                  text: translate('forgot_password.continue_button'),
                ),
              ] else ...[
                Text(
                  translate('forgot_password.security_question_error'),
                  style: const TextStyle(color: Colors.red, fontSize: 16),
                  textAlign: TextAlign.center,
                ),
              ],
            ] else if (_currentStep == 2) ...[
              TextField(
                controller: _newPasswordController,
                obscureText: true,
                onChanged: (value) => _updatePasswordStrength(),
                decoration: InputDecoration(
                  labelText: translate('forgot_password.new_password'),
                  labelStyle: const TextStyle(color: Color(0xB3FFFFFF)),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: AppColors.glassBorder),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: AppColors.neonPink),
                  ),
                  prefixIcon: const Icon(Icons.lock, color: Color(0xB3FFFFFF)),
                ),
                style: const TextStyle(color: Colors.white),
              ),
              const SizedBox(height: 8),
              LinearProgressIndicator(
                value: _passwordStrength,
                backgroundColor: Colors.grey[800],
                color: _getPasswordStrengthColor(),
                minHeight: 4,
              ),
              const SizedBox(height: 4),
              Text(
                _getPasswordStrengthText(),
                style: TextStyle(
                  color: _getPasswordStrengthColor(),
                  fontSize: 12,
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _confirmPasswordController,
                obscureText: true,
                onChanged: (value) => _validatePasswordMatch(),
                decoration: InputDecoration(
                  labelText: translate('forgot_password.confirm_new_password'),
                  labelStyle: const TextStyle(color: Color(0xB3FFFFFF)),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: _passwordsMatch
                          ? AppColors.glassBorder
                          : Colors.red,
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: _passwordsMatch ? AppColors.neonPink : Colors.red,
                    ),
                  ),
                  errorText: _passwordsMatch
                      ? null
                      : translate('register.password_match_error'),
                  prefixIcon: const Icon(
                    Icons.lock_outline,
                    color: Color(0xB3FFFFFF),
                  ),
                ),
                style: const TextStyle(color: Colors.white),
              ),
              const SizedBox(height: 20),
              GradientButton(
                onPressed: _resetPassword,
                text: translate('forgot_password.reset_button'),
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _getSecurityQuestionText(String key) {
    final questions = {
      "security.question.pet_name": translate('security_questions.pet_name'),
      "security.question.birth_city": translate(
        'security_questions.birth_city',
      ),
      "security.question.mother_maiden_name": translate(
        'security_questions.mother_maiden_name',
      ),
      "security.question.first_school": translate(
        'security_questions.first_school',
      ),
      "security.question.favorite_food": translate(
        'security_questions.favorite_food',
      ),
      "security.question.childhood_street": translate(
        'security_questions.childhood_street',
      ),
      "security.question.best_friend": translate(
        'security_questions.best_friend',
      ),
      "security.question.first_job": translate('security_questions.first_job'),
      "security.question.favorite_book": translate(
        'security_questions.favorite_book',
      ),
      "security.question.birth_hospital": translate(
        'security_questions.birth_hospital',
      ),
      "security.question.father_middle_name": translate(
        'security_questions.father_middle_name',
      ),
      "security.question.first_car": translate('security_questions.first_car'),
      "security.question.favorite_teacher": translate(
        'security_questions.favorite_teacher',
      ),
      "security.question.graduation_year": translate(
        'security_questions.graduation_year',
      ),
      "security.question.favorite_movie": translate(
        'security_questions.favorite_movie',
      ),
    };
    return questions[key] ?? key;
  }

  String _getPasswordStrengthText() {
    if (_passwordStrength < 0.4)
      return translate('register.password_strength.weak');
    if (_passwordStrength < 0.7)
      return translate('register.password_strength.medium');
    return translate('register.password_strength.strong');
  }
}
