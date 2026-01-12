import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';

// Barangay data model
class Barangay {
  final String name;
  final LatLng coordinates;

  Barangay(this.name, this.coordinates);
}

class AdminPinMapsPage extends StatefulWidget {
  final Function(Map<String, double>) onLocationSelected;
  final Map<String, double>? currentLocation;
  final Function(String)? onAddressChanged; // NEW: Callback for address updates

  const AdminPinMapsPage({
    super.key,
    required this.onLocationSelected,
    this.currentLocation,
    this.onAddressChanged, // NEW
  });

  @override
  State<AdminPinMapsPage> createState() => _AdminPinMapsPageState();
}

class _AdminPinMapsPageState extends State<AdminPinMapsPage> {
  final MapController _mapController = MapController();
  final TextEditingController _barangaySearchController =
      TextEditingController();

  LatLng? userLocation;
  LatLng? selectedLocation;
  bool isLoading = true;
  List<Barangay> filteredBarangays = [];
  bool showDropdown = false;
  Barangay? selectedBarangay;

  final sanJoseDelMonteBounds = LatLngBounds(
    const LatLng(14.7667, 121.0167), // Southwest: 14°46'N, 121°1'E
    const LatLng(14.8667, 121.1667), // Northeast: 14°52'N, 121°10'E
  );

  bool _rayCastIntersect(LatLng point, LatLng vertA, LatLng vertB) {
    double aY = vertA.latitude;
    double bY = vertB.latitude;
    double aX = vertA.longitude;
    double bX = vertB.longitude;
    double pY = point.latitude;
    double pX = point.longitude;

    if ((aY > pY && bY > pY) || (aY < pY && bY < pY) || (aX < pX && bX < pX)) {
      return false;
    }

    double m = (bY - aY) / (bX - aX);
    double bee = (-aX) * m + aY;
    double x = (pY - bee) / m;

    return x > pX;
  }

