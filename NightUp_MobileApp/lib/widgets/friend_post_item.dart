import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:video_player/video_player.dart';
import 'package:just_audio/just_audio.dart';
import 'package:visibility_detector/visibility_detector.dart';
import '../models/post.dart';
import '../widgets/image_with_fallback.dart';
import '../widgets/comments_bottom_sheet.dart';
import '../theme/colors.dart';
import 'package:get/get.dart';
import '../controllers/home_feed_controller.dart';

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
  final AudioPlayer _musicPlayer = AudioPlayer();
  final FocusNode _focusNode = FocusNode();
  bool _isInitialized = false;
  bool _isMuted = false;
  bool _isPlaying = true;
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
    if (widget.post.music != null) {
      _initMusic();
    }
  }

  void _initMusic() async {
    final previewUrl = widget.post.music?['prevista'];
    if (previewUrl != null && previewUrl.isNotEmpty) {
      try {
        await _musicPlayer.setUrl(previewUrl);
        await _musicPlayer.setLoopMode(LoopMode.one);

        final startTime = widget.post.music?['inicio'];
        if (startTime != null) {
          final startMs = (double.tryParse(startTime.toString()) ?? 0.0) * 1000;
          await _musicPlayer.seek(Duration(milliseconds: startMs.toInt()));
        }
      } catch (e) {
        //nothing
      }
    } else {
      //nothing
    }
  }

  void _initVideo() {
    _videoController =
        VideoPlayerController.networkUrl(Uri.parse(widget.post.safeMediaUrl))
          ..initialize()
              .then((_) {
                if (!mounted) return;
                setState(() {
                  _isInitialized = true;
                });
                _videoController?.setLooping(true);

                if (widget.post.music != null) {
                  _videoController?.setVolume(0);
                }

                if (_isPlaying && (_isPlayingPage)) {
                  _videoController?.play();
                }
              })
              .catchError((error) {
                if (mounted) {
                  setState(() {
                    _isInitialized = false;
                  });
                }
              });
  }

  bool _isPlayingPage = false;

  @override
  void dispose() {
    _videoController?.dispose();
    _musicPlayer.dispose();
    _musicDiscController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _togglePlayPause() {
    setState(() {
      _isPlaying = !_isPlaying;

      if (_isPlaying) {
        _videoController?.play();
        if (widget.post.music != null) {
          _musicPlayer.play();
        }
        _musicDiscController.repeat();
      } else {
        _videoController?.pause();
        _musicPlayer.pause();
        _musicDiscController.stop();
      }
    });
  }

  void _toggleMute() {
    setState(() {
      _isMuted = !_isMuted;
      final volume = _isMuted ? 0.0 : 1.0;

      _videoController?.setVolume(volume);
      if (widget.post.music != null) {
        _musicPlayer.setVolume(volume);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return VisibilityDetector(
      key: Key('post-${widget.post.id}'),
      onVisibilityChanged: (info) {
        if (!mounted) return;
        if (info.visibleFraction > 0.8) {
          _isPlayingPage = true;
          if (_isPlaying) {
            _videoController?.play();
            if (widget.post.music != null) {
              _musicPlayer.play();
            }
            _musicDiscController.repeat();
          }
          FocusScope.of(context).requestFocus(_focusNode);
        } else {
          _isPlayingPage = false;
          _videoController?.pause();
          _musicPlayer.pause();
          _musicDiscController.stop();
        }
      },
      child: Focus(
        focusNode: _focusNode,
        autofocus: true,
        onKeyEvent: (node, event) {
          if (event.logicalKey == LogicalKeyboardKey.space &&
              event is KeyDownEvent) {
            _togglePlayPause();
            return KeyEventResult.handled;
          }
          return KeyEventResult.ignored;
        },
        child: Container(
          height: MediaQuery.of(context).size.height - 150,
          width: double.infinity,
          color: Colors.black,
          child: Stack(
            children: [
              _buildMedia(),

              if (widget.post.filterColor != null)
                Positioned.fill(
                  child: IgnorePointer(
                    child: Container(
                      color: _hexToColor(widget.post.filterColor!),
                    ),
                  ),
                ),

              _buildGradient(),
              _buildLeftOverlay(),
              _buildRightOverlay(),
            ],
          ),
        ),
      ),
    );
  }

  Color _hexToColor(String hex) {
    try {
      return Color(int.parse(hex.replaceFirst('#', ''), radix: 16));
    } catch (e) {
      return Colors.transparent;
    }
  }

  Widget _buildMedia() {
    return GestureDetector(
      onTap: _togglePlayPause,
      child: Stack(
        alignment: Alignment.center,
        children: [
          _buildPrimaryMedia(),
          if (!_isPlaying)
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.black45,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white24, width: 2),
              ),
              child: const Icon(
                Icons.play_arrow_rounded,
                color: Colors.white,
                size: 80,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildPrimaryMedia() {
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
                '@${widget.post.user?.username ?? 'usuario'}',
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
                      '${widget.post.music?['titulo'] ?? 'Desconocido'} - ${widget.post.music?['artista'] ?? 'Desconocido'}',
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
          _ActionButton(
            icon: Icons.share,
            label: 'Compartir',
            onTap: () {
              Get.find<HomeFeedController>().sharePost(widget.post);
            },
          ),
          IconButton(
            onPressed: _toggleMute,
            icon: Icon(
              _isMuted ? Icons.volume_off : Icons.volume_up,
              color: Colors.white,
              size: 28,
            ),
          ),
          const SizedBox(height: 20),
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
