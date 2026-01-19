//menu_modal.dart
import '../screens/friend_profile_screen.dart';
import '../screens/chat_screen.dart';
import '../controllers/chat_controller.dart';
import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/menu_modal_controller.dart';
import '../theme/colors.dart';
import '../widgets/glass_card.dart';
import '../widgets/image_with_fallback.dart';
import '../models/business.dart';
import '../models/event.dart';
import '../models/friend.dart';
import '../screens/full_map_screen.dart';

class MenuModal extends StatelessWidget {
  const MenuModal({super.key});

  @override
  Widget build(BuildContext context) {
    final MenuModalController controller = Get.put(MenuModalController());

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          GestureDetector(
            onTap: () => Get.back(),
            child: Container(color: Colors.black54),
          ),
          Align(
            alignment: Alignment.centerRight,
            child: Container(
              width: MediaQuery.of(context).size.width * 0.85,
              height: double.infinity,
              decoration: BoxDecoration(
                color: Colors.grey[850],
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(20),
                  bottomLeft: Radius.circular(20),
                ),
              ),
              child: SizedBox.expand(
                child: Column(
                  children: [
                    // HEADER NEÓN CYBERPUNK
                    Container(
                      padding: const EdgeInsets.symmetric(
                        vertical: 30,
                        horizontal: 20,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black,
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(20),
                        ),
                        border: Border(
                          bottom: BorderSide(
                            color: AppColors.primary.withOpacity(0.5),
                            width: 1,
                          ),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primary.withOpacity(0.3),
                            blurRadius: 20,
                            spreadRadius: 2,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Stack(
                        children: [
                          // Partículas decorativas de fondo
                          Positioned(
                            right: 20,
                            top: 10,
                            child: Row(
                              children: List.generate(
                                3,
                                (index) => Container(
                                  width: 6,
                                  height: 6,
                                  margin: const EdgeInsets.only(left: 8),
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: AppColors.primary.withOpacity(0.6),
                                    boxShadow: [
                                      BoxShadow(
                                        color: AppColors.primary.withOpacity(
                                          0.8,
                                        ),
                                        blurRadius: 8,
                                        spreadRadius: 2,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),

                          // Contenido principal
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  // Botón cerrar con neón
                                  Container(
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: AppColors.primary,
                                        width: 2,
                                      ),
                                      boxShadow: [
                                        BoxShadow(
                                          color: AppColors.primary.withOpacity(
                                            0.5,
                                          ),
                                          blurRadius: 10,
                                          spreadRadius: 2,
                                        ),
                                      ],
                                    ),
                                    child: IconButton(
                                      onPressed: () => Get.back(),
                                      icon: const Icon(
                                        Icons.close,
                                        color: Colors.white,
                                        size: 20,
                                      ),
                                      padding: EdgeInsets.zero,
                                      constraints: const BoxConstraints(
                                        minWidth: 36,
                                        minHeight: 36,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 20),

                                  // Barra vertical decorativa
                                  Container(
                                    width: 3,
                                    height: 40,
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        begin: Alignment.topCenter,
                                        end: Alignment.bottomCenter,
                                        colors: [
                                          AppColors.primary,
                                          AppColors.secondary,
                                        ],
                                      ),
                                      boxShadow: [
                                        BoxShadow(
                                          color: AppColors.primary.withOpacity(
                                            0.6,
                                          ),
                                          blurRadius: 8,
                                          spreadRadius: 1,
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 16),

                                  // Texto EXPLORE
                                  Expanded(
                                    child: ShaderMask(
                                      shaderCallback: (bounds) =>
                                          LinearGradient(
                                            colors: [
                                              AppColors.primary,
                                              AppColors.secondary,
                                              AppColors.primary,
                                            ],
                                          ).createShader(bounds),
                                      child: const Text(
                                        'E X P L O R E',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 22,
                                          fontWeight: FontWeight.w900,
                                          letterSpacing: 4,
                                          shadows: [
                                            Shadow(
                                              color: AppColors.primary,
                                              blurRadius: 20,
                                            ),
                                            Shadow(
                                              color: AppColors.primary,
                                              blurRadius: 40,
                                            ),
                                            Shadow(
                                              color: AppColors.secondary,
                                              blurRadius: 60,
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),

                              const SizedBox(height: 12),

                              // Barra decorativa inferior con gradiente neón
                              Padding(
                                padding: const EdgeInsets.only(left: 76),
                                child: Container(
                                  height: 2,
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: [
                                        AppColors.primary,
                                        AppColors.secondary,
                                        Colors.transparent,
                                      ],
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: AppColors.primary.withOpacity(
                                          0.6,
                                        ),
                                        blurRadius: 10,
                                        spreadRadius: 1,
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

                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Obx(
                        () => Row(
                          children: [
                            _buildTabButton('Businesses', 0, controller),
                            _buildTabButton('Events', 1, controller),
                            _buildTabButton('Friends', 2, controller),
                          ],
                        ),
                      ),
                    ),
                    Expanded(
                      child: Obx(() {
                        if (controller.currentTab.value == 0) {
                          return _buildBusinessesTab(controller);
                        } else if (controller.currentTab.value == 1) {
                          return _buildEventsTab(controller);
                        } else {
                          return _buildFriendsTab(controller);
                        }
                      }),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabButton(
    String text,
    int index,
    MenuModalController controller,
  ) {
    final isSelected = controller.currentTab.value == index;
    return Expanded(
      child: GestureDetector(
        onTap: () => controller.changeTab(index),
        child: Container(
          margin: const EdgeInsets.all(4),
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.glassWhite : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: isSelected ? AppColors.primary : Colors.transparent,
            ),
          ),
          child: Text(
            text,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBusinessesTab(MenuModalController controller) {
    return Obx(() {
      final businesses = controller.businesses;
      if (controller.isLoadingBusinesses.value) {
        return const Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        );
      }
      if (businesses.isEmpty) {
        return _buildEmptyState(
          Icons.business_center,
          'No Businesses Found',
          'There are no businesses available at the moment.',
        );
      }
      return RefreshIndicator(
        onRefresh: () async {
          controller.fetchBusinesses();
          return;
        },
        child: ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: businesses.length,
          itemBuilder: (context, index) {
            final business = businesses[index];
            return _buildBusinessCard(business);
          },
        ),
      );
    });
  }

  Widget _buildBusinessCard(Business business) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: GlassCard(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: ImageWithFallback(
                        imageUrl: business.safeImageUrl,
                        fallbackAsset: 'assets/images/default-business.jpg',
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          business.name,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          business.displayAddress,
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 14,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            const Icon(
                              Icons.phone,
                              color: Colors.white70,
                              size: 14,
                            ),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                business.displayContact,
                                style: const TextStyle(
                                  color: Colors.white70,
                                  fontSize: 12,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            const Icon(
                              Icons.access_time,
                              color: Colors.white70,
                              size: 14,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              business.displayHours,
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Container(
              height: 120,
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
                          GestureDetector(
                            onTap: () {
                              final controller =
                                  Get.find<MenuModalController>();
                              Get.to(
                                () => FullMapScreen(
                                  businesses: controller.businesses,
                                  events: controller.events,
                                  selectedBusiness: business,
                                ),
                              );
                            },
                            child: Column(
                              children: [
                                SizedBox(
                                  width: double.infinity,
                                  height: 80,
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(12),
                                    child: Image.asset(
                                      'assets/images/default-mapa.jpg',
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  business.lat != null && business.lng != null
                                      ? 'Location Available'
                                      : 'No Location',
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
                    ),
                  ),
                  Positioned(
                    top: 8,
                    right: 8,
                    child: GlassCard(
                      padding: EdgeInsets.zero,
                      child: IconButton(
                        icon: const Icon(
                          Icons.share,
                          color: Colors.white,
                          size: 20,
                        ),
                        onPressed: () {
                          _shareLocation(business);
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
    );
  }

  Widget _buildEventsTab(MenuModalController controller) {
    return Obx(() {
      final events = controller.events;
      if (controller.isLoadingEvents.value) {
        return const Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        );
      }
      if (events.isEmpty) {
        return _buildEmptyState(
          Icons.event,
          'No Events Found',
          'There are no events available at the moment.',
        );
      }
      return RefreshIndicator(
        onRefresh: () async {
          controller.fetchEvents();
          return;
        },
        child: ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: events.length,
          itemBuilder: (context, index) {
            final event = events[index];
            return _buildEventCard(event);
          },
        ),
      );
    });
  }

  Widget _buildEventCard(Event event) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: GlassCard(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: ImageWithFallback(
                        imageUrl: event.safeImageUrl,
                        fallbackAsset: 'assets/images/default-event.jpg',
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          event.title,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          event.venue,
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 14,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Text(
                              event.displayPrice,
                              style: const TextStyle(
                                color: AppColors.primary,
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              event.formattedDate,
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${event.participantsCount} attending',
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
            ),
            Container(
              height: 120,
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
                          GestureDetector(
                            onTap: () {
                              final controller =
                                  Get.find<MenuModalController>();
                              Get.to(
                                () => FullMapScreen(
                                  businesses: controller.businesses,
                                  events: controller.events,
                                  selectedEvent: event,
                                ),
                              );
                            },
                            child: Column(
                              children: [
                                SizedBox(
                                  width: double.infinity,
                                  height: 80,
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(12),
                                    child: Image.asset(
                                      'assets/images/default-mapa.jpg',
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 8),
                                const Text(
                                  'Event Location',
                                  style: TextStyle(
                                    color: Colors.white70,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
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
                        icon: const Icon(
                          Icons.share,
                          color: Colors.white,
                          size: 20,
                        ),
                        onPressed: () {
                          _shareLocationFromEvent(event);
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
    );
  }

  Widget _buildFriendsTab(MenuModalController controller) {
    return Obx(() {
      if (controller.isLoadingFriends.value) {
        return const Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        );
      }
      if (controller.friends.isEmpty) {
        return _buildEmptyState(
          Icons.people,
          'No Friends Yet',
          'Add friends to see them here and connect on NightUp.',
        );
      }
      return RefreshIndicator(
        onRefresh: () => controller.fetchFriends(),
        child: ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: controller.friends.length,
          itemBuilder: (context, index) {
            final friend = controller.friends[index];
            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              child: GlassCard(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Stack(
                        children: [
                          SizedBox(
                            width: 50,
                            height: 50,
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(25),
                              child: ImageWithFallback(
                                imageUrl: friend.safeProfilePictureUrl,
                                fallbackAsset:
                                    'assets/images/default-avatar.png',
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
                                color: friend.isOnline
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
                              friend.username,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            Text(
                              friend.isOnline ? 'Online' : 'Offline',
                              style: TextStyle(
                                color: friend.isOnline
                                    ? Colors.green
                                    : Colors.grey,
                                fontSize: 12,
                              ),
                            ),
                            if (friend.distance != null) ...[
                              const SizedBox(height: 4),
                              Text(
                                '${friend.distance!.toStringAsFixed(1)} km away',
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
                              Get.to(
                                () => FriendProfileScreen(friendId: friend.id),
                              );
                            },
                            icon: const Icon(
                              Icons.person,
                              color: Colors.white70,
                              size: 20,
                            ),
                          ),
                          IconButton(
                            onPressed: () {
                              _openChatWithFriend(friend);
                            },
                            icon: const Icon(
                              Icons.chat,
                              color: Colors.white70,
                              size: 20,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      );
    });
  }

  Widget _buildEmptyState(IconData icon, String title, String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 64, color: Colors.white70),
            const SizedBox(height: 16),
            Text(
              title,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white70, fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }

  void _shareLocation(Business business) async {
    final locationText = '${business.name} - ${business.displayAddress}';
    log('📍 Sharing business location: $locationText');
    Get.snackbar(
      'Location Shared',
      'Business location copied to clipboard',
      snackPosition: SnackPosition.BOTTOM,
    );
  }

  void _shareLocationFromEvent(Event event) async {
    final locationText = '${event.title} - ${event.venue}';
    log('📍 Sharing event location: $locationText');
    Get.snackbar(
      'Location Shared',
      'Event location copied to clipboard',
      snackPosition: SnackPosition.BOTTOM,
    );
  }

  // ✅ FUNCIÓN MODIFICADA CON MEJOR DEBUGGING
  void _openChatWithFriend(Friend friend) async {
    try {
      log('💬 Opening chat with ${friend.username}');
      log('   Friend ID: "${friend.id}"');
      log('   Friend ID length: ${friend.id.length}');
      log('   Friend ID type: ${friend.id.runtimeType}');
      log('   Full friend object: ${friend.toString()}');

      // Validar que el ID no esté vacío
      if (friend.id.isEmpty) {
        throw Exception('Friend ID is empty');
      }

      // Validar que el ID tenga el formato correcto (MongoDB ObjectId tiene 24 caracteres)
      if (friend.id.length != 24) {
        log('⚠️ Warning: Friend ID length is ${friend.id.length}, expected 24');
      }

      // 1. Asegurar que el ChatController existe
      if (!Get.isRegistered<ChatController>()) {
        log('⚠️ ChatController not found, creating new instance');
        Get.put(ChatController());
      }

      final ChatController chatController = Get.find<ChatController>();

      // 2. Mostrar loading con diseño mejorado
      Get.dialog(
        Center(
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.black.withOpacity(0.9),
                  Colors.grey[900]!.withOpacity(0.9),
                ],
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: AppColors.primary.withOpacity(0.5),
                width: 2,
              ),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withOpacity(0.3),
                  blurRadius: 20,
                  spreadRadius: 5,
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const CircularProgressIndicator(
                  color: AppColors.primary,
                  strokeWidth: 3,
                ),
                const SizedBox(height: 20),
                Text(
                  'Abriendo chat con',
                  style: TextStyle(color: Colors.white70, fontSize: 14),
                ),
                const SizedBox(height: 4),
                Text(
                  friend.username,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ),
        barrierDismissible: false,
      );

      // 3. Crear o encontrar la conversación
      log('📡 Calling createPrivateChat with friendId: ${friend.id}');
      await chatController.createPrivateChat(friend.id);
      log('✅ Private chat created/found successfully');

      // 4. Cerrar loading
      if (Get.isDialogOpen ?? false) {
        Get.back();
      }

      // 5. Cerrar el MenuModal
      Get.back();

      // 6. Esperar un poco para asegurar que la UI se actualice
      await Future.delayed(const Duration(milliseconds: 300));

      // 7. Navegar a la pantalla de chat
      log('🚀 Navigating to ChatScreen');
      Get.to(() => const ChatScreen());

      log('✅ Successfully navigated to chat with ${friend.username}');
    } catch (e, stackTrace) {
      log('❌ Error opening chat with ${friend.username}');
      log('Error details: $e');
      log('Stack trace: $stackTrace');

      // Cerrar loading si está abierto
      if (Get.isDialogOpen ?? false) {
        Get.back();
      }

      // Mostrar error detallado al usuario
      String errorMessage = 'No se pudo abrir el chat con ${friend.username}';

      if (e.toString().contains('500')) {
        errorMessage +=
            '\n\nError del servidor. Por favor verifica:\n1. Que sois amigos aceptados\n2. Que el backend esté corriendo\n3. Los logs del backend para más detalles';
      } else if (e.toString().contains('404')) {
        errorMessage += '\n\nUsuario no encontrado';
      } else if (e.toString().contains('401') || e.toString().contains('403')) {
        errorMessage += '\n\nNo tienes permisos para crear esta conversación';
      }

      Get.snackbar(
        'Error',
        errorMessage,
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red.withOpacity(0.9),
        colorText: Colors.white,
        duration: const Duration(seconds: 6),
        margin: const EdgeInsets.all(16),
        borderRadius: 12,
        icon: const Icon(Icons.error_outline, color: Colors.white),
      );
    }
  }
}
