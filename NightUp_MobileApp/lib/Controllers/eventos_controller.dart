import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../Models/eventos.dart';
import '../Services/eventos_services.dart';
import '../Controllers/auth_controller.dart';

class EventoController extends GetxController {
  var isLoading = true.obs;
  var eventosList = <Evento>[].obs;
  var selectedEvento = Rxn<Evento>();
  var eventStats = <String, dynamic>{}.obs;
  final EventosServices _eventosServices;

  EventoController(this._eventosServices);

  @override
  void onInit() {
    fetchEventos();
    fetchEventStats();
    super.onInit();
  }

  void fetchEventos() async {
    try {
      isLoading(true);
      var eventos = await _eventosServices.fetchEvents();
      eventosList.assignAll(eventos);
    } catch (e) {
      Get.snackbar(
        "Error",
        "No se pudieron cargar los eventos: ${e.toString()}",
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      isLoading(false);
    }
  }

  Future<void> fetchEventoById(String id) async {
    try {
      isLoading(true);
      var evento = await _eventosServices.fetchEventById(id);
      selectedEvento.value = evento;
    } catch (e) {
      Get.snackbar(
        "Error al cargar",
        "No se pudo encontrar el evento: ${e.toString()}",
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      isLoading(false);
    }
  }

  Future<void> fetchEventStats() async {
    try {
      final result = await _eventosServices.getEventStats();
      if (result['success'] == true) {
        eventStats.value = result['stats'] ?? {};
      }
    } catch (e) {
      print('Error fetching event stats: $e');
    }
  }

  Future<void> createEvent(Map<String, dynamic> eventData) async {
    try {
      isLoading(true);
      final newEvent = await _eventosServices.createEvent(eventData);
      eventosList.insert(0, newEvent);
      Get.back();
      Get.snackbar(
        "Éxito",
        "Evento creado correctamente",
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.green,
        colorText: Colors.white,
      );
    } catch (e) {
      Get.snackbar(
        "Error",
        "No se pudo crear el evento: ${e.toString()}",
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    } finally {
      isLoading(false);
    }
  }

  Future<void> updateEvent(String eventId, Map<String, dynamic> eventData) async {
    try {
      isLoading(true);
      final updatedEvent = await _eventosServices.updateEvent(eventId, eventData);
      
      // Actualizar en la lista
      final index = eventosList.indexWhere((event) => event.id == eventId);
      if (index != -1) {
        eventosList[index] = updatedEvent;
      }
      
      // Actualizar evento seleccionado si es el mismo
      if (selectedEvento.value?.id == eventId) {
        selectedEvento.value = updatedEvent;
      }
      
      Get.back();
      Get.snackbar(
        "Éxito",
        "Evento actualizado correctamente",
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.green,
        colorText: Colors.white,
      );
    } catch (e) {
      Get.snackbar(
        "Error",
        "No se pudo actualizar el evento: ${e.toString()}",
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    } finally {
      isLoading(false);
    }
  }

  Future<void> deleteEvent(String eventId) async {
    try {
      isLoading(true);
      final success = await _eventosServices.deleteEvent(eventId);
      if (success) {
        eventosList.removeWhere((event) => event.id == eventId);
        if (selectedEvento.value?.id == eventId) {
          selectedEvento.value = null;
        }
        Get.snackbar(
          "Éxito",
          "Evento eliminado correctamente",
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.green,
          colorText: Colors.white,
        );
      }
    } catch (e) {
      Get.snackbar(
        "Error",
        "No se pudo eliminar el evento: ${e.toString()}",
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    } finally {
      isLoading(false);
    }
  }

  Future<void> joinEvent(String eventId) async {
    try {
      final updatedEvent = await _eventosServices.joinEvent(eventId);
      
      // Actualizar en la lista
      final index = eventosList.indexWhere((event) => event.id == eventId);
      if (index != -1) {
        eventosList[index] = updatedEvent;
      }
      
      // Actualizar evento seleccionado si es el mismo
      if (selectedEvento.value?.id == eventId) {
        selectedEvento.value = updatedEvent;
      }
      
      Get.snackbar(
        "Éxito",
        "Te has unido al evento",
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.green,
        colorText: Colors.white,
      );
    } catch (e) {
      Get.snackbar(
        "Error",
        "No se pudo unir al evento: ${e.toString()}",
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }

  Future<void> leaveEvent(String eventId) async {
    try {
      final updatedEvent = await _eventosServices.leaveEvent(eventId);
      
      // Actualizar en la lista
      final index = eventosList.indexWhere((event) => event.id == eventId);
      if (index != -1) {
        eventosList[index] = updatedEvent;
      }
      
      // Actualizar evento seleccionado si es el mismo
      if (selectedEvento.value?.id == eventId) {
        selectedEvento.value = updatedEvent;
      }
      
      Get.snackbar(
        "Éxito",
        "Has salido del evento",
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.green,
        colorText: Colors.white,
      );
    } catch (e) {
      Get.snackbar(
        "Error",
        "No se pudo salir del evento: ${e.toString()}",
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }

  void refreshEvents() {
    fetchEventos();
    fetchEventStats();
  }

  List<Evento> get myEvents {
    final authController = Get.find<AuthController>();
    final currentUserId = authController.currentUser.value?.id;
    if (currentUserId == null) return [];
    
    return eventosList.where((event) => event.participants.contains(currentUserId)).toList();
  }
}