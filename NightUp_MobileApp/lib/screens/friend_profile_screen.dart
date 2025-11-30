// screens/friend_profile_screen.dart
import 'dart:developer';
import 'package:dio/dio.dart' as dio;
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../services/api_service.dart';
import '../theme/colors.dart';
import '../widgets/glass_card.dart';
import '../widgets/image_with_fallback.dart';

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
  var _friendshipStatus = ''.obs; // 'none', 'pending', 'accepted', 'blocked'
  var _friendshipId = ''.obs;
  var _statusLoading = false.obs;

  @override
  void initState() {
    super.initState();
    _fetchFriendProfile();
    _fetchFriendEvents();
    _fetchFriendshipStatus();
  }

  Future<void> _fetchFriendshipStatus() async {
    _statusLoading.value = true;
    try {
      final response = await _apiService.get('/friendship/status/${widget.friendId}');
      if (response.data is Map && response.data['status'] != null) {
        _friendshipStatus.value = response.data['status'];
        _friendshipId.value = response.data['friendshipId']?.toString() ?? '';
      } else {
        _friendshipStatus.value = 'none';
        _friendshipId.value = '';
      }
    } catch (e) {
      _friendshipStatus.value = 'none';
      _friendshipId.value = '';
    } finally {
      _statusLoading.value = false;
    }
  }

  Future<void> _sendFriendRequest() async {
    try {
      final response = await _apiService.post('/friendship/request', data: {"recipientId": widget.friendId});
      Get.snackbar('Solicitud enviada', 'Tu solicitud de amistad ha sido enviada.');
      await _fetchFriendshipStatus();
    } catch (e) {
      Get.snackbar('Error', 'No se pudo enviar la solicitud.');
    }
  }

  Future<void> _deleteFriend() async {
    try {
      if (_friendshipId.value.isEmpty) return;
      await _apiService.delete('/friendship/friend/${_friendshipId.value}');
      Get.snackbar('Amistad eliminada', 'Has eliminado a este amigo.');
      await _fetchFriendshipStatus();
    } catch (e) {
      Get.snackbar('Error', 'No se pudo eliminar la amistad.');
    }
  }

  Future<void> _fetchFriendProfile() async {
    _isLoading.value = true;
    try {
      final response = await _apiService.get('/user/profile/${widget.friendId}');
      
      // Manejar diferentes formatos de respuesta
      if (response.data is Map<String, dynamic>) {
        _friendData.value = response.data;
      } else {
        _friendData.value = {};
      }
      
      print('✅ Loaded friend profile: ${_friendData['username']}');
    } catch (e) {
      if (e is dio.DioError && e.response != null) {
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
          body: Center(
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
    final avatar = _friendData['avatar']?.toString() ?? '';
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
                  const SizedBox(width: 12),
                  Text(
                    'Trust Score: 4.8⭐',
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        // ... Botón de volver eliminado para dejar solo el del AppBar ...
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
        GlassCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Padding(
                padding: EdgeInsets.all(16),
                child: Text(
                  'Current Location',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Container(
                height: 150,
                margin: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.glassBorder),
                ),
                child: Stack(
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        color: AppColors.glassWhite,
                      ),
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.map, color: Colors.white70, size: 40),
                            const SizedBox(height: 8),
                            Text(
                              _friendData['location'] != null ? 'Location Available' : 'No Location',
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    Positioned(
                      top: 8,
                      right: 8,
                      child: GlassCard(
                        padding: EdgeInsets.zero,
                        child: IconButton(
                          icon: const Icon(Icons.share, color: Colors.white, size: 20),
                          onPressed: () {
                            _shareFriendLocation();
                          },
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        // NUEVO: Lista de eventos en los que participa el amigo
        Obx(() {
          if (_friendEvents.isEmpty) {
            return const SizedBox();
          }
          return GlassCard(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Eventos en los que participa',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 12),
                  ..._friendEvents.map((event) {
                    final title = event['title'] ?? 'Evento';
                    final date = event['formattedDate'] ?? '';
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Row(
                        children: [
                          const Icon(Icons.event, color: Colors.orange, size: 18),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              '$title - $date',
                              style: const TextStyle(color: Colors.white70),
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
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
      // Botón de amistad
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
      // Botón de chat y mapa (si es amigo o no hay relación bloqueada)
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
              onPressed: () {
                Get.snackbar(
                  'Map',
                  'Opening full map view',
                  snackPosition: SnackPosition.BOTTOM,
                );
              },
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.white,
                side: const BorderSide(color: AppColors.glassBorder),
                backgroundColor: AppColors.glassWhite,
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

  void _shareFriendLocation() async {
    final username = _friendData['username']?.toString() ?? 'Friend';
    final city = _friendData['city']?.toString() ?? 'Unknown location';
    final locationText = '$username - $city';
    
    print('📍 Sharing friend location: $locationText');
    Get.snackbar(
      'Location Shared',
      'Friend location copied to clipboard',
      snackPosition: SnackPosition.BOTTOM,
    );
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