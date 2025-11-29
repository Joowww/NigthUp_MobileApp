// screens/search_screen.dart
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

  final my_map.MapController _mapController = Get.find<my_map.MapController>();
  final ApiService _apiService = Get.find<ApiService>();
  final TextEditingController _searchController = TextEditingController();

  final _searchResults = [].obs;
  final _isSearching = false.obs;

  // Filtros visuales
  final RxBool _showFriends = true.obs;
  final RxBool _showUsers = false.obs;
  final RxBool _showEvents = false.obs;
  final RxBool _showBusinesses = false.obs;

  RxBool get _isVisibleOnMap => _mapController.isVisibleOnMap;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // ------------------- MAPA -------------------
          Obx(() {
            final List<Marker> markers = [];
            // Amigos
            if (_showFriends.value) {
              for (var friend in _mapController.getFriendsAsMap()) {
                final marker = _createMarker(friend, type: 'friend');
                if (marker != null) markers.add(marker);
              }
            }
            // Usuarios
            if (_showUsers.value) {
              for (var user in _mapController.getUsersAsMap()) {
                final marker = _createMarker(user, type: 'user');
                if (marker != null) markers.add(marker);
              }
            }
            // Eventos
            if (_showEvents.value) {
              for (var event in _mapController.nearbyEvents.whereType<Map<String, dynamic>>()) {
                final marker = _createMarker(event, type: 'event');
                if (marker != null) markers.add(marker);
              }
            }
            // Negocios
            if (_showBusinesses.value) {
              for (var biz in _mapController.nearbyBusinesses.whereType<Map<String, dynamic>>()) {
                final marker = _createMarker(biz, type: 'business');
                if (marker != null) markers.add(marker);
              }
            }
            // Mi posición
            markers.add(
              Marker(
                point: LatLng(
                  _mapController.currentPosition.value.latitude,
                  _mapController.currentPosition.value.longitude,
                ),
                width: 40,
                height: 40,
                child: Container(
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.3),
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColors.primary, width: 2),
                  ),
                  child: Center(
                    child: Container(
                      width: 15,
                      height: 15,
                      decoration: const BoxDecoration(
                        color: AppColors.primary,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                ),
              ),
            );
            return FlutterMap(
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
                MarkerLayer(markers: markers),
              ],
            );
          }),
          // ------------------- BARRA DE BÚSQUEDA Y FILTROS -------------------
          Positioned(
            top: 16,
            left: 16,
            right: 16,
            child: Column(
              children: [
                GlassCard(
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'Search users, events...',
                      hintStyle: const TextStyle(color: Colors.white70),
                      prefixIcon: const Icon(Icons.search, color: Colors.white70),
                      border: InputBorder.none,
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
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _filterChip('Amigos', _showFriends, AppColors.primary),
                      const SizedBox(width: 8),
                      _filterChip('Usuarios', _showUsers, Colors.blue),
                      const SizedBox(width: 8),
                      _filterChip('Eventos', _showEvents, Colors.pink),
                      const SizedBox(width: 8),
                      _filterChip('Negocios', _showBusinesses, Colors.orange),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Helper para construir los marcadores de forma segura
  Marker? _createMarker(dynamic data, {required String type}) {
    if (data['location'] == null || data['location']['coordinates'] == null) return null;
    final coords = data['location']['coordinates'];
    if (coords is! List || coords.length < 2) return null;
    final lat = (coords[1] as num).toDouble();
    final lng = (coords[0] as num).toDouble();
    String imageUrl = '';
    String title = '';
    Color borderColor = Colors.white;
    IconData? icon;
    switch (type) {
      case 'friend':
      case 'user':
        imageUrl = data['profilePicture'] ?? data['profilePictureUrl'] ?? '';
        title = data['username'] ?? 'User';
        borderColor = type == 'friend' ? AppColors.primary : Colors.blue;
        break;
      case 'event':
        imageUrl = data['image'] ?? '';
        title = data['title'] ?? data['name'] ?? 'Event';
        borderColor = Colors.pink;
        icon = Icons.event;
        break;
      case 'business':
        imageUrl = data['logo'] ?? '';
        title = data['name'] ?? 'Business';
        borderColor = Colors.orange;
        icon = Icons.store;
        break;
    }
    return Marker(
      point: LatLng(lat, lng),
      width: 80,
      height: 90,
      child: GestureDetector(
        onTap: () {
          Get.snackbar("Info", "Tocaste a $title");
        },
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: borderColor, width: 2),
                color: Colors.black,
                boxShadow: [BoxShadow(color: borderColor.withOpacity(0.5), blurRadius: 8)],
              ),
              child: ClipOval(
                child: imageUrl.isNotEmpty
                    ? Image.network(imageUrl, fit: BoxFit.cover, errorBuilder: (_,__,___) => const Icon(Icons.person, color: Colors.white))
                    : (icon != null 
                        ? Icon(icon, color: borderColor, size: 30) 
                        : const Icon(Icons.person, color: Colors.white)),
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
                title,
                style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _filterChip(String label, RxBool value, Color activeColor) {
    return Obx(() => FilterChip(
      label: Text(label),
      selected: value.value,
      onSelected: (v) => value.value = v,
      backgroundColor: Colors.black.withOpacity(0.6),
      selectedColor: activeColor.withOpacity(0.3),
      labelStyle: TextStyle(
        color: value.value ? activeColor : Colors.white70,
        fontWeight: value.value ? FontWeight.bold : FontWeight.normal,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: value.value ? activeColor : Colors.white24),
      ),
      showCheckmark: false,
    ));
  }

  // ============================================================
  //                 FRIEND MAP MODAL
  // ============================================================
  void _showFriendMapModal(BuildContext context, Map friend) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) {
        return Container(
          margin: const EdgeInsets.all(24),
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.black87,
            borderRadius: BorderRadius.circular(24),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircleAvatar(
                radius: 40,
                backgroundImage: NetworkImage(friend['profilePictureUrl'] ?? ''),
                backgroundColor: Colors.grey[800],
              ),
              const SizedBox(height: 12),
              Text(
                friend['username'] ?? 'Unknown',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                icon: const Icon(Icons.person, color: Colors.white),
                label: const Text(
                  'Ver perfil',
                  style: TextStyle(color: Colors.white),
                ),
                onPressed: () {
                  final friendId = friend['_id'] ?? friend['id'];
                  if (friendId != null) {
                    Navigator.of(context).pop();
                    Get.to(() =>
                        FriendProfileScreen(friendId: friendId.toString()));
                  }
                },
              ),
            ],
          ),
        );
      },
    );
  }

  // ============================================================
  //                 USER CARD
  // ============================================================
  Widget _buildUserCard(dynamic user) {
    final userMap =
        user is Map<String, dynamic> ? user : <String, dynamic>{};

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: GlassCard(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Stack(
                children: [
                  Container(
                    width: 50,
                    height: 50,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(25),
                      child: ImageWithFallback(
                        imageUrl:
                            userMap['avatar'] ?? userMap['profilePictureUrl'] ?? '',
                        fallbackAsset: 'assets/images/default-avatar.png',
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        color: (userMap['isOnline'] ?? false)
                            ? Colors.green
                            : Colors.grey,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: AppColors.surface,
                          width: 2,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      userMap['username'] ?? 'Unknown User',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      (userMap['isOnline'] ?? false) ? 'Online' : 'Offline',
                      style: TextStyle(
                        color: (userMap['isOnline'] ?? false)
                            ? Colors.green
                            : Colors.grey,
                        fontSize: 12,
                      ),
                    ),
                    if (userMap['city'] != null || userMap['country'] != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        '${userMap['city'] ?? ''}'
                        '${userMap['city'] != null && userMap['country'] != null ? ', ' : ''}'
                        '${userMap['country'] ?? ''}',
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              Row(
                children: [
                  IconButton(
                    onPressed: () {
                      final friendId = userMap['_id'] ?? userMap['id'];
                      if (friendId != null) {
                        Get.to(() =>
                            FriendProfileScreen(friendId: friendId.toString()));
                      }
                    },
                    icon: const Icon(Icons.person,
                        color: Colors.white70, size: 20),
                  ),
                  IconButton(
                    onPressed: () => _openChatWithUser(userMap),
                    icon: const Icon(Icons.chat,
                        color: Colors.white70, size: 20),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ============================================================
  //                 EMPTY SEARCH
  // ============================================================
  Widget _buildEmptySearch() {
    return Center(
      child: GlassCard(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.search_off, size: 64, color: Colors.white70),
              const SizedBox(height: 16),
              const Text(
                'No Users Found',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'No users found for "${_searchController.text}"',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ============================================================
  //                 SEARCH FUNCTION
  // ============================================================
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

  // ============================================================
  //                 OPEN CHAT
  // ============================================================
  void _openChatWithUser(Map<String, dynamic> user) {
    final username = user['username'] ?? 'User';
    Get.snackbar(
      'Chat',
      'Opening chat with $username',
      snackPosition: SnackPosition.BOTTOM,
    );
  }
}
