// friend_profile_screen.dart
import 'dart:developer';
import 'package:dio/dio.dart' as dio;
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../services/api_service.dart';
import '../theme/colors.dart';
import '../widgets/glass_card.dart';
import '../widgets/image_with_fallback.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

class FriendProfileScreen extends StatefulWidget {
  final String friendId;

  const FriendProfileScreen({super.key, required this.friendId});

  @override
  State<FriendProfileScreen> createState() => _FriendProfileScreenState();
}

class _FriendProfileScreenState extends State<FriendProfileScreen> {
  final ApiService _apiService = Get.find<ApiService>();
  var _isLoading = true.obs;
  var _friendData = <String, dynamic>{}.obs;
  var _friendEvents = [].obs;
  var _friendshipStatus = ''.obs;
  var _friendshipId = ''.obs;
  var _statusLoading = false.obs;
  
  // Trust score
  var _trustScore = 0.0.obs;
  var _totalRatings = 0.obs;
  var _trustLevel = ''.obs;
  var _trustRatings = [].obs;
  
  // Para ubicación
  double? _friendLat;
  double? _friendLng;

  @override
  void initState() {
    super.initState();
    _fetchFriendProfile();
    _fetchFriendEvents();
    _fetchFriendshipStatus();
    _fetchTrustScore();
  }

  Future<void> _fetchTrustScore() async {
    try {
      final response = await _apiService.get('/user-trust/user/summary/${widget.friendId}');
      if (response.data is Map) {
        _trustScore.value = (response.data['averageTrust'] ?? 0.0).toDouble();
        _totalRatings.value = response.data['totalRatings'] ?? 0;
        _trustLevel.value = response.data['trustLevel'] ?? '';
        
        final ratingsResponse = await _apiService.get('/user-trust/user/ratings/${widget.friendId}');
        if (ratingsResponse.data is List) {
          _trustRatings.value = ratingsResponse.data;
        }
        
        log('✅ Trust score loaded: ${_trustScore.value} (${_totalRatings.value} ratings)');
      }
    } catch (e) {
      log('❌ Error loading trust score: $e');
      _trustScore.value = 0.0;
      _totalRatings.value = 0;
    }
  }

  Future<void> _fetchFriendshipStatus() async {
    _statusLoading.value = true;
    try {
      final response = await _apiService.get('/friendship/status/${widget.friendId}');
      
      log('🔍 FRIENDSHIP STATUS RESPONSE: ${response.data}');
      
      if (response.data is Map && response.data['status'] is Map) {
        final statusData = response.data['status'];
        _friendshipStatus.value = statusData['friendshipStatus'] ?? 'none';
        
        // Si son amigos, obtener friendshipId Y ubicación
        if (_friendshipStatus.value == 'accepted') {
          await _getFriendshipDataAndLocation();
        }
        
        log('✅ Friendship status: ${_friendshipStatus.value}');
      } else {
        _friendshipStatus.value = 'none';
        _friendshipId.value = '';
      }
    } catch (e) {
      log('❌ Error loading friendship status: $e');
      _friendshipStatus.value = 'none';
      _friendshipId.value = '';
    } finally {
      _statusLoading.value = false;
    }
  }

