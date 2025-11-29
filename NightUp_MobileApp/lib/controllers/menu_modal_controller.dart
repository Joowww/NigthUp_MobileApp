import 'package:get/get.dart';
import '../models/business.dart';
import '../models/event.dart';
import '../models/friend.dart';
import '../services/api_service.dart';
import 'map_controller.dart';

class MenuModalController extends GetxController {

  final ApiService _apiService = Get.find<ApiService>();
  final MapController mapController = Get.find<MapController>();

  var currentTab = 0.obs;
  var isLoadingBusinesses = false.obs;
  var isLoadingEvents = false.obs;
  var isLoadingFriends = true.obs;

  // Usar los datos de MapController para negocios y eventos
  RxList<Business> get businesses => RxList<Business>(
    mapController.nearbyBusinesses.map<Business>((b) => Business.fromJson(b)).toList(),
  );
  RxList<Event> get events => RxList<Event>(
    mapController.nearbyEvents.map<Event>((e) => Event.fromJson(e)).toList(),
  );
  var friends = <Friend>[].obs;

  @override
  void onInit() {
    super.onInit();
    // Los negocios y eventos se obtienen desde MapController
    fetchFriends();
  }

  void changeTab(int index) {
    currentTab.value = index;
  }

  // Los negocios y eventos se refrescan desde MapController
  void fetchBusinesses() {
    mapController.fetchNearbyBusinesses();
  }

  void fetchEvents() {
    mapController.fetchNearbyEvents();
  }

  Future<void> fetchFriends() async {
    isLoadingFriends.value = true;
    try {
      final response = await _apiService.get('/friendship/friends');
      if (response.data is List) {
        friends.value = response.data.map((i) => Friend.fromJson(i)).toList();
        print('✅ Loaded ${friends.length} friends from backend');
      } else {
        friends.value = [];
        print('⚠️ No friends found or invalid response format');
      }
    } catch (e) {
      print('❌ Error loading friends: $e');
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