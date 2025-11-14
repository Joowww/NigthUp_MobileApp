import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../app/themes/app_colors.dart';
import '../controllers/events_controller.dart';

class EventsViewSimple extends StatelessWidget {
  const EventsViewSimple({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(EventsController(), permanent: true);

    print('EventsViewSimple: Building EventsView');

    return Scaffold(
      backgroundColor: AppColors.darkBackground,
      appBar: AppBar(
        title: const Text('Eventos Debug', style: TextStyle(color: Colors.white)),
        backgroundColor: AppColors.darkBackground,
        elevation: 0,
      ),
      body: Column(
        children: [
          // Debug info
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            color: Colors.red.withOpacity(0.3),
            child: Obx(() => Text(
              'DEBUG INFO:\n'
              'Loading: ${controller.isLoading.value}\n'
              'Events count: ${controller.events.length}\n'
              'Filtered count: ${controller.filteredEvents.length}\n'
              'Search: "${controller.searchQuery.value}"\n'
              'Category: "${controller.selectedCategory.value}"',
              style: const TextStyle(color: Colors.white, fontSize: 12),
            )),
          ),
          
          // Botón para forzar carga
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      print('Manual load button pressed');
                      controller.loadEvents();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.neonPink,
                    ),
                    child: const Text('Cargar Eventos', 
                      style: TextStyle(color: Colors.white)),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      print('Reset filter button pressed');
                      controller.selectCategory('all');
                      controller.searchEvents('');
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.neonPurple,
                    ),
                    child: const Text('Reset Filtros', 
                      style: TextStyle(color: Colors.white)),
                  ),
                ),
              ],
            ),
          ),
          
          // Lista simplificada
          Expanded(
            child: Obx(() {
              if (controller.isLoading.value) {
                return const Center(
                  child: CircularProgressIndicator(color: AppColors.neonPink),
                );
              }
              
              if (controller.events.isEmpty) {
                return const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.event_busy, size: 64, color: Colors.white),
                      SizedBox(height: 16),
                      Text(
                        'No hay eventos cargados',
                        style: TextStyle(color: Colors.white, fontSize: 18),
                      ),
                    ],
                  ),
                );
              }
              
              final eventsToShow = controller.filteredEvents.isNotEmpty 
                  ? controller.filteredEvents 
                  : controller.events;
              
              return ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: eventsToShow.length,
                itemBuilder: (context, index) {
                  final event = eventsToShow[index];
                  return Card(
                    color: AppColors.darkCard,
                    margin: const EdgeInsets.only(bottom: 12),
                    child: ListTile(
                      title: Text(
                        event.name,
                        style: const TextStyle(color: Colors.white),
                      ),
                      subtitle: Text(
                        '${event.location} - ${event.category}\n${event.price > 0 ? '€${event.price}' : 'GRATIS'}',
                        style: const TextStyle(color: Colors.grey),
                      ),
                      trailing: Icon(
                        Icons.event,
                        color: AppColors.neonPink,
                      ),
                    ),
                  );
                },
              );
            }),
          ),
        ],
      ),
    );
  }
}