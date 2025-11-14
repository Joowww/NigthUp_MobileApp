import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:pull_to_refresh/pull_to_refresh.dart';
import '../../../app/themes/app_colors.dart';
import '../controllers/tag_controller.dart';
import '../../../data/models/tag_model.dart';

class TagsView extends StatelessWidget {
  const TagsView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(TagsController());
    final refreshController = RefreshController();

    return Scaffold(
      body: SmartRefresher(
        controller: refreshController,
        onRefresh: () async {
          await controller.refreshTags();
          refreshController.refreshCompleted();
        },
        header: WaterDropMaterialHeader(
          backgroundColor: AppColors.neonGreen,
          color: Colors.white,
        ),
        child: CustomScrollView(
          slivers: [
            // AppBar
            SliverAppBar(
              expandedHeight: 250,
              floating: true,
              pinned: true,
              backgroundColor: AppColors.darkBackground,
              flexibleSpace: FlexibleSpaceBar(
                background: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        AppColors.neonGreen.withOpacity(0.2),
                        AppColors.neonBlue.withOpacity(0.2),
                      ],
                    ),
                  ),
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: AppColors.darkCard.withOpacity(0.5),
                          ),
                          child: const Icon(
                            Icons.label,
                            size: 50,
                            color: AppColors.neonGreen,
                          ),
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'Tags',
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                            fontFamily: 'Poppins',
                          ),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          margin: const EdgeInsets.symmetric(horizontal: 20),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppColors.darkCard.withOpacity(0.7),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Text(
                            'Los tags ayudan a categorizar eventos y negocios. Úsalos para encontrar contenido específico más fácilmente.',
                            style: TextStyle(
                              fontSize: 12,
                              color: AppColors.textSecondary,
                              fontFamily: 'Poppins',
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            
            // Search bar
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: _buildSearchBar(controller),
              ),
            ),
            
            // Lista de tags en grid
            Obx(() {
              if (controller.isLoading.value && controller.tags.isEmpty) {
                return const SliverFillRemaining(
                  child: Center(
                    child: CircularProgressIndicator(
                      color: AppColors.neonGreen,
                    ),
                  ),
                );
              }
              
              if (controller.filteredTags.isEmpty) {
                return SliverFillRemaining(
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.search_off,
                          size: 80,
                          color: AppColors.textSecondary.withOpacity(0.5),
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'No se encontraron tags',
                          style: TextStyle(
                            fontSize: 18,
                            color: AppColors.textSecondary,
                            fontFamily: 'Poppins',
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }
              
              return SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                sliver: SliverGrid(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    mainAxisSpacing: 16,
                    crossAxisSpacing: 16,
                    childAspectRatio: 1.2,
                  ),
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final tag = controller.filteredTags[index];
                      return _buildTagCard(tag);
                    },
                    childCount: controller.filteredTags.length,
                  ),
                ),
              );
            }),
            
            const SliverToBoxAdapter(
              child: SizedBox(height: 20),
            ),
          ],
        ),
      ),
      floatingActionButton: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          FloatingActionButton.extended(
            heroTag: "info",
            onPressed: () => _showTagInfoDialog(),
            backgroundColor: AppColors.neonBlue,
            label: const Text(
              '¿Qué son los Tags?',
              style: TextStyle(color: Colors.white, fontFamily: 'Poppins'),
            ),
            icon: const Icon(Icons.help_outline, color: Colors.white),
          ),
          const SizedBox(width: 16),
          FloatingActionButton(
            heroTag: "add",
            onPressed: () => _showAddTagDialog(controller),
            backgroundColor: AppColors.neonGreen,
            child: const Icon(Icons.add, color: Colors.white),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar(TagsController controller) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.darkCard,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.neonGreen.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: TextField(
        onChanged: controller.searchTags,
        style: const TextStyle(
          color: AppColors.textPrimary,
          fontFamily: 'Poppins',
        ),
        decoration: const InputDecoration(
          hintText: 'Buscar tags',
          hintStyle: TextStyle(
            color: AppColors.textHint,
            fontFamily: 'Poppins',
          ),
          prefixIcon: Icon(
            Icons.search,
            color: AppColors.neonGreen,
          ),
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(
            horizontal: 20,
            vertical: 16,
          ),
        ),
      ),
    );
  }

  Widget _buildTagCard(TagModel tag) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.darkCard,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: tag.colorValue.withOpacity(0.3),
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: tag.colorValue.withOpacity(0.2),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () {
            _showTagDetail(tag);
          },
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: tag.colorValue.withOpacity(0.2),
                  ),
                  child: Icon(
                    Icons.label,
                    color: tag.colorValue,
                    size: 30,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  tag.name,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                    fontFamily: 'Poppins',
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                if (tag.description != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    tag.description!,
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppColors.textSecondary,
                      fontFamily: 'Poppins',
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showTagDetail(TagModel tag) {
    Get.dialog(
      AlertDialog(
        backgroundColor: AppColors.darkCard,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: Row(
          children: [
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: tag.colorValue.withOpacity(0.2),
              ),
              child: Icon(
                Icons.label,
                color: tag.colorValue,
                size: 26,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                tag.name,
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontFamily: 'Poppins',
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (tag.description != null) ...[
              const Text(
                'Descripción:',
                style: TextStyle(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                  fontFamily: 'Poppins',
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                tag.description!,
                style: const TextStyle(
                  fontSize: 14,
                  color: AppColors.textPrimary,
                  fontFamily: 'Poppins',
                ),
              ),
              const SizedBox(height: 16),
            ],
            const Text(
              'Color:',
              style: TextStyle(
                fontSize: 12,
                color: AppColors.textSecondary,
                fontFamily: 'Poppins',
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Container(
                  width: 30,
                  height: 30,
                  decoration: BoxDecoration(
                    color: tag.colorValue,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Colors.white.withOpacity(0.2),
                      width: 2,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  tag.color,
                  style: const TextStyle(
                    fontSize: 14,
                    color: AppColors.textPrimary,
                    fontFamily: 'Poppins',
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text(
              'Cerrar',
              style: TextStyle(
                color: AppColors.neonGreen,
                fontFamily: 'Poppins',
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showTagInfoDialog() {
    Get.dialog(
      AlertDialog(
        backgroundColor: AppColors.darkCard,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: Row(
          children: [
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.neonBlue.withOpacity(0.2),
              ),
              child: const Icon(
                Icons.label,
                color: AppColors.neonBlue,
                size: 26,
              ),
            ),
            const SizedBox(width: 16),
            const Text(
              '¿Qué son los Tags?',
              style: TextStyle(
                color: AppColors.textPrimary,
                fontFamily: 'Poppins',
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Los tags son etiquetas que permiten:',
              style: TextStyle(
                fontSize: 16,
                color: AppColors.textPrimary,
                fontFamily: 'Poppins',
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 16),
            _buildInfoItem(
              icon: Icons.search,
              text: 'Encontrar eventos y negocios por categorías específicas',
            ),
            _buildInfoItem(
              icon: Icons.filter_list,
              text: 'Filtrar contenido según tus preferencias',
            ),
            _buildInfoItem(
              icon: Icons.star,
              text: 'Descubrir contenido similar a tus gustos',
            ),
            _buildInfoItem(
              icon: Icons.group,
              text: 'Conectar con personas con intereses similares',
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.neonBlue.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Text(
                '💡 Ejemplos: #Música, #Gastronomía, #Arte, #Deportes, #Tecnología',
                style: TextStyle(
                  fontSize: 14,
                  color: AppColors.textPrimary,
                  fontFamily: 'Poppins',
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text(
              'Entendido',
              style: TextStyle(
                color: AppColors.neonBlue,
                fontFamily: 'Poppins',
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoItem({required IconData icon, required String text}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(
            icon,
            color: AppColors.neonGreen,
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                fontSize: 14,
                color: AppColors.textSecondary,
                fontFamily: 'Poppins',
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showAddTagDialog(TagsController controller) {
    final TextEditingController nameController = TextEditingController();
    final TextEditingController descriptionController = TextEditingController();
    final RxString selectedColor = '#FF6B6B'.obs;
    
    final availableColors = [
      '#FF6B6B', '#4ECDC4', '#45B7D1', '#96CEB4', '#FFEAA7',
      '#DDA0DD', '#98D8C8', '#F7DC6F', '#BB8FCE', '#85C1E9',
    ];

    Get.dialog(
      AlertDialog(
        backgroundColor: AppColors.darkCard,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: const Text(
          'Crear Nuevo Tag',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.bold,
            fontFamily: 'Poppins',
          ),
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                style: const TextStyle(color: AppColors.textPrimary),
                decoration: InputDecoration(
                  labelText: 'Nombre del tag',
                  labelStyle: const TextStyle(color: AppColors.textSecondary),
                  filled: true,
                  fillColor: AppColors.darkInput,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: AppColors.neonGreen),
                  ),
                  prefixIcon: const Icon(Icons.tag, color: AppColors.neonGreen),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: descriptionController,
                style: const TextStyle(color: AppColors.textPrimary),
                maxLines: 3,
                decoration: InputDecoration(
                  labelText: 'Descripción (opcional)',
                  labelStyle: const TextStyle(color: AppColors.textSecondary),
                  filled: true,
                  fillColor: AppColors.darkInput,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: AppColors.neonGreen),
                  ),
                  prefixIcon: const Icon(Icons.description, color: AppColors.neonGreen),
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'Color del tag:',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w600,
                  fontFamily: 'Poppins',
                ),
              ),
              const SizedBox(height: 12),
              Obx(() => Wrap(
                spacing: 12,
                runSpacing: 12,
                children: availableColors.map((color) {
                  final isSelected = selectedColor.value == color;
                  return GestureDetector(
                    onTap: () => selectedColor.value = color,
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: Color(int.parse(color.substring(1, 7), radix: 16) + 0xFF000000),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: isSelected ? Colors.white : Colors.transparent,
                          width: 3,
                        ),
                      ),
                      child: isSelected
                          ? const Icon(Icons.check, color: Colors.white, size: 20)
                          : null,
                    ),
                  );
                }).toList(),
              )),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text(
              'Cancelar',
              style: TextStyle(color: AppColors.textSecondary),
            ),
          ),
          Container(
            decoration: BoxDecoration(
              gradient: AppColors.secondaryGradient,
              borderRadius: BorderRadius.circular(8),
            ),
            child: TextButton(
              onPressed: () {
                if (nameController.text.isNotEmpty) {
                  controller.createNewTag(
                    nameController.text,
                    selectedColor.value,
                    descriptionController.text.isNotEmpty ? descriptionController.text : null,
                  );
                  Get.back();
                } else {
                  Get.snackbar(
                    'Error',
                    'El nombre del tag es requerido',
                    snackPosition: SnackPosition.BOTTOM,
                    backgroundColor: Colors.red,
                    colorText: Colors.white,
                  );
                }
              },
              child: const Text(
                'Crear Tag',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
    );
  }
}