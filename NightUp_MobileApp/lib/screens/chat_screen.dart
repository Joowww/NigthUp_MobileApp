import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/chat_controller.dart';
import '../services/api_service.dart';
import '../models/conversation.dart';
import '../models/message.dart';
import '../theme/colors.dart';
import '../widgets/glass_card.dart';
import '../widgets/image_with_fallback.dart';
import 'ai_chat_screen.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final ChatController _chatController = Get.find<ChatController>();
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  bool _showIndividualChat = false;
  Timer? _typingTimer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _chatController.fetchConversations();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _messageController.dispose();
    _scrollController.dispose();
    _typingTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_showIndividualChat) {
      return _buildIndividualChat();
    }
    return _buildConversationsList();
  }

  Widget _buildConversationsList() {
    return Scaffold(
      backgroundColor: Colors.black,
      floatingActionButton: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          FloatingActionButton(
            onPressed: _showSearchUsersDialog,
            backgroundColor: AppColors.secondary,
            heroTag: 'search',
            mini: true,
            child: const Icon(
              Icons.person_search,
              color: Colors.white,
              size: 24,
            ),
          ),
          const SizedBox(height: 12),
          FloatingActionButton(
            onPressed: _showCreateGroupDialog,
            backgroundColor: AppColors.primary,
            heroTag: 'group',
            child: const Icon(Icons.group_add, color: Colors.white, size: 28),
          ),
        ],
      ),
      body: Column(
        children: [
          _buildHeader(),
          _buildSearchBar(),
          Expanded(
            child: Obx(() {
              if (_chatController.isLoading.value) {
                return const Center(
                  child: CircularProgressIndicator(color: AppColors.primary),
                );
              }

              final filteredConversations = _chatController.conversations
                  .where(
                    (conv) => conv.displayName.toLowerCase().contains(
                      _searchController.text.toLowerCase(),
                    ),
                  )
                  .toList();

              return RefreshIndicator(
                onRefresh: () => _chatController.fetchConversations(),
                child: ListView.builder(
                  itemCount: filteredConversations.isEmpty
                      ? 2
                      : (filteredConversations.length + 1),
                  itemBuilder: (context, index) {
                    if (index == 0) {
                      return _buildAiConversationItem();
                    }

                    if (filteredConversations.isEmpty) {
                      if (_searchController.text.isNotEmpty) {
                        return const Padding(
                          padding: EdgeInsets.only(top: 40),
                          child: Center(
                            child: Text(
                              'No se encontraron conversaciones',
                              style: TextStyle(color: Colors.white70),
                            ),
                          ),
                        );
                      } else {
                        return SizedBox(
                          height: MediaQuery.of(context).size.height * 0.6,
                          child: _buildEmptyConversations(),
                        );
                      }
                    }

                    final conv = filteredConversations[index - 1];
                    return _buildConversationItem(conv);
                  },
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyConversations() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.chat_bubble_outline, size: 64, color: Colors.white70),
            const SizedBox(height: 16),
            const Text(
              'No tienes conversaciones',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Busca amigos o crea un grupo\npara empezar a chatear',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white70, fontSize: 14),
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton.icon(
                  onPressed: _showSearchUsersDialog,
                  icon: const Icon(Icons.person_search),
                  label: const Text('Buscar Amigos'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.secondary,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 12,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                ElevatedButton.icon(
                  onPressed: _showCreateGroupDialog,
                  icon: const Icon(Icons.group_add),
                  label: const Text('Crear Grupo'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 12,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildConversationItem(Conversation conv) {
    return GestureDetector(
      onTap: () {
        _chatController.setCurrentConversation(conv);
        setState(() {
          _showIndividualChat = true;
        });
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(color: AppColors.glassBorder.withOpacity(0.3)),
          ),
        ),
        child: Row(
          children: [
            Stack(
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: conv.isGroup ? AppColors.primaryGradient : null,
                  ),
                  child: conv.isGroup
                      ? const Center(
                          child: Icon(
                            Icons.group,
                            color: Colors.white,
                            size: 28,
                          ),
                        )
                      : ClipRRect(
                          borderRadius: BorderRadius.circular(28),
                          child: ImageWithFallback(
                            imageUrl: conv.displayAvatar,
                            fit: BoxFit.cover,
                          ),
                        ),
                ),
                if (!conv.isGroup && conv.participants.isNotEmpty)
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: Container(
                      width: 14,
                      height: 14,
                      decoration: BoxDecoration(
                        color: Colors.green,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.black, width: 2),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(width: 12),

            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          conv.displayName,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (conv.unreadCount > 0) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.primary,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            conv.unreadCount > 99
                                ? '99+'
                                : '${conv.unreadCount}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          conv.lastMessage ?? 'Inicia una conversación',
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 14,
                            fontWeight: conv.unreadCount > 0
                                ? FontWeight.w600
                                : FontWeight.normal,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (conv.lastMessageTime != null) ...[
                        const SizedBox(width: 8),
                        Text(
                          _formatTime(conv.lastMessageTime!),
                          style: const TextStyle(
                            color: Colors.white54,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAiConversationItem() {
    return GestureDetector(
      onTap: () {
        Get.to(() => const AiChatScreen());
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(color: AppColors.glassBorder.withOpacity(0.3)),
          ),
          color: AppColors.primary.withOpacity(0.05),
        ),
        child: Row(
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [AppColors.neonBlue, AppColors.neonPurple],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: const Center(
                child: Icon(Icons.auto_awesome, color: Colors.white, size: 28),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'NightUp AI',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: const [
                      Icon(Icons.bolt, color: AppColors.primary, size: 14),
                      SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          'Asistente de eventos inteligente',
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildIndividualChat() {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Column(
        children: [
          _buildChatHeader(),
          Expanded(
            child: Obx(() {
              if (_chatController.messages.isEmpty) {
                return _buildEmptyMessages();
              }

              return ListView.builder(
                controller: _scrollController,
                reverse: true,
                padding: const EdgeInsets.all(16),
                itemCount: _chatController.messages.length,
                itemBuilder: (context, index) {
                  final message = _chatController
                      .messages[_chatController.messages.length - 1 - index];
                  return _buildMessageBubble(message);
                },
              );
            }),
          ),
          _buildMessageInput(),
        ],
      ),
    );
  }

  Widget _buildEmptyMessages() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: const BoxDecoration(
              gradient: AppColors.primaryGradient,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.chat_bubble, color: Colors.white, size: 40),
          ),
          const SizedBox(height: 16),
          const Text(
            'No hay mensajes todavía',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Envía un mensaje para iniciar la conversación',
            style: TextStyle(color: Colors.white70, fontSize: 14),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(Message message) {
    final userId = Get.find<ApiService>().getUserId();
    final isMe = message.sender.id == userId;

    return GestureDetector(
      onLongPress: () => _showMessageOptions(message, isMe),
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          mainAxisAlignment: isMe
              ? MainAxisAlignment.end
              : MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            if (!isMe) ...[
              CircleAvatar(
                radius: 16,
                backgroundImage: message.sender.avatar != null
                    ? NetworkImage(message.sender.avatar!)
                    : null,
                child: message.sender.avatar == null
                    ? const Icon(Icons.person, size: 16)
                    : null,
              ),
              const SizedBox(width: 8),
            ],
            Flexible(
              child: Column(
                crossAxisAlignment: isMe
                    ? CrossAxisAlignment.end
                    : CrossAxisAlignment.start,
                children: [
                  if (message.replyTo != null)
                    _buildReplyPreview(message.replyTo!),

                  GlassCard(
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(isMe ? 16 : 4),
                      topRight: Radius.circular(isMe ? 4 : 16),
                      bottomLeft: const Radius.circular(16),
                      bottomRight: const Radius.circular(16),
                    ),
                    child: Container(
                      constraints: BoxConstraints(
                        maxWidth: MediaQuery.of(context).size.width * 0.7,
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (!isMe)
                            Text(
                              message.sender.username,
                              style: const TextStyle(
                                color: AppColors.primary,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          Text(
                            message.displayText,
                            style: TextStyle(
                              color: message.isDeleted
                                  ? Colors.white54
                                  : Colors.white,
                              fontSize: 14,
                              fontStyle: message.isDeleted
                                  ? FontStyle.italic
                                  : FontStyle.normal,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                _formatMessageTime(message.createdAt),
                                style: const TextStyle(
                                  color: Colors.white54,
                                  fontSize: 10,
                                ),
                              ),
                              if (message.isEdited) ...[
                                const SizedBox(width: 4),
                                const Text(
                                  '· editado',
                                  style: TextStyle(
                                    color: Colors.white54,
                                    fontSize: 10,
                                  ),
                                ),
                              ],
                              if (isMe && message.readBy.length > 1) ...[
                                const SizedBox(width: 4),
                                const Icon(
                                  Icons.done_all,
                                  color: AppColors.primary,
                                  size: 12,
                                ),
                              ],
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),

                  if (message.reactions.isNotEmpty)
                    _buildReactions(message.reactions),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReplyPreview(Message replyMessage) {
    return Container(
      margin: const EdgeInsets.only(bottom: 4),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: AppColors.glassWhite,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.primary),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(width: 3, height: 30, color: AppColors.primary),
          const SizedBox(width: 8),
          Flexible(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  replyMessage.sender.username,
                  style: const TextStyle(
                    color: AppColors.primary,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  replyMessage.displayText,
                  style: const TextStyle(color: Colors.white70, fontSize: 12),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReactions(List<Reaction> reactions) {
    final groupedReactions = <String, List<String>>{};
    for (var reaction in reactions) {
      groupedReactions
          .putIfAbsent(reaction.emoji, () => [])
          .add(reaction.userId);
    }

    return Container(
      margin: const EdgeInsets.only(top: 4),
      child: Wrap(
        spacing: 4,
        children: groupedReactions.entries.map((entry) {
          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: AppColors.glassWhite,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.primary),
            ),
            child: Text(
              '${entry.key} ${entry.value.length}',
              style: const TextStyle(fontSize: 12),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildMessageInput() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: AppColors.glassBorder)),
      ),
      child: Row(
        children: [
          Expanded(
            child: GlassCard(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                constraints: const BoxConstraints(
                  minHeight: 48,
                  maxHeight: 120,
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _messageController,
                        decoration: const InputDecoration(
                          hintText: 'Escribe un mensaje...',
                          hintStyle: TextStyle(color: Colors.white70),
                          border: InputBorder.none,
                        ),
                        style: const TextStyle(color: Colors.white),
                        maxLines: null,
                        textCapitalization: TextCapitalization.sentences,
                        onChanged: (text) {
                          if (text.isNotEmpty) {
                            _chatController.startTyping();
                            _typingTimer?.cancel();
                            _typingTimer = Timer(
                              const Duration(seconds: 2),
                              () {
                                _chatController.stopTyping();
                              },
                            );
                          } else {
                            _chatController.stopTyping();
                          }
                        },
                      ),
                    ),
                    IconButton(
                      icon: const Icon(
                        Icons.attach_file,
                        color: Colors.white70,
                        size: 20,
                      ),
                      onPressed: () {
                        Get.snackbar(
                          'Próximamente',
                          'Función de adjuntos en desarrollo',
                          snackPosition: SnackPosition.BOTTOM,
                        );
                      },
                    ),
                    IconButton(
                      icon: const Icon(
                        Icons.emoji_emotions_outlined,
                        color: Colors.white70,
                        size: 20,
                      ),
                      onPressed: () {
                        Get.snackbar(
                          'Próximamente',
                          'Selector de emojis en desarrollo',
                          snackPosition: SnackPosition.BOTTOM,
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          GestureDetector(
            onTap: () {
              if (_messageController.text.trim().isNotEmpty) {
                _chatController.sendMessage(_messageController.text.trim());
                _messageController.clear();
                _chatController.stopTyping();

                Future.delayed(const Duration(milliseconds: 100), () {
                  if (_scrollController.hasClients) {
                    _scrollController.animateTo(
                      0,
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeOut,
                    );
                  }
                });
              }
            },
            child: Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                gradient: AppColors.primaryGradient,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withOpacity(0.3),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: const Icon(Icons.send, color: Colors.white, size: 20),
            ),
          ),
        ],
      ),
    );
  }

  // ==================== HEADERS ====================

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 48, 16, 16),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: AppColors.glassBorder)),
      ),
      child: Row(
        children: [
          const Text(
            'Mensajes',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(width: 12),
          Obx(() {
            final badge = _chatController.unreadBadge.value;
            if (badge > 0) {
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  badge > 99 ? '99+' : '$badge',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              );
            }
            return const SizedBox.shrink();
          }),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: GlassCard(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          height: 48,
          child: Row(
            children: [
              const Icon(Icons.search, color: Colors.white70, size: 20),
              const SizedBox(width: 12),
              Expanded(
                child: TextField(
                  controller: _searchController,
                  decoration: const InputDecoration(
                    hintText: 'Buscar conversaciones...',
                    hintStyle: TextStyle(color: Colors.white70),
                    border: InputBorder.none,
                  ),
                  style: const TextStyle(color: Colors.white),
                  onChanged: (value) {
                    setState(() {});
                  },
                ),
              ),
              if (_searchController.text.isNotEmpty)
                IconButton(
                  icon: const Icon(
                    Icons.clear,
                    color: Colors.white70,
                    size: 20,
                  ),
                  onPressed: () {
                    _searchController.clear();
                    setState(() {});
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildChatHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 48, 16, 16),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: AppColors.glassBorder)),
      ),
      child: Obx(() {
        final conv = _chatController.currentConversation.value;
        if (conv == null) {
          return const SizedBox.shrink();
        }

        return Row(
          children: [
            GestureDetector(
              onTap: () {
                setState(() {
                  _showIndividualChat = false;
                });
              },
              child: const Icon(
                Icons.arrow_back,
                color: Colors.white,
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: conv.isGroup ? AppColors.primaryGradient : null,
              ),
              child: conv.isGroup
                  ? const Center(
                      child: Icon(Icons.group, color: Colors.white, size: 20),
                    )
                  : ClipRRect(
                      borderRadius: BorderRadius.circular(20),
                      child: ImageWithFallback(
                        imageUrl: conv.displayAvatar,
                        fit: BoxFit.cover,
                      ),
                    ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    conv.displayName,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    conv.isGroup
                        ? '${conv.participants.length} participantes'
                        : 'Online',
                    style: const TextStyle(color: Colors.white70, fontSize: 12),
                  ),
                ],
              ),
            ),
            IconButton(
              icon: const Icon(Icons.videocam, color: Colors.white),
              onPressed: () {
                Get.snackbar(
                  'Próximamente',
                  'Videollamadas en desarrollo',
                  snackPosition: SnackPosition.BOTTOM,
                );
              },
            ),
            IconButton(
              icon: const Icon(Icons.call, color: Colors.white),
              onPressed: () {
                Get.snackbar(
                  'Próximamente',
                  'Llamadas en desarrollo',
                  snackPosition: SnackPosition.BOTTOM,
                );
              },
            ),
            IconButton(
              icon: const Icon(Icons.more_vert, color: Colors.white),
              onPressed: () {
                _showChatOptions();
              },
            ),
          ],
        );
      }),
    );
  }

  void _showCreateGroupDialog() {
    final TextEditingController groupNameController = TextEditingController();
    final RxList<String> selectedFriends = <String>[].obs;
    final RxBool isLoading = false.obs;

    if (_chatController.conversations.isEmpty) {
      Get.snackbar(
        'Cargando...',
        'Espera un momento mientras cargamos tus contactos',
        snackPosition: SnackPosition.BOTTOM,
        duration: const Duration(seconds: 2),
      );
      return;
    }

    Get.dialog(
      Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          constraints: const BoxConstraints(maxWidth: 500),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Colors.grey[900]!, Colors.black],
            ),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: AppColors.primary.withOpacity(0.5),
              width: 2,
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withOpacity(0.3),
                blurRadius: 30,
                spreadRadius: 5,
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppColors.primary.withOpacity(0.2),
                      Colors.transparent,
                    ],
                  ),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(20),
                    topRight: Radius.circular(20),
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.primary, width: 2),
                      ),
                      child: const Icon(
                        Icons.group_add,
                        color: AppColors.primary,
                        size: 28,
                      ),
                    ),
                    const SizedBox(width: 16),
                    const Expanded(
                      child: Text(
                        'Crear Grupo',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () => Get.back(),
                      icon: const Icon(Icons.close, color: Colors.white70),
                    ),
                  ],
                ),
              ),

              // Content
              Flexible(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Nombre del grupo
                      const Text(
                        'Nombre del Grupo',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: groupNameController,
                        style: const TextStyle(color: Colors.white),
                        decoration: InputDecoration(
                          hintText: 'Ej: Amigos de la Universidad',
                          hintStyle: TextStyle(color: Colors.white30),
                          filled: true,
                          fillColor: Colors.white.withOpacity(0.05),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(
                              color: AppColors.primary.withOpacity(0.3),
                            ),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(
                              color: AppColors.primary.withOpacity(0.3),
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(
                              color: AppColors.primary,
                              width: 2,
                            ),
                          ),
                          prefixIcon: const Icon(
                            Icons.group,
                            color: AppColors.primary,
                          ),
                        ),
                      ),

                      const SizedBox(height: 24),

                      // Seleccionar amigos
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Seleccionar Participantes',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Obx(
                            () => Text(
                              '${selectedFriends.length} seleccionados',
                              style: TextStyle(
                                color: AppColors.primary,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      // Lista de conversaciones para seleccionar
                      Obx(() {
                        final privateConversations = _chatController
                            .conversations
                            .where((conv) => !conv.isGroup)
                            .toList();

                        if (privateConversations.isEmpty) {
                          return Container(
                            padding: const EdgeInsets.all(24),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.05),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: AppColors.primary.withOpacity(0.2),
                              ),
                            ),
                            child: Column(
                              children: const [
                                Icon(
                                  Icons.people_outline,
                                  color: Colors.white30,
                                  size: 48,
                                ),
                                SizedBox(height: 12),
                                Text(
                                  'No tienes chats privados todavía.\nAbre un chat con un amigo primero.',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    color: Colors.white70,
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                          );
                        }

                        return Container(
                          constraints: const BoxConstraints(maxHeight: 300),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.05),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: AppColors.primary.withOpacity(0.2),
                            ),
                          ),
                          child: ListView.builder(
                            shrinkWrap: true,
                            itemCount: privateConversations.length,
                            itemBuilder: (context, index) {
                              final conversation = privateConversations[index];
                              final participantId = conversation.participants
                                  .firstWhere(
                                    (p) => p != _chatController.currentUserId,
                                    orElse: () =>
                                        conversation.participants.first,
                                  );

                              return Obx(() {
                                final isSelected = selectedFriends.contains(
                                  participantId,
                                );

                                return Material(
                                  color: Colors.transparent,
                                  child: InkWell(
                                    onTap: () {
                                      if (isSelected) {
                                        selectedFriends.remove(participantId);
                                      } else {
                                        selectedFriends.add(participantId);
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
                                            color: Colors.white.withOpacity(
                                              0.05,
                                            ),
                                          ),
                                        ),
                                      ),
                                      child: Row(
                                        children: [
                                          // Avatar
                                          Container(
                                            width: 40,
                                            height: 40,
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
                                              borderRadius:
                                                  BorderRadius.circular(20),
                                              child: ImageWithFallback(
                                                imageUrl:
                                                    conversation.displayAvatar,
                                                fallbackAsset:
                                                    'assets/images/default-avatar.png',
                                                fit: BoxFit.cover,
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 12),
                                          // Nombre
                                          Expanded(
                                            child: Text(
                                              conversation.displayName,
                                              style: TextStyle(
                                                color: isSelected
                                                    ? Colors.white
                                                    : Colors.white70,
                                                fontSize: 16,
                                                fontWeight: isSelected
                                                    ? FontWeight.bold
                                                    : FontWeight.normal,
                                              ),
                                            ),
                                          ),
                                          // Checkbox
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
                          ),
                        );
                      }),
                    ],
                  ),
                ),
              ),

              // Footer con botones
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  border: Border(
                    top: BorderSide(color: Colors.white.withOpacity(0.1)),
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Get.back(),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          side: BorderSide(color: Colors.white30),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text(
                          'Cancelar',
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Obx(
                        () => ElevatedButton(
                          onPressed: isLoading.value
                              ? null
                              : () async {
                                  if (groupNameController.text.trim().isEmpty) {
                                    Get.snackbar(
                                      'Error',
                                      'Ingresa un nombre para el grupo',
                                      snackPosition: SnackPosition.BOTTOM,
                                      backgroundColor: Colors.red.withOpacity(
                                        0.8,
                                      ),
                                      colorText: Colors.white,
                                    );
                                    return;
                                  }

                                  if (selectedFriends.isEmpty) {
                                    Get.snackbar(
                                      'Error',
                                      'Selecciona al menos un participante',
                                      snackPosition: SnackPosition.BOTTOM,
                                      backgroundColor: Colors.red.withOpacity(
                                        0.8,
                                      ),
                                      colorText: Colors.white,
                                    );
                                    return;
                                  }

                                  isLoading.value = true;
                                  try {
                                    await _chatController.createGroupChat(
                                      groupNameController.text.trim(),
                                      selectedFriends.toList(),
                                    );
                                    Get.back();
                                  } catch (e) {
                                  } finally {
                                    isLoading.value = false;
                                  }
                                },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 0,
                          ),
                          child: isLoading.value
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      Colors.white,
                                    ),
                                  ),
                                )
                              : Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: const [
                                    Icon(
                                      Icons.check,
                                      color: Colors.white,
                                      size: 20,
                                    ),
                                    SizedBox(width: 8),
                                    Text(
                                      'Crear Grupo',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showSearchUsersDialog() {
    final TextEditingController searchController = TextEditingController();
    final RxList<dynamic> allFriends = <dynamic>[].obs;
    final RxList<dynamic> filteredFriends = <dynamic>[].obs;
    final RxBool isLoading = true.obs;

    Future<void> loadFriends() async {
      isLoading.value = true;
      try {
        final apiService = Get.find<ApiService>();
        final response = await apiService.get('/friendship/friends');

        if (response.data != null) {
          // La respuesta es una lista de relaciones de amistad
          final List<dynamic> friendships = response.data is List
              ? response.data
              : [];

          allFriends.value = friendships;
          filteredFriends.value = friendships;
        }
      } catch (e) {
        Get.snackbar(
          'Error',
          'No se pudieron cargar los amigos',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red.withOpacity(0.8),
          colorText: Colors.white,
        );
      } finally {
        isLoading.value = false;
      }
    }

    void filterFriends(String query) {
      if (query.trim().isEmpty) {
        filteredFriends.value = allFriends;
        return;
      }

      final currentUserId = Get.find<ApiService>().getUserId();
      final queryLower = query.toLowerCase();

      filteredFriends.value = allFriends.where((friendship) {
        final requesterData = friendship['requester'];
        final recipientData = friendship['recipient'];

        final isRequester = requesterData['_id'] == currentUserId;
        final friendData = isRequester ? recipientData : requesterData;

        final username = (friendData['username'] ?? '').toLowerCase();
        final email = (friendData['email'] ?? '').toLowerCase();

        return username.contains(queryLower) || email.contains(queryLower);
      }).toList();
    }

    loadFriends();

    Get.dialog(
      Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          constraints: const BoxConstraints(maxWidth: 500, maxHeight: 600),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Colors.grey[900]!, Colors.black],
            ),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: AppColors.primary.withOpacity(0.5),
              width: 2,
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withOpacity(0.3),
                blurRadius: 30,
                spreadRadius: 5,
              ),
            ],
          ),
          child: Column(
            children: [
              // Header
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppColors.primary.withOpacity(0.2),
                      Colors.transparent,
                    ],
                  ),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(20),
                    topRight: Radius.circular(20),
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.primary, width: 2),
                      ),
                      child: const Icon(
                        Icons.search,
                        color: AppColors.primary,
                        size: 28,
                      ),
                    ),
                    const SizedBox(width: 16),
                    const Expanded(
                      child: Text(
                        'Buscar Amigos',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () => Get.back(),
                      icon: const Icon(Icons.close, color: Colors.white70),
                    ),
                  ],
                ),
              ),

              // Search bar
              Padding(
                padding: const EdgeInsets.all(24),
                child: TextField(
                  controller: searchController,
                  style: const TextStyle(color: Colors.white),
                  onChanged: (value) => filterFriends(value),
                  decoration: InputDecoration(
                    hintText: 'Buscar por nombre de usuario...',
                    hintStyle: TextStyle(color: Colors.white30),
                    filled: true,
                    fillColor: Colors.white.withOpacity(0.05),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: AppColors.primary.withOpacity(0.3),
                      ),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: AppColors.primary.withOpacity(0.3),
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(
                        color: AppColors.primary,
                        width: 2,
                      ),
                    ),
                    prefixIcon: const Icon(
                      Icons.search,
                      color: AppColors.primary,
                    ),
                    suffixIcon: searchController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(
                              Icons.clear,
                              color: Colors.white70,
                            ),
                            onPressed: () {
                              searchController.clear();
                              filterFriends('');
                            },
                          )
                        : null,
                  ),
                ),
              ),

              Expanded(
                child: Obx(() {
                  if (isLoading.value) {
                    return const Center(
                      child: CircularProgressIndicator(
                        color: AppColors.primary,
                      ),
                    );
                  }

                  if (allFriends.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.people_outline,
                            size: 64,
                            color: Colors.white30,
                          ),
                          const SizedBox(height: 16),
                          const Text(
                            'No tienes amigos todavía',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'Añade amigos desde el mapa\npara empezar a chatear',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Colors.white54,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    );
                  }

                  if (filteredFriends.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.search_off,
                            size: 64,
                            color: Colors.white30,
                          ),
                          const SizedBox(height: 16),
                          const Text(
                            'No se encontraron amigos',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'No hay resultados para "${searchController.text}"',
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: Colors.white54,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    );
                  }

                  return ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    itemCount: filteredFriends.length,
                    itemBuilder: (context, index) {
                      final friendship = filteredFriends[index];
                      final currentUserId = Get.find<ApiService>().getUserId();

                      final requesterData = friendship['requester'];
                      final recipientData = friendship['recipient'];

                      final isRequester = requesterData['_id'] == currentUserId;
                      final friendData = isRequester
                          ? recipientData
                          : requesterData;

                      final friendId = friendData['_id'];
                      final username = friendData['username'] ?? 'Usuario';
                      final email = friendData['email'] ?? '';
                      final avatar = friendData['avatar'];

                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.05),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: AppColors.primary.withOpacity(0.2),
                          ),
                        ),
                        child: ListTile(
                          leading: Container(
                            width: 50,
                            height: 50,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: AppColors.primary,
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
                          title: Text(
                            username,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          subtitle: Text(
                            email,
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 12,
                            ),
                          ),
                          trailing: ElevatedButton.icon(
                            onPressed: () async {
                              try {
                                await _chatController.createPrivateChat(
                                  friendId,
                                );
                                Get.back();
                                Get.snackbar(
                                  '✅ Chat abierto',
                                  'Conversación con $username',
                                  snackPosition: SnackPosition.BOTTOM,
                                  backgroundColor: AppColors.primary
                                      .withOpacity(0.8),
                                  colorText: Colors.white,
                                  duration: const Duration(seconds: 2),
                                );
                              } catch (e) {
                                Get.snackbar(
                                  'Error',
                                  'No se pudo abrir el chat',
                                  snackPosition: SnackPosition.BOTTOM,
                                  backgroundColor: Colors.red.withOpacity(0.8),
                                  colorText: Colors.white,
                                );
                              }
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 8,
                              ),
                            ),
                            icon: const Icon(
                              Icons.chat,
                              size: 18,
                              color: Colors.white,
                            ),
                            label: const Text(
                              'Chat',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  );
                }),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showMessageOptions(Message message, bool isMe) {
    Get.bottomSheet(
      Container(
        decoration: const BoxDecoration(
          color: Colors.black,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 12),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.white54,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 12),
            if (!message.isDeleted) ...[
              ListTile(
                leading: const Icon(Icons.reply, color: Colors.white),
                title: const Text(
                  'Responder',
                  style: TextStyle(color: Colors.white),
                ),
                onTap: () {
                  Get.back();
                },
              ),
              ListTile(
                leading: const Icon(Icons.emoji_emotions, color: Colors.white),
                title: const Text(
                  'Reaccionar',
                  style: TextStyle(color: Colors.white),
                ),
                onTap: () {
                  Get.back();
                  _showReactionPicker(message.id);
                },
              ),
              if (isMe) ...[
                ListTile(
                  leading: const Icon(Icons.edit, color: Colors.white),
                  title: const Text(
                    'Editar',
                    style: TextStyle(color: Colors.white),
                  ),
                  onTap: () {
                    Get.back();
                    _showEditMessageDialog(message);
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.delete, color: Colors.red),
                  title: const Text(
                    'Eliminar',
                    style: TextStyle(color: Colors.red),
                  ),
                  onTap: () {
                    Get.back();
                    _confirmDeleteMessage(message.id);
                  },
                ),
              ],
            ],
            ListTile(
              leading: const Icon(Icons.info_outline, color: Colors.white),
              title: const Text(
                'Info del mensaje',
                style: TextStyle(color: Colors.white),
              ),
              onTap: () {
                Get.back();
                _showMessageInfo(message);
              },
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }

  void _showReactionPicker(String messageId) {
    final emojis = ['👍', '❤️', '😂', '😮', '😢', '😡', '🔥', '🎉'];

    Get.dialog(
      Dialog(
        backgroundColor: Colors.transparent,
        child: GlassCard(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Wrap(
              spacing: 12,
              runSpacing: 12,
              children: emojis.map((emoji) {
                return GestureDetector(
                  onTap: () {
                    _chatController.reactToMessage(messageId, emoji);
                    Get.back();
                  },
                  child: Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: AppColors.glassWhite,
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: Center(
                      child: Text(emoji, style: const TextStyle(fontSize: 24)),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ),
      ),
    );
  }

  void _showEditMessageDialog(Message message) {
    final TextEditingController editController = TextEditingController(
      text: message.text,
    );

    Get.dialog(
      Dialog(
        backgroundColor: Colors.transparent,
        child: GlassCard(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Editar Mensaje',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: editController,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    enabledBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: AppColors.glassBorder),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: AppColors.primary),
                    ),
                  ),
                  style: const TextStyle(color: Colors.white),
                  maxLines: 3,
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Get.back(),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.white,
                          side: const BorderSide(color: Colors.white70),
                        ),
                        child: const Text('Cancelar'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          if (editController.text.trim().isNotEmpty) {
                            _chatController.editMessage(
                              message.id,
                              editController.text.trim(),
                            );
                            Get.back();
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                        ),
                        child: const Text('Guardar'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _confirmDeleteMessage(String messageId) {
    Get.dialog(
      Dialog(
        backgroundColor: Colors.transparent,
        child: GlassCard(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.delete_forever, color: Colors.red, size: 48),
                const SizedBox(height: 16),
                const Text(
                  'Eliminar Mensaje',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  '¿Estás seguro de que quieres eliminar este mensaje?',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.white70),
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Get.back(),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.white,
                          side: const BorderSide(color: Colors.white70),
                        ),
                        child: const Text('Cancelar'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          _chatController.deleteMessage(messageId);
                          Get.back();
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                        ),
                        child: const Text('Eliminar'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showMessageInfo(Message message) {
    Get.dialog(
      Dialog(
        backgroundColor: Colors.transparent,
        child: GlassCard(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Info del Mensaje',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                _infoRow('Enviado por:', message.sender.username),
                _infoRow('Fecha:', _formatFullDate(message.createdAt)),
                if (message.isEdited)
                  _infoRow(
                    'Editado:',
                    message.updatedAt != null
                        ? _formatFullDate(message.updatedAt!)
                        : 'Sí',
                  ),
                _infoRow('Leído por:', '${message.readBy.length} persona(s)'),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => Get.back(),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                    ),
                    child: const Text('Cerrar'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(color: Colors.white, fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }

  void _showChatOptions() {
    Get.bottomSheet(
      Container(
        decoration: const BoxDecoration(
          color: Colors.black,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 12),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.white54,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 12),
            ListTile(
              leading: const Icon(Icons.search, color: Colors.white),
              title: const Text(
                'Buscar en conversación',
                style: TextStyle(color: Colors.white),
              ),
              onTap: () {
                Get.back();
                Get.snackbar(
                  'Próximamente',
                  'Búsqueda en conversación en desarrollo',
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.wallpaper, color: Colors.white),
              title: const Text(
                'Fondo de pantalla',
                style: TextStyle(color: Colors.white),
              ),
              onTap: () {
                Get.back();
                Get.snackbar(
                  'Próximamente',
                  'Personalización de fondo en desarrollo',
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.notifications_off, color: Colors.white),
              title: const Text(
                'Silenciar notificaciones',
                style: TextStyle(color: Colors.white),
              ),
              onTap: () {
                Get.back();
                Get.snackbar(
                  'Próximamente',
                  'Silenciar notificaciones en desarrollo',
                );
              },
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }

  String _formatTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays == 0) {
      return '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
    } else if (difference.inDays == 1) {
      return 'Ayer';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d';
    } else {
      return '${dateTime.day}/${dateTime.month}';
    }
  }

  String _formatMessageTime(DateTime dateTime) {
    return '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  }

  String _formatFullDate(DateTime dateTime) {
    return '${dateTime.day}/${dateTime.month}/${dateTime.year} ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  }
}
