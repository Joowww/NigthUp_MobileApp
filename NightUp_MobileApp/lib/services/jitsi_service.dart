import 'package:jitsi_meet_wrapper/jitsi_meet_wrapper.dart';
import 'package:get/get.dart';
import 'package:flutter/foundation.dart';
import 'package:url_launcher/url_launcher.dart';
import 'api_service.dart';
import '../models/conversation.dart';
import 'dart:developer';

class JitsiService extends GetxService {
  final ApiService _apiService = Get.find<ApiService>();

  Future<void> startMeeting(Conversation conversation) async {
    final String roomName = "NightUp_${conversation.id}";
    final String serverUrl = "https://meet.jit.si/$roomName";

    // Si es WEB, usamos url_launcher porque el plugin de eventos falla en Chrome
    if (kIsWeb) {
      log(
        '🌐 Lanzando videollamada en Web (nueva pestaña): $serverUrl',
        name: 'JitsiService',
      );
      if (await canLaunchUrl(Uri.parse(serverUrl))) {
        await launchUrl(
          Uri.parse(serverUrl),
          mode: LaunchMode.externalApplication,
        );
      } else {
        Get.snackbar(
          'Error',
          'No se pudo abrir la videollamada en el navegador',
        );
      }
      return;
    }

    // Si es MÓVIL, usamos la integración nativa
    try {
      final String? username = _apiService.getUsername();
      log(
        '🚀 Iniciando videollamada integrada: $roomName',
        name: 'JitsiService',
      );

      final options = JitsiMeetingOptions(
        roomNameOrUrl: roomName,
        subject: conversation.displayName,
        userDisplayName: username ?? "Usuario de NightUp",
        isAudioMuted: false,
        isVideoMuted: false,
      );

      await JitsiMeetWrapper.joinMeeting(options: options);
    } catch (e) {
      log('❌ Error al lanzar Jitsi Meet nativo: $e', name: 'JitsiService');
      // Fallback a URL externa si falla el plugin nativo
      if (await canLaunchUrl(Uri.parse(serverUrl))) {
        await launchUrl(
          Uri.parse(serverUrl),
          mode: LaunchMode.externalApplication,
        );
      }
    }
  }
}
