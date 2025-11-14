import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import '../../../app/themes/app_colors.dart';
import '../../../app/widgets/gradient_button.dart';
import '../../../app/widgets/rating_card.dart';
import '../controllers/event_detail_controller.dart';
import '../../../data/models/event_model.dart';

class EventDetailView extends StatelessWidget {
  final String eventId;

  const EventDetailView({
    Key? key,
    required this.eventId,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(EventDetailController());
    controller.loadEventDetail(eventId);

    return Scaffold(
      body: Obx(() {
        if (controller.isLoading.value && controller.event.value == null) {
          return const Center(
            child: CircularProgressIndicator(
              color: AppColors.neonPink,
            ),
          );
        }

        final event = controller.event.value;
        if (event == null) {
          return const Center(
            child: Text(
              'Evento no encontrado',
              style: TextStyle(
                color: AppColors.textSecondary,
                fontFamily: 'Poppins',
              ),
            ),
          );
        }

        return CustomScrollView(
          slivers: [
            // AppBar con imagen
            _buildAppBar(context, event),
            
            // Contenido
            SliverToBoxAdapter(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Información principal
                  _buildMainInfo(event, controller),
                  
                  // Descripción
                  _buildDescription(event),
                  
                  // Detalles
                  _buildDetails(event),
                  
                  // Ratings
                  _buildRatingsSection(controller),
                  
                  const SizedBox(height: 100),
                ],
              ),
            ),
          ],
        );
      }),
      bottomNavigationBar: _buildBottomBar(controller),
    );
  }

  Widget _buildAppBar(BuildContext context, EventModel event) {
    return SliverAppBar(
      expandedHeight: 300,
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
        background: Stack(
          fit: StackFit.expand,
          children: [
            // Imagen
            event.imageUrl != null
                ? CachedNetworkImage(
                    imageUrl: event.imageUrl!,
                    fit: BoxFit.cover,
                    placeholder: (context, url) => Container(
                      decoration: BoxDecoration(
                        gradient: AppColors.primaryGradient,
                      ),
                    ),
                    errorWidget: (context, url, error) => Container(
                      decoration: BoxDecoration(
                        gradient: AppColors.primaryGradient,
                      ),
                      child: const Icon(
                        Icons.nightlife,
                        size: 100,
                        color: Colors.white,
                      ),
                    ),
                  )
                : Container(
                    decoration: BoxDecoration(
                      gradient: AppColors.primaryGradient,
                    ),
                    child: const Icon(
                      Icons.nightlife,
                      size: 100,
                      color: Colors.white,
                    ),
                  ),
            
            // Gradiente overlay
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    AppColors.darkBackground.withOpacity(0.7),
                    AppColors.darkBackground,
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMainInfo(EventModel event, EventDetailController controller) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Nombre y categoría
          Row(
            children: [
              Expanded(
                child: Text(
                  event.name,
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                    fontFamily: 'Poppins',
                  ),
                ),
              ),
              _buildCategoryChip(event.category),
            ],
          ),
          const SizedBox(height: 16),
          
          // Rating promedio
          Obx(() => controller.ratings.isNotEmpty
              ? Row(
                  children: [
                    RatingBarIndicator(
                      rating: controller.averageRating.value,
                      itemBuilder: (context, index) => const Icon(
                        Icons.star,
                        color: AppColors.neonOrange,
                      ),
                      itemCount: 5,
                      itemSize: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '${controller.averageRating.value.toStringAsFixed(1)} (${controller.ratings.length})',
                      style: const TextStyle(
                        fontSize: 14,
                        color: AppColors.textSecondary,
                        fontFamily: 'Poppins',
                      ),
                    ),
                  ],
                )
              : const SizedBox.shrink()),
        ],
      ),
    );
  }

  Widget _buildCategoryChip(String category) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        gradient: AppColors.primaryGradient,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: AppColors.neonPink.withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Text(
        category.toUpperCase(),
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: Colors.white,
          fontFamily: 'Poppins',
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget _buildDescription(EventModel event) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
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
            event.description,
            style: const TextStyle(
              fontSize: 14,
              color: AppColors.textSecondary,
              fontFamily: 'Poppins',
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetails(EventModel event) {
    return Padding(
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
                'Detalles',
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
          
          // Fecha y hora
          _buildDetailItem(
            icon: Icons.calendar_today,
            title: 'Fecha y hora',
            value: '${event.schedule.day}/${event.schedule.month}/${event.schedule.year} - ${event.schedule.hour}:${event.schedule.minute.toString().padLeft(2, '0')}',
            color: AppColors.neonPurple,
          ),
          const SizedBox(height: 12),
          
          // Ubicación
          _buildDetailItem(
            icon: Icons.location_on,
            title: 'Ubicación',
            value: event.location,
            color: AppColors.neonBlue,
          ),
          const SizedBox(height: 12),
          
          // Precio
          _buildDetailItem(
            icon: Icons.euro,
            title: 'Precio',
            value: event.price > 0 ? '€${event.price.toStringAsFixed(2)}' : 'GRATIS',
            color: AppColors.neonGreen,
          ),
          const SizedBox(height: 12),
          
          // Capacidad
          _buildDetailItem(
            icon: Icons.people,
            title: 'Participantes',
            value: '${event.currentParticipants} / ${event.capacity}',
            color: event.isFull ? AppColors.error : AppColors.neonOrange,
          ),
        ],
      ),
    );
  }

  Widget _buildDetailItem({
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

  Widget _buildRatingsSection(EventDetailController controller) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
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
                    'Valoraciones',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                      fontFamily: 'Poppins',
                    ),
                  ),
                ],
              ),
              TextButton.icon(
                onPressed: () => _showRatingDialog(controller),
                icon: const Icon(
                  Icons.add,
                  color: AppColors.neonPink,
                ),
                label: const Text(
                  'Valorar',
                  style: TextStyle(
                    color: AppColors.neonPink,
                    fontFamily: 'Poppins',
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          Obx(() {
            if (controller.ratings.isEmpty) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      Icon(
                        Icons.star_outline,
                        size: 60,
                        color: AppColors.textSecondary.withOpacity(0.5),
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Aún no hay valoraciones',
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          fontFamily: 'Poppins',
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }
            
            return ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: controller.ratings.length,
              itemBuilder: (context, index) {
                final rating = controller.ratings[index];
                return RatingCard(rating: rating);
              },
            );
          }),
        ],
      ),
    );
  }

  Widget _buildBottomBar(EventDetailController controller) {
    return Obx(() {
      final event = controller.event.value;
      if (event == null) return const SizedBox.shrink();

      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppColors.darkCard,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.3),
              blurRadius: 20,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: SafeArea(
          child: controller.isJoined.value
              ? GradientButton(
                  text: 'Salir del evento',
                  onPressed: controller.leaveEvent,
                  gradient: LinearGradient(
                    colors: [
                      AppColors.error,
                      AppColors.error.withOpacity(0.7),
                    ],
                  ),
                )
              : GradientButton(
                  text: event.isFull ? 'Evento completo' : 'Unirse al evento',
                  onPressed: event.isFull ? () {} : controller.joinEvent,
                  gradient: event.isFull 
                      ? LinearGradient(
                          colors: [
                            AppColors.textHint,
                            AppColors.textSecondary,
                          ],
                        )
                      : AppColors.primaryGradient,
                ),
        ),
      );
    });
  }

  void _showRatingDialog(EventDetailController controller) {
    double rating = 5;
    final commentController = TextEditingController();

    Get.dialog(
      AlertDialog(
        backgroundColor: AppColors.darkCard,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: const Text(
          'Valorar evento',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontFamily: 'Poppins',
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              '¿Cómo fue tu experiencia?',
              style: TextStyle(
                color: AppColors.textSecondary,
                fontFamily: 'Poppins',
              ),
            ),
            const SizedBox(height: 20),
            RatingBar.builder(
              initialRating: 5,
              minRating: 1,
              direction: Axis.horizontal,
              allowHalfRating: false,
              itemCount: 5,
              itemSize: 40,
              itemBuilder: (context, _) => const Icon(
                Icons.star,
                color: AppColors.neonOrange,
              ),
              onRatingUpdate: (value) {
                rating = value;
              },
            ),
            const SizedBox(height: 20),
            TextField(
              controller: commentController,
              maxLines: 3,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontFamily: 'Poppins',
              ),
              decoration: InputDecoration(
                hintText: 'Comentario (opcional)',
                hintStyle: const TextStyle(
                  color: AppColors.textHint,
                  fontFamily: 'Poppins',
                ),
                filled: true,
                fillColor: AppColors.darkInput,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text(
              'Cancelar',
              style: TextStyle(
                color: AppColors.textSecondary,
                fontFamily: 'Poppins',
              ),
            ),
          ),
          TextButton(
            onPressed: () {
              controller.addRating(
                rating.toInt(),
                commentController.text.isNotEmpty ? commentController.text : null,
              );
            },
            child: const Text(
              'Enviar',
              style: TextStyle(
                color: AppColors.neonPink,
                fontFamily: 'Poppins',
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }
}