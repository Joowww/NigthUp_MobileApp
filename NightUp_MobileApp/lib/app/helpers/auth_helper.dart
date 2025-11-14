import 'package:flutter/material.dart';
import 'package:get/get.dart';

class AuthHelper {
  static void showTokenExpiredDialog() {
    Get.dialog(
      AlertDialog(
        backgroundColor: const Color(0xFF1E1E1E),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: const Row(
          children: [
            Icon(
              Icons.warning_amber_rounded,
              color: Colors.red,
              size: 26,
            ),
            SizedBox(width: 16),
            Text(
              'Sesión Expirada',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
          ],
        ),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Tu sesión ha expirado. Por favor, inicia sesión nuevamente para continuar usando todas las funcionalidades de la aplicación.',
              style: TextStyle(
                fontSize: 16,
                color: Colors.white70,
                height: 1.4,
              ),
            ),
          ],
        ),
        actions: [
          Container(
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF8B5CF6), Color(0xFFA855F7)],
              ),
              borderRadius: BorderRadius.circular(8),
            ),
            child: TextButton(
              onPressed: () {
                Get.back();
                Get.offAllNamed('/login');
              },
              child: const Text(
                'Iniciar Sesión',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}