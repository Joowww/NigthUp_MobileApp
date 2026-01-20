import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'dart:developer';
import 'dart:convert';
import 'package:dio/dio.dart' as dio;
import '../theme/colors.dart';
import '../widgets/glass_card.dart';
import '../widgets/image_with_fallback.dart';
import '../widgets/gradient_button.dart';
import '../services/api_service.dart';
import '../models/event.dart';
import 'friend_profile_screen.dart';
import '../controllers/auth_controller.dart';

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
  bool _isJoined = false;
  List<Map<String, dynamic>> _participants = [];
  bool _loadingParticipants = false;
  Map<String, dynamic>? _ratingStats;
  List<Map<String, dynamic>> _eventRatings = [];
  Map<String, dynamic>? _myRating;
  bool _loadingRatings = false;

  @override
  void initState() {
    super.initState();
    _loadEventData();
    _fetchRatings();
  }

  Future<void> _loadEventData() async {
    try {
      final response = await _apiService.get('/event/${widget.eventId}');
      _event = Event.fromJson(response.data);
      final userId = _apiService.getUserId();
      try {
        final likeResponse = await _apiService.get(
          '/event/${widget.eventId}/like-status',
        );
        final isLiked = likeResponse.data['liked'] ?? false;
        final likesCount =
            likeResponse.data['likesCount'] ?? _event?.likes ?? 0;
        bool isJoined = false;
        if (userId != null && _event != null) {
          final joinResp = await _apiService.get(
            '/event/is-participant/${widget.eventId}/$userId',
          );
          isJoined = joinResp.data['isParticipant'] == true;
        }
        setState(() {
          _isLiked = isLiked;
          _likeCount = likesCount;
          _isJoined = isJoined;
          _isLoading = false;
        });
      } catch (likeError) {
        debugPrint('⚠️ Could not load like status: $likeError');
        setState(() {
          _isLiked = false;
          _likeCount = _event?.likes ?? 0;
          _isJoined = false;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (e is dio.DioError && e.response != null) {
        if (e.response?.statusCode == 401) {
          log('🔐 Sesión expirada. Por favor inicia sesión de nuevo.');
          Get.snackbar(
            'Sesión expirada',
            'Por favor inicia sesión de nuevo',
            snackPosition: SnackPosition.BOTTOM,
          );
        } else if (e.response?.statusCode == 404) {
          log('❌ Recurso no encontrado (404)');
          Get.snackbar(
            'No encontrado',
            'El evento no existe o fue eliminado',
            snackPosition: SnackPosition.BOTTOM,
          );
        } else {
          log('❌ Error loading event details: $e');
          Get.snackbar(
            'Error',
            'No se pudo cargar los detalles del evento',
            snackPosition: SnackPosition.BOTTOM,
          );
        }
      } else {
        log('❌ Error loading event details: $e');
        Get.snackbar(
          'Error',
          'No se pudo cargar los detalles del evento',
          snackPosition: SnackPosition.BOTTOM,
        );
      }
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _fetchRatings() async {
    setState(() {
      _loadingRatings = true;
    });
    try {
      final statsResp = await _apiService.get(
        '/rating/event/${widget.eventId}/stats',
      );
      if (statsResp.data is Map) _ratingStats = statsResp.data;

      final ratingsResp = await _apiService.get(
        '/rating/event/${widget.eventId}',
      );
      if (ratingsResp.data is List) {
        _eventRatings = List<Map<String, dynamic>>.from(ratingsResp.data);
      } else if (ratingsResp.data is Map &&
          ratingsResp.data['ratings'] is List) {
        _eventRatings = List<Map<String, dynamic>>.from(
          ratingsResp.data['ratings'],
        );
      } else {
        _eventRatings = [];
      }

      final userId = _apiService.getUserId();
      if (userId != null && _event != null) {
        try {
          final myRatingResp = await _apiService.get(
            '/rating/user/$userId/event/${widget.eventId}',
          );
          if (myRatingResp.data is Map && myRatingResp.data.isNotEmpty) {
            _myRating = Map<String, dynamic>.from(myRatingResp.data);
          } else {
            _myRating = null;
          }
        } catch (e) {
          try {
            final currentUser = Get.find<AuthController>().currentUser;
            if (currentUser != null && currentUser.username != null) {
              final myRatingResp = await _apiService.get(
                '/rating/user/${currentUser.username}/event/${widget.eventId}',
              );
              if (myRatingResp.data is Map && myRatingResp.data.isNotEmpty) {
                _myRating = Map<String, dynamic>.from(myRatingResp.data);
              } else {
                _myRating = null;
              }
            }
          } catch (e2) {
            _myRating = null;
          }
        }
      }
    } catch (e) {
      print('❌ Error fetching ratings: $e');
      _ratingStats = null;
      _eventRatings = [];
      _myRating = null;
    } finally {
      setState(() {
        _loadingRatings = false;
      });
    }
  }

  Future<void> _toggleLike() async {
    if (_event == null) return;

    try {
      setState(() {
        _isLiked = !_isLiked;
        _likeCount = _isLiked ? _likeCount + 1 : _likeCount - 1;
      });

      if (_isLiked) {
        await _apiService.post('/event/${widget.eventId}/like', data: {});
        log('✅ Event liked successfully');
      } else {
        await _apiService.post('/event/${widget.eventId}/unlike', data: {});
        log('✅ Event unliked successfully');
      }
    } catch (e) {
      log('❌ Error toggling like: $e');
      setState(() {
        _isLiked = !_isLiked;
        _likeCount = _isLiked ? _likeCount - 1 : _likeCount + 1;
      });

      Get.snackbar(
        'Error',
        'No se pudo actualizar el like: $e',
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  Future<void> _shareEvent() async {
    if (_event == null) return;

    final shareText =
        '¡Mira este evento: ${_event!.title} en ${_event!.venue}! ${_event!.displayPrice} - ${_event!.formattedDate}';
    final eventUrl = 'https://nightup.com/events/${_event!.id}';

    log('📤 Sharing event: ${_event!.id}');

    try {
      await Get.dialog(
        Dialog(
          backgroundColor: Colors.transparent,
          child: Container(
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.primary.withOpacity(0.3)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: AppColors.neonGradient,
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(20),
                      topRight: Radius.circular(20),
                    ),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.share, color: Colors.white, size: 24),
                      SizedBox(width: 12),
                      Text(
                        'Compartir Evento',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),

                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      const Text(
                        'Copia el texto para compartir:',
                        style: TextStyle(color: Colors.white, fontSize: 16),
                      ),
                      const SizedBox(height: 16),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppColors.glassWhite,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppColors.glassBorder),
                        ),
                        child: SelectableText(
                          '$shareText\n$eventUrl',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Selecciona y copia el texto',
                        style: TextStyle(
                          color: AppColors.primary,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),

                Container(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextButton(
                          onPressed: () {
                            Get.back();
                          },
                          style: TextButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Text(
                            'Cerrar',
                            style: TextStyle(
                              color: Colors.white,
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
        barrierDismissible: true,
      );
    } catch (e) {
      log('❌ Error sharing event: $e');
      Get.snackbar(
        'Compartir',
        'Texto listo para compartir: ${_event!.title}',
        snackPosition: SnackPosition.BOTTOM,
        duration: const Duration(seconds: 3),
      );
    }
  }

  Future<void> _joinEvent() async {
    if (_event == null) return;
    try {
      final userId = _apiService.getUserId();
      if (userId == null) {
        Get.snackbar(
          'Error',
          'No se pudo identificar al usuario',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red,
          colorText: Colors.white,
        );
        return;
      }
      if (!_isJoined) {
        await _apiService.post('/event/${widget.eventId}/join', data: {});
        setState(() {
          _isJoined = true;
        });
        final joinResp = await _apiService.get(
          '/event/is-participant/${widget.eventId}/$userId',
        );
        setState(() {
          _isJoined = joinResp.data['isParticipant'] == true;
        });
        Get.snackbar(
          '¡Unido!',
          'Te has unido al evento ${_event!.title}',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.green,
          colorText: Colors.white,
        );
      } else {
        await _apiService.post('/event/${widget.eventId}/leave', data: {});
        setState(() {
          _isJoined = false;
        });
        final joinResp = await _apiService.get(
          '/event/is-participant/${widget.eventId}/$userId',
        );
        setState(() {
          _isJoined = joinResp.data['isParticipant'] == true;
        });
        Get.snackbar(
          '¡Saliste!',
          'Has salido del evento ${_event!.title}',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.orange,
          colorText: Colors.white,
        );
      }
    } catch (e) {
      debugPrint('❌ Error in join/leave: $e');
      Get.snackbar(
        'Error',
        'No se pudo actualizar la participación: $e',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }

  Future<void> _showParticipantsDialog() async {
    setState(() {
      _loadingParticipants = true;
    });
    try {
      final response = await _apiService.get(
        '/event/${widget.eventId}/participants',
      );
      List<dynamic> data = [];
      if (response.data is Map && response.data['participants'] is List) {
        data = response.data['participants'];
      } else if (response.data is List) {
        data = response.data;
      }
      _participants = data.cast<Map<String, dynamic>>();
    } catch (e) {
      _participants = [];
    } finally {
      setState(() {
        _loadingParticipants = false;
      });
    }
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.black,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        if (_loadingParticipants) {
          return const Padding(
            padding: EdgeInsets.all(32),
            child: Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            ),
          );
        }
        if (_participants.isEmpty) {
          return const Padding(
            padding: EdgeInsets.all(32),
            child: Center(
              child: Text(
                'No hay participantes',
                style: TextStyle(color: Colors.white70),
              ),
            ),
          );
        }
        return ListView.separated(
          padding: const EdgeInsets.all(24),
          itemCount: _participants.length,
          separatorBuilder: (_, __) => const Divider(color: Colors.white12),
          itemBuilder: (context, index) {
            final user = _participants[index];

            return ListTile(
              leading: ClipOval(
                child: SizedBox(
                  width: 40,
                  height: 40,
                  child: ImageWithFallback(
                    imageUrl: user['avatar']?.toString(),
                    fallbackAsset: 'assets/images/default-avatar.png',
                    fit: BoxFit.cover,
                    width: 40,
                    height: 40,
                  ),
                ),
              ),
              title: Text(
                user['username'] ?? 'Usuario',
                style: const TextStyle(color: Colors.white),
              ),
              onTap: () {
                Navigator.of(context).pop();
                Get.to(() => FriendProfileScreen(friendId: user['_id']));
              },
            );
          },
        );
      },
    );
  }

  Future<void> _showRatingDialog({bool edit = false}) async {
    final TextEditingController commentCtrl = TextEditingController(
      text: (edit && _myRating != null) ? (_myRating!['comment'] ?? '') : '',
    );
    int score = edit ? (_myRating?['score'] ?? 5) : 5;
    final currentUser = Get.find<AuthController>().currentUser;
    final username = currentUser?.username;
    await showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              backgroundColor: Colors.black,
              title: Text(
                edit ? 'Editar valoración' : 'Valorar evento',
                style: const TextStyle(color: Colors.white),
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(
                        5,
                        (i) => Flexible(
                          child: IconButton(
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                            icon: Icon(
                              i < score ? Icons.star : Icons.star_border,
                              color: Colors.amber,
                              size: 32,
                            ),
                            onPressed: () {
                              setState(() {
                                score = i + 1;
                              });
                            },
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: commentCtrl,
                      maxLines: 3,
                      style: const TextStyle(color: Colors.white),
                      decoration: const InputDecoration(
                        hintText: 'Comentario (opcional)',
                        hintStyle: TextStyle(color: Colors.white54),
                        border: OutlineInputBorder(),
                        filled: true,
                        fillColor: Colors.white10,
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                if (edit && _myRating != null)
                  TextButton(
                    onPressed: () async {
                      try {
                        await _apiService.delete(
                          '/rating/${_myRating!['_id']}',
                        );
                        Navigator.of(context).pop();
                        await _fetchRatings();
                        Get.snackbar(
                          'Valoración eliminada',
                          'Tu valoración ha sido eliminada',
                          snackPosition: SnackPosition.BOTTOM,
                        );
                      } catch (e) {
                        Get.snackbar(
                          'Error',
                          'No se pudo eliminar la valoración: $e',
                          snackPosition: SnackPosition.BOTTOM,
                        );
                      }
                    },
                    child: const Text(
                      'Eliminar valoración',
                      style: TextStyle(color: Colors.red),
                    ),
                  ),
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text(
                    'Cancelar',
                    style: TextStyle(color: Colors.white70),
                  ),
                ),
                ElevatedButton(
                  onPressed: () async {
                    try {
                      if (username == null || username.isEmpty) {
                        Get.snackbar(
                          'Error',
                          'Usuario no identificado',
                          snackPosition: SnackPosition.BOTTOM,
                        );
                        return;
                      }

                      if (edit && _myRating != null) {
                        await _apiService.patch(
                          '/rating/${_myRating!['_id']}',
                          data: {'score': score, 'comment': commentCtrl.text},
                        );
                      } else {
                        await _apiService.post(
                          '/rating',
                          data: {
                            'event': widget.eventId,
                            'username': username,
                            'score': score,
                            'comment': commentCtrl.text,
                          },
                        );
                      }
                      Navigator.of(context).pop();
                      await _fetchRatings();
                      Get.snackbar(
                        '¡Gracias!',
                        'Tu valoración ha sido guardada',
                        snackPosition: SnackPosition.BOTTOM,
                      );
                    } catch (e) {
                      Get.snackbar(
                        'Error',
                        'No se pudo guardar la valoración: $e',
                        snackPosition: SnackPosition.BOTTOM,
                      );
                    }
                  },
                  child: Text(edit ? 'Actualizar' : 'Enviar'),
                ),
              ],
            );
          },
        );
      },
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
              const SizedBox(height: 16),
              const Text(
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
              const Icon(Icons.error_outline, size: 64, color: Colors.white70),
              const SizedBox(height: 16),
              const Text(
                'Evento no encontrado',
                style: TextStyle(color: Colors.white70, fontSize: 16),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: widget.onBack,
                child: const Text('Volver'),
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
                    fallbackAsset: 'assets/images/default-event.jpg',
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
                  onPressed: _toggleLike,
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
                  onPressed: _shareEvent,
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
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
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

                  if (event.tags.isNotEmpty)
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: event.tags.map((tag) {
                        return Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: AppColors.primary.withOpacity(0.3),
                            ),
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
                        'Fecha',
                        event.formattedDate,
                        AppColors.primary,
                      ),
                      _buildInfoCard(
                        Icons.access_time,
                        'Hora',
                        event.formattedDate,
                        AppColors.secondary,
                      ),
                      _buildInfoCard(
                        Icons.attach_money,
                        'Precio',
                        event.displayPrice,
                        Colors.green,
                      ),
                      _buildInfoCard(
                        Icons.people,
                        'Asistentes',
                        '${event.participantsCount}',
                        Colors.purple,
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),

                  if (event.description.isNotEmpty)
                    GlassCard(
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Sobre el evento',
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

                  _isJoined
                      ? Container(
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Colors.red, Colors.orange],
                            ),
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.red.withOpacity(0.3),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Material(
                            color: Colors.transparent,
                            child: InkWell(
                              onTap: _joinEvent,
                              borderRadius: BorderRadius.circular(12),
                              child: Container(
                                height: 48,
                                alignment: Alignment.center,
                                child: const Text(
                                  'Salir del evento',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        )
                      : GradientButton(
                          onPressed: _joinEvent,
                          text: 'Unirse al evento',
                        ),

                  if (_isJoined ||
                      (!_isJoined &&
                          _event != null &&
                          _event!.participantsCount > 0))
                    Padding(
                      padding: const EdgeInsets.only(top: 16.0),
                      child: OutlinedButton.icon(
                        onPressed: _showParticipantsDialog,
                        icon: const Icon(Icons.people, color: Colors.white),
                        label: const Text(
                          'Ver participantes',
                          style: TextStyle(color: Colors.white),
                        ),
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: AppColors.primary),
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ),

                  const SizedBox(height: 24),

                  GlassCard(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(
                                Icons.star,
                                color: Colors.amber,
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                _ratingStats != null &&
                                        _ratingStats!['average'] != null
                                    ? (_ratingStats!['average'] as num)
                                          .toStringAsFixed(1)
                                    : '--',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                '(${_ratingStats != null && _ratingStats!['count'] != null ? _ratingStats!['count'] : 0} valoraciones)',
                                style: const TextStyle(
                                  color: Colors.white70,
                                  fontSize: 14,
                                ),
                              ),
                              const Spacer(),
                              if (!_loadingRatings && _myRating == null)
                                OutlinedButton(
                                  onPressed: () => _showRatingDialog(),
                                  child: const Text(
                                    'Valorar',
                                    style: TextStyle(color: Colors.amber),
                                  ),
                                  style: OutlinedButton.styleFrom(
                                    side: const BorderSide(color: Colors.amber),
                                  ),
                                ),
                              if (!_loadingRatings && _myRating != null)
                                OutlinedButton(
                                  onPressed: () =>
                                      _showRatingDialog(edit: true),
                                  child: const Text(
                                    'Editar',
                                    style: TextStyle(color: Colors.amber),
                                  ),
                                  style: OutlinedButton.styleFrom(
                                    side: const BorderSide(color: Colors.amber),
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          if (_loadingRatings)
                            const Center(
                              child: CircularProgressIndicator(
                                color: Colors.amber,
                              ),
                            ),
                          if (!_loadingRatings && _eventRatings.isEmpty)
                            const Text(
                              'Sé el primero en valorar este evento',
                              style: TextStyle(color: Colors.white54),
                            ),
                          if (!_loadingRatings && _eventRatings.isNotEmpty)
                            ..._eventRatings
                                .take(5)
                                .map(
                                  (r) => Padding(
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 6,
                                    ),
                                    child: Row(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        ClipOval(
                                          child: SizedBox(
                                            width: 32,
                                            height: 32,
                                            child: ImageWithFallback(
                                              imageUrl: r['avatar']?.toString(),
                                              fallbackAsset:
                                                  'assets/images/default-avatar.png',
                                              fit: BoxFit.cover,
                                              width: 32,
                                              height: 32,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 10),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Row(
                                                children: [
                                                  Text(
                                                    r['username'] ?? '',
                                                    style: const TextStyle(
                                                      color: Colors.white,
                                                      fontWeight:
                                                          FontWeight.w600,
                                                    ),
                                                  ),
                                                  const SizedBox(width: 8),
                                                  ...List.generate(
                                                    5,
                                                    (i) => Icon(
                                                      i < (r['score'] ?? 0)
                                                          ? Icons.star
                                                          : Icons.star_border,
                                                      color: Colors.amber,
                                                      size: 16,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                              if ((r['comment'] ?? '')
                                                  .toString()
                                                  .isNotEmpty)
                                                Padding(
                                                  padding:
                                                      const EdgeInsets.only(
                                                        top: 2.0,
                                                      ),
                                                  child: Text(
                                                    r['comment'],
                                                    style: const TextStyle(
                                                      color: Colors.white70,
                                                      fontSize: 13,
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
                          if (!_loadingRatings && _eventRatings.length > 5)
                            TextButton(
                              onPressed: () async {
                                await showDialog(
                                  context: context,
                                  builder: (context) {
                                    return AlertDialog(
                                      backgroundColor: Colors.black,
                                      title: const Text(
                                        'Todas las valoraciones',
                                        style: TextStyle(color: Colors.white),
                                      ),
                                      content: SizedBox(
                                        width: double.maxFinite,
                                        child: ListView(
                                          shrinkWrap: true,
                                          children: _eventRatings
                                              .map(
                                                (r) => Padding(
                                                  padding:
                                                      const EdgeInsets.symmetric(
                                                        vertical: 6,
                                                      ),
                                                  child: Row(
                                                    crossAxisAlignment:
                                                        CrossAxisAlignment
                                                            .start,
                                                    children: [
                                                      ClipOval(
                                                        child: SizedBox(
                                                          width: 32,
                                                          height: 32,
                                                          child: ImageWithFallback(
                                                            imageUrl: r['avatar']
                                                                ?.toString(),
                                                            fallbackAsset:
                                                                'assets/images/default-avatar.png',
                                                            fit: BoxFit.cover,
                                                            width: 32,
                                                            height: 32,
                                                          ),
                                                        ),
                                                      ),
                                                      const SizedBox(width: 10),
                                                      Expanded(
                                                        child: Column(
                                                          crossAxisAlignment:
                                                              CrossAxisAlignment
                                                                  .start,
                                                          children: [
                                                            Row(
                                                              children: [
                                                                Text(
                                                                  r['username'] ??
                                                                      '',
                                                                  style: const TextStyle(
                                                                    color: Colors
                                                                        .white,
                                                                    fontWeight:
                                                                        FontWeight
                                                                            .w600,
                                                                  ),
                                                                ),
                                                                const SizedBox(
                                                                  width: 8,
                                                                ),
                                                                ...List.generate(
                                                                  5,
                                                                  (i) => Icon(
                                                                    i <
                                                                            (r['score'] ??
                                                                                0)
                                                                        ? Icons
                                                                              .star
                                                                        : Icons
                                                                              .star_border,
                                                                    color: Colors
                                                                        .amber,
                                                                    size: 16,
                                                                  ),
                                                                ),
                                                              ],
                                                            ),
                                                            if ((r['comment'] ??
                                                                    '')
                                                                .toString()
                                                                .isNotEmpty)
                                                              Padding(
                                                                padding:
                                                                    const EdgeInsets.only(
                                                                      top: 2.0,
                                                                    ),
                                                                child: Text(
                                                                  r['comment'],
                                                                  style: const TextStyle(
                                                                    color: Colors
                                                                        .white70,
                                                                    fontSize:
                                                                        13,
                                                                  ),
                                                                ),
                                                              ),
                                                          ],
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                              )
                                              .toList(),
                                        ),
                                      ),
                                      actions: [
                                        TextButton(
                                          onPressed: () =>
                                              Navigator.of(context).pop(),
                                          child: const Text(
                                            'Cerrar',
                                            style: TextStyle(
                                              color: Colors.white70,
                                            ),
                                          ),
                                        ),
                                      ],
                                    );
                                  },
                                );
                              },
                              child: const Text(
                                'Ver todas las valoraciones',
                                style: TextStyle(color: Colors.amber),
                              ),
                            ),
                        ],
                      ),
                    ),
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

  Widget _buildInfoCard(
    IconData icon,
    String title,
    String value,
    Color color,
  ) {
    return GlassCard(
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(height: 6),
            Text(
              title,
              style: const TextStyle(color: Colors.white70, fontSize: 12),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 2),
            Flexible(
              child: Text(
                value,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
