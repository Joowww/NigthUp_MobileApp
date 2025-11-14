import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../app/themes/app_colors.dart';
import '../../../data/models/business_model.dart';
import '../../../data/repositories/business_repository.dart';

class BusinessDetailView extends StatefulWidget {
  final String businessId;

  const BusinessDetailView({
    Key? key,
    required this.businessId,
  }) : super(key: key);

  @override
  State<BusinessDetailView> createState() => _BusinessDetailViewState();
}

class _BusinessDetailViewState extends State<BusinessDetailView> {
  final BusinessRepository _repository = BusinessRepository();
  BusinessModel? business;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadBusiness();
  }

  Future<void> _loadBusiness() async {
    try {
      final result = await _repository.getBusinessById(widget.businessId);
      setState(() {
        business = result;
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      Get.snackbar(
        'Error',
        e.toString(),
        backgroundColor: AppColors.error.withOpacity(0.9),
        colorText: Colors.white,
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(
            color: AppColors.neonOrange,
          ),
        ),
      );
    }

    if (business == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Negocio'),
        ),
        body: const Center(
          child: Text(
            'Negocio no encontrado',
            style: TextStyle(
              color: AppColors.textSecondary,
              fontFamily: 'Poppins',
            ),
          ),
        ),
      );
    }

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // AppBar
          SliverAppBar(
            expandedHeight: 250,
            pinned: true,
            backgroundColor: AppColors.darkBackground,
            leading: Container(
              margin: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.darkCard.withOpacity(0.8),
                borderRadius: BorderRadius.circular(12),
              ),
              child: IconButton(
                icon: const Icon(Icons.arrow_back_ios_new),
                onPressed: () => Get.back(),
              ),
            ),
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      AppColors.neonOrange.withOpacity(0.3),
                      AppColors.darkBackground,
                    ],
                  ),
                ),
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 100,
                        height: 100,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: LinearGradient(
                            colors: [
                              AppColors.neonOrange,
                              AppColors.neonOrange.withOpacity(0.7),
                            ],
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.neonOrange.withOpacity(0.5),
                              blurRadius: 30,
                              spreadRadius: 5,
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.business,
                          size: 50,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          
          // Contenido
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Nombre
                  Text(
                    business!.name,
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                      fontFamily: 'Poppins',
                    ),
                  ),
                  const SizedBox(height: 24),
                  
                  // Descripción
                  if (business!.description != null) ...[
                    Row(
                      children: [
                        Container(
                          width: 4,
                          height: 20,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                AppColors.neonOrange,
                                AppColors.neonOrange.withOpacity(0.7),
                              ],
                            ),
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                        const SizedBox(width: 12),
                        const Text(
                          'Descripción',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                            fontFamily: 'Poppins',
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      business!.description!,
                      style: const TextStyle(
                        fontSize: 14,
                        color: AppColors.textSecondary,
                        fontFamily: 'Poppins',
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],
                  
                  // Información de contacto
                  Row(
                    children: [
                      Container(
                        width: 4,
                        height: 20,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              AppColors.neonBlue,
                              AppColors.neonBlue.withOpacity(0.7),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Text(
                        'Contacto',
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
                  
                  _buildInfoCard(
                    icon: Icons.location_on,
                    title: 'Dirección',
                    value: business!.address ?? 'No especificada',
                    color: AppColors.neonOrange,
                  ),
                  const SizedBox(height: 12),
                  
                  _buildInfoCard(
                    icon: Icons.phone,
                    title: 'Teléfono',
                    value: business!.phone ?? 'No especificado',
                    color: AppColors.neonBlue,
                  ),
                  const SizedBox(height: 12),
                  
                  _buildInfoCard(
                    icon: Icons.email,
                    title: 'Email',
                    value: business!.email ?? 'No especificado',
                    color: AppColors.neonPurple,
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // Estadísticas
                  Row(
                    children: [
                      Container(
                        width: 4,
                        height: 20,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              AppColors.neonPink,
                              AppColors.neonPink.withOpacity(0.7),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Text(
                        'Estadísticas',
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
                  
                  Row(
                    children: [
                      Expanded(
                        child: _buildStatCard(
                          icon: Icons.business_center,
                          title: 'Managers',
                          value: business!.managers.length.toString(),
                          color: AppColors.neonOrange,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _buildStatCard(
                          icon: Icons.event,
                          title: 'Eventos',
                          value: business!.events.length.toString(),
                          color: AppColors.neonPink,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard({
    required IconData icon,
    required String title,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.darkCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: color.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              icon,
              color: color,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                    fontFamily: 'Poppins',
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                    fontFamily: 'Poppins',
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required String title,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.darkCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: color.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              icon,
              color: color,
              size: 28,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
              fontFamily: 'Poppins',
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.textSecondary,
              fontFamily: 'Poppins',
            ),
          ),
        ],
      ),
    );
  }
}