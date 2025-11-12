import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_translate/flutter_translate.dart';
import '../Controllers/auth_controller.dart';
import '../Models/user.dart';
import 'package:password_strength_checker/password_strength_checker.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({Key? key}) : super(key: key);

  @override
  _RegisterScreenState createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  Color _getPasswordBorderColor(PasswordStrength? strength) {
    switch (strength) {
      case PasswordStrength.strong:
        return Colors.green;
      case PasswordStrength.medium:
        return Colors.orange;
      case PasswordStrength.weak:
        return Colors.red;
      default:
        return Colors.grey.shade200;
    }
  }
  
  final ValueNotifier<PasswordStrength?> passwordStrengthNotifier = ValueNotifier<PasswordStrength?>(null);
  final AuthController authController = Get.find<AuthController>();
  final TextEditingController usernameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController confirmPasswordController = TextEditingController();
  final TextEditingController birthdayController = TextEditingController();
  bool isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  final _formKey = GlobalKey<FormState>();

  void _showSuccessDialog() {
    Get.dialog(
      AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.green, size: 30),
            const SizedBox(width: 10),
            Text(translate('common.success')),
          ],
        ),
        content: Text(translate('register.success_message')),
        actions: [
          TextButton(
            onPressed: () {
              Get.back();
              Get.back();
            },
            child: Text(
              translate('common.continue'),
              style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold),
            ),
          ),
        ],
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      ),
      barrierDismissible: false,
    );
  }

  String? _validateUsername(String? value) {
    if (value == null || value.isEmpty) {
      return translate('validation.required');
    }
    if (value.length < 3) {
      return translate('validation.min_length', args: {'length': '3'});
    }
    if (!RegExp(r'^[a-zA-Z0-9_]+$').hasMatch(value)) {
      return 'Solo se permiten letras, números y guiones bajos';
    }
    return null;
  }

  Widget _buildPasswordRequirements(String password) {
    final requirements = [
      {
        'label': translate('validation.min_length', args: {'length': '6'}),
        'valid': password.length >= 6,
      },
      {
        'label': 'Al menos 1 letra minúscula',
        'valid': RegExp(r'[a-z]').hasMatch(password),
      },
      {
        'label': 'Al menos 1 letra mayúscula',
        'valid': RegExp(r'[A-Z]').hasMatch(password),
      },
      {
        'label': 'Al menos 1 dígito',
        'valid': RegExp(r'[0-9]').hasMatch(password),
      },
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: requirements.map((req) {
        Color color;
        if (req['valid'] as bool) {
          color = Colors.green;
        } else if (password.isEmpty) {
          color = Colors.grey;
        } else {
          color = Colors.red;
        }
        return Row(
          children: [
            Icon(
              req['valid'] as bool ? Icons.check_circle : Icons.cancel,
              color: color,
              size: 18,
            ),
            const SizedBox(width: 8),
            Text(
              req['label'] as String,
              style: TextStyle(color: color, fontSize: 14),
            ),
          ],
        );
      }).toList(),
    );
  }

  String? _validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return translate('validation.required');
    }
    if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
      return translate('validation.invalid_email');
    }
    return null;
  }

  String? _validateConfirmPassword(String? value) {
    if (value == null || value.isEmpty) {
      return translate('validation.required');
    }
    if (value != passwordController.text) {
      return translate('validation.password_mismatch');
    }
    return null;
  }

  String? _validateBirthday(String? value) {
    if (value == null || value.isEmpty) {
      return translate('validation.required');
    }
    if (!RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch(value)) {
      return 'Formato de fecha incorrecto. Usa YYYY-MM-DD';
    }
    try {
      final parts = value.split('-');
      final year = int.parse(parts[0]);
      final month = int.parse(parts[1]);
      final day = int.parse(parts[2]);
      final birthday = DateTime(year, month, day);
      final now = DateTime.now();
      final age = now.year - birthday.year;

      if (birthday.isAfter(now)) {
        return 'La fecha no puede ser futura';
      }

      if (age < 13) {
        return 'Debes tener al menos 13 años';
      }

      if (age > 120) {
        return 'Por favor ingresa una fecha válida';
      }
    } catch (e) {
      return 'Fecha inválida';
    }

    return null;
  }

  PasswordStrength _customPasswordStrength(String password) {
    int count = 0;
    if (password.length >= 12) count++;
    if (RegExp(r'[a-z]').hasMatch(password)) count++;
    if (RegExp(r'[A-Z]').hasMatch(password)) count++;
    if (RegExp(r'[0-9]').hasMatch(password)) count++;
    if (RegExp(r'[!@#\$%^&*(),.?":{}|<>]').hasMatch(password)) count++;
    switch (count) {
      case 5:
        return PasswordStrength.secure;
      case 4:
        return PasswordStrength.strong;
      case 3:
        return PasswordStrength.medium;
      default:
        return PasswordStrength.weak;
    }
  }

  String _generateStrongPassword({int length = 14}) {
    const String lower = 'abcdefghijklmnopqrstuvwxyz';
    const String upper = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ';
    const String digits = '0123456789';
    const String special = '!@#\$%^&*(),.?":{}|<>';
    final String all = lower + upper + digits + special;
    final rand = DateTime.now().microsecondsSinceEpoch;
    final List<String> password = [];
    password.add(lower[rand % lower.length]);
    password.add(upper[(rand ~/ 2) % upper.length]);
    password.add(digits[(rand ~/ 3) % digits.length]);
    password.add(special[(rand ~/ 4) % special.length]);
    for (int i = password.length; i < length; i++) {
      password.add(all[(rand + i * 17) % all.length]);
    }
    password.shuffle();
    return password.join();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(translate('register.title')),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 20),
              _buildHeader(),
              const SizedBox(height: 32),
              _buildRegisterForm(),
              const SizedBox(height: 24),
              _buildFooter(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 60,
          height: 60,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF667EEA), Color(0xFF764BA2)],
            ),
            borderRadius: BorderRadius.circular(16),
          ),
          child: const Icon(Icons.person_add, color: Colors.white, size: 32),
        ),
        const SizedBox(height: 24),
        Text(
          translate('register.title'),
          style: const TextStyle(
            fontSize: 32,
            fontWeight: FontWeight.w800,
            color: Colors.black87,
            height: 1.2,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          translate('register.subtitle'),
          style: TextStyle(
            fontSize: 16,
            color: Colors.grey.shade600,
          ),
        ),
      ],
    );
  }

  Widget _buildRegisterForm() {
    return Form(
      key: _formKey,
      child: Column(
        children: [
          _buildTextField(
            controller: usernameController,
            label: translate('register.username'),
            icon: Icons.person_outline,
            validator: _validateUsername,
          ),
          const SizedBox(height: 16),
          _buildTextField(
            controller: emailController,
            label: translate('register.email'),
            icon: Icons.email_outlined,
            validator: _validateEmail,
          ),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: _buildPasswordRequirements(passwordController.text),
          ),
          TextFormField(
            controller: passwordController,
            obscureText: _obscurePassword,
            onChanged: (value) {
              passwordStrengthNotifier.value = _customPasswordStrength(value);
              setState(() {});
            },
            decoration: InputDecoration(
              labelText: translate('register.password'),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color: _getPasswordBorderColor(passwordStrengthNotifier.value),
                  width: 2,
                ),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color: _getPasswordBorderColor(passwordStrengthNotifier.value),
                  width: 2,
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color: _getPasswordBorderColor(passwordStrengthNotifier.value),
                  width: 2,
                ),
              ),
              fillColor: Colors.grey.shade50,
              filled: true,
              prefixIcon: const Icon(Icons.lock_outline, color: Colors.grey),
              suffixIcon: IconButton(
                icon: Icon(
                  _obscurePassword ? Icons.visibility_off : Icons.visibility,
                  color: Colors.grey,
                ),
                onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            ),
          ),
          const SizedBox(height: 8),
          ValueListenableBuilder<PasswordStrength?>(
            valueListenable: passwordStrengthNotifier,
            builder: (context, strength, _) {
              String label = '';
              Color color = _getPasswordBorderColor(strength);
              if (strength == PasswordStrength.secure) {
                color = const Color(0xFF0B6C0E);
              }
              switch (strength) {
                case PasswordStrength.weak:
                  label = 'Weak';
                  break;
                case PasswordStrength.medium:
                  label = 'Medium';
                  break;
                case PasswordStrength.strong:
                  label = 'Strong';
                  break;
                case PasswordStrength.secure:
                  label = 'Secure';
                  break;
                default:
                  label = '';
              }
              return Row(
                children: [
                  Container(
                    margin: const EdgeInsets.only(right: 8),
                    child: Text(
                      label,
                      style: TextStyle(
                        color: color,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  Expanded(
                    child: Container(
                      height: 8,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        color: Colors.grey.shade300,
                      ),
                      child: FractionallySizedBox(
                        alignment: Alignment.centerLeft,
                        widthFactor: _getStrengthWidth(strength),
                        child: Container(
                          height: 8,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(8),
                            color: color,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: 16),
          _buildPasswordField(
            controller: confirmPasswordController,
            label: translate('register.confirm_password'),
            obscureText: _obscureConfirmPassword,
            onToggle: () => setState(() => _obscureConfirmPassword = !_obscureConfirmPassword),
            validator: _validateConfirmPassword,
          ),
          const SizedBox(height: 16),
          _buildTextField(
            controller: birthdayController,
            label: '${translate('register.birthday')} (YYYY-MM-DD)',
            icon: Icons.cake_outlined,
            hintText: '2000-01-01',
            validator: _validateBirthday,
          ),
          const SizedBox(height: 32),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton(
              onPressed: () {
                final generated = _generateStrongPassword();
                passwordController.text = generated;
                passwordStrengthNotifier.value = _customPasswordStrength(generated);
                setState(() {});
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.grey.shade200,
                foregroundColor: Colors.black87,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text('Generar contraseña'),
            ),
          ),
          const SizedBox(height: 32),
          _buildRegisterButton(),
        ],
      ),
    );
  }

  double _getStrengthWidth(PasswordStrength? strength) {
    switch (strength) {
      case PasswordStrength.strong:
        return 0.75;
      case PasswordStrength.medium:
        return 0.4;
      case PasswordStrength.weak:
        return 0.15;
      case PasswordStrength.secure:
        return 1.0;
      default:
        return 0.0;
    }
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    required String? Function(String?) validator,
    String? hintText,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: TextFormField(
        controller: controller,
        style: const TextStyle(fontSize: 16),
        decoration: InputDecoration(
          labelText: label,
          hintText: hintText,
          border: InputBorder.none,
          prefixIcon: Icon(icon, color: Colors.grey),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        ),
        validator: validator,
      ),
    );
  }

  Widget _buildPasswordField({
    required TextEditingController controller,
    required String label,
    required bool obscureText,
    required VoidCallback onToggle,
    required String? Function(String?) validator,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: TextFormField(
        controller: controller,
        obscureText: obscureText,
        style: const TextStyle(fontSize: 16),
        decoration: InputDecoration(
          labelText: label,
          border: InputBorder.none,
          prefixIcon: const Icon(Icons.lock_outline, color: Colors.grey),
          suffixIcon: IconButton(
            icon: Icon(
              obscureText ? Icons.visibility_off : Icons.visibility,
              color: Colors.grey,
            ),
            onPressed: onToggle,
          ),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        ),
        validator: validator,
      ),
    );
  }

  Widget _buildRegisterButton() {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed: _handleRegister,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF667EEA),
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: isLoading
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            : Text(
                translate('register.register_button'),
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
      ),
    );
  }

  Widget _buildFooter() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          translate('register.has_account'),
          style: TextStyle(color: Colors.grey.shade600),
        ),
        GestureDetector(
          onTap: () => Get.back(),
          child: Text(
            translate('register.login_link'),
            style: const TextStyle(
              color: Color(0xFF667EEA),
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }

  void _handleRegister() async {
    if (_formKey.currentState!.validate()) {
      setState(() => isLoading = true);

      User newUser = User(
        id: '',
        username: usernameController.text,
        email: emailController.text,
        birthday: birthdayController.text,
        role: 'user',
        active: true,
        events: [],
      );

      final result = await authController.register(newUser, passwordController.text);
      setState(() => isLoading = false);

      if (result['success'] == true) {
        _showSuccessDialog();
      } else {
        Get.snackbar(
          translate('common.error'),
          result['message'],
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red,
          colorText: Colors.white,
          borderRadius: 12,
          margin: const EdgeInsets.all(16),
        );
      }
    } else {
      Get.snackbar(
        translate('validation.error'),
        translate('register.validation_error'),
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.orange,
        colorText: Colors.white,
        borderRadius: 12,
        margin: const EdgeInsets.all(16),
      );
    }
  }
}