import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../controllers/map_controller.dart' as myapp;
import '../theme/colors.dart';
import '../widgets/glass_card.dart';
import '../widgets/image_with_fallback.dart';

class FullMapScreen extends StatelessWidget {
  final VoidCallback onBack;
  
  const FullMapScreen({super.key, required this.onBack});

  @override
  Widget build(BuildContext context) {
    final myapp.MapController _mapController = Get.find<myapp.MapController>();

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          Obx(() => FlutterMap(
            options: MapOptions(
              center: LatLng(
                _mapController.currentPosition.value.latitude,
                _mapController.currentPosition.value.longitude,
              ),
              zoom: 13.0,
            ),
            children: [
              // Capa de tiles de OpenStreetMap
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.nightup.app',
              ),
              
              // Marcadores de amigos
              MarkerLayer(
                markers: _mapController.nearbyFriends.map((friend) {
                  return Marker(
                    width: 80.0,
                    height: 80.0,
                    point: LatLng(
                      friend['location']['coordinates'][1],
                      friend['location']['coordinates'][0],
                    ),
                    child: GestureDetector(
                      onTap: () {
                        _showFriendInfo(friend);
                      },
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(2),
                            decoration: const BoxDecoration(
                              color: AppColors.primary,
                              shape: BoxShape.circle,
                            ),
                            child: CircleAvatar(
                              radius: 20,
                              backgroundImage: NetworkImage(
                                friend['profilePictureUrl'] ?? '',
                              ),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.black.withOpacity(0.7),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              friend['username'],
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
              
              // Marcadores de eventos
              MarkerLayer(
                markers: _mapController.nearbyEvents.map((event) {
                  return Marker(
                    width: 60.0,
                    height: 60.0,
                    point: LatLng(
                      event['location']['coordinates'][1],
                      event['location']['coordinates'][0],
                    ),
                    child: GestureDetector(
                      onTap: () {
                        _showEventInfo(event);
                      },
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.orange,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.orange.withOpacity(0.5),
                                  blurRadius: 8,
                                  spreadRadius: 2,
                                ),
                              ],
                            ),
                            child: const Icon(
                              Icons.event,
                              color: Colors.white,
                              size: 20,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.black.withOpacity(0.7),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              event['title'],
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
              
              // Marcador de posición actual
              MarkerLayer(
                markers: [
                  Marker(
                    width: 40.0,
                    height: 40.0,
                    point: LatLng(
                      _mapController.currentPosition.value.latitude,
                      _mapController.currentPosition.value.longitude,
                    ),
                    child: Container(
                      decoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.2),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: AppColors.primary,
                          width: 3,
                        ),
                      ),
                      child: const Center(
                        child: Icon(
                          Icons.location_on,
                          color: AppColors.primary,
                          size: 20,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          )),
          
          // Botón de regreso
          Positioned(
            top: 60,
            left: 16,
            child: GlassCard(
              padding: EdgeInsets.zero,
              child: IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.white),
                onPressed: onBack,
              ),
            ),
          ),
          
          // Botón de actualizar
          Positioned(
            top: 60,
            right: 16,
            child: GlassCard(
              padding: EdgeInsets.zero,
              child: IconButton(
                icon: const Icon(Icons.refresh, color: Colors.white),
                onPressed: _mapController.refreshData,
              ),
            ),
          ),
          
          // Panel inferior con información
          Positioned(
            bottom: 120,
            left: 16,
            right: 16,
            child: Obx(() => GlassCard(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Around You',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${_mapController.nearbyFriends.length} friends • ${_mapController.nearbyEvents.length} events',
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                    GestureDetector(
                      onTap: _mapController.refreshData,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                        decoration: BoxDecoration(
                          gradient: AppColors.primaryGradient,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Text(
                          'Refresh',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            )),
          ),
        ],
      ),
    );
  }

  void _showFriendInfo(Map<String, dynamic> friend) {
    Get.dialog(
      GlassCard(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 30,
                    backgroundImage: NetworkImage(
                      friend['profilePictureUrl'] ?? '',
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          friend['username'],
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          friend['isOnline'] ? 'Online' : 'Offline',
                          style: TextStyle(
                            color: friend['isOnline'] ? Colors.green : Colors.grey,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              if (friend['distance'] != null)
                Text(
                  '${friend['distance'].toStringAsFixed(1)} km away',
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 14,
                  ),
                ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () {
                        // Abrir chat con el amigo
                        Get.back();
                      },
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.white,
                        side: const BorderSide(color: AppColors.primary),
                      ),
                      child: const Text('Message'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        // Ver perfil
                        Get.back();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                      ),
                      child: const Text('Profile'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showEventInfo(Map<String, dynamic> event) {
    Get.dialog(
      GlassCard(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                event['title'],
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                event['venue'],
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 8),
              if (event['price'] != null)
                Text(
                  event['price'] > 0 ? '\$${event['price']}' : 'Free',
                  style: const TextStyle(
                    color: AppColors.primary,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () {
                        Get.back();
                      },
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.white,
                        side: const BorderSide(color: AppColors.primary),
                      ),
                      child: const Text('Details'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        // Unirse al evento
                        Get.back();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                      ),
                      child: const Text('Join'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}