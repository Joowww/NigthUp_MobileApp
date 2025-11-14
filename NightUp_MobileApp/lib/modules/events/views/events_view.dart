import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:pull_to_refresh/pull_to_refresh.dart';
import 'package:flutter_translate/flutter_translate.dart';
import '../../../app/themes/app_colors.dart';
import '../controllers/events_controller.dart';
import '../../home/widgets/event_card.dart';

class EventsView extends StatelessWidget {
  const EventsView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(EventsController(), permanent: true);
    final refreshController = RefreshController();

    return Scaffold(
      backgroundColor: AppColors.darkBackground,
      body: SmartRefresher(
        controller: refreshController,
        onRefresh: () async {
          await controller.refreshEvents();
          refreshController.refreshCompleted();
        },
        header: WaterDropMaterialHeader(
          backgroundColor: AppColors.neonPink,
          color: Colors.white,
        ),
        child: CustomScrollView(
          slivers: [
            // AppBar simple
            SliverAppBar(
              expandedHeight: 120,
              floating: true,
              pinned: true,
              backgroundColor: AppColors.darkBackground,
              flexibleSpace: FlexibleSpaceBar(
                title: Text(
                  translate('events.title'),
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Poppins',
                  ),
                ),
                background: Container(
                  decoration: BoxDecoration(
                    gradient: AppColors.primaryGradient,
                  ),
                  child: const Center(
                    child: Icon(
                      Icons.nightlife,
                      size: 60,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ),
            
            // Search bar simple
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: TextField(
                  onChanged: (value) => controller.searchEvents(value),
                  style: const TextStyle(color: AppColors.textPrimary),
                  decoration: InputDecoration(
                    hintText: translate('events.search_placeholder'),
                    hintStyle: TextStyle(color: AppColors.textSecondary.withOpacity(0.7)),
                    prefixIcon: const Icon(Icons.search, color: AppColors.neonBlue),
                    filled: true,
                    fillColor: AppColors.darkInput,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(15),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                  ),
                ),
              ),
            ),
            
            // Lista de eventos
            Obx(() {
              if (controller.isLoading.value && controller.events.isEmpty) {
                return const SliverFillRemaining(
                  child: Center(
                    child: CircularProgressIndicator(
                      color: AppColors.neonPink,
                    ),
                  ),
                );
              }
              
              if (controller.filteredEvents.isEmpty) {
                return SliverFillRemaining(
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          controller.events.isEmpty ? Icons.event_busy : Icons.search_off,
                          size: 80,
                          color: AppColors.textSecondary.withOpacity(0.5),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          controller.events.isEmpty 
                            ? translate('events.no_events')
                            : translate('events.no_search_results'),
                          style: const TextStyle(
                            fontSize: 18,
                            color: AppColors.textSecondary,
                            fontFamily: 'Poppins',
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }
              
              return SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      // Si es el último elemento y hay más eventos, mostrar botón de cargar más
                      if (index == controller.filteredEvents.length) {
                        if (controller.hasMore.value) {
                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 20),
                            child: Center(
                              child: Obx(() => controller.isLoadingMore.value
                                  ? const CircularProgressIndicator(
                                      color: AppColors.neonPink,
                                    )
                                  : ElevatedButton(
                                      onPressed: controller.loadMoreEvents,
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: AppColors.neonPurple,
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 32,
                                          vertical: 12,
                                        ),
                                      ),
                                      child: Text(
                                        translate('events.load_more'),
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontFamily: 'Poppins',
                                        ),
                                      ),
                                    ),
                              ),
                            ),
                          );
                        } else {
                          return const SizedBox();
                        }
                      }
                      
                      final event = controller.filteredEvents[index];
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: EventCard(
                          event: event,
                          onTap: () {
                            // TODO: Navegar a detalles del evento
                          },
                        ),
                      );
                    },
                    childCount: controller.filteredEvents.length + 
                        (controller.hasMore.value ? 1 : 0),
                  ),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}