  // Obtener friendshipId Y ubicación desde /friendship/friends
  Future<void> _getFriendshipDataAndLocation() async {
    try {
      print('🔍 Getting friendship data and location...');
      final response = await _apiService.get('/friendship/friends');
      
      print('🔍 FRIENDSHIP/FRIENDS RESPONSE:');
      print('   Type: ${response.data.runtimeType}');
      print('   Is List: ${response.data is List}');
      
      if (response.data is List) {
        print('   List length: ${response.data.length}');
        
        for (var friendship in response.data) {
          final recipient = friendship['recipient'];
          final requester = friendship['requester'];
          
          print('   Checking friendship:');
          print('      recipient._id: ${recipient?['_id']}');
          print('      requester._id: ${requester?['_id']}');
          print('      Looking for: ${widget.friendId}');
          
          // Buscar el amigo en recipient o requester
          Map<String, dynamic>? friendData;
          
          if (recipient != null && recipient['_id'] == widget.friendId) {
            print('   ✅ FOUND in recipient!');
            _friendshipId.value = friendship['_id'];
            friendData = recipient;
          } else if (requester != null && requester['_id'] == widget.friendId) {
            print('   ✅ FOUND in requester!');
            _friendshipId.value = friendship['_id'];
            friendData = requester;
          }
          
          // Si encontramos al amigo, extraer su ubicación
          if (friendData != null) {
            log('✅ Friendship ID found: ${_friendshipId.value}');
            
            print('   🔍 Friend data:');
            print('      location: ${friendData['location']}');
            print('      location type: ${friendData['location']?.runtimeType}');
            
            // Extraer ubicación
            if (friendData['location'] is Map) {
              final location = friendData['location'] as Map;
              print('      coordinates: ${location['coordinates']}');
              print('      coordinates type: ${location['coordinates']?.runtimeType}');
              
              if (location['coordinates'] is List) {
                final coords = location['coordinates'] as List;
                print('      ✅ coordinates is List with ${coords.length} elements');
                
                if (coords.length >= 2) {
                  _friendLng = (coords[0] as num).toDouble();
                  _friendLat = (coords[1] as num).toDouble();
                  print('      ✅ EXTRACTED: lat=$_friendLat, lng=$_friendLng');
                  log('✅ Friend location extracted: lat=$_friendLat, lng=$_friendLng');
                } else {
                  print('      ❌ coords.length < 2');
                }
              } else {
                print('      ❌ coordinates is NOT a List');
              }
            } else {
              print('      ❌ location is NOT a Map');
            }
            return;
          }
        }
        print('   ❌ Friend not found in list');
      } else {
        print('   ❌ Response is NOT a List');
      }
    } catch (e) {
      log('❌ Error getting friendship data and location: $e');
      print('❌ Exception: $e');
    }
  }

  Future<void> _sendFriendRequest() async {
    try {
      await _apiService.post('/friendship/request', data: {"recipientId": widget.friendId});
      Get.snackbar('Solicitud enviada', 'Tu solicitud de amistad ha sido enviada.');
      await _fetchFriendshipStatus();
    } catch (e) {
      Get.snackbar('Error', 'No se pudo enviar la solicitud.');
    }
  }

  Future<void> _deleteFriend() async {
    try {
      if (_friendshipId.value.isEmpty) {
        Get.snackbar('Error', 'No se pudo encontrar la amistad');
        return;
      }
      await _apiService.delete('/friendship/friend/${_friendshipId.value}');
      Get.snackbar('Amistad eliminada', 'Has eliminado a este amigo.');
      
      // Limpiar ubicación al eliminar amigo
      _friendLat = null;
      _friendLng = null;
      
      await _fetchFriendshipStatus();
    } catch (e) {
      Get.snackbar('Error', 'No se pudo eliminar la amistad.');
    }
  }

  Future<void> _fetchFriendProfile() async {
    _isLoading.value = true;
    try {
      final response = await _apiService.get('/user/profile/${widget.friendId}');
      if (response.data is Map<String, dynamic>) {
        _friendData.value = response.data;
      } else {
        _friendData.value = {};
      }
      log('✅ Loaded friend profile: ${_friendData['username']}');
    } catch (e) {
      _friendData.value = {};
      if (e is dio.DioException && e.response != null) {
        if (e.response?.statusCode == 401) {
          log('🔐 Sesión expirada. Por favor inicia sesión de nuevo.');
          Get.snackbar('Sesión expirada', 'Por favor inicia sesión de nuevo');
        } else if (e.response?.statusCode == 404) {
          log('❌ Recurso no encontrado (404)');
          Get.snackbar('No encontrado', 'El usuario no existe o fue eliminado');
        } else {
          log('❌ Error loading friend profile: $e');
          Get.snackbar('Error', 'No se pudo cargar el perfil');
        }
      } else {
        log('❌ Error loading friend profile: $e');
        Get.snackbar('Error', 'No se pudo cargar el perfil');
      }
    } finally {
      _isLoading.value = false;
    }
  }

