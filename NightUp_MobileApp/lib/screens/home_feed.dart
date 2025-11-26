import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../widgets/glass_card.dart';
import '../theme/colors.dart';
import '../controllers/home_feed_controller.dart';
import '../models/event.dart';
import '../models/post.dart';
import '../widgets/image_with_fallback.dart'; 

class HomeFeed extends GetView<HomeFeedController> {
  final void Function(String eventId)? onEventClick;

  const HomeFeed({
    super.key,
    this.onEventClick,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Contenido principal
          _buildContent(),
          
          // Navegación superior - COMPLETAMENTE PEGADO AL BORDE
          _buildTopNavigation(),

          // Acciones inferiores
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
          children: [
            _buildDiscoverFeed(),
            _buildFriendsFeed(),
          ],
        );
      },
    );
  }

  Widget _buildDiscoverFeed() {
    return GetBuilder<HomeFeedController>(
      id: 'discover_feed',
      builder: (controller) {
        if (controller.isLoadingDiscover.value) {
          return const Center(child: CircularProgressIndicator(color: AppColors.primary));
        }

        if (controller.discoverEvents.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.event_busy, size: 64, color: Colors.white70),
                const SizedBox(height: 16),
                Text(
                  'No hay eventos disponibles',
                  style: TextStyle(color: Colors.white70, fontSize: 16),
                ),
                const SizedBox(height: 8),
                Text(
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
                  child: Text('Recargar', style: TextStyle(color: Colors.white)),
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
            controller.update(['current_page']);
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
        _buildDetailsButton(event), // Botón separado
      ],
    );
  }

  Widget _buildEventContent(Event event) {
    return Positioned(
      left: 20,
      right: 20,
      bottom: 70, // Espacio para el botón + margen del nav bar
      child: Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(Get.context!).size.height * 0.6, // Límite máximo de altura
        ),
        child: SingleChildScrollView( // Permite scroll si el contenido es muy largo
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Título - con margen superior para evitar solapamiento con botones de like
              Container(
                margin: const EdgeInsets.only(
                  top: 50, // Espacio para los botones de like
                  right: 80, // LÍMITE: margen derecho para que no se solape con botones
                ),
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
                  maxLines: 3, // Máximo 3 líneas
                  overflow: TextOverflow.ellipsis, // Puntos suspensivos si es muy largo
                ),
              ),
              const SizedBox(height: 8),
              Container(
                margin: const EdgeInsets.only(right: 80), // Mismo margen para la ubicación
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
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
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

  // Botón de detalles posicionado justo encima del nav bar
  Widget _buildDetailsButton(Event event) {
    return Positioned(
      left: 20,
      right: 20,
      bottom: 10, // Justo encima del nav bar
      child: GestureDetector(
        onTap: () {
          if (onEventClick != null) {
            onEventClick!(event.id);
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
          return Container(
            color: Colors.black,
            padding: const EdgeInsets.only(top: 80), // Ajustado por la navegación superior
            child: const Center(child: CircularProgressIndicator(color: AppColors.primary)),
          );
        }

        if (controller.friendsPosts.isEmpty) {
          return Container(
            color: Colors.black,
            padding: const EdgeInsets.only(top: 80), // Ajustado por la navegación superior
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.people_outline, size: 64, color: Colors.white70),
                  const SizedBox(height: 16),
                  Text(
                    'Añade amigos para ver sus publicaciones',
                    style: TextStyle(color: Colors.white70, fontSize: 16),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Tus amigos aparecerán aquí cuando\ncompartan eventos y experiencias',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.white54, fontSize: 14),
                  ),
                ],
              ),
            ),
          );
        }
        
        return Container(
          color: Colors.black,
          child: ListView.builder(
            padding: const EdgeInsets.only(top: 80, bottom: 80), // Ajustado por la navegación superior
            itemCount: controller.friendsPosts.length,
            itemBuilder: (context, index) {
              final post = controller.friendsPosts[index];
              return _buildFriendPost(post);
            },
          ),
        );
      },
    );
  }

  Widget _buildFriendPost(Post post) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      child: GlassCard(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                ImageWithFallback(
                  imageUrl: post.user?.profilePictureUrl,
                  isCircle: true,
                  width: 40,
                  height: 40,
                  fallbackAsset: 'assets/images/google.png', 
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        post.user?.username ?? 'Usuario Desconocido',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      Text(
                        post.location ?? 'Ubicación Desconocida',
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.more_vert, color: Colors.white70),
              ],
            ),
            const SizedBox(height: 12),
            
            Container(
              width: double.infinity,
              height: 200,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: ImageWithFallback(
                  imageUrl: post.mediaUrl,
                  fallbackAsset: 'assets/images/google.png',
                ),
              ),
            ),
            const SizedBox(height: 12),
            
            if (post.caption != null && post.caption!.isNotEmpty)
              Text(
                post.caption!,
                style: const TextStyle(color: Colors.white, fontSize: 14),
              ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.favorite_border, color: Colors.white70, size: 20),
                const SizedBox(width: 4),
                Text(
                  '${post.likes}',
                  style: const TextStyle(color: Colors.white70, fontSize: 12),
                ),
                const SizedBox(width: 16),
                const Icon(Icons.chat_bubble_outline, color: Colors.white70, size: 20),
                const SizedBox(width: 4),
                Text(
                  '${post.comments}',
                  style: const TextStyle(color: Colors.white70, fontSize: 12),
                ),
                const Spacer(),
                const Icon(Icons.share, color: Colors.white70, size: 20),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTopNavigation() {
    return GetBuilder<HomeFeedController>(
      id: 'tab_selection',
      builder: (controller) {
        return Positioned(
          top: 0, // COMPLETAMENTE PEGADO AL BORDE SUPERIOR
          left: 0,
          right: 0,
          child: Container(
            // SIN MARGEN - COMPLETAMENTE PEGADO
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8), // Padding interno
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
                      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 8),
                      child: TabBar(
                        controller: controller.tabController,
                        indicator: BoxDecoration(
                          borderRadius: BorderRadius.circular(25),
                          color: AppColors.glassWhite,
                        ),
                        labelColor: Colors.white,
                        unselectedLabelColor: Colors.white70,
                        labelStyle: const TextStyle(fontWeight: FontWeight.w600),
                        unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.normal),
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
                      // Menú de opciones
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

  Widget _buildBottomActions() {
    return GetBuilder<HomeFeedController>(
      id: 'current_page',
      builder: (controller) {
        // Solo mostrar en el tab Discover (Para Ti)
        if (controller.tabController.index != 0 || controller.discoverEvents.isEmpty) {
          return const SizedBox.shrink();
        }
        
        final event = controller.discoverEvents[controller.currentPage.value.clamp(0, controller.discoverEvents.length - 1)];
        
        return Positioned(
          bottom: 70, // Justo encima del botón "Ver Detalles"
          right: 24,
          child: Column(
            children: [
              _buildActionButton(Icons.favorite, '${event.likes}'),
              const SizedBox(height: 16),
              _buildActionButton(Icons.share, 'Compartir'),
            ],
          ),
        );
      },
    );
  }

  Widget _buildActionButton(IconData icon, String text) {
    return Column(
      children: [
        GestureDetector(
          onTap: () {
            // Aquí puedes agregar la lógica para like/share
          },
          child: GlassCard(
            padding: const EdgeInsets.all(12),
            child: Icon(icon, color: Colors.white, size: 24),
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