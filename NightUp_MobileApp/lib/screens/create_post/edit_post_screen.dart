import 'dart:io';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:get/get.dart';
import 'package:flutter/foundation.dart'; // Per kIsWeb
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:nightup_mobile_app/services/music_service.dart';
import 'package:nightup_mobile_app/services/api_service.dart';
import 'package:nightup_mobile_app/theme/colors.dart';
import 'package:video_player/video_player.dart';
import 'package:just_audio/just_audio.dart';
import '../../app.dart';

class EditPostScreen extends StatefulWidget {
  final XFile file;
  final bool isVideo;

  const EditPostScreen({super.key, required this.file, required this.isVideo});

  @override
  State<EditPostScreen> createState() => _EditPostScreenState();
}

class _EditPostScreenState extends State<EditPostScreen>
    with TickerProviderStateMixin {
  final TextEditingController _captionController = TextEditingController();
  final TextEditingController _locationController = TextEditingController();
  bool _isUploading = false;
  Map<String, String>? _selectedMusic;
  double _musicStartTime = 0.0;
  VideoPlayerController? _videoController;
  final AudioPlayer _audioPlayer = AudioPlayer();
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat(reverse: true);
    _loadInitialLocation();
    if (widget.isVideo) {
      _initVideoPlayer();
    }
  }

  void _initVideoPlayer() {
    if (kIsWeb) {
      _videoController = VideoPlayerController.networkUrl(
        Uri.parse(widget.file.path),
      );
    } else {
      _videoController = VideoPlayerController.file(File(widget.file.path));
    }
    _videoController?.initialize().then((_) {
      setState(() {});
      _videoController?.play();
      _videoController?.setLooping(true);
    });
  }

  @override
  void dispose() {
    _videoController?.dispose();
    _audioPlayer.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  void _playMusicPreview(String? url, double start) async {
    if (url == null) return;
    try {
      if (_audioPlayer.audioSource == null ||
          _audioPlayer.audioSource!.toString() != url) {
        await _audioPlayer.setUrl(url);
      }
      await _audioPlayer.seek(Duration(milliseconds: (start * 1000).toInt()));
      _audioPlayer.play();

      // Aturar després de 15 segons (estil clip)
      Future.delayed(const Duration(seconds: 15), () {
        if (mounted && _audioPlayer.playing) {
          _audioPlayer.pause();
        }
      });
    } catch (e) {
      print('Error playing music: $e');
    }
  }

  Future<void> _loadInitialLocation() async {
    try {
      final position = await Geolocator.getCurrentPosition();
      final response = await http.get(
        Uri.parse(
          'https://nominatim.openstreetmap.org/reverse?format=json&lat=${position.latitude}&lon=${position.longitude}',
        ),
      );
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final city =
            data['address']['city'] ??
            data['address']['town'] ??
            data['address']['village'] ??
            'Barcelona'; // Per defecte si no troba
        setState(() {
          _locationController.text = city;
        });
      }
    } catch (e) {
      print('Error getting location: $e');
      setState(() {
        _locationController.text = 'Barcelona';
      });
    }
  }

  void _showMusicPicker() {
    Map<String, String>? tempSelected;
    bool pickingClip = false;

    Get.bottomSheet(
      StatefulBuilder(
        builder: (context, setModalState) {
          return Container(
            height: MediaQuery.of(context).size.height * 0.7,
            decoration: const BoxDecoration(
              color: Colors.black,
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: pickingClip
                ? _buildClipSelector(tempSelected!, setModalState)
                : _buildSongList(setModalState, (item) {
                    setModalState(() {
                      tempSelected = item;
                      pickingClip = true;
                    });
                    _playMusicPreview(item['preview'], 0.0);
                  }),
          );
        },
      ),
      isScrollControlled: true,
    ).then((_) => _audioPlayer.stop());
  }

  Widget _buildSongList(
    StateSetter setModalState,
    Function(Map<String, String>) onSelect,
  ) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: TextField(
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              hintText: 'Search songs...',
              hintStyle: const TextStyle(color: Colors.white54),
              prefixIcon: const Icon(Icons.search, color: Colors.white),
              filled: true,
              fillColor: Colors.white10,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            onChanged: (val) => setModalState(() {}),
          ),
        ),
        Expanded(
          child: FutureBuilder<List<Map<String, String>>>(
            future: MusicService.searchMusic('top hits'),
            builder: (context, snapshot) {
              if (!snapshot.hasData)
                return const Center(
                  child: CircularProgressIndicator(color: AppColors.primary),
                );
              return ListView.builder(
                itemCount: snapshot.data!.length,
                itemBuilder: (context, index) {
                  final item = snapshot.data![index];
                  return ListTile(
                    leading: ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: Image.network(
                        item['cover']!,
                        width: 40,
                        height: 40,
                      ),
                    ),
                    title: Text(
                      item['title']!,
                      style: const TextStyle(color: Colors.white),
                    ),
                    subtitle: Text(
                      item['artist']!,
                      style: const TextStyle(color: Colors.white54),
                    ),
                    onTap: () => onSelect(item),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildClipSelector(
    Map<String, String> song,
    StateSetter setModalState,
  ) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // 1. Portada amb Animació de Pols
          ScaleTransition(
            scale: Tween(begin: 1.0, end: 1.05).animate(
              CurvedAnimation(
                parent: _pulseController,
                curve: Curves.easeInOut,
              ),
            ),
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withOpacity(0.3),
                    blurRadius: 20,
                    spreadRadius: 5,
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.network(song['cover']!, width: 180, height: 180),
              ),
            ),
          ),
          const SizedBox(height: 30),
          Text(
            song['title']!,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          Text(
            song['artist']!,
            style: const TextStyle(color: Colors.white70, fontSize: 16),
          ),

          const SizedBox(height: 40),

          // 2. Visualitzador de barres animades
          const _MusicVisualizer(),

          const SizedBox(height: 10),
          const Text(
            'Select 15s clip',
            style: TextStyle(
              color: AppColors.primary,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),

          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              activeTrackColor: AppColors.primary,
              inactiveTrackColor: Colors.white10,
              thumbColor: Colors.white,
              overlayColor: AppColors.primary.withOpacity(0.2),
              trackHeight: 4,
            ),
            child: Slider(
              value: _musicStartTime,
              min: 0.0,
              max: 15.0,
              onChanged: (val) {
                setModalState(() => _musicStartTime = val);
                setState(() => _musicStartTime = val);
              },
              onChangeEnd: (val) {
                _playMusicPreview(song['preview'], val);
              },
            ),
          ),
          Text(
            '${_musicStartTime.toStringAsFixed(1)}s ——— ${(0.0 + 15).toStringAsFixed(1)}s clip',
            style: const TextStyle(color: Colors.white38, fontSize: 11),
          ),
          const Spacer(),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              minimumSize: const Size(double.infinity, 54),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15),
              ),
              elevation: 0,
            ),
            onPressed: () {
              setState(() => _selectedMusic = song);
              Get.back();
            },
            child: const Text(
              'Confirm music',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Get.back(),
        ),
        title: const Text(
          'New Post',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        actions: [
          TextButton(
            onPressed: _isUploading ? null : _handleUpload,
            child: Text(
              'Share',
              style: TextStyle(
                color: AppColors.primary,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // 1. Media Preview
            _buildMediaPreview(),

            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  // 2. Caption Input
                  TextField(
                    controller: _captionController,
                    maxLines: 4,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      hintText: 'Write a caption...',
                      hintStyle: TextStyle(
                        color: Colors.white.withOpacity(0.5),
                      ),
                      border: InputBorder.none,
                    ),
                  ),
                  const Divider(color: Colors.white24),

                  // 3. Location Selector
                  _buildListTile(
                    icon: Icons.location_on,
                    title: 'Add Location',
                    controller: _locationController,
                  ),

                  // 4. Music Selector
                  _buildListTile(
                    icon: Icons.music_note,
                    title: _selectedMusic != null
                        ? _selectedMusic!['title']!
                        : 'Add Music',
                    subtitle: _selectedMusic != null
                        ? _selectedMusic!['artist']
                        : 'Choose a background track',
                    onTap: _showMusicPicker,
                  ),

                  const SizedBox(height: 30),

                  if (_isUploading)
                    const CircularProgressIndicator(color: AppColors.primary),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMediaPreview() {
    return Container(
      width: double.infinity,
      height: MediaQuery.of(context).size.width,
      color: Colors.grey[900],
      child: widget.isVideo
          ? (_videoController != null && _videoController!.value.isInitialized
                ? AspectRatio(
                    aspectRatio: _videoController!.value.aspectRatio,
                    child: VideoPlayer(_videoController!),
                  )
                : const Center(child: CircularProgressIndicator()))
          : (kIsWeb
                ? Image.network(widget.file.path, fit: BoxFit.cover)
                : Image.file(File(widget.file.path), fit: BoxFit.cover)),
    );
  }

  Widget _buildListTile({
    required IconData icon,
    required String title,
    String? subtitle,
    TextEditingController? controller,
    VoidCallback? onTap,
  }) {
    return Column(
      children: [
        ListTile(
          leading: Icon(icon, color: Colors.white),
          title: controller != null
              ? TextField(
                  controller: controller,
                  style: const TextStyle(color: Colors.white, fontSize: 16),
                  decoration: InputDecoration(
                    hintText: title,
                    hintStyle: TextStyle(color: Colors.white.withOpacity(0.5)),
                    border: InputBorder.none,
                  ),
                )
              : Text(title, style: const TextStyle(color: Colors.white)),
          subtitle: subtitle != null
              ? Text(
                  subtitle,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.5),
                    fontSize: 12,
                  ),
                )
              : null,
          trailing: const Icon(Icons.chevron_right, color: Colors.white24),
          onTap: onTap,
        ),
        const Divider(color: Colors.white24),
      ],
    );
  }

  Future<void> _handleUpload() async {
    if (_isUploading) return;

    setState(() => _isUploading = true);

    try {
      final apiService = Get.find<ApiService>();

      // 1. Subir a Cloudinary primero
      final String? mediaUrl = await apiService.uploadToCloudinary(
        widget.file,
        'posts',
      );

      if (mediaUrl == null) {
        throw Exception('No se pudo obtener la URL de Cloudinary');
      }

      // 2. Preparar los datos finales del post con la URL
      final Map<String, dynamic> postData = {
        'caption': _captionController.text,
        'location': _locationController.text,
        'isVideo': widget.isVideo,
        'mediaUrl': mediaUrl, // Enviamos el string obtenido
      };

      if (_selectedMusic != null) {
        postData['musicTitle'] = _selectedMusic!['title'];
        postData['musicArtist'] = _selectedMusic!['artist'];
        postData['musicCover'] = _selectedMusic!['cover'];
      }

      // 3. Crear el post en el backend con un POST normal (JSON)
      await apiService.post('/posts/create', data: postData);

      setState(() => _isUploading = false);
      Get.offAll(() => const App());
      Get.snackbar(
        '¡Genial!',
        'Tu post se ha compartido correctamente',
        backgroundColor: Colors.green,
        colorText: Colors.white,
        snackPosition: SnackPosition.BOTTOM,
      ).show();
    } catch (e) {
      print('Error uploading post: $e');
      setState(() => _isUploading = false);
      Get.snackbar(
        'Error',
        'No pudimos subir tu post: $e',
        backgroundColor: Colors.red,
        colorText: Colors.white,
        snackPosition: SnackPosition.BOTTOM,
      ).show();
    }
  }
}

class _MusicVisualizer extends StatefulWidget {
  const _MusicVisualizer();

  @override
  State<_MusicVisualizer> createState() => _MusicVisualizerState();
}

class _MusicVisualizerState extends State<_MusicVisualizer>
    with SingleTickerProviderStateMixin {
  final List<int> _durations = [900, 700, 600, 800, 500, 900, 700, 600];

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 40,
      width: 100,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: List.generate(8, (index) {
          return _VisualizerBar(
            duration: _durations[index],
            color: AppColors.primary,
          );
        }),
      ),
    );
  }
}

class _VisualizerBar extends StatefulWidget {
  final int duration;
  final Color color;

  const _VisualizerBar({required this.duration, required this.color});

  @override
  State<_VisualizerBar> createState() => _VisualizerBarState();
}

class _VisualizerBarState extends State<_VisualizerBar>
    with SingleTickerProviderStateMixin {
  late Animation<double> _animation;
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: Duration(milliseconds: widget.duration),
      vsync: this,
    );
    _animation = Tween<double>(
      begin: 5,
      end: 35,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
    _controller.repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Container(
          width: 4,
          height: _animation.value,
          decoration: BoxDecoration(
            color: widget.color,
            borderRadius: BorderRadius.circular(2),
          ),
        );
      },
    );
  }
}
