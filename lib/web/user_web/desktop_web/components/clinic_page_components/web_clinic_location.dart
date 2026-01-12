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

class WebClinicLocationUpdated extends StatefulWidget {
  final Clinic clinic;

  const WebClinicLocationUpdated({super.key, required this.clinic});

  @override
  State<WebClinicLocationUpdated> createState() =>
      _WebClinicLocationUpdatedState();
}

class _WebClinicLocationUpdatedState extends State<WebClinicLocationUpdated> {
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

  double getResponsivePadding(double screenWidth) {
    const double minScreen = 1100;
    const double maxScreen = 1920;
    const double minPadding = 16;
    const double maxPadding = 380;

    if (screenWidth <= minScreen) return minPadding;
    if (screenWidth >= maxScreen) return maxPadding;

    double t = (screenWidth - minScreen) / (maxScreen - minScreen);
    return minPadding + t * (maxPadding - minPadding);
  }

  // Get responsive map height based on screen size
  double getResponsiveMapHeight(double screenWidth) {
    if (screenWidth < 600) {
      return 300; // Mobile
    } else if (screenWidth < 1100) {
      return 500; // Tablet
    } else {
      return 700; // Desktop
    }
  }

  // Get responsive marker sizes
  double getResponsiveMarkerSize(double screenWidth, bool isUser) {
    if (screenWidth < 600) {
      return isUser ? 32 : 50; // Mobile
    } else {
      return isUser ? 40 : 70; // Desktop/Tablet
    }
  }

  // Get responsive icon sizes
  double getResponsiveIconSize(double screenWidth, String type) {
    if (screenWidth < 600) {
      // Mobile sizes
      if (type == 'user') return 18;
      if (type == 'clinic') return 32;
      if (type == 'overlay') return 16;
      if (type == 'error') return 48;
    }
    // Desktop/Tablet sizes
    if (type == 'user') return 24;
    if (type == 'clinic') return 40;
    if (type == 'overlay') return 18;
    if (type == 'error') return 64;
    return 20;
  }

  // Get responsive font sizes
  double getResponsiveFontSize(double screenWidth, String type) {
    if (screenWidth < 600) {
      // Mobile sizes
      if (type == 'title') return 18;
      if (type == 'overlay_name') return 12;
      if (type == 'overlay_distance') return 10;
      if (type == 'clinic_label') return 8;
      if (type == 'address') return 16;
      if (type == 'address_subtitle') return 12;
      if (type == 'dialog_title') return 16;
      if (type == 'dialog_text') return 13;
      if (type == 'dialog_button') return 14;
    }
    // Desktop/Tablet sizes
    if (type == 'title') return 26;
    if (type == 'overlay_name') return 14;
    if (type == 'overlay_distance') return 12;
    if (type == 'clinic_label') return 10;
    if (type == 'address') return 18;
    if (type == 'address_subtitle') return 14;
    if (type == 'dialog_title') return 22;
    if (type == 'dialog_text') return 16;
    if (type == 'dialog_button') return 16;
    return 14;
  }

  // Get responsive padding
  double getResponsiveElementPadding(double screenWidth, String type) {
    if (screenWidth < 600) {
      // Mobile padding
      if (type == 'overlay') return 10;
      if (type == 'dialog') return 24;
      if (type == 'address') return 16;
    }
    // Desktop/Tablet padding
    if (type == 'overlay') return 12;
    if (type == 'dialog') return 32;
    if (type == 'address') return 20;
    return 16;
  }

