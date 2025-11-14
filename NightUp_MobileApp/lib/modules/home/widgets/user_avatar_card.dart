import 'package:flutter/material.dart';
import '../../../app/themes/app_colors.dart';
import '../../../data/models/user_model.dart';

class UserAvatarCard extends StatelessWidget {
  final UserModel user;
  final VoidCallback? onTap;

  const UserAvatarCard({
    Key? key,
    required this.user,
    this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 75,
        margin: const EdgeInsets.only(right: 12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Avatar con gradiente
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: AppColors.primaryGradient,
                boxShadow: [
                  BoxShadow(
                    color: AppColors.neonPink.withOpacity(0.3),
                    blurRadius: 15,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: Container(
                margin: const EdgeInsets.all(2),
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.darkCard,
                ),
                child: Center(
                  child: Text(
                    user.username.isNotEmpty ? user.username[0].toUpperCase() : '?',
                    style: const TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                      color: AppColors.neonPink,
                      fontFamily: 'Poppins',
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 6),
            
            // Nombre
            Text(
              user.username,
              style: const TextStyle(
                fontSize: 11,
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w500,
                fontFamily: 'Poppins',
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 1),
            
            // Rol
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
              decoration: BoxDecoration(
                color: AppColors.neonPurple.withOpacity(0.2),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                user.role.toUpperCase(),
                style: const TextStyle(
                  fontSize: 8,
                  color: AppColors.neonPurple,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Poppins',
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}