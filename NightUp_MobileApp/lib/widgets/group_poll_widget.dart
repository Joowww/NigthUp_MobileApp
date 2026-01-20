import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../models/group_poll.dart';
import '../theme/colors.dart';
import '../controllers/chat_controller.dart';

class GroupPollWidget extends StatelessWidget {
  final GroupPoll poll;
  final String currentUserId;

  const GroupPollWidget({
    Key? key,
    required this.poll,
    required this.currentUserId,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final hasVoted = poll.hasUserVoted(currentUserId);
    final userVotedIndex = poll.getUserVotedOptionIndex(currentUserId);
    final totalVotes = poll.totalVotes;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Colors.grey[850]!, Colors.grey[900]!],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.primary.withOpacity(0.3), width: 1),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.poll,
                  color: AppColors.primary,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'ENCUESTA',
                      style: TextStyle(
                        color: AppColors.primary,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1,
                      ),
                    ),
                    if (!poll.isActive || poll.isExpired)
                      Text(
                        poll.isExpired ? 'EXPIRADA' : 'CERRADA',
                        style: TextStyle(
                          color: Colors.grey[500],
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                  ],
                ),
              ),
              Text(
                '$totalVotes ${totalVotes == 1 ? 'voto' : 'votos'}',
                style: TextStyle(
                  color: Colors.grey[400],
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),
          Text(
            poll.question,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 16),

          ...poll.options.asMap().entries.map((entry) {
            final index = entry.key;
            final option = entry.value;
            final isSelected = userVotedIndex == index;
            final percentage = option.getPercentage(totalVotes);
            final canVote = poll.canVote && !hasVoted;

            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: GestureDetector(
                onTap: canVote
                    ? () => _voteInPoll(index)
                    : hasVoted
                    ? () => _showVoters(option)
                    : null,
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isSelected ? AppColors.primary : Colors.grey[700]!,
                      width: isSelected ? 2 : 1,
                    ),
                  ),
                  child: Stack(
                    children: [
                      if (hasVoted || !poll.canVote)
                        ClipRRect(
                          borderRadius: BorderRadius.circular(11),
                          child: LinearProgressIndicator(
                            value: percentage / 100,
                            minHeight: 48,
                            backgroundColor: Colors.transparent,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              isSelected
                                  ? AppColors.primary.withOpacity(0.3)
                                  : Colors.grey[800]!,
                            ),
                          ),
                        ),

                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        child: Row(
                          children: [
                            Icon(
                              isSelected
                                  ? Icons.check_circle
                                  : canVote
                                  ? Icons.radio_button_unchecked
                                  : Icons.circle_outlined,
                              color: isSelected
                                  ? AppColors.primary
                                  : Colors.grey[600],
                              size: 20,
                            ),
                            const SizedBox(width: 12),

                            Expanded(
                              child: Text(
                                option.text,
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 15,
                                  fontWeight: isSelected
                                      ? FontWeight.bold
                                      : FontWeight.normal,
                                ),
                              ),
                            ),

                            if (hasVoted || !poll.canVote) ...[
                              const SizedBox(width: 8),
                              Text(
                                '${percentage.toStringAsFixed(1)}%',
                                style: TextStyle(
                                  color: isSelected
                                      ? AppColors.primary
                                      : Colors.grey[400],
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }).toList(),

          if (poll.expiresAt != null)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Row(
                children: [
                  Icon(Icons.access_time, size: 14, color: Colors.grey[500]),
                  const SizedBox(width: 4),
                  Text(
                    poll.isExpired
                        ? 'Expiró el ${_formatDate(poll.expiresAt!)}'
                        : 'Expira el ${_formatDate(poll.expiresAt!)}',
                    style: TextStyle(color: Colors.grey[500], fontSize: 11),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  void _voteInPoll(int optionIndex) {
    final chatController = Get.find<ChatController>();
    chatController.voteInGroupPoll(poll.id, optionIndex);
  }

  void _showVoters(PollOption option) {
    if (option.voters.isEmpty) return;

    Get.dialog(
      Dialog(
        backgroundColor: Colors.grey[900],
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.how_to_vote, color: AppColors.primary, size: 24),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      option.text,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                '${option.voteCount} ${option.voteCount == 1 ? 'voto' : 'votos'}',
                style: TextStyle(color: Colors.grey[400], fontSize: 13),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey[800],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '${option.voters.length} persona${option.voters.length == 1 ? '' : 's'} votó por esta opción',
                  style: TextStyle(color: Colors.grey[400], fontSize: 13),
                ),
              ),
              const SizedBox(height: 16),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () => Get.back(),
                  child: const Text(
                    'Cerrar',
                    style: TextStyle(color: AppColors.primary),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays > 0) {
      return '${date.day}/${date.month}/${date.year}';
    } else if (difference.inHours > 0) {
      return 'en ${difference.inHours}h';
    } else if (difference.inMinutes > 0) {
      return 'en ${difference.inMinutes}min';
    } else {
      return 'ahora';
    }
  }
}
