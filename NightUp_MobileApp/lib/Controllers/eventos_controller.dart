import 'package:NightUp_MobileApp/Models/eventos.dart';
import 'package:NightUp_MobileApp/Services/eventos_services.dart';
import 'package:get/get.dart';

class EventoController extends GetxController {
  var isLoading = true.obs;
  var eventosList = <Evento>[].obs;
  var selectedEvento = Rxn<Evento>();
 final EventosServices _eventosServices;

  EventoController(this._eventosServices);
  @override
  void onInit() {
    fetchEventos();
    super.onInit();
  }

  void fetchEventos() async {
    try {
      isLoading(true);
      var eventos = await _eventosServices.fetchEvents(); 
      if (eventos.isNotEmpty) {
        eventosList.assignAll(eventos);
      }
    } finally {
      isLoading(false);
    }
  }
  fetchEventoById(String id) async{
    try {
      isLoading(true);
      var evento = await _eventosServices.fetchEventById(id);
      selectedEvento.value = evento;
      }
      catch(e){
        Get.snackbar(
        "Error al cargar",
        "No se pudo encontrar el usuario: ${e.toString()}",
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      isLoading(false);
    }
  }
}