  // Complete list of SJDM Barangays with approximate coordinates
  // NOTE: These are approximate coordinates distributed across SJDM bounds
  // Replace with actual barangay coordinates for accurate navigation
  final List<Barangay> barangays = [
    // NORTHERN AREA - Sapang Palay District (Upper SJDM)
    // PhilAtlas verified: Sapang Palay is at 14.8390, 121.0429 (NORTHERN, not southern!)
    Barangay('Sapang Palay', const LatLng(14.8390, 121.0429)),

    // NORTHERN AREA - Minuyan District (Uppermost SJDM, near Norzagaray border)
    Barangay('Minuyan', const LatLng(14.8523, 121.0770)), // PhilAtlas verified
    Barangay('Minuyan II',
        const LatLng(14.8349, 121.0922)), // Estimated near Minuyan
    Barangay(
        'Minuyan III', const LatLng(14.8400, 121.1099)), // PhilAtlas verified
    Barangay(
        'Minuyan IV', const LatLng(14.8461, 121.1186)), // PhilAtlas verified
    Barangay('Minuyan V',
        const LatLng(14.8490, 121.0950)), // Estimated between III & IV
    Barangay(
        'Minuyan Proper', const LatLng(14.8428, 121.0787)), // Near main Minuyan

    // NORTHWESTERN AREA (Assumption, Kaypian Area - Upper West)
    Barangay(
        'Assumption', const LatLng(14.8350, 121.0320)), // West of Sapang Palay
    Barangay('Kaypian', const LatLng(14.8300, 121.0280)), // Far northwest
    Barangay('Kaybanban', const LatLng(14.8450, 121.0250)), // Northwest area
    Barangay('Gaya-Gaya', const LatLng(14.8380, 121.0380)), // Near Sapang Palay
    Barangay('Lawang Pari', const LatLng(14.8400, 121.0450)), // Central north
    Barangay('Maharlika',
        const LatLng(14.8420, 121.0520)), // Northeast of Sapang Palay

    // NORTHEASTERN AREA (San Rafael District - Upper East)
    Barangay('San Rafael I', const LatLng(14.8280, 121.0720)), // East area
    Barangay('San Rafael II', const LatLng(14.8310, 121.0750)), // East area
    Barangay('San Rafael III', const LatLng(14.8340, 121.0780)), // East area
    Barangay('San Rafael IV', const LatLng(14.8370, 121.0710)), // East area
    Barangay('San Rafael V', const LatLng(14.8400, 121.0740)), // East area

    // CENTRAL-EAST AREA (Francisco Homes Subdivision)
    Barangay('Francisco Homes - Guijo',
        const LatLng(14.8140, 121.0600)), // PhilAtlas verified
    Barangay('Francisco Homes - Mulawin',
        const LatLng(14.8060, 121.0629)), // PhilAtlas verified
    Barangay('Francisco Homes - Narra',
        const LatLng(14.8099, 121.0585)), // PhilAtlas verified
    Barangay('Francisco Homes - Yakal',
        const LatLng(14.8080, 121.0650)), // Near Narra

    // CENTRAL AREA (Poblacion, City Center - Heart of SJDM)
    Barangay(
        'Poblacion', const LatLng(14.8153, 121.0435)), // PhilAtlas verified
    Barangay(
        'Poblacion I', const LatLng(14.8098, 121.0476)), // PhilAtlas verified
    Barangay(
        'Dulong Bayan', const LatLng(14.8120, 121.0410)), // West of Poblacion
    Barangay('Tungkong Mangga',
        const LatLng(14.8180, 121.0500)), // North of Poblacion

    // CENTRAL-WEST AREA (Gumaoc District)
    Barangay('Gumaoc Central', const LatLng(14.8050, 121.0420)), // Central west
    Barangay('Gumaoc East', const LatLng(14.8070, 121.0450)), // East of central
    Barangay('Gumaoc West', const LatLng(14.8030, 121.0390)), // West area

    // CENTRAL-SOUTH AREA (Fatima District)
    Barangay('Fatima', const LatLng(14.8020, 121.0550)), // Central south
    Barangay('Fatima II', const LatLng(14.7990, 121.0570)), // South of Fatima
    Barangay('Fatima III', const LatLng(14.8040, 121.0590)), // East of Fatima
    Barangay('Fatima IV', const LatLng(14.8060, 121.0620)), // Northeast
    Barangay('Fatima V', const LatLng(14.8010, 121.0610)), // Southeast

    // EASTERN AREA (Santo Niño, Santa Cruz District)
    Barangay('Santo Niño I', const LatLng(14.8150, 121.0680)), // East central
    Barangay('Santo Niño II', const LatLng(14.8170, 121.0710)), // Northeast
    Barangay('Santa Cruz I', const LatLng(14.7980, 121.0700)), // Southeast
    Barangay('Santa Cruz II', const LatLng(14.8000, 121.0730)), // Southeast
    Barangay('Santa Cruz III', const LatLng(14.8030, 121.0760)), // East
    Barangay('Santa Cruz IV', const LatLng(14.8050, 121.0790)), // East
    Barangay('Santa Cruz V', const LatLng(14.8080, 121.0820)), // East

    // SOUTHEASTERN AREA (Paradise, Graceville)
    Barangay('Paradise III', const LatLng(14.7920, 121.0850)), // Far southeast
    Barangay('Graceville', const LatLng(14.7890, 121.0820)), // Southeast
    Barangay('Citrus', const LatLng(14.7950, 121.0780)), // Southeast
    Barangay('Ciudad Real', const LatLng(14.7980, 121.0800)), // Southeast

    // SOUTH-CENTRAL AREA (San Pedro, San Manuel, San Isidro)
    Barangay('San Pedro', const LatLng(14.7870, 121.0520)), // South central
    Barangay('San Manuel', const LatLng(14.7890, 121.0580)), // South central
    Barangay('San Isidro', const LatLng(14.7920, 121.0620)), // South central
    Barangay('San Roque', const LatLng(14.7850, 121.0650)), // South

    // SOUTHWESTERN AREA (San Martin, Santo Cristo District)
    Barangay('San Martin I', const LatLng(14.7830, 121.0480)), // Southwest
    Barangay('San Martin II', const LatLng(14.7800, 121.0510)), // Southwest
    Barangay('San Martin III', const LatLng(14.7860, 121.0540)), // Southwest
    Barangay('San Martin IV', const LatLng(14.7880, 121.0510)), // Southwest
    Barangay('Saint Martin de Porres',
        const LatLng(14.7780, 121.0450)), // Far southwest
    Barangay('Santo Cristo', const LatLng(14.7850, 121.0420)), // Southwest

    // SOUTHERN AREA (Muzon District - Lower SJDM, near Caloocan border)
    // Muzon is actually in the SOUTH, bordering Metro Manila
    Barangay('Muzon Proper', const LatLng(14.7720, 121.0550)), // South
    Barangay('Muzon East', const LatLng(14.7750, 121.0580)), // South
    Barangay('Muzon South',
        const LatLng(14.7680, 121.0530)), // Far south (near Caloocan)
    Barangay('Muzon West', const LatLng(14.7700, 121.0500)), // South

    // CENTRAL-EAST AREA (Bagong Buhay District)
    Barangay('Bagong Buhay I', const LatLng(14.8180, 121.0650)), // Central east
    Barangay(
        'Bagong Buhay II', const LatLng(14.8210, 121.0680)), // Central east
    Barangay(
        'Bagong Buhay III', const LatLng(14.8240, 121.0710)), // Central east
  ];

