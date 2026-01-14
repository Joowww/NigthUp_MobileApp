import 'package:flutter/material.dart';
import 'package:dio/dio.dart' as dio;
import 'package:get/get.dart';
import '../models/post.dart';
import '../services/api_service.dart';
import '../theme/colors.dart';
import '../widgets/image_with_fallback.dart';

class CommentsBottomSheet extends StatefulWidget {
  final Post post;

  const CommentsBottomSheet({super.key, required this.post});

  @override
  State<CommentsBottomSheet> createState() => _CommentsBottomSheetState();
}

class _CommentsBottomSheetState extends State<CommentsBottomSheet> {
  final TextEditingController _commentController = TextEditingController();
  final ApiService _apiService = Get.find<ApiService>();
  List<dynamic> _comments = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchComments();
  }

  Future<void> _fetchComments() async {
    try {
      final response = await _apiService.get(
        '/post/${widget.post.id}/comments',
      );
      setState(() {
        _comments = response.data as List;
        _isLoading = false;
      });
    } catch (e) {
      print('Error fetching comments: $e');
      setState(() => _isLoading = false);
    }
  }

  Future<void> _postComment() async {
    if (_commentController.text.trim().isEmpty) return;

    final content = _commentController.text;
    try {
      _commentController.clear();

      await _apiService.post(
        '/post/${widget.post.id}/comment',
        data: {'text': content}, // Cambiado de 'content' a 'text'
      );

      _fetchComments(); // Refresh list
    } catch (e) {
      String errorMsg = 'No se pudo publicar el comentario';
      if (e is dio.DioException && e.response?.data != null) {
        final data = e.response?.data;
        if (data is Map) {
          errorMsg = data['message'] ?? data['error'] ?? errorMsg;
        }
      }
      Get.snackbar(
        'Error',
        errorMsg,
        backgroundColor: Colors.red.withOpacity(0.8),
        colorText: Colors.white,
      );
      _commentController.text = content; // Devolver el texto si falla
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.7,
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
      ),
      child: Column(
        children: [
          const SizedBox(height: 12),
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.white24,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            '${_comments.length} Comments',
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          const Divider(color: Colors.white10, height: 32),
          Expanded(
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(color: AppColors.primary),
                  )
                : _comments.isEmpty
                ? const Center(
                    child: Text(
                      'No comments yet. Be the first!',
                      style: TextStyle(color: Colors.white54),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: _comments.length,
                    itemBuilder: (context, index) {
                      final comment = _comments[index];
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 20),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            CircleAvatar(
                              radius: 16,
                              child: ClipOval(
                                child: ImageWithFallback(
                                  imageUrl: comment['user']?['avatar'],
                                  fallbackAsset:
                                      'assets/images/default-avatar.png',
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    comment['user']?['username'] ?? 'User',
                                    style: const TextStyle(
                                      color: Colors.white70,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 13,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    comment['text'] ?? comment['content'] ?? '',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 14,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
          ),
          _buildInputSection(),
        ],
      ),
    );
  }

  Widget _buildInputSection() {
    return Container(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 16,
        top: 16,
      ),
      decoration: const BoxDecoration(
        color: Colors.black,
        border: Border(top: BorderSide(color: Colors.white10)),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _commentController,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'Add a comment...',
                hintStyle: const TextStyle(color: Colors.white54),
                border: InputBorder.none,
                filled: true,
                fillColor: Colors.white10,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 10,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(20),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(20),
                  borderSide: const BorderSide(color: AppColors.primary),
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          IconButton(
            onPressed: _postComment,
            icon: const Icon(Icons.send, color: AppColors.primary),
          ),
        ],
      ),
    );
  }
}
