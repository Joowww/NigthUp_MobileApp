import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../controllers/map_controller.dart' as myapp;
import '../theme/colors.dart';
import '../widgets/glass_card.dart';
import '../widgets/image_with_fallback.dart';
import '../models/business.dart';
import '../models/event.dart';
import '../models/friend.dart';

class FullMapScreen extends StatelessWidget {
  final VoidCallback? onBack;
  final List<Business>? businesses;
  final List<Event>? events;
  final List<Friend>? friends;
  final Business? selectedBusiness;
  final Event? selectedEvent;
  final Friend? selectedFriend;
  const FullMapScreen({Key? key, this.onBack, this.businesses, this.events, this.friends, this.selectedBusiness, this.selectedEvent, this.selectedFriend}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final myapp.MapController _mapController = Get.find<myapp.MapController>();
    final List<Business> allBusinesses = businesses ?? _mapController.nearbyBusinesses.map((e) => Business.fromJson(e)).toList();
    final List<Event> allEvents = events ?? _mapController.nearbyEvents.map((e) => Event.fromJson(e)).toList();
    final List<Friend> allFriends = friends ?? _mapController.nearbyFriends.map((e) => Friend.fromJson(e)).toList();
    final Business? highlightedBusiness = selectedBusiness;
    final Event? highlightedEvent = selectedEvent;
    final Friend? highlightedFriend = selectedFriend;

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          FlutterMap(
            options: MapOptions(
              initialCenter: LatLng(
                _mapController.currentPosition.value.latitude,
                _mapController.currentPosition.value.longitude,
              ),
              initialZoom: 13.0,
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.nightup.app',
              ),
              // Marcadores de negocios
              MarkerLayer(
                markers: allBusinesses.where((b) => b.lat != null && b.lng != null).map((business) {
                  final isSelected = highlightedBusiness != null && business.id == highlightedBusiness.id;
                  return Marker(
                    width: isSelected ? 60.0 : 40.0,
                    height: isSelected ? 60.0 : 40.0,
                    point: LatLng(business.lat!, business.lng!),
                    child: GestureDetector(
                      onTap: () {
                        // Mostrar info negocio
                      },
                      child: Icon(
                        Icons.store,
                        color: isSelected ? Colors.red : Colors.blue,
                        size: isSelected ? 40 : 30,
                      ),
                    ),
                  );
                }).toList(),
              ),
              // Marcadores de eventos
              MarkerLayer(
                markers: allEvents.where((e) {
                  // Extraer lat/lng de GeoJSON
                  final loc = (e as dynamic).toJson()['location'];
                  if (loc is Map && loc['coordinates'] is List && loc['coordinates'].length >= 2) {
                    return loc['coordinates'][1] != null && loc['coordinates'][0] != null;
                  }
                  return false;
                }).map((event) {
                  final isSelected = highlightedEvent != null && event.id == highlightedEvent.id;
                  final loc = (event as dynamic).toJson()['location'];
                  final lat = loc['coordinates'][1];
                  final lng = loc['coordinates'][0];
                  return Marker(
                    width: isSelected ? 60.0 : 40.0,
                    height: isSelected ? 60.0 : 40.0,
                    point: LatLng(lat, lng),
                    child: GestureDetector(
                      onTap: () {
                        // Mostrar info evento
                      },
                      child: Icon(
                        Icons.event,
                        color: isSelected ? Colors.red : Colors.orange,
                        size: isSelected ? 40 : 30,
                      ),
                    ),
                  );
                }).toList(),
              ),
              // Marcadores de amigos
              MarkerLayer(
                markers: allFriends.where((f) => f.lat != null && f.lng != null).map((friend) {
                  final isSelected = highlightedFriend != null && friend.id == highlightedFriend.id;
                  return Marker(
                    width: isSelected ? 60.0 : 40.0,
                    height: isSelected ? 60.0 : 40.0,
                    point: LatLng(friend.lat!, friend.lng!),
                    child: GestureDetector(
                      onTap: () {
                        // Mostrar info amigo
                      },
                      child: Icon(
                        Icons.person_pin_circle,
                        color: isSelected ? Colors.red : Colors.green,
                        size: isSelected ? 40 : 30,
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
          ),
          
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


}