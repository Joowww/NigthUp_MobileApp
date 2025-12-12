import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/interestSelection_controller.dart';
import '../controllers/auth_controller.dart'; // Importar AuthController
import '../theme/colors.dart';
import '../widgets/glass_card.dart';
import '../widgets/gradient_button.dart';
import '../screens/home_feed.dart';

class InterestSelectionScreen extends StatefulWidget {
  const InterestSelectionScreen({super.key});

  @override
  State<InterestSelectionScreen> createState() => _InterestSelectionScreenState();
}

class _InterestSelectionScreenState extends State<InterestSelectionScreen> {
  // Usa Get.find para obtener la instancia global creada por el binding
  late final InterestSelectionController _controller;

  @override
  void initState() {
    super.initState();
    
    // SOLUCIÓN DIRECTA - siempre asegura que el controller existe
    if (Get.isRegistered<InterestSelectionController>()) {
      _controller = Get.find<InterestSelectionController>();
    } else {
      _controller = Get.put(InterestSelectionController());
    }
    
    print('✅ InterestSelectionController inicializado correctamente');
  }

  @override
  Widget build(BuildContext context) {
    print('🟣 [InterestScreen] build called. isLoading: ${_controller.isLoading.value}, currentPage: ${_controller.currentPage.value}');
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          _buildBackgroundGradients(),
          SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 40),
              child: Column(
                children: [
                  _buildHeader(),
                  const SizedBox(height: 30),
                  _buildContent(),
                  const SizedBox(height: 30),
                  // Botón temporal para limpiar sesión y volver a login
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                    ),
                    onPressed: () async {
                      await Get.find<AuthController>().logout();
                      // Opcional: recargar la app o navegar a login
                      Get.offAllNamed('/');
                    },
                    child: const Text('Resetear sesión (dev)', style: TextStyle(color: Colors.white)),
                  ),
                ],
              ),
            ),
          ),
          if (_controller.isLoading.value) _buildLoadingOverlay(),
        ],
      ),
    );
  }

  Widget _buildLoadingOverlay() {
    print('🟣 [InterestScreen] _buildLoadingOverlay called. isLoading: ${_controller.isLoading.value}');
    return Obx(() => Container(
      color: Colors.black54,
      child: Center(
        child: _controller.errorMessage.value.isNotEmpty
            ? Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    _controller.errorMessage.value,
                    style: const TextStyle(color: Colors.redAccent),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  ElevatedButton(
                    onPressed: () {
                      _controller.errorMessage.value = '';
                      _controller.reloadTags();
                    },
                    child: const Text('Reintentar'),
                  ),
                  const SizedBox(height: 8),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                    onPressed: () async {
                      await Get.find<AuthController>().logout();
                      Get.offAllNamed('/');
                    },
                    child: const Text('Forzar logout'),
                  ),
                ],
              )
            : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(AppColors.neonPink),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    _controller.isLoading.value ? 'Cargando opciones...' : 'Procesando...',
                    style: const TextStyle(color: Colors.white),
                  ),
                ],
              ),
      ),
    ));
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
          boxShadow: [
            BoxShadow(
              color: color,
              blurRadius: 8,
              spreadRadius: 2,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        // Indicador de progreso
        Obx(() => Row(
          children: List.generate(4, (index) => _buildStepDot(index, _controller.currentPage.value)),
        )),
        // Botón Skip
        TextButton(
          onPressed: () {
            print('🎯 Skip button pressed');
            _controller.skipOnboarding();
          },
          child: const Text(
            'Saltar',
            style: TextStyle(
              color: Colors.grey,
              fontFamily: 'Poppins',
              fontSize: 16,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStepDot(int index, int currentPage) {
    final isActive = index <= currentPage;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      margin: const EdgeInsets.only(right: 8),
      height: 4,
      width: isActive ? 25 : 15,
      decoration: BoxDecoration(
        color: isActive ? AppColors.neonGreen : Colors.grey[800],
        borderRadius: BorderRadius.circular(2),
      ),
    );
  }

  Widget _buildContent() {
    return GlassCard(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            _buildStepTitle(),
            const SizedBox(height: 30),
            _buildOptionsGrid(),
            const SizedBox(height: 30),
            _buildNavigationButtons(),
          ],
        ),
      ),
    );
  }

  Widget _buildStepTitle() {
    return Obx(() {
      final stepInfo = _controller.stepsInfo[_controller.currentPage.value];
      
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            stepInfo['title']!,
            style: const TextStyle(
              color: AppColors.neonBlue,
              fontSize: 14,
              fontWeight: FontWeight.bold,
              fontFamily: 'Poppins',
            ),
          ),
          const SizedBox(height: 5),
          Text(
            stepInfo['subtitle']!,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 28,
              fontWeight: FontWeight.bold,
              fontFamily: 'Poppins',
            ),
          ),
        ],
      );
    });
  }

  Widget _buildOptionsGrid() {
    return Obx(() {
      final category = _controller.currentCategory;
      final options = _controller.tagOptions[category] ?? [];
      print('🟣 [InterestScreen] Building grid for $category with ${options.length} options. isLoading: ${_controller.isLoading.value}');
      if (_controller.isLoading.value && options.isEmpty) {
        print('🟣 [InterestScreen] Showing loading grid');
        return _buildLoadingGrid();
      }
      if (options.isEmpty) {
        print('🟣 [InterestScreen] No options, showing empty state');
        return _buildEmptyState();
      }
      return SizedBox(
        height: 400,
        child: GridView.builder(
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            childAspectRatio: 2.5,
            crossAxisSpacing: 15,
            mainAxisSpacing: 15,
          ),
          itemCount: options.length,
          itemBuilder: (context, index) {
            final option = options[index];
            final isSelected = _controller.isSelected(category, option['id']);
            print('🟣 [InterestScreen] Option $index: ${option['name']} - selected: $isSelected');
            return _buildOptionCard(
              option['name'],
              option['color'],
              isSelected,
              () {
                print('🟣 [InterestScreen] Tapping option: ${option['name']}');
                _controller.selectOption(category, option['id']);
              },
            );
          },
        ),
      );
    });
  }

  // En interestSelection_screen.dart - CORREGIR solo este método
