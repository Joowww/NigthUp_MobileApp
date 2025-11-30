import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/chat_controller.dart';
import 'create_group_screen.dart';
import '../theme/colors.dart';

class GroupsScreen extends StatelessWidget {
  final ChatController _chatController = Get.find<ChatController>();

  GroupsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('Group Polls'),
        backgroundColor: Colors.black,
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Get.to(() => CreateGroupScreen()); // ✅ CORREGIDO: Navega a pantalla con Material
        },
        backgroundColor: AppColors.primary,
        child: const Icon(Icons.group_add, color: Colors.white),
      ),
      body: Obx(() {
        final polls = _chatController.polls;
        if (polls.isEmpty) {
          return const Center(child: Text('No polls yet', style: TextStyle(color: Colors.white70)));
        }
        return ListView.builder(
          itemCount: polls.length,
          itemBuilder: (context, index) {
            final poll = polls[index];
            return Card(
              color: Colors.grey[900],
              margin: const EdgeInsets.all(12),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(poll['question'] ?? '', style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    ...List.generate((poll['options'] as List).length, (i) {
                      final option = poll['options'][i];
                      final votes = (poll['votes']?[i] ?? 0).toString();
                      return Row(
                        children: [
                          Expanded(child: Text(option, style: const TextStyle(color: Colors.white70))),
                          Text('$votes votes', style: const TextStyle(color: Colors.white54)),
                        ],
                      );
                    }),
                  ],
                ),
              ),
            );
          },
        );
      }),
    );
  }
}