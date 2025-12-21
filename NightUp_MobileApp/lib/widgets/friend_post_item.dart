import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:visibility_detector/visibility_detector.dart';
import '../models/post.dart';
import '../widgets/image_with_fallback.dart';
import '../widgets/comments_bottom_sheet.dart';
import '../theme/colors.dart';

class FriendPostItem extends StatefulWidget {
  final Post post;
  final VoidCallback? onLike;
  final VoidCallback? onComment;

  const FriendPostItem({
    super.key,
    required this.post,
    this.onLike,
    this.onComment,
  });

  @override
  State<FriendPostItem> createState() => _FriendPostItemState();
}

class _FriendPostItemState extends State<FriendPostItem>
    with SingleTickerProviderStateMixin {
  VideoPlayerController? _videoController;
  bool _isInitialized = false;
  late AnimationController _musicDiscController;

  @override
  void initState() {
    super.initState();
    _musicDiscController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    );

    if (widget.post.isVideo && widget.post.mediaUrl != null) {
      _initVideo();
    }
  }

  void _initVideo() {
    _videoController =
        VideoPlayerController.networkUrl(Uri.parse(widget.post.safeMediaUrl))
          ..initialize().then((_) {
            setState(() {
              _isInitialized = true;
            });
            _videoController?.setLooping(true);
          });
  }

  @override
  void dispose() {
    _videoController?.dispose();
    _musicDiscController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return VisibilityDetector(
      key: Key('post-${widget.post.id}'),
      onVisibilityChanged: (info) {
        if (info.visibleFraction > 0.8) {
          _videoController?.play();
          _musicDiscController.repeat();
        } else {
          _videoController?.pause();
          _musicDiscController.stop();
        }
      },
      child: Container(
        height: MediaQuery.of(context).size.height - 150, // Ajustat per barres
        width: double.infinity,
        color: Colors.black,
        child: Stack(
          children: [
            // 1. Multimedia (Vídeo o Foto)
            _buildMedia(),

            // 2. Gradient inferior per llegibilitat
            _buildGradient(),

            // 3. Informació l'usuari i la música (Esquerra inferior)
            _buildLeftOverlay(),

            // 4. Botons d'acció (Dreta inferior)
            _buildRightOverlay(),
          ],
        ),
      ),
    );
  }

  Widget _buildMedia() {
    if (widget.post.isVideo) {
      return Center(
        child: _isInitialized
            ? AspectRatio(
                aspectRatio: _videoController!.value.aspectRatio,
                child: VideoPlayer(_videoController!),
              )
            : const CircularProgressIndicator(color: AppColors.primary),
      );
    } else {
      return ImageWithFallback(
        imageUrl: widget.post.safeMediaUrl,
        fallbackAsset: 'assets/images/default-event.jpg',
        fit: BoxFit.cover,
        width: double.infinity,
        height: double.infinity,
      );
    }
  }

  Widget _buildGradient() {
    return Positioned.fill(
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.black.withOpacity(0.3),
              Colors.transparent,
              Colors.transparent,
              Colors.black.withOpacity(0.8),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLeftOverlay() {
    return Positioned(
      left: 16,
      bottom: 20,
      right: 80,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 18,
                backgroundColor: AppColors.primary,
                child: ClipOval(
                  child: ImageWithFallback(
                    imageUrl: widget.post.user?.safeProfilePictureUrl,
                    fallbackAsset: 'assets/images/default-avatar.png',
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Text(
                '@${widget.post.user?.username ?? 'user'}',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            widget.post.caption ?? '',
            style: const TextStyle(color: Colors.white, fontSize: 14),
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 8),
          if (widget.post.location != null)
            Row(
              children: [
                const Icon(Icons.location_on, color: Colors.white70, size: 14),
                const SizedBox(width: 4),
                Text(
                  widget.post.location!,
                  style: const TextStyle(color: Colors.white70, fontSize: 12),
                ),
              ],
            ),
          const SizedBox(height: 12),
          if (widget.post.music != null)
            Row(
              children: [
                const Icon(Icons.music_note, color: Colors.white, size: 14),
                const SizedBox(width: 6),
                Expanded(
                  child: SizedBox(
                    height: 20,
                    child: Text(
                      '${widget.post.music!['title']} - ${widget.post.music!['artist']}',
                      style: const TextStyle(color: Colors.white, fontSize: 13),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildRightOverlay() {
    return Positioned(
      right: 16,
      bottom: 20,
      child: Column(
        children: [
          _ActionButton(
            icon: widget.post.isLiked ? Icons.favorite : Icons.favorite_border,
            label: '${widget.post.likes}',
            onTap: widget.onLike,
            color: widget.post.isLiked ? Colors.red : Colors.white,
          ),
          const SizedBox(height: 20),
          _ActionButton(
            icon: Icons.chat_bubble,
            label: '${widget.post.comments}',
            onTap: () {
              showModalBottomSheet(
                context: context,
                isScrollControlled: true,
                backgroundColor: Colors.transparent,
                builder: (context) => CommentsBottomSheet(post: widget.post),
              );
            },
          ),
          const SizedBox(height: 20),
          _ActionButton(icon: Icons.share, label: 'Share', onTap: () {}),
          const SizedBox(height: 30),
          // El Disc de Música que gira
          RotationTransition(
            turns: _musicDiscController,
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: SweepGradient(
                  colors: [Colors.grey[800]!, Colors.black, Colors.grey[800]!],
                ),
              ),
              child: ClipOval(
                child: ImageWithFallback(
                  imageUrl: widget.post.music?['cover'],
                  fallbackAsset: 'assets/images/default-event.jpg',
                  width: 30,
                  height: 30,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback? onTap;
  final Color color;

  const _ActionButton({
    required this.icon,
    required this.label,
    this.onTap,
    this.color = Colors.white,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Icon(icon, color: color, size: 35),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(color: Colors.white, fontSize: 12),
          ),
        ],
      ),
    );
  }
}
