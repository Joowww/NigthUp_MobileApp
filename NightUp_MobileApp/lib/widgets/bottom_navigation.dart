import 'package:flutter/material.dart';
import '../theme/colors.dart';

class BottomNavigation extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTabChanged;
  
  const BottomNavigation({
    super.key,
    required this.currentIndex,
    required this.onTabChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.grey[900]!.withOpacity(0.95),
            Colors.black.withOpacity(0.95),
        ],
        ),
        borderRadius: BorderRadius.circular(25),
        border: Border.all(color: AppColors.glassBorder),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildNavItem(Icons.home, 'Home', 0),
            _buildNavItem(Icons.search, 'Search', 1),
            _buildCameraButton(),
            _buildNavItem(Icons.chat_bubble, 'Chat', 3),
            _buildNavItem(Icons.person, 'Profile', 4),
          ],
        ),
      ),
    );
  }

  Widget _buildNavItem(IconData icon, String label, int index) {
    final isActive = currentIndex == index;
    
    return GestureDetector(
      onTap: () => onTabChanged(index),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            color: isActive ? AppColors.primary : Colors.white70,
            size: 24,
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              color: isActive ? AppColors.primary : Colors.white70,
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCameraButton() {
    final isActive = currentIndex == 2;
    
    return GestureDetector(
      onTap: () => onTabChanged(2),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              gradient: isActive 
                  ? AppColors.primaryGradient 
                  : LinearGradient(
                      colors: [
                        Colors.grey[800]!,
                        Colors.grey[900]!,
                      ],
                    ),
              shape: BoxShape.circle,
              boxShadow: isActive
                  ? [
                      BoxShadow(
                        color: AppColors.primary.withOpacity(0.5),
                        blurRadius: 10,
                        spreadRadius: 2,
                      ),
                    ]
                  : [],
            ),
            child: Icon(
              Icons.add, 
              color: isActive ? Colors.white : Colors.white70, 
              size: 28
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Post',
            style: TextStyle(
              color: isActive ? AppColors.primary : Colors.white70,
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }
}