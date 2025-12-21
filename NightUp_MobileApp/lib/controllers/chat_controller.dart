import 'package:get/get.dart';
import '../services/api_service.dart';
import '../services/socket_service.dart';
import '../services/notification_service.dart';
import '../models/conversation.dart';
import '../theme/colors.dart';
import '../models/message.dart';

class ChatController extends GetxController {
  final ApiService _apiService = Get.find<ApiService>();
  final SocketService _socketService = Get.find<SocketService>();
  final NotificationService _notificationService = NotificationService();

  final RxList<Conversation> conversations = <Conversation>[].obs;
  final Rx<Conversation?> currentConversation = Rx<Conversation?>(null);
  final RxList<Message> messages = <Message>[].obs;
  final RxBool isLoading = true.obs;
  final RxBool isTyping = false.obs;
  final RxList<String> typingUsers = <String>[].obs;
  final RxInt unreadBadge = 0.obs;
  final RxMap<String, dynamic> friendStatus = <String, dynamic>{}.obs;

  String? get currentUserId => _apiService.getUserId();

  RxList<dynamic> get polls => _socketService.polls;

  @override
  void onInit() {
    super.onInit();
    fetchConversations();
    _setupSocketListeners();
  }

  void _setupSocketListeners() {
    ever<List<dynamic>>(_socketService.messages, (newMessages) {
      if (newMessages.isNotEmpty) {
        final lastMessage = newMessages.last;
        final conversationId = lastMessage['conversation'];
        final senderData = lastMessage['sender'];
        final senderId = senderData is Map ? senderData['_id'] : senderData;

        if (senderId != currentUserId) {
          _updateConversationWithNewMessage(lastMessage);

          if (currentConversation.value?.id != conversationId) {
            _showNotificationForMessage(lastMessage);
          }
        }
      }

      if (currentConversation.value != null) {
        messages.value = newMessages
            .where((m) => m['conversation'] == currentConversation.value!.id)
            .map((m) => Message.fromJson(m))
            .toList();
      }
    });

    ever<int>(_socketService.unreadNotifications, (count) {
      unreadBadge.value = count;
    });

    ever<Map<String, dynamic>>(_socketService.friendStatus, (status) {
      friendStatus.assignAll(status);
    });
  }

  void _updateConversationWithNewMessage(Map<String, dynamic> messageData) {
    try {
      final conversationId = messageData['conversation'];
      final text = messageData['text'] ?? '';
      final createdAt = messageData['createdAt'];

      final index = conversations.indexWhere((c) => c.id == conversationId);

      if (index != -1) {
        final conv = conversations[index];
        final updatedConv = Conversation(
          id: conv.id,
          isGroup: conv.isGroup,
          name: conv.name,
          avatar: conv.avatar,
          lastMessage: text,
          lastMessageTime: createdAt != null
              ? DateTime.parse(createdAt)
              : DateTime.now(),
          participants: conv.participants,
          unreadCount: conv.unreadCount + 1,
        );

        conversations.removeAt(index);

        conversations.insert(0, updatedConv);
      } else {
        fetchConversations();
      }
    } catch (e) {}
  }

  void _showNotificationForMessage(Map<String, dynamic> messageData) {
    try {
      final conversationId = messageData['conversation'];
      final senderData = messageData['sender'];
      final senderName = senderData is Map
          ? (senderData['username'] ?? 'Usuario')
          : 'Usuario';
      final text = messageData['text'] ?? '';

      final conv = conversations.firstWhereOrNull(
        (c) => c.id == conversationId,
      );
      final isGroup = conv?.isGroup ?? false;

      _notificationService.showMessageNotification(
        conversationId: conversationId,
        senderName: senderName,
        message: text,
        isGroup: isGroup,
      );
    } catch (e) {}
  }

