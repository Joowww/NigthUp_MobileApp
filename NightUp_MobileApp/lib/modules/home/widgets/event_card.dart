import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:shimmer/shimmer.dart';
import 'package:flutter_translate/flutter_translate.dart';
import 'package:get/get.dart';                              // ⬅️ AÑADIDO
import '../../../app/routes/app_routes.dart';               // ⬅️ AÑADIDO
import '../../../app/themes/app_colors.dart';
import '../../../data/models/event_model.dart';

class EventCard extends StatelessWidget {
  final EventModel event;
  final VoidCallback? onTap; // Puedes mantenerlo igual

  const EventCard({
    Key? key,
    required this.event,
    this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap ??
          () {
            Get.toNamed(
              AppRoutes.eventDetail,
              arguments: event.id,
            );
          },
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        decoration: BoxDecoration(
          color: AppColors.darkCard,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.15),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildEventImage(),
            Padding(
              padding: const EdgeInsets.all(6),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
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

                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
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
                          event.price > 0
                              ? '€${event.price.toStringAsFixed(2)}'
                              : translate('events.free'),
                          style: const TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            fontFamily: 'Poppins',
                          ),
                        ),
                      ),

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
                              color: event.isFull
                                  ? AppColors.error
                                  : AppColors.neonGreen,
                              fontWeight: FontWeight.w600,
                              fontFamily: 'Poppins',
                            ),
                          ),
                        ],
                      ),
                    ],
                  )
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
                  height: 70,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  placeholder: (context, url) => Shimmer.fromColors(
                    baseColor: AppColors.darkInput,
                    highlightColor: AppColors.darkCard,
                    child: Container(
                      height: 70,
                      color: AppColors.darkInput,
                    ),
                  ),
                  errorWidget: (context, url, error) =>
                      _buildPlaceholderImage(),
                )
              : _buildPlaceholderImage(),

          Container(
            height: 70,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.transparent,
                  const Color(0xFF1A1A2E).withOpacity(0.6),
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
      height: 70,
      width: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF2A1A4A),
            Color(0xFF1A2F4A),
          ],
        ),
      ),
      child: const Icon(
        Icons.nightlife,
        size: 30,
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