  final List<LatLng> sjdmPolygonBoundary = const [
    // Start from SOUTHWEST - Muzon area (border with Caloocan City)
    LatLng(14.7680, 121.0480), // Muzon South - southernmost point

    // SOUTH BORDER - Muzon to San Manuel (Caloocan & Quezon City border)
    LatLng(14.7700, 121.0520), // Muzon South boundary
    LatLng(14.7720, 121.0580), // Between Muzon and Gaya-Gaya
    LatLng(14.7750, 121.0650), // Gaya-Gaya/Graceville area
    LatLng(14.7780, 121.0720), // San Manuel area

    // SOUTHEAST CURVE - San Manuel to Ciudad Real (Quezon City border)
    LatLng(14.7820, 121.0800), // Tungkong Mangga south
    LatLng(14.7860, 121.0880), // Ciudad Real west
    LatLng(14.7900, 121.0950), // Ciudad Real center

    // EAST BORDER START - Ciudad Real to Paradise III (Rodriguez, Rizal border)
    LatLng(14.7950, 121.1020), // Ciudad Real east
    LatLng(14.8000, 121.1080), // Paradise III south
    LatLng(14.8050, 121.1140), // Paradise III center

    // EAST BORDER MIDDLE - Paradise III to San Isidro (Rodriguez/Quezon border)
    LatLng(14.8100, 121.1180), // Paradise III north / San Isidro
    LatLng(14.8150, 121.1200), // San Isidro - easternmost point
    LatLng(14.8200, 121.1190), // San Roque east

    // NORTHEAST CURVE - San Roque to Minuyan areas
    LatLng(14.8250, 121.1160), // Kaybanban east
    LatLng(14.8300, 121.1120), // Minuyan II east
    LatLng(14.8350, 121.1080), // Minuyan III east
    LatLng(14.8400, 121.1050), // Minuyan IV east

    // NORTH BORDER START - Minuyan to Citrus (Norzagaray border - conservative)
    LatLng(14.8450, 121.1000), // Minuyan Proper east
    LatLng(14.8480, 121.0920), // Citrus north - avoid disputed areas
    LatLng(14.8500, 121.0850), // Minuyan V north (conservative boundary)

    // NORTH BORDER MIDDLE - Minuyan to Sapang Palay (Norzagaray border)
    LatLng(14.8510, 121.0780), // Santo Nino II north
    LatLng(14.8500, 121.0700), // Bagong Buhay north
    LatLng(14.8480, 121.0620), // San Rafael V north
    LatLng(14.8460, 121.0550), // San Martin de Porres / Lawang Pari
    LatLng(14.8440, 121.0480), // Assumption / Maharlika north

    // NORTHWEST CORNER - Sapang Palay area (Norzagaray border)
    LatLng(14.8420, 121.0410), // Sapang Palay north
    LatLng(14.8390, 121.0350), // Sapang Palay northwest
    LatLng(14.8350, 121.0300), // Gaya-Gaya north / Kaypian

    // WEST BORDER - Kaypian to Dulong Bayan (Santa Maria border)
    LatLng(14.8300, 121.0270), // Kaypian west - westernmost point
    LatLng(14.8250, 121.0290), // Kaybanban west
    LatLng(14.8200, 121.0310), // San Pedro west
    LatLng(14.8150, 121.0330), // Santo Cristo west

    // WEST BORDER SOUTH - Santo Cristo to Muzon (Santa Maria/Marilao border)
    LatLng(14.8100, 121.0350), // Dulong Bayan west
    LatLng(14.8050, 121.0370), // Poblacion west
    LatLng(14.8000, 121.0390), // Gumaoc West
    LatLng(14.7950, 121.0410), // Gaya-Gaya west
    LatLng(14.7900, 121.0430), // Gaya-Gaya southwest
    LatLng(14.7850, 121.0450), // Muzon West
    LatLng(14.7800, 121.0460), // Muzon area
    LatLng(14.7750, 121.0470), // Muzon South area

    // Close polygon - back to start
    LatLng(14.7680, 121.0480), // Muzon South - southernmost point
  ];

