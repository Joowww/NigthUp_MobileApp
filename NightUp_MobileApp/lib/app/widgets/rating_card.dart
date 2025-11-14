import 'package:flutter/material.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import '../../app/themes/app_colors.dart';
import '../../data/models/rating_model.dart';

class RatingCard extends StatelessWidget {
  final RatingModel rating;

  const RatingCard({
    Key? key,
    required this.rating,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.darkCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.neonOrange.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: AppColors.primaryGradient,
                ),
                child: Center(
                  child: Text(
                    _getInitials(rating.username),
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      fontFamily: 'Poppins',
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      rating.username.isNotEmpty ? rating.username : 'Usuario Anónimo',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                        fontFamily: 'Poppins',
                      ),
                    ),
                    const SizedBox(height: 4),
                    RatingBarIndicator(
                      rating: rating.score.toDouble(),
                      itemBuilder: (context, index) => const Icon(
                        Icons.star,
                        color: AppColors.neonOrange,
                      ),
                      itemCount: 5,
                      itemSize: 16,
                    ),
                  ],
                ),
              ),
              Text(
                _formatDate(rating.createdAt),
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                  fontFamily: 'Poppins',
                ),
              ),
            ],
          ),
          if (rating.comment != null && rating.comment!.isNotEmpty) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.darkInput,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                rating.comment!,
                style: const TextStyle(
                  fontSize: 14,
                  color: AppColors.textPrimary,
                  fontFamily: 'Poppins',
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  String _getInitials(String username) {
    if (username.isEmpty) return 'U';
    final words = username.trim().split(' ');
    if (words.length == 1) {
      return words[0][0].toUpperCase();
    } else {
      return '${words[0][0]}${words.last[0]}'.toUpperCase();
    }
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays > 7) {
      return '${date.day}/${date.month}/${date.year}';
    } else if (difference.inDays > 0) {
      return 'Hace ${difference.inDays}d';
    } else if (difference.inHours > 0) {
      return 'Hace ${difference.inHours}h';
    } else if (difference.inMinutes > 0) {
      return 'Hace ${difference.inMinutes}m';
    } else {
      return 'Ahora';
    }
  }
}