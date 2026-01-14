class GroupPoll {
  final String id;
  final String question;
  final List<PollOption> options;
  final String creatorId;
  final bool isActive;
  final DateTime? expiresAt;
  final DateTime createdAt;

  GroupPoll({
    required this.id,
    required this.question,
    required this.options,
    required this.creatorId,
    this.isActive = true,
    this.expiresAt,
    required this.createdAt,
  });

  factory GroupPoll.fromJson(Map<String, dynamic> json) {
    return GroupPoll(
      id: json['_id']?.toString() ?? '',
      question: json['question'] ?? '',
      options:
          (json['options'] as List?)
              ?.map((o) => PollOption.fromJson(o))
              .toList() ??
          [],
      creatorId: json['creator']?.toString() ?? '',
      isActive: json['isActive'] ?? true,
      expiresAt: json['expiresAt'] != null
          ? DateTime.parse(json['expiresAt'])
          : null,
      createdAt: DateTime.parse(json['createdAt']),
    );
  }

  int get totalVotes {
    return options.fold<int>(0, (sum, option) => sum + option.voteCount);
  }

  bool hasUserVoted(String userId) {
    return options.any((option) => option.voters.contains(userId));
  }

  int? getUserVotedOptionIndex(String userId) {
    for (int i = 0; i < options.length; i++) {
      if (options[i].voters.contains(userId)) {
        return i;
      }
    }
    return null;
  }

  bool get isExpired {
    if (expiresAt == null) return false;
    return DateTime.now().isAfter(expiresAt!);
  }

  bool get canVote => isActive && !isExpired;
}

class PollOption {
  final String text;
  final List<String> voters;

  PollOption({required this.text, required this.voters});

  factory PollOption.fromJson(Map<String, dynamic> json) {
    return PollOption(
      text: json['text'] ?? '',
      voters:
          (json['voters'] as List?)?.map((v) {
            if (v is String) return v;
            if (v is Map) return v['_id']?.toString() ?? '';
            return v.toString();
          }).toList() ??
          [],
    );
  }

  int get voteCount => voters.length;

  double getPercentage(int totalVotes) {
    if (totalVotes == 0) return 0.0;
    return (voteCount / totalVotes * 100);
  }
}
