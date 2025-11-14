import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:pull_to_refresh/pull_to_refresh.dart';
import '../../../app/themes/app_colors.dart';
import '../controllers/interests_controller.dart';
import '../../../data/models/interest_model.dart';

class InterestsView extends StatelessWidget {
  const InterestsView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(InterestsController());
    final refreshController = RefreshController();

    return Scaffold(
      body: SmartRefresher(
        controller: refreshController,
        onRefresh: () async {
          await controller.refreshData();
          refreshController.refreshCompleted();
        },
        header: WaterDropMaterialHeader(
          backgroundColor: AppColors.neonPurple,
          color: Colors.white,
        ),
        child: CustomScrollView(
          slivers: [
            // AppBar
            SliverAppBar(
              expandedHeight: 200,
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
                        AppColors.neonPurple.withOpacity(0.2),
                        AppColors.neonPink.withOpacity(0.2),
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
                            Icons.interests,
                            size: 50,
                            color: AppColors.neonPurple,
                          ),
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'Intereses',
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                            fontFamily: 'Poppins',
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            
            // Mis intereses
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 4,
                          height: 20,
                          decoration: BoxDecoration(
                            gradient: AppColors.primaryGradient,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                        const SizedBox(width: 12),
                        const Text(
                          'Mis intereses',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                            fontFamily: 'Poppins',
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Obx(() {
                      if (controller.userInterests.isEmpty) {
                        return Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: AppColors.darkCard,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: const Center(
                            child: Text(
                              'Aún no has añadido intereses',
                              style: TextStyle(
                                color: AppColors.textSecondary,
                                fontFamily: 'Poppins',
                              ),
                            ),
                          ),
                        );
                      }
                      
                      return Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: controller.userInterests.map((interest) {
                          return _buildInterestChip(interest, controller, true);
                        }).toList(),
                      );
                    }),
                  ],
                ),
              ),
            ),
            
            // Todos los intereses
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 4,
                          height: 20,
                          decoration: BoxDecoration(
                            gradient: AppColors.secondaryGradient,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                        const SizedBox(width: 12),
                        const Text(
                          'Todos los intereses',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                            fontFamily: 'Poppins',
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            
            // Lista de intereses
            Obx(() {
              if (controller.isLoading.value && controller.allInterests.isEmpty) {
                return const SliverFillRemaining(
                  child: Center(
                    child: CircularProgressIndicator(
                      color: AppColors.neonPurple,
                    ),
                  ),
                );
              }
              
              return SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final interest = controller.allInterests[index];
                      final isAdded = controller.isInterestAdded(interest.id);
                      return _buildInterestCard(interest, controller, isAdded);
                    },
                    childCount: controller.allInterests.length,
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
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddInterestDialog(controller),
        backgroundColor: AppColors.neonPurple,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildInterestChip(
    InterestModel interest,
    InterestsController controller,
    bool isAdded,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        gradient: isAdded ? AppColors.primaryGradient : null,
        color: isAdded ? null : AppColors.darkCard,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isAdded ? Colors.transparent : AppColors.neonPurple.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isAdded ? Icons.check_circle : Icons.add_circle_outline,
            color: isAdded ? Colors.white : AppColors.neonPurple,
            size: 18,
          ),
          const SizedBox(width: 8),
          Text(
            interest.name,
            style: TextStyle(
              color: isAdded ? Colors.white : AppColors.textPrimary,
              fontWeight: FontWeight.w600,
              fontFamily: 'Poppins',
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInterestCard(
    InterestModel interest,
    InterestsController controller,
    bool isAdded,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppColors.darkCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isAdded 
              ? AppColors.neonPurple.withOpacity(0.5)
              : AppColors.textHint.withOpacity(0.2),
          width: isAdded ? 2 : 1,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => controller.toggleInterest(interest),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: isAdded ? AppColors.primaryGradient : null,
                    color: isAdded ? null : AppColors.darkInput,
                  ),
                  child: Icon(
                    isAdded ? Icons.check : Icons.interests,
                    color: isAdded ? Colors.white : AppColors.neonPurple,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        interest.name,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                          fontFamily: 'Poppins',
                        ),
                      ),
                      if (interest.description != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          interest.description!,
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.textSecondary,
                            fontFamily: 'Poppins',
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: isAdded 
                        ? AppColors.neonPurple.withOpacity(0.2)
                        : AppColors.darkInput,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    isAdded ? Icons.remove : Icons.add,
                    color: isAdded ? AppColors.neonPurple : AppColors.textSecondary,
                    size: 20,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showAddInterestDialog(InterestsController controller) {
    final TextEditingController nameController = TextEditingController();
    final TextEditingController descriptionController = TextEditingController();

    Get.dialog(
      AlertDialog(
        backgroundColor: AppColors.darkCard,
        title: Text(
          'Añadir Nuevo Interés',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.bold,
            fontFamily: 'Poppins',
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              style: TextStyle(color: AppColors.textPrimary),
              decoration: InputDecoration(
                labelText: 'Nombre del interés',
                labelStyle: TextStyle(color: AppColors.textSecondary),
                filled: true,
                fillColor: AppColors.darkInput,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: AppColors.neonPurple),
                ),
              ),
            ),
            SizedBox(height: 16),
            TextField(
              controller: descriptionController,
              style: TextStyle(color: AppColors.textPrimary),
              maxLines: 3,
              decoration: InputDecoration(
                labelText: 'Descripción (opcional)',
                labelStyle: TextStyle(color: AppColors.textSecondary),
                filled: true,
                fillColor: AppColors.darkInput,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: AppColors.neonPurple),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: Text(
              'Cancelar',
              style: TextStyle(color: AppColors.textSecondary),
            ),
          ),
          Container(
            decoration: BoxDecoration(
              gradient: AppColors.primaryGradient,
              borderRadius: BorderRadius.circular(8),
            ),
            child: TextButton(
              onPressed: () {
                if (nameController.text.isNotEmpty) {
                  controller.createNewInterest(
                    nameController.text,
                    descriptionController.text.isNotEmpty ? descriptionController.text : null,
                  );
                  Get.back();
                } else {
                  Get.snackbar(
                    'Error',
                    'El nombre del interés es requerido',
                    snackPosition: SnackPosition.BOTTOM,
                    backgroundColor: Colors.red,
                    colorText: Colors.white,
                  );
                }
              },
              child: Text(
                'Añadir',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
    );
  }
}