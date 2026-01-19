import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/chat_controller.dart';
import '../theme/colors.dart';

// ✅ MODIFICACIÓN: Esta pantalla ahora SOLO sirve para mostrar grupos
// Se eliminó toda la funcionalidad de encuestas independientes

class GroupsScreen extends StatelessWidget {
  final ChatController _chatController = Get.find<ChatController>();

  GroupsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        // ✅ MODIFICACIÓN: Título cambiado a "Grupos" en lugar de "Encuestas"
        title: const Text('Grupos'),
        backgroundColor: Colors.black,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => _chatController.fetchConversations(),
          ),
        ],
      ),

      // ✅ MODIFICACIÓN: Se eliminó el FloatingActionButton que creaba encuestas independientes
      // floatingActionButton: FloatingActionButton(...) ❌ ELIMINADO
      body: Obx(() {
        if (_chatController.isLoading.value) {
          return const Center(
            child: CircularProgressIndicator(color: AppColors.primary),
          );
        }

        // ✅ MODIFICACIÓN: Filtrar solo conversaciones de grupo
        final groups = _chatController.conversations
            .where((conv) => conv.isGroup)
            .toList();

        if (groups.isEmpty) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.group_outlined, size: 64, color: Colors.white30),
                SizedBox(height: 16),
                Text(
                  'No tienes grupos todavía',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  'Crea un grupo desde el chat',
                  style: TextStyle(color: Colors.white70, fontSize: 14),
                ),
              ],
            ),
          );
        }

        // ✅ MODIFICACIÓN: Lista simple de grupos
        return RefreshIndicator(
          onRefresh: () => _chatController.fetchConversations(),
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: groups.length,
            itemBuilder: (context, index) {
              final group = groups[index];
              return Card(
                color: Colors.grey[900],
                margin: const EdgeInsets.only(bottom: 12),
                child: ListTile(
                  contentPadding: const EdgeInsets.all(16),
                  leading: const CircleAvatar(
                    radius: 28,
                    backgroundColor: AppColors.primary,
                    child: Icon(Icons.group, color: Colors.white, size: 28),
                  ),
                  title: Text(
                    group.name,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  subtitle: Text(
                    '${group.participants.length} miembros',
                    style: const TextStyle(color: Colors.white54, fontSize: 14),
                  ),
                  trailing: const Icon(
                    Icons.chevron_right,
                    color: Colors.white54,
                  ),
                  onTap: () {
                    // Abrir el grupo
                    _chatController.setCurrentConversation(group);
                    Get.back(); // Volver al chat
                  },
                ),
              );
            },
          ),
        );
      }),
    );
  }
}

// import 'package:flutter/material.dart';
// import 'package:get/get.dart';
// import '../controllers/chat_controller.dart';
// import '../models/poll.dart';
// import '../theme/colors.dart';
// import 'create_poll_screen.dart';
// import 'poll_results_screen.dart';

// class GroupsScreen extends StatelessWidget {
//   final ChatController _chatController = Get.find<ChatController>();

//   GroupsScreen({super.key});

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: Colors.black,
//       appBar: AppBar(
//         title: const Text('Encuestas'),
//         backgroundColor: Colors.black,
//         actions: [
//           IconButton(
//             icon: const Icon(Icons.refresh),
//             onPressed: () => _chatController.loadPolls(),
//           ),
//         ],
//       ),
//       floatingActionButton: FloatingActionButton(
//         onPressed: () {
//           Get.to(() => CreatePollScreen());
//         },
//         backgroundColor: AppColors.primary,
//         child: const Icon(Icons.add, color: Colors.white),
//       ),
//       body: RefreshIndicator(
//         onRefresh: () => _chatController.loadPolls(),
//         child: Obx(() {
//           if (_chatController.isLoadingPolls.value) {
//             return const Center(
//               child: CircularProgressIndicator(color: AppColors.primary),
//             );
//           }

//           final polls = _chatController.polls;

//           if (polls.isEmpty) {
//             return Center(
//               child: Column(
//                 mainAxisAlignment: MainAxisAlignment.center,
//                 children: [
//                   Icon(Icons.poll_outlined, size: 64, color: Colors.white30),
//                   const SizedBox(height: 16),
//                   const Text(
//                     'No hay encuestas todavía',
//                     style: TextStyle(
//                       color: Colors.white,
//                       fontSize: 18,
//                       fontWeight: FontWeight.w600,
//                     ),
//                   ),
//                   const SizedBox(height: 8),
//                   const Text(
//                     'Crea la primera encuesta',
//                     style: TextStyle(color: Colors.white70, fontSize: 14),
//                   ),
//                 ],
//               ),
//             );
//           }