  Widget _buildLoadingState(double screenWidth) {
    final mapHeight = getResponsiveMapHeight(screenWidth);

    return Container(
      height: mapHeight,
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(),
            SizedBox(height: screenWidth < 600 ? 12 : 16),
            Text(
              'Loading map...',
              style: TextStyle(
                fontSize: screenWidth < 600 ? 14 : 16,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState(double screenWidth) {
    final mapHeight = getResponsiveMapHeight(screenWidth);
    final iconSize = getResponsiveIconSize(screenWidth, 'error');

    return Container(
      height: mapHeight,
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: iconSize,
              color: Colors.grey[400],
            ),
            SizedBox(height: screenWidth < 600 ? 12 : 16),
            Text(
              error ?? "Failed to load location",
              style: TextStyle(
                fontSize: getResponsiveFontSize(screenWidth, 'dialog_text'),
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOutOfBoundsDialog(double screenWidth) {
    final mapHeight = getResponsiveMapHeight(screenWidth);
    final dialogPadding = getResponsiveElementPadding(screenWidth, 'dialog');
    final iconSize = getResponsiveIconSize(screenWidth, 'error');

    return Container(
      height: mapHeight,
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Center(
        child: Container(
          padding: EdgeInsets.all(dialogPadding),
          margin: EdgeInsets.symmetric(horizontal: screenWidth < 600 ? 20 : 40),
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
                size: iconSize,
                color: Colors.orange.shade600,
              ),
              SizedBox(height: screenWidth < 600 ? 16 : 24),
              Text(
                "Location Outside Service Area",
                style: TextStyle(
                  fontSize: getResponsiveFontSize(screenWidth, 'dialog_title'),
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: screenWidth < 600 ? 8 : 12),
              Text(
                "Your current location is outside San Jose Del Monte, Bulacan.",
                style: TextStyle(
                  fontSize: getResponsiveFontSize(screenWidth, 'dialog_text'),
                  color: Colors.grey[600],
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: screenWidth < 600 ? 4 : 8),
              Text(
                "You can still view the clinic location on the map.",
                style: TextStyle(
                  fontSize:
                      getResponsiveFontSize(screenWidth, 'dialog_text') - 2,
                  color: Colors.grey[500],
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: screenWidth < 600 ? 16 : 32),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _continueWithoutLocation,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue.shade600,
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(
                      vertical: screenWidth < 600 ? 12 : 16,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: Text(
                    "Show Clinic Location",
                    style: TextStyle(
                      fontSize:
                          getResponsiveFontSize(screenWidth, 'dialog_button'),
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
    final screenWidth = MediaQuery.of(context).size.width;
    final mapHeight = getResponsiveMapHeight(screenWidth);
    final userMarkerSize = getResponsiveMarkerSize(screenWidth, true);
    final clinicMarkerSize = getResponsiveMarkerSize(screenWidth, false);
    final overlayPadding = getResponsiveElementPadding(screenWidth, 'overlay');
    final addressPadding = getResponsiveElementPadding(screenWidth, 'address');

    return Padding(
      padding:
          EdgeInsets.symmetric(horizontal: getResponsivePadding(screenWidth)),
      child: Column(
        children: [
          Row(
            children: [
              Text(
                "Location",
                style: TextStyle(
                  fontSize: getResponsiveFontSize(screenWidth, 'title'),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          SizedBox(height: screenWidth < 600 ? 10 : 14),

          // Address and contact information
          Container(
            width: double.infinity,
            margin: EdgeInsets.only(bottom: screenWidth < 600 ? 12 : 16),
            padding: EdgeInsets.all(addressPadding),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: BorderRadius.circular(15),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Column(
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.location_on,
                      color: Colors.red.shade600,
                      size: screenWidth < 600 ? 20 : 24,
                    ),
                    SizedBox(width: screenWidth < 600 ? 8 : 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.clinic.address,
                            style: TextStyle(
                              fontSize:
                                  getResponsiveFontSize(screenWidth, 'address'),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          SizedBox(height: screenWidth < 600 ? 2 : 4),
                          Text(
                            "Full address of ${widget.clinic.clinicName}",
                            style: TextStyle(
                              fontSize: getResponsiveFontSize(
                                  screenWidth, 'address_subtitle'),
                              color: Colors.grey.shade600,
                            ),
                          ),
                          if (distanceInKm > 0 && !showWithoutUserLocation) ...[
                            SizedBox(height: screenWidth < 600 ? 6 : 8),
                            Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: screenWidth < 600 ? 6 : 8,
                                vertical: screenWidth < 600 ? 3 : 4,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.blue.shade50,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                "${distanceInKm.toStringAsFixed(2)} km away",
                                style: TextStyle(
                                  fontSize: getResponsiveFontSize(
                                      screenWidth, 'address_subtitle'),
                                  fontWeight: FontWeight.w600,
                                  color: Colors.blue.shade700,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
                SizedBox(height: screenWidth < 600 ? 12 : 16),
              ],
            ),
          ),

          // Map container
          Container(
            width: double.maxFinite,
            height: mapHeight,
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: isLoading
                  ? _buildLoadingState(screenWidth)
                  : error != null
                      ? _buildErrorState(screenWidth)
                      : userOutOfBounds
                          ? _buildOutOfBoundsDialog(screenWidth)
                          : (clinicLocation == null)
                              ? _buildErrorState(screenWidth)
                              : Stack(
                                  children: [
                                    FlutterMap(
                                      mapController: _mapController,
                                      options: MapOptions(
                                        initialCenter: clinicLocation!,
                                        initialZoom: 15,
                                        maxZoom: 19,
                                        minZoom: 12,
                                        cameraConstraint:
                                            CameraConstraint.contain(
                                          bounds: _sjdmBounds,
                                        ),
                                      ),
                                      children: [
                                        TileLayer(
                                          urlTemplate:
                                              "https://{s}.basemaps.cartocdn.com/light_all/{z}/{x}/{y}.png",
                                          subdomains: const [
                                            'a',
                                            'b',
                                            'c',
                                            'd'
                                          ],
                                        ),
                                        if (routePoints.isNotEmpty &&
                                            !showWithoutUserLocation)
                                          PolylineLayer(
                                            polylines: [
                                              Polyline(
                                                points: routePoints,
                                                color: Colors.blue,
                                                strokeWidth: screenWidth < 600
                                                    ? 4.0
                                                    : 5.0,
                                              ),
                                            ],
                                          ),
                                        MarkerLayer(
                                          markers: [
                                            if (userLocation != null &&
                                                !showWithoutUserLocation)
                                              Marker(
                                                point: userLocation!,
                                                width: userMarkerSize,
                                                height: userMarkerSize,
                                                child: Container(
                                                  decoration: BoxDecoration(
                                                    color: Colors.blue,
                                                    shape: BoxShape.circle,
                                                    border: Border.all(
                                                      color: Colors.white,
                                                      width: 2,
                                                    ),
                                                  ),
                                                  child: Icon(
                                                    Icons.my_location,
                                                    color: Colors.white,
                                                    size: getResponsiveIconSize(
                                                        screenWidth, 'user'),
                                                  ),
                                                ),
                                              ),
                                            Marker(
                                              point: clinicLocation!,
                                              width: clinicMarkerSize,
                                              height: clinicMarkerSize + 20,
                                              child: Column(
                                                children: [
                                                  Icon(
                                                    Icons.location_on,
                                                    color: Colors.red.shade600,
                                                    size: getResponsiveIconSize(
                                                        screenWidth, 'clinic'),
                                                  ),
                                                  Container(
                                                    padding:
                                                        EdgeInsets.symmetric(
                                                      horizontal:
                                                          screenWidth < 600
                                                              ? 4
                                                              : 5,
                                                      vertical: 2,
                                                    ),
                                                    decoration: BoxDecoration(
                                                      color: Colors.white,
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                              5),
                                                      boxShadow: [
                                                        BoxShadow(
                                                          color: Colors.black
                                                              .withOpacity(0.2),
                                                          blurRadius: 2,
                                                          offset: const Offset(
                                                              0, 1),
                                                        ),
                                                      ],
                                                    ),
                                                    child: Text(
                                                      widget.clinic.clinicName,
                                                      style: TextStyle(
                                                        fontSize:
                                                            getResponsiveFontSize(
                                                                screenWidth,
                                                                'clinic_label'),
                                                        fontWeight:
                                                            FontWeight.bold,
                                                        color: Colors.black87,
                                                      ),
                                                      overflow:
                                                          TextOverflow.ellipsis,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),

                                    // Info overlay with distance
                                    Positioned(
                                      top: screenWidth < 600 ? 12 : 20,
                                      left: screenWidth < 600 ? 12 : 20,
                                      child: Container(
                                        padding: EdgeInsets.symmetric(
                                          horizontal: overlayPadding,
                                          vertical: overlayPadding - 4,
                                        ),
                                        decoration: BoxDecoration(
                                          color: Colors.white,
                                          borderRadius:
                                              BorderRadius.circular(10),
                                          boxShadow: [
                                            BoxShadow(
                                              color:
                                                  Colors.black.withOpacity(0.1),
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
                                              size: getResponsiveIconSize(
                                                  screenWidth, 'overlay'),
                                            ),
                                            SizedBox(
                                                width:
                                                    screenWidth < 600 ? 4 : 6),
                                            Text(
                                              widget.clinic.clinicName,
                                              style: TextStyle(
                                                fontWeight: FontWeight.w600,
                                                fontSize: getResponsiveFontSize(
                                                    screenWidth,
                                                    'overlay_name'),
                                              ),
                                            ),
                                            if (distanceInKm > 0 &&
                                                !showWithoutUserLocation) ...[
                                              SizedBox(
                                                  width: screenWidth < 600
                                                      ? 6
                                                      : 8),
                                              Container(
                                                padding: EdgeInsets.symmetric(
                                                  horizontal:
                                                      screenWidth < 600 ? 4 : 6,
                                                  vertical: 2,
                                                ),
                                                decoration: BoxDecoration(
                                                  color: Colors.blue.shade50,
                                                  borderRadius:
                                                      BorderRadius.circular(4),
                                                ),
                                                child: Text(
                                                  "${distanceInKm.toStringAsFixed(2)} km",
                                                  style: TextStyle(
                                                    fontSize:
                                                        getResponsiveFontSize(
                                                            screenWidth,
                                                            'overlay_distance'),
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
                                  ],
                                ),
            ),
          ),
        ],
      ),
    );
  }
}
