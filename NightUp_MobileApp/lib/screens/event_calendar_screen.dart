import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import '../theme/colors.dart';
import '../widgets/glass_card.dart';
import '../widgets/image_with_fallback.dart';

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
  late Map<DateTime, List<Event>> _events;

  @override
  void initState() {
    super.initState();
    _calendarFormat = CalendarFormat.month;
    _focusedDay = DateTime.now();
    _selectedDay = DateTime.now();
    _events = _getEvents();
  }

  Map<DateTime, List<Event>> _getEvents() {
    final events = <DateTime, List<Event>>{};
    
    // Add sample events for November 2025
    events[DateTime(2025, 11, 21)] = [
      Event(
        id: 1,
        name: 'Neon Techno Nights',
        venue: 'Opium Club',
        date: DateTime(2025, 11, 21),
        time: '10:00 PM',
        image: 'https://images.unsplash.com/photo-1713885462557-12b5c41f22cd',
        status: EventStatus.confirmed,
      ),
    ];
    
    events[DateTime(2025, 11, 22)] = [
      Event(
        id: 2,
        name: 'Saturday House Sessions',
        venue: 'The Basement',
        date: DateTime(2025, 11, 22),
        time: '9:00 PM',
        image: 'https://images.unsplash.com/photo-1641203251058-3eb0ad540780',
        status: EventStatus.confirmed,
      ),
    ];
    
    events[DateTime(2025, 11, 23)] = [
      Event(
        id: 3,
        name: 'EDM Festival Weekend',
        venue: 'Skybar Rooftop',
        date: DateTime(2025, 11, 23),
        time: '8:00 PM',
        image: 'https://images.unsplash.com/photo-1689783101582-98feb9393a57',
        status: EventStatus.interested,
      ),
    ];
    
    events[DateTime(2025, 11, 24)] = [
      Event(
        id: 4,
        name: 'Rooftop Sunset Party',
        venue: 'Skybar Rooftop',
        date: DateTime(2025, 11, 24),
        time: '6:00 PM',
        image: 'https://images.unsplash.com/photo-1574391884720-bbc3740c59d1',
        status: EventStatus.interested,
      ),
    ];
    
    return events;
  }

  List<Event> _getEventsForDay(DateTime day) {
    return _events[day] ?? [];
  }

  @override
  Widget build(BuildContext context) {
    final eventsForSelectedDay = _getEventsForDay(_selectedDay);
    final allEvents = _events.values.expand((x) => x).toList();

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
              'Events Calendar',
              style: TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(60),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  children: [
                    _buildFilterButton('All', true),
                    const SizedBox(width: 8),
                    _buildFilterButton('Confirmed', false),
                    const SizedBox(width: 8),
                    _buildFilterButton('Interested', false),
                  ],
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  // Calendar
                  GlassCard(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: TableCalendar(
                        firstDay: DateTime.utc(2025, 10, 1),
                        lastDay: DateTime.utc(2025, 12, 31),
                        focusedDay: _focusedDay,
                        selectedDayPredicate: (day) {
                          return isSameDay(_selectedDay, day);
                        },
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
                          defaultTextStyle: const TextStyle(color: Colors.white70),
                          weekendTextStyle: const TextStyle(color: Colors.white70),
                          selectedTextStyle: const TextStyle(color: Colors.white),
                          todayTextStyle: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                          outsideTextStyle: const TextStyle(color: Colors.white30),
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
                            color: AppColors.primary,
                            shape: BoxShape.circle,
                          ),
                          markerSize: 6,
                          markerMargin: const EdgeInsets.symmetric(horizontal: 1),
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
                          leftChevronIcon: Icon(Icons.chevron_left, color: Colors.white),
                          rightChevronIcon: Icon(Icons.chevron_right, color: Colors.white),
                        ),
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // Events for selected day
                  if (eventsForSelectedDay.isNotEmpty)
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Events on ${_formatDate(_selectedDay)}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 16),
                        ...eventsForSelectedDay.map((event) => _buildEventCard(event)),
                      ],
                    )
                  else if (isSameDay(_selectedDay, DateTime.now()))
                    Column(
                      children: [
                        const Text(
                          'No events today',
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Check out upcoming events below',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.5),
                            fontSize: 14,
                          ),
                        ),
                      ],
                    )
                  else
                    Column(
                      children: [
                        Text(
                          'No events on ${_formatDate(_selectedDay)}',
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  
                  const SizedBox(height: 24),
                  
                  // All upcoming events
                  if (!isSameDay(_selectedDay, DateTime.now()) || eventsForSelectedDay.isEmpty)
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Upcoming Events',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 16),
                        ...allEvents.map((event) => _buildEventCard(event)),
                      ],
                    ),
                  
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterButton(String text, bool isActive) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: isActive ? AppColors.primary : AppColors.glassWhite,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: isActive ? Colors.white : Colors.white70,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Widget _buildEventCard(Event event) {
    return Container(
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
                    imageUrl: event.image,
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
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                event.name,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                event.venue,
                                style: const TextStyle(
                                  color: Colors.white70,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: event.status == EventStatus.confirmed
                                ? Colors.green.withOpacity(0.2)
                                : AppColors.secondary.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: event.status == EventStatus.confirmed
                                  ? Colors.green
                                  : AppColors.secondary,
                              width: 1,
                            ),
                          ),
                          child: Text(
                            event.status == EventStatus.confirmed ? 'Going' : 'Interested',
                            style: TextStyle(
                              color: event.status == EventStatus.confirmed
                                  ? Colors.green
                                  : AppColors.secondary,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(
                          Icons.calendar_today,
                          color: Colors.white70,
                          size: 16,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          '${_formatDate(event.date)} • ${event.time}',
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Container(
                      width: double.infinity,
                      height: 36,
                      decoration: BoxDecoration(
                        gradient: AppColors.primaryGradient,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Center(
                        child: Text(
                          'View Details',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
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

  String _formatDate(DateTime date) {
    return '${_getMonthName(date.month)} ${date.day}, ${date.year}';
  }

  String _getMonthName(int month) {
    switch (month) {
      case 1: return 'January';
      case 2: return 'February';
      case 3: return 'March';
      case 4: return 'April';
      case 5: return 'May';
      case 6: return 'June';
      case 7: return 'July';
      case 8: return 'August';
      case 9: return 'September';
      case 10: return 'October';
      case 11: return 'November';
      case 12: return 'December';
      default: return '';
    }
  }
}

class Event {
  final int id;
  final String name;
  final String venue;
  final DateTime date;
  final String time;
  final String image;
  final EventStatus status;

  Event({
    required this.id,
    required this.name,
    required this.venue,
    required this.date,
    required this.time,
    required this.image,
    required this.status,
  });
}

enum EventStatus {
  confirmed,
  interested,
}