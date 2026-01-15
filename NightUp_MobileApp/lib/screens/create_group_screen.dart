import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/chat_controller.dart';
import '../services/api_service.dart';
import '../theme/colors.dart';
import '../widgets/glass_card.dart';
import '../widgets/image_with_fallback.dart';

class CreateGroupScreen extends StatefulWidget {
  const CreateGroupScreen({super.key});

  @override
  State<CreateGroupScreen> createState() => _CreateGroupScreenState();
}

class _CreateGroupScreenState extends State<CreateGroupScreen> {
  final TextEditingController _groupNameController = TextEditingController();
  final ChatController _chatController = Get.find<ChatController>();
  final ApiService _apiService = Get.find<ApiService>();

  final RxList<String> selectedParticipants = <String>[].obs;
  final RxList<dynamic> friends = <dynamic>[].obs;
  final RxBool isLoadingFriends = true.obs;
  final RxBool isCreating = false.obs;

  @override
  void initState() {
    super.initState();
    _loadFriends();
  }

  @override
  void dispose() {
    _groupNameController.dispose();
    super.dispose();
  }

  Future<void> _loadFriends() async {
    isLoadingFriends.value = true;
    try {
      final response = await _apiService.get('/friendship/friends');

      if (response.data != null) {
        final List<dynamic> friendships = response.data is List
            ? response.data
            : [];

        friends.value = friendships;
      }
    } catch (e) {
      Get.snackbar(
        'Error',
        'No se pudieron cargar los amigos',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red.withOpacity(0.8),
        colorText: Colors.white,
      );
    } finally {
      isLoadingFriends.value = false;
    }
  }

  Future<void> _createGroup() async {
    if (_groupNameController.text.trim().isEmpty) {
      Get.snackbar(
        'Error',
        'Ingresa un nombre para el grupo',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red.withOpacity(0.8),
        colorText: Colors.white,
      );
      return;
    }

    if (selectedParticipants.isEmpty) {
      Get.snackbar(
        'Error',
        'Selecciona al menos un participante',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red.withOpacity(0.8),
        colorText: Colors.white,
      );
      return;
    }

    isCreating.value = true;
    try {
      await _chatController.createGroupChat(
        _groupNameController.text.trim(),
        selectedParticipants.toList(),
      );
      // El éxito ya se maneja en el controller
    } catch (e) {
      Get.snackbar(
        'Error',
        'No se pudo crear el grupo',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red.withOpacity(0.8),
        colorText: Colors.white,
      );
    } finally {
      isCreating.value = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('Crear Grupo'),
        backgroundColor: Colors.black,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Get.back(),
        ),
      ),
      body: Column(
        children: [
          // Nombre del grupo
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: GlassCard(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: TextField(
                  controller: _groupNameController,
                  decoration: const InputDecoration(
                    labelText: 'Nombre del Grupo',
                    labelStyle: TextStyle(color: Colors.white70),
                    hintText: 'Ej: Amigos de la Universidad',
                    hintStyle: TextStyle(color: Colors.white30),
                    border: OutlineInputBorder(),
                    enabledBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: AppColors.glassBorder),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderSide: BorderSide(
                        color: AppColors.primary,
                        width: 2,
                      ),
                    ),
                    prefixIcon: Icon(Icons.group, color: AppColors.primary),
                  ),
                  style: const TextStyle(color: Colors.white),
                ),
              ),
            ),
          ),

          // Header de participantes
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Flexible(
                  child: Text(
                    'Seleccionar Participantes',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 8),
                Obx(
                  () => Text(
                    '${selectedParticipants.length} sel.',
                    style: TextStyle(
                      color: AppColors.primary,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 12),

          // Lista de amigos
          Expanded(
            child: Obx(() {
              if (isLoadingFriends.value) {
                return const Center(
                  child: CircularProgressIndicator(color: AppColors.primary),
                );
              }

              if (friends.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.people_outline,
                        size: 64,
                        color: Colors.white30,
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'No tienes amigos todavía',
                        style: TextStyle(color: Colors.white70, fontSize: 16),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Añade amigos desde el mapa',
                        style: TextStyle(color: Colors.white54, fontSize: 14),
                      ),
                    ],
                  ),
                );
              }

              return ListView.builder(
                itemCount: friends.length,
                itemBuilder: (context, index) {
                  final friendship = friends[index];
                  final currentUserId = _apiService.getUserId();

                  final requesterData = friendship['requester'];
                  final recipientData = friendship['recipient'];

                  final isRequester = requesterData['_id'] == currentUserId;
                  final friendData = isRequester
                      ? recipientData
                      : requesterData;

                  final friendId = friendData['_id'];
                  final username = friendData['username'] ?? 'Usuario';
                  final avatar = friendData['avatar'];

                  return Obx(() {
                    final isSelected = selectedParticipants.contains(friendId);

                    return Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () {
                          if (isSelected) {
                            selectedParticipants.remove(friendId);
                          } else {
                            selectedParticipants.add(friendId);
                          }
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? AppColors.primary.withOpacity(0.1)
                                : Colors.transparent,
                            border: Border(
                              bottom: BorderSide(
                                color: Colors.white.withOpacity(0.05),
                              ),
                            ),
                          ),
                          child: Row(
                            children: [
                              // Avatar
                              Container(
                                width: 50,
                                height: 50,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: isSelected
                                        ? AppColors.primary
                                        : Colors.white30,
                                    width: 2,
                                  ),
                                ),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(25),
                                  child: ImageWithFallback(
                                    imageUrl: avatar ?? '',
                                    fallbackAsset:
                                        'assets/images/default-avatar.png',
                                    fit: BoxFit.cover,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              // Nombre
                              Expanded(
                                child: Text(
                                  username,
                                  style: TextStyle(
                                    color: isSelected
                                        ? Colors.white
                                        : Colors.white70,
                                    fontSize: 16,
                                    fontWeight: isSelected
                                        ? FontWeight.bold
                                        : FontWeight.normal,
                                  ),
                                ),
                              ),
                              // Checkbox
                              Container(
                                width: 24,
                                height: 24,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: isSelected
                                      ? AppColors.primary
                                      : Colors.transparent,
                                  border: Border.all(
                                    color: isSelected
                                        ? AppColors.primary
                                        : Colors.white30,
                                    width: 2,
                                  ),
                                ),
                                child: isSelected
                                    ? const Icon(
                                        Icons.check,
                                        color: Colors.white,
                                        size: 16,
                                      )
                                    : null,
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  });
                },
              );
            }),
          ),

          // Botón crear
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Obx(
              () => ElevatedButton(
                onPressed: isCreating.value ? null : _createGroup,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  minimumSize: const Size(double.infinity, 50),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: isCreating.value
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : const Text(
                        'Crear Grupo',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
