import 'package:flutter/material.dart';
import 'dart:developer';
import 'package:get/get.dart';
import '../models/conversation.dart';
import '../services/api_service.dart';
import '../theme/colors.dart';
import '../widgets/image_with_fallback.dart';

class GroupInfoScreen extends StatefulWidget {
  final Conversation conversation;

  const GroupInfoScreen({super.key, required this.conversation});

  @override
  State<GroupInfoScreen> createState() => _GroupInfoScreenState();
}

class _GroupInfoScreenState extends State<GroupInfoScreen> {
  final ApiService _apiService = Get.find<ApiService>();
  List<Map<String, dynamic>> _participants = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadParticipants();
  }

  Future<void> _loadParticipants() async {
    try {
      setState(() => _isLoading = true);

      // Cargar datos de cada participante
      final participantsFutures = widget.conversation.participants.map((
        userId,
      ) async {
        try {
          final response = await _apiService.get('/users/$userId');
          if (response.data != null) {
            return {
              'id': userId,
              'username': response.data['username'] ?? 'Usuario',
              'email': response.data['email'] ?? '',
              'avatar': response.data['avatar'],
              'isCreator':
                  widget.conversation.groupParticipants
                      ?.firstWhereOrNull((gp) => gp.userId == userId)
                      ?.isCreator ??
                  false,
              'isAdmin':
                  widget.conversation.groupParticipants
                      ?.firstWhereOrNull((gp) => gp.userId == userId)
                      ?.isAdmin ??
                  false,
            };
          }
        } catch (e) {
          // Si es 404, usuario no encontrado, devolver placeholder sin hacer ruido
          if (e.toString().contains('404')) {
            log('⚠️ Usuario no encontrado (404): $userId', name: 'GroupInfo');
          } else {
            log('Error loading user $userId: $e', name: 'GroupInfo', error: e);
          }
        }
        return {
          'id': userId,
          'username': 'Usuario',
          'email': '',
          'avatar': null,
          'isCreator': false,
          'isAdmin': false,
        };
      });

      final results = await Future.wait(participantsFutures);
      setState(() {
        _participants = results.where((p) => p != null).toList();
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading participants: $e');
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final groupPolls = widget.conversation.groupPolls ?? [];

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.grey[900],
        title: const Text(
          'Información del grupo',
          style: TextStyle(color: Colors.white),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Get.back(),
        ),
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            )
          : SingleChildScrollView(
              child: Column(
                children: [
                  // Header del grupo
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(32),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          AppColors.primary.withOpacity(0.3),
                          Colors.transparent,
                        ],
                      ),
                    ),
                    child: Column(
                      children: [
                        // Avatar del grupo
                        Container(
                          width: 100,
                          height: 100,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: AppColors.primaryGradient,
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.primary.withOpacity(0.5),
                                blurRadius: 20,
                                spreadRadius: 5,
                              ),
                            ],
                          ),
                          child:
                              widget.conversation.avatar.isNotEmpty &&
                                  !widget.conversation.avatar.contains(
                                    'placeholder',
                                  )
                              ? ClipRRect(
                                  borderRadius: BorderRadius.circular(50),
                                  child: ImageWithFallback(
                                    imageUrl: widget.conversation.displayAvatar,
                                    fit: BoxFit.cover,
                                  ),
                                )
                              : const Center(
                                  child: Icon(
                                    Icons.group,
                                    color: Colors.white,
                                    size: 50,
                                  ),
                                ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          widget.conversation.name,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '${_participants.length} participantes',
                          style: TextStyle(color: Colors.white70, fontSize: 14),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Participantes
                  Container(
                    margin: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.grey[900],
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(16),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.people,
                                color: AppColors.primary,
                                size: 24,
                              ),
                              const SizedBox(width: 12),
                              const Text(
                                'Participantes',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Divider(color: Colors.white12, height: 1),
                        ListView.separated(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: _participants.length,
                          separatorBuilder: (context, index) => const Divider(
                            color: Colors.white12,
                            height: 1,
                            indent: 72,
                          ),
                          itemBuilder: (context, index) {
                            final participant = _participants[index];
                            return ListTile(
                              leading: Container(
                                width: 48,
                                height: 48,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: participant['isCreator']
                                        ? AppColors.primary
                                        : Colors.white30,
                                    width: 2,
                                  ),
                                ),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(24),
                                  child: ImageWithFallback(
                                    imageUrl: participant['avatar'] ?? '',
                                    fallbackAsset:
                                        'assets/images/default-avatar.png',
                                    fit: BoxFit.cover,
                                  ),
                                ),
                              ),
                              title: Text(
                                participant['username'],
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              subtitle: participant['isCreator']
                                  ? Row(
                                      children: const [
                                        Icon(
                                          Icons.admin_panel_settings,
                                          color: AppColors.primary,
                                          size: 14,
                                        ),
                                        SizedBox(width: 4),
                                        Text(
                                          'Creador',
                                          style: TextStyle(
                                            color: AppColors.primary,
                                            fontSize: 12,
                                          ),
                                        ),
                                      ],
                                    )
                                  : null,
                              trailing: participant['isCreator']
                                  ? Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 4,
                                      ),
                                      decoration: BoxDecoration(
                                        gradient: AppColors.primaryGradient,
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: const Text(
                                        'ADMIN',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 10,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    )
                                  : null,
                            );
                          },
                        ),
                      ],
                    ),
                  ),

                  // Encuestas del grupo
                  if (groupPolls.isNotEmpty) ...[
                    Container(
                      margin: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.grey[900],
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Column(
                        children: [
                          Padding(
                            padding: const EdgeInsets.all(16),
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.poll,
                                  color: AppColors.primary,
                                  size: 24,
                                ),
                                const SizedBox(width: 12),
                                Text(
                                  'Encuestas (${groupPolls.length})',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const Divider(color: Colors.white12, height: 1),
                          ListView.separated(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: groupPolls.length,
                            separatorBuilder: (context, index) => const Divider(
                              color: Colors.white12,
                              height: 1,
                              indent: 16,
                              endIndent: 16,
                            ),
                            itemBuilder: (context, index) {
                              final poll = groupPolls[index];
                              return ListTile(
                                leading: Container(
                                  width: 40,
                                  height: 40,
                                  decoration: BoxDecoration(
                                    color: AppColors.primary.withOpacity(0.2),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: const Icon(
                                    Icons.bar_chart,
                                    color: AppColors.primary,
                                    size: 20,
                                  ),
                                ),
                                title: Text(
                                  poll.question,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                subtitle: Text(
                                  '${poll.totalVotes} votos',
                                  style: const TextStyle(
                                    color: Colors.white54,
                                    fontSize: 12,
                                  ),
                                ),
                                trailing: poll.isActive
                                    ? Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 4,
                                        ),
                                        decoration: BoxDecoration(
                                          color: AppColors.success,
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                        ),
                                        child: const Text(
                                          'ACTIVA',
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 10,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      )
                                    : null,
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                  ],

                  const SizedBox(height: 32),
                ],
              ),
            ),
    );
  }
}
