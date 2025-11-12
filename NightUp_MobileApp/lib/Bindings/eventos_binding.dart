import 'package:nightup_mobile_app/Controllers/eventos_controller.dart';
import 'package:nightup_mobile_app/Services/eventos_services.dart';
import 'package:get/get.dart';

class EventosBinding extends Bindings {
  @override
  void dependencies() {
     Get.lazyPut<EventosServices>(() => EventosServices());
     Get.lazyPut<EventoController>(() => EventoController(Get.find<EventosServices>()));
  }
}