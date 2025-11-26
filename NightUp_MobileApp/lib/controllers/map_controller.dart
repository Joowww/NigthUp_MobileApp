import 'package:get/get.dart';
import '../services/api_service.dart';
import 'package:geolocator/geolocator.dart';

class MapController extends GetxController {
  final ApiService _apiService = Get.find<ApiService>();
  var nearbyFriends = [].obs;
  var nearbyEvents = [].obs;
  var isLoading = true.obs;
  var currentPosition = Position(
    longitude: 2.1734, // Barcelona por defecto
    latitude: 41.3851,
    timestamp: DateTime.now(),
    accuracy: 0,
    altitude: 0,
    heading: 0,
    speed: 0,
    speedAccuracy: 0,
    altitudeAccuracy: 0,
    headingAccuracy: 0,
  ).obs;

  @override
  void onInit() {
    super.onInit();
    _getCurrentLocation();
    fetchNearbyFriends();
    fetchNearbyEvents();
  }

  void _getCurrentLocation() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      Get.snackbar('Error', 'Location services are disabled.');
      return;
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        Get.snackbar('Error', 'Location permissions are denied');
        return;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      Get.snackbar('Error', 'Location permissions are permanently denied, we cannot request permissions.');
      return;
    }

    Position position = await Geolocator.getCurrentPosition();
    currentPosition.value = position;
    updateUserLocation(position.latitude, position.longitude);
  }

  void fetchNearbyFriends() async {
    try {
      final response = await _apiService.get('/map/nearby/friends');
      nearbyFriends.value = response.data;
      print('✅ Loaded ${nearbyFriends.length} nearby friends');
    } catch (e) {
      Get.snackbar('Error', 'No se pudieron cargar los amigos cercanos: $e');
    }
  }

  void fetchNearbyEvents() async {
    try {
      final response = await _apiService.get('/map/nearby/events');
      nearbyEvents.value = response.data;
      print('✅ Loaded ${nearbyEvents.length} nearby events');
    } catch (e) {
      Get.snackbar('Error', 'No se pudieron cargar los eventos cercanos: $e');
    }
  }

  void updateUserLocation(double lat, double lng) async {
    try {
      await _apiService.post('/map/location', data: {
        'coordinates': [lng, lat], // GeoJSON format
        'isVisibleOnMap': true
      });
      print('✅ Location updated to: $lat, $lng');
    } catch (e) {
      print('❌ Error updating location: $e');
    }
  }

  void refreshData() {
    fetchNearbyFriends();
    fetchNearbyEvents();
  }
}