// interestSelection_controller.dart - COMPLETO Y CORREGIDO
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../services/api_service.dart';
import '../services/storage_service.dart';
import '../app.dart'; // Asegúrate de que la ruta sea correcta
import 'auth_controller.dart';

class InterestSelectionController extends GetxController {
  final RxString errorMessage = ''.obs;
  final ApiService _apiService = Get.find<ApiService>();
  final StorageService _storageService = Get.find<StorageService>();

  // PageController removed: navigation is now managed by currentPage only
  final RxInt currentPage = 0.obs;
  final RxBool isLoading = false.obs;

  // Almacena las selecciones por tipo
  final Map<String, String> selections = {
    'MusicType': '',
    'Musician': '',
    'EventType': '',
    'ChildhoodIdol': '',
  };

  // Opciones cargadas desde la API
  final Map<String, List<Map<String, dynamic>>> tagOptions = {
    'MusicType': [],
    'Musician': [],
    'EventType': [],
    'ChildhoodIdol': [],
  };

  // Información de cada paso
  final List<Map<String, String>> stepsInfo = [
    {'title': 'Tu Vibra Musical', 'subtitle': '¿Qué te hace mover?'},
    {'title': 'Artistas Top', 'subtitle': '¿Quién está en tu playlist?'},
    {'title': 'Estilo Nocturno', 'subtitle': '¿Dónde encajas mejor?'},
    {'title': 'Recuerdos', 'subtitle': '¿Quién fue tu héroe de la infancia?'},
  ];

  @override
  void onInit() {
    super.onInit();
    print('🟢 [InterestController] onInit called');
    // Si el usuario es JoelMoreno, saltar onboarding automáticamente
    try {
      final authController = Get.find<AuthController>();
      final user = authController.currentUser;
      if (user != null && user.username == 'JoelMoreno') {
        print(
          '🟢 [InterestController] Usuario JoelMoreno detectado, saltando onboarding',
        );
        _storageService.write('onboarding_complete', true);
        Future.delayed(Duration.zero, () => Get.offAll(() => const App()));
        return;
      }
    } catch (e) {
      print('Error comprobando usuario para skip onboarding: $e');
    }
    _loadTags();
  }

  // Cargar tags desde la API - CORREGIDO
  Future<void> _loadTags() async {
    isLoading.value = true;
    errorMessage.value = '';
    bool completed = false;
    Future timeout = Future.delayed(const Duration(seconds: 15), () {
      if (!completed) {
        errorMessage.value =
            'No se pudo cargar. Comprueba tu conexión o reintenta.';
        isLoading.value = false;
        update();
      }
    });
    try {
      print('🟢 [InterestController] _loadTags called');
      final types = ['MusicType', 'Musician', 'EventType', 'ChildhoodIdol'];
      for (final type in types) {
        try {
          print('🟢 [InterestController] Requesting tags for $type');
          final response = await _apiService.getTagsByType(type);
          print('🟢 [InterestController] Response for $type: $response');
          if (response is List) {
            tagOptions[type] = response.map<Map<String, dynamic>>((tag) {
              print('🟢 [InterestController] Mapping tag: $tag');
              return {
                'id': tag['_id']?.toString() ?? '',
                'name': tag['name']?.toString() ?? '',
                'color': tag['color']?.toString() ?? '#3b82f6',
              };
            }).toList();
          } else {
            print(
              '🔴 [InterestController] Unexpected response format for $type: $response',
            );
            tagOptions[type] = [];
          }
        } catch (e) {
          print('🔴 [InterestController] Error loading tags for $type: $e');
          tagOptions[type] = [];
        }
      }
      print('🟢 [InterestController] All tags loaded successfully');
      print('🟢 [InterestController] Tags summary:');
      tagOptions.forEach((key, value) {
        print('   $key: ${value.length} items');
      });
      completed = true;
      isLoading.value = false;
      update();
    } catch (e) {
      print('🔴 [InterestController] Error loading tags: $e');
      _loadFallbackTags();
      completed = true;
      isLoading.value = false;
      errorMessage.value =
          'No se pudo cargar. Comprueba tu conexión o reintenta.';
      update();
    }
  }

