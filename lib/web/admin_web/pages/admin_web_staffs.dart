import 'dart:ui';

import 'package:capstone_app/utils/snackbar_helper.dart';
import 'package:capstone_app/web/admin_web/components/staffs/staff_full_details.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'dart:typed_data';
import 'package:capstone_app/data/repository/auth.repository.dart';
import 'package:capstone_app/utils/user_session_service.dart';
import 'package:capstone_app/data/models/staff_model.dart' as StaffModel;
import 'package:capstone_app/data/models/clinic_model.dart';
import 'package:capstone_app/web/admin_web/components/staffs/staff_tile.dart';
import 'package:capstone_app/web/admin_web/components/staffs/new_staff_tile.dart';
import 'package:get_storage/get_storage.dart';
import 'package:appwrite/appwrite.dart';

class AdminWebStaffs extends StatefulWidget {
  const AdminWebStaffs({super.key});

  @override
  State<AdminWebStaffs> createState() => _AdminWebStaffsState();
}

class _AdminWebStaffsState extends State<AdminWebStaffs>
    with TickerProviderStateMixin {
  final GetStorage _getStorage = GetStorage();
  final TextEditingController _searchController = TextEditingController();
  final AuthRepository _authRepository = Get.find<AuthRepository>();
  final UserSessionService _session = Get.find<UserSessionService>();

  String? selectedTag;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  Clinic? _clinic;
  List<StaffModel.Staff> staffList = [];
  bool _isLoading = true;

  static const Color primaryBlue = Color(0xFF4A6FA5);
  static const Color primaryTeal = Color(0xFF5B9BD5);
  static const Color lightTeal = Color(0xFF9FC5E8);
  static const Color deepBlue = Color(0xFF2F4F7F);
  static const Color softBlue = Color(0xFF6FA8DC);
  static const Color lightGray = Color(0xFFF3F4F6);
  static const Color mediumGray = Color(0xFF9CA3AF);
  static const Color darkText = Color(0xFF374151);
  static const Color vetGreen = Color(0xFF34D399);
  static const Color vetOrange = Color(0xFFF59E0B);
  static const Color vetPurple = Color(0xFFA855F7);
  static const Color lightVetGreen = Color(0xFFE5F7E5);

  final List<String> tags = const ['Clinic', 'Appointments', 'Messages'];

  DateTime? _lastLoadTime;
  static const Duration _cacheDuration = Duration(minutes: 30);

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeIn,
    );
    _animationController.forward();

    // Don't show loading if we have valid cache
    if (_lastLoadTime != null && _clinic != null && staffList.isNotEmpty) {
      final cacheAge = DateTime.now().difference(_lastLoadTime!);
      if (cacheAge < _cacheDuration) {
        _isLoading = false;
      }
    }

    _initializeData();
  }

  Future<void> _initializeData() async {
    // Check if we have valid cached data
    if (_lastLoadTime != null && _clinic != null && staffList.isNotEmpty) {
      final cacheAge = DateTime.now().difference(_lastLoadTime!);
      if (cacheAge < _cacheDuration) {
        // We have valid cache, don't reload
        setState(() => _isLoading = false);
        return;
      }
    }

    // No valid cache, load data
    await _loadClinicAndStaff();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadClinicAndStaff({bool forceRefresh = false}) async {
    if (!mounted) return;

    // Check cache validity - skip if we have valid cache and not forcing refresh
    if (!forceRefresh && _lastLoadTime != null) {
      final cacheAge = DateTime.now().difference(_lastLoadTime!);
      if (cacheAge < _cacheDuration &&
          _clinic != null &&
          staffList.isNotEmpty) {
        // Cache is still valid, skip loading
        if (mounted) {
          setState(() => _isLoading = false);
        }
        return;
      }
    }

    // Show loading only if we don't have any data
    if (mounted && (_clinic == null || staffList.isEmpty)) {
      setState(() => _isLoading = true);
    }

    try {
      final role = _getStorage.read('role') as String?;
      if (role == 'admin') {
        final clinicDoc =
            await _authRepository.getClinicByAdminId(_session.userId);
        if (clinicDoc != null) {
          _clinic = Clinic.fromMap(clinicDoc.data);
          _clinic!.documentId = clinicDoc.$id;
        }
      } else if (role == 'staff') {
        final clinicId = _getStorage.read('clinicId') as String?;
        if (clinicId != null && clinicId.isNotEmpty) {
          final clinicDoc = await _authRepository.getClinicById(clinicId);
          if (clinicDoc != null) {
            _clinic = Clinic.fromMap(clinicDoc.data);
            _clinic!.documentId = clinicDoc.$id;
          }
        }
      }

      if (_clinic != null) {
        final staff =
            await _authRepository.getClinicStaff(_clinic!.documentId!);
        if (mounted) {
          setState(() {
            staffList = staff;
            _lastLoadTime = DateTime.now(); // Update cache timestamp
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        Get.snackbar(
          'Error',
          'Failed to load staff: $e',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red,
          colorText: Colors.white,
        );
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _addNewStaff(
    String name,
    String username,
    String email,
    String phone,
    List<String> authorities,
    Uint8List? imageBytes,
    String password,
    bool isDoctor,
  ) async {
    if (_clinic == null || !mounted) return;

    try {
      String imageUrl = '';

      if (imageBytes != null && imageBytes.isNotEmpty) {
        try {
          final inputFile = InputFile.fromBytes(
            bytes: imageBytes,
            filename: "${DateTime.now().millisecondsSinceEpoch}_staff.jpg",
          );
          final uploadedImage = await _authRepository.uploadImage(inputFile);
          imageUrl = _authRepository.getImageUrl(uploadedImage.$id);
        } catch (e) {
          if (mounted) {
            Get.snackbar(
              'Warning',
              'Failed to upload image, continuing without photo.',
              snackPosition: SnackPosition.BOTTOM,
              backgroundColor: vetOrange,
              colorText: Colors.white,
              duration: const Duration(seconds: 3),
            );
          }
        }
      }

      final result = await _authRepository.createStaffAccount(
        name: name,
        username: username,
        password: password,
        clinicId: _clinic!.documentId!,
        authorities: authorities,
        createdBy: _session.userId,
        image: imageUrl,
        phone: phone,
        email: email,
        isDoctor: isDoctor,
      );

      if (result['success'] == true) {
        // Force refresh to get new data
        await _loadClinicAndStaff(forceRefresh: true);
        if (mounted) {
          SnackbarHelper.showSuccess(
            context: Get.context!,
            title: "Success",
            message:
                "Staff account created successfully! $name has been added.${isDoctor ? ' (Licensed Veterinarian)' : ''}",
          );
        }
      }
    } catch (e) {
      if (mounted) {
        Get.snackbar(
          'Error',
          'Failed to create staff: $e',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red,
          colorText: Colors.white,
          duration: const Duration(seconds: 5),
        );
      }
    }
  }

  Future<void> _updateStaffAuthorities(
      StaffModel.Staff staff, List<String> newAuthorities) async {
    if (!mounted) return;

    try {
      await _authRepository.updateStaffAuthorities(
        staff.documentId!,
        newAuthorities,
      );
      // Force refresh to get updated data
      await _loadClinicAndStaff(forceRefresh: true);

      if (mounted) {
        // Success feedback (currently commented out in your code)
      }
    } catch (e) {
      if (mounted) {
        Get.snackbar(
          'Error',
          'Failed to update permissions: $e',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red,
          colorText: Colors.white,
        );
      }
    }
  }

  Future<void> _removeStaff(StaffModel.Staff staff) async {
    if (!mounted) return;

    try {
      await _authRepository.deactivateStaffAccount(
        staff.documentId!,
        staff.userId,
      );

      // Force refresh to get updated data
      await _loadClinicAndStaff(forceRefresh: true);

      if (mounted) {
        // Success feedback (currently commented out in your code)
      }
    } catch (e) {
      if (mounted) {
        Get.snackbar(
          'Error',
          'Failed to remove staff: $e',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red,
          colorText: Colors.white,
        );
      }
    }
  }

  List<StaffModel.Staff> get filteredStaffs {
    final query = _searchController.text.trim().toLowerCase();
    return staffList.where((staff) {
      final matchesSearch = query.isEmpty ||
          staff.name.toLowerCase().contains(query) ||
          staff.username.toLowerCase().contains(query);
      final matchesTag =
          selectedTag == null || staff.authorities.contains(selectedTag);
      return matchesSearch && matchesTag;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isLarge = screenWidth > 1200;
    final isMedium = screenWidth > 768;
    final isSmall = screenWidth <= 768;

    if (_isLoading) {
      return const Scaffold(
        backgroundColor: lightGray,
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_clinic == null) {
      return const Scaffold(
        backgroundColor: lightGray,
        body: Center(
          child: Text('Clinic not found. Please contact support.'),
        ),
      );
    }

    return Scaffold(
      backgroundColor: lightGray,
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: Column(
          children: [
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Colors.white,
                    lightVetGreen.withOpacity(0.3),
                    Colors.white
                  ],
                ),
                boxShadow: [
                  BoxShadow(
                    color: primaryTeal.withOpacity(0.15),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                    spreadRadius: 1,
                  ),
                ],
              ),
              child: Column(
                children: [
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: isMedium ? 24 : 16,
                      vertical: isSmall ? 16 : 20,
                    ),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          primaryBlue.withOpacity(0.08),
                          primaryTeal.withOpacity(0.12),
                          softBlue.withOpacity(0.06),
                        ],
                      ),
                    ),
                    child: _buildTitleSection(isLarge, isMedium, isSmall),
                  ),
                  LayoutBuilder(
                    builder: (context, cons) {
                      final w = cons.maxWidth;
                      final wideHeader = w >= 1100;
                      return Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: isMedium ? 24 : 16,
                          vertical: 18,
                        ),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.white.withOpacity(0.8),
                              lightGray.withOpacity(0.5)
                            ],
                          ),
                        ),
                        child: wideHeader
                            ? Row(
                                children: [
                                  Expanded(child: _buildFilterTags()),
                                  const SizedBox(width: 20),
                                  ConstrainedBox(
                                    constraints: const BoxConstraints(
                                        maxWidth: 420, minWidth: 280),
                                    child: _buildSearchBar(),
                                  ),
                                ],
                              )
                            : Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _buildFilterTags(),
                                  const SizedBox(height: 12),
                                  _buildSearchBar(fullWidth: true),
                                ],
                              ),
                      );
                    },
                  ),
                ],
              ),
            ),
            Expanded(
              child: Container(
                color: lightGray,
                child: Padding(
                  padding: EdgeInsets.all(isMedium ? 24 : 16),
                  child: filteredStaffs.isEmpty &&
                          _searchController.text.isNotEmpty
                      ? _buildEmptyState()
                      : _buildStaffGrid(isSmall, isMedium, isLarge),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTitleSection(bool isLarge, bool isMedium, bool isSmall) {
    if (!isMedium) {
      return Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  primaryTeal.withOpacity(0.2),
                  primaryBlue.withOpacity(0.15)
                ],
              ),
              borderRadius: BorderRadius.circular(12),
              border:
                  Border.all(color: primaryTeal.withOpacity(0.3), width: 1.5),
            ),
            child:
                const Icon(Icons.group_rounded, color: primaryTeal, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: ShaderMask(
              shaderCallback: (bounds) => const LinearGradient(
                      colors: [darkText, deepBlue, primaryTeal])
                  .createShader(bounds),
              blendMode: BlendMode.srcIn,
              child: Text(
                'Staff Management',
                style: TextStyle(
                  fontSize: isSmall ? 18 : 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  primaryBlue.withOpacity(0.1),
                  softBlue.withOpacity(0.05)
                ],
              ),
              borderRadius: BorderRadius.circular(12),
              border:
                  Border.all(color: primaryBlue.withOpacity(0.3), width: 1.5),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Total Staff',
                  style: TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.w600,
                    color: primaryBlue,
                  ),
                ),
                const SizedBox(height: 2),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.people_rounded,
                        color: primaryBlue, size: 14),
                    const SizedBox(width: 4),
                    Text(
                      staffList.length.toString(),
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: primaryBlue,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      );
    } else {
      return Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  primaryTeal.withOpacity(0.2),
                  primaryBlue.withOpacity(0.15)
                ],
              ),
              borderRadius: BorderRadius.circular(16),
              border:
                  Border.all(color: primaryTeal.withOpacity(0.3), width: 1.5),
            ),
            child:
                const Icon(Icons.group_rounded, color: primaryTeal, size: 26),
          ),
          const SizedBox(width: 18),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ShaderMask(
                  shaderCallback: (bounds) => const LinearGradient(
                          colors: [darkText, deepBlue, primaryTeal])
                      .createShader(bounds),
                  blendMode: BlendMode.srcIn,
                  child: const Text(
                    'Staff Management',
                    style: TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                        color: Colors.white),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Manage ${_clinic?.clinicName ?? "your clinic"}\'s staff and permissions',
                  style: const TextStyle(
                      fontSize: 15,
                      color: mediumGray,
                      fontWeight: FontWeight.w500),
                ),
              ],
            ),
          ),
          _buildStatCard('Total Staff', staffList.length.toString(),
              Icons.people_rounded, const [primaryBlue, softBlue]),
        ],
      );
    }
  }

  Widget _buildFilterTags() {
    final scrollController = ScrollController();

    return ScrollConfiguration(
      behavior: ScrollConfiguration.of(context).copyWith(
        dragDevices: {
          PointerDeviceKind.touch,
          PointerDeviceKind.mouse,
        },
        scrollbars: false,
      ),
      child: SingleChildScrollView(
        controller: scrollController,
        scrollDirection: Axis.horizontal,
        physics: const ClampingScrollPhysics(),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    primaryTeal.withOpacity(0.1),
                    primaryBlue.withOpacity(0.08)
                  ],
                ),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: primaryTeal.withOpacity(0.2)),
              ),
              child: const Text(
                'Filter by permission',
                style: TextStyle(
                    fontSize: 14, color: darkText, fontWeight: FontWeight.w600),
              ),
            ),
            const SizedBox(width: 16),
            ...tags.map((tag) {
              final bool isSelected = tag == selectedTag;
              IconData icon;
              List<Color> colors;

              switch (tag) {
                case 'Clinic':
                  icon = Icons.local_hospital_rounded;
                  colors = const [primaryTeal, primaryBlue];
                  break;
                case 'Appointments':
                  icon = Icons.calendar_month_rounded;
                  colors = const [primaryBlue, softBlue];
                  break;
                case 'Messages':
                  icon = Icons.message_rounded;
                  colors = const [vetOrange, primaryTeal];
                  break;
                default:
                  icon = Icons.check_circle;
                  colors = const [mediumGray, mediumGray];
              }

              return Padding(
                padding: const EdgeInsets.only(right: 10),
                child: GestureDetector(
                  onTap: () =>
                      setState(() => selectedTag = isSelected ? null : tag),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 10),
                    decoration: BoxDecoration(
                      gradient: isSelected
                          ? LinearGradient(colors: colors)
                          : LinearGradient(
                              colors: [
                                colors.first.withOpacity(0.1),
                                colors.last.withOpacity(0.05)
                              ],
                            ),
                      borderRadius: BorderRadius.circular(25),
                      border: Border.all(
                        color: isSelected
                            ? colors.first
                            : colors.first.withOpacity(0.3),
                        width: 2,
                      ),
                      boxShadow: isSelected
                          ? [
                              BoxShadow(
                                color: colors.first.withOpacity(0.3),
                                blurRadius: 8,
                                offset: const Offset(0, 3),
                              ),
                            ]
                          : null,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(icon,
                            size: 18,
                            color: isSelected ? Colors.white : colors.first),
                        const SizedBox(width: 8),
                        Text(
                          tag,
                          style: TextStyle(
                            color: isSelected ? Colors.white : colors.first,
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }),
            if (selectedTag != null)
              IconButton(
                onPressed: () => setState(() => selectedTag = null),
                tooltip: 'Clear filter',
                icon: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: const BoxDecoration(
                      color: Color(0x1AFF0000), shape: BoxShape.circle),
                  child: Icon(Icons.clear, size: 16, color: Colors.red[600]),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchBar({bool fullWidth = false}) {
    final isMedium = MediaQuery.of(context).size.width > 768;

    return SizedBox(
      width: fullWidth ? double.infinity : (isMedium ? 320 : double.infinity),
      height: 48,
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Colors.white, lightVetGreen.withOpacity(0.3)],
          ),
          borderRadius: BorderRadius.circular(30),
          border: Border.all(color: primaryTeal.withOpacity(0.3), width: 2),
          boxShadow: [
            BoxShadow(
              color: primaryTeal.withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: TextField(
          controller: _searchController,
          onChanged: (_) => setState(() {}),
          decoration: InputDecoration(
            hintText: 'Search staff by name or username...',
            hintStyle:
                TextStyle(fontSize: 15, color: mediumGray.withOpacity(0.8)),
            prefixIcon: Container(
              margin: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    primaryTeal.withOpacity(0.2),
                    primaryBlue.withOpacity(0.1)
                  ],
                ),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.search_rounded,
                  size: 20, color: primaryTeal),
            ),
            suffixIcon: _searchController.text.isNotEmpty
                ? IconButton(
                    onPressed: () {
                      _searchController.clear();
                      setState(() {});
                    },
                    icon: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: Colors.grey.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child:
                          const Icon(Icons.clear, size: 16, color: mediumGray),
                    ),
                  )
                : null,
            border: InputBorder.none,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          ),
        ),
      ),
    );
  }

  Widget _buildStatCard(
      String label, String value, IconData icon, List<Color> colors) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            colors.first.withOpacity(0.15),
            colors.last.withOpacity(0.08)
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colors.first.withOpacity(0.3), width: 2),
        boxShadow: [
          BoxShadow(
            color: colors.first.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
                gradient: LinearGradient(colors: colors),
                shape: BoxShape.circle),
            child: Icon(icon, color: Colors.white, size: 22),
          ),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              ShaderMask(
                shaderCallback: (bounds) =>
                    LinearGradient(colors: colors).createShader(bounds),
                blendMode: BlendMode.srcIn,
                child: Text(
                  value,
                  style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.white),
                ),
              ),
              Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  color: colors.first.withOpacity(0.9),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: primaryTeal.withOpacity(0.1),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: const Icon(Icons.search_off_rounded,
                size: 72, color: mediumGray),
          ),
          const SizedBox(height: 20),
          const Text(
            'No staff found',
            style: TextStyle(
                fontSize: 20, fontWeight: FontWeight.w700, color: darkText),
          ),
          const SizedBox(height: 10),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 32),
            child: Text(
              'No staff members match your search criteria.\nTry adjusting your search or filters.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 15, color: mediumGray, height: 1.5),
            ),
          ),
          const SizedBox(height: 28),
          ElevatedButton.icon(
            onPressed: () {
              _searchController.clear();
              setState(() => selectedTag = null);
            },
            icon: const Icon(Icons.clear_all_rounded, color: Colors.white),
            label: const Text('Clear Filters',
                style: TextStyle(color: Colors.white)),
            style: ElevatedButton.styleFrom(
              backgroundColor: primaryBlue,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStaffGrid(bool isSmall, bool isMedium, bool isLarge) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final double w = constraints.maxWidth;
        final double spacing = isSmall ? 12.0 : 20.0;

        int cols;
        if (isSmall) {
          cols = 3;
        } else if (w >= 1600) {
          cols = 8;
        } else if (w >= 1400) {
          cols = 7;
        } else if (w >= 1200) {
          cols = 6;
        } else if (w >= 1000) {
          cols = 5;
        } else if (w >= 820) {
          cols = 4;
        } else if (w >= 620) {
          cols = 3;
        } else {
          cols = 2;
        }

        final double tileWidth = (w - (cols - 1) * spacing) / cols;
        final double baseRatio = (cols <= 2) ? 0.66 : (isSmall ? 0.75 : 0.62);

        final double minH;
        if (isSmall) {
          minH = 160;
        } else {
          minH = (cols <= 1)
              ? 340
              : (cols == 2)
                  ? 300
                  : (cols == 3)
                      ? 260
                      : (cols == 4)
                          ? 250
                          : (cols == 5)
                              ? 240
                              : (cols == 6)
                                  ? 230
                                  : (cols == 7)
                                      ? 220
                                      : 210;
        }

        int maxChips = 0;
        for (final s in filteredStaffs) {
          if (s.authorities.length > maxChips) maxChips = s.authorities.length;
        }

        final double chipW = isSmall ? 70.0 : 96.0;
        final double chipGap = isSmall ? 4.0 : 8.0;
        final double innerW = tileWidth - (isSmall ? 24.0 : 48.0);
        final double chipsTotalW =
            maxChips > 0 ? (maxChips * chipW + (maxChips - 1) * chipGap) : 0.0;
        final int chipLines =
            (chipsTotalW > 0 && innerW > 0) ? (chipsTotalW / innerW).ceil() : 1;
        final double extraForWrap = isSmall
            ? (chipLines > 1)
                ? (chipLines - 1) * 20.0
                : 0.0
            : (chipLines > 1)
                ? (chipLines - 1) * 30.0
                : 0.0;

        double finalHeight = tileWidth / baseRatio;
        if (finalHeight < minH) finalHeight = minH;
        finalHeight += extraForWrap + (isSmall ? 2 : 6);

        final double finalRatio = tileWidth / finalHeight;

        final totalItems = 1 + filteredStaffs.length;

        return GridView.builder(
          itemCount: totalItems,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: cols,
            crossAxisSpacing: spacing,
            mainAxisSpacing: spacing,
            childAspectRatio: finalRatio,
          ),
          itemBuilder: (context, index) {
            if (index == 0) {
              return NewStaffTile(
                onStaffCreated: _addNewStaff,
              );
            }

            final staffIndex = index - 1;
            final staff = filteredStaffs[staffIndex];

            return isSmall
                ? _buildMobileStaffTile(staff)
                : StaffTile(
                    staff: staff,
                    onUpdate: (authorities) =>
                        _updateStaffAuthorities(staff, authorities),
                    onRemove: () => _removeStaff(staff),
                  );
          },
        );
      },
    );
  }

  Widget _buildMobileStaffTile(StaffModel.Staff staff) {
    return Material(
      elevation: 2.0,
      borderRadius: BorderRadius.circular(16),
      shadowColor: primaryTeal.withOpacity(0.15),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () {
          showDialog(
            context: context,
            builder: (_) => StaffFullDetails(
              staffName: staff.name,
              username: staff.username,
              phone: staff.phone,
              email: staff.email,
              initialAuthorities: staff.authorities,
              onAuthoritiesUpdated: (authorities) =>
                  _updateStaffAuthorities(staff, authorities),
              onRemove: () => _removeStaff(staff),
              imageBytes: null,
              staffDocumentId: staff.documentId!,
              currentImageUrl: staff.image.isNotEmpty ? staff.image : null,
            ),
          );
        },
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: primaryTeal.withOpacity(0.2), width: 1.5),
          ),
          padding: const EdgeInsets.all(10),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Profile Image
              Stack(
                children: [
                  Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: staff.image.isEmpty
                          ? LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                primaryTeal.withOpacity(0.15),
                                primaryBlue.withOpacity(0.1),
                              ],
                            )
                          : null,
                      border: Border.all(
                        color: primaryTeal.withOpacity(0.4),
                        width: 1.5,
                      ),
                      image: staff.image.isNotEmpty
                          ? DecorationImage(
                              image: NetworkImage(staff.image),
                              fit: BoxFit.cover,
                            )
                          : null,
                    ),
                    child: staff.image.isEmpty
                        ? const Icon(Icons.person, size: 24, color: primaryTeal)
                        : null,
                  ),
                  if (staff.authorities.isNotEmpty)
                    Positioned(
                      bottom: -2,
                      right: -2,
                      child: Container(
                        width: 20,
                        height: 20,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [vetGreen, primaryTeal],
                          ),
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2),
                        ),
                        child: Center(
                          child: Text(
                            '${staff.authorities.length}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 9,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 6),

              // Name
              Text(
                staff.name,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 11,
                  color: darkText,
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 6),

              // Permissions with containers
              if (staff.authorities.isNotEmpty)
                Flexible(
                  child: Container(
                    width: double.infinity,
                    padding:
                        const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          lightGray,
                          lightVetGreen.withOpacity(0.2),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: primaryTeal.withOpacity(0.2)),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Padding(
                          padding: EdgeInsets.only(bottom: 4),
                          child: Text(
                            'Permissions',
                            style: TextStyle(
                              fontSize: 8,
                              color: mediumGray,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        ...staff.authorities.map((auth) {
                          IconData icon;
                          List<Color> colors;
                          switch (auth) {
                            case 'Clinic':
                              icon = Icons.local_hospital;
                              colors = [primaryTeal, primaryBlue];
                              break;
                            case 'Appointments':
                              icon = Icons.calendar_month;
                              colors = [primaryBlue, softBlue];
                              break;
                            case 'Messages':
                              icon = Icons.message;
                              colors = [vetOrange, primaryTeal];
                              break;
                            default:
                              icon = Icons.check_circle;
                              colors = [mediumGray, mediumGray];
                          }

                          return Padding(
                            padding: const EdgeInsets.only(bottom: 3),
                            child: Container(
                              width: double.infinity,
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 6, vertical: 3),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    colors.first.withOpacity(0.2),
                                    colors.last.withOpacity(0.1),
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(
                                    color: colors.first.withOpacity(0.3)),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(icon, size: 9, color: colors.first),
                                  const SizedBox(width: 3),
                                  Flexible(
                                    child: Text(
                                      auth,
                                      style: TextStyle(
                                        fontSize: 8,
                                        color: colors.first,
                                        fontWeight: FontWeight.w700,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        }).toList(),
                      ],
                    ),
                  ),
                )
              else
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Text(
                    'No permissions',
                    style: TextStyle(
                      fontSize: 9,
                      color: Colors.grey[500],
                      fontStyle: FontStyle.italic,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
