import 'package:jitsi_meet_wrapper/jitsi_meet_wrapper.dart';
import 'package:get/get.dart';
import 'package:flutter/foundation.dart';
import 'package:url_launcher/url_launcher.dart';
import 'api_service.dart';
import '../models/conversation.dart';

class JitsiService extends GetxService {
  final ApiService _apiService = Get.find<ApiService>();

  Future<void> startMeeting(Conversation conversation) async {
    final String roomName = "NightUp_${conversation.id}";
    final String serverUrl = "https://meet.jit.si/$roomName";

    if (kIsWeb) {
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

    try {
      final String? username = _apiService.getUsername();
      final options = JitsiMeetingOptions(
        roomNameOrUrl: roomName,
        subject: conversation.displayName,
        userDisplayName: username ?? "Usuario de NightUp",
        isAudioMuted: false,
        isVideoMuted: false,
      );

      await JitsiMeetWrapper.joinMeeting(options: options);
    } catch (e) {
      if (await canLaunchUrl(Uri.parse(serverUrl))) {
        await launchUrl(
          Uri.parse(serverUrl),
          mode: LaunchMode.externalApplication,
        );
      }
    }
  }
}
