class ContentModerationService {
  static const Map<String, List<String>> bannedWords = {
    'general': [
      'idiota',
      'idiotas',
      'estúpido',
      'estúpidos',
      'imbécil',
      'imbéciles',
      'tonto',
      'tonta',
      'tontos',
      'tontas',
      'bobo',
      'bobos',
      'burro',
      'burra',
      'burros',
      'burras',
      'zopenco',
      'zopencos',
      'payaso',
      'payasa',
      'payasos',
      'payasas',
      'patético',
      'patética',
      'patéticos',
      'patéticas',
      'mediocre',
      'inútil',
      'inútiles',
      'pesado',
      'pesada',
      'pesados',
      'pesadas',
      'maleducado',
      'maleducada',
      'maleducados',
      'maleducadas',
    ],
    'strong': [
      'mierda',
      'mierdas',
      'puto',
      'puta',
      'putos',
      'putas',
      'cabrón',
      'cabrona',
      'cabrones',
      'gilipollas',
      'subnormal',
      'malnacido',
      'malnacida',
      'hijo de puta',
      'hdp',
      'pendejo',
      'pendeja',
      'maricón',
      'zorra',
      'zorras',
      'perra',
      'perras',
      'rata',
      'ratas',
    ],
    'discriminatory': [
      'escoria',
      'gentuza',
      'basura humana',
      'despojo',
      'lacra',
      'plaga',
      'subhumano',
      'subhumanos',
      'apestoso',
      'apestosa',
      'repugnante',
      'repugnantes',
    ],
    'sexual': [
      'pene',
      'vagina',
      'coño',
      'polla',
      'pollas',
      'tetas',
      'tetillas',
      'culo',
      'culos',
      'follar',
      'folla',
      'follas',
      'follen',
      'joder',
      'jodido',
      'jodida',
      'sexo explícito',
      'pornografía',
      'porno',
    ],
    'drugs': [
      'coca',
      'cocaína',
      'heroína',
      'éxtasis',
      'mdma',
      'lsd',
      'marihuana',
      'porro',
      'porros',
      'speed',
      'anfeta',
      'metanfetamina',
      'ketamina',
      'crack',
    ],
    'violence': [
      'matar',
      'mátate',
      'matarte',
      'asesinar',
      'golpear',
      'apaleado',
      'apuñalar',
      'apuñalado',
      'amenaza',
      'amenazarte',
    ],
    'selfHarm': [
      'suicidio',
      'suicidarse',
      'cortarse',
      'autolesión',
      'quiero morir',
      'me quiero morir',
    ],
  };

  static const Map<String, List<String>> bullyingPatterns = {
    'threats': [
      r'te\s+voy\s+a\s+matar',
      r'voy\s+a\s+matarte',
      r'te\s+mato\b',
      r'te\s+voy\s+a\s+(pegar|golpear|dar|romper)',
      r'voy\s+a\s+encontrarte',
      r'sé\s+dónde\s+vives',
      r'te\s+voy\s+a\s+hacer\s+daño',
      r'vas\s+a\s+ver\b',
    ],
    'suicide': [
      r'suicídate',
      r'mátate',
      r'quítate\s+la\s+vida',
      r'ojalá\s+te\s+mueras',
      r'mejor\s+muerto',
      r'el\s+mundo\s+estaría\s+mejor\s+sin\s+ti',
      r'no\s+mereces\s+vivir',
    ],
    'harassment': [
      r'nadie\s+te\s+quiere',
      r'todos\s+te\s+odian',
      r'eres\s+una?\s+mierda',
      r'no\s+vales\s+nada',
      r'eres\s+patético',
      r'das\s+pena\b',
      r'eres\s+un[a]?\s+fracaso',
    ],
    'doxxing': [
      r'voy\s+a\s+publicar',
      r'voy\s+a\s+difundir',
      r'voy\s+a\s+compartir\s+(tus\s+)?(fotos|datos|información)',
      r'todos\s+van\s+a\s+saber',
      r'te\s+voy\s+a\s+arruinar\s+la\s+vida',
    ],
    'sexualHarassment': [
      r'manda(r)?\s+(fotos|nudes|desnudos)',
      r'envíame\s+(fotos|nudes)',
      r'te\s+voy\s+a\s+violar',
      r'eres\s+una?\s+(puta|zorra|perra)\b',
    ],
    'socialExclusion': [
      r'nadie\s+te\s+quiere\s+aquí',
      r'vete\s+de\s+aquí',
      r'no\s+eres\s+bienvenido',
      r'todos\s+estamos\s+mejor\s+sin\s+ti',
    ],
  };

