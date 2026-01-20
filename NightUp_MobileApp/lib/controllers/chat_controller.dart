import 'package:get/get.dart';
import 'package:flutter/material.dart';
import 'dart:async';
import '../services/api_service.dart';
import '../services/socket_service.dart';
import '../services/poll_service.dart';
import '../services/content_moderation_service.dart';
import '../services/cloudinary_service.dart' hide AppColors;
import '../services/jitsi_service.dart';
import '../models/conversation.dart';
import '../models/message.dart';
import '../models/poll.dart';

class ChatController extends GetxController {
  final ApiService _apiService = Get.find<ApiService>();
  final SocketService _socketService = Get.find<SocketService>();
  final PollService _pollService = Get.find<PollService>();
  final JitsiService _jitsiService = Get.find<JitsiService>();

  final RxList<Conversation> conversations = <Conversation>[].obs;
  final Rx<Conversation?> currentConversation = Rx<Conversation?>(null);
  final RxList<Message> messages = <Message>[].obs;
  final RxBool isLoading = true.obs;
  final RxBool isLoadingMessages = false.obs;
  final RxList<String> typingUsers = <String>[].obs;
  final RxInt unreadBadge = 0.obs;
  final Rx<Message?> replyingTo = Rx<Message?>(null);

  final RxList<Poll> polls = <Poll>[].obs;
  final RxBool isLoadingPolls = false.obs;

  final ScrollController scrollController = ScrollController();
  Timer? _typingTimer;

  String? get currentUserId => _apiService.getUserId();

  @override
  void onInit() {
    super.onInit();
    fetchConversations();
    loadPolls();
    _setupSocketListeners();
  }

  void _setupSocketListeners() {
    _socketService.socket.on('newMessage', (data) {
      _handleNewMessage(data);
    });

    _socketService.socket.on('messageEdited', (data) {
      _handleMessageEdited(data);
    });

    _socketService.socket.on('messageDeleted', (data) {
      _handleMessageDeleted(data);
    });

    _socketService.socket.on('messageReacted', (data) {
      _handleMessageReacted(data);
    });

    _socketService.socket.on('userTyping', (data) {
      _handleUserTyping(data);
    });

    _socketService.socket.on('userStoppedTyping', (data) {
      _handleUserStoppedTyping(data);
    });

    _socketService.socket.on('newGroup', (data) {
      _handleNewGroup(data);
    });

    _socketService.socket.on('messagesRead', (data) {
      _handleMessagesRead(data);
    });

    _socketService.socket.on('newGroupPoll', (data) {
      _handleNewGroupPoll(data);
    });

    _socketService.socket.on('groupPollUpdated', (data) {
      _handleGroupPollUpdated(data);
    });

    _socketService.socket.on('error', (data) {});
  }

  void _handleNewMessage(dynamic data) {
    try {
      final message = Message.fromJson(data);

      if (currentConversation.value?.id == message.conversationId) {
        final existingIndex = messages.indexWhere(
          (m) =>
              m.id == message.id ||
              (message.isAudio &&
                  m.isAudio &&
                  m.sender.id == message.sender.id &&
                  m.audioUrl == null &&
                  message.audioUrl != null) ||
              (m.text == message.text &&
                  m.sender.id == message.sender.id &&
                  m.createdAt.difference(message.createdAt).inSeconds.abs() <
                      5) ||
              (m.imageUrl != null &&
                  m.imageUrl == message.imageUrl &&
                  m.sender.id == message.sender.id) ||
              (m.audioUrl != null &&
                  m.audioUrl == message.audioUrl &&
                  m.sender.id == message.sender.id),
        );

        if (existingIndex != -1) {
          messages[existingIndex] = message;
        } else {
          messages.add(message);
        }

        messages.refresh();

        if (message.sender.id == currentUserId) {
          scrollToBottom();
        }

        if (message.sender.id != currentUserId) {
          _markMessageAsRead(message.id);
        }
      }

      _updateConversationWithNewMessage(message);
    } catch (e) {}
  }

