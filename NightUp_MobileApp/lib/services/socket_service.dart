import 'package:get/get.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import '../services/storage_service.dart';

class SocketService extends GetxService {
  late IO.Socket _socket;
  final StorageService _storageService = Get.find<StorageService>();
  final RxBool _isConnected = false.obs;
  final RxList<dynamic> _messages = <dynamic>[].obs;

  bool get isConnected => _isConnected.value;
  List<dynamic> get messages => _messages;

  @override
  void onInit() {
    super.onInit();
    _initSocket();
  }

  void _initSocket() {
    final token = _storageService.read('token');
    if (token == null) {
      print('No token found for socket connection');
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
      print('Socket connected');
    });

    _socket.onDisconnect((_) {
      _isConnected.value = false;
      print('Socket disconnected');
    });

    _socket.onError((data) {
      print('Socket error: $data');
    });

    // Escuchar mensajes nuevos
    _socket.on('newMessage', (data) {
      _messages.add(data);
      print('New message received: $data');
    });

    // Escuchar cuando un usuario se une
    _socket.on('userJoined', (data) {
      print('User joined: $data');
    });

    // Escuchar cuando un usuario abandona
    _socket.on('userLeft', (data) {
      print('User left: $data');
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