  // Datos de fallback - CORREGIDO
  void _loadFallbackTags() {
    print('🔄 Loading fallback tags...');

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
      {'id': '11', 'name': 'Clubbing', 'color': '#8b5cf6'},
      {'id': '12', 'name': 'Festival', 'color': '#3b82f6'},
      {'id': '13', 'name': 'Rave', 'color': '#ef4444'},
      {'id': '14', 'name': 'Bar Crawl', 'color': '#f59e0b'},
    ];

    tagOptions['ChildhoodIdol'] = [
      {'id': '15', 'name': 'Spider-Man', 'color': '#8b5cf6'},
      {'id': '16', 'name': 'Messi', 'color': '#3b82f6'},
      {'id': '17', 'name': 'Hannah Montana', 'color': '#ef4444'},
      {'id': '18', 'name': 'Goku', 'color': '#f59e0b'},
    ];

    update(); // 👈 AÑADIR ESTO
  }

  // Seleccionar una opción - CORREGIDO
  void selectOption(String category, String id) {
    print('🟢 [InterestController] Selecting $category: $id');
    selections[category] = id;
    update();
  }

  // Navegar a la siguiente página - CORREGIDO
  void nextPage() {
    print(
      '🟢 [InterestController] nextPage called. currentPage: ${currentPage.value}',
    );
    if (currentPage.value < 3) {
      print('🟢 [InterestController] Moving to page ${currentPage.value + 1}');
      currentPage.value++;
      update();
    } else {
      print(
        '🟢 [InterestController] Final page reached, submitting interests...',
      );
      _submitInterests();
    }
  }

  // Navegar a la página anterior - AÑADIR ESTE MÉTODO
  void previousPage() {
    if (currentPage.value > 0) {
      print('⬅️ Moving to page ${currentPage.value - 1}');
      currentPage.value--;
      update();
    }
  }

  // Enviar intereses al backend - CORREGIDO
  Future<void> _submitInterests() async {
    try {
      isLoading.value = true;
      print('🟢 [InterestController] _submitInterests called');
      // Verificar que todas las selecciones estén completas
      final missingSelections = selections.entries
          .where((entry) => entry.value.isEmpty)
          .toList();
      if (missingSelections.isNotEmpty) {
        print('🔴 [InterestController] Missing selections: $missingSelections');
        Get.snackbar(
          'Error',
          'Por favor completa todas las selecciones',
          backgroundColor: Colors.red,
          colorText: Colors.white,
        );
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
      print('🟢 [InterestController] Enviando intereses: $dataToSend');
      await _apiService.saveInitialInterests(dataToSend);
      await _storageService.write('onboarding_complete', true);
      print('🟢 [InterestController] Intereses guardados exitosamente');
      Get.offAll(() => const App());
    } catch (e) {
      print('🔴 [InterestController] Error submitting interests: $e');
      Get.snackbar(
        'Error',
        'Error al guardar intereses: $e',
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    } finally {
      print(
        '🟢 [InterestController] _submitInterests finally. Setting isLoading to false',
      );
      isLoading.value = false;
    }
  }

  // Helper para obtener el nombre desde el ID - CORREGIDO
  String _getNameFromId(String category, String id) {
    try {
      final option = tagOptions[category]?.firstWhere(
        (opt) => opt['id'] == id,
        orElse: () => {'name': ''},
      );
      return option?['name'] ?? '';
    } catch (e) {
      print('❌ Error getting name for $category:$id: $e');
      return '';
    }
  }

  // Saltar onboarding - CORREGIDO
  void skipOnboarding() async {
    print('🟢 [InterestController] skipOnboarding called');
    await _storageService.write('onboarding_complete', true);
    Get.offAll(() => const App());
  }

  // Método para recargar tags - AÑADIR ESTE MÉTODO
  void reloadTags() {
    print('🟢 [InterestController] reloadTags called');
    _loadTags();
  }

  // Obtener la categoría actual basada en la página
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

  // Verificar si una opción está seleccionada
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
      print('❌ Error converting color $hexColor: $e');
      return Colors.blue; // Color por defecto
    }
  }
}
