import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../controllers/map_controller.dart' as myapp;
import '../theme/colors.dart';
import '../widgets/glass_card.dart';
import '../widgets/image_with_fallback.dart';
import '../models/business.dart';
import '../models/event.dart';
import '../models/friend.dart';

class FullMapScreen extends StatefulWidget {
  final Business? selectedBusiness;
  final Event? selectedEvent;
  final List<Business>? businesses;
  final List<Event>? events;

  const FullMapScreen({
    Key? key,
    this.selectedBusiness,
    this.selectedEvent,
    this.businesses,
    this.events,
  }) : super(key: key);

  @override
  _FullMapScreenState createState() => _FullMapScreenState();
}

class _FullMapScreenState extends State<FullMapScreen> {
  Business? _selectedBusiness;
  Event? _selectedEvent;
  final MapController _flutterMapController = MapController();
  bool _isMinimap = false;

  @override
  void initState() {
    super.initState();
    _selectedBusiness = widget.selectedBusiness;
    _selectedEvent = widget.selectedEvent;
  }

  void _showBusinessInfo(Business business) {
    setState(() {
      _selectedBusiness = business;
      _selectedEvent = null;
    });
  }

  void _showEventInfo(Event event) {
    setState(() {
      _selectedEvent = event;
      _selectedBusiness = null;
    });
  }

  void _zoomIn() {
    final currentZoom = _flutterMapController.camera.zoom;
    final newZoom = (currentZoom + 1).clamp(1.0, 18.0);
    _flutterMapController.move(_flutterMapController.camera.center, newZoom);
  }

  void _zoomOut() {
    final currentZoom = _flutterMapController.camera.zoom;
    final newZoom = (currentZoom - 1).clamp(1.0, 18.0);
    _flutterMapController.move(_flutterMapController.camera.center, newZoom);
  }

  void _toggleMinimap() {
    setState(() {
      _isMinimap = !_isMinimap;
      if (_isMinimap) {
        _flutterMapController.move(LatLng(40.4637, -3.7492), 5.5);
      } else {
        if (_selectedBusiness != null &&
            _selectedBusiness!.lat != null &&
            _selectedBusiness!.lng != null) {
          _flutterMapController.move(
            LatLng(_selectedBusiness!.lat!, _selectedBusiness!.lng!),
            15.0,
          );
        } else if (_selectedEvent != null &&
            _selectedEvent!.toJson()['location']?['coordinates'] != null) {
          final coords = _selectedEvent!.toJson()['location']['coordinates'];
          _flutterMapController.move(LatLng(coords[1], coords[0]), 15.0);
        }
      }
    });
  }

