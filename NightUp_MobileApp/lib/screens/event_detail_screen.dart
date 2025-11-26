import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../theme/colors.dart';
import '../widgets/glass_card.dart';
import '../widgets/image_with_fallback.dart';
import '../widgets/gradient_button.dart';
import '../services/api_service.dart';
import '../models/event.dart';

class EventDetailScreen extends StatefulWidget {
  final VoidCallback onBack;
  final String eventId;
  final VoidCallback? onTinderOpen;
  
  const EventDetailScreen({
    super.key,
    required this.onBack,
    required this.eventId,
    this.onTinderOpen,
  });

  @override
  State<EventDetailScreen> createState() => _EventDetailScreenState();
}

class _EventDetailScreenState extends State<EventDetailScreen> {
  final ApiService _apiService = Get.find<ApiService>();
  
  bool _isLiked = false;
  int _likeCount = 0;
  Event? _event;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadEventData();
  }

  Future<void> _loadEventData() async {
    try {
      print('🔄 Loading event details for ID: ${widget.eventId}');
      
      // Cargar datos del evento
      final response = await _apiService.get('/event/${widget.eventId}');
      print('✅ Event data loaded: ${response.data}');
      
      _event = Event.fromJson(response.data);
      
      // Cargar estado de like
      try {
        final likeResponse = await _apiService.get('/event/${widget.eventId}/like-status');
        setState(() {
          _isLiked = likeResponse.data['liked'] ?? false;
          _likeCount = likeResponse.data['likesCount'] ?? _event?.likes ?? 0;
          _isLoading = false;
        });
      } catch (likeError) {
        print('⚠️ Could not load like status, using default: $likeError');
        setState(() {
          _isLiked = false;
          _likeCount = _event?.likes ?? 0;
          _isLoading = false;
        });
      }
    } catch (e) {
      print('❌ Error loading event details: $e');
      Get.snackbar(
        'Error',
        'No se pudo cargar los detalles del evento',
        snackPosition: SnackPosition.BOTTOM,
      );
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _toggleLike() async {
    if (_event == null) return;

    try {
      setState(() {
        // Actualización optimista
        _isLiked = !_isLiked;
        _likeCount = _isLiked ? _likeCount + 1 : _likeCount - 1;
      });

      if (_isLiked) {
        // Like
        await _apiService.post('/event/${widget.eventId}/like');
        print('✅ Event liked successfully');
      } else {
        // Unlike
        await _apiService.post('/event/${widget.eventId}/unlike');
        print('✅ Event unliked successfully');
      }
    } catch (e) {
      print('❌ Error toggling like: $e');
      // Revertir actualización optimista
      setState(() {
        _isLiked = !_isLiked;
        _likeCount = _isLiked ? _likeCount - 1 : _likeCount + 1;
      });
      
      Get.snackbar(
        'Error',
        'No se pudo actualizar el like',
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  Future<void> _shareEvent() async {
    if (_event == null) return;

    final shareText = '¡Mira este evento: ${_event!.title} en ${_event!.venue}! ${_event!.displayPrice} - ${_event!.formattedDate}';
    
    // Aquí integrarías con el paquete de sharing
    // Por ejemplo: await Share.share(shareText);
    
    Get.snackbar(
      'Compartir',
      'Funcionalidad de compartir pronto disponible',
      snackPosition: SnackPosition.BOTTOM,
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: Colors.black,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(color: AppColors.primary),
              SizedBox(height: 16),
              Text(
                'Cargando evento...',
                style: TextStyle(color: Colors.white70),
              ),
            ],
          ),
        ),
      );
    }

    if (_event == null) {
      return Scaffold(
        backgroundColor: Colors.black,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 64, color: Colors.white70),
              SizedBox(height: 16),
              Text(
                'Evento no encontrado',
                style: TextStyle(color: Colors.white70, fontSize: 16),
              ),
              SizedBox(height: 16),
              ElevatedButton(
                onPressed: widget.onBack,
                child: Text('Volver'),
              ),
            ],
          ),
        ),
      );
    }

    final event = _event!;
    
    return Scaffold(
      backgroundColor: Colors.black,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 300,
            floating: false,
            pinned: true,
            backgroundColor: Colors.transparent,
            leading: Container(
              margin: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.5),
                borderRadius: BorderRadius.circular(20),
              ),
              child: IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.white),
                onPressed: widget.onBack,
              ),
            ),
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                children: [
                  ImageWithFallback(
                    imageUrl: event.safeImageUrl,
                    width: double.infinity,
                    height: double.infinity,
                    fit: BoxFit.cover,
                  ),
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          Colors.transparent,
                          Colors.black.withOpacity(0.8),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              if (widget.onTinderOpen != null)
                Container(
                  margin: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Colors.orange, Colors.red],
                    ),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: IconButton(
                    icon: const Text('🔥', style: TextStyle(fontSize: 20)),
                    onPressed: widget.onTinderOpen,
                  ),
                ),
              Container(
                margin: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: IconButton(
                  icon: Icon(
                    _isLiked ? Icons.favorite : Icons.favorite_border,
                    color: _isLiked ? Colors.red : Colors.white,
                  ),
                  onPressed: _toggleLike, // BOTÓN FUNCIONAL
                ),
              ),
              Container(
                margin: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: IconButton(
                  icon: const Icon(Icons.share, color: Colors.white),
                  onPressed: _shareEvent, // BOTÓN FUNCIONAL
                ),
              ),
            ],
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title and venue
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              event.title,
                              style: const TextStyle(
                                fontSize: 32,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              event.venue,
                              style: const TextStyle(
                                fontSize: 20,
                                color: Colors.white70,
                              ),
                            ),
                          ],
                        ),
                      ),
                      GlassCard(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          child: Row(
                            children: [
                              Icon(Icons.favorite, color: Colors.red, size: 16),
                              const SizedBox(width: 4),
                              Text(
                                _likeCount.toString(),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Tags
                  if (event.tags.isNotEmpty)
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: event.tags.map((tag) {
                        return Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: AppColors.primary.withOpacity(0.3)),
                          ),
                          child: Text(
                            tag,
                            style: const TextStyle(
                              color: AppColors.primary,
                              fontSize: 12,
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  
                  const SizedBox(height: 24),
                  
                  // Quick info cards
                  GridView.count(
                    crossAxisCount: 2,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: 1.5,
                    children: [
                      _buildInfoCard(
                        Icons.calendar_today,
                        'Date',
                        event.formattedDate,
                        AppColors.primary,
                      ),
                      _buildInfoCard(
                        Icons.access_time,
                        'Time',
                        event.formattedDate,
                        AppColors.secondary,
                      ),
                      _buildInfoCard(
                        Icons.attach_money,
                        'Price',
                        event.displayPrice,
                        Colors.green,
                      ),
                      _buildInfoCard(
                        Icons.people,
                        'Attending',
                        '${event.participantsCount}',
                        Colors.purple,
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // Description
                  if (event.description.isNotEmpty)
                    GlassCard(
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'About the Event',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              event.description,
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 14,
                                height: 1.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  
                  const SizedBox(height: 24),
                  
                  // Join button
                  GradientButton(
                    onPressed: _joinEvent, // BOTÓN FUNCIONAL
                    text: 'Join Event',
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

  Widget _buildInfoCard(IconData icon, String title, String value, Color color) {
    return GlassCard(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 8),
            Text(
              title,
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _joinEvent() async {
    if (_event == null) return;

    try {
      await _apiService.post('/event/${widget.eventId}/join');
      Get.snackbar(
        '¡Unido!',
        'Te has unido al evento ${_event!.title}',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.green,
        colorText: Colors.white,
      );
    } catch (e) {
      Get.snackbar(
        'Error',
        'No se pudo unir al evento: $e',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }
}