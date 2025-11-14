import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:shimmer/shimmer.dart';
import 'package:flutter_translate/flutter_translate.dart';
import '../../../app/themes/app_colors.dart';
import '../../../data/models/event_model.dart';

class EventCard extends StatelessWidget {
  final EventModel event;
  final VoidCallback? onTap;

  const EventCard({
    Key? key,
    required this.event,
    this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        decoration: BoxDecoration(
          color: AppColors.darkCard,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.15), // Sombra más sutil
              blurRadius: 8, // Menos blur para menos grosor
              offset: const Offset(0, 2), // Sombra más pequeña
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Imagen del evento
            _buildEventImage(),
            
            // Información del evento
            Padding(
              padding: const EdgeInsets.all(6), // Reducido de 8 a 6
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Nombre y categoría
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          event.name,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                            fontFamily: 'Poppins',
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 6),
                      _buildCategoryChip(),
                    ],
                  ),
                  const SizedBox(height: 4),
                  
                  // Ubicación
                  Row(
                    children: [
                      const Icon(
                        Icons.location_on,
                        size: 12,
                        color: AppColors.neonBlue,
                      ),
                      const SizedBox(width: 3),
                      Expanded(
                        child: Text(
                          event.location,
                          style: const TextStyle(
                            fontSize: 11,
                            color: AppColors.textSecondary,
                            fontFamily: 'Poppins',
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  
                  // Fecha
                  Row(
                    children: [
                      const Icon(
                        Icons.calendar_today,
                        size: 12,
                        color: AppColors.neonPurple,
                      ),
                      const SizedBox(width: 3),
                      Text(
                        '${event.schedule.day}/${event.schedule.month}/${event.schedule.year}',
                        style: const TextStyle(
                          fontSize: 11,
                          color: AppColors.textSecondary,
                          fontFamily: 'Poppins',
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  
                  // Precio y ocupación
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Precio
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          gradient: AppColors.primaryGradient,
                          borderRadius: BorderRadius.circular(5),
                        ),
                        child: Text(
                          event.price > 0 ? '€${event.price.toStringAsFixed(2)}' : translate('events.free'),
                          style: const TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            fontFamily: 'Poppins',
                          ),
                        ),
                      ),
                      
                      // Ocupación
                      Row(
                        children: [
                          const Icon(
                            Icons.people,
                            size: 12,
                            color: AppColors.neonGreen,
                          ),
                          const SizedBox(width: 3),
                          Text(
                            '${event.currentParticipants}/${event.capacity}',
                            style: TextStyle(
                              fontSize: 11,
                              color: event.isFull ? AppColors.error : AppColors.neonGreen,
                              fontWeight: FontWeight.w600,
                              fontFamily: 'Poppins',
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEventImage() {
    return ClipRRect(
      borderRadius: const BorderRadius.only(
        topLeft: Radius.circular(16),
        topRight: Radius.circular(16),
      ),
      child: Stack(
        children: [
          event.imageUrl != null
              ? CachedNetworkImage(
                  imageUrl: event.imageUrl!,
                  height: 70, // Reducido de 80 a 70
                  width: double.infinity,
                  fit: BoxFit.cover,
                  placeholder: (context, url) => Shimmer.fromColors(
                    baseColor: AppColors.darkInput,
                    highlightColor: AppColors.darkCard,
                    child: Container(
                      height: 70, // Reducido de 80 a 70
                      color: AppColors.darkInput,
                    ),
                  ),
                  errorWidget: (context, url, error) => _buildPlaceholderImage(),
                )
              : _buildPlaceholderImage(),
          
          // Gradiente overlay
          Container(
            height: 70, // Reducido de 80 a 70
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.transparent,
                  const Color(0xFF1A1A2E).withOpacity(0.6), // Azul oscuro más neutro
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlaceholderImage() {
    return Container(
      height: 70, // Reducido de 80 a 70
      width: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF2A1A4A), // Morado oscuro
            Color(0xFF1A2F4A), // Azul oscuro
          ],
        ),
      ),
      child: const Icon(
        Icons.nightlife,
        size: 30, // Reducido de 35 a 30
        color: Colors.white,
      ),
    );
  }

  Widget _buildCategoryChip() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
      decoration: BoxDecoration(
        color: AppColors.neonPurple.withOpacity(0.2),
        borderRadius: BorderRadius.circular(5),
        border: Border.all(
          color: AppColors.neonPurple.withOpacity(0.5),
          width: 1,
        ),
      ),
      child: Text(
        event.category.toUpperCase(),
        style: const TextStyle(
          fontSize: 8,
          fontWeight: FontWeight.bold,
          color: AppColors.neonPurple,
          fontFamily: 'Poppins',
          letterSpacing: 0.3,
        ),
      ),
    );
  }
}