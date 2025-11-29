// controllers/map_controller.dart - ACTUALIZADO
import 'package:get/get.dart';
import '../services/api_service.dart';
import 'package:geolocator/geolocator.dart';

class MapController extends GetxController {
  final ApiService _apiService = Get.find<ApiService>();
  var nearbyFriends = [].obs;
  var nearbyUsers = [].obs;
  var nearbyEvents = [].obs;
  var nearbyBusinesses = [].obs;
  var isVisibleOnMap = true.obs;
  var isLoading = true.obs;
  
  // Posición por defecto (Madrid)
  var currentPosition = Position(
    longitude: -3.6929536,
    latitude: 40.4258816,
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
    // Esperar a que el usuario esté autenticado antes de cargar datos
    Future.delayed(const Duration(seconds: 2), () {
      final userId = _apiService.getUserId();
      if (userId != null) {
        fetchNearbyFriends();
        fetchNearbyEvents(); // Esto usa businesses con category=event
        fetchNearbyBusinesses(); // Esto usa businesses con category=business o sin categoría
      } else {
        print('⚠️ No token, no se cargan datos de mapa');
      }
    });
  }

  void _getCurrentLocation() async {
    try {
      bool serviceEnabled;
      LocationPermission permission;

      serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        print('❌ Location services are disabled');
        return;
      }

      permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          print('❌ Location permissions are denied');
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        print('❌ Location permissions are permanently denied');
        return;
      }

      Position position = await Geolocator.getCurrentPosition();
      currentPosition.value = position;
      print('📍 Current location: ${position.latitude}, ${position.longitude}');
      
      // Solo actualizar ubicación si el usuario está autenticado
      _updateUserLocationIfAuthenticated(position.latitude, position.longitude);
    } catch (e) {
      print('❌ Error getting location: $e');
    }
  }

  void _updateUserLocationIfAuthenticated(double lat, double lng) async {
    try {
      // Verificar si hay token antes de hacer la request
      final token = await _apiService.getUserId();
      if (token != null) {
        await updateUserLocation(lat, lng);
      } else {
        print('⚠️ User not authenticated, skipping location update');
      }
    } catch (e) {
      print('❌ Error checking authentication for location update: $e');
    }
  }

  void fetchNearbyFriends() async {
    final userId = _apiService.getUserId();
    if (userId == null) {
      print('⚠️ No token, no se cargan nearby friends');
      isLoading.value = false;
      return;
    }
    try {
      isLoading.value = true;
      final response = await _apiService.get('/map/nearby/friends?radius=10000');
      if (response.statusCode == 200 && response.data is List) {
        nearbyFriends.value = response.data;
        print('✅ Loaded ${nearbyFriends.length} nearby friends');
      } else if (response.statusCode == 401) {
        print('🔐 Authentication required for friends data');
        nearbyFriends.value = [];
      } else {
        nearbyFriends.value = [];
        print('⚠️ No friends found or invalid response format');
      }
    } catch (e) {
      print('❌ Error loading nearby friends: $e');
      nearbyFriends.value = [];
    } finally {
      isLoading.value = false;
    }
  }

  void fetchNearbyEvents() async {
    final userId = _apiService.getUserId();
    if (userId == null) {
      print('⚠️ No token, no se cargan nearby events');
      return;
    }
    try {
      // Usar la ruta de businesses con filtro de categoría para eventos
      final response = await _apiService.get('/map/nearby/businesses?radius=5000&category=event');
      if (response.statusCode == 200 && response.data is Map && response.data['businesses'] is List) {
        nearbyEvents.value = response.data['businesses'];
        print('✅ Loaded ${nearbyEvents.length} nearby events (category=event)');
      } else if (response.statusCode == 401) {
        print('🔐 Authentication required for events data');
        nearbyEvents.value = [];
      } else {
        nearbyEvents.value = [];
        print('⚠️ No events found or invalid response format');
      }
    } catch (e) {
      print('❌ Error loading nearby events: $e');
      nearbyEvents.value = [];
    }
  }

  void fetchNearbyBusinesses() async {
    final userId = _apiService.getUserId();
    if (userId == null) {
      print('⚠️ No token, no se cargan nearby businesses');
      return;
    }
    try {
      // Puedes filtrar por category=business si tu backend lo soporta, o dejarlo vacío para traer todos los negocios
      final response = await _apiService.get('/map/nearby/businesses?radius=5000&category=business');
      if (response.statusCode == 200 && response.data is Map && response.data['businesses'] is List) {
        nearbyBusinesses.value = response.data['businesses'];
        print('✅ Loaded ${nearbyBusinesses.length} nearby businesses (category=business)');
      } else if (response.statusCode == 401) {
        print('🔐 Authentication required for businesses data');
        nearbyBusinesses.value = [];
      } else {
        nearbyBusinesses.value = [];
        print('⚠️ No businesses found or invalid response format');
      }
    } catch (e) {
      print('❌ Error loading nearby businesses: $e');
      nearbyBusinesses.value = [];
    }
  }

  Future<void> updateUserLocation(double lat, double lng) async {
    try {
      // POST /api/map/location body: [lng, lat]
      final response = await _apiService.post('/map/location', data: [lng, lat]);
      if (response.statusCode == 200 || response.statusCode == 201) {
        print('✅ Location updated to: $lat, $lng');
      } else if (response.statusCode == 401) {
        print('🔐 Authentication required to update location');
      } else {
        print('❌ Error updating location: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ Error updating location: $e');
    }

  }

  Future<void> setVisibilityOnMap(bool isVisible) async {
    try {
      final response = await _apiService.patch('/map/visibility', data: {"isVisible": isVisible});
      if (response.statusCode == 200) {
        isVisibleOnMap.value = isVisible;
        print('✅ User visibility updated: $isVisible');
      } else {
        print('❌ Error updating visibility: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ Error updating visibility: $e');
    }
  }

  // ...existing code...

  void refreshData() {
    fetchNearbyFriends();
    fetchNearbyEvents();
    fetchNearbyBusinesses();
  }

  // Método para obtener amigos como List<Map> para compatibilidad
  List<Map<String, dynamic>> getFriendsAsMap() {
    return nearbyFriends
        .where((friend) => friend is Map<String, dynamic>)
        .map<Map<String, dynamic>>((friend) => friend as Map<String, dynamic>)
        .where((element) => element.isNotEmpty)
        .toList();
  }

  List<Map<String, dynamic>> getUsersAsMap() {
    return nearbyUsers
        .where((user) => user is Map<String, dynamic>)
        .map<Map<String, dynamic>>((user) => user as Map<String, dynamic>)
        .where((element) => element.isNotEmpty)
        .toList();
  }
}