import 'package:get/get.dart';
import '../services/api_service.dart';
import '../models/friend.dart';
import 'package:geolocator/geolocator.dart';
import '../services/storage_service.dart';
import 'settings_controller.dart';

class MapController extends GetxController {
  final ApiService _apiService = Get.find<ApiService>();
  final SettingsController _settingsController = Get.find<SettingsController>();
  var nearbyFriends = [].obs;
  var nearbyUsers = [].obs;
  var nearbyEvents = [].obs;
  var nearbyBusinesses = [].obs;
  var isVisibleOnMap = true.obs;
  var isLoading = true.obs;

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
    Future.delayed(const Duration(seconds: 2), () {
      final userId = _apiService.getUserId();
      if (userId != null) {
        fetchNearbyFriends();
        fetchNearbyEvents();
        fetchNearbyBusinesses();
      }
    });
  }

  void _getCurrentLocation() async {
    try {
      bool serviceEnabled;
      LocationPermission permission;

      serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        return;
      }

      if (!_settingsController.locationEnabled.value) {
        return;
      }

      permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        return;
      }

      Position position = await Geolocator.getCurrentPosition();
      currentPosition.value = position;
      _updateUserLocationIfAuthenticated(position.latitude, position.longitude);
    } catch (e) {}
  }

  void _updateUserLocationIfAuthenticated(double lat, double lng) async {
    try {
      final token = await _apiService.getUserId();
      if (token != null) {
        await updateUserLocation(lat, lng);
      }
    } catch (e) {}
  }

  void fetchNearbyFriends() async {
    final userId = _apiService.getUserId();
    if (userId == null) {
      isLoading.value = false;
      return;
    }
    try {
      isLoading.value = true;
      final response = await _apiService.get('/friendship/friends');
      if (response.statusCode == 200 && response.data is List) {
        final List<dynamic> friendships = response.data;
        final List<Friend> friends = friendships.map<Friend>((item) {
          final requester = item['requester'];
          final recipient = item['recipient'];
          final isMeRequester = requester['_id'] == userId;
          final userJson = isMeRequester ? recipient : requester;
          return Friend.fromJson(userJson);
        }).toList();
        nearbyFriends.value = friends;
      } else if (response.data is Map && response.data['friends'] is List) {
        final List<dynamic> friendships = response.data['friends'];
        final List<Friend> friends = friendships.map<Friend>((item) {
          final requester = item['requester'];
          final recipient = item['recipient'];
          final isMeRequester = requester['_id'] == userId;
          final userJson = isMeRequester ? recipient : requester;
          return Friend.fromJson(userJson);
        }).toList();
        nearbyFriends.value = friends;
      } else {
        nearbyFriends.value = [
          Friend.fromJson({
            '_id': 'friend_1',
            'username': 'Ana García',
            'profilePictureUrl': '',
            'location': {
              'coordinates': [-3.70256, 40.4165],
            },
          }),
          Friend.fromJson({
            '_id': 'friend_2',
            'username': 'Carlos López',
            'profilePictureUrl': '',
            'location': {
              'coordinates': [-3.70379, 40.4192],
            },
          }),
        ];
      }
    } catch (e) {
      nearbyFriends.value = [];
    } finally {
      isLoading.value = false;
    }
  }

  void fetchNearbyEvents() async {
    final userId = _apiService.getUserId();
    if (userId == null) {
      return;
    }
    try {
      final response = await _apiService.get('/event?limit=50');
      if (response.statusCode == 200) {
        List<dynamic> eventsList = [];
        if (response.data is Map && response.data['events'] is List) {
          eventsList = response.data['events'];
        } else if (response.data is List) {
          eventsList = response.data;
        }

        nearbyEvents.value = eventsList;
      } else {
        nearbyEvents.value = [
          {
            '_id': 'event_1',
            'name': 'Fiesta Techno',
            'location': {
              'coordinates': [-3.70256, 40.4165],
              'name': 'Sala Capital',
            },
            'image': '',
          },
          {
            '_id': 'event_2',
            'name': 'Concierto Rock',
            'location': {
              'coordinates': [-3.70379, 40.4192],
              'name': 'Teatro Principal',
            },
            'image': '',
          },
        ];
      }
    } catch (e) {
      nearbyEvents.value = [];
    }
  }

  void fetchNearbyBusinesses() async {
    final userId = _apiService.getUserId();
    if (userId == null) {
      return;
    }
    try {
      final response = await _apiService.get('/business?limit=50');
      if (response.statusCode == 200) {
        List<dynamic> businessesList = [];
        if (response.data is Map && response.data['businesses'] is List) {
          businessesList = response.data['businesses'];
        } else if (response.data is List) {
          businessesList = response.data;
        }

        nearbyBusinesses.value = businessesList;
      } else {
        nearbyBusinesses.value = [
          {
            '_id': 'business_1',
            'name': 'Bar Central',
            'location': {
              'coordinates': [-3.70379, 40.4192],
              'name': 'Calle Mayor 123',
            },
            'avatar': '',
          },
          {
            '_id': 'business_2',
            'name': 'Restaurante Luna',
            'location': {
              'coordinates': [-3.70123, 40.4178],
              'name': 'Plaza del Sol 45',
            },
            'avatar': '',
          },
        ];
      }
    } catch (e) {
      nearbyBusinesses.value = [];
    }
  }

  Future<void> updateUserLocation(double lat, double lng) async {
    try {
      await _apiService.post(
        '/map/location',
        data: {'longitude': lng, 'latitude': lat},
      );
    } catch (e) {}
  }

  Future<void> setVisibilityOnMap(bool isVisible) async {
    try {
      final response = await _apiService.patch(
        '/map/visibility',
        data: {"isVisible": isVisible},
      );
      if (response.statusCode == 200) {
        isVisibleOnMap.value = isVisible;
      }
    } catch (e) {}
  }

  void refreshData() {
    fetchNearbyFriends();
    fetchNearbyEvents();
    fetchNearbyBusinesses();
  }

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