  void _handleMessageEdited(dynamic data) {
    try {
      final messageId = data['_id'] ?? data['messageId'];
      final newText = data['text'];
      final isEdited = data['isEdited'] ?? true;

      final index = messages.indexWhere((m) => m.id == messageId);
      if (index != -1) {
        final message = messages[index];
        messages[index] = Message(
          id: message.id,
          conversationId: message.conversationId,
          sender: message.sender,
          text: newText,
          messageType: message.messageType,
          imageUrl: message.imageUrl,
          createdAt: message.createdAt,
          updatedAt: DateTime.now(),
          isEdited: isEdited,
          isDeleted: message.isDeleted,
          replyTo: message.replyTo,
          reactions: message.reactions,
          readBy: message.readBy,
        );
      }
    } catch (e) {}
  }

  void _handleMessageDeleted(dynamic data) {
    try {
      final messageId = data['messageId'];
      final index = messages.indexWhere((m) => m.id == messageId);
      if (index != -1) {
        final message = messages[index];
        messages[index] = Message(
          id: message.id,
          conversationId: message.conversationId,
          sender: message.sender,
          text: 'Mensaje eliminado',
          createdAt: message.createdAt,
          updatedAt: DateTime.now(),
          isEdited: message.isEdited,
          isDeleted: true,
          replyTo: message.replyTo,
          reactions: [],
          readBy: message.readBy,
        );
      }
    } catch (e) {}
  }

  void _handleMessageReacted(dynamic data) {
    try {
      final messageId = data['messageId'];
      final reactions =
          (data['reactions'] as List?)
              ?.map((r) => Reaction(userId: r['user'], emoji: r['emoji']))
              .toList() ??
          [];

      final index = messages.indexWhere((m) => m.id == messageId);
      if (index != -1) {
        final message = messages[index];
        messages[index] = Message(
          id: message.id,
          conversationId: message.conversationId,
          sender: message.sender,
          text: message.text,
          messageType: message.messageType,
          imageUrl: message.imageUrl,
          createdAt: message.createdAt,
          updatedAt: message.updatedAt,
          isEdited: message.isEdited,
          isDeleted: message.isDeleted,
          replyTo: message.replyTo,
          reactions: reactions,
          readBy: message.readBy,
        );
      }
    } catch (e) {}
  }

  void _handleUserTyping(dynamic data) {
    try {
      final conversationId = data['conversationId'];
      final username = data['username'] ?? 'Usuario';
      final userId = data['userId'];

      if (currentConversation.value?.id == conversationId &&
          userId != currentUserId) {
        if (!typingUsers.contains(username)) {
          typingUsers.add(username);
        }
      }
    } catch (e) {}
  }

  void _handleUserStoppedTyping(dynamic data) {
    try {
      final username = data['username'] ?? 'Usuario';
      typingUsers.remove(username);
    } catch (e) {}
  }

  void _handleNewGroup(dynamic data) {
    try {
      fetchConversations();
    } catch (e) {}
  }

  void _handleMessagesRead(dynamic data) {
    try {
      final messageIds = (data['messageIds'] as List).cast<String>();
      final userId = data['userId'];

      for (final messageId in messageIds) {
        final index = messages.indexWhere((m) => m.id == messageId);
        if (index != -1) {
          final message = messages[index];
          if (!message.readBy.contains(userId)) {
            messages[index] = Message(
              id: message.id,
              conversationId: message.conversationId,
              sender: message.sender,
              text: message.text,
              messageType: message.messageType,
              imageUrl: message.imageUrl,
              createdAt: message.createdAt,
              updatedAt: message.updatedAt,
              isEdited: message.isEdited,
              isDeleted: message.isDeleted,
              replyTo: message.replyTo,
              reactions: message.reactions,
              readBy: [...message.readBy, userId],
            );
          }
        }
      }
    } catch (e) {}
  }

  void _handleNewGroupPoll(dynamic data) {
    try {
      if (currentConversation.value?.id == data['conversationId']) {
        refreshCurrentConversation();
      }
    } catch (e) {}
  }