  Future<void> fetchConversations() async {
    final userId = _apiService.getUserId();
    if (userId == null) {
      isLoading.value = false;
      return;
    }

    isLoading.value = true;
    try {
      final response = await _apiService.get('/chat');

      if (response.data is List) {
        conversations.value = (response.data as List)
            .map((json) => Conversation.fromJson(json))
            .toList();
      } else {
        conversations.value = [];
      }
    } catch (e) {
      conversations.value = [];
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> fetchMessages(String conversationId) async {
    try {
      final response = await _apiService.get('/chat/$conversationId/messages');

      if (response.data is List) {
        messages.value = (response.data as List)
            .map((json) => Message.fromJson(json))
            .toList();
      }

      _socketService.joinRoom(conversationId);
    } catch (e) {
      messages.value = [];
    }
  }

  Future<void> sendMessage(String text, {String? replyToId}) async {
    if (text.trim().isEmpty) return;
    if (currentConversation.value == null) {
      return;
    }

    try {
      await _apiService.post(
        '/chat/message',
        data: {
          'conversationId': currentConversation.value!.id,
          'text': text.trim(),
          if (replyToId != null) 'replyTo': replyToId,
        },
      );
    } catch (e) {
      Get.snackbar(
        'Error',
        'No se pudo enviar el mensaje: $e',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: AppColors.error.withOpacity(0.8),
        colorText: AppColors.white,
      );
    }
  }

  void setCurrentConversation(Conversation conversation) {
    currentConversation.value = conversation;
    fetchMessages(conversation.id);
    unreadBadge.value = 0;
    _socketService.resetUnreadNotifications();
  }

  Future<void> createPrivateChat(String recipientId) async {
    try {
      final response = await _apiService.post(
        '/chat/conversation',
        data: {'recipientId': recipientId},
      );

      if (response.data['conversationId'] != null) {
        final conversationId = response.data['conversationId'].toString();

        await fetchConversations();

        final conv = conversations.firstWhereOrNull(
          (c) => c.id == conversationId,
        );

        if (conv != null) {
          setCurrentConversation(conv);
        }
      }
    } catch (e) {
      throw Exception('No se pudo crear el chat: $e');
    }
  }

  Future<void> createGroupChat(String name, List<String> participantIds) async {
    try {
      await _apiService.post(
        '/chat/group',
        data: {'name': name, 'participants': participantIds},
      );

      await fetchConversations();
      Get.back();
      Get.snackbar(
        'Éxito',
        'Grupo "$name" creado correctamente',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: AppColors.success.withOpacity(0.8),
        colorText: AppColors.white,
      );
    } catch (e) {
      Get.snackbar('Error', 'No se pudo crear el grupo: $e');
    }
  }

  Future<void> editMessage(String messageId, String newText) async {
    try {
      await _apiService.put(
        '/chat/message/$messageId',
        data: {'text': newText},
      );
    } catch (e) {
      Get.snackbar('Error', 'No se pudo editar el mensaje: $e');
    }
  }

  Future<void> deleteMessage(String messageId) async {
    try {
      await _apiService.delete('/chat/message/$messageId');
    } catch (e) {
      Get.snackbar('Error', 'No se pudo eliminar el mensaje: $e');
    }
  }

  Future<void> reactToMessage(String messageId, String emoji) async {
    try {
      await _apiService.post(
        '/chat/message/$messageId/react',
        data: {'emoji': emoji},
      );
    } catch (e) {}
  }

  void startTyping() {
    if (currentConversation.value != null) {
      _socketService.typing(currentConversation.value!.id);
    }
  }

  void stopTyping() {
    if (currentConversation.value != null) {
      _socketService.stopTyping(currentConversation.value!.id);
    }
  }

  void resetUnreadNotifications() {
    _socketService.resetUnreadNotifications();
  }

  @override
  void onClose() {
    if (currentConversation.value != null) {
      _socketService.leaveRoom(currentConversation.value!.id);
    }
    super.onClose();
  }
}