  static const Map<String, String> wordSeverity = {
    'idiota': 'low',
    'tonto': 'low',
    'bobo': 'low',
    'pene': 'medium',
    'vagina': 'medium',
    'puto': 'high',
    'cabrón': 'high',
    'mierda': 'high',
    'matar': 'high',
    'suicidio': 'critical',
    'escoria': 'critical',
  };

  static ModerationResult moderateMessage(String text) {
    if (text.trim().isEmpty) {
      return ModerationResult(
        isAllowed: false,
        reason: 'El mensaje no puede estar vacío',
        severity: 'low',
      );
    }

    final lowerText = text.toLowerCase();
    final detectedWords = <String>[];
    final detectedPatterns = <String>[];
    String? highestSeverity;

    bannedWords.forEach((category, words) {
      for (final word in words) {
        if (lowerText.contains(word.toLowerCase())) {
          detectedWords.add(word);
          final severity = wordSeverity[word] ?? 'medium';
          if (highestSeverity == null ||
              _isMoreSevere(severity, highestSeverity!)) {
            highestSeverity = severity;
          }
        }
      }
    });

    bullyingPatterns.forEach((category, patterns) {
      for (final pattern in patterns) {
        final regex = RegExp(pattern, caseSensitive: false);
        if (regex.hasMatch(lowerText)) {
          detectedPatterns.add(category);
          highestSeverity = 'critical';
        }
      }
    });

    if (detectedWords.isNotEmpty || detectedPatterns.isNotEmpty) {
      return ModerationResult(
        isAllowed: false,
        reason: _getReason(
          detectedWords,
          detectedPatterns,
          highestSeverity ?? 'low',
        ),
        severity: highestSeverity ?? 'low',
        detectedWords: detectedWords,
        detectedPatterns: detectedPatterns,
        sanitizedMessage: null,
      );
    }

    return ModerationResult(
      isAllowed: true,
      reason: null,
      severity: 'none',
      sanitizedMessage: text.trim(),
    );
  }

  static bool _isMoreSevere(String severity1, String severity2) {
    const severityLevels = {
      'none': 0,
      'low': 1,
      'medium': 2,
      'high': 3,
      'critical': 4,
    };

    return (severityLevels[severity1] ?? 0) > (severityLevels[severity2] ?? 0);
  }

  static String _getReason(
    List<String> detectedWords,
    List<String> detectedPatterns,
    String severity,
  ) {
    if (detectedPatterns.isNotEmpty) {
      if (detectedPatterns.contains('suicide')) {
        return '⚠️ Este mensaje contiene incitación al suicidio, lo cual está estrictamente prohibido';
      }
      if (detectedPatterns.contains('threats')) {
        return '⚠️ Este mensaje contiene amenazas, lo cual no está permitido';
      }
      if (detectedPatterns.contains('sexualHarassment')) {
        return '⚠️ Este mensaje contiene acoso sexual, lo cual está prohibido';
      }
      if (detectedPatterns.contains('doxxing')) {
        return '⚠️ Este mensaje contiene amenazas de doxxing, lo cual está prohibido';
      }
      return '⚠️ Este mensaje contiene contenido de acoso o bullying';
    }

    if (severity == 'critical') {
      return '⚠️ Este mensaje contiene lenguaje extremadamente inapropiado';
    }
    if (severity == 'high') {
      return '⚠️ Este mensaje contiene lenguaje ofensivo';
    }
    if (severity == 'medium') {
      return '⚠️ Este mensaje contiene contenido inapropiado';
    }

    return '⚠️ Este mensaje contiene lenguaje no permitido';
  }
}

class ModerationResult {
  final bool isAllowed;
  final String? reason;
  final String severity;
  final List<String> detectedWords;
  final List<String> detectedPatterns;
  final String? sanitizedMessage;

  ModerationResult({
    required this.isAllowed,
    required this.reason,
    required this.severity,
    this.detectedWords = const [],
    this.detectedPatterns = const [],
    this.sanitizedMessage,
  });
}
