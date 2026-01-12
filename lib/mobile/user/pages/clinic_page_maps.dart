import 'package:capstone_app/data/models/clinic_model.dart';
import 'package:capstone_app/data/models/clinic_settings_model.dart';
import 'package:capstone_app/data/repository/auth.repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:get/get.dart';

class ClinicPageMaps extends StatefulWidget {
  final Clinic clinic;

  const ClinicPageMaps({super.key, required this.clinic});

  @override
  State<ClinicPageMaps> createState() => _ClinicPageMapsState();
}

class _ClinicPageMapsState extends State<ClinicPageMaps> {
  final MapController _mapController = MapController();
  LatLng? userLocation;
  LatLng? clinicLocation;
  List<LatLng> routePoints = [];
  double distanceInKm = 0.0;
  bool isLoading = true;
  String? error;
  ClinicSettings? clinicSettings;
  bool userOutOfBounds = false;
  bool showWithoutUserLocation = false;

  // San Jose Del Monte, Bulacan bounds
  static const double southLat = 14.7500;
  static const double northLat = 14.8700;
  static const double westLng = 121.0000;
  static const double eastLng = 121.1000;

  // Define the bounds for map constraint
  final LatLngBounds _sjdmBounds = LatLngBounds(
    const LatLng(southLat, westLng),
    const LatLng(northLat, eastLng),
  );

  @override
  void initState() {
    super.initState();
    _initializeMap();
  }

  Future<void> _initializeMap() async {
    await _fetchClinicSettings();

    if (clinicLocation != null) {
      await _fetchUserLocation();

      if (!showWithoutUserLocation &&
          userLocation != null &&
          clinicLocation != null) {
        await _fetchRoute();
        _fitMapToBounds();
      } else if (showWithoutUserLocation || userLocation == null) {
        _centerOnClinic();
      }
    }

    setState(() {
      isLoading = false;
    });
  }

  Future<void> _fetchUserLocation() async {
    try {
      Position? position = await _getCurrentUserLocation();
      if (position != null) {
        LatLng fetchedLocation = LatLng(position.latitude, position.longitude);

        if (!_isWithinBounds(fetchedLocation)) {
          setState(() {
            userOutOfBounds = true;
          });
          return;
        }

        setState(() {
          userLocation = fetchedLocation;
          userOutOfBounds = false;
        });
      }
    } catch (e) {
    }
  }

  bool _isWithinBounds(LatLng point) {
    return point.latitude >= southLat &&
        point.latitude <= northLat &&
        point.longitude >= westLng &&
        point.longitude <= eastLng;
  }

  Future<void> _fetchClinicSettings() async {
    try {
      final authRepository = Get.find<AuthRepository>();
      final settings = await authRepository
          .getClinicSettingsByClinicId(widget.clinic.documentId ?? '');

      if (settings?.location != null) {
        LatLng location =
            LatLng(settings!.location!['lat']!, settings.location!['lng']!);

        if (!_isWithinBounds(location)) {
          setState(() {
            error = "Clinic location is outside San Jose Del Monte, Bulacan";
          });
          return;
        }

        setState(() {
          clinicSettings = settings;
          clinicLocation = location;
        });
      } else {
        setState(() {
          error = "Clinic location not set";
        });
      }
    } catch (e) {
      setState(() {
        error = "Failed to load clinic location";
      });
    }
  }

