import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:get/get.dart';
import '../theme/colors.dart';

class WebCameraDialog extends StatefulWidget {
  const WebCameraDialog({super.key});

  @override
  State<WebCameraDialog> createState() => _WebCameraDialogState();
}

class _WebCameraDialogState extends State<WebCameraDialog> {
  CameraController? _controller;
  List<CameraDescription> _cameras = [];
  bool _isInit = false;
  int _selectedCameraIndex = 0;

  @override
  void initState() {
    super.initState();
    _initCameras();
  }

  Future<void> _initCameras() async {
    try {
      _cameras = await availableCameras();
      if (_cameras.isNotEmpty) {
        _initController(_cameras[_selectedCameraIndex]);
      } else {
        Get.snackbar('Error', 'No se encontraron cámaras');
      }
    } catch (e) {
      debugPrint('Error inicializando cámaras: $e');
    }
  }

  Future<void> _initController(CameraDescription camera) async {
    if (_controller != null) {
      await _controller!.dispose();
    }

    _controller = CameraController(
      camera,
      ResolutionPreset.medium,
      enableAudio: false,
    );

    try {
      await _controller!.initialize();
      if (mounted) setState(() => _isInit = true);
    } catch (e) {
      debugPrint('Error inicializando controller: $e');
    }
  }

  void _switchCamera() {
    if (_cameras.length < 2) return;
    _selectedCameraIndex = (_selectedCameraIndex + 1) % _cameras.length;
    _isInit = false;
    _initController(_cameras[_selectedCameraIndex]);
  }

  Future<void> _takePicture() async {
    if (_controller == null || !_controller!.value.isInitialized) return;

    try {
      final XFile image = await _controller!.takePicture();
      Get.back(result: image);
    } catch (e) {
      Get.snackbar('Error', 'No se pudo capturar la imagen');
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 40),
      child: Container(
        width: 400,
        height: 600,
        decoration: BoxDecoration(
          color: Colors.black,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: AppColors.glassBorder),
        ),
        child: Column(
          children: [
            // Cabecera
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Capturar Foto',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white),
                    onPressed: () => Get.back(),
                  ),
                ],
              ),
            ),

            // Preview
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    width: double.infinity,
                    color: Colors.grey[900],
                    child: _isInit && _controller != null
                        ? CameraPreview(_controller!)
                        : const Center(
                            child: CircularProgressIndicator(
                              color: AppColors.primary,
                            ),
                          ),
                  ),
                ),
              ),
            ),

            // Controles
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  // Cambiar cámara
                  if (_cameras.length > 1)
                    IconButton(
                      icon: const Icon(
                        Icons.flip_camera_ios,
                        color: Colors.white,
                        size: 28,
                      ),
                      onPressed: _switchCamera,
                    ),

                  // Botón Obturador
                  GestureDetector(
                    onTap: _takePicture,
                    child: Container(
                      width: 70,
                      height: 70,
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 3),
                      ),
                      child: Container(
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.camera_alt,
                          color: Colors.black,
                        ),
                      ),
                    ),
                  ),

                  // Espaciador si no hay cambio de cámara para centrar
                  if (_cameras.length <= 1) const SizedBox(width: 48),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
