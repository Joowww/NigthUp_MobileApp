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

  // Inyección segura del controlador
  final ChatController _chatController = Get.isRegistered<ChatController>()
      ? Get.find<ChatController>()
      : Get.put(ChatController());

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
      print("Error loading friends: $e");
    } finally {
      isLoadingFriends.value = false;
    }
  }

  Future<void> _createGroup() async {
    if (_groupNameController.text.trim().isEmpty) {
      return;
    }

    if (selectedParticipants.isEmpty) {
      return;
    }

    isCreating.value = true;
    try {
      await _chatController.createGroupChat(
        _groupNameController.text.trim(),
        selectedParticipants.toList(),
      );
    } catch (e) {
      print("Error creating group: $e");
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
          // 1. INPUT DEL NOMBRE
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
                    hintText: 'Ej: Amigos',
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

          // 2. TÍTULO Y CONTADOR (AQUÍ ESTABA EL PROBLEMA)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // 🔥 SOLUCIÓN: Expanded obliga al texto largo a respetar el espacio
                // Si el contador crece, este texto se encoge automáticamente.
                const Expanded(
                  child: Text(
                    'Seleccionar Participantes',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                    overflow: TextOverflow.ellipsis, // Pone "..." si no cabe
                    maxLines: 1,
                  ),
                ),

                const SizedBox(width: 10), // Un poco de aire
                // El contador se mantiene fijo a la derecha
                Obx(
                  () => Text(
                    '${selectedParticipants.length} sel.',
                    style: const TextStyle(
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

          // 3. LISTA DE AMIGOS
          Expanded(
            child: Obx(() {
              if (isLoadingFriends.value) {
                return const Center(
                  child: CircularProgressIndicator(color: AppColors.primary),
                );
              }
              if (friends.isEmpty) {
                return const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.people_outline,
                        size: 64,
                        color: Colors.white30,
                      ),
                      SizedBox(height: 16),
                      Text(
                        'No tienes amigos todavía',
                        style: TextStyle(color: Colors.white70, fontSize: 16),
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

                  if (friendship['requester'] == null ||
                      friendship['recipient'] == null) {
                    return const SizedBox();
                  }

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
                              // Expanded aquí también protege el nombre del usuario
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
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const SizedBox(width: 8),
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

          // 4. BOTÓN DE CREAR
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
