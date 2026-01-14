import 'package:get/get.dart';
import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:developer';
import '../services/api_service.dart';
import '../services/socket_service.dart';
import '../services/poll_service.dart';
import '../services/content_moderation_service.dart';
import '../services/cloudinary_service.dart' hide AppColors;
import '../services/jitsi_service.dart';
import '../models/conversation.dart';
import '../models/message.dart';
import '../models/poll.dart';
import '../theme/colors.dart';

class ChatController extends GetxController {
  final ApiService _apiService = Get.find<ApiService>();
  final SocketService _socketService = Get.find<SocketService>();
  final PollService _pollService = Get.find<PollService>();
  final JitsiService _jitsiService = Get.find<JitsiService>();

  // ==================== OBSERVABLES - CHAT ====================

  final RxList<Conversation> conversations = <Conversation>[].obs;
  final Rx<Conversation?> currentConversation = Rx<Conversation?>(null);
  final RxList<Message> messages = <Message>[].obs;
  final RxBool isLoading = true.obs;
  final RxBool isLoadingMessages = false.obs;
  final RxList<String> typingUsers = <String>[].obs;
  final RxInt unreadBadge = 0.obs;
  final Rx<Message?> replyingTo = Rx<Message?>(null);

  // ==================== OBSERVABLES - POLLS ====================

  final RxList<Poll> polls = <Poll>[].obs;
  final RxBool isLoadingPolls = false.obs;

  // ==================== CONTROLLERS ====================

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

  // ==================== SETUP SOCKET LISTENERS ====================

  void _setupSocketListeners() {
    // Escuchar nuevos mensajes
    _socketService.socket.on('newMessage', (data) {
      _handleNewMessage(data);
    });

    // Escuchar mensajes editados
    _socketService.socket.on('messageEdited', (data) {
      _handleMessageEdited(data);
    });

    // Escuchar mensajes eliminados
    _socketService.socket.on('messageDeleted', (data) {
      _handleMessageDeleted(data);
    });

    // Escuchar reacciones
    _socketService.socket.on('messageReacted', (data) {
      _handleMessageReacted(data);
    });

    // Escuchar usuario escribiendo
    _socketService.socket.on('userTyping', (data) {
      _handleUserTyping(data);
    });

    // Escuchar usuario dejó de escribir
    _socketService.socket.on('userStoppedTyping', (data) {
      _handleUserStoppedTyping(data);
    });

    // Escuchar nuevo grupo creado
    _socketService.socket.on('newGroup', (data) {
      _handleNewGroup(data);
    });

    // Escuchar mensajes leídos
    _socketService.socket.on('messagesRead', (data) {
      _handleMessagesRead(data);
    });

    // Escuchar nueva encuesta en grupo
    _socketService.socket.on('newGroupPoll', (data) {
      _handleNewGroupPoll(data);
    });

    // Escuchar actualización de encuesta
    _socketService.socket.on('groupPollUpdated', (data) {
      _handleGroupPollUpdated(data);
    });

    // Escuchar errores
    _socketService.socket.on('error', (data) {
      Get.snackbar(
        'Error',
        data['message'] ?? 'Ha ocurrido un error',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: AppColors.error.withOpacity(0.8),
        colorText: Colors.white,
      );
    });
  }

  // ==================== HANDLE SOCKET EVENTS ====================