//           return ListView.builder(
//             padding: const EdgeInsets.all(16),
//             itemCount: polls.length,
//             itemBuilder: (context, index) {
//               final poll = polls[index];
//               return _buildPollCard(poll);
//             },
//           );
//         }),
//       ),
//     );
//   }

//   Widget _buildPollCard(Poll poll) {
//     final hasVoted = poll.hasUserVoted(_chatController.currentUserId ?? '');
//     final isCreator = poll.creator.id == _chatController.currentUserId;

//     return Card(
//       color: Colors.grey[900],
//       margin: const EdgeInsets.only(bottom: 16),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           // Header
//           Padding(
//             padding: const EdgeInsets.all(16),
//             child: Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 Row(
//                   children: [
//                     CircleAvatar(
//                       radius: 16,
//                       backgroundColor: AppColors.primary,
//                       child: Text(
//                         poll.creator.username[0].toUpperCase(),
//                         style: const TextStyle(
//                           color: Colors.white,
//                           fontWeight: FontWeight.bold,
//                         ),
//                       ),
//                     ),
//                     const SizedBox(width: 8),
//                     Expanded(
//                       child: Column(
//                         crossAxisAlignment: CrossAxisAlignment.start,
//                         children: [
//                           Text(
//                             poll.creator.username,
//                             style: const TextStyle(
//                               color: Colors.white,
//                               fontWeight: FontWeight.bold,
//                               fontSize: 14,
//                             ),
//                           ),
//                           Text(
//                             _formatDate(poll.createdAt),
//                             style: const TextStyle(
//                               color: Colors.white54,
//                               fontSize: 12,
//                             ),
//                           ),
//                         ],
//                       ),
//                     ),
//                     if (isCreator && poll.isActive)
//                       PopupMenuButton<String>(
//                         icon: const Icon(Icons.more_vert, color: Colors.white),
//                         onSelected: (value) {
//                           if (value == 'close') {
//                             _showClosePollDialog(poll);
//                           }
//                         },
//                         itemBuilder: (context) => [
//                           const PopupMenuItem(
//                             value: 'close',
//                             child: Row(
//                               children: [
//                                 Icon(Icons.close, color: Colors.red),
//                                 SizedBox(width: 8),
//                                 Text('Cerrar encuesta'),
//                               ],
//                             ),
//                           ),
//                         ],
//                       ),
//                   ],
//                 ),
//                 const SizedBox(height: 12),
//                 Text(
//                   poll.question,
//                   style: const TextStyle(
//                     color: Colors.white,
//                     fontSize: 18,
//                     fontWeight: FontWeight.bold,
//                   ),
//                 ),
//                 const SizedBox(height: 8),
//                 Row(
//                   children: [
//                     Icon(
//                       Icons.poll,
//                       size: 16,
//                       color: poll.canVote ? AppColors.primary : Colors.grey,
//                     ),
//                     const SizedBox(width: 4),
//                     Text(
//                       '${poll.totalVotes} ${poll.totalVotes == 1 ? 'voto' : 'votos'}',
//                       style: const TextStyle(
//                         color: Colors.white54,
//                         fontSize: 13,
//                       ),
//                     ),
//                     if (!poll.isActive) ...[
//                       const SizedBox(width: 12),
//                       Container(
//                         padding: const EdgeInsets.symmetric(
//                           horizontal: 8,
//                           vertical: 2,
//                         ),
//                         decoration: BoxDecoration(
//                           color: Colors.red[900],
//                           borderRadius: BorderRadius.circular(12),
//                         ),
//                         child: const Text(
//                           'CERRADA',
//                           style: TextStyle(
//                             color: Colors.white,
//                             fontSize: 11,
//                             fontWeight: FontWeight.bold,
//                           ),
//                         ),
//                       ),
//                     ],
//                     if (poll.isExpired) ...[
//                       const SizedBox(width: 12),
//                       Container(
//                         padding: const EdgeInsets.symmetric(
//                           horizontal: 8,
//                           vertical: 2,
//                         ),
//                         decoration: BoxDecoration(
//                           color: Colors.orange[900],
//                           borderRadius: BorderRadius.circular(12),
//                         ),
//                         child: const Text(
//                           'EXPIRADA',
//                           style: TextStyle(
//                             color: Colors.white,
//                             fontSize: 11,
//                             fontWeight: FontWeight.bold,
//                           ),
//                         ),
//                       ),
//                     ],
//                     if (!poll.isPublic) ...[
//                       const SizedBox(width: 12),
//                       const Icon(Icons.lock, size: 16, color: Colors.amber),
//                     ],
//                   ],
//                 ),
//               ],
//             ),
//           ),

