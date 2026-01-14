import 'dart:developer';
import 'package:get/get.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import '../services/storage_service.dart';
import '../services/api_service.dart';
import 'notification_service.dart';

class SocketService extends GetxService {
  late IO.Socket _socket;
  final StorageService _storageService = Get.find<StorageService>();
  final ApiService _apiService = Get.find<ApiService>();

  final RxBool _isConnected = false.obs;
  final RxList<String> _onlineUsers = <String>[].obs;

  bool get isConnected => _isConnected.value;
  IO.Socket get socket => _socket;
  RxList<String> get onlineUsers => _onlineUsers;

  @override
  void onInit() {
    super.onInit();
    _initSocket();
  }

  void _initSocket() {
    final userId = _apiService.getUserId();
    if (userId == null) {
      log('⚠️ No userId found for socket connection');
      return;
    }

    // ✅ FIX: Socket.IO está en la raíz, no en /api
    final socketUrl = _apiService.baseUrl.replaceAll('/api', '');

    log('🔌 Connecting socket to: $socketUrl with userId: $userId');

    _socket = IO.io(
      socketUrl,
      IO.OptionBuilder()
          .setTransports(['websocket'])
          .enableAutoConnect()
          .setAuth({'userId': userId})
          .build(),
    );

    // ==================== CONEXIÓN ====================

    _socket.onConnect((_) {
      _isConnected.value = true;
      log('✅ Socket connected with userId: $userId');
    });

    _socket.onDisconnect((_) {
      _isConnected.value = false;
      log('❌ Socket disconnected');
    });

    _socket.onError((data) {
      log('❌ Socket error: $data');
    });

    _socket.onConnectError((data) {
      log('❌ Socket connection error: $data');
    });

    // ==================== EVENTOS GLOBALES ====================

    _socket.on('onlineUsers', (data) {
      log('👥 Online users updated: $data');
      if (data is List) {
        _onlineUsers.value = data.cast<String>();
      }
    });

    _socket.on('userJoined', (data) {
      log('👋 User joined: ${data['userId']}');
    });

    _socket.on('userDisconnected', (data) {
      log('👋 User disconnected: ${data['userId']}');
    });

    // ==================== EVENTOS DE MENSAJES ====================

    _socket.on('newMessage', (data) {
      log('📨 New message received: ${data['_id']}');

      // ✅ NUEVO: Mostrar notificación in-app si no estamos en ese chat
      try {
        final conversationId = data['conversation']?.toString();
        final senderName = data['sender']?['username'] ?? 'Usuario';
        final messageText = data['messageType'] == 'image'
            ? '📷 Imagen'
            : (data['text'] ?? '');

        // Obtener ChatController de forma segura
        if (Get.isRegistered<dynamic>(tag: 'ChatController')) {
          final chatController = Get.find(tag: 'ChatController');
          final currentChatId = chatController.currentConversation?.value?.id;

          // Solo mostrar si NO estamos en ese chat actualmente
          if (conversationId != null && conversationId != currentChatId) {
            NotificationService().showInAppNotification(
              title: senderName,
              message: messageText,
              imageUrl: data['sender']?['avatar'],
              onTap: () {
                // Navegar al chat al tocar la notificación
                final conversation = chatController.conversations
                    .firstWhereOrNull((c) => c.id == conversationId);

                if (conversation != null) {
                  chatController.setCurrentConversation(conversation);
                }
              },
            );
          }
        }
      } catch (e) {
        log('Error showing in-app notification: $e');
      }

      // El ChatController manejará este evento
    });

    _socket.on('messageEdited', (data) {
      log('✏️ Message edited: ${data['_id']}');
      // El ChatController manejará este evento
    });

    _socket.on('messageDeleted', (data) {
      log('🗑️ Message deleted: ${data['messageId']}');
      // El ChatController manejará este evento
    });

    _socket.on('messageReacted', (data) {
      log('👍 Message reacted: ${data['messageId']}');
      // El ChatController manejará este evento
    });

    // ==================== EVENTOS DE TYPING ====================

    _socket.on('userTyping', (data) {
      log('✍️ User typing: ${data['username']} in ${data['conversationId']}');
      // El ChatController manejará este evento
    });

    _socket.on('userStoppedTyping', (data) {
      log('🛑 User stopped typing: ${data['username']}');
      // El ChatController manejará este evento
    });

    // ==================== EVENTOS DE GRUPOS ====================

    _socket.on('newGroup', (data) {
      log('👥 New group created: ${data['groupId']}');
      // El ChatController manejará este evento
    });

    // ==================== EVENTOS DE LECTURA ====================

    _socket.on('messagesRead', (data) {
      log('👁️ Messages read by: ${data['userId']}');
      // El ChatController manejará este evento
    });

    // ==================== ERRORES ====================

    _socket.on('error', (data) {
      log('❌ Server error: ${data['message']}');
      // El ChatController manejará este evento
    });

    _socket.connect();
  }

