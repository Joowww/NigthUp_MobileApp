import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../services/api_service.dart';
import '../services/storage_service.dart';
import '../app.dart';
import 'auth_controller.dart';

class InterestSelectionController extends GetxController {
  final RxString errorMessage = ''.obs;
  final ApiService _apiService = Get.find<ApiService>();
  final StorageService _storageService = Get.find<StorageService>();

  final RxInt currentPage = 0.obs;
  final RxBool isLoading = false.obs;

  final Map<String, String> selections = {
    'MusicType': '',
    'Musician': '',
    'EventType': '',
    'ChildhoodIdol': '',
  };

  final Map<String, List<Map<String, dynamic>>> tagOptions = {
    'MusicType': [],
    'Musician': [],
    'EventType': [],
    'ChildhoodIdol': [],
  };

  final List<Map<String, String>> stepsInfo = [
    {'title': 'Tu Vibra Musical', 'subtitle': '¿Qué te hace mover?'},
    {'title': 'Artistas Top', 'subtitle': '¿Quién está en tu playlist?'},
    {'title': 'Estilo Nocturno', 'subtitle': '¿Dónde encajas mejor?'},
    {'title': 'Recuerdos', 'subtitle': '¿Quién fue tu héroe de la infancia?'},
  ];

  @override
  void onInit() {
    super.onInit();
    try {
      final authController = Get.find<AuthController>();
      final user = authController.currentUser;
      if (user != null && user.username == 'JoelMoreno') {
        _storageService.write('onboarding_complete', true);
        Future.delayed(Duration.zero, () => Get.offAll(() => const App()));
        return;
      }
    } catch (e) {}
    _loadTags();
  }

  Future<void> _loadTags() async {
    isLoading.value = true;
    errorMessage.value = '';
    bool completed = false;
    Future.delayed(const Duration(seconds: 15), () {
      if (!completed) {
        errorMessage.value =
            'No se pudo cargar. Comprueba tu conexión o reintenta.';
        isLoading.value = false;
        update();
      }
    });

    try {
      final types = ['MusicType', 'Musician', 'EventType', 'ChildhoodIdol'];
      for (final type in types) {
        try {
          final response = await _apiService.getTagsByType(type);
          if (response is List) {
            tagOptions[type] = response.map<Map<String, dynamic>>((tag) {
              return {
                'id': tag['_id']?.toString() ?? '',
                'name': tag['name']?.toString() ?? '',
                'color': tag['color']?.toString() ?? '#3b82f6',
              };
            }).toList();
          } else {
            tagOptions[type] = [];
          }
        } catch (e) {
          tagOptions[type] = [];
        }
      }
      completed = true;
      isLoading.value = false;
      update();
    } catch (e) {
      _loadFallbackTags();
      completed = true;
      isLoading.value = false;
      errorMessage.value =
          'No se pudo cargar. Comprueba tu conexión o reintenta.';
      update();
    }
  }

  void _loadFallbackTags() {
    tagOptions['MusicType'] = [
      {'id': '1', 'name': 'Techno', 'color': '#8b5cf6'},
      {'id': '2', 'name': 'House', 'color': '#3b82f6'},
      {'id': '3', 'name': 'Reggaeton', 'color': '#ef4444'},
      {'id': '4', 'name': 'Hip Hop', 'color': '#f59e0b'},
      {'id': '5', 'name': 'EDM', 'color': '#10b981'},
      {'id': '6', 'name': 'Rock', 'color': '#f97316'},
    ];
    tagOptions['Musician'] = [
      {'id': '7', 'name': 'Peggy Gou', 'color': '#8b5cf6'},
      {'id': '8', 'name': 'Bad Bunny', 'color': '#3b82f6'},
      {'id': '9', 'name': 'Fred Again..', 'color': '#ef4444'},
      {'id': '10', 'name': 'The Weeknd', 'color': '#f59e0b'},
    ];
    tagOptions['EventType'] = [
      {'id': '11', 'name': 'Discotecas', 'color': '#8b5cf6'},
      {'id': '12', 'name': 'Festival', 'color': '#3b82f6'},
      {'id': '13', 'name': 'Rave', 'color': '#ef4444'},
      {'id': '14', 'name': 'Ruta de Bares', 'color': '#f59e0b'},
    ];
    tagOptions['ChildhoodIdol'] = [
      {'id': '15', 'name': 'Spider-Man', 'color': '#8b5cf6'},
      {'id': '16', 'name': 'Messi', 'color': '#3b82f6'},
      {'id': '17', 'name': 'Hannah Montana', 'color': '#ef4444'},
      {'id': '18', 'name': 'Goku', 'color': '#f59e0b'},
    ];
    update();
  }

  void selectOption(String category, String id) {
    selections[category] = id;
    update();
  }

  void nextPage() {
    if (currentPage.value < 3) {
      currentPage.value++;
      update();
    } else {
      _submitInterests();
    }
  }

  void previousPage() {
    if (currentPage.value > 0) {
      currentPage.value--;
      update();
    }
  }

  Future<void> _submitInterests() async {
    try {
      isLoading.value = true;

      final missingSelections = selections.entries
          .where((entry) => entry.value.isEmpty)
          .toList();

      if (missingSelections.isNotEmpty) {
        isLoading.value = false;
        return;
      }

      final dataToSend = {
        'musicType': _getNameFromId('MusicType', selections['MusicType']!),
        'musician': _getNameFromId('Musician', selections['Musician']!),
        'eventType': _getNameFromId('EventType', selections['EventType']!),
        'childhoodIdol': _getNameFromId(
          'ChildhoodIdol',
          selections['ChildhoodIdol']!,
        ),
      };

      await _apiService.saveInitialInterests(dataToSend);
      await _storageService.write('onboarding_complete', true);
      Get.offAll(() => const App());
    } catch (e) {
    } finally {
      isLoading.value = false;
    }
  }

  String _getNameFromId(String category, String id) {
    try {
      final option = tagOptions[category]?.firstWhere(
        (opt) => opt['id'] == id,
        orElse: () => {'name': ''},
      );
      return option?['name'] ?? '';
    } catch (e) {
      return '';
    }
  }

  void skipOnboarding() async {
    await _storageService.write('onboarding_complete', true);
    Get.offAll(() => const App());
  }

  void reloadTags() {
    _loadTags();
  }

  String get currentCategory {
    switch (currentPage.value) {
      case 0:
        return 'MusicType';
      case 1:
        return 'Musician';
      case 2:
        return 'EventType';
      case 3:
        return 'ChildhoodIdol';
      default:
        return 'MusicType';
    }
  }

  bool isSelected(String category, String id) {
    return selections[category] == id;
  }

  Color hexToColor(String hexColor) {
    try {
      hexColor = hexColor.replaceAll("#", "");
      if (hexColor.length == 6) {
        hexColor = "FF$hexColor";
      }
      return Color(int.parse(hexColor, radix: 16));
    } catch (e) {
      return Colors.blue;
    }
  }
}
