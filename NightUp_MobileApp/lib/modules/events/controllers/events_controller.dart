import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../app/themes/app_colors.dart';
import '../../../data/models/event_model.dart';
import '../../../data/repositories/event_repository.dart';

class EventsController extends GetxController {
  final EventRepository _eventRepository = EventRepository();

  final RxList<EventModel> events = <EventModel>[].obs;
  final RxList<EventModel> filteredEvents = <EventModel>[].obs;
  final RxBool isLoading = false.obs;
  final RxBool isLoadingMore = false.obs;
  final RxString searchQuery = ''.obs;
  final RxString selectedCategory = 'all'.obs;
  final RxBool hasMore = true.obs;
  final RxInt totalEvents = 0.obs;

  final List<String> categories = [
    'all',
    'techno',
    'general', 
    'music',
    'party',
    'concert',
    'festival',
    'club',
    'bar',
    'electronica',
    'rock',
    'hip-hop',
    'jazz',
    'reggaeton',
  ];

  int _currentSkip = 0;
  final int _limit = 20;

  @override
  void onInit() {
    super.onInit();
    loadEvents();
  }

  Future<void> loadEvents({bool loadMore = false}) async {
    try {
      if (loadMore) {
        isLoadingMore.value = true;
      } else {
        isLoading.value = true;
        _currentSkip = 0;
        events.clear();
      }

      final result = await _eventRepository.getEvents(
        skip: loadMore ? _currentSkip : 0,
        limit: _limit,
      );
      
      final newEvents = result['events'] as List<EventModel>;
      hasMore.value = result['hasMore'] as bool;
      totalEvents.value = result['total'] as int;
      
      if (loadMore) {
        events.addAll(newEvents);
      } else {
        events.value = newEvents;
      }
      
      _currentSkip += newEvents.length;
      filterEvents();
      
    } catch (e) {
      Get.snackbar(
        'Error',
        e.toString(),
        backgroundColor: AppColors.error.withOpacity(0.9),
        colorText: Colors.white,
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      isLoading.value = false;
      isLoadingMore.value = false;
    }
  }

  Future<void> loadMoreEvents() async {
    if (!hasMore.value || isLoadingMore.value) return;
    await loadEvents(loadMore: true);
  }

  void searchEvents(String query) {
    searchQuery.value = query.toLowerCase();
    filterEvents();
  }

  void selectCategory(String category) {
    selectedCategory.value = category;
    filterEvents();
  }

  void filterEvents() {
    var filtered = events.where((event) {
      final matchesSearch = searchQuery.value.isEmpty ||
          event.name.toLowerCase().contains(searchQuery.value) ||
          event.location.toLowerCase().contains(searchQuery.value);
      
      // Hacer el filtro de categoría más permisivo
      final matchesCategory = selectedCategory.value == 'all' ||
          event.category.toLowerCase() == selectedCategory.value.toLowerCase() ||
          event.category.toLowerCase().contains(selectedCategory.value.toLowerCase()) ||
          selectedCategory.value.toLowerCase().contains(event.category.toLowerCase());
      
      return matchesSearch && matchesCategory;
    }).toList();
    
    filteredEvents.value = filtered;
  }

  Future<void> refreshEvents() async {
    await loadEvents();
  }
}