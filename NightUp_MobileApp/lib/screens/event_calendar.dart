import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:table_calendar/table_calendar.dart';
import '../controllers/auth_controller.dart';
import '../services/api_service.dart';
import '../theme/colors.dart';
import '../widgets/glass_card.dart';
import '../widgets/image_with_fallback.dart';

class EventsCalendar extends StatefulWidget {
  const EventsCalendar({super.key});

  @override
  State<EventsCalendar> createState() => _EventsCalendarState();
}

class _EventsCalendarState extends State<EventsCalendar> {
  final AuthController _authController = Get.find<AuthController>();
  final ApiService _apiService = Get.find<ApiService>();

  CalendarFormat _calendarFormat = CalendarFormat.month;
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  
  String _selectedFilter = 'All';
  
  final RxList<Map<String, dynamic>> _allEvents = <Map<String, dynamic>>[].obs;
  final RxBool _isLoading = true.obs;

  @override
  void initState() {
    super.initState();
    _selectedDay = _focusedDay;
    _fetchUserEvents();
  }

  Future<void> _fetchUserEvents() async {
    _isLoading.value = true;
    try {
      final user = _authController.currentUser;
      if (user == null) return;

      // ✅ USA TU BACKEND
      final response = await _apiService.get('/event/by-participant/${user.id}');
      
      if (response.data is Map && response.data['events'] is List) {
        _allEvents.value = List<Map<String, dynamic>>.from(response.data['events']);
      } else if (response.data is List) {
        _allEvents.value = List<Map<String, dynamic>>.from(response.data);
      } else {
        _allEvents.clear();
      }
      print('✅ Loaded ${_allEvents.length} events from backend');
    } catch (e) {
      print('❌ Error fetching events: $e');
      _allEvents.clear();
    } finally {
      _isLoading.value = false;
    }
  }

  List<Map<String, dynamic>> _getEventsForDay(DateTime day) {
    return _allEvents.where((event) {
      try {
        final eventDate = DateTime.parse(event['date']?.toString() ?? '');
        return isSameDay(eventDate, day);
      } catch (e) {
        return false;
      }
    }).toList();
  }

  List<Map<String, dynamic>> _getFilteredEvents() {
    final eventsForDay = _getEventsForDay(_selectedDay ?? _focusedDay);
    
    if (_selectedFilter == 'All') {
      return eventsForDay;
    } else if (_selectedFilter == 'Confirmed') {
      return eventsForDay.where((event) {
        final status = event['participationStatus']?.toString().toLowerCase() ?? '';
        return status == 'going' || status == 'confirmed';
      }).toList();
    } else if (_selectedFilter == 'Interested') {
      return eventsForDay.where((event) {
        final status = event['participationStatus']?.toString().toLowerCase() ?? '';
        return status == 'interested';
      }).toList();
    }
    
    return eventsForDay;
  }

  List<Map<String, dynamic>> _getUpcomingEvents() {
    final now = DateTime.now();
    final filteredEvents = _allEvents.where((event) {
      try {
        final eventDate = DateTime.parse(event['date']?.toString() ?? '');
        return eventDate.isAfter(now) || isSameDay(eventDate, now);
      } catch (e) {
        return false;
      }
    }).toList();

    filteredEvents.sort((a, b) {
      try {
        final dateA = DateTime.parse(a['date']?.toString() ?? '');
        final dateB = DateTime.parse(b['date']?.toString() ?? '');
        return dateA.compareTo(dateB);
      } catch (e) {
        return 0;
      }
    });

    return filteredEvents.take(10).toList();
  }

  String _safeString(dynamic value, {String mapKey = 'name'}) {
    if (value == null) return '';
    if (value is String) return value;
    if (value is Map) {
      if (value[mapKey] != null) return value[mapKey].toString();
      if (value['title'] != null) return value['title'].toString();
      if (value['address'] != null) return value['address'].toString();
    }
    return value.toString();
  }

  String _formatEventDate(dynamic date) {
    if (date == null) return '';
    try {
      final dateTime = DateTime.parse(date.toString());
      final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
      return '${months[dateTime.month - 1]} ${dateTime.day}, ${dateTime.year}';
    } catch (e) {
      return '';
    }
  }

  String _formatEventTime(dynamic date) {
    if (date == null) return '';
    try {
      final dateTime = DateTime.parse(date.toString());
      final hour = dateTime.hour > 12 ? dateTime.hour - 12 : (dateTime.hour == 0 ? 12 : dateTime.hour);
      final minute = dateTime.minute.toString().padLeft(2, '0');
      final period = dateTime.hour >= 12 ? 'PM' : 'AM';
      return '$hour:$minute $period';
    } catch (e) {
      return '';
    }
  }

