import 'package:flutter/material.dart';
import 'package:password_strength_checker/password_strength_checker.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final passNotifier = ValueNotifier<PasswordStrength?>(null);

    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextField(
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                labelText: 'Password',
              ),
              onChanged: (value) {
                passNotifier.value = PasswordStrength.calculate(text: value);
              },
            ),
            const SizedBox(height: 20),
            PasswordStrengthChecker(strength: passNotifier),
          ],
        ),
      ),
    );
  }
}

  class PasswordValidator {
    static String? validate(String? password) {
      if (password == null || password.isEmpty) {
        return 'Por favor ingresa una contraseña';
      }
      if (password.length < 6) {
        return 'La contraseña debe tener al menos 6 caracteres';
      }
      final strength = PasswordStrength.calculate(text: password);
      if (strength == PasswordStrength.weak) {
        return 'La contraseña es débil. Usa mayúsculas, números y símbolos.';
      }
      return null;
    }

    static String getStrengthText(PasswordStrength? strength) {
      switch (strength) {
        case PasswordStrength.weak:
          return 'Débil';
        case PasswordStrength.medium:
          return 'Media';
        case PasswordStrength.strong:
          return 'Fuerte';
        default:
          return 'Sin evaluar';
      }
    }
  }