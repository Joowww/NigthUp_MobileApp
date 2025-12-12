// lib/services/socket_service.dart
import 'dart:developer';
import 'package:get/get.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import '../services/storage_service.dart';
import '../services/api_service.dart';

class SocketService extends GetxService {
  late IO.Socket _socket;
  final StorageService _storageService = Get.find<StorageService>();
  final ApiService _apiService = Get.find<ApiService>();
  
  final RxBool _isConnected = false.obs;
  final RxList<dynamic> _messages = <dynamic>[].obs;
  final RxInt _unreadNotifications = 0.obs;
  final RxList<dynamic> _polls = <dynamic>[].obs;
  final RxMap<String, dynamic> _friendStatus = <String, dynamic>{}.obs;

  bool get isConnected => _isConnected.value;
  RxList<dynamic> get messages => _messages;
  RxInt get unreadNotifications => _unreadNotifications;
  RxList<dynamic> get polls => _polls;
  RxMap<String, dynamic> get friendStatus => _friendStatus;

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

    log('🔌 Connecting socket with userId: $userId');

    // ✅ CORREGIDO: Conectar con autenticación correcta
    _socket = IO.io(
      'http://localhost:3000', // ✅ Sin /api
      IO.OptionBuilder()
        .setTransports(['websocket'])
        .enableAutoConnect()
        .setAuth({'userId': userId}) // ✅ Pasar userId en auth
        .build(),
    );

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

    // ===== EVENTOS DEL BACKEND =====
    
    // Nuevo mensaje
    _socket.on('newMessage', (data) {
      log('📨 New message received: $data');
      _messages.add(data);
      _unreadNotifications.value++;
    });

    // Mensaje editado
    _socket.on('messageEdited', (data) {
      log('✏️ Message edited: $data');
      final index = _messages.indexWhere((m) => m['_id'] == data['_id']);
      if (index != -1) {
        _messages[index] = data;
      }
    });

    // Mensaje eliminado
    _socket.on('messageDeleted', (data) {
      log('🗑️ Message deleted: ${data['messageId']}');
      final index = _messages.indexWhere((m) => m['_id'] == data['messageId']);
      if (index != -1) {
        _messages[index] = {
          ..._messages[index],
          'isDeleted': true,
          'text': 'Mensaje eliminado'
        };
      }
    });

    // Reacción a mensaje
    _socket.on('messageReacted', (data) {
      log('👍 Message reacted: ${data['messageId']}');
      final index = _messages.indexWhere((m) => m['_id'] == data['messageId']);
      if (index != -1) {
        _messages[index] = {
          ..._messages[index],
          'reactions': data['reactions']
        };
      }
    });

    // Nuevo grupo creado
    _socket.on('newGroup', (data) {
      log('👥 New group created: $data');
    });

    // Usuario escribiendo
    _socket.on('userTyping', (data) {
      log('✍️ User typing: ${data['userId']}');
    });

    // Usuario dejó de escribir
    _socket.on('userStoppedTyping', (data) {
      log('User stopped typing: ${data['userId']}');
    });

    // Mensaje bloqueado por moderación
    _socket.on('messageBlocked', (data) {
      log('🚫 Message blocked: $data');
      Get.snackbar(
        'Mensaje bloqueado',
        data['reason'] ?? 'Tu mensaje contiene contenido inapropiado',
        snackPosition: SnackPosition.BOTTOM,
      );
    });

    // Edición bloqueada por moderación
    _socket.on('editBlocked', (data) {
      log('🚫 Edit blocked: $data');
      Get.snackbar(
        'Edición bloqueada',
        data['reason'] ?? 'Tu edición contiene contenido inapropiado',
        snackPosition: SnackPosition.BOTTOM,
      );
    });

    _socket.connect();
  }

  // ===== MÉTODOS PARA EMITIR EVENTOS =====

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

  void sendMessage(Map<String, dynamic> message) {
    if (!_isConnected.value) {
      log('⚠️ Cannot send message: socket not connected');
      return;
    }
    log('📤 Sending message: $message');
    _socket.emit('sendMessage', message);
  }

  void editMessage(String messageId, String text) {
    if (!_isConnected.value) return;
    log('✏️ Editing message: $messageId');
    _socket.emit('editMessage', {
      'messageId': messageId,
      'text': text,
    });
  }

  void deleteMessage(String messageId) {
    if (!_isConnected.value) return;
    log('🗑️ Deleting message: $messageId');
    _socket.emit('deleteMessage', {'messageId': messageId});
  }

  void reactToMessage(String messageId, String emoji) {
    if (!_isConnected.value) return;
    log('👍 Reacting to message: $messageId with $emoji');
    _socket.emit('reactToMessage', {
      'messageId': messageId,
      'emoji': emoji,
    });
  }

  void typing(String conversationId) {
    if (!_isConnected.value) return;
    _socket.emit('typing', {'conversationId': conversationId});
  }

  void stopTyping(String conversationId) {
    if (!_isConnected.value) return;
    _socket.emit('stopTyping', {'conversationId': conversationId});
  }

  void createGroup(String name, List<String> participants) {
    if (!_isConnected.value) return;
    log('👥 Creating group: $name');
    _socket.emit('createGroup', {
      'name': name,
      'participants': participants,
    });
  }

  void joinConversation(String conversationId) {
    joinRoom(conversationId);
  }

  void leaveConversation(String conversationId) {
    leaveRoom(conversationId);
  }

  void resetUnreadNotifications() {
    _unreadNotifications.value = 0;
  }

  @override
  void onClose() {
    _socket.disconnect();
    _socket.dispose();
    super.onClose();
  }
}