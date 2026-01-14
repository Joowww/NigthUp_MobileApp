import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../models/message.dart';
import '../theme/colors.dart';
import '../widgets/image_with_fallback.dart';
import '../widgets/audio_message_bubble.dart';

class SwipeableMessageBubble extends StatefulWidget {
  final Message message;
  final bool isMe;
  final VoidCallback? onSwipeReply;
  final VoidCallback? onLongPress;

  const SwipeableMessageBubble({
    Key? key,
    required this.message,
    required this.isMe,
    this.onSwipeReply,
    this.onLongPress,
  }) : super(key: key);

  @override
  State<SwipeableMessageBubble> createState() => _SwipeableMessageBubbleState();
}

class _SwipeableMessageBubbleState extends State<SwipeableMessageBubble>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Offset> _slideAnimation;
  double _dragExtent = 0;
  bool _dragUnderway = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _slideAnimation = Tween<Offset>(
      begin: Offset.zero,
      end: const Offset(-0.2, 0),
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  // ==================== SWIPE GESTURE ====================

  void _handleDragStart(DragStartDetails details) {
    _dragUnderway = true;
  }

  void _handleDragUpdate(DragUpdateDetails details) {
    if (!_dragUnderway) return;

    final delta = details.primaryDelta ?? 0;
    _dragExtent += delta;

    if (_dragExtent < 0) {
      _dragExtent = 0;
    }

    final progress = (_dragExtent / 100).clamp(0.0, 1.0);
    _controller.value = progress;
  }

  void _handleDragEnd(DragEndDetails details) {
    if (!_dragUnderway) return;
    _dragUnderway = false;

    if (_dragExtent > 50 && widget.onSwipeReply != null) {
      widget.onSwipeReply!();
    }

    _controller.reverse();
    _dragExtent = 0;
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onHorizontalDragStart: _handleDragStart,
      onHorizontalDragUpdate: _handleDragUpdate,
      onHorizontalDragEnd: _handleDragEnd,
      onLongPress: widget.onLongPress,
      child: Stack(
        children: [
          // Icono de reply al hacer swipe
          Positioned(
            right: widget.isMe ? 20 : null,
            left: !widget.isMe ? 20 : null,
            top: 0,
            bottom: 0,
            child: AnimatedBuilder(
              animation: _controller,
              builder: (context, child) {
                return Opacity(
                  opacity: _controller.value,
                  child: const Icon(
                    Icons.reply,
                    color: AppColors.primary,
                    size: 24,
                  ),
                );
              },
            ),
          ),

          // Mensaje deslizable
          SlideTransition(
            position: _slideAnimation,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: Row(
                mainAxisAlignment: widget.isMe
                    ? MainAxisAlignment.end
                    : MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  // Avatar (solo si no es mensaje propio)
                  if (!widget.isMe) ...[
                    Container(
                      width: 32,
                      height: 32,
                      decoration: const BoxDecoration(shape: BoxShape.circle),
                      child: widget.message.sender.avatar != null
                          ? ImageWithFallback(
                              imageUrl: widget.message.sender.avatar!,
                              isCircle: true,
                              width: 32,
                              height: 32,
                              fit: BoxFit.cover,
                            )
                          : CircleAvatar(
                              radius: 16,
                              backgroundColor: AppColors.primary.withOpacity(
                                0.3,
                              ),
                              child: Text(
                                widget.message.sender.username[0].toUpperCase(),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                    ),
                    const SizedBox(width: 8),
                  ],

                  // Burbuja
                  Flexible(
                    child: Column(
                      crossAxisAlignment: widget.isMe
                          ? CrossAxisAlignment.end
                          : CrossAxisAlignment.start,
                      children: [
                        // Nombre del remitente
                        if (!widget.isMe)
                          Padding(
                            padding: const EdgeInsets.only(left: 12, bottom: 4),
                            child: Text(
                              widget.message.sender.username,
                              style: TextStyle(
                                color: Colors.grey[400],
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),

                        // Reply preview
                        if (widget.message.replyTo != null)
                          Container(
                            margin: const EdgeInsets.only(bottom: 4),
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: widget.isMe
                                  ? AppColors.primary.withOpacity(0.2)
                                  : Colors.grey[800],
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: AppColors.primary.withOpacity(0.5),
                                width: 2,
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  widget.message.replyTo!.sender.username,
                                  style: const TextStyle(
                                    color: AppColors.primary,
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  widget.message.replyTo!.displayText,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    color: Colors.grey[400],
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),

                        // Contenedor del mensaje
                        Container(
                          constraints: BoxConstraints(
                            maxWidth: MediaQuery.of(context).size.width * 0.7,
                          ),
                          decoration: BoxDecoration(
                            gradient: widget.isMe
                                ? LinearGradient(
                                    colors: [
                                      AppColors.primary,
                                      AppColors.primary.withOpacity(0.8),
                                    ],
                                  )
                                : LinearGradient(
                                    colors: [
                                      Colors.grey[800]!,
                                      Colors.grey[850]!,
                                    ],
                                  ),
                            borderRadius: BorderRadius.only(
                              topLeft: const Radius.circular(16),
                              topRight: const Radius.circular(16),
                              bottomLeft: Radius.circular(widget.isMe ? 16 : 4),
                              bottomRight: Radius.circular(
                                widget.isMe ? 4 : 16,
                              ),
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: widget.isMe
                                    ? AppColors.primary.withOpacity(0.3)
                                    : Colors.black.withOpacity(0.3),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(12),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Contenido del mensaje
                                if (widget.message.isDeleted)
                                  // Mensaje eliminado
                                  Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        Icons.block,
                                        size: 16,
                                        color: Colors.grey[400],
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        widget.message.text,
                                        style: TextStyle(
                                          color: Colors.grey[400],
                                          fontStyle: FontStyle.italic,
                                          fontSize: 14,
                                        ),
                                      ),
                                    ],
                                  )
                                else if (widget.message.isImage &&
                                    widget.message.imageUrl != null)
                                  // Mensaje con imagen
                                  Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      ClipRRect(
                                        borderRadius: BorderRadius.circular(8),
                                        child: GestureDetector(
                                          onTap: () => _showImageFullScreen(
                                            context,
                                            widget.message.imageUrl!,
                                          ),
                                          child: Image.network(
                                            widget.message.imageUrl!,
                                            fit: BoxFit.cover,
                                            loadingBuilder: (context, child, loadingProgress) {
                                              if (loadingProgress == null) {
                                                return child;
                                              }
                                              return Container(
                                                height: 200,
                                                alignment: Alignment.center,
                                                child: CircularProgressIndicator(
                                                  value:
                                                      loadingProgress
                                                              .expectedTotalBytes !=
                                                          null
                                                      ? loadingProgress
                                                                .cumulativeBytesLoaded /
                                                            loadingProgress
                                                                .expectedTotalBytes!
                                                      : null,
                                                  color: AppColors.primary,
                                                ),
                                              );
                                            },
                                            errorBuilder:
                                                (context, error, stackTrace) {
                                                  return Container(
                                                    height: 200,
                                                    alignment: Alignment.center,
                                                    child: Column(
                                                      mainAxisAlignment:
                                                          MainAxisAlignment
                                                              .center,
                                                      children: [
                                                        Icon(
                                                          Icons.broken_image,
                                                          size: 48,
                                                          color:
                                                              Colors.grey[600],
                                                        ),
                                                        const SizedBox(
                                                          height: 8,
                                                        ),
                                                        Text(
                                                          'Error al cargar imagen',
                                                          style: TextStyle(
                                                            color: Colors
                                                                .grey[600],
                                                            fontSize: 12,
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                  );
                                                },
                                          ),
                                        ),
                                      ),
                                      if (widget.message.text.isNotEmpty) ...[
                                        const SizedBox(height: 8),
                                        Text(
                                          widget.message.text,
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 15,
                                          ),
                                        ),
                                      ],
                                    ],
                                  )
                                else if (widget.message.isAudio)
                                  // Mensaje de audio
                                  AudioMessageBubble(
                                    audioUrl:
                                        widget.message.audioUrl ??
                                        widget.message.imageUrl ??
                                        '',
                                    isMe: widget.isMe,
                                  )
                                else
                                  // Mensaje de texto normal
                                  Text(
                                    widget.message.text,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 15,
                                    ),
                                  ),

                                const SizedBox(height: 4),

                                // Reacciones
                                if (widget.message.reactions.isNotEmpty)
                                  Padding(
                                    padding: const EdgeInsets.only(top: 4),
                                    child: Wrap(
                                      spacing: 4,
                                      runSpacing: 4,
                                      children: _buildReactionChips(
                                        widget.message.reactions,
                                      ),
                                    ),
                                  ),

                                // Metadata (hora, editado, estado)
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    if (widget.message.isEdited)
                                      Padding(
                                        padding: const EdgeInsets.only(
                                          right: 4,
                                        ),
                                        child: Text(
                                          'editado',
                                          style: TextStyle(
                                            color: Colors.white.withOpacity(
                                              0.6,
                                            ),
                                            fontSize: 10,
                                            fontStyle: FontStyle.italic,
                                          ),
                                        ),
                                      ),
                                    Text(
                                      _formatTime(widget.message.createdAt),
                                      style: TextStyle(
                                        color: Colors.white.withOpacity(0.6),
                                        fontSize: 11,
                                      ),
                                    ),
                                    if (widget.isMe) ...[
                                      const SizedBox(width: 4),
                                      _buildStatusIcon(widget.message.status),
                                    ],
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
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

  // ==================== HELPERS ====================

  List<Widget> _buildReactionChips(List<Reaction> reactions) {
    final reactionCounts = <String, int>{};
    for (final reaction in reactions) {
      reactionCounts[reaction.emoji] =
          (reactionCounts[reaction.emoji] ?? 0) + 1;
    }

    return reactionCounts.entries.map((entry) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.2),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(entry.key, style: const TextStyle(fontSize: 14)),
            if (entry.value > 1) ...[
              const SizedBox(width: 4),
              Text(
                entry.value.toString(),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ],
        ),
      );
    }).toList();
  }

  Widget _buildStatusIcon(MessageStatus status) {
    IconData icon;
    Color color;

    switch (status) {
      case MessageStatus.sending:
        icon = Icons.access_time;
        color = Colors.white.withOpacity(0.5);
        break;
      case MessageStatus.sent:
        icon = Icons.check;
        color = Colors.white.withOpacity(0.7);
        break;
      case MessageStatus.delivered:
        icon = Icons.done_all;
        color = Colors.white.withOpacity(0.7);
        break;
      case MessageStatus.read:
        icon = Icons.done_all;
        color = AppColors.primary;
        break;
      case MessageStatus.failed:
        icon = Icons.error_outline;
        color = AppColors.error;
        break;
    }

    return Icon(icon, size: 14, color: color);
  }

  String _formatTime(DateTime dateTime) {
    final hour = dateTime.hour.toString().padLeft(2, '0');
    final minute = dateTime.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  void _showImageFullScreen(BuildContext context, String imageUrl) {
    Get.dialog(
      Dialog(
        backgroundColor: Colors.transparent,
        child: Stack(
          children: [
            Center(
              child: InteractiveViewer(
                child: Image.network(imageUrl, fit: BoxFit.contain),
              ),
            ),
            Positioned(
              top: 40,
              right: 20,
              child: IconButton(
                icon: const Icon(Icons.close, color: Colors.white, size: 32),
                onPressed: () => Get.back(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