  Future<Position?> _getCurrentUserLocation() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) return null;

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) return null;
      }
      if (permission == LocationPermission.deniedForever) return null;

      return await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
    } catch (e) {
      return null;
    }
  }

  Future<void> _fetchRoute() async {
    if (userLocation == null || clinicLocation == null) return;

    try {
      String url =
          "https://router.project-osrm.org/route/v1/driving/${userLocation!.longitude},${userLocation!.latitude};${clinicLocation!.longitude},${clinicLocation!.latitude}?overview=full&geometries=geojson";

      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        if (data['routes'] != null && data['routes'].isNotEmpty) {
          List<dynamic> coordinates =
              data['routes'][0]['geometry']['coordinates'];

          double distanceMeters = data['routes'][0]['distance'].toDouble();

          setState(() {
            routePoints = coordinates.map((c) => LatLng(c[1], c[0])).toList();
            distanceInKm = distanceMeters / 1000;
          });
        }
      }
    } catch (e) {
    }
  }

  void _fitMapToBounds() {
    if (userLocation == null || clinicLocation == null) return;

    double minLat = userLocation!.latitude < clinicLocation!.latitude
        ? userLocation!.latitude
        : clinicLocation!.latitude;
    double maxLat = userLocation!.latitude > clinicLocation!.latitude
        ? userLocation!.latitude
        : clinicLocation!.latitude;
    double minLng = userLocation!.longitude < clinicLocation!.longitude
        ? userLocation!.longitude
        : clinicLocation!.longitude;
    double maxLng = userLocation!.longitude > clinicLocation!.longitude
        ? userLocation!.longitude
        : clinicLocation!.longitude;

    double latPadding = (maxLat - minLat) * 0.2;
    double lngPadding = (maxLng - minLng) * 0.2;

    minLat = (minLat - latPadding).clamp(southLat, northLat);
    maxLat = (maxLat + latPadding).clamp(southLat, northLat);
    minLng = (minLng - lngPadding).clamp(westLng, eastLng);
    maxLng = (maxLng + lngPadding).clamp(westLng, eastLng);

    final bounds = LatLngBounds(
      LatLng(minLat, minLng),
      LatLng(maxLat, maxLng),
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _mapController.fitCamera(
        CameraFit.bounds(
          bounds: bounds,
          padding: const EdgeInsets.all(50),
        ),
      );
    });
  }

  void _centerOnClinic() {
    if (clinicLocation == null) return;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _mapController.move(clinicLocation!, 15);
    });
  }

  void _continueWithoutLocation() {
    setState(() {
      showWithoutUserLocation = true;
      userOutOfBounds = false;
      isLoading = true;
    });
    _centerOnClinic();
    setState(() {
      isLoading = false;
    });
  }

  Widget _buildLoadingState() {
    return Container(
      color: Colors.grey.shade100,
      child: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 12),
            Text(
              'Loading map...',
              style: TextStyle(fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState() {
    return Container(
      color: Colors.grey.shade100,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 48,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 12),
            Text(
              error ?? "Failed to load location",
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOutOfBoundsDialog() {
    return Container(
      color: Colors.grey.shade100,
      child: Center(
        child: Container(
          padding: const EdgeInsets.all(24),
          margin: const EdgeInsets.symmetric(horizontal: 20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.location_off,
                size: 48,
                color: Colors.orange.shade600,
              ),
              const SizedBox(height: 16),
              const Text(
                "Location Outside Service Area",
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                "Your current location is outside San Jose Del Monte, Bulacan.",
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.grey[600],
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 4),
              Text(
                "You can still view the clinic location on the map.",
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.grey[500],
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _continueWithoutLocation,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue.shade600,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: const Text(
                    "Show Clinic Location",
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: isLoading
          ? _buildLoadingState()
          : error != null
              ? _buildErrorState()
              : userOutOfBounds
                  ? _buildOutOfBoundsDialog()
                  : (clinicLocation == null)
                      ? _buildErrorState()
                      : Stack(
                          children: [
                            // Map
                            FlutterMap(
                              mapController: _mapController,
                              options: MapOptions(
                                initialCenter: clinicLocation!,
                                initialZoom: 15,
                                maxZoom: 19,
                                minZoom: 12,
                                cameraConstraint: CameraConstraint.contain(
                                  bounds: _sjdmBounds,
                                ),
                                interactionOptions: const InteractionOptions(
                                  flags: InteractiveFlag.all &
                                      ~InteractiveFlag.rotate,
                                ),
                              ),
                              children: [
                                TileLayer(
                                  urlTemplate:
                                      "https://{s}.basemaps.cartocdn.com/light_all/{z}/{x}/{y}.png",
                                  subdomains: const ['a', 'b', 'c', 'd'],
                                ),
                                // Route polyline - always visible
                                if (routePoints.isNotEmpty &&
                                    !showWithoutUserLocation)
                                  PolylineLayer(
                                    polylines: [
                                      Polyline(
                                        points: routePoints,
                                        color: Colors.blue,
                                        strokeWidth: 4.0,
                                      ),
                                    ],
                                  ),
                                // Markers
                                MarkerLayer(
                                  markers: [
                                    // User location marker
                                    if (userLocation != null &&
                                        !showWithoutUserLocation)
                                      Marker(
                                        point: userLocation!,
                                        width: 32,
                                        height: 32,
                                        child: Container(
                                          decoration: BoxDecoration(
                                            color: Colors.blue,
                                            shape: BoxShape.circle,
                                            border: Border.all(
                                              color: Colors.white,
                                              width: 2,
                                            ),
                                          ),
                                          child: const Icon(
                                            Icons.my_location,
                                            color: Colors.white,
                                            size: 18,
                                          ),
                                        ),
                                      ),
                                    // Clinic location marker (non-clickable)
                                    Marker(
                                      point: clinicLocation!,
                                      width: 50,
                                      height: 70,
                                      child: Column(
                                        children: [
                                          Icon(
                                            Icons.location_on,
                                            color: Colors.red.shade600,
                                            size: 32,
                                          ),
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 4,
                                              vertical: 2,
                                            ),
                                            decoration: BoxDecoration(
                                              color: Colors.white,
                                              borderRadius:
                                                  BorderRadius.circular(5),
                                              boxShadow: [
                                                BoxShadow(
                                                  color: Colors.black
                                                      .withOpacity(0.2),
                                                  blurRadius: 2,
                                                  offset: const Offset(0, 1),
                                                ),
                                              ],
                                            ),
                                            child: Text(
                                              widget.clinic.clinicName,
                                              style: const TextStyle(
                                                fontSize: 8,
                                                fontWeight: FontWeight.bold,
                                                color: Colors.black87,
                                              ),
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),

                            // Top info overlay with distance
                            SafeArea(
                              child: Padding(
                                padding: const EdgeInsets.all(16.0),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 10,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(25),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.1),
                                        blurRadius: 8,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        Icons.location_on,
                                        color: Colors.red.shade600,
                                        size: 20,
                                      ),
                                      const SizedBox(width: 8),
                                      Flexible(
                                        child: Text(
                                          widget.clinic.clinicName,
                                          style: const TextStyle(
                                            fontWeight: FontWeight.w600,
                                            fontSize: 14,
                                          ),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                      if (distanceInKm > 0 &&
                                          !showWithoutUserLocation) ...[
                                        const SizedBox(width: 8),
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 6,
                                            vertical: 3,
                                          ),
                                          decoration: BoxDecoration(
                                            color: Colors.blue.shade50,
                                            borderRadius:
                                                BorderRadius.circular(6),
                                          ),
                                          child: Text(
                                            "${distanceInKm.toStringAsFixed(2)} km",
                                            style: TextStyle(
                                              fontSize: 11,
                                              fontWeight: FontWeight.w600,
                                              color: Colors.blue.shade700,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
    );
  }
}
