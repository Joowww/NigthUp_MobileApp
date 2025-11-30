import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/map_controller.dart' as my_map;
import '../services/api_service.dart';
import '../theme/colors.dart';
import '../widgets/glass_card.dart';
import '../widgets/image_with_fallback.dart';
import 'friend_profile_screen.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {

  // ✅ CAMBIO 3: Iniciar en modo minimap (vista península)
  final RxBool _isMinimap = true.obs; // ← Cambiado de false a true

  final my_map.MapController _mapController = Get.find<my_map.MapController>();
  final ApiService _apiService = Get.find<ApiService>();
  final TextEditingController _searchController = TextEditingController();

  final _searchResults = [].obs;
  final _isSearching = false.obs;

  final RxString _activeFilter = 'friends'.obs;
  final MapController _flutterMapController = MapController();

  @override
  void initState() {
    super.initState();
    _mapController.refreshData();
    
    Future.delayed(Duration(seconds: 2), () {
      _centerMapOnMarkers();
    });

    ever(_activeFilter, (_) {
      Future.delayed(Duration(milliseconds: 300), _centerMapOnMarkers);
    });
  }

  void _centerMapOnMarkers() {
    final markers = _getAllValidMarkers();
    
    if (markers.isEmpty) {
      print('⚠️ No markers to center on');
      return;
    }

    if (_isMinimap.value) {
      _flutterMapController.move(LatLng(40.4637, -3.7492), 5.5);
      print('🗺️ MINIMAP MODE: Showing full peninsula view');
      return;
    }

    double minLat = 90.0, maxLat = -90.0, minLng = 180.0, maxLng = -180.0;

    for (var marker in markers) {
      final point = marker.point;
      if (point.latitude < minLat) minLat = point.latitude;
      if (point.latitude > maxLat) maxLat = point.latitude;
      if (point.longitude < minLng) minLng = point.longitude;
      if (point.longitude > maxLng) maxLng = point.longitude;
    }

    final centerLat = (minLat + maxLat) / 2;
    final centerLng = (minLng + maxLng) / 2;
    
    final latDiff = maxLat - minLat;
    final lngDiff = maxLng - minLng;
    final maxDiff = latDiff > lngDiff ? latDiff : lngDiff;
    double zoom = 13.0;
    
    if (maxDiff > 0.1) zoom = 11.0;
    if (maxDiff > 0.2) zoom = 10.0;
    if (maxDiff > 0.5) zoom = 9.0;

    _flutterMapController.move(LatLng(centerLat, centerLng), zoom);
    
    print('🎯 MAP CENTERED on ${_activeFilter.value}: $centerLat, $centerLng zoom: $zoom');
  }

  List<Marker> _getAllValidMarkers() {
    final List<Marker> markers = [];
    
    switch (_activeFilter.value) {
      case 'friends':
        for (var friend in _mapController.nearbyFriends) {
          final marker = _createFriendMarker(friend);
          if (marker != null) markers.add(marker);
        }
        break;
        
      case 'events':
        for (var event in _mapController.nearbyEvents) {
          if (event is Map<String, dynamic>) {
            final marker = _createEventMarker(event);
            if (marker != null) markers.add(marker);
          }
        }
        break;
        
      case 'businesses':
        for (var biz in _mapController.nearbyBusinesses) {
          if (biz is Map<String, dynamic>) {
            final marker = _createBusinessMarker(biz);
            if (marker != null) markers.add(marker);
          }
        }
        break;
    }

    return markers;
  }

  void _zoomIn() {
    final currentZoom = _flutterMapController.camera.zoom;
    final newZoom = (currentZoom + 1).clamp(1.0, 18.0);
    _flutterMapController.move(_flutterMapController.camera.center, newZoom);
    print('🔍 Zoom In: $currentZoom → $newZoom');
  }

  void _zoomOut() {
    final currentZoom = _flutterMapController.camera.zoom;
    final newZoom = (currentZoom - 1).clamp(1.0, 18.0);
    _flutterMapController.move(_flutterMapController.camera.center, newZoom);
    print('🔍 Zoom Out: $currentZoom → $newZoom');
  }

  // ✅ CAMBIO 2: Widget para botones con fondo gris transparente
  Widget _greyGlassButton({
    required IconData icon,
    required VoidCallback onPressed,
    double size = 24,
    String? tooltip,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey.withOpacity(1.0), // ← Gris transparente
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.5)),
      ),
      child: IconButton(
        icon: Icon(icon, color: Colors.white, size: size),
        onPressed: onPressed,
        tooltip: tooltip,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Obx(() {
        if (_isMinimap.value) {
          return Stack(
            children: [
              FlutterMap(
                mapController: _flutterMapController,
                options: MapOptions(
                  initialCenter: LatLng(40.4637, -3.7492),
                  initialZoom: 5.5,
                  interactionOptions: const InteractionOptions(
                    flags: InteractiveFlag.all,
                  ),
                ),
                children: [
                  TileLayer(
                    urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                    userAgentPackageName: 'com.nightup.app',
                  ),
                  MarkerLayer(markers: _getAllValidMarkers()),
                ],
              ),
              
              Positioned(
                top: 16,
                left: 16,
                right: 16,
                child: Column(
                  children: [
                    // ✅ CAMBIO 2: Buscador con fondo gris
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.grey.withOpacity(1.0), // ← Gris transparente
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.white.withOpacity(0.5)),
                      ),
                      child: TextField(
                        controller: _searchController,
                        decoration: InputDecoration(
                          hintText: 'Search users, events...',
                          hintStyle: const TextStyle(color: Colors.white70),
                          prefixIcon: const Icon(Icons.search, color: Colors.white70),
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          suffixIcon: Obx(
                            () => _isSearching.value
                                ? const Padding(
                                    padding: EdgeInsets.all(8.0),
                                    child: CircularProgressIndicator(strokeWidth: 2),
                                  )
                                : IconButton(
                                    icon: const Icon(Icons.clear, color: Colors.white70),
                                    onPressed: () {
                                      _searchController.clear();
                                      _searchResults.clear();
                                    },
                                  ),
                          ),
                        ),
                        style: const TextStyle(color: Colors.white),
                        onChanged: _performSearch,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        // ✅ CAMBIO 2: Botón centrar con fondo gris
                        _greyGlassButton(
                          icon: Icons.my_location,
                          onPressed: _centerMapOnMarkers,
                          tooltip: 'Center map',
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: Row(
                              children: [
                                _filterChip('Friends', 'friends', AppColors.primary),
                                const SizedBox(width: 8),
                                _filterChip('Events', 'events', Colors.pink),
                                const SizedBox(width: 8),
                                _filterChip('Businesses', 'businesses', Colors.orange),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              
              // ✅ CAMBIO 1: Botón minimap pegado al fondo derecho
              Positioned(
                bottom: 16, // ← Pegado al fondo
                right: 16,  // ← Pegado a la derecha
                child: FloatingActionButton(
                  heroTag: 'minimap',
                  onPressed: () {
                    _isMinimap.value = !_isMinimap.value;
                    Future.delayed(Duration(milliseconds: 300), _centerMapOnMarkers);
                  },
                  backgroundColor: Colors.white,
                  child: Icon(
                    _isMinimap.value ? Icons.zoom_in_map : Icons.zoom_out_map, 
                    color: AppColors.primary,
                    size: 24,
                  ),
                  tooltip: _isMinimap.value ? 'Expandir mapa' : 'Vista península',
                ),
              ),
              
              // ✅ CAMBIO 1 y 2: Controles zoom pegados al fondo con fondo gris
              Positioned(
                bottom: 86, // ← Encima del botón minimap
                right: 16,  // ← Pegado a la derecha
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _greyGlassButton(
                      icon: Icons.add,
                      onPressed: _zoomIn,
                      size: 24,
                      tooltip: 'Zoom In',
                    ),
                    const SizedBox(height: 8),
                    _greyGlassButton(
                      icon: Icons.remove,
                      onPressed: _zoomOut,
                      size: 24,
                      tooltip: 'Zoom Out',
                    ),
                  ],
                ),
              ),
              
              if (_mapController.isLoading.value)
                Positioned(
                  top: 100,
                  left: 0,
                  right: 0,
                  child: Center(
                    child: GlassCard(
                      child: Padding(
                        padding: const EdgeInsets.all(12.0),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const CircularProgressIndicator(color: AppColors.primary),
                            const SizedBox(width: 12),
                            Text(
                              'Loading map data...',
                              style: TextStyle(color: Colors.white),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          );
        } else {
          // Modo mapa completo
          return Stack(
            children: [
              FlutterMap(
                mapController: _flutterMapController,
                options: MapOptions(
                  initialCenter: LatLng(
                    _mapController.currentPosition.value.latitude,
                    _mapController.currentPosition.value.longitude,
                  ),
                  initialZoom: 12.0,
                  interactionOptions: const InteractionOptions(
                    flags: InteractiveFlag.all,
                  ),
                ),
                children: [
                  TileLayer(
                    urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                    userAgentPackageName: 'com.nightup.app',
                  ),
                  MarkerLayer(markers: _getAllValidMarkers()),
                ],
              ),
              
              Positioned(
                top: 16,
                left: 16,
                right: 16,
                child: Column(
                  children: [
                    // ✅ CAMBIO 2: Buscador con fondo gris
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.grey.withOpacity(0.3),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.white.withOpacity(0.2)),
                      ),
                      child: TextField(
                        controller: _searchController,
                        decoration: InputDecoration(
                          hintText: 'Search users, events...',
                          hintStyle: const TextStyle(color: Colors.white70),
                          prefixIcon: const Icon(Icons.search, color: Colors.white70),
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          suffixIcon: Obx(
                            () => _isSearching.value
                                ? const Padding(
                                    padding: EdgeInsets.all(8.0),
                                    child: CircularProgressIndicator(strokeWidth: 2),
                                  )
                                : IconButton(
                                    icon: const Icon(Icons.clear, color: Colors.white70),
                                    onPressed: () {
                                      _searchController.clear();
                                      _searchResults.clear();
                                    },
                                  ),
                          ),
                        ),
                        style: const TextStyle(color: Colors.white),
                        onChanged: _performSearch,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        _greyGlassButton(
                          icon: Icons.my_location,
                          onPressed: _centerMapOnMarkers,
                          tooltip: 'Center map',
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: Row(
                              children: [
                                _filterChip('Friends', 'friends', AppColors.primary),
                                const SizedBox(width: 8),
                                _filterChip('Events', 'events', Colors.pink),
                                const SizedBox(width: 8),
                                _filterChip('Businesses', 'businesses', Colors.orange),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              
              // ✅ CAMBIO 1: Botón minimap pegado al fondo derecho
              Positioned(
                bottom: 16,
                right: 16,
                child: FloatingActionButton(
                  heroTag: 'minimap',
                  onPressed: () {
                    _isMinimap.value = !_isMinimap.value;
                    Future.delayed(Duration(milliseconds: 300), _centerMapOnMarkers);
                  },
                  backgroundColor: Colors.white,
                  child: Icon(
                    _isMinimap.value ? Icons.zoom_in_map : Icons.zoom_out_map, 
                    color: AppColors.primary,
                    size: 24,
                  ),
                  tooltip: _isMinimap.value ? 'Expandir mapa' : 'Vista península',
                ),
              ),
              
              // ✅ CAMBIO 1 y 2: Controles zoom pegados al fondo con fondo gris
              Positioned(
                bottom: 86,
                right: 16,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _greyGlassButton(
                      icon: Icons.add,
                      onPressed: _zoomIn,
                      size: 28,
                      tooltip: 'Zoom In',
                    ),
                    const SizedBox(height: 8),
                    _greyGlassButton(
                      icon: Icons.remove,
                      onPressed: _zoomOut,
                      size: 28,
                      tooltip: 'Zoom Out',
                    ),
                  ],
                ),
              ),
              
              if (_mapController.isLoading.value)
                Positioned(
                  top: 100,
                  left: 0,
                  right: 0,
                  child: Center(
                    child: GlassCard(
                      child: Padding(
                        padding: const EdgeInsets.all(12.0),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const CircularProgressIndicator(color: AppColors.primary),
                            const SizedBox(width: 12),
                            Text(
                              'Loading map data...',
                              style: TextStyle(color: Colors.white),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          );
        }
      }),
    );
  }

  Marker? _createFriendMarker(dynamic friend) {
    try {
      if (friend.lat == null || friend.lng == null) {
        print('❌ Friend ${friend.username} has invalid coordinates: [${friend.lng}, ${friend.lat}]');
        return null;
      }
      final lat = friend.lat as double;
      final lng = friend.lng as double;
      final username = friend.username ?? 'Friend';
      final avatar = friend.profilePictureUrl ?? '';
      print('📍 Friend Marker: $username at $lat, $lng');
      return Marker(
        point: LatLng(lat, lng),
        width: 70,
        height: 85,
        child: GestureDetector(
          onTap: () {
            Get.snackbar("Friend", "Tapped on $username");
          },
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.primary, width: 3),
                  color: Colors.black,
                  boxShadow: [BoxShadow(color: AppColors.primary.withOpacity(0.5), blurRadius: 10)],
                ),
                child: ClipOval(
                  child: ImageWithFallback(
                    imageUrl: avatar,
                    fallbackAsset: 'assets/images/default-avatar.png',
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.8),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.primary),
                ),
                child: Text(
                  username,
                  style: const TextStyle(
                    color: Colors.white, 
                    fontSize: 11, 
                    fontWeight: FontWeight.bold
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      );
    } catch (e) {
      print('❌ Error creating friend marker: $e');
      return null;
    }
  }

  Marker? _createEventMarker(Map<String, dynamic> event) {
    try {
      final coords = event['location']?['coordinates'];
      if (coords is! List || coords.length < 2) {
        final name = event['name'] ?? event['title'] ?? 'Unknown';
        print('❌ Event $name has invalid coordinates: $coords');
        return null;
      }
      
      final lng = (coords[0] as num).toDouble();
      final lat = (coords[1] as num).toDouble();
      
      final name = event['name'] ?? event['title'] ?? 'Event';
      
      print('📍 Event Marker: $name at $lat, $lng');
      
      return Marker(
        point: LatLng(lat, lng),
        width: 60,
        height: 75,
        child: GestureDetector(
          onTap: () {
            Get.snackbar("Event", "Tapped on $name");
          },
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 45,
                height: 45,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.pink, width: 3),
                  color: Colors.black,
                  boxShadow: [BoxShadow(color: Colors.pink.withOpacity(0.5), blurRadius: 10)],
                ),
                child: const Icon(Icons.event, color: Colors.pink, size: 25),
              ),
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.8),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.pink),
                ),
                child: Text(
                  name,
                  style: const TextStyle(
                    color: Colors.white, 
                    fontSize: 10, 
                    fontWeight: FontWeight.bold
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      );
    } catch (e) {
      print('❌ Error creating event marker: $e');
      return null;
    }
  }

  Marker? _createBusinessMarker(Map<String, dynamic> business) {
    try {
      final coords = business['location']?['coordinates'];
      if (coords is! List || coords.length < 2) {
        final name = business['name'] ?? 'Unknown';
        print('❌ Business $name has invalid coordinates: $coords');
        return null;
      }
      
      final lng = (coords[0] as num).toDouble();
      final lat = (coords[1] as num).toDouble();
      
      final name = business['name'] ?? 'Business';
      
      print('📍 Business Marker: $name at $lat, $lng');
      
      return Marker(
        point: LatLng(lat, lng),
        width: 60,
        height: 75,
        child: GestureDetector(
          onTap: () {
            Get.snackbar("Business", "Tapped on $name");
          },
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 45,
                height: 45,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.orange, width: 3),
                  color: Colors.black,
                  boxShadow: [BoxShadow(color: Colors.orange.withOpacity(0.5), blurRadius: 10)],
                ),
                child: const Icon(Icons.store, color: Colors.orange, size: 25),
              ),
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.8),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.orange),
                ),
                child: Text(
                  name,
                  style: const TextStyle(
                    color: Colors.white, 
                    fontSize: 10, 
                    fontWeight: FontWeight.bold
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      );
    } catch (e) {
      print('❌ Error creating business marker: $e');
      return null;
    }
  }

  Widget _filterChip(String label, String filterValue, Color activeColor) {
    return Obx(() {
      final isActive = _activeFilter.value == filterValue;
      
      return FilterChip(
        label: Text(label),
        selected: isActive,
        onSelected: (v) {
          _activeFilter.value = filterValue;
        },
        backgroundColor: Colors.black.withOpacity(0.6),
        selectedColor: activeColor.withOpacity(0.3),
        labelStyle: TextStyle(
          color: isActive ? activeColor : Colors.white70,
          fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: isActive ? activeColor : Colors.white24),
        ),
        showCheckmark: false,
      );
    });
  }

  void _performSearch(String query) async {
    if (query.isEmpty) {
      _searchResults.clear();
      return;
    }

    _isSearching.value = true;

    try {
      final response = await _apiService.get('/user?search=$query&limit=10');

      if (response.data is Map && response.data['users'] is List) {
        _searchResults.value = response.data['users'];
      } else if (response.data is List) {
        _searchResults.value = response.data;
      } else {
        _searchResults.value = [];
      }
    } catch (e) {
      print('❌ Error searching users: $e');
      _searchResults.value = [];
    } finally {
      _isSearching.value = false;
    }
  }
}