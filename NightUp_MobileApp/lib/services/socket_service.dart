import 'dart:developer';
import 'package:get/get.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import '../services/storage_service.dart';

class SocketService extends GetxService {
    void resetUnreadNotifications() {
      _unreadNotifications.value = 0;
    }
  late IO.Socket _socket;
  final StorageService _storageService = Get.find<StorageService>();
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
    final token = _storageService.read('token');
    if (token == null) {
      log('No token found for socket connection');
      return;
    }

    // Conectar al servidor Socket.io de tu backend
    _socket = IO.io(
      'http://localhost:3000', // Ajusta según tu backend
      IO.OptionBuilder()
        .setTransports(['websocket'])
        .enableAutoConnect()
        .setExtraHeaders({'Authorization': 'Bearer $token'})
        .build(),
    );

    _socket.onConnect((_) {
      _isConnected.value = true;
      log('Socket connected');
    });

    _socket.onDisconnect((_) {
      _isConnected.value = false;
      log('Socket disconnected');
    });

    _socket.onError((data) {
      log('Socket error: $data');
    });

    // Escuchar mensajes nuevos
    _socket.on('newMessage', (data) {
      _messages.add(data);
      log('New message received: $data');
    });

    // Notificación de nuevo mensaje (badge)
    _socket.on('newMessageNotification', (data) {
      _unreadNotifications.value++;
      log('New message notification: $data');
    });

    // Polls en grupos
    _socket.on('newGroupPoll', (data) {
      _polls.add(data);
      log('New group poll: $data');
    });
    _socket.on('pollUpdated', (data) {
      // Actualizar poll existente
      int idx = _polls.indexWhere((p) => p['_id'] == data['_id']);
      if (idx != -1) {
        _polls[idx] = data;
      } else {
        _polls.add(data);
      }
      log('Poll updated: $data');
    });

    // Estado de amigos online/offline
    _socket.on('friend-status-change', (data) {
      if (data is Map && data.containsKey('userId') && data.containsKey('status')) {
        _friendStatus[data['userId']] = data['status'];
        log('Friend status change: $data');
      }
    });

    // Escuchar cuando un usuario se une
    _socket.on('userJoined', (data) {
      log('User joined: $data');
    });

    // Escuchar cuando un usuario abandona
    _socket.on('userLeft', (data) {
      log('User left: $data');
    });

    _socket.connect();
  }

  void sendMessage(Map<String, dynamic> message) {
    _socket.emit('sendMessage', message);
  }

  void joinConversation(String conversationId) {
    _socket.emit('joinConversation', conversationId);
  }

  void leaveConversation(String conversationId) {
    _socket.emit('leaveConversation', conversationId);
  }

  void typing(String conversationId, bool isTyping) {
    _socket.emit('typing', {
      'conversationId': conversationId,
      'isTyping': isTyping
    });
  }

  @override
  void onClose() {
    _socket.disconnect();
    super.onClose();
  }
}