  Widget _buildFilterChip(String label, String value) {
    final isSelected = _selectedFilter == value;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedFilter = value;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? AppColors.primary : Colors.white30,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.black : Colors.white,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  Widget _buildEventCard(Map<String, dynamic> event) {
    final status = event['participationStatus']?.toString().toLowerCase() ?? '';
    final isGoing = status == 'going' || status == 'confirmed';
    final isInterested = status == 'interested';

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: GlassCard(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: SizedBox(
                  width: 80,
                  height: 80,
                  child: ImageWithFallback(
                    imageUrl: _safeString(event['image']),
                    fallbackAsset: 'assets/images/default-event.jpg',
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            _safeString(event['name']),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (isGoing)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.green.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.green),
                            ),
                            child: const Text(
                              'Going',
                              style: TextStyle(color: Colors.green, fontSize: 10),
                            ),
                          )
                        else if (isInterested)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.orange.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.orange),
                            ),
                            child: const Text(
                              'Interested',
                              style: TextStyle(color: Colors.orange, fontSize: 10),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _safeString(event['location']),
                      style: const TextStyle(color: AppColors.primary, fontSize: 13),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(Icons.calendar_today, color: Colors.white70, size: 12),
                        const SizedBox(width: 4),
                        Text(
                          '${_formatEventDate(event['date'])} • ${_formatEventTime(event['date'])}',
                          style: const TextStyle(color: Colors.white70, fontSize: 12),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: const Text('Events Calendar', style: TextStyle(color: Colors.white)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Obx(() {
        if (_isLoading.value) {
          return const Center(child: CircularProgressIndicator(color: AppColors.primary));
        }

        return SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Filtros
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    _buildFilterChip('All', 'All'),
                    const SizedBox(width: 12),
                    _buildFilterChip('Confirmed', 'Confirmed'),
                    const SizedBox(width: 12),
                    _buildFilterChip('Interested', 'Interested'),
                  ],
                ),
              ),

              // Calendario
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.white.withOpacity(0.1)),
                ),
                child: TableCalendar(
                  firstDay: DateTime.utc(2020, 1, 1),
                  lastDay: DateTime.utc(2030, 12, 31),
                  focusedDay: _focusedDay,
                  calendarFormat: _calendarFormat,
                  selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
                  eventLoader: _getEventsForDay,
                  onDaySelected: (selectedDay, focusedDay) {
                    setState(() {
                      _selectedDay = selectedDay;
                      _focusedDay = focusedDay;
                    });
                  },
                  onFormatChanged: (format) {
                    setState(() {
                      _calendarFormat = format;
                    });
                  },
                  onPageChanged: (focusedDay) {
                    _focusedDay = focusedDay;
                  },
                  calendarStyle: CalendarStyle(
                    outsideDaysVisible: true,
                    weekendTextStyle: const TextStyle(color: Colors.white70),
                    defaultTextStyle: const TextStyle(color: Colors.white),
                    selectedDecoration: BoxDecoration(
                      color: AppColors.primary,
                      shape: BoxShape.circle,
                    ),
                    todayDecoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.3),
                      shape: BoxShape.circle,
                    ),
                    markerDecoration: const BoxDecoration(
                      color: AppColors.primary,
                      shape: BoxShape.circle,
                    ),
                  ),
                  headerStyle: HeaderStyle(
                    formatButtonVisible: false,
                    titleCentered: true,
                    titleTextStyle: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                    leftChevronIcon: const Icon(Icons.chevron_left, color: Colors.white),
                    rightChevronIcon: const Icon(Icons.chevron_right, color: Colors.white),
                  ),
                  daysOfWeekStyle: const DaysOfWeekStyle(
                    weekdayStyle: TextStyle(color: Colors.white70),
                    weekendStyle: TextStyle(color: Colors.white70),
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // Eventos del día
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  _getFilteredEvents().isEmpty
                      ? 'No events today'
                      : 'Events on ${_formatEventDate(_selectedDay)}',
                  style: const TextStyle(color: Colors.white70, fontSize: 14),
                ),
              ),

              const SizedBox(height: 8),

              if (_getFilteredEvents().isEmpty)
                const Padding(
                  padding: EdgeInsets.all(32),
                  child: Center(
                    child: Text('Check out upcoming events below', style: TextStyle(color: Colors.white70)),
                  ),
                )
              else
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    children: _getFilteredEvents().map((event) => _buildEventCard(event)).toList(),
                  ),
                ),

              const SizedBox(height: 24),

              // Upcoming Events
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: Text('Upcoming Events', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w600)),
              ),

              const SizedBox(height: 16),

              if (_getUpcomingEvents().isEmpty)
                const Padding(
                  padding: EdgeInsets.all(32),
                  child: Center(child: Text('No upcoming events', style: TextStyle(color: Colors.white70))),
                )
              else
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    children: _getUpcomingEvents().map((event) => _buildEventCard(event)).toList(),
                  ),
                ),

              const SizedBox(height: 100),
            ],
          ),
        );
      }),
    );
  }
}