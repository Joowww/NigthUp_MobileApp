import 'package:get/get.dart';
import '../models/business.dart';
import '../models/event.dart';
import '../models/friend.dart';
import '../services/api_service.dart';

class MenuModalController extends GetxController {
  final ApiService _apiService = Get.find<ApiService>();

  var currentTab = 0.obs;
  var isLoadingBusinesses = false.obs;
  var isLoadingEvents = false.obs;
  var isLoadingFriends = true.obs;

  var businesses = <Business>[].obs;
  var events = <Event>[].obs;
  var friends = <Friend>[].obs;

  @override
  void onInit() {
    super.onInit();
    fetchBusinesses();
    fetchEvents();
    fetchFriends();
  }

  void changeTab(int index) {
    currentTab.value = index;
  }

  Future<void> fetchBusinesses() async {
    isLoadingBusinesses.value = true;
    try {
      final response = await _apiService.get('/business?limit=1000');

      if (response.data is List) {
        businesses.value = (response.data as List)
            .map((json) => Business.fromJson(json))
            .toList();
      } else if (response.data is Map && response.data['businesses'] is List) {
        businesses.value = (response.data['businesses'] as List)
            .map((json) => Business.fromJson(json))
            .toList();
      } else {
        businesses.value = [
          Business(
            id: 'business_1',
            name: 'Bar Ejemplo',
            address: 'Calle Principal 123',
            phone: '666777888',
            avatar: '',
            events: [],
            managers: [],
            active: true,
          ),
        ];
      }
    } catch (e) {
      businesses.value = [];
    } finally {
      isLoadingBusinesses.value = false;
    }
  }

  Future<void> fetchEvents() async {
    isLoadingEvents.value = true;
    try {
      final response = await _apiService.get('/event?limit=1000');

      if (response.data is List) {
        events.value = (response.data as List)
            .map((json) => Event.fromJson(json))
            .toList();
      } else if (response.data is Map && response.data['events'] is List) {
        events.value = (response.data['events'] as List)
            .map((json) => Event.fromJson(json))
            .toList();
      } else {
        events.value = [
          Event(
            id: 'event_1',
            title: 'Fiesta de Ejemplo',
            venue: 'Sala Principal',
            description: 'Una gran fiesta',
            image: '',
            price: 15.0,
            date: DateTime.now().add(Duration(days: 1)),
            tags: ['Techno', 'Electrónica'],
            likes: 42,
            participantsCount: 120,
          ),
        ];
      }
    } catch (e) {
      events.value = [];
    } finally {
      isLoadingEvents.value = false;
    }
  }

  Future<void> updateFriendsStatus() async {
    final ApiService apiService = _apiService;
    for (var friend in friends) {
      try {
        await apiService.get('/friendship/status/${friend.id}');
      } catch (e) {}
    }
  }

  Future<void> fetchFriends() async {
    isLoadingFriends.value = true;
    try {
      final response = await _apiService.get('/friendship/friends');

      if (response.data is List) {
        friends.value = (response.data as List)
            .map((json) => Friend.fromJson(json))
            .toList();
        await updateFriendsStatus();
      } else if (response.data is Map && response.data['friends'] is List) {
        friends.value = (response.data['friends'] as List)
            .map((json) => Friend.fromJson(json))
            .toList();
        await updateFriendsStatus();
      } else {
        friends.value = [
          Friend(
            id: 'friend_1',
            username: 'Amigo Ejemplo',
            profilePictureUrl: '',
            isOnline: true,
            distance: 2.5,
          ),
        ];
      }
    } catch (e) {
      friends.value = [];
    } finally {
      isLoadingFriends.value = false;
    }
  }

  void refreshData() {
    if (currentTab.value == 0) fetchBusinesses();
    if (currentTab.value == 1) fetchEvents();
    if (currentTab.value == 2) fetchFriends();
  }
}
