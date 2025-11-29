import 'dart:developer';
import 'package:get/get.dart';
import '../services/api_service.dart';
import '../services/socket_service.dart';

class ChatController extends GetxController {
    RxList<dynamic> get polls => _socketService.polls;
  final ApiService _apiService = Get.find<ApiService>();
  final SocketService _socketService = Get.find<SocketService>();
  final RxList<Map<String, dynamic>> conversations = <Map<String, dynamic>>[].obs;
  final RxMap<String, dynamic> currentConversation = <String, dynamic>{}.obs;
  final RxList<Map<String, dynamic>> messages = <Map<String, dynamic>>[].obs;
  final RxBool isLoading = true.obs;
  final RxBool isTyping = false.obs;
  final RxList<String> typingUsers = <String>[].obs;
  final RxInt unreadBadge = 0.obs;
  final RxMap<String, dynamic> friendStatus = <String, dynamic>{}.obs;

  @override
  void onInit() {
    fetchConversations();
    _setupSocketListeners();
    super.onInit();
  }

  void _setupSocketListeners() {
    // Escuchar mensajes nuevos del socket y asegurarse de que sean Map<String, dynamic>
    ever<List<dynamic>>(_socketService.messages, (newMessages) {
      // Filtrar y convertir solo los mensajes que sean Map<String, dynamic>
      final safeMessages = newMessages
          .whereType<Map<String, dynamic>>()
          .toList();
      messages.assignAll(safeMessages);
    });

    ever<int>(_socketService.unreadNotifications, (count) {
      unreadBadge.value = count;
    });

    ever<Map<String, dynamic>>(_socketService.friendStatus, (status) {
      friendStatus.assignAll(status);
    });
  }

  void fetchConversations() async {
    final userId = _apiService.getUserId();
    if (userId == null) {
      log('⚠️ No token, no se cargan conversaciones');
      isLoading.value = false;
      return;
    }
    isLoading.value = true;
    try {
      final response = await _apiService.get('/chat');
      if (response.data is List) {
        // Asegurarse de que cada item sea Map<String, dynamic>
        final safeList = response.data
            .whereType<Map<String, dynamic>>()
            .toList();
        conversations.assignAll(safeList);
      } else {
        conversations.clear();
      }
      log('✅ Loaded ${conversations.length} conversations');
    } catch (e) {
      Get.snackbar('Error', 'No se pudieron cargar las conversaciones: $e');
    } finally {
      isLoading.value = false;
    }
  }

  void fetchMessages(String conversationId) async {
    try {
      final response = await _apiService.get('/chat/messages/$conversationId');
      if (response.data is List) {
        final safeList = response.data
            .whereType<Map<String, dynamic>>()
            .toList();
        messages.assignAll(safeList);
      } else {
        messages.clear();
      }
      _socketService.joinConversation(conversationId);
      log('✅ Loaded ${messages.length} messages for conversation $conversationId');
    } catch (e) {
      Get.snackbar('Error', 'No se pudieron cargar los mensajes: $e');
    }
  }

  void sendMessage(String content, {String type = 'text'}) {
    if (content.trim().isEmpty) return;

    final message = {
      'conversationId': currentConversation['_id'],
      'content': content.trim(),
      'type': type
    };

    _socketService.sendMessage(message);
    // Agregar mensaje localmente inmediatamente
    messages.add({
      ...message,
      '_id': 'temp-${DateTime.now().millisecondsSinceEpoch}',
      'sender': {
        '_id': 'current-user',
        'username': 'You',
        'profilePictureUrl': null
      },
      'createdAt': DateTime.now().toIso8601String(),
      'isSent': false
    });
  }

  void setCurrentConversation(Map<String, dynamic> conversation) {
    currentConversation.value = conversation;
    fetchMessages(conversation['_id']);
    // Marcar mensajes como leídos y resetear badge
    unreadBadge.value = 0;
    _socketService.resetUnreadNotifications();
    // Aquí podrías llamar a la API para marcar como leídos en backend si es necesario
  }

  void createGroupChat(String name, List<String> participantIds) async {
    try {
      final response = await _apiService.post('/group', data: {
        'name': name,
        'participants': participantIds
      });
      if (response.data is Map<String, dynamic>) {
        conversations.add(response.data);
      }
      Get.back();
      Get.snackbar('Éxito', 'Grupo creado correctamente');
    } catch (e) {
      Get.snackbar('Error', 'No se pudo crear el grupo: $e');
    }
  }

  void createPoll(String question, List<String> options) async {
    try {
      await _apiService.post('/group/${currentConversation['_id']}/poll', data: {
        'question': question,
        'options': options
      });
      Get.back();
      Get.snackbar('Éxito', 'Encuesta creada correctamente');
    } catch (e) {
      Get.snackbar('Error', 'No se pudo crear la encuesta: $e');
    }
  }
}