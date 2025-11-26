import 'package:get/get.dart';
import '../services/api_service.dart';
import '../services/socket_service.dart';

class ChatController extends GetxController {
  final ApiService _apiService = Get.find<ApiService>();
  final SocketService _socketService = Get.find<SocketService>();
  final RxList<Map<String, dynamic>> conversations = <Map<String, dynamic>>[].obs;
  final RxMap<String, dynamic> currentConversation = <String, dynamic>{}.obs;
  final RxList<Map<String, dynamic>> messages = <Map<String, dynamic>>[].obs;
  final RxBool isLoading = true.obs;
  final RxBool isTyping = false.obs;
  final RxList<String> typingUsers = <String>[].obs;

  @override
  void onInit() {
    fetchConversations();
    _setupSocketListeners();
    super.onInit();
  }

  void _setupSocketListeners() {
    ever<List<Map<String, dynamic>>>(_socketService.messages as RxList<Map<String, dynamic>>, (newMessages) {
      // Actualizar mensajes cuando lleguen nuevos via socket
      messages.assignAll(newMessages);
    });
  }

  void fetchConversations() async {
    isLoading.value = true;
    try {
      final response = await _apiService.get('/chat');
      if (response.data is List) {
        conversations.assignAll(List<Map<String, dynamic>>.from(response.data));
      } else {
        conversations.clear();
      }
      print('✅ Loaded ${conversations.length} conversations');
    } catch (e) {
      Get.snackbar('Error', 'No se pudieron cargar las conversaciones: $e');
    } finally {
      isLoading.value = false;
    }
  }

  void fetchMessages(String conversationId) async {
    try {
      final response = await _apiService.get('/chat/$conversationId/messages');
      if (response.data is List) {
        messages.assignAll(List<Map<String, dynamic>>.from(response.data));
      } else {
        messages.clear();
      }
      _socketService.joinConversation(conversationId);
      print('✅ Loaded ${messages.length} messages for conversation $conversationId');
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