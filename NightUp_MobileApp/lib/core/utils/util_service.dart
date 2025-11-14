import 'dart:convert';
import 'package:intl/intl.dart';

class UtilService {
  static final UtilService _instance = UtilService._internal();
  factory UtilService() => _instance;
  UtilService._internal();

  // Format date for display
  String formatDate(DateTime date, {String pattern = 'dd/MM/yyyy'}) {
    return DateFormat(pattern, 'es').format(date);
  }

  // Format datetime for display
  String formatDateTime(DateTime date, {String pattern = 'dd/MM/yyyy HH:mm'}) {
    return DateFormat(pattern, 'es').format(date);
  }

  // Format time for display
  String formatTime(DateTime date, {String pattern = 'HH:mm'}) {
    return DateFormat(pattern).format(date);
  }

  // Get time ago string
  String getTimeAgo(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays > 7) {
      return formatDate(date);
    } else if (difference.inDays > 0) {
      return 'Hace ${difference.inDays} día${difference.inDays > 1 ? 's' : ''}';
    } else if (difference.inHours > 0) {
      return 'Hace ${difference.inHours} hora${difference.inHours > 1 ? 's' : ''}';
    } else if (difference.inMinutes > 0) {
      return 'Hace ${difference.inMinutes} minuto${difference.inMinutes > 1 ? 's' : ''}';
    } else {
      return 'Ahora';
    }
  }

  // Capitalize first letter
  String capitalize(String text) {
    if (text.isEmpty) return text;
    return text[0].toUpperCase() + text.substring(1).toLowerCase();
  }

  // Convert to title case
  String toTitleCase(String text) {
    return text.split(' ').map((word) => capitalize(word)).join(' ');
  }

  // Format currency
  String formatCurrency(double amount, {String symbol = '€'}) {
    final formatter = NumberFormat('#,##0.00', 'es');
    return '$symbol${formatter.format(amount)}';
  }

  // Format percentage
  String formatPercentage(double value) {
    return '${(value * 100).toStringAsFixed(1)}%';
  }

  // Truncate text
  String truncateText(String text, int maxLength, {String suffix = '...'}) {
    if (text.length <= maxLength) return text;
    return text.substring(0, maxLength - suffix.length) + suffix;
  }

  // Generate initials from name
  String getInitials(String name) {
    final words = name.trim().split(' ');
    if (words.isEmpty) return '';
    if (words.length == 1) return words[0][0].toUpperCase();
    return '${words.first[0].toUpperCase()}${words.last[0].toUpperCase()}';
  }

  // Check if email is valid
  bool isValidEmail(String email) {
    return RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$')
        .hasMatch(email);
  }

  // Check if URL is valid
  bool isValidUrl(String url) {
    return Uri.tryParse(url)?.hasAbsolutePath ?? false;
  }

  // Generate random string
  String generateRandomString(int length) {
    const chars = 'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    return List.generate(length, (index) => chars[(DateTime.now().millisecondsSinceEpoch + index) % chars.length])
        .join();
  }

  // Convert bytes to human readable format
  String formatBytes(int bytes) {
    if (bytes <= 0) return '0 B';
    const suffixes = ['B', 'KB', 'MB', 'GB', 'TB'];
    var i = (bytes.bitLength - 1) ~/ 10;
    return '${(bytes / (1 << (i * 10))).toStringAsFixed(1)} ${suffixes[i]}';
  }

  // Get platform info
  String getPlatform() {
    // This would need platform-specific imports
    return 'Mobile';
  }

  // Deep copy of map
  Map<String, dynamic> deepCopyMap(Map<String, dynamic> original) {
    return json.decode(json.encode(original));
  }

  // Check if string is numeric
  bool isNumeric(String str) {
    return double.tryParse(str) != null;
  }

  // Remove accents from text
  String removeAccents(String text) {
    const withAccents = 'àáäâèéëêìíïîòóöôùúüûñç';
    const withoutAccents = 'aaaaeeeeiiiioooouuuunc';
    
    String result = text.toLowerCase();
    for (int i = 0; i < withAccents.length; i++) {
      result = result.replaceAll(withAccents[i], withoutAccents[i]);
    }
    return result;
  }

  // Get file extension from filename
  String getFileExtension(String filename) {
    return filename.split('.').last.toLowerCase();
  }

  // Check if file is image
  bool isImageFile(String filename) {
    const imageExtensions = ['jpg', 'jpeg', 'png', 'gif', 'bmp', 'webp'];
    return imageExtensions.contains(getFileExtension(filename));
  }

  // Generate color from string
  int getColorFromString(String text) {
    int hash = 0;
    for (int i = 0; i < text.length; i++) {
      hash = text.codeUnitAt(i) + ((hash << 5) - hash);
    }
    return (hash & 0xFFFFFF) | 0xFF000000;
  }
}