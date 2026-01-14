class Poll {
  final String id;
  final PollCreator creator;
  final String question;
  final List<PollOption> options;
  final bool isActive;
  final bool isPublic;
  final List<String> allowedVoters;
  final DateTime? expiresAt;
  final DateTime createdAt;
  final DateTime updatedAt;

  Poll({
    required this.id,
    required this.creator,
    required this.question,
    required this.options,
    required this.isActive,
    required this.isPublic,
    this.allowedVoters = const [],
    this.expiresAt,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Poll.fromJson(Map<String, dynamic> json) {
    return Poll(
      id: json['_id'] ?? '',
      creator: PollCreator.fromJson(json['creator'] ?? {}),
      question: json['question'] ?? '',
      options:
          (json['options'] as List?)
              ?.map((o) => PollOption.fromJson(o))
              .toList() ??
          [],
      isActive: json['isActive'] ?? true,
      isPublic: json['isPublic'] ?? true,
      allowedVoters:
          (json['allowedVoters'] as List?)?.map((v) => v.toString()).toList() ??
          [],
      expiresAt: json['expiresAt'] != null
          ? DateTime.parse(json['expiresAt'])
          : null,
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt: DateTime.parse(json['updatedAt']),
    );
  }

  int get totalVotes {
    return options.fold<int>(0, (sum, option) => sum + option.voteCount);
  }

  bool hasUserVoted(String userId) {
    return options.any((option) => option.voters.contains(userId));
  }

  bool get isExpired {
    if (expiresAt == null) return false;
    return DateTime.now().isAfter(expiresAt!);
  }

  bool get canVote {
    return isActive && !isExpired;
  }
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
}

class PollCreator {
  final String id;
  final String username;
  final String? email;
  final String? avatar;

  PollCreator({
    required this.id,
    required this.username,
    this.email,
    this.avatar,
  });

  factory PollCreator.fromJson(Map<String, dynamic> json) {
    return PollCreator(
      id: json['_id'] ?? json['id'] ?? '',
      username: json['username'] ?? 'Usuario',
      email: json['email'],
      avatar: json['avatar'],
    );
  }
}

class PollResults {
  final String question;
  final int totalVotes;
  final List<PollResultOption> results;
  final bool isActive;

  PollResults({
    required this.question,
    required this.totalVotes,
    required this.results,
    required this.isActive,
  });

  factory PollResults.fromJson(Map<String, dynamic> json) {
    return PollResults(
      question: json['question'] ?? '',
      totalVotes: json['totalVotes'] ?? 0,
      results:
          (json['results'] as List?)
              ?.map((r) => PollResultOption.fromJson(r))
              .toList() ??
          [],
      isActive: json['isActive'] ?? true,
    );
  }
}

class PollResultOption {
  final String text;
  final int votes;
  final double percentage;
  final List<dynamic> voters;

  PollResultOption({
    required this.text,
    required this.votes,
    required this.percentage,
    required this.voters,
  });

  factory PollResultOption.fromJson(Map<String, dynamic> json) {
    return PollResultOption(
      text: json['text'] ?? '',
      votes: json['votes'] ?? 0,
      percentage: (json['percentage'] ?? 0).toDouble(),
      voters: json['voters'] ?? [],
    );
  }
}
