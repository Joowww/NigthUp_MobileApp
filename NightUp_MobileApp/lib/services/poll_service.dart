import 'package:get/get.dart';
import '../services/api_service.dart';
import '../models/poll.dart';

class PollService extends GetxService {
  final ApiService _apiService = Get.find<ApiService>();
  Future<Poll> createPoll({
    required String question,
    required List<String> options,
    bool isPublic = true,
    List<String>? allowedVoters,
    DateTime? expiresAt,
  }) async {
    final response = await _apiService.post(
      '/poll',
      data: {
        'question': question,
        'options': options,
        'isPublic': isPublic,
        if (allowedVoters != null) 'allowedVoters': allowedVoters,
        if (expiresAt != null) 'expiresAt': expiresAt.toIso8601String(),
      },
    );

    return Poll.fromJson(response.data);
  }

  Future<List<Poll>> getActivePolls({
    int limit = 20,
    int skip = 0,
    String? createdBy,
  }) async {
    final response = await _apiService.get(
      '/poll',
      queryParameters: {
        'limit': limit,
        'skip': skip,
        if (createdBy != null) 'createdBy': createdBy,
      },
    );

    if (response.data is List) {
      return (response.data as List)
          .map((json) => Poll.fromJson(json))
          .toList();
    }

    return [];
  }

  Future<Poll> voteInPoll(String pollId, int optionIndex) async {
    final response = await _apiService.post(
      '/poll/$pollId/vote',
      data: {'optionIndex': optionIndex},
    );

    return Poll.fromJson(response.data);
  }

  Future<Poll> closePoll(String pollId) async {
    final response = await _apiService.patch('/poll/$pollId/close');
    return Poll.fromJson(response.data);
  }

  Future<PollResults> getPollResults(String pollId) async {
    final response = await _apiService.get('/poll/$pollId/results');
    return PollResults.fromJson(response.data);
  }
}
