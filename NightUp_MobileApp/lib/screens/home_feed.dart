import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../widgets/glass_card.dart';
import '../theme/colors.dart';
import '../controllers/home_feed_controller.dart';
import '../models/event.dart';
import '../widgets/image_with_fallback.dart';
import '../widgets/menu_modal.dart';
import '../widgets/friend_post_item.dart';

class HomeFeed extends StatefulWidget {
  final void Function(String eventId)? onEventClick;

  const HomeFeed({super.key, this.onEventClick});

  @override
  State<HomeFeed> createState() => _HomeFeedState();
}

class _HomeFeedState extends State<HomeFeed> {
  final HomeFeedController controller = Get.find<HomeFeedController>();

  @override
  void initState() {
    super.initState();
    // Restaurar la página cuando volvemos a esta pantalla
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (controller.lastViewedPage.value > 0) {
        controller.restoreLastPage();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          _buildContent(),
          _buildTopNavigation(),
          _buildBottomActions(),
          // Sugerencia de intereses tras renovar token y si onboarding está incompleto
          _buildContent(),
          _buildTopNavigation(),
          _buildBottomActions(),
        ],
      ),
    );
  }

  Widget _buildContent() {
    return GetBuilder<HomeFeedController>(
      id: 'tab_selection',
      builder: (controller) {
        return IndexedStack(
          index: controller.tabController.index,
          children: [_buildDiscoverFeed(), _buildFriendsFeed()],
        );
      },
    );
  }

  Widget _buildDiscoverFeed() {
    return GetBuilder<HomeFeedController>(
      id: 'discover_feed',
      builder: (controller) {
        if (controller.isLoadingDiscover.value) {
          return const Center(
            child: CircularProgressIndicator(color: AppColors.primary),
          );
        }

        if (controller.discoverEvents.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.event_busy, size: 64, color: Colors.white70),
                const SizedBox(height: 16),
                const Text(
                  'No hay eventos disponibles',
                  style: TextStyle(color: Colors.white70, fontSize: 16),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Prueba a recargar o verifica tu conexión',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.white54, fontSize: 14),
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: controller.refreshAllFeeds,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                  ),
                  child: Text(
                    'Recargar',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ],
            ),
          );
        }

        return PageView.builder(
          controller: controller.pageController,
          itemCount: controller.discoverEvents.length,
          onPageChanged: (index) {
            controller.currentPage.value = index;
            controller.update(['current_page', 'bottom_actions']);
          },
          itemBuilder: (context, index) {
            final event = controller.discoverEvents[index];
            return _buildDiscoverEventWithButton(event);
          },
        );
      },
    );
  }

  Widget _buildDiscoverEventWithButton(Event event) {
    return Stack(
      children: [
        SizedBox(
          width: double.infinity,
          height: double.infinity,
          child: ImageWithFallback(
            imageUrl: event.safeImageUrl,
            fallbackAsset: 'assets/images/default-event.jpg',
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
                Colors.black.withOpacity(0.3),
                Colors.black.withOpacity(0.8),
                Colors.black.withOpacity(0.9),
              ],
            ),
          ),
        ),

        _buildEventContent(event),
        _buildDetailsButton(event),
      ],
    );
  }

  Widget _buildEventContent(Event event) {
    return Positioned(
      left: 20,
      right: 20,
      bottom: 70,
      child: Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.6,
        ),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                margin: const EdgeInsets.only(top: 50, right: 80),
                child: Text(
                  event.title,
                  style: const TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    shadows: [
                      Shadow(
                        blurRadius: 10,
                        color: Colors.black,
                        offset: Offset(2, 2),
                      ),
                    ],
                  ),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(height: 8),
              Container(
                margin: const EdgeInsets.only(right: 80),
                child: Text(
                  event.venue,
                  style: const TextStyle(
                    fontSize: 20,
                    color: Colors.white70,
                    shadows: [
                      Shadow(
                        blurRadius: 5,
                        color: Colors.black,
                        offset: Offset(1, 1),
                      ),
                    ],
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Text(
                    event.displayPrice,
                    style: const TextStyle(
                      fontSize: 24,
                      color: AppColors.primary,
                      fontWeight: FontWeight.w600,
                      shadows: [
                        Shadow(
                          blurRadius: 5,
                          color: Colors.black,
                          offset: Offset(1, 1),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  Text(
                    event.formattedDate,
                    style: const TextStyle(
                      fontSize: 16,
                      color: Colors.white70,
                      shadows: [
                        Shadow(
                          blurRadius: 5,
                          color: Colors.black,
                          offset: Offset(1, 1),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              if (event.tags.isNotEmpty) ...[
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  children: event.tags.take(3).map((tag) {
                    return Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.3),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.primary),
                      ),
                      child: Text(
                        tag,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ],
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailsButton(Event event) {
    return Positioned(
      left: 20,
      right: 20,
      bottom: 10,
      child: GestureDetector(
        onTap: () {
          final eventId = event.id;
          log('🖱️ Details Button clicked - Event ID: $eventId');

          // Guardar la página actual antes de navegar
          controller.saveCurrentPage();

          if (widget.onEventClick != null) {
            widget.onEventClick!(eventId);
          }
        },
        child: Container(
          width: double.infinity,
          height: 48,
          decoration: BoxDecoration(
            gradient: AppColors.primaryGradient,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.3),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: const Center(
            child: Text(
              'Ver Detalles del Evento',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
                fontSize: 16,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFriendsFeed() {
    return GetBuilder<HomeFeedController>(
      id: 'friends_feed',
      builder: (controller) {
        if (controller.isLoadingFriends.value) {
          return const Center(
            child: CircularProgressIndicator(color: AppColors.primary),
          );
        }

        if (controller.friendsPosts.isEmpty) {
          return Container(
            color: Colors.black,
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.people_outline,
                    size: 64,
                    color: Colors.white70,
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'No hay publicaciones de amigos',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Sigue a alguien para ver su contenido aquí',
                    style: TextStyle(color: Colors.white54, fontSize: 14),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    onPressed: () => controller.refreshAllFeeds(),
                    icon: const Icon(Icons.refresh, color: Colors.white),
                    label: const Text(
                      'Recargar',
                      style: TextStyle(color: Colors.white),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 12,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(25),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        return PageView.builder(
          scrollDirection: Axis.vertical,
          itemCount: controller.friendsPosts.length,
          itemBuilder: (context, index) {
            final post = controller.friendsPosts[index];
            return FriendPostItem(
              post: post,
              onLike: () => controller.toggleLikePost(post),
              onComment: () {
                // Obrirem modal de comentaris més endavant
              },
            );
          },
        );
      },
    );
  }

  Widget _buildTopNavigation() {
    return GetBuilder<HomeFeedController>(
      id: 'tab_selection',
      builder: (controller) {
        return Positioned(
          top: 0,
          left: 0,
          right: 0,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.black.withOpacity(0.8),
                  Colors.black.withOpacity(0.4),
                  Colors.transparent,
                ],
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Center(
                    child: GlassCard(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 32,
                        vertical: 8,
                      ),
                      child: TabBar(
                        controller: controller.tabController,
                        indicator: BoxDecoration(
                          borderRadius: BorderRadius.circular(25),
                          color: AppColors.glassWhite,
                        ),
                        labelColor: Colors.white,
                        unselectedLabelColor: Colors.white70,
                        labelStyle: const TextStyle(
                          fontWeight: FontWeight.w600,
                        ),
                        unselectedLabelStyle: const TextStyle(
                          fontWeight: FontWeight.normal,
                        ),
                        tabs: const [
                          Tab(text: 'Para Ti'),
                          Tab(text: 'Amigos'),
                        ],
                        onTap: (index) {
                          controller.changeTab(index);
                        },
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                GlassCard(
                  padding: EdgeInsets.zero,
                  child: IconButton(
                    icon: const Icon(Icons.menu, color: Colors.white, size: 20),
                    onPressed: () {
                      Get.to(() => const MenuModal());
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // ✅ CAMBIO PRINCIPAL: Usar Obx en lugar de GetBuilder
  Widget _buildBottomActions() {
    return GetBuilder<HomeFeedController>(
      id: 'bottom_actions',
      builder: (controller) {
        // 1. Verificar que estamos en el tab "Para Ti" (índice 0)
        // Usamos el index del tabController directamente
        if (controller.tabController.index != 0) {
          return const SizedBox.shrink();
        }

        // 2. Verificar que hay eventos cargados
        if (controller.discoverEvents.isEmpty) {
          return const SizedBox.shrink();
        }

        // 3. Obtener el evento actual basado en la página del PageView
        final currentIndex = controller.currentPage.value.clamp(
          0,
          controller.discoverEvents.length - 1,
        );
        final event = controller.discoverEvents[currentIndex];

        return Positioned(
          bottom: 70,
          right: 24,
          child: Column(
            children: [
              _buildActionButton(
                event.isLiked ? Icons.favorite : Icons.favorite_border,
                '${event.likes}',
                () {
                  log('🖱️ LIKE BUTTON PRESSED - Event: ${event.id}');
                  controller.toggleLikeEvent(event);
                },
                isLiked: event.isLiked,
              ),
              const SizedBox(height: 16),
              _buildActionButton(Icons.share, 'Compartir', () {
                log('🖱️ SHARE BUTTON PRESSED - Event: ${event.id}');
                controller.shareEvent(event);
              }),
            ],
          ),
        );
      },
    );
  }

  Widget _buildActionButton(
    IconData icon,
    String text,
    VoidCallback onTap, {
    bool isLiked = false,
  }) {
    return Column(
      children: [
        GestureDetector(
          onTap: onTap,
          child: GlassCard(
            padding: const EdgeInsets.all(12),
            child: Icon(
              icon,
              color: isLiked ? Colors.red : Colors.white,
              size: 24,
            ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          text,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}