  // REPLACE _isWithinBounds with polygon-based checking
  bool _isPointInPolygon(LatLng point, List<LatLng> polygon) {
    int intersectCount = 0;
    for (int i = 0; i < polygon.length - 1; i++) {
      if (_rayCastIntersect(point, polygon[i], polygon[i + 1])) {
        intersectCount++;
      }
    }
    return (intersectCount % 2) == 1; // Odd number of intersections = inside
  }

  @override
  void initState() {
    super.initState();
    filteredBarangays = List.from(barangays);
    _initializeMap();

    // Listen to search text changes
    _barangaySearchController.addListener(_filterBarangays);

    // NEW: Listen to address field changes
    _streetController.addListener(_updateFullAddress);
    _blockController.addListener(_updateFullAddress);
    _buildingController.addListener(_updateFullAddress);
  }

  void _filterBarangays() {
    final query = _barangaySearchController.text.toLowerCase().trim();
    setState(() {
      if (query.isEmpty) {
        filteredBarangays = List.from(barangays);
        showDropdown = false;
      } else {
        filteredBarangays = barangays
            .where((barangay) => barangay.name.toLowerCase().contains(query))
            .toList();
        showDropdown = filteredBarangays.isNotEmpty;
      }
    });
  }

  void _selectBarangay(Barangay barangay) {
    setState(() {
      selectedBarangay = barangay;
      _barangaySearchController.text = barangay.name;
      showDropdown = false;
    });

    // Navigate map to selected barangay with smooth animation
    _mapController.move(barangay.coordinates, 17);

    // Do NOT auto-select the barangay location as clinic location
    // User must manually tap the map to pin their clinic location
  }

  void _clearBarangaySearch() {
    setState(() {
      _barangaySearchController.clear();
      selectedBarangay = null;
      filteredBarangays = List.from(barangays);
      showDropdown = false;
    });
  }

  Future<void> _initializeMap() async {
    await _fetchUserLocation();
    _setInitialLocation();
  }