Widget _buildEmptyState() {
  return Container(
    height: 400,
    alignment: Alignment.center,
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.error_outline, color: Colors.grey[400], size: 48),
        const SizedBox(height: 16),
        Text(
          'No hay opciones disponibles',
          style: TextStyle(color: Colors.grey[400]),
        ),
        const SizedBox(height: 8),
        TextButton(
          onPressed: () => _controller.reloadTags(), // 👈 CAMBIAR A reloadTags
          child: const Text('Reintentar'),
        ),
      ],
    ),
  );
}

  Widget _buildLoadingGrid() {
    return SizedBox(
      height: 400,
      child: GridView.builder(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          childAspectRatio: 2.5,
          crossAxisSpacing: 15,
          mainAxisSpacing: 15,
        ),
        itemCount: 6,
        itemBuilder: (context, index) {
          return Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              color: Colors.grey[800]!.withOpacity(0.3),
            ),
          );
        },
      ),
    );
  }

  Widget _buildOptionCard(String text, String color, bool isSelected, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        decoration: BoxDecoration(
          color: isSelected 
              ? _controller.hexToColor(color).withOpacity(0.2)
              : const Color(0xFF1A1A1A),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? _controller.hexToColor(color) : Colors.white10,
            width: isSelected ? 2 : 1,
          ),
          boxShadow: isSelected ? [
            BoxShadow(
              color: _controller.hexToColor(color).withOpacity(0.3),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ] : [],
        ),
        child: Center(
          child: Text(
            text,
            style: TextStyle(
              color: isSelected ? Colors.white : Colors.grey,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              fontFamily: 'Poppins',
              fontSize: 15,
            ),
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }

  Widget _buildNavigationButtons() {
    return Obx(() {
      final category = _controller.currentCategory;
      final hasSelection = _controller.selections[category]?.isNotEmpty ?? false;
      final isLastPage = _controller.currentPage.value == 3;
      return Row(
        children: [
          // Botón Atrás
          _controller.currentPage.value > 0
              ? IconButton(
                  icon: const Icon(Icons.arrow_back, color: Colors.white, size: 28),
                  onPressed: () {
                    _controller.previousPage();
                  },
                )
              : const SizedBox(width: 48),
          const Spacer(),
          // Botón Siguiente/Finalizar
          SizedBox(
            width: 120,
            child: GradientButton(
              onPressed: hasSelection && !_controller.isLoading.value
                  ? () {
                      _controller.nextPage();
                    }
                  : null,
              text: isLastPage ? 'Finalizar' : 'Siguiente',
              isLoading: _controller.isLoading.value,
            ),
          ),
        ],
      );
    });
  // IMPORTANTE: Navega SIEMPRE así para que el binding funcione y el controlador sea único:
  // Get.to(() => InterestSelectionScreen(), binding: InterestBinding());
  // O en tu sistema de rutas:
  // GetPage(name: '/interests', page: () => InterestSelectionScreen(), binding: InterestBinding())
  }
}