  Widget _greyGlassButton({
    required IconData icon,
    required VoidCallback onPressed,
    double size = 24,
    String? tooltip,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey.withOpacity(1.0),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.5)),
      ),
      child: IconButton(
        icon: Icon(icon, color: Colors.white, size: size),
        onPressed: onPressed,
        tooltip: tooltip,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final myapp.MapController _mapController = Get.find<myapp.MapController>();
    final List<Business> allBusinesses =
        widget.businesses ??
        _mapController.nearbyBusinesses
            .map((e) => Business.fromJson(e))
            .toList();
    final List<Event> allEvents =
        widget.events ??
        _mapController.nearbyEvents.map((e) => Event.fromJson(e)).toList();
    final LatLng initialCenter =
        _selectedBusiness != null &&
            _selectedBusiness!.lat != null &&
            _selectedBusiness!.lng != null
        ? LatLng(_selectedBusiness!.lat!, _selectedBusiness!.lng!)
        : _selectedEvent != null &&
              _selectedEvent!.toJson()['location']?['coordinates'] != null
        ? LatLng(
            _selectedEvent!.toJson()['location']['coordinates'][1],
            _selectedEvent!.toJson()['location']['coordinates'][0],
          )
        : LatLng(
            _mapController.currentPosition.value.latitude,
            _mapController.currentPosition.value.longitude,
          );

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          FlutterMap(
            mapController: _flutterMapController,
            options: MapOptions(
              initialCenter: _isMinimap
                  ? LatLng(40.4637, -3.7492)
                  : initialCenter,
              initialZoom: _isMinimap ? 5.5 : 15.0,
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.nightup.app',
              ),
              if (_selectedBusiness != null)
                MarkerLayer(
                  markers: allBusinesses
                      .where((b) => b.lat != null && b.lng != null)
                      .map((business) {
                        final isSelected =
                            _selectedBusiness != null &&
                            business.id == _selectedBusiness!.id;
                        return Marker(
                          width: isSelected ? 70.0 : 40.0,
                          height: isSelected ? 70.0 : 40.0,
                          point: LatLng(business.lat!, business.lng!),
                          child: GestureDetector(
                            onTap: () => _showBusinessInfo(business),
                            child: Icon(
                              Icons.store,
                              color: isSelected
                                  ? Colors.redAccent
                                  : Colors.blue,
                              size: isSelected ? 50 : 30,
                            ),
                          ),
                        );
                      })
                      .toList(),
                ),
              if (_selectedEvent != null)
                MarkerLayer(
                  markers: allEvents
                      .where((e) {
                        final loc = (e as dynamic).toJson()['location'];
                        if (loc is Map &&
                            loc['coordinates'] is List &&
                            loc['coordinates'].length >= 2) {
                          return loc['coordinates'][1] != null &&
                              loc['coordinates'][0] != null;
                        }
                        return false;
                      })
                      .map((event) {
                        final isSelected =
                            _selectedEvent != null &&
                            event.id == _selectedEvent!.id;
                        final loc = (event as dynamic).toJson()['location'];
                        final lat = loc['coordinates'][1];
                        final lng = loc['coordinates'][0];
                        return Marker(
                          width: isSelected ? 70.0 : 40.0,
                          height: isSelected ? 70.0 : 40.0,
                          point: LatLng(lat, lng),
                          child: GestureDetector(
                            onTap: () => _showEventInfo(event),
                            child: Icon(
                              Icons.event,
                              color: isSelected
                                  ? Colors.redAccent
                                  : Colors.orange,
                              size: isSelected ? 50 : 30,
                            ),
                          ),
                        );
                      })
                      .toList(),
                ),

              MarkerLayer(
                markers: [
                  Marker(
                    width: 40.0,
                    height: 40.0,
                    point: LatLng(
                      _mapController.currentPosition.value.latitude,
                      _mapController.currentPosition.value.longitude,
                    ),
                    child: Container(
                      decoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.2),
                        shape: BoxShape.circle,
                        border: Border.all(color: AppColors.primary, width: 3),
                      ),
                      child: const Center(
                        child: Icon(
                          Icons.location_on,
                          color: AppColors.primary,
                          size: 20,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),

          Positioned(
            bottom: 16,
            right: 16,
            child: FloatingActionButton(
              heroTag: 'minimap',
              onPressed: _toggleMinimap,
              backgroundColor: Colors.white,
              child: Icon(
                _isMinimap ? Icons.zoom_in_map : Icons.zoom_out_map,
                color: AppColors.primary,
                size: 24,
              ),
              tooltip: _isMinimap ? 'Expandir mapa' : 'Vista península',
            ),
          ),

          Positioned(
            bottom: 86,
            right: 16,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _greyGlassButton(
                  icon: Icons.add,
                  onPressed: _zoomIn,
                  size: 24,
                  tooltip: 'Zoom In',
                ),
                const SizedBox(height: 8),
                _greyGlassButton(
                  icon: Icons.remove,
                  onPressed: _zoomOut,
                  size: 24,
                  tooltip: 'Zoom Out',
                ),
              ],
            ),
          ),

          if (_selectedBusiness != null)
            Positioned(
              top: 60,
              left: 16,
              right: 16,
              child: GlassCard(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        _selectedBusiness!.name,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      if (_selectedBusiness!.address != null)
                        Text(
                          _selectedBusiness!.address!,
                          style: const TextStyle(color: Colors.grey),
                        ),
                      Padding(
                        padding: const EdgeInsets.only(top: 8.0),
                        child: Text(
                          _selectedBusiness!.displayContact,
                          style: const TextStyle(color: Colors.grey),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          if (_selectedEvent != null)
            Positioned(
              top: 64,
              left: 16,
              right: 16,
              child: GlassCard(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        _selectedEvent!.title,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      Text(
                        _selectedEvent!.venue,
                        style: const TextStyle(color: Colors.white70),
                      ),
                      Padding(
                        padding: const EdgeInsets.only(top: 8.0),
                        child: Text(
                          _selectedEvent!.description,
                          style: const TextStyle(color: Colors.white),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

          Positioned(
            top: 12,
            left: 12,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.grey.withOpacity(1.0),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white.withOpacity(0.5)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.15),
                    blurRadius: 4,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: IconButton(
                icon: const Icon(
                  Icons.arrow_back,
                  color: Colors.white,
                  size: 24,
                ),
                onPressed: () {
                  Get.back();
                },
                tooltip: 'Volver',
                splashRadius: 28,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
