import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:pull_to_refresh/pull_to_refresh.dart';
import '../../../app/themes/app_colors.dart';
import '../controllers/business_controller.dart';
import '../../../data/models/business_model.dart';
import 'business_detail_view.dart';

class BusinessView extends StatelessWidget {
  const BusinessView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(BusinessController());
    final refreshController = RefreshController();

    return Scaffold(
      body: SmartRefresher(
        controller: refreshController,
        onRefresh: () async {
          await controller.refreshBusinesses();
          refreshController.refreshCompleted();
        },
        header: WaterDropMaterialHeader(
          backgroundColor: AppColors.neonOrange,
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
                        AppColors.neonOrange.withOpacity(0.2),
                        AppColors.neonPurple.withOpacity(0.2),
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
                            Icons.business,
                            size: 50,
                            color: AppColors.neonOrange,
                          ),
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'Negocios',
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
            
            // Search bar
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: _buildSearchBar(controller),
              ),
            ),
            
            // Lista de negocios
            Obx(() {
              if (controller.isLoading.value && controller.businesses.isEmpty) {
                return const SliverFillRemaining(
                  child: Center(
                    child: CircularProgressIndicator(
                      color: AppColors.neonOrange,
                    ),
                  ),
                );
              }
              
              if (controller.filteredBusinesses.isEmpty) {
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
                          'No se encontraron negocios',
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
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final business = controller.filteredBusinesses[index];
                      return _buildBusinessCard(business);
                    },
                    childCount: controller.filteredBusinesses.length,
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
    );
  }

  Widget _buildSearchBar(BusinessController controller) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.darkCard,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.neonOrange.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: TextField(
        onChanged: controller.searchBusinesses,
        style: const TextStyle(
          color: AppColors.textPrimary,
          fontFamily: 'Poppins',
        ),
        decoration: const InputDecoration(
          hintText: 'Buscar negocios',
          hintStyle: TextStyle(
            color: AppColors.textHint,
            fontFamily: 'Poppins',
          ),
          prefixIcon: Icon(
            Icons.search,
            color: AppColors.neonOrange,
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

  Widget _buildBusinessCard(BusinessModel business) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: AppColors.darkCard,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.neonOrange.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () {
            Get.to(
              () => BusinessDetailView(businessId: business.id),
              transition: Transition.rightToLeft,
            );
          },
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(
                          colors: [
                            AppColors.neonOrange,
                            AppColors.neonOrange.withOpacity(0.7),
                          ],
                        ),
                      ),
                      child: const Icon(
                        Icons.business,
                        color: Colors.white,
                        size: 30,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            business.name,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textPrimary,
                              fontFamily: 'Poppins',
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              const Icon(
                                Icons.location_on,
                                size: 14,
                                color: AppColors.neonOrange,
                              ),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  business.address ?? 'Sin ubicación',
                                  style: const TextStyle(
                                    fontSize: 14,
                                    color: AppColors.textSecondary,
                                    fontFamily: 'Poppins',
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.neonOrange.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.arrow_forward_ios,
                        size: 16,
                        color: AppColors.neonOrange,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    const Icon(
                      Icons.phone,
                      size: 14,
                      color: AppColors.neonBlue,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      business.phone ?? 'Sin teléfono',
                      style: const TextStyle(
                        fontSize: 14,
                        color: AppColors.textSecondary,
                        fontFamily: 'Poppins',
                      ),
                    ),
                    const SizedBox(width: 16),
                    const Icon(
                      Icons.email,
                      size: 14,
                      color: AppColors.neonPurple,
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        business.email ?? 'Sin email',
                        style: const TextStyle(
                          fontSize: 14,
                          color: AppColors.textSecondary,
                          fontFamily: 'Poppins',
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}