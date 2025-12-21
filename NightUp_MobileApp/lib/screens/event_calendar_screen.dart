import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:get/get.dart';
import '../theme/colors.dart';
import '../widgets/glass_card.dart';
import '../widgets/image_with_fallback.dart';
import '../models/event.dart';
import '../services/api_service.dart';
import '../controllers/auth_controller.dart';
import 'event_detail_screen.dart';
import 'full_map_screen.dart';

class EventCalendarScreen extends StatefulWidget {
  final VoidCallback onBack;

  const EventCalendarScreen({super.key, required this.onBack});

  @override
  State<EventCalendarScreen> createState() => _EventCalendarScreenState();
}

class _EventCalendarScreenState extends State<EventCalendarScreen> {
  late CalendarFormat _calendarFormat;
  late DateTime _focusedDay;
  late DateTime _selectedDay;

  // Map of events by date
  final RxMap<DateTime, List<Event>> _events = <DateTime, List<Event>>{}.obs;
  final RxBool _isLoading = true.obs;

  final ApiService _apiService = Get.find<ApiService>();
  final AuthController _authController = Get.find<AuthController>();

  @override
  void initState() {
    super.initState();
    _calendarFormat = CalendarFormat.month;
    _focusedDay = DateTime.now();
    _selectedDay = DateTime.now();
    _fetchUserEvents();
  }

  Future<void> _fetchUserEvents() async {
    final user = _authController.currentUser;
    if (user == null) {
      _isLoading.value = false;
      return;
    }

    try {
      final response = await _apiService.get(
        '/event/by-participant/${user.id}',
      );
      List<Event> eventList = [];

      if (response.data is Map && response.data['events'] is List) {
        eventList = (response.data['events'] as List)
            .map((e) => Event.fromJson(e))
            .toList();
      } else if (response.data is List) {
        eventList = (response.data as List)
            .map((e) => Event.fromJson(e))
            .toList();
      }

      // Group events by day
      final groupedEvents = <DateTime, List<Event>>{};
      for (var event in eventList) {
        // Normalize date to remove time component for calendar grouping
        final date = DateTime(
          event.date.year,
          event.date.month,
          event.date.day,
        );

        if (groupedEvents[date] == null) {
          groupedEvents[date] = [];
        }
        groupedEvents[date]!.add(event);
      }

      _events.value = groupedEvents;
    } catch (e) {
      Get.snackbar('Error', 'Could not load your calendar');
    } finally {
      _isLoading.value = false;
    }
  }

  List<Event> _getEventsForDay(DateTime day) {
    // Normalize user selection to key format
    final dateKey = DateTime(day.year, day.month, day.day);
    return _events[dateKey] ?? [];
  }