//           // Options
//           ...poll.options.asMap().entries.map((entry) {
//             final index = entry.key;
//             final option = entry.value;
//             final percentage = poll.totalVotes > 0
//                 ? (option.voteCount / poll.totalVotes * 100).round()
//                 : 0;
//             final isVoted = option.voters.contains(
//               _chatController.currentUserId,
//             );

//             return GestureDetector(
//               onTap: !hasVoted && poll.canVote
//                   ? () => _chatController.voteInPoll(poll.id, index)
//                   : null,
//               child: Container(
//                 margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
//                 child: Stack(
//                   children: [
//                     // Barra de progreso
//                     Container(
//                       height: 48,
//                       decoration: BoxDecoration(
//                         color: Colors.grey[800],
//                         borderRadius: BorderRadius.circular(8),
//                       ),
//                       child: FractionallySizedBox(
//                         alignment: Alignment.centerLeft,
//                         widthFactor: percentage / 100,
//                         child: Container(
//                           decoration: BoxDecoration(
//                             gradient: isVoted
//                                 ? AppColors.primaryGradient
//                                 : LinearGradient(
//                                     colors: [
//                                       AppColors.primary.withOpacity(0.3),
//                                       AppColors.primary.withOpacity(0.1),
//                                     ],
//                                   ),
//                             borderRadius: BorderRadius.circular(8),
//                           ),
//                         ),
//                       ),
//                     ),
//                     // Contenido
//                     Container(
//                       height: 48,
//                       padding: const EdgeInsets.symmetric(horizontal: 12),
//                       child: Row(
//                         children: [
//                           if (isVoted)
//                             const Icon(
//                               Icons.check_circle,
//                               color: Colors.white,
//                               size: 18,
//                             ),
//                           if (isVoted) const SizedBox(width: 8),
//                           Expanded(
//                             child: Text(
//                               option.text,
//                               style: TextStyle(
//                                 color: Colors.white,
//                                 fontWeight: isVoted
//                                     ? FontWeight.bold
//                                     : FontWeight.normal,
//                               ),
//                             ),
//                           ),
//                           Text(
//                             '$percentage%',
//                             style: TextStyle(
//                               color: Colors.white,
//                               fontWeight: isVoted
//                                   ? FontWeight.bold
//                                   : FontWeight.normal,
//                             ),
//                           ),
//                         ],
//                       ),
//                     ),
//                   ],
//                 ),
//               ),
//             );
//           }).toList(),

//           // Footer
//           Padding(
//             padding: const EdgeInsets.all(16),
//             child: Row(
//               mainAxisAlignment: MainAxisAlignment.end,
//               children: [
//                 TextButton.icon(
//                   onPressed: () {
//                     Get.to(() => PollResultsScreen(pollId: poll.id));
//                   },
//                   icon: const Icon(
//                     Icons.bar_chart,
//                     size: 18,
//                     color: AppColors.primary,
//                   ),
//                   label: const Text(
//                     'Ver resultados',
//                     style: TextStyle(color: AppColors.primary),
//                   ),
//                 ),
//               ],
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   void _showClosePollDialog(Poll poll) {
//     Get.dialog(
//       AlertDialog(
//         backgroundColor: Colors.grey[900],
//         title: const Text(
//           'Cerrar Encuesta',
//           style: TextStyle(color: Colors.white),
//         ),
//         content: const Text(
//           '¿Estás seguro de que quieres cerrar esta encuesta? No se podrán registrar más votos.',
//           style: TextStyle(color: Colors.white70),
//         ),
//         actions: [
//           TextButton(
//             onPressed: () => Get.back(),
//             child: const Text('Cancelar'),
//           ),
//           ElevatedButton(
//             onPressed: () {
//               Get.back();
//               _chatController.closePoll(poll.id);
//             },
//             style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
//             child: const Text('Cerrar'),
//           ),
//         ],
//       ),
//     );
//   }

//   String _formatDate(DateTime date) {
//     final now = DateTime.now();
//     final difference = now.difference(date);

//     if (difference.inDays == 0) {
//       if (difference.inHours == 0) {
//         return 'Hace ${difference.inMinutes}m';
//       }
//       return 'Hace ${difference.inHours}h';
//     } else if (difference.inDays < 7) {
//       return 'Hace ${difference.inDays}d';
//     } else {
//       return '${date.day}/${date.month}/${date.year}';
//     }
//   }
// }