  Future<void> _fetchFriendEvents() async {
    try {
      final response = await _apiService.get('/event/by-participant/${widget.friendId}');
      if (response.data is Map && response.data['events'] is List) {
        _friendEvents.value = response.data['events'];
        log('✅ Loaded ${_friendEvents.length} events for friend');
      } else if (response.data is List) {
        _friendEvents.value = response.data;
      } else {
        _friendEvents.value = [];
      }
    } catch (e) {
      log('❌ Error loading friend events: $e');
      _friendEvents.value = [];
    }
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      if (_isLoading.value) {
        return const Scaffold(
          backgroundColor: Colors.black,
          body: Center(child: CircularProgressIndicator(color: AppColors.primary)),
        );
      }

      if (_friendData.isEmpty) {
        return Scaffold(
          backgroundColor: Colors.black,
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white),
              onPressed: () => Get.back(),
            ),
          ),
          body: const Center(
            child: Text(
              'Friend not found',
              style: TextStyle(color: Colors.white70),
            ),
          ),
        );
      }

      return Scaffold(
        backgroundColor: Colors.black,
        body: NestedScrollView(
          headerSliverBuilder: (context, innerBoxIsScrolled) {
            return [
              SliverAppBar(
                expandedHeight: 250,
                collapsedHeight: 100,
                floating: false,
                pinned: true,
                backgroundColor: Colors.transparent,
                flexibleSpace: _buildProfileHeader(),
              ),
            ];
          },
          body: _buildProfileInfo(),
        ),
        bottomNavigationBar: _buildActionButtons(),
      );
    });
  }

  Widget _buildProfileHeader() {
    final username = _friendData['username']?.toString() ?? 'Unknown User';
    final coverPhoto = _friendData['coverPhoto']?.toString() ?? '';
    final isOnline = _friendData['isOnline'] == true;

    return Stack(
      children: [
        Container(
          width: double.infinity,
          height: double.infinity,
          child: ImageWithFallback(
            imageUrl: coverPhoto,
            fallbackAsset: 'assets/images/default-cover.jpg',
            fit: BoxFit.cover,
          ),
        ),
        Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.transparent,
                Colors.transparent,
                Colors.black.withOpacity(0.9),
              ],
            ),
          ),
        ),
        Positioned(
          bottom: 20,
          left: 20,
          right: 20,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                username,
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: isOnline ? Colors.green.withOpacity(0.2) : Colors.grey.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: isOnline ? Colors.green : Colors.grey,
                      ),
                    ),
                    child: Text(
                      isOnline ? 'Online' : 'Offline',
                      style: TextStyle(
                        color: isOnline ? Colors.green : Colors.grey,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildProfileInfo() {
    final email = _friendData['email']?.toString() ?? 'No email';
    final phone = _friendData['phoneNumber']?.toString() ?? 'No phone';
    final bio = _friendData['bio']?.toString() ?? 'No bio yet';
    final city = _friendData['city']?.toString() ?? 'Unknown city';
    final country = _friendData['country']?.toString() ?? 'Unknown country';

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        GlassCard(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Contact Information',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 16),
                _buildContactItem(Icons.email, email),
                const SizedBox(height: 12),
                _buildContactItem(Icons.phone, phone),
                const SizedBox(height: 12),
                _buildContactItem(Icons.location_on, '$city, $country'),
                const SizedBox(height: 12),
                _buildContactItem(Icons.info, bio),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        
        // Trust Score
        Obx(() => GlassCard(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Valoraciones de confianza',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 16),
                if (_totalRatings.value > 0) ...[
                  Row(
                    children: [
                      const Icon(Icons.star, color: Colors.amber, size: 28),
                      const SizedBox(width: 8),
                      Text(
                        _trustScore.value.toStringAsFixed(1),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '(${_totalRatings.value} ${_totalRatings.value == 1 ? "valoración" : "valoraciones"})',
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  ...(_trustRatings.take(3).map((rating) {
                    final raterUsername = rating['rater']?['username'] ?? 'Usuario';
                    final score = rating['score'] ?? 0;
                    final comment = rating['comment'] ?? '';
                    
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: List.generate(5, (index) => 
                              Icon(
                                index < score ? Icons.star : Icons.star_border,
                                color: Colors.amber,
                                size: 16,
                              )
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  raterUsername,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                if (comment.isNotEmpty)
                                  Text(
                                    comment,
                                    style: const TextStyle(
                                      color: Colors.white70,
                                      fontSize: 12,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList()),
                ] else ...[
                  Row(
                    children: [
                      const Icon(Icons.star_border, color: Colors.grey, size: 28),
                      const SizedBox(width: 8),
                      const Text(
                        'Sin valoraciones',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 18,
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        )),
        
        const SizedBox(height: 16),
        
        // Eventos
        Obx(() {
          if (_friendEvents.isEmpty) {
            return const GlassCard(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Eventos en los que participa',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    SizedBox(height: 12),
                    Row(
                      children: [
                        Icon(Icons.event_busy, color: Colors.grey, size: 18),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Este usuario no participa en ningún evento todavía.',
                            style: TextStyle(color: Colors.white54, fontSize: 16),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          }
          return GlassCard(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Eventos en los que participa (${_friendEvents.length})',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 12),
                  ..._friendEvents.take(5).map((event) {
                    final title = event['name'] ?? 'Evento';
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Row(
                        children: [
                          const Icon(Icons.event, color: Colors.orange, size: 18),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              title,
                              style: const TextStyle(color: Colors.white70),
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                  if (_friendEvents.length > 5) ...[
                    const SizedBox(height: 8),
                    Text(
                      '+ ${_friendEvents.length - 5} eventos más',
                      style: const TextStyle(
                        color: AppColors.primary,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          );
        }),
      ],
    );
  }

  Widget _buildContactItem(IconData icon, String text) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: AppColors.primary, size: 20),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 16,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildActionButtons() {
    return Obx(() {
      if (_statusLoading.value) {
        return const Padding(
          padding: EdgeInsets.all(16),
          child: Center(child: CircularProgressIndicator()),
        );
      }
      
      List<Widget> buttons = [];
      
      if (_friendshipStatus.value == 'accepted') {
        buttons.add(
          Expanded(
            child: OutlinedButton.icon(
              onPressed: _deleteFriend,
              icon: const Icon(Icons.person_remove, color: Colors.red),
              label: const Text('Eliminar amigo', style: TextStyle(color: Colors.red)),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.red,
                side: const BorderSide(color: Colors.red),
                backgroundColor: Colors.red.withOpacity(0.1),
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
        );
      } else if (_friendshipStatus.value == 'pending') {
        buttons.add(
          Expanded(
            child: OutlinedButton.icon(
              onPressed: null,
              icon: const Icon(Icons.hourglass_empty, color: Colors.amber),
              label: const Text('Solicitud pendiente', style: TextStyle(color: Colors.amber)),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.amber,
                side: const BorderSide(color: Colors.amber),
                backgroundColor: Colors.amber.withOpacity(0.1),
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
        );
      } else if (_friendshipStatus.value == 'none') {
        buttons.add(
          Expanded(
            child: OutlinedButton.icon(
              onPressed: _sendFriendRequest,
              icon: const Icon(Icons.person_add, color: Colors.green),
              label: const Text('Agregar amigo', style: TextStyle(color: Colors.green)),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.green,
                side: const BorderSide(color: Colors.green),
                backgroundColor: Colors.green.withOpacity(0.1),
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
        );
      } else if (_friendshipStatus.value == 'blocked') {
        buttons.add(
          Expanded(
            child: OutlinedButton.icon(
              onPressed: null,
              icon: const Icon(Icons.block, color: Colors.grey),
              label: const Text('Usuario bloqueado', style: TextStyle(color: Colors.grey)),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.grey,
                side: const BorderSide(color: Colors.grey),
                backgroundColor: Colors.grey.withOpacity(0.1),
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
        );
      }
      
      if (_friendshipStatus.value != 'blocked') {
        buttons.add(const SizedBox(width: 12));
        buttons.add(
          Expanded(
            child: OutlinedButton(
              onPressed: _openChat,
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.white,
                side: const BorderSide(color: AppColors.glassBorder),
                backgroundColor: AppColors.glassWhite,
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.chat, size: 16),
                  SizedBox(width: 8),
                  Text('Message'),
                ],
              ),
            ),
          ),
        );
        buttons.add(const SizedBox(width: 12));
        
        buttons.add(
          Expanded(
            child: OutlinedButton(
              onPressed: _friendLat != null && _friendLng != null
                  ? () async {
                      final userId = _apiService.getUserId();
                      double? myLat;
                      double? myLng;
                      
                      try {
                        final resp = await _apiService.get('/friendship/friends');
                        if (resp.data is List) {
                          for (var friendship in resp.data) {
                            final requester = friendship['requester'];
                            if (requester != null && requester['_id'] == userId) {
                              if (requester['location'] is Map && 
                                  requester['location']['coordinates'] is List) {
                                final coords = requester['location']['coordinates'] as List;
                                if (coords.length >= 2) {
                                  myLng = (coords[0] as num).toDouble();
                                  myLat = (coords[1] as num).toDouble();
                                  break;
                                }
                              }
                            }
                          }
                        }
                      } catch (e) {
                        log('❌ Error getting my location: $e');
                      }
                      
                      if (myLat != null && myLng != null) {
                        Get.to(() => FriendMapScreen(
                          friendUsername: _friendData['username']?.toString() ?? 'Friend',
                          friendLat: _friendLat!,
                          friendLng: _friendLng!,
                          myLat: myLat!,
                          myLng: myLng!,
                        ));
                      } else {
                        Get.snackbar(
                          'Error',
                          'No se pudo obtener tu ubicación',
                          backgroundColor: Colors.red.withOpacity(0.8),
                          colorText: Colors.white,
                        );
                      }
                    }
                  : () {
                      Get.snackbar(
                        'Ubicación no disponible',
                        _friendshipStatus.value == 'accepted' 
                            ? 'Este amigo no tiene una ubicación registrada'
                            : 'Solo puedes ver la ubicación de tus amigos',
                        backgroundColor: Colors.orange.withOpacity(0.8),
                        colorText: Colors.white,
                      );
                    },
              style: OutlinedButton.styleFrom(
                foregroundColor: _friendLat != null && _friendLng != null 
                    ? Colors.white 
                    : Colors.grey,
                side: BorderSide(
                  color: _friendLat != null && _friendLng != null 
                      ? AppColors.glassBorder 
                      : Colors.grey,
                ),
                backgroundColor: _friendLat != null && _friendLng != null 
                    ? AppColors.glassWhite 
                    : Colors.grey.withOpacity(0.2),
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.map, size: 16),
                  SizedBox(width: 8),
                  Text('View Map'),
                ],
              ),
            ),
          ),
        );
      }
      
      return Container(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: buttons,
        ),
      );
    });
  }

  void _openChat() {
    final username = _friendData['username']?.toString() ?? 'Friend';
    print('💬 Opening chat with $username');
    Get.snackbar(
      'Chat',
      'Opening chat with $username',
      snackPosition: SnackPosition.BOTTOM,
    );
  }
}

// ============================================================================
// FriendMapScreen - Pantalla de mapa con controles
// ============================================================================

class FriendMapScreen extends StatefulWidget {
  final String friendUsername;
  final double friendLat;
  final double friendLng;
  final double myLat;
  final double myLng;

  const FriendMapScreen({
    super.key,
    required this.friendUsername,
    required this.friendLat,
    required this.friendLng,
    required this.myLat,
    required this.myLng,
  });

  @override
  State<FriendMapScreen> createState() => _FriendMapScreenState();
}

class _FriendMapScreenState extends State<FriendMapScreen> {
  final MapController _mapController = MapController();
  var _isExpanded = false.obs;
  var _currentZoom = 13.0.obs;

  void _zoomIn() {
    _currentZoom.value = (_currentZoom.value + 1).clamp(1.0, 18.0);
    _mapController.move(_mapController.camera.center, _currentZoom.value);
  }

  void _zoomOut() {
    _currentZoom.value = (_currentZoom.value - 1).clamp(1.0, 18.0);
    _mapController.move(_mapController.camera.center, _currentZoom.value);
  }

  void _toggleExpand() {
    _isExpanded.value = !_isExpanded.value;
  }

  @override
  Widget build(BuildContext context) {
    final markers = [
      Marker(
        point: LatLng(widget.friendLat, widget.friendLng),
        width: 100,
        height: 60,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.person_pin_circle, color: Colors.red, size: 40),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.7),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                widget.friendUsername,
                style: const TextStyle(color: Colors.white, fontSize: 11),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
      Marker(
        point: LatLng(widget.myLat, widget.myLng),
        width: 60,
        height: 60,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.person_pin, color: Colors.blue, size: 40),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.7),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text(
                'Tú',
                style: TextStyle(color: Colors.white, fontSize: 11),
              ),
            ),
          ],
        ),
      ),
    ];

    final centerLat = (widget.friendLat + widget.myLat) / 2;
    final centerLng = (widget.friendLng + widget.myLng) / 2;

    return Scaffold(
      backgroundColor: Colors.black,
      body: Obx(() => Stack(
        children: [
          // Mapa
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
              height: _isExpanded.value 
                  ? MediaQuery.of(context).size.height 
                  : 300,
              child: FlutterMap(
                mapController: _mapController,
                options: MapOptions(
                  initialCenter: LatLng(centerLat, centerLng),
                  initialZoom: _currentZoom.value,
                ),
                children: [
                  TileLayer(
                    urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                    userAgentPackageName: 'com.nightup.app',
                  ),
                  MarkerLayer(markers: markers),
                ],
              ),
            ),
          ),

          // Header con botón de cerrar
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: EdgeInsets.only(
                top: MediaQuery.of(context).padding.top + 8,
                left: 16,
                right: 16,
                bottom: 16,
              ),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withOpacity(0.7),
                    Colors.transparent,
                  ],
                ),
              ),
              child: Row(
                children: [
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.6),
                      shape: BoxShape.circle,
                    ),
                    child: IconButton(
                      icon: const Icon(Icons.arrow_back, color: Colors.white),
                      onPressed: () => Get.back(),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Ubicación - ${widget.friendUsername}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Controles de zoom (dentro del área del mapa, abajo a la derecha)
          Positioned(
            top: _isExpanded.value ? null : 220,
            bottom: _isExpanded.value ? 20 : null,
            right: 16,
            child: Column(
              children: [
                // Botón expandir/minimizar
                Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  decoration: BoxDecoration(
                    color: Colors.grey[850]?.withOpacity(0.9),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: AppColors.glassBorder,
                      width: 1,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: _toggleExpand,
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        width: 48,
                        height: 48,
                        alignment: Alignment.center,
                        child: Icon(
                          _isExpanded.value 
                              ? Icons.fullscreen_exit 
                              : Icons.fullscreen,
                          color: Colors.white,
                          size: 24,
                        ),
                      ),
                    ),
                  ),
                ),
                
                // Botón zoom in
                Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  decoration: BoxDecoration(
                    color: Colors.grey[850]?.withOpacity(0.9),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: AppColors.glassBorder,
                      width: 1,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: _zoomIn,
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        width: 48,
                        height: 48,
                        alignment: Alignment.center,
                        child: const Icon(
                          Icons.add,
                          color: Colors.white,
                          size: 24,
                        ),
                      ),
                    ),
                  ),
                ),
                
                // Botón zoom out
                Container(
                  decoration: BoxDecoration(
                    color: Colors.grey[850]?.withOpacity(0.9),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: AppColors.glassBorder,
                      width: 1,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: _zoomOut,
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        width: 48,
                        height: 48,
                        alignment: Alignment.center,
                        child: const Icon(
                          Icons.remove,
                          color: Colors.white,
                          size: 24,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Información adicional cuando está minimizado
          if (!_isExpanded.value)
            Positioned(
              top: 300,
              left: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: const BoxDecoration(
                  color: Colors.black,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Detalles de ubicación',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    GlassCard(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Icon(
                                  Icons.person_pin_circle,
                                  color: Colors.red,
                                  size: 24,
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        widget.friendUsername,
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 16,
                                          fontWeight: FontWeight.w600,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        'Lat: ${widget.friendLat.toStringAsFixed(6)}, Lng: ${widget.friendLng.toStringAsFixed(6)}',
                                        style: TextStyle(
                                          color: Colors.grey[400],
                                          fontSize: 12,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            const Divider(color: Colors.grey, height: 1),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                const Icon(
                                  Icons.person_pin,
                                  color: Colors.blue,
                                  size: 24,
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Text(
                                        'Tu ubicación',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 16,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        'Lat: ${widget.myLat.toStringAsFixed(6)}, Lng: ${widget.myLng.toStringAsFixed(6)}',
                                        style: TextStyle(
                                          color: Colors.grey[400],
                                          fontSize: 12,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      )),
    );
  }
}