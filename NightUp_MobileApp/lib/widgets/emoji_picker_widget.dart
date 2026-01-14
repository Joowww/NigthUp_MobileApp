import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../theme/colors.dart';

class EmojiPickerWidget extends StatelessWidget {
  final Function(String) onEmojiSelected;

  const EmojiPickerWidget({Key? key, required this.onEmojiSelected})
    : super(key: key);

  static const List<String> frequentEmojis = [
    '😀',
    '😂',
    '🥰',
    '😍',
    '🤩',
    '😊',
    '😎',
    '🤗',
    '🤔',
    '😐',
    '😑',
    '😶',
    '🙄',
    '😏',
    '😣',
    '😥',
    '😮',
    '🤐',
    '😯',
    '😪',
    '😫',
    '🥱',
    '😴',
    '😌',
    '👍',
    '👎',
    '👏',
    '🙌',
    '👐',
    '🤝',
    '🙏',
    '✌️',
    '🤞',
    '🤟',
    '🤘',
    '🤙',
    '👈',
    '👉',
    '👆',
    '👇',
    '❤️',
    '🧡',
    '💛',
    '💚',
    '💙',
    '💜',
    '🖤',
    '🤍',
    '💔',
    '❣️',
    '💕',
    '💞',
    '💓',
    '💗',
    '💖',
    '💘',
    '🔥',
    '✨',
    '💫',
    '⭐',
    '🌟',
    '💥',
    '💢',
    '💯',
  ];

  static const Map<String, List<String>> emojiCategories = {
    'Frecuentes': frequentEmojis,
    'Caritas': [
      '😀',
      '😃',
      '😄',
      '😁',
      '😆',
      '😅',
      '🤣',
      '😂',
      '🙂',
      '🙃',
      '😉',
      '😊',
      '😇',
      '🥰',
      '😍',
      '🤩',
      '😘',
      '😗',
      '😚',
      '😙',
      '😋',
      '😛',
      '😜',
      '🤪',
      '😝',
      '🤑',
      '🤗',
      '🤭',
      '🤫',
      '🤔',
      '🤐',
      '🤨',
    ],
    'Gestos': [
      '👍',
      '👎',
      '👊',
      '✊',
      '🤛',
      '🤜',
      '🤞',
      '✌️',
      '🤟',
      '🤘',
      '👌',
      '🤌',
      '🤏',
      '👈',
      '👉',
      '👆',
      '👇',
      '☝️',
      '👋',
      '🤚',
      '🖐️',
      '✋',
      '🖖',
      '👏',
    ],
    'Corazones': [
      '❤️',
      '🧡',
      '💛',
      '💚',
      '💙',
      '💜',
      '🖤',
      '🤍',
      '🤎',
      '💔',
      '❣️',
      '💕',
      '💞',
      '💓',
      '💗',
      '💖',
      '💘',
      '💝',
      '💟',
      '☮️',
      '✝️',
      '☪️',
      '🕉️',
      '☸️',
    ],
    'Símbolos': [
      '🔥',
      '✨',
      '💫',
      '⭐',
      '🌟',
      '💥',
      '💢',
      '💯',
      '✅',
      '❌',
      '⭕',
      '🚫',
      '💤',
      '💨',
      '👁️',
      '🗨️',
      '💬',
      '🗯️',
      '💭',
      '🕳️',
      '👣',
      '🔔',
      '🔕',
      '📢',
    ],
  };

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 300,
      decoration: BoxDecoration(
        color: Colors.grey[900],
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          // Handle
          Container(
            margin: const EdgeInsets.symmetric(vertical: 8),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey[700],
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // Tabs
          DefaultTabController(
            length: emojiCategories.length,
            child: Expanded(
              child: Column(
                children: [
                  TabBar(
                    isScrollable: true,
                    indicatorColor: AppColors.primary,
                    labelColor: AppColors.primary,
                    unselectedLabelColor: Colors.grey[600],
                    tabs: emojiCategories.keys
                        .map((category) => Tab(text: category))
                        .toList(),
                  ),
                  Expanded(
                    child: TabBarView(
                      children: emojiCategories.values.map((emojis) {
                        return GridView.builder(
                          padding: const EdgeInsets.all(16),
                          gridDelegate:
                              const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 8,
                                mainAxisSpacing: 8,
                                crossAxisSpacing: 8,
                              ),
                          itemCount: emojis.length,
                          itemBuilder: (context, index) {
                            final emoji = emojis[index];
                            return GestureDetector(
                              onTap: () {
                                onEmojiSelected(emoji);
                                Get.back();
                              },
                              child: Container(
                                decoration: BoxDecoration(
                                  color: Colors.grey[800],
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Center(
                                  child: Text(
                                    emoji,
                                    style: const TextStyle(fontSize: 24),
                                  ),
                                ),
                              ),
                            );
                          },
                        );
                      }).toList(),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
