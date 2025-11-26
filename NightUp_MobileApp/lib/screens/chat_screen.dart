import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/chat_controller.dart';
import '../theme/colors.dart';
import '../widgets/glass_card.dart';
import '../widgets/image_with_fallback.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final ChatController _chatController = Get.find<ChatController>();
  final TextEditingController _searchController = TextEditingController();
  bool _showIndividualChat = false;

  @override
  void initState() {
    super.initState();
    _chatController.fetchConversations();
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
      floatingActionButton: FloatingActionButton(
        onPressed: _showCreateGroupDialog,
        backgroundColor: AppColors.primary,
        child: const Icon(Icons.group_add, color: Colors.white),
      ),
      body: Column(
        children: [
          _buildHeader(),
          _buildSearchBar(),
          Expanded(
            child: Obx(() {
              if (_chatController.isLoading.value) {
                return const Center(child: CircularProgressIndicator(color: AppColors.primary));
              }
              
              final filteredConversations = _chatController.conversations
                  .where((conv) => conv['name']?.toLowerCase().contains(
                        _searchController.text.toLowerCase()) ?? false)
                  .toList();

              return ListView.builder(
                itemCount: filteredConversations.length,
                itemBuilder: (context, index) {
                  final conv = filteredConversations[index];
                  return _buildConversationItem(conv);
                },
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildConversationItem(Map<String, dynamic> conv) {
    final lastMessage = conv['lastMessage'];
    final isGroup = conv['isGroup'] ?? false;
    final unreadCount = conv['unreadCount'] ?? 0;

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
            // Avatar
            if (isGroup)
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  gradient: AppColors.primaryGradient,
                  shape: BoxShape.circle,
                ),
                child: const Center(
                  child: Icon(Icons.group, color: Colors.white, size: 24),
                ),
              )
            else
              Container(
                width: 56,
                height: 56,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(28),
                  child: ImageWithFallback(
                    imageUrl: conv['otherUser']?['profilePictureUrl'],
                    fit: BoxFit.cover,
                  ),
                ),
              ),
            
            const SizedBox(width: 12),
            
            // Información de la conversación
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        conv['name'] ?? conv['otherUser']?['username'] ?? 'Unknown',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      if (unreadCount > 0) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.primary,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            unreadCount > 99 ? '99+' : '$unreadCount',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                      const Spacer(),
                      Text(
                        _formatTime(lastMessage?['createdAt']),
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    lastMessage?['content'] ?? 'No messages yet',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 14,
                      fontWeight: unreadCount > 0 ? FontWeight.w600 : FontWeight.normal,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
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
            child: Obx(() => ListView.builder(
              reverse: true,
              padding: const EdgeInsets.all(16),
              itemCount: _chatController.messages.length,
              itemBuilder: (context, index) {
                final message = _chatController.messages[index];
                return _buildMessageBubble(message);
              },
            )),
          ),
          _buildMessageInput(),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(Map<String, dynamic> message) {
    final isMe = message['sender']?['_id'] == 'current-user' || 
                 message['sender']?['username'] == 'You';
    
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        children: [
          if (!isMe) ...[
            CircleAvatar(
              radius: 16,
              backgroundImage: NetworkImage(
                message['sender']?['profilePictureUrl'] ?? '',
              ),
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: GlassCard(
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(isMe ? 16 : 4),
                topRight: Radius.circular(isMe ? 4 : 16),
                bottomLeft: const Radius.circular(16),
                bottomRight: const Radius.circular(16),
              ),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (!isMe)
                      Text(
                        message['sender']?['username'] ?? 'Unknown',
                        style: const TextStyle(
                          color: AppColors.primary,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    Text(
                      message['content'] ?? '',
                      style: const TextStyle(color: Colors.white, fontSize: 14),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _formatTime(message['createdAt']),
                      style: const TextStyle(
                        color: Colors.white54,
                        fontSize: 10,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageInput() {
    final TextEditingController _textController = TextEditingController();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(color: AppColors.glassBorder),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: GlassCard(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                height: 48,
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _textController,
                        decoration: const InputDecoration(
                          hintText: 'Type a message...',
                          hintStyle: TextStyle(color: Colors.white70),
                          border: InputBorder.none,
                        ),
                        style: const TextStyle(color: Colors.white),
                        onChanged: (text) {
                          // Implementar typing indicator
                        },
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.attach_file, color: Colors.white70, size: 20),
                      onPressed: () {},
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          GestureDetector(
            onTap: () {
              if (_textController.text.trim().isNotEmpty) {
                _chatController.sendMessage(_textController.text.trim());
                _textController.clear();
              }
            },
            child: Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                gradient: AppColors.primaryGradient,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.send, color: Colors.white, size: 20),
            ),
          ),
        ],
      ),
    );
  }

  void _showCreateGroupDialog() {
    final TextEditingController groupNameController = TextEditingController();
    final List<String> selectedUsers = [];

    Get.dialog(
      GlassCard(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Create Group',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: groupNameController,
                decoration: const InputDecoration(
                  labelText: 'Group Name',
                  labelStyle: TextStyle(color: Colors.white70),
                  border: OutlineInputBorder(),
                ),
                style: const TextStyle(color: Colors.white),
              ),
              const SizedBox(height: 16),
              // Aquí iría la lista de amigos para seleccionar
              const Text(
                'Select friends to add to group',
                style: TextStyle(color: Colors.white70),
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
                      child: const Text('Cancel'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        if (groupNameController.text.isNotEmpty) {
                          _chatController.createGroupChat(
                            groupNameController.text,
                            selectedUsers,
                          );
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                      ),
                      child: const Text('Create'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatTime(String? isoTime) {
    if (isoTime == null) return '';
    try {
      final date = DateTime.parse(isoTime);
      final now = DateTime.now();
      final difference = now.difference(date);

      if (difference.inDays > 0) {
        return '${difference.inDays}d';
      } else if (difference.inHours > 0) {
        return '${difference.inHours}h';
      } else if (difference.inMinutes > 0) {
        return '${difference.inMinutes}m';
      } else {
        return 'now';
      }
    } catch (e) {
      return '';
    }
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: AppColors.glassBorder),
        ),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Messages',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          SizedBox(height: 16),
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
                    hintText: 'Search conversations...',
                    hintStyle: TextStyle(color: Colors.white70),
                    border: InputBorder.none,
                  ),
                  style: const TextStyle(color: Colors.white),
                  onChanged: (value) {
                    setState(() {});
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildChatHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: AppColors.glassBorder),
        ),
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: () {
              setState(() {
                _showIndividualChat = false;
              });
            },
            child: const Icon(Icons.arrow_back, color: Colors.white, size: 24),
          ),
          const SizedBox(width: 12),
          Obx(() {
            final conv = _chatController.currentConversation;
            final isGroup = conv['isGroup'] ?? false;
            
            return Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    conv['name'] ?? conv['otherUser']?['username'] ?? 'Chat',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    isGroup ? 'Group • ${conv['participants']?.length ?? 0} members' : 'Online',
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            );
          }),
          IconButton(
            icon: const Icon(Icons.more_vert, color: Colors.white),
            onPressed: () {
              // Mostrar opciones del chat
            },
          ),
        ],
      ),
    );
  }
}