  void _handleGroupPollUpdated(dynamic data) {
    try {
      if (currentConversation.value?.id == data['conversationId']) {
        refreshCurrentConversation();
      }
    } catch (e) {}
  }

  void _updateConversationWithNewMessage(Message message) {
    final index = conversations.indexWhere(
      (c) => c.id == message.conversationId,
    );
    if (index != -1) {
      final conv = conversations[index];
      final updatedConv = Conversation(
        id: conv.id,
        isGroup: conv.isGroup,
        name: conv.name,
        avatar: conv.avatar,
        lastMessage: message.displayText,
        lastMessageTime: message.createdAt,
        participants: conv.participants,
        unreadCount: message.sender.id == currentUserId
            ? 0
            : conv.unreadCount + 1,
      );

      conversations.removeAt(index);
      conversations.insert(0, updatedConv);
    } else {
      fetchConversations();
    }
  }

  void _markMessageAsRead(String messageId) {
    if (currentConversation.value == null) return;
    _socketService.markAsRead(currentConversation.value!.id, [messageId]);
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
    isLoadingMessages.value = true;
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
    } finally {
      isLoadingMessages.value = false;
    }
  }

  Future<void> refreshCurrentConversation() async {
    if (currentConversation.value == null) {
      return;
    }

    try {
      final conversationId = currentConversation.value!.id;
      final response = await _apiService.get('/chat');

      if (response.data is List) {
        final conversations = (response.data as List)
            .map((json) => Conversation.fromJson(json))
            .toList();

        final updatedConv = conversations.firstWhereOrNull(
          (c) => c.id == conversationId,
        );
        if (updatedConv != null) {
          currentConversation.value = updatedConv;
          currentConversation.refresh();
        }
      }
    } catch (e) {}
  }

  Future<void> sendMessage(String text, {String? replyToId}) async {
    if (text.trim().isEmpty) return;
    if (currentConversation.value == null) return;

    final moderationResult = ContentModerationService.moderateMessage(
      text.trim(),
    );
    if (!moderationResult.isAllowed) {
      return;
    }

    final tempId = 'temp_${DateTime.now().millisecondsSinceEpoch}';
    final replyToMessage = replyingTo.value;

    final optimisticMessage = Message(
      id: tempId,
      conversationId: currentConversation.value!.id,
      sender: Sender(id: currentUserId ?? '', username: 'Tú', avatar: null),
      text: moderationResult.sanitizedMessage ?? text.trim(),
      createdAt: DateTime.now(),
      replyTo: replyToMessage,
      status: MessageStatus.sending,
    );
    messages.add(optimisticMessage);
    scrollToBottom();

    try {
      _socketService.sendMessage({
        'conversationId': currentConversation.value!.id,
        'text': moderationResult.sanitizedMessage ?? text.trim(),
        if (replyToId != null || replyingTo.value != null)
          'replyTo': replyToId ?? replyingTo.value?.id,
      });

      Future.delayed(const Duration(seconds: 3), () {
        messages.removeWhere((m) => m.id == tempId);
      });
    } catch (e) {
      final index = messages.indexWhere((m) => m.id == tempId);
      if (index != -1) {
        messages[index] = Message(
          id: tempId,
          conversationId: currentConversation.value!.id,
          sender: Sender(id: currentUserId ?? '', username: 'Tú', avatar: null),
          text: text.trim(),
          createdAt: DateTime.now(),
          replyTo: replyToMessage,
          status: MessageStatus.failed,
        );
      }
    } finally {
      replyingTo.value = null;
      stopTyping();
    }
  }

  Future<void> sendImage() async {
    if (currentConversation.value == null) return;
    final CloudinaryService cloudinaryService = Get.find<CloudinaryService>();

    final imageUrl = await cloudinaryService.showImagePickerDialog();
    if (imageUrl == null) return;

    final tempId = 'temp_${DateTime.now().millisecondsSinceEpoch}';
    final optimisticMessage = Message(
      id: tempId,
      conversationId: currentConversation.value!.id,
      sender: Sender(id: currentUserId ?? '', username: 'Tú', avatar: null),
      text: '',
      messageType: MessageType.image,
      imageUrl: imageUrl,
      createdAt: DateTime.now(),
      status: MessageStatus.sending,
    );
    messages.add(optimisticMessage);
    scrollToBottom();

    try {
      _socketService.sendMessage({
        'conversationId': currentConversation.value!.id,
        'text': '',
        'imageUrl': imageUrl,
        'messageType': 'image',
      });
    } catch (e) {
      final index = messages.indexWhere((m) => m.id == tempId);
      if (index != -1) {
        messages[index] = Message(
          id: tempId,
          conversationId: currentConversation.value!.id,
          sender: Sender(id: currentUserId ?? '', username: 'Tú', avatar: null),
          text: '',
          messageType: MessageType.image,
          imageUrl: imageUrl,
          createdAt: DateTime.now(),
          status: MessageStatus.failed,
        );
      }
    }
  }

  Future<void> sendAudio(String filePath) async {
    if (currentConversation.value == null) return;
    final CloudinaryService cloudinaryService = Get.find<CloudinaryService>();

    final tempId = 'temp_audio_${DateTime.now().millisecondsSinceEpoch}';
    final optimisticMessage = Message(
      id: tempId,
      conversationId: currentConversation.value!.id,
      sender: Sender(id: currentUserId ?? '', username: 'Tú', avatar: null),
      text: '🎤 Grabando/Subiendo...',
      messageType: MessageType.audio,
      audioUrl: null,
      createdAt: DateTime.now(),
      status: MessageStatus.sending,
    );
    messages.add(optimisticMessage);
    scrollToBottom();

    try {
      final audioUrl = await cloudinaryService.uploadAudio(filePath);
      if (audioUrl == null) throw Exception('Error subiendo audio');

      final optIndex = messages.indexWhere((m) => m.id == tempId);
      if (optIndex != -1) {
        messages[optIndex] = messages[optIndex].copyWith(audioUrl: audioUrl);
        messages.refresh();
      }

      _socketService.sendMessage({
        'conversationId': currentConversation.value!.id,
        'text': '',
        'audioUrl': audioUrl,
        'messageType': 'audio',
      });
    } catch (e) {
      final index = messages.indexWhere((m) => m.id == tempId);
      if (index != -1) {
        messages[index] = Message(
          id: tempId,
          conversationId: currentConversation.value!.id,
          sender: Sender(id: currentUserId ?? '', username: 'Tú', avatar: null),
          text: 'Error audio',
          messageType: MessageType.audio,
          createdAt: DateTime.now(),
          status: MessageStatus.failed,
        );
      }
    }
  }

  Future<void> startVideoCall() async {
    final conv = currentConversation.value;
    if (conv == null) return;

    try {
      await _jitsiService.startMeeting(conv);
      final String roomName = "NightUp_${conv.id}";
      sendMessage(
        "📞 He iniciado una videollamada integrada. ¡Únete pulsando el icono de llamada!",
      );
    } catch (e) {}
  }

  Future<void> editMessage(String messageId, String newText) async {
    final moderationResult = ContentModerationService.moderateMessage(
      newText.trim(),
    );
    if (!moderationResult.isAllowed) {
      return;
    }

    try {
      _socketService.editMessage(
        messageId,
        moderationResult.sanitizedMessage ?? newText.trim(),
      );
    } catch (e) {}
  }

  Future<void> deleteMessage(String messageId) async {
    try {
      _socketService.deleteMessage(messageId);
    } catch (e) {}
  }

  Future<void> reactToMessage(String messageId, String emoji) async {
    try {
      _socketService.reactToMessage(messageId, emoji);
    } catch (e) {}
  }

  void onTyping() {
    if (currentConversation.value == null) return;

    final username = _apiService.getUsername() ?? 'Usuario';
    _socketService.typing(currentConversation.value!.id, username);

    _typingTimer?.cancel();
    _typingTimer = Timer(const Duration(seconds: 2), () {
      stopTyping();
    });
  }

  void stopTyping() {
    if (currentConversation.value == null) return;

    final username = _apiService.getUsername() ?? 'Usuario';
    _socketService.stopTyping(currentConversation.value!.id, username);
    _typingTimer?.cancel();
  }

  Future<void> createGroupPoll({
    required String question,
    required List<String> options,
    DateTime? expiresAt,
  }) async {
    if (currentConversation.value == null) {
      return;
    }

    if (!currentConversation.value!.isGroup) {
      return;
    }

    final conversationId = currentConversation.value!.id;

    try {
      final pollData = {
        'conversationId': conversationId,
        'question': question,
        'options': options,
        if (expiresAt != null) 'expiresAt': expiresAt.toIso8601String(),
      };

      _socketService.socket.emit('createGroupPoll', pollData);
    } catch (e) {}
  }

  Future<void> voteInGroupPoll(String pollId, int optionIndex) async {
    if (currentConversation.value == null) {
      return;
    }

    final conversationId = currentConversation.value!.id;

    if (conversationId.isEmpty) {
      return;
    }

    if (pollId.isEmpty) {
      return;
    }

    try {
      _socketService.socket.emit('voteInGroupPoll', {
        'conversationId': conversationId,
        'pollId': pollId,
        'optionIndex': optionIndex,
      });
    } catch (e) {}
  }

  void setCurrentConversation(Conversation conversation) {
    if (currentConversation.value != null) {
      _socketService.leaveRoom(currentConversation.value!.id);
    }

    currentConversation.value = conversation;
    messages.clear();
    typingUsers.clear();

    fetchMessages(conversation.id);
    final index = conversations.indexWhere((c) => c.id == conversation.id);
    if (index != -1) {
      conversations[index] = Conversation(
        id: conversation.id,
        isGroup: conversation.isGroup,
        name: conversation.name,
        avatar: conversation.avatar,
        lastMessage: conversation.lastMessage,
        lastMessageTime: conversation.lastMessageTime,
        participants: conversation.participants,
        unreadCount: 0,
      );
    }
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
    } catch (e) {}
  }

  Future<void> loadPolls() async {
    isLoadingPolls.value = true;
    try {
      polls.value = await _pollService.getActivePolls(limit: 50);
    } catch (e) {
    } finally {
      isLoadingPolls.value = false;
    }
  }

  Future<void> createPoll({
    required String question,
    required List<String> options,
    bool isPublic = true,
    List<String>? allowedVoters,
    DateTime? expiresAt,
  }) async {
    try {
      final newPoll = await _pollService.createPoll(
        question: question,
        options: options,
        isPublic: isPublic,
        allowedVoters: allowedVoters,
        expiresAt: expiresAt,
      );

      polls.insert(0, newPoll);
    } catch (e) {
      rethrow;
    }
  }

  Future<void> voteInPoll(String pollId, int optionIndex) async {
    try {
      final updatedPoll = await _pollService.voteInPoll(pollId, optionIndex);
      final index = polls.indexWhere((p) => p.id == pollId);
      if (index != -1) {
        polls[index] = updatedPoll;
      }
    } catch (e) {}
  }

  Future<void> closePoll(String pollId) async {
    try {
      final updatedPoll = await _pollService.closePoll(pollId);
      final index = polls.indexWhere((p) => p.id == pollId);
      if (index != -1) {
        polls[index] = updatedPoll;
      }
    } catch (e) {}
  }

  Future<PollResults> getPollResults(String pollId) async {
    try {
      return await _pollService.getPollResults(pollId);
    } catch (e) {
      rethrow;
    }
  }

  void setReplyTo(Message message) {
    replyingTo.value = message;
  }

  void cancelReply() {
    replyingTo.value = null;
  }

  void scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (scrollController.hasClients) {
        scrollController.animateTo(
          0,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  void onClose() {
    if (currentConversation.value != null) {
      _socketService.leaveRoom(currentConversation.value!.id);
    }
    scrollController.dispose();
    _typingTimer?.cancel();
    super.onClose();
  }
}