  Future<void> _fetchUserLocation() async {
    try {
      Position? position = await _getCurrentUserLocation();
      if (position != null) {
        LatLng fetchedLocation = LatLng(position.latitude, position.longitude);

        // STRICT: If user location is outside SJDM polygon, default to city center
        if (!_isWithinBounds(fetchedLocation)) {
          fetchedLocation =
              const LatLng(14.8167, 121.0500); // SJDM City Center (Poblacion)
        }

        if (mounted) {
          setState(() {
            userLocation = fetchedLocation;
          });
        }
      } else {
        if (mounted) {
          setState(() {
            userLocation =
                const LatLng(14.8167, 121.0500); // Default to city center
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          userLocation =
              const LatLng(14.8167, 121.0500); // Default to city center
        });
      }
    }
  }

  void _setInitialLocation() {
    if (widget.currentLocation != null) {
      if (mounted) {
        setState(() {
          selectedLocation = LatLng(
            widget.currentLocation!['lat']!,
            widget.currentLocation!['lng']!,
          );
          isLoading = false;
        });
      }
    } else {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
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

  bool _isWithinBounds(LatLng point) {
    return sanJoseDelMonteBounds.contains(point);
  }

  void _onMapTap(TapPosition tapPosition, LatLng point) {
    if (!_isWithinBounds(point)) {
      _showOutOfBoundsDialog();
      return;
    }

    setState(() {
      selectedLocation = point;
    });

    widget.onLocationSelected({
      'lat': point.latitude,
      'lng': point.longitude,
    });
  }

  void _showOutOfBoundsDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Location Not Available'),
          content: const Text(
            'Please select a location within San Jose del Monte, Bulacan city limits. '
            'Only locations within the official SJDM boundary are allowed.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }

  void _centerToUserLocation() {
    if (userLocation != null) {
      _mapController.move(userLocation!, 15);
    }
  }

  void _clearSelection() {
    setState(() {
      selectedLocation = null;
    });
    widget.onLocationSelected({});
  }

  List<Marker> _getMarkers() {
    final markers = <Marker>[];

    if (userLocation != null) {
      markers.add(
        Marker(
          point: userLocation!,
          width: 40,
          height: 40,
          child: Container(
            decoration: BoxDecoration(
              color: Colors.blue,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 2),
            ),
            child: const Icon(
              Icons.my_location,
              color: Colors.white,
              size: 24,
            ),
          ),
        ),
      );
    }

    if (selectedLocation != null) {
      markers.add(
        Marker(
          point: selectedLocation!,
          width: 110,
          height: 70,
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: Colors.red,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text(
                  'Clinic Location',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(height: 2),
              const Icon(
                Icons.location_on,
                color: Colors.red,
                size: 40,
              ),
            ],
          ),
        ),
      );
    }

    return markers;
  }

  bool _isMobileLayout(double screenWidth) {
    return screenWidth <= 785;
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = _isMobileLayout(screenWidth);

    if (isLoading) {
      return Container(
        height: isMobile ? 300 : 400,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          color: Colors.grey.shade100,
        ),
        child: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Loading map...'),
            ],
          ),
        ),
      );
    }

    if (userLocation == null) {
      return Container(
        height: isMobile ? 300 : 400,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          color: Colors.grey.shade100,
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.location_off,
                  size: isMobile ? 48 : 64, color: Colors.grey),
              const SizedBox(height: 16),
              Text('Unable to load map',
                  style: TextStyle(fontSize: isMobile ? 14 : 16)),
              Text('Please check your internet connection',
                  style: TextStyle(fontSize: isMobile ? 12 : 14)),
            ],
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Barangay search section
        Container(
          decoration: const BoxDecoration(),
          child: _buildBarangaySearchSection(isMobile),
        ),

        const SizedBox(height: 16),

        // Info Container
        _buildInfoContainer(isMobile),

        const SizedBox(height: 16),

        // Map Container
        _buildMapContainer(isMobile),

        // REMOVED: _buildLocationDisplay(isMobile) - No more coordinate display
      ],
    );
  }

  // NEW: Text controllers for detailed address
  final TextEditingController _streetController = TextEditingController();
  final TextEditingController _blockController = TextEditingController();
  final TextEditingController _buildingController = TextEditingController();

  Widget _buildBarangaySearchSection(bool isMobile) {
    return Container(
      padding: EdgeInsets.all(isMobile ? 10 : 12),
      decoration: BoxDecoration(
        color: Colors.green.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.green.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.search_rounded,
                  color: Colors.green, size: isMobile ? 18 : 20),
              SizedBox(width: isMobile ? 6 : 8),
              Expanded(
                child: Text(
                  'Search for your barangay to quickly locate it on the map',
                  style: TextStyle(
                    color: Colors.green,
                    fontSize: isMobile ? 12 : 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          LayoutBuilder(
            builder: (context, constraints) {
              return Column(
                children: [
                  TextField(
                    controller: _barangaySearchController,
                    decoration: InputDecoration(
                      hintText: 'Search barangay (e.g., Poblacion, Muzon)',
                      hintStyle: TextStyle(fontSize: isMobile ? 12 : 13),
                      prefixIcon: const Icon(Icons.location_city, size: 20),
                      suffixIcon: _barangaySearchController.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear, size: 18),
                              onPressed: _clearBarangaySearch,
                            )
                          : null,
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(color: Colors.grey[300]!),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(color: Colors.grey[300]!),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide:
                            const BorderSide(color: Colors.green, width: 2),
                      ),
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: isMobile ? 10 : 12,
                        vertical: isMobile ? 10 : 12,
                      ),
                    ),
                    style: TextStyle(fontSize: isMobile ? 13 : 14),
                    onChanged: (value) {
                      setState(() {});
                    },
                  ),

                  // Dropdown list positioned below TextField
                  if (showDropdown && filteredBarangays.isNotEmpty)
                    Container(
                      margin: const EdgeInsets.only(top: 4),
                      constraints: BoxConstraints(
                        maxHeight: isMobile ? 200 : 250,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.grey[300]!),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Material(
                        color: Colors.transparent,
                        child: ListView.separated(
                          shrinkWrap: true,
                          padding: EdgeInsets.zero,
                          itemCount: filteredBarangays.length,
                          separatorBuilder: (context, index) => Divider(
                            height: 1,
                            color: Colors.grey[200],
                          ),
                          itemBuilder: (context, index) {
                            final barangay = filteredBarangays[index];
                            final query =
                                _barangaySearchController.text.toLowerCase();
                            final barangayName = barangay.name;
                            final matchIndex =
                                barangayName.toLowerCase().indexOf(query);

                            return ListTile(
                              dense: true,
                              leading: Icon(
                                Icons.location_on_outlined,
                                color: Colors.green,
                                size: isMobile ? 18 : 20,
                              ),
                              title: RichText(
                                text: TextSpan(
                                  style: TextStyle(
                                    fontSize: isMobile ? 12 : 13,
                                    fontWeight: FontWeight.w500,
                                    color: Colors.black87,
                                  ),
                                  children: matchIndex >= 0 && query.isNotEmpty
                                      ? [
                                          TextSpan(
                                            text: barangayName.substring(
                                                0, matchIndex),
                                          ),
                                          TextSpan(
                                            text: barangayName.substring(
                                              matchIndex,
                                              matchIndex + query.length,
                                            ),
                                            style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                              color: Colors.green,
                                              backgroundColor:
                                                  Color(0xFFE8F5E9),
                                            ),
                                          ),
                                          TextSpan(
                                            text: barangayName.substring(
                                              matchIndex + query.length,
                                            ),
                                          ),
                                        ]
                                      : [TextSpan(text: barangayName)],
                                ),
                              ),
                              subtitle: Text(
                                _getBarangayAreaDescription(barangay.name),
                                style: TextStyle(
                                  fontSize: isMobile ? 10 : 11,
                                  color: Colors.grey[600],
                                  fontStyle: FontStyle.italic,
                                ),
                              ),
                              onTap: () => _selectBarangay(barangay),
                              hoverColor: Colors.green.withOpacity(0.1),
                            );
                          },
                        ),
                      ),
                    ),

                  // No results message
                  if (showDropdown &&
                      filteredBarangays.isEmpty &&
                      _barangaySearchController.text.isNotEmpty)
                    Container(
                      margin: const EdgeInsets.only(top: 4),
                      padding: EdgeInsets.all(isMobile ? 12 : 16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.grey[300]!),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.search_off,
                            color: Colors.grey,
                            size: isMobile ? 18 : 20,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'No barangay found matching "${_barangaySearchController.text}"',
                              style: TextStyle(
                                fontSize: isMobile ? 12 : 13,
                                color: Colors.grey[600],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              );
            },
          ),

          if (selectedBarangay != null) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(0.2),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Row(
                children: [
                  Icon(Icons.check_circle,
                      color: Colors.green, size: isMobile ? 16 : 18),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      'Map navigated to ${selectedBarangay!.name}. Tap the map to pin your clinic location.',
                      style: TextStyle(
                        fontSize: isMobile ? 11 : 12,
                        color: Colors.green[900],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],

          // NEW: Detailed Address Fields
          const SizedBox(height: 24),
          const Divider(),
          const SizedBox(height: 16),

          Text(
            'Complete Address Details',
            style: TextStyle(
              fontSize: isMobile ? 14 : 16,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 12),

          // Street/Subdivision TextField
          TextField(
            controller: _streetController,
            decoration: InputDecoration(
              labelText: 'Street/Subdivision Name',
              hintText: 'e.g., Main Street, Greenfield Subdivision',
              prefixIcon: const Icon(Icons.route, size: 20),
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: Colors.grey[300]!),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: Colors.grey[300]!),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: Colors.green, width: 2),
              ),
              contentPadding: EdgeInsets.symmetric(
                horizontal: isMobile ? 10 : 12,
                vertical: isMobile ? 10 : 12,
              ),
            ),
            style: TextStyle(fontSize: isMobile ? 13 : 14),
            onChanged: (value) => _updateFullAddress(),
          ),
          const SizedBox(height: 12),

          // Block/Lot Number and Building/Unit in a Row
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _blockController,
                  decoration: InputDecoration(
                    labelText: 'Block/Lot No. (Optional)',
                    hintText: 'e.g., Block 5 Lot 10',
                    prefixIcon: const Icon(Icons.tag, size: 20),
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: Colors.grey[300]!),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: Colors.grey[300]!),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide:
                          const BorderSide(color: Colors.green, width: 2),
                    ),
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: isMobile ? 8 : 10,
                      vertical: isMobile ? 10 : 12,
                    ),
                  ),
                  style: TextStyle(fontSize: isMobile ? 13 : 14),
                  onChanged: (value) => _updateFullAddress(),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextField(
                  controller: _buildingController,
                  decoration: InputDecoration(
                    labelText: 'Building/Unit (Optional)',
                    hintText: 'e.g., Unit 201',
                    prefixIcon: const Icon(Icons.apartment, size: 20),
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: Colors.grey[300]!),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: Colors.grey[300]!),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide:
                          const BorderSide(color: Colors.green, width: 2),
                    ),
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: isMobile ? 8 : 10,
                      vertical: isMobile ? 10 : 12,
                    ),
                  ),
                  style: TextStyle(fontSize: isMobile ? 13 : 14),
                  onChanged: (value) => _updateFullAddress(),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Auto-populated City/Province (Read-only)
          Container(
            padding: EdgeInsets.all(isMobile ? 12 : 14),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey[300]!),
            ),
            child: Row(
              children: [
                Icon(Icons.location_city, size: 20, color: Colors.grey[600]),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'City / Province',
                        style: TextStyle(
                          fontSize: isMobile ? 11 : 12,
                          color: Colors.grey[600],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'San Jose del Monte, Bulacan',
                        style: TextStyle(
                          fontSize: isMobile ? 13 : 14,
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.blue[100],
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    'Auto',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue[700],
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Full Address Preview
          if (_getPreviewAddress().isNotEmpty)
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue[200]!),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.preview, size: 16, color: Colors.blue[700]),
                      const SizedBox(width: 6),
                      Text(
                        'Address Preview:',
                        style: TextStyle(
                          fontSize: isMobile ? 11 : 12,
                          fontWeight: FontWeight.w600,
                          color: Colors.blue[700],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    _getPreviewAddress(),
                    style: TextStyle(
                      fontSize: isMobile ? 12 : 13,
                      color: Colors.black87,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  // NEW: Helper method to build full address string
  String _getPreviewAddress() {
    List<String> addressParts = [];

    // Add building/unit if provided
    if (_buildingController.text.trim().isNotEmpty) {
      addressParts.add(_buildingController.text.trim());
    }

    // Add block/lot if provided
    if (_blockController.text.trim().isNotEmpty) {
      addressParts.add(_blockController.text.trim());
    }

    // Add street if provided
    if (_streetController.text.trim().isNotEmpty) {
      addressParts.add(_streetController.text.trim());
    }

    // Add barangay if selected
    if (selectedBarangay != null) {
      addressParts.add('Brgy. ${selectedBarangay!.name}');
    }

    // Always add city and province
    addressParts.add('San Jose del Monte');
    addressParts.add('Bulacan');

    return addressParts.join(', ');
  }

  // NEW: Method to update full address and notify parent
  void _updateFullAddress() {
    final fullAddress = _getPreviewAddress();
    widget.onAddressChanged?.call(fullAddress);
  }

  @override
  void dispose() {
    _mapController.dispose();
    _barangaySearchController.dispose();
    _streetController.dispose();
    _blockController.dispose();
    _buildingController.dispose();
    super.dispose();
  }

  Widget _buildInfoContainer(bool isMobile) {
    return Container(
      padding: EdgeInsets.all(isMobile ? 10 : 12),
      decoration: BoxDecoration(
        color: Colors.blue.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.blue.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(Icons.info, color: Colors.blue, size: isMobile ? 18 : 20),
          SizedBox(width: isMobile ? 6 : 8),
          Expanded(
            child: Text(
              'Tap on the map to pin your clinic location. Only locations within San Jose del Monte city limits are allowed.',
              style:
                  TextStyle(color: Colors.blue, fontSize: isMobile ? 12 : 13),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMapContainer(bool isMobile) {
    return Container(
      height: isMobile ? 300 : 400,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Stack(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(7),
            child: FlutterMap(
              mapController: _mapController,
              options: MapOptions(
                initialCenter: selectedLocation ?? userLocation!,
                initialZoom: selectedLocation != null ? 17 : 15,
                maxZoom: 19,
                cameraConstraint: CameraConstraint.contain(
                  bounds: sanJoseDelMonteBounds,
                ),
                onTap: _onMapTap,
              ),
              children: [
                TileLayer(
                  urlTemplate:
                      "https://{s}.basemaps.cartocdn.com/light_all/{z}/{x}/{y}.png",
                  subdomains: const ['a', 'b', 'c', 'd'],
                ),
                MarkerLayer(markers: _getMarkers()),
              ],
            ),
          ),
          Positioned(
            top: 10,
            right: 10,
            child: Column(
              children: [
                FloatingActionButton(
                  heroTag: "center",
                  mini: true,
                  backgroundColor: Colors.white,
                  onPressed: _centerToUserLocation,
                  child: const Icon(
                    Icons.my_location,
                    color: Colors.black,
                    size: 20,
                  ),
                ),
                if (selectedLocation != null) ...[
                  const SizedBox(height: 8),
                  FloatingActionButton(
                    heroTag: "clear",
                    mini: true,
                    backgroundColor: Colors.red,
                    onPressed: _clearSelection,
                    child: const Icon(
                      Icons.clear,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  // MODIFIED: This method now returns an empty widget instead of showing coordinates
  Widget _buildLocationDisplay(bool isMobile) {
    return const SizedBox
        .shrink(); // Returns invisible widget - no coordinate display
  }

  String _getBarangayAreaDescription(String barangayName) {
    // NORTHERN DISTRICT - Minuyan Area (Uppermost SJDM, near Norzagaray)
    if ([
      'Minuyan',
      'Minuyan II',
      'Minuyan III',
      'Minuyan IV',
      'Minuyan V',
      'Minuyan Proper'
    ].contains(barangayName)) {}

    // NORTHERN DISTRICT - Sapang Palay Area (Upper SJDM)
    // CRITICAL: Sapang Palay is in the NORTH, verified at 14.8390 latitude
    if (barangayName == 'Sapang Palay') {}

    // NORTHWESTERN AREA
    if ([
      'Assumption',
      'Kaypian',
      'Kaybanban',
      'Gaya-Gaya',
      'Lawang Pari',
      'Maharlika'
    ].contains(barangayName)) {}

    // NORTHEASTERN AREA - San Rafael District
    if (barangayName.startsWith('San Rafael')) {}

    // CENTRAL-EAST - Francisco Homes
    if (barangayName.startsWith('Francisco Homes')) {}

    // CENTRAL DISTRICT - Poblacion/City Center
    if (['Poblacion', 'Poblacion I', 'Dulong Bayan', 'Tungkong Mangga']
        .contains(barangayName)) {}

    // CENTRAL-WEST - Gumaoc District
    if (barangayName.startsWith('Gumaoc')) {}

    // CENTRAL-SOUTH - Fatima District
    if (barangayName.startsWith('Fatima')) {}

    // EASTERN DISTRICT - Santo Niño & Santa Cruz
    if (barangayName.startsWith('Santo Niño') ||
        barangayName.startsWith('Santa Cruz')) {}

    // SOUTHEASTERN - Paradise/Graceville
    if (['Paradise III', 'Graceville', 'Citrus', 'Ciudad Real']
        .contains(barangayName)) {}

    // SOUTH-CENTRAL AREA
    if (['San Pedro', 'San Manuel', 'San Isidro', 'San Roque']
        .contains(barangayName)) {}

    // SOUTHWESTERN - San Martin District
    if (barangayName.startsWith('San Martin') ||
        barangayName.contains('Saint Martin') ||
        barangayName == 'Santo Cristo') {}

    // SOUTHERN DISTRICT - Muzon Area (LOWER SJDM, near Metro Manila)
    // Muzon is actually in the SOUTH, bordering Caloocan City
    if (barangayName.startsWith('Muzon')) {}

    // CENTRAL-EAST - Bagong Buhay
    if (barangayName.startsWith('Bagong Buhay')) {}

    // Default
    return 'San Jose del Monte City, Bulacan';
  }
}
