import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../services/ai_service.dart';
import '../models/event.dart';
import '../theme/colors.dart';
import '../widgets/glass_card.dart';
import '../widgets/image_with_fallback.dart';
import 'event_detail_screen.dart';

class AiChatMessage {
  final bool isUser;
  final String text;
  final List<Event>? events;
  final bool isLoading;

  AiChatMessage({
    required this.isUser,
    required this.text,
    this.events,
    this.isLoading = false,
  });
}

class AiChatScreen extends StatefulWidget {
  const AiChatScreen({super.key});

  @override
  State<AiChatScreen> createState() => _AiChatScreenState();
}

class _AiChatScreenState extends State<AiChatScreen> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final AiService _aiService = Get.put(AiService());

  final List<AiChatMessage> _messages = [
    AiChatMessage(
      isUser: false,
      text:
          'Hello! I am your NightUp event assistant.\n\nYou can ask me things like:\n"Cheap techno party today" or "Art events this weekend".',
    ),
  ];

  void _sendMessage() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;

    setState(() {
      _messages.add(AiChatMessage(isUser: true, text: text));
      _messages.add(
        AiChatMessage(isUser: false, text: 'Thinking...', isLoading: true),
      );
      _controller.clear();
    });
    _scrollToBottom();

    try {
      final result = await _aiService.searchEventsWithAi(text);

      if (result.containsKey('error') && result['error'] != null) {
        throw Exception(result['error']);
      }

      final events = result['events'] as List<Event>;

      if (mounted) {
        setState(() {
          _messages.removeLast();

          String responseText = result['message'] as String? ?? '';

          if (responseText.isEmpty) {
            responseText = events.isNotEmpty
                ? 'Here are the results:'
                : 'No events found for "$text". Try different terms.';
          }

          _messages.add(
            AiChatMessage(
              isUser: false,
              text: responseText,
              events: events.isNotEmpty ? events : null,
            ),
          );
        });
        _scrollToBottom();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _messages.removeLast();
          _messages.add(
            AiChatMessage(isUser: false, text: 'Error searching: $e'),
          );
        });
      }
    }
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text(
          'Asistente IA NightUp',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: Colors.black,
        iconTheme: const IconThemeData(color: Colors.white),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Get.back(),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(16),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                return _buildMessage(_messages[index]);
              },
            ),
          ),
          _buildInput(),
        ],
      ),
    );
  }

  Widget _buildMessage(AiChatMessage message) {
    return Align(
      alignment: message.isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 8),
        width: MediaQuery.of(context).size.width * 0.85,
        child: Column(
          crossAxisAlignment: message.isUser
              ? CrossAxisAlignment.end
              : CrossAxisAlignment.start,
          children: [
            GlassCard(
              borderRadius: BorderRadius.only(
                topLeft: const Radius.circular(16),
                topRight: const Radius.circular(16),
                bottomLeft: message.isUser
                    ? const Radius.circular(16)
                    : Radius.zero,
                bottomRight: message.isUser
                    ? Radius.zero
                    : const Radius.circular(16),
              ),
              child: Container(
                padding: const EdgeInsets.all(12),
                child: Text(
                  message.text,
                  style: const TextStyle(color: Colors.white),
                ),
              ),
            ),
            if (message.isLoading)
              const Padding(
                padding: EdgeInsets.only(top: 8),
                child: SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: AppColors.primary,
                  ),
                ),
              ),
            if (message.events != null && message.events!.isNotEmpty)
              _buildEventList(message.events!),
          ],
        ),
      ),
    );
  }

  Widget _buildEventList(List<Event> events) {
    return Container(
      height: 230,
      margin: const EdgeInsets.only(top: 12),
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: events.length,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (context, index) {
          final event = events[index];
          return GestureDetector(
            onTap: () {
              Get.to(
                () => EventDetailScreen(
                  eventId: event.id,
                  onBack: () => Get.back(),
                ),
              );
            },
            child: SizedBox(
              width: 180,
              child: GlassCard(
                padding: EdgeInsets.zero,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: ClipRRect(
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(16),
                        ),
                        child: ImageWithFallback(
                          imageUrl: event.safeImageUrl,
                          fit: BoxFit.cover,
                          fallbackAsset: 'assets/images/google.png',
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(10.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            event.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            event.formattedDate,
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 10,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            event.displayPrice,
                            style: const TextStyle(
                              color: AppColors.primary,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
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
        },
      ),
    );
  }

  Widget _buildInput() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.black,
        border: Border(top: BorderSide(color: AppColors.glassBorder)),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _controller,
              decoration: InputDecoration(
                hintText: 'Ex: Party this weekend...',
                hintStyle: const TextStyle(color: Colors.white54),
                filled: true,
                fillColor: AppColors.glassWhite,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(25),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 12,
                ),
              ),
              style: const TextStyle(color: Colors.white),
              textCapitalization: TextCapitalization.sentences,
              onSubmitted: (_) => _sendMessage(),
            ),
          ),
          const SizedBox(width: 12),
          GestureDetector(
            onTap: _sendMessage,
            child: Container(
              height: 48,
              width: 48,
              decoration: BoxDecoration(
                gradient: AppColors.primaryGradient,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.send, color: Colors.white, size: 20),
            ),
          ),
        ],
      ),
    );
  }
}
