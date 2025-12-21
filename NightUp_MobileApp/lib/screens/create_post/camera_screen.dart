import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:get/get.dart'; // Add Get import
import 'package:nightup_mobile_app/services/image_picker_service.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter/foundation.dart'; // For kIsWeb
import 'package:nightup_mobile_app/theme/colors.dart'; // Assuming AppColors exists

// Import EditPostScreen (will be created next)
import 'edit_post_screen.dart';

class CameraScreen extends StatefulWidget {
  const CameraScreen({super.key});

  @override
  State<CameraScreen> createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen>
    with WidgetsBindingObserver {
  CameraController? _controller;
  List<CameraDescription> _cameras = [];
  bool _isCameraInitialized = false;
  int _selectedCameraIndex = 0;

  // Filtros Básicos (ColorMatrix simulados con colores overlay)
  int _selectedFilterIndex = 0;
  final List<Map<String, dynamic>> _filters = [
    {'name': 'Normal', 'color': null},
    {'name': 'Vintage', 'color': Colors.amber.withOpacity(0.2)},
    {
      'name': 'B&W',
      'color': Colors.grey,
    }, // Requires ShaderMask for true B&W, using overlay for now
    {'name': 'Cold', 'color': Colors.blue.withOpacity(0.2)},
    {'name': 'Warm', 'color': Colors.orange.withOpacity(0.2)},
    {'name': 'Dark', 'color': Colors.black.withOpacity(0.3)},
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initCamera();
  }

  Future<void> _initCamera() async {
    try {
      _cameras = await availableCameras();
      if (_cameras.isNotEmpty) {
        await _initializeCameraController(_cameras[_selectedCameraIndex]);
      } else {
        Get.snackbar('Error', 'No cameras found');
      }
    } catch (e) {
      print('Error initializing camera: $e');
    }
  }

  Future<void> _initializeCameraController(
    CameraDescription cameraDescription,
  ) async {
    final controller = CameraController(
      cameraDescription,
      ResolutionPreset.high,
      enableAudio: true,
      imageFormatGroup: ImageFormatGroup.jpeg,
    );

    _controller = controller;

    try {
      await controller.initialize();
      if (mounted) {
        setState(() {
          _isCameraInitialized = true;
        });
      }
    } catch (e) {
      print('Camera initialization error: $e');
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _controller?.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Re-initialize camera on resume logic usually goes here
    if (_controller == null || !_controller!.value.isInitialized) {
      return;
    }
    if (state == AppLifecycleState.inactive) {
      _controller?.dispose();
    } else if (state == AppLifecycleState.resumed) {
      if (_controller != null) {
        _initializeCameraController(_controller!.description);
      }
    }
  }

  void _switchCamera() {
    if (_cameras.length <= 1) return;
    setState(() {
      _selectedCameraIndex = (_selectedCameraIndex + 1) % _cameras.length;
      _isCameraInitialized = false;
    });
    _initializeCameraController(_cameras[_selectedCameraIndex]);
  }

  bool _isRecording = false;

  Future<void> _startVideoRecording() async {
    if (!_isCameraInitialized || _controller == null || _isRecording) return;

    try {
      await _controller!.startVideoRecording();
      setState(() {
        _isRecording = true;
      });
    } catch (e) {
      print('Error starting video recording: $e');
    }
  }

  Future<void> _stopVideoRecording() async {
    if (!_isCameraInitialized || _controller == null || !_isRecording) return;

    try {
      final XFile videoFile = await _controller!.stopVideoRecording();
      setState(() {
        _isRecording = false;
      });
      Get.to(() => EditPostScreen(file: videoFile, isVideo: true));
    } catch (e) {
      print('Error stopping video recording: $e');
    }
  }

  Future<void> _takePicture() async {
    if (!_isCameraInitialized || _controller == null || _isRecording) return;
    if (_controller!.value.isTakingPicture) return;

    try {
      final XFile image = await _controller!.takePicture();
      Get.to(() => EditPostScreen(file: image, isVideo: false));
    } catch (e) {
      print('Error taking picture: $e');
    }
  }

  Future<void> _pickFromGallery() async {
    final image = await ImagePickerService.pickImage(
      source: ImageSource.gallery,
    );
    if (image != null) {
      Get.to(() => EditPostScreen(file: image, isVideo: false));
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_isCameraInitialized || _controller == null) {
      return const Scaffold(
        backgroundColor: Colors.black,
        body: Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // 1. Camera Preview
          _buildCameraPreview(),

          // 2. Filters Overlay (Visual only for preview)
          if (_filters[_selectedFilterIndex]['color'] != null)
            Container(
              color: _filters[_selectedFilterIndex]['color'],
              // Note: For true B&W you'd use a BackdropFilter with ColorFilter.matrix
              // This is a simplified "tint" filter for demonstration
            ),

          // 3. UI Controls
          SafeArea(
            child: Column(
              children: [
                // Top Bar
                _buildTopBar(),

                const Spacer(),

                // Right Sidebar (TikTok style)
                Align(
                  alignment: Alignment.centerRight,
                  child: _buildRightSidebar(),
                ),

                const Spacer(),

                // Bottom Controls
                _buildBottomControls(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCameraPreview() {
    return CameraPreview(_controller!);
  }

  Widget _buildTopBar() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: const Icon(Icons.close, color: Colors.white, size: 28),
            onPressed: () => Get.back(),
          ),

          // Music Selector
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.5),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Row(
              children: [
                Icon(Icons.music_note, color: Colors.white, size: 16),
                SizedBox(width: 8),
                Text(
                  'Add Sound',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(width: 28), // Spacer balance
        ],
      ),
    );
  }

  Widget _buildRightSidebar() {
    return Padding(
      padding: const EdgeInsets.only(right: 16.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildSideIcon(Icons.flip_camera_ios, 'Flip', onTap: _switchCamera),
          const SizedBox(height: 20),
          _buildSideIcon(
            Icons.flash_off,
            'Flash',
            onTap: () {},
          ), // Implement flash toggle
          const SizedBox(height: 20),
          _buildSideIcon(
            Icons.filter_hdr,
            'Filters',
            onTap: () {},
          ), // Could toggle filter menu visibility
          const SizedBox(height: 20),
          _buildSideIcon(Icons.timer, 'Timer', onTap: () {}),
          const SizedBox(height: 20),
          _buildSideIcon(Icons.speed, 'Speed', onTap: () {}),
        ],
      ),
    );
  }

  Widget _buildSideIcon(
    IconData icon,
    String label, {
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Icon(icon, color: Colors.white, size: 28),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(color: Colors.white, fontSize: 10),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomControls() {
    return Column(
      children: [
        // Filter Selector Horizontal List
        SizedBox(
          height: 60,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: _filters.length,
            itemBuilder: (context, index) {
              final isSelected = _selectedFilterIndex == index;
              return GestureDetector(
                onTap: () {
                  setState(() {
                    _selectedFilterIndex = index;
                  });
                },
                child: Container(
                  margin: const EdgeInsets.only(right: 16),
                  child: Column(
                    children: [
                      CircleAvatar(
                        radius: 20,
                        backgroundColor: isSelected
                            ? AppColors.primary
                            : Colors.white.withOpacity(0.2),
                        child: CircleAvatar(
                          radius: 18,
                          backgroundColor:
                              _filters[index]['color'] ?? Colors.grey[800],
                          child: _filters[index]['color'] == null
                              ? const Icon(
                                  Icons.block,
                                  size: 16,
                                  color: Colors.white,
                                )
                              : null,
                        ),
                      ),
                      if (isSelected)
                        Text(
                          _filters[index]['name'],
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                          ),
                        ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),

        const SizedBox(height: 20),

        // Shutter & Gallery Row
        Padding(
          padding: const EdgeInsets.only(bottom: 40, left: 30, right: 30),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Gallery Button
              GestureDetector(
                onTap: _pickFromGallery,
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.white, width: 2),
                  ),
                  child: const Icon(
                    Icons.photo_library,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
              ),

              // Shutter Button
              GestureDetector(
                onTap: _takePicture,
                onLongPressStart: (_) => _startVideoRecording(),
                onLongPressEnd: (_) => _stopVideoRecording(),
                child: Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: _isRecording ? Colors.red : Colors.white,
                      width: 4,
                    ),
                    color: Colors.transparent,
                  ),
                  child: Container(
                    margin: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: _isRecording ? Colors.red : AppColors.primary,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
              ),

              // Spacer / Switch Mode (Optional)
              const SizedBox(width: 40), // Placeholder for balance
            ],
          ),
        ),

        // Mode Selector (Photo / Video text)
        Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildModeText('Camera', true),
              const SizedBox(width: 20),
              _buildModeText('Video', false),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildModeText(String text, bool isSelected) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: isSelected
          ? BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(20),
            )
          : null,
      child: Text(
        text,
        style: TextStyle(
          color: isSelected ? Colors.white : Colors.white60,
          fontWeight: FontWeight.w600,
          fontSize: 14,
        ),
      ),
    );
  }
}
