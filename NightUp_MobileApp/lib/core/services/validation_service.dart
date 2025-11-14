class ValidationService {
  static final ValidationService _instance = ValidationService._internal();
  factory ValidationService() => _instance;
  ValidationService._internal();

  // Email validation
  String? validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return 'El email es requerido';
    }
    
    final emailRegExp = RegExp(
      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
    );
    
    if (!emailRegExp.hasMatch(value)) {
      return 'Ingresa un email válido';
    }
    
    return null;
  }

  // Password validation
  String? validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'La contraseña es requerida';
    }
    
    if (value.length < 6) {
      return 'La contraseña debe tener al menos 6 caracteres';
    }
    
    return null;
  }

  // Username validation
  String? validateUsername(String? value) {
    if (value == null || value.isEmpty) {
      return 'El nombre de usuario es requerido';
    }
    
    if (value.length < 3) {
      return 'El nombre de usuario debe tener al menos 3 caracteres';
    }
    
    if (value.length > 20) {
      return 'El nombre de usuario no puede tener más de 20 caracteres';
    }
    
    final usernameRegExp = RegExp(r'^[a-zA-Z0-9_]+$');
    if (!usernameRegExp.hasMatch(value)) {
      return 'El nombre de usuario solo puede contener letras, números y guiones bajos';
    }
    
    return null;
  }

  // Required field validation
  String? validateRequired(String? value, {String fieldName = 'Este campo'}) {
    if (value == null || value.trim().isEmpty) {
      return '$fieldName es requerido';
    }
    return null;
  }

  // Phone number validation
  String? validatePhone(String? value) {
    if (value == null || value.isEmpty) {
      return null; // Phone is optional
    }
    
    final phoneRegExp = RegExp(r'^\+?[1-9]\d{8,14}$');
    if (!phoneRegExp.hasMatch(value.replaceAll(RegExp(r'[\s-()]'), ''))) {
      return 'Ingresa un número de teléfono válido';
    }
    
    return null;
  }
}