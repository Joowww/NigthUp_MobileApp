import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:record/record.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';

class AudioRecorderService {
  final AudioRecorder _audioRecorder = AudioRecorder();
  bool _isRecording = false;

  bool get isRecording => _isRecording;

  Future<void> init() async {
    // Inicialización si es necesaria
  }

  Future<bool> hasPermission() async {
    if (kIsWeb) {
      return await _audioRecorder.hasPermission();
    }
    final status = await Permission.microphone.request();
    return status == PermissionStatus.granted;
  }

  Future<void> startRecording() async {
    try {
      if (await hasPermission()) {
        String path = '';

        if (!kIsWeb) {
          final Directory appDir = await getApplicationDocumentsDirectory();
          final String fileName =
              'audio_${DateTime.now().millisecondsSinceEpoch}.m4a';
          path = '${appDir.path}/$fileName';
        }
        await _audioRecorder.start(const RecordConfig(), path: path);
        _isRecording = true;
      }
    } catch (e) {
      //nothing
    }
  }

  Future<String?> stopRecording() async {
    try {
      if (!_isRecording) return null;

      final path = await _audioRecorder.stop();
      _isRecording = false;
      return path;
    } catch (e) {
      return null;
    }
  }

  Future<void> cancelRecording() async {
    if (_isRecording) {
      await _audioRecorder.stop();
      _isRecording = false;
    }
  }

  void dispose() {
    _audioRecorder.dispose();
  }
}