  // ==================== SALAS ====================

  void joinRoom(String conversationId) {
    if (!_isConnected.value) {
      log('⚠️ Cannot join room: socket not connected');
      return;
    }
    log('🚪 Joining room: $conversationId');
    _socket.emit('joinRoom', conversationId);
  }

  void leaveRoom(String conversationId) {
    if (!_isConnected.value) return;
    log('🚪 Leaving room: $conversationId');
    _socket.emit('leaveRoom', conversationId);
  }

  // ==================== MENSAJES ====================

  void sendMessage(Map<String, dynamic> message) {
    if (!_isConnected.value) {
      log('⚠️ Cannot send message: socket not connected');
      throw Exception('Socket not connected');
    }
    log('📤 Sending message: $message');
    _socket.emit('sendMessage', message);
  }

  void editMessage(String messageId, String text) {
    if (!_isConnected.value) {
      log('⚠️ Cannot edit message: socket not connected');
      throw Exception('Socket not connected');
    }
    log('✏️ Editing message: $messageId');
    _socket.emit('editMessage', {'messageId': messageId, 'text': text});
  }

  void deleteMessage(String messageId) {
    if (!_isConnected.value) {
      log('⚠️ Cannot delete message: socket not connected');
      throw Exception('Socket not connected');
    }
    log('🗑️ Deleting message: $messageId');
    _socket.emit('deleteMessage', {'messageId': messageId});
  }

  void reactToMessage(String messageId, String emoji) {
    if (!_isConnected.value) return;
    log('👍 Reacting to message: $messageId with $emoji');
    _socket.emit('reactToMessage', {'messageId': messageId, 'emoji': emoji});
  }

  // ==================== TYPING INDICATORS ====================

  void typing(String conversationId, String username) {
    if (!_isConnected.value) return;
    _socket.emit('typing', {
      'conversationId': conversationId,
      'username': username,
    });
  }

  void stopTyping(String conversationId, String username) {
    if (!_isConnected.value) return;
    _socket.emit('stopTyping', {
      'conversationId': conversationId,
      'username': username,
    });
  }

  // ==================== GRUPOS ====================

  void createGroup(String name, List<String> participants) {
    if (!_isConnected.value) {
      log('⚠️ Cannot create group: socket not connected');
      throw Exception('Socket not connected');
    }
    log('👥 Creating group: $name');
    _socket.emit('createGroup', {'name': name, 'participants': participants});
  }

  // ==================== MARCAR COMO LEÍDO ====================

  void markAsRead(String conversationId, List<String> messageIds) {
    if (!_isConnected.value) return;
    _socket.emit('markAsRead', {
      'conversationId': conversationId,
      'messageIds': messageIds,
    });
  }

  // ==================== HELPERS ====================

  bool isUserOnline(String userId) {
    return _onlineUsers.contains(userId);
  }

  void reconnect() {
    if (!_isConnected.value) {
      log('🔄 Attempting to reconnect...');
      _socket.connect();
    }
  }

  void disconnect() {
    if (_isConnected.value) {
      log('🔌 Disconnecting socket...');
      _socket.disconnect();
    }
  }

  @override
  void onClose() {
    _socket.disconnect();
    _socket.dispose();
    super.onClose();
  }
}