  void _openMapWithLocation(double lat, double lng, String eventName) {
    // Navigate to FullMapScreen with the event location (uses OpenStreetMap)
    final eventForMap = Event(
      id: 'temp-map-event',
      title: eventName,
      venue: '📍 Map Location',
      description: '',
      image: '',
      price: 0,
      date: DateTime.now(),
      tags: [],
      likes: 0,
      participantsCount: 0,
      lat: lat,
      lng: lng,
    );

    Get.to(
      () => FullMapScreen(selectedEvent: eventForMap, events: [eventForMap]),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            pinned: true,
            backgroundColor: Colors.black,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white),
              onPressed: widget.onBack,
            ),
            title: const Text(
              'My Calendar',
              style: TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Obx(() {
                if (_isLoading.value) {
                  return const Center(child: CircularProgressIndicator());
                }

                return Column(
                  children: [
                    // Calendar
                    GlassCard(
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: TableCalendar<Event>(
                          firstDay: DateTime.utc(2020, 10, 1),
                          lastDay: DateTime.utc(2030, 12, 31),
                          focusedDay: _focusedDay,
                          selectedDayPredicate: (day) =>
                              isSameDay(_selectedDay, day),
                          onDaySelected: (selectedDay, focusedDay) {
                            setState(() {
                              _selectedDay = selectedDay;
                              _focusedDay = focusedDay;
                            });
                          },
                          onPageChanged: (focusedDay) {
                            _focusedDay = focusedDay;
                          },
                          calendarFormat: _calendarFormat,
                          onFormatChanged: (format) {
                            setState(() {
                              _calendarFormat = format;
                            });
                          },
                          eventLoader: _getEventsForDay,
                          calendarStyle: CalendarStyle(
                            defaultTextStyle: const TextStyle(
                              color: Colors.white70,
                            ),
                            weekendTextStyle: const TextStyle(
                              color: Colors.white70,
                            ),
                            selectedTextStyle: const TextStyle(
                              color: Colors.white,
                            ),
                            todayTextStyle: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                            outsideTextStyle: const TextStyle(
                              color: Colors.white30,
                            ),
                            selectedDecoration: BoxDecoration(
                              color: AppColors.primary,
                              shape: BoxShape.circle,
                            ),
                            todayDecoration: BoxDecoration(
                              color: AppColors.primary.withOpacity(0.3),
                              shape: BoxShape.circle,
                              border: Border.all(color: AppColors.primary),
                            ),
                            markerDecoration: BoxDecoration(
                              color: AppColors.secondary,
                              shape: BoxShape.circle,
                            ),
                            markerSize: 6,
                            markerMargin: const EdgeInsets.symmetric(
                              horizontal: 1,
                            ),
                          ),
                          daysOfWeekStyle: const DaysOfWeekStyle(
                            weekdayStyle: TextStyle(color: Colors.white70),
                            weekendStyle: TextStyle(color: Colors.white70),
                          ),
                          headerStyle: const HeaderStyle(
                            formatButtonVisible: false,
                            titleTextStyle: TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                            ),
                            leftChevronIcon: Icon(
                              Icons.chevron_left,
                              color: Colors.white,
                            ),
                            rightChevronIcon: Icon(
                              Icons.chevron_right,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 24),

                    _buildDayEventList(),
                  ],
                );
              }),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDayEventList() {
    final eventsForSelectedDay = _getEventsForDay(_selectedDay);

    if (eventsForSelectedDay.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.only(top: 20.0),
          child: Text(
            'No plans for ${_formatDate(_selectedDay)}',
            style: const TextStyle(color: Colors.white54, fontSize: 16),
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Plans for ${_formatDate(_selectedDay)}',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 16),
        ...eventsForSelectedDay.map((event) => _buildEventCard(event)),
      ],
    );
  }

  Widget _buildEventCard(Event event) {
    return GestureDetector(
      onTap: () {
        Get.to(
          () => EventDetailScreen(eventId: event.id, onBack: () => Get.back()),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        child: GlassCard(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                // Event image
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
                const SizedBox(width: 16),
                // Event details
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        event.title,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      GestureDetector(
                        onTap: () {
                          // If venue is "📍 View on Map" and we have coordinates, open map
                          if (event.venue.contains('📍') &&
                              event.lat != null &&
                              event.lng != null) {
                            _openMapWithLocation(
                              event.lat!,
                              event.lng!,
                              event.title,
                            );
                          }
                        },
                        child: Text(
                          event.venue,
                          style: TextStyle(
                            color: event.venue.contains('📍')
                                ? AppColors.primary
                                : Colors.white70,
                            fontSize: 14,
                            decoration: event.venue.contains('📍')
                                ? TextDecoration.underline
                                : null,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          const Icon(
                            Icons.access_time,
                            color: AppColors.primary,
                            size: 14,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            event.formattedDate,
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
                const Icon(
                  Icons.arrow_forward_ios,
                  color: Colors.white54,
                  size: 16,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    // Simple format locally without extra package if needed, or stick to basic
    // "January 1, 2025" style
    const months = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }
}
