import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/map_controller.dart' as my_map;
import '../services/api_service.dart';
import '../theme/colors.dart';
import '../widgets/glass_card.dart';
import '../widgets/image_with_fallback.dart';

import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final RxBool _isMinimap = true.obs;

  final my_map.MapController _mapController = Get.find<my_map.MapController>();
  final ApiService _apiService = Get.find<ApiService>();
  final TextEditingController _searchController = TextEditingController();

  final RxMap<String, List<dynamic>> _searchResults = <String, List<dynamic>>{
    'users': [],
    'events': [],
    'businesses': [],
  }.obs;

  final _isSearching = false.obs;
  final _showResults = false.obs;

  final RxString _activeFilter = 'friends'.obs;
  final MapController _flutterMapController = MapController();

  final RxString _selectedId = ''.obs;
  final RxString _selectedType = ''.obs;

  @override
  void initState() {
    super.initState();

    Future.microtask(() {
      _mapController.refreshData();
    });

    Future.delayed(const Duration(seconds: 2), () {
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

    print(
      '🎯 MAP CENTERED on ${_activeFilter.value}: $centerLat, $centerLng zoom: $zoom',
    );
  }

  List<Marker> _getAllValidMarkers() {
    final List<Marker> markers = [];

    switch (_activeFilter.value) {
      case 'friends':
        for (var friend in _mapController.nearbyFriends) {
          if (friend == null) continue;
          bool isHidden = false;
          try {
            if ((friend as dynamic).isVisibleOnMap == false) isHidden = true;
          } catch (e) {
            // Si el modelo no tiene el campo todavía, no hacemos nada (se muestra)
          }
          if (friend is Map && friend['isVisibleOnMap'] == false) {
            isHidden = true;
          }
          if (isHidden) continue;

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

  Widget _greyGlassButton({
    required IconData icon,
    required VoidCallback onPressed,
    double size = 24,
    String? tooltip,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey[800]!.withOpacity(0.6),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.3)),
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
                    urlTemplate:
                        'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
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
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.grey[800]!.withOpacity(0.6),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.3),
                        ),
                      ),
                      child: TextField(
                        controller: _searchController,
                        decoration: InputDecoration(
                          hintText: 'Busca usuarios, eventos, negocios...',
                          hintStyle: const TextStyle(color: Colors.white70),
                          prefixIcon: const Icon(
                            Icons.search,
                            color: Colors.white70,
                          ),
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                          suffixIcon: Obx(
                            () => _isSearching.value
                                ? const Padding(
                                    padding: EdgeInsets.all(8.0),
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  )
                                : IconButton(
                                    icon: const Icon(
                                      Icons.clear,
                                      color: Colors.white70,
                                    ),
                                    onPressed: () {
                                      _searchController.clear();
                                      _searchResults.value = {
                                        'users': [],
                                        'events': [],
                                        'businesses': [],
                                      };
                                      _showResults.value = false;
                                      _selectedId.value = '';
                                      _selectedType.value = '';
                                    },
                                  ),
                          ),
                        ),
                        style: const TextStyle(color: Colors.white),
                        onChanged: _performSearch,
                      ),
                    ),

                    if (_showResults.value) _buildSearchResults(),

                    const SizedBox(height: 10),
                    Row(
                      children: [
                        _greyGlassButton(
                          icon: Icons.my_location,
                          onPressed: _centerMapOnMarkers,
                          tooltip: 'Centrar mapa',
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: Row(
                              children: [
                                _filterChip(
                                  'Amigos',
                                  'friends',
                                  AppColors.primary,
                                ),
                                const SizedBox(width: 8),
                                _filterChip('Eventos', 'events', Colors.pink),
                                const SizedBox(width: 8),
                                _filterChip(
                                  'Negocios',
                                  'businesses',
                                  Colors.orange,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              Positioned(
                bottom: 16,
                right: 16,
                child: FloatingActionButton(
                  heroTag: 'minimap',
                  onPressed: () {
                    _isMinimap.value = !_isMinimap.value;
                    Future.delayed(
                      Duration(milliseconds: 300),
                      _centerMapOnMarkers,
                    );
                  },
                  backgroundColor: Colors.white,
                  child: Icon(
                    _isMinimap.value ? Icons.zoom_in_map : Icons.zoom_out_map,
                    color: AppColors.primary,
                    size: 24,
                  ),
                  tooltip: _isMinimap.value
                      ? 'Expandir mapa'
                      : 'Vista península',
                ),
              ),

              Positioned(
                bottom: 86,
                right: 16,
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
                            const CircularProgressIndicator(
                              color: AppColors.primary,
                            ),
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
                    urlTemplate:
                        'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
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
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.grey[800]!.withOpacity(0.6),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.3),
                        ),
                      ),
                      child: TextField(
                        controller: _searchController,
                        decoration: InputDecoration(
                          hintText: 'Search users, events, businesses...',
                          hintStyle: const TextStyle(color: Colors.white70),
                          prefixIcon: const Icon(
                            Icons.search,
                            color: Colors.white70,
                          ),
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                          suffixIcon: Obx(
                            () => _isSearching.value
                                ? const Padding(
                                    padding: EdgeInsets.all(8.0),
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  )
                                : IconButton(
                                    icon: const Icon(
                                      Icons.clear,
                                      color: Colors.white70,
                                    ),
                                    onPressed: () {
                                      _searchController.clear();
                                      _searchResults.value = {
                                        'users': [],
                                        'events': [],
                                        'businesses': [],
                                      };
                                      _showResults.value = false;
                                      _selectedId.value = '';
                                      _selectedType.value = '';
                                    },
                                  ),
                          ),
                        ),
                        style: const TextStyle(color: Colors.white),
                        onChanged: _performSearch,
                      ),
                    ),

                    if (_showResults.value) _buildSearchResults(),

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
                                _filterChip(
                                  'Friends',
                                  'friends',
                                  AppColors.primary,
                                ),
                                const SizedBox(width: 8),
                                _filterChip('Events', 'events', Colors.pink),
                                const SizedBox(width: 8),
                                _filterChip(
                                  'Businesses',
                                  'businesses',
                                  Colors.orange,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              Positioned(
                bottom: 16,
                right: 16,
                child: FloatingActionButton(
                  heroTag: 'minimap',
                  onPressed: () {
                    _isMinimap.value = !_isMinimap.value;
                    Future.delayed(
                      Duration(milliseconds: 300),
                      _centerMapOnMarkers,
                    );
                  },
                  backgroundColor: Colors.white,
                  child: Icon(
                    _isMinimap.value ? Icons.zoom_in_map : Icons.zoom_out_map,
                    color: AppColors.primary,
                    size: 24,
                  ),
                  tooltip: _isMinimap.value
                      ? 'Expandir mapa'
                      : 'Vista península',
                ),
              ),

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
                            const CircularProgressIndicator(
                              color: AppColors.primary,
                            ),
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

  Widget _buildSearchResults() {
    final users = _searchResults['users'] ?? [];
    final events = _searchResults['events'] ?? [];
    final businesses = _searchResults['businesses'] ?? [];

    final totalResults = users.length + events.length + businesses.length;

    if (totalResults == 0) {
      return Container(
        margin: const EdgeInsets.only(top: 8),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.grey[900]!.withOpacity(0.95),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white.withOpacity(0.1)),
        ),
        child: const Text(
          'No results found',
          style: TextStyle(color: Colors.white70),
          textAlign: TextAlign.center,
        ),
      );
    }

    return Container(
      margin: const EdgeInsets.only(top: 8),
      constraints: const BoxConstraints(maxHeight: 300),
      decoration: BoxDecoration(
        color: Colors.grey[900]!.withOpacity(0.95),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: ListView(
        shrinkWrap: true,
        padding: const EdgeInsets.all(8),
        children: [
          if (users.isNotEmpty) ...[
            _buildResultSection('Users', users, Colors.blue, 'user'),
            const Divider(color: Colors.white12),
          ],
          if (events.isNotEmpty) ...[
            _buildResultSection('Events', events, Colors.pink, 'event'),
            const Divider(color: Colors.white12),
          ],
          if (businesses.isNotEmpty) ...[
            _buildResultSection(
              'Businesses',
              businesses,
              Colors.orange,
              'business',
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildResultSection(
    String title,
    List<dynamic> items,
    Color color,
    String type,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Text(
            title,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
        ),
        ...items.map((item) => _buildResultItem(item, color, type)),
      ],
    );
  }

  Widget _buildResultItem(dynamic item, Color color, String type) {
    final String name = type == 'user'
        ? (item['username'] ?? 'Unknown')
        : (item['name'] ?? item['title'] ?? 'Unknown');

    final String? id = item['_id']?.toString();
    final String? status = item['status'];

    return ListTile(
      dense: true,
      leading: Icon(
        type == 'user'
            ? Icons.person
            : (type == 'event' ? Icons.event : Icons.store),
        color: color,
        size: 20,
      ),
      title: Row(
        children: [
          Expanded(
            child: Text(
              name,
              style: const TextStyle(color: Colors.white, fontSize: 14),
            ),
          ),
          if (type == 'user' && status != null && status != 'none')
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: status == 'friends'
                    ? Colors.blue.withOpacity(0.2)
                    : Colors.orange.withOpacity(0.2),
                borderRadius: BorderRadius.circular(4),
                border: Border.all(
                  color: status == 'friends' ? Colors.blue : Colors.orange,
                  width: 0.5,
                ),
              ),
              child: Text(
                status.toUpperCase().replaceAll('_', ' '),
                style: TextStyle(
                  color: status == 'friends' ? Colors.blue : Colors.orange,
                  fontSize: 8,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
        ],
      ),
      trailing: _isItemInMap(id, type)
          ? Icon(Icons.location_on, color: Colors.green, size: 20)
          : null,
      onTap: () => _onResultSelected(item, type),
    );
  }

  bool _isItemInMap(String? id, String type) {
    if (id == null) return false;

    switch (type) {
      case 'user':
        return _mapController.nearbyFriends.any((f) => f.id == id);
      case 'event':
        return _mapController.nearbyEvents.any(
          (e) => e is Map && e['_id']?.toString() == id,
        );
      case 'business':
        return _mapController.nearbyBusinesses.any(
          (b) => b is Map && b['_id']?.toString() == id,
        );
      default:
        return false;
    }
  }

  void _onResultSelected(dynamic item, String type) {
    final String? id = item['_id']?.toString();

    if (id == null) return;

    if (_isItemInMap(id, type)) {
      switch (type) {
        case 'user':
          _activeFilter.value = 'friends';
          break;
        case 'event':
          _activeFilter.value = 'events';
          break;
        case 'business':
          _activeFilter.value = 'businesses';
          break;
      }

      _selectedId.value = id;
      _selectedType.value = type;

      LatLng? coords = _getCoordinates(item, type);

      if (coords != null) {
        _isMinimap.value = false;
        _flutterMapController.move(coords, 15.0);

        _flutterMapController.move(coords, 15.0);
      }
    } else {
      // Not on map, do nothing or show a subtle hint
    }

    _showResults.value = false;
  }

  LatLng? _getCoordinates(dynamic item, String type) {
    try {
      switch (type) {
        case 'user':
          if (item['lat'] != null && item['lng'] != null) {
            return LatLng(
              (item['lat'] as num).toDouble(),
              (item['lng'] as num).toDouble(),
            );
          }
          break;
        case 'event':
        case 'business':
          final coords = item['location']?['coordinates'];
          if (coords is List && coords.length >= 2) {
            return LatLng(
              (coords[1] as num).toDouble(),
              (coords[0] as num).toDouble(),
            );
          }
          break;
      }
    } catch (e) {
      print('❌ Error getting coordinates: $e');
    }
    return null;
  }

  Marker? _createFriendMarker(dynamic friend) {
    try {
      if (friend.lat == null || friend.lng == null) return null;

      final lat = friend.lat as double;
      final lng = friend.lng as double;
      final username = friend.username ?? 'Friend';
      final avatar = friend.safeProfilePictureUrl ?? '';
      final id = friend.id?.toString() ?? '';

      final isSelected =
          _selectedId.value == id && _selectedType.value == 'user';
      final borderColor = isSelected ? Colors.greenAccent : AppColors.primary;

      return Marker(
        point: LatLng(lat, lng),
        width: 70,
        height: 85,
        child: GestureDetector(
          onTap: () {},
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: borderColor,
                    width: isSelected ? 4 : 3,
                  ),
                  color: Colors.black,
                  boxShadow: [
                    BoxShadow(
                      color: borderColor.withOpacity(0.5),
                      blurRadius: isSelected ? 15 : 10,
                    ),
                  ],
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
                  border: Border.all(color: borderColor),
                ),
                child: Text(
                  username,
                  style: TextStyle(
                    color: isSelected ? Colors.greenAccent : Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
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
      return null;
    }
  }

  Marker? _createEventMarker(Map<String, dynamic> event) {
    try {
      final coords = event['location']?['coordinates'];
      if (coords is! List || coords.length < 2) return null;

      final lng = (coords[0] as num).toDouble();
      final lat = (coords[1] as num).toDouble();
      final name = event['name'] ?? event['title'] ?? 'Event';
      final id = event['_id']?.toString() ?? '';

      final isSelected =
          _selectedId.value == id && _selectedType.value == 'event';
      final borderColor = isSelected ? Colors.greenAccent : Colors.pink;

      return Marker(
        point: LatLng(lat, lng),
        width: 60,
        height: 75,
        child: GestureDetector(
          onTap: () {},
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 45,
                height: 45,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: borderColor,
                    width: isSelected ? 4 : 3,
                  ),
                  color: Colors.black,
                  boxShadow: [
                    BoxShadow(
                      color: borderColor.withOpacity(0.5),
                      blurRadius: isSelected ? 15 : 10,
                    ),
                  ],
                ),
                child: Icon(Icons.event, color: borderColor, size: 25),
              ),
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.8),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: borderColor),
                ),
                child: Text(
                  name,
                  style: TextStyle(
                    color: isSelected ? Colors.greenAccent : Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
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
      return null;
    }
  }

  Marker? _createBusinessMarker(Map<String, dynamic> business) {
    try {
      final coords = business['location']?['coordinates'];
      if (coords is! List || coords.length < 2) return null;

      final lng = (coords[0] as num).toDouble();
      final lat = (coords[1] as num).toDouble();
      final name = business['name'] ?? 'Business';
      final id = business['_id']?.toString() ?? '';

      final isSelected =
          _selectedId.value == id && _selectedType.value == 'business';
      final borderColor = isSelected ? Colors.greenAccent : Colors.orange;

      return Marker(
        point: LatLng(lat, lng),
        width: 60,
        height: 75,
        child: GestureDetector(
          onTap: () {},
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 45,
                height: 45,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: borderColor,
                    width: isSelected ? 4 : 3,
                  ),
                  color: Colors.black,
                  boxShadow: [
                    BoxShadow(
                      color: borderColor.withOpacity(0.5),
                      blurRadius: isSelected ? 15 : 10,
                    ),
                  ],
                ),
                child: Icon(Icons.store, color: borderColor, size: 25),
              ),
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.8),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: borderColor),
                ),
                child: Text(
                  name,
                  style: TextStyle(
                    color: isSelected ? Colors.greenAccent : Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
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
          _selectedId.value = '';
          _selectedType.value = '';

          if (_searchController.text.isNotEmpty) {
            _performSearch(_searchController.text);
          }
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
      _searchResults.value = {'users': [], 'events': [], 'businesses': []};
      _showResults.value = false;
      return;
    }

    _isSearching.value = true;
    _showResults.value = true;

    try {
      _searchResults.value = {'users': [], 'events': [], 'businesses': []};

      if (_activeFilter.value == 'friends') {
        final response = await _apiService.get(
          '/friendship/search?search=$query&limit=20',
        );

        List<dynamic> users = [];
        if (response.data is List) {
          users = response.data;
        } else if (response.data is Map && response.data['users'] is List) {
          users = response.data['users'];
        }

        _searchResults['users'] = users;
      } else if (_activeFilter.value == 'events') {
        final response = await _apiService.get('/event?search=$query&limit=20');

        List<dynamic> events = [];
        if (response.data is Map && response.data['events'] is List) {
          events = response.data['events'];
        } else if (response.data is List) {
          events = response.data;
        }

        _searchResults['events'] = events;
      } else if (_activeFilter.value == 'businesses') {
        final response = await _apiService.get(
          '/business?search=$query&limit=20',
        );

        List<dynamic> businesses = [];
        if (response.data is Map && response.data['businesses'] is List) {
          businesses = response.data['businesses'];
        } else if (response.data is List) {
          businesses = response.data;
        }

        _searchResults['businesses'] = businesses;
      }
    } catch (e) {
    } finally {
      _isSearching.value = false;
    }
  }
}
