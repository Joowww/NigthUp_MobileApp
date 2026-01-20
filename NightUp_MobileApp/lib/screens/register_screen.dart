import 'package:flutter/material.dart';
import 'package:flutter_translate/flutter_translate.dart';
import 'dart:math';
import 'package:get/get.dart';
import '../controllers/auth_controller.dart';
import '../services/api_service.dart';
import '../theme/colors.dart';
import '../widgets/glass_card.dart';
import '../widgets/gradient_button.dart';

class RegisterScreen extends StatefulWidget {
  final VoidCallback onBack;
  final VoidCallback onRegister;

  const RegisterScreen({
    super.key,
    required this.onBack,
    required this.onRegister,
  });

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _nameController = TextEditingController();
  final _usernameController = TextEditingController();
  final _dateOfBirthController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _securityAnswerController = TextEditingController();

  late final AuthController _authController;

  String? _selectedSecurityQuestion;
  double _passwordStrength = 0;
  bool _passwordsMatch = true;

  final List<Map<String, String>> _securityQuestions = [
    {
      "key": "security.question.pet_name",
      "text": translate('security_questions.pet_name'),
    },
    {
      "key": "security.question.birth_city",
      "text": translate('security_questions.birth_city'),
    },
    {
      "key": "security.question.mother_maiden_name",
      "text": translate('security_questions.mother_maiden_name'),
    },
    {
      "key": "security.question.first_school",
      "text": translate('security_questions.first_school'),
    },
    {
      "key": "security.question.favorite_food",
      "text": translate('security_questions.favorite_food'),
    },
    {
      "key": "security.question.childhood_street",
      "text": translate('security_questions.childhood_street'),
    },
    {
      "key": "security.question.best_friend",
      "text": translate('security_questions.best_friend'),
    },
    {
      "key": "security.question.first_job",
      "text": translate('security_questions.first_job'),
    },
    {
      "key": "security.question.favorite_book",
      "text": translate('security_questions.favorite_book'),
    },
    {
      "key": "security.question.birth_hospital",
      "text": translate('security_questions.birth_hospital'),
    },
    {
      "key": "security.question.father_middle_name",
      "text": translate('security_questions.father_middle_name'),
    },
    {
      "key": "security.question.first_car",
      "text": translate('security_questions.first_car'),
    },
    {
      "key": "security.question.favorite_teacher",
      "text": translate('security_questions.favorite_teacher'),
    },
    {
      "key": "security.question.graduation_year",
      "text": translate('security_questions.graduation_year'),
    },
    {
      "key": "security.question.favorite_movie",
      "text": translate('security_questions.favorite_movie'),
    },
  ];

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
    _passwordController.addListener(_updatePasswordStrength);
    _confirmPasswordController.addListener(_validatePasswordMatch);
  }

  void _updatePasswordStrength() {
    final password = _passwordController.text;
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
          _passwordController.text == _confirmPasswordController.text ||
          _confirmPasswordController.text.isEmpty;
    });
  }

  void _generatePassword() {
    const chars =
        'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789!@#\$%^&*';
    final random = Random();
    final password = String.fromCharCodes(
      Iterable.generate(
        12,
        (_) => chars.codeUnitAt(random.nextInt(chars.length)),
      ),
    );

    setState(() {
      _passwordController.text = password;
      _confirmPasswordController.text = password;
      _updatePasswordStrength();
      _validatePasswordMatch();
    });
  }

  Color _getPasswordStrengthColor() {
    if (_passwordStrength < 0.4) return Colors.red;
    if (_passwordStrength < 0.7) return Colors.orange;
    return Colors.green;
  }

  String _getPasswordStrengthText() {
    if (_passwordStrength < 0.4)
      return translate('register.password_strength.weak');
    if (_passwordStrength < 0.7)
      return translate('register.password_strength.medium');
    return translate('register.password_strength.strong');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          _buildBackgroundGradients(),
          SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 24.0,
                vertical: 40,
              ),
              child: Column(
                children: [
                  _buildBackButton(),
                  const SizedBox(height: 30),
                  _buildTitle(),
                  const SizedBox(height: 30),
                  _buildRegisterForm(),
                ],
              ),
            ),
          ),
        ],
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
          translate('register.title'),
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
          translate('register.slogan'),
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

  Widget _buildRegisterForm() {
    return GlassCard(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            TextField(
              controller: _nameController,
              decoration: InputDecoration(
                labelText: translate('register.full_name'),
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
                prefixIcon: const Icon(Icons.person, color: Color(0xB3FFFFFF)),
              ),
              style: const TextStyle(color: Colors.white),
            ),
            const SizedBox(height: 12),

            TextField(
              controller: _usernameController,
              decoration: InputDecoration(
                labelText: translate('register.username'),
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
                prefixIcon: const Icon(Icons.people, color: Color(0xB3FFFFFF)),
              ),
              style: const TextStyle(color: Colors.white),
            ),

            const SizedBox(height: 12),
            TextField(
              controller: _dateOfBirthController,
              readOnly: true,
              onTap: () => _selectDateOfBirth(context),
              decoration: InputDecoration(
                labelText: translate('register.birth_date'),
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
                prefixIcon: const Icon(
                  Icons.calendar_today,
                  color: Color(0xB3FFFFFF),
                ),
              ),
              style: const TextStyle(color: Colors.white),
            ),

            const SizedBox(height: 12),
            TextField(
              controller: _phoneController,
              keyboardType: TextInputType.phone,
              decoration: InputDecoration(
                labelText: translate('register.phone'),
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
                prefixIcon: const Icon(Icons.phone, color: Color(0xB3FFFFFF)),
              ),
              style: const TextStyle(color: Colors.white),
            ),

            const SizedBox(height: 12),
            TextField(
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              decoration: InputDecoration(
                labelText: translate('register.email'),
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

            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _passwordController,
                    obscureText: true,
                    decoration: InputDecoration(
                      labelText: translate('register.password'),
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
                        Icons.lock,
                        color: Color(0xB3FFFFFF),
                      ),
                    ),
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  onPressed: _generatePassword,
                  icon: const Icon(Icons.autorenew, color: AppColors.neonPink),
                  tooltip: translate('register.generate_password'),
                ),
              ],
            ),
            const SizedBox(height: 8),
            LinearProgressIndicator(
              value: _passwordStrength,
              backgroundColor: Colors.grey[800],
              color: _getPasswordStrengthColor(),
              minHeight: 4,
            ),
            const SizedBox(height: 4),
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                '${translate('register.password_strength.label')}: ${_getPasswordStrengthText()}',
                style: TextStyle(
                  color: _getPasswordStrengthColor(),
                  fontSize: 12,
                ),
              ),
            ),

            const SizedBox(height: 12),
            TextField(
              controller: _confirmPasswordController,
              obscureText: true,
              decoration: InputDecoration(
                labelText: translate('register.confirm_password'),
                labelStyle: const TextStyle(color: Color(0xB3FFFFFF)),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: _passwordsMatch ? AppColors.glassBorder : Colors.red,
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

            const SizedBox(height: 12),
            Container(
              decoration: BoxDecoration(
                border: Border.all(
                  color: _selectedSecurityQuestion == null
                      ? AppColors.glassBorder
                      : AppColors.neonPink,
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: _selectedSecurityQuestion,
                  isExpanded: true,
                  hint: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Text(
                      translate('register.security_question'),
                      style: const TextStyle(color: Color(0xB3FFFFFF)),
                    ),
                  ),
                  icon: const Padding(
                    padding: EdgeInsets.only(right: 12),
                    child: Icon(
                      Icons.arrow_drop_down,
                      color: Color(0xB3FFFFFF),
                    ),
                  ),
                  items: _securityQuestions.map((question) {
                    return DropdownMenuItem<String>(
                      value: question['key'],
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        child: Text(
                          question['text']!,
                          style: const TextStyle(color: Colors.white),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      _selectedSecurityQuestion = value;
                    });
                  },
                ),
              ),
            ),

            const SizedBox(height: 12),
            TextField(
              controller: _securityAnswerController,
              decoration: InputDecoration(
                labelText: translate('register.security_answer'),
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
                prefixIcon: const Icon(
                  Icons.security,
                  color: Color(0xB3FFFFFF),
                ),
              ),
              style: const TextStyle(color: Colors.white),
            ),

            const SizedBox(height: 20),

            GradientButton(
              onPressed: widget.onRegister,
              text: translate('register.register_button'),
            ),

            const SizedBox(height: 16),

            OutlinedButton(
              onPressed: _googleRegister,
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.white,
                side: const BorderSide(color: AppColors.glassBorder),
                backgroundColor: AppColors.glassWhite,
                minimumSize: const Size(double.infinity, 48),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Image.asset(
                    'assets/images/google.png',
                    width: 20,
                    height: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    translate('register.google_register'),
                    style: const TextStyle(
                      shadows: [
                        Shadow(blurRadius: 5, color: Color(0x4DFF00FF)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _googleRegister() async {
    final success = await _authController.googleLogin();
    if (success) {
      widget.onRegister();
    } else {
      _showErrorDialog(_authController.error);
    }
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

  Future<void> _selectDateOfBirth(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
    );

    if (picked != null) {
      setState(() {
        _dateOfBirthController.text =
            "${picked.day}/${picked.month}/${picked.year}";
      });
    }
  }
}