  void _handleNewMessage(dynamic data) {
    try {
      final message = Message.fromJson(data);

      // Si es la conversación actual, añadir mensaje
      if (currentConversation.value?.id == message.conversationId) {
        log(
          '📨 Mensaje recibido en conversación actual: ${message.text} (Imagen: ${message.imageUrl})',
          name: 'ChatController',
        ); // DEBUG

        // Verificar si el mensaje ya existe (por si es optimista)
        final existingIndex = messages.indexWhere(
          (m) =>
              m.id == message.id ||
              // Para audios optimistas: si soy el sender y el mensaje es reciente (menos de 10s)
              // y el mensaje en la lista es de tipo audio sin URL todavía
              (message.isAudio &&
                  m.isAudio &&
                  m.sender.id == message.sender.id &&
                  m.audioUrl == null &&
                  message.audioUrl != null) ||
              // Para mensajes de texto: coincidencia exacta
              (m.text == message.text &&
                  m.sender.id == message.sender.id &&
                  m.createdAt.difference(message.createdAt).inSeconds.abs() <
                      5) ||
              // Para imágenes: coincidencia de URL
              (m.imageUrl != null &&
                  m.imageUrl == message.imageUrl &&
                  m.sender.id == message.sender.id) ||
              // Para audios: coincidencia de URL
              (m.audioUrl != null &&
                  m.audioUrl == message.audioUrl &&
                  m.sender.id == message.sender.id),
        );

        if (existingIndex != -1) {
          // Reemplazar mensaje optimista con el real
          log(
            '🔄 Reemplazando mensaje optimista con real: ${message.id}',
            name: 'ChatController',
          );
          messages[existingIndex] = message;
        } else {
          // Añadir nuevo mensaje
          log(
            '➕ Añadiendo nuevo mensaje: ${message.id}',
            name: 'ChatController',
          );
          messages.add(message);
        }

        messages.refresh(); // Forzar actualización de UI

        // Scroll automático si es mensaje propio
        if (message.sender.id == currentUserId) {
          scrollToBottom();
        }

        // Marcar como leído si no es propio
        if (message.sender.id != currentUserId) {
          _markMessageAsRead(message.id);
        }
      } else {
        log(
          '⚠️ Mensaje recibido de OTRA conversación: ${message.conversationId}. Actual: ${currentConversation.value?.id}',
          name: 'ChatController',
        );
      }

      // Actualizar última mensaje en lista de conversaciones
      _updateConversationWithNewMessage(message);
    } catch (e) {
      log('Error handling new message: $e', name: 'ChatController', error: e);
    }
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
    } catch (e) {
      log(
        'Error handling message edited: $e',
        name: 'ChatController',
        error: e,
      );
    }
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
    } catch (e) {
      log(
        'Error handling message deleted: $e',
        name: 'ChatController',
        error: e,
      );
    }
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
    } catch (e) {
      log(
        'Error handling message reacted: $e',
        name: 'ChatController',
        error: e,
      );
    }
  }

  void _handleUserTyping(dynamic data) {
    try {
      final conversationId = data['conversationId'];
      final username = data['username'] ?? 'Usuario';
      final userId = data['userId'];

      // Solo mostrar si es la conversación actual y no es el usuario actual
      if (currentConversation.value?.id == conversationId &&
          userId != currentUserId) {
        if (!typingUsers.contains(username)) {
          typingUsers.add(username);
        }
      }
    } catch (e) {
      log('Error handling user typing: $e', name: 'ChatController', error: e);
    }
  }

  void _handleUserStoppedTyping(dynamic data) {
    try {
      final username = data['username'] ?? 'Usuario';
      typingUsers.remove(username);
    } catch (e) {
      log(
        'Error handling user stopped typing: $e',
        name: 'ChatController',
        error: e,
      );
    }
  }

  void _handleNewGroup(dynamic data) {
    try {
      // Recargar conversaciones para mostrar el nuevo grupo
      fetchConversations();

      Get.snackbar(
        'Nuevo Grupo',
        'Has sido añadido a "${data['groupName']}"',
        snackPosition: SnackPosition.TOP,
        backgroundColor: AppColors.primary.withOpacity(0.8),
        colorText: Colors.white,
        duration: const Duration(seconds: 3),
      );
    } catch (e) {
      log('Error handling new group: $e', name: 'ChatController', error: e);
    }
  }

  void _handleMessagesRead(dynamic data) {
    try {
      final messageIds = (data['messageIds'] as List).cast<String>();
      final userId = data['userId'];

      // Actualizar readBy en los mensajes
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
    } catch (e) {
      log('Error handling messages read: $e', name: 'ChatController', error: e);
    }
  }

  void _handleNewGroupPoll(dynamic data) {
    try {
      if (currentConversation.value?.id == data['conversationId']) {
        // Recargar conversación para obtener la nueva encuesta
        fetchMessages(currentConversation.value!.id);

        Get.snackbar(
          '📊 Nueva encuesta',
          data['question'] ?? 'Se ha creado una encuesta',
          snackPosition: SnackPosition.TOP,
          backgroundColor: AppColors.primary.withOpacity(0.8),
          colorText: Colors.white,
          duration: const Duration(seconds: 3),
        );
      }
    } catch (e) {
      log(
        'Error handling new group poll: $e',
        name: 'ChatController',
        error: e,
      );
    }
  }

  void _handleGroupPollUpdated(dynamic data) {
    try {
      if (currentConversation.value?.id == data['conversationId']) {
        // Recargar conversación para obtener votos actualizados
        fetchMessages(currentConversation.value!.id);
      }
    } catch (e) {
      log(
        'Error handling group poll updated: $e',
        name: 'ChatController',
        error: e,
      );
    }
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
      // Si no existe, recargar conversaciones
      fetchConversations();
    }
  }

  void _markMessageAsRead(String messageId) {
    if (currentConversation.value == null) return;

    _socketService.markAsRead(currentConversation.value!.id, [messageId]);
  }

  // ==================== HTTP ENDPOINTS - CONVERSACIONES ====================

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
      log('Error fetching conversations: $e', name: 'ChatController', error: e);
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

      // Unirse a la sala de WebSocket
      _socketService.joinRoom(conversationId);
    } catch (e) {
      log('Error fetching messages: $e', name: 'ChatController', error: e);
      messages.value = [];
    } finally {
      isLoadingMessages.value = false;
    }
  }

  // ==================== WEBSOCKET ACTIONS - MENSAJES ====================

  Future<void> sendMessage(String text, {String? replyToId}) async {
    if (text.trim().isEmpty) return;
    if (currentConversation.value == null) return;

    // ✅ MODERAR CONTENIDO EN FRONTEND
    final moderationResult = ContentModerationService.moderateMessage(
      text.trim(),
    );

    if (!moderationResult.isAllowed) {
      Get.snackbar(
        'Mensaje Bloqueado',
        moderationResult.reason ?? 'Contenido no permitido',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: AppColors.error.withOpacity(0.9),
        colorText: Colors.white,
        duration: const Duration(seconds: 4),
        icon: const Icon(Icons.block, color: Colors.white),
      );
      return;
    }

    final tempId = 'temp_${DateTime.now().millisecondsSinceEpoch}';
    final replyToMessage = replyingTo.value;

    // Mensaje optimista
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
      // ✅ ENVIAR POR WEBSOCKET
      _socketService.sendMessage({
        'conversationId': currentConversation.value!.id,
        'text': moderationResult.sanitizedMessage ?? text.trim(),
        if (replyToId != null || replyingTo.value != null)
          'replyTo': replyToId ?? replyingTo.value?.id,
      });

      // El mensaje real llegará por el evento 'newMessage'
      // Remover mensaje optimista después de 3 segundos
      Future.delayed(const Duration(seconds: 3), () {
        messages.removeWhere((m) => m.id == tempId);
      });
    } catch (e) {
      // Marcar como fallido
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

      Get.snackbar(
        'Error',
        'No se pudo enviar el mensaje',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: AppColors.error.withOpacity(0.8),
        colorText: Colors.white,
      );
    } finally {
      replyingTo.value = null;
      stopTyping();
    }
  }

  // ==================== ENVIAR IMAGEN ====================

  Future<void> sendImage() async {
    if (currentConversation.value == null) return;

    final CloudinaryService cloudinaryService = Get.find<CloudinaryService>();

    // Mostrar diálogo de selección
    final imageUrl = await cloudinaryService.showImagePickerDialog();

    if (imageUrl == null) return;

    // Crear mensaje optimista
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

      // No remover mensaje optimista automáticamente.
      // Se reemplazará cuando llegue el evento 'newMessage' o se actualizará si falla.
    } catch (e) {
      // Marcar como fallido
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

      Get.snackbar(
        'Error',
        'No se pudo enviar la imagen',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: AppColors.error.withOpacity(0.8),
        colorText: Colors.white,
      );
    }
  }

  // ==================== ENVIAR AUDIO ====================

  Future<void> sendAudio(String filePath) async {
    if (currentConversation.value == null) return;

    final CloudinaryService cloudinaryService = Get.find<CloudinaryService>();

    // Mensaje optimista
    final tempId = 'temp_audio_${DateTime.now().millisecondsSinceEpoch}';
    final optimisticMessage = Message(
      id: tempId,
      conversationId: currentConversation.value!.id,
      sender: Sender(id: currentUserId ?? '', username: 'Tú', avatar: null),
      text: '🎤 Grabando/Subiendo...',
      messageType: MessageType.audio,
      audioUrl: null, // Aún no tenemos la URL
      createdAt: DateTime.now(),
      status: MessageStatus.sending,
    );

    messages.add(optimisticMessage);
    scrollToBottom();

    try {
      log('📤 Subiendo audio...', name: 'ChatController');
      // Subir a Cloudinary como 'video' (resource_type)
      // Necesitamos adaptar CloudinaryService o hacerlo aquí.
      // Como CloudinaryService pide XFile, creamos uno.
      // Pero CloudinaryService.uploadImage usa presets de imagen probablemente.
      // Haremos la llamada directa o añadiremos soporte en CloudinaryService.
      // Por simplicidad y rapidez, usaremos el servicio existente asumiendo que el backend lo maneja,
      // PERO el backend de Cloudinary necesita 'resource_type: video' para audios normalmente.

      // Mejor opción: Añadir método uploadAudio en CloudinaryService.
      // Como no puedo editar 2 archivos a la vez en tool calls secuenciales sin riesgo,
      // asumo que CloudinaryService tiene un método genérico o lo añadiré después.
      // Llamaré a un método que crearé: cloudinaryService.uploadAudioFile(File(filePath))

      final audioUrl = await cloudinaryService.uploadAudio(filePath);

      if (audioUrl == null) throw Exception('Error subiendo audio');

      // ✅ Actualizar mensaje optimista con la URL real
      final optIndex = messages.indexWhere((m) => m.id == tempId);
      if (optIndex != -1) {
        messages[optIndex] = messages[optIndex].copyWith(audioUrl: audioUrl);
        messages.refresh();
      }

      _socketService.sendMessage({
        'conversationId': currentConversation.value!.id,
        'text': '', // Texto vacío para audio
        'audioUrl': audioUrl, // El backend debe soportar esto
        'messageType': 'audio',
      });
    } catch (e) {
      log('❌ Error enviando audio: $e', name: 'ChatController');
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
      // 1. Iniciar la videollamada integrada (Jitsi)
      await _jitsiService.startMeeting(conv);

      // 2. Enviar mensaje informando de la llamada
      final String roomName = "NightUp_${conv.id}";
      final String callUrl = "https://meet.jit.si/$roomName";
      sendMessage(
        "📞 He iniciado una videollamada integrada. ¡Únete pulsando el icono de llamada!",
      );

      log(
        '✅ Videollamada iniciada correctamente: $callUrl',
        name: 'ChatController',
      );
    } catch (e) {
      log('❌ Error al iniciar videollamada: $e', name: 'ChatController');
      Get.snackbar('Error', 'No se pudo iniciar la videollamada');
    }
  }

  Future<void> editMessage(String messageId, String newText) async {
    // ✅ MODERAR CONTENIDO
    final moderationResult = ContentModerationService.moderateMessage(
      newText.trim(),
    );

    if (!moderationResult.isAllowed) {
      Get.snackbar(
        'Edición Bloqueada',
        moderationResult.reason ?? 'Contenido no permitido',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: AppColors.error.withOpacity(0.9),
        colorText: Colors.white,
        duration: const Duration(seconds: 4),
      );
      return;
    }

    try {
      _socketService.editMessage(
        messageId,
        moderationResult.sanitizedMessage ?? newText.trim(),
      );
    } catch (e) {
      Get.snackbar(
        'Error',
        'No se pudo editar el mensaje',
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  Future<void> deleteMessage(String messageId) async {
    try {
      _socketService.deleteMessage(messageId);
    } catch (e) {
      Get.snackbar(
        'Error',
        'No se pudo eliminar el mensaje',
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  Future<void> reactToMessage(String messageId, String emoji) async {
    try {
      _socketService.reactToMessage(messageId, emoji);
    } catch (e) {
      log('Error reacting to message: $e', name: 'ChatController', error: e);
    }
  }

  void onTyping() {
    if (currentConversation.value == null) return;

    final username = _apiService.getUsername() ?? 'Usuario';
    _socketService.typing(currentConversation.value!.id, username);

    // Auto-stop después de 2 segundos
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

  // ==================== ENCUESTAS EN GRUPOS ====================

  Future<void> createGroupPoll({
    required String question,
    required List<String> options,
    DateTime? expiresAt,
  }) async {
    if (currentConversation.value == null ||
        !currentConversation.value!.isGroup) {
      Get.snackbar(
        'Error',
        'Solo puedes crear encuestas en grupos',
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }

    if (question.trim().isEmpty) {
      Get.snackbar(
        'Error',
        'La pregunta no puede estar vacía',
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }

    if (options.length < 2) {
      Get.snackbar(
        'Error',
        'Debes añadir al menos 2 opciones',
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }

    try {
      _socketService.socket.emit('createGroupPoll', {
        'conversationId': currentConversation.value!.id,
        'question': question.trim(),
        'options': options.map((o) => o.trim()).toList(),
        if (expiresAt != null) 'expiresAt': expiresAt.toIso8601String(),
      });

      Get.snackbar(
        '✅ Encuesta creada',
        question,
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: AppColors.success.withOpacity(0.8),
        colorText: Colors.white,
      );
    } catch (e) {
      Get.snackbar(
        'Error',
        'No se pudo crear la encuesta',
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  Future<void> voteInGroupPoll(String pollId, int optionIndex) async {
    if (currentConversation.value == null) return;

    try {
      _socketService.socket.emit('voteInGroupPoll', {
        'conversationId': currentConversation.value!.id,
        'pollId': pollId,
        'optionIndex': optionIndex,
      });
    } catch (e) {
      Get.snackbar(
        'Error',
        'No se pudo registrar el voto',
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  // ==================== CONVERSACIONES ====================

  void setCurrentConversation(Conversation conversation) {
    // Salir de la sala anterior
    if (currentConversation.value != null) {
      _socketService.leaveRoom(currentConversation.value!.id);
    }

    currentConversation.value = conversation;
    messages.clear();
    typingUsers.clear();

    fetchMessages(conversation.id);

    // Resetear contador de no leídos
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
      Get.snackbar(
        'Éxito',
        'Grupo "$name" creado correctamente',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: AppColors.success.withOpacity(0.8),
        colorText: Colors.white,
      );
    } catch (e) {
      Get.snackbar(
        'Error',
        'No se pudo crear el grupo: $e',
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  // ==================== POLLS ====================

  Future<void> loadPolls() async {
    isLoadingPolls.value = true;
    try {
      polls.value = await _pollService.getActivePolls(limit: 50);
    } catch (e) {
      log('Error loading polls: $e', name: 'ChatController', error: e);
      Get.snackbar(
        'Error',
        'No se pudieron cargar las encuestas',
        snackPosition: SnackPosition.BOTTOM,
      );
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

      Get.snackbar(
        '✅ Encuesta Creada',
        question,
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: AppColors.success.withOpacity(0.8),
        colorText: Colors.white,
        duration: const Duration(seconds: 3),
      );
    } catch (e) {
      Get.snackbar(
        'Error',
        'No se pudo crear la encuesta: $e',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: AppColors.error.withOpacity(0.8),
        colorText: Colors.white,
      );
      rethrow;
    }
  }

  Future<void> voteInPoll(String pollId, int optionIndex) async {
    try {
      final updatedPoll = await _pollService.voteInPoll(pollId, optionIndex);

      // Actualizar poll en la lista
      final index = polls.indexWhere((p) => p.id == pollId);
      if (index != -1) {
        polls[index] = updatedPoll;
      }

      Get.snackbar(
        '✅ Voto Registrado',
        'Tu voto ha sido contabilizado',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: AppColors.success.withOpacity(0.8),
        colorText: Colors.white,
        duration: const Duration(seconds: 2),
      );
    } catch (e) {
      Get.snackbar(
        'Error',
        e.toString().replaceAll('Exception: ', ''),
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: AppColors.error.withOpacity(0.8),
        colorText: Colors.white,
      );
    }
  }

  Future<void> closePoll(String pollId) async {
    try {
      final updatedPoll = await _pollService.closePoll(pollId);

      // Actualizar poll en la lista
      final index = polls.indexWhere((p) => p.id == pollId);
      if (index != -1) {
        polls[index] = updatedPoll;
      }

      Get.snackbar(
        '✅ Encuesta Cerrada',
        'La encuesta ha sido cerrada',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: AppColors.success.withOpacity(0.8),
        colorText: Colors.white,
      );
    } catch (e) {
      Get.snackbar(
        'Error',
        'No se pudo cerrar la encuesta',
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  Future<PollResults> getPollResults(String pollId) async {
    try {
      return await _pollService.getPollResults(pollId);
    } catch (e) {
      Get.snackbar(
        'Error',
        'No se pudieron cargar los resultados',
        snackPosition: SnackPosition.BOTTOM,
      );
      rethrow;
    }
  }

  // ==================== HELPERS ====================

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
