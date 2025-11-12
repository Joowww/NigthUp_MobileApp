import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_translate/flutter_translate.dart';
import '../Controllers/eventos_controller.dart';
import '../Controllers/auth_controller.dart';
import '../Widgets/eventos_card.dart';
import '../Widgets/navigation_bar.dart';

class EventosListScreen extends GetView<EventoController> {
  const EventosListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final AuthController authController = Get.find<AuthController>();

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: Text(translate('events.title')),
        backgroundColor: Colors.white,
        elevation: 0,
        actions: [
          if (authController.isAdmin || authController.isManager)
            IconButton(
              icon: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.green.shade100,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.add, color: Colors.green, size: 20),
              ),
              onPressed: () => Get.toNamed('/create-event'),
            ),
          IconButton(
            icon: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.search, color: Colors.grey),
            ),
            onPressed: () {},
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Obx(() {
          if (controller.isLoading.value) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Cargando eventos...'),
                ],
              ),
            );
          }

          if (controller.eventosList.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.event_busy, size: 80, color: Colors.grey.shade400),
                  const SizedBox(height: 16),
                  Text(
                    translate('events.not_found'),
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.grey.shade600,
                    ),
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton.icon(
                    onPressed: () => controller.refreshEvents(),
                    icon: const Icon(Icons.refresh),
                    label: const Text('Recargar'),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            itemCount: controller.eventosList.length,
            itemBuilder: (context, index) {
              return EventosCard(evento: controller.eventosList[index]);
            },
          );
        }),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          controller.refreshEvents();
          Get.snackbar(
            translate('common.success'),
            translate('events.refreshed'),
            snackPosition: SnackPosition.BOTTOM,
            backgroundColor: Colors.green,
            colorText: Colors.white,
            borderRadius: 12,
          );
        },
        backgroundColor: const Color(0xFF667EEA),
        child: const Icon(Icons.refresh, color: Colors.white),
      ),
      bottomNavigationBar: const CustomNavBar(currentIndex: 1),
    );
  }
}