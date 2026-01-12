import 'package:capstone_app/data/repository/auth.repository.dart';
import 'package:capstone_app/utils/logout_helper.dart';
import 'package:capstone_app/utils/snackbar_helper.dart';
import 'package:capstone_app/utils/user_session_service.dart';
import 'package:capstone_app/web/admin_web/components/appointments/appointment_view_mode.dart';
import 'package:capstone_app/web/admin_web/components/appointments/admin_web_appointment_controller.dart';
import 'package:capstone_app/web/admin_web/components/appointments/web_appointment_stats.dart';
import 'package:capstone_app/web/admin_web/components/appointments/web_appointment_tile.dart';
import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

class AdminWebAppointments extends StatefulWidget {
  const AdminWebAppointments({super.key});

  @override
  State<AdminWebAppointments> createState() => _AdminWebAppointmentsState();
}

class _AdminWebAppointmentsState extends State<AdminWebAppointments>
    with TickerProviderStateMixin {
  late TabController _tabController;
  late TabController _mobileTabController;
  late TextEditingController _searchController;
  late ScrollController _statsScrollController;

  WebAppointmentController? _controller;
  bool _isDisposed = false;
  String? _initError;

  // ✅ NEW: Add logout flag
  bool _isLoggingOut = false;

  final List<Tab> _tabs = const [
    Tab(text: 'Pending'),
    Tab(text: 'Scheduled'),
    Tab(text: 'In Progress'),
    Tab(text: 'Completed'),
    Tab(text: 'Cancelled'),
    Tab(text: 'Declined'),
  ];

  final List<String> _tabValues = [
    'pending',
    'scheduled',
    'in_progress',
    'completed',
    'cancelled',
    'declined',
  ];

  @override
  void initState() {
    super.initState();

    // Initialize UI controllers
    _tabController = TabController(length: _tabs.length, vsync: this);
    _mobileTabController = TabController(length: _tabs.length, vsync: this);
    _searchController = TextEditingController();
    _statsScrollController = ScrollController();

    // Add listeners
    _tabController.addListener(_onTabControllerChanged);
    _mobileTabController.addListener(_onMobileTabControllerChanged);

    // ✅ Listen to global logout flag (YOUR EXISTING FIX)
    ever(LogoutHelper.isLoggingOut, (isLoggingOut) {
      if (mounted && isLoggingOut) {
        setState(() {
          _isLoggingOut = true;
        });
      }
    });

    // Initialize controller
    _initializeControllerSync();

    // Sync tab controllers with saved state
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_controller != null && Get.isRegistered<WebAppointmentController>()) {
        _controller!
            .syncTabControllerWithState(_tabController, _mobileTabController);
        _controller!.updateFilteredAppointments();
      }
    });
  }

  void _initializeControllerSync() {
    if (_isDisposed) return;

    try {
      // CRITICAL FIX: Check if controller exists AND is still valid
      if (Get.isRegistered<WebAppointmentController>()) {
        try {
          _controller = Get.find<WebAppointmentController>();

          // CRITICAL: Verify the controller is actually functional
          // by checking if it has clinic data initialized
          if (_controller!.clinicData.value != null) {
            _initError = null;
            return;
          } else {
            // Delete the stale controller
            Get.delete<WebAppointmentController>(force: true);
            _controller = null;
          }
        } catch (e) {
          // Try to delete the broken controller
          try {
            Get.delete<WebAppointmentController>(force: true);
          } catch (deleteError) {}
          _controller = null;
        }
      } else {}

      // Verify dependencies exist
      if (!Get.isRegistered<AuthRepository>()) {
        throw Exception('AuthRepository not found in GetX');
      }

      if (!Get.isRegistered<UserSessionService>()) {
        throw Exception('UserSessionService not found in GetX');
      }

      // Get dependencies
      final authRepository = Get.find<AuthRepository>();
      final session = Get.find<UserSessionService>();

      // Create controller instance
      _controller = WebAppointmentController(
        authRepository: authRepository,
        session: session,
      );

      // Register with GetX IMMEDIATELY (synchronously)
      Get.put<WebAppointmentController>(_controller!, permanent: true);

      _initError = null;

      // NOW fetch data asynchronously (after registration)
      Future.microtask(() async {
        try {
          await _controller!.fetchClinicData();
        } catch (e) {
          if (mounted) {
            setState(() {
              _initError = 'Failed to load data: $e';
            });
          }
        }
      });
    } catch (e, stackTrace) {
      _initError = e.toString();
      _controller = null;

      // Show error to user
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          Get.snackbar(
            'Initialization Error',
            'Failed to initialize appointments: $e',
            backgroundColor: Colors.red,
            colorText: Colors.white,
            duration: const Duration(seconds: 5),
          );
        }
      });
    }
  }

  void _onTabControllerChanged() {
    // ✅ Add _isLoggingOut check to your existing safety checks
    if (_isDisposed || _isLoggingOut || _tabController.indexIsChanging) return;

    if (_controller == null || !Get.isRegistered<WebAppointmentController>()) {
      return;
    }

    try {
      final tabValues = [
        'pending',
        'scheduled',
        'in_progress',
        'completed',
        'cancelled',
        'declined',
      ];

      final currentIndex = _tabController.index;
      if (currentIndex >= 0 && currentIndex < tabValues.length) {
        _controller!.setSelectedTab(tabValues[currentIndex]);
      }
    } catch (e) {
    }
  }

  void _onMobileTabControllerChanged() {
    // ✅ Add _isLoggingOut check to your existing safety checks
    if (_isDisposed || _isLoggingOut || _mobileTabController.indexIsChanging)
      return;

    if (_controller == null || !Get.isRegistered<WebAppointmentController>()) {
      return;
    }

    try {
      final tabValues = [
        'pending',
        'scheduled',
        'in_progress',
        'completed',
        'cancelled',
        'declined',
      ];

      final currentIndex = _mobileTabController.index;
      if (currentIndex >= 0 && currentIndex < tabValues.length) {
        _controller!.setSelectedTab(tabValues[currentIndex]);
      }
    } catch (e) {
    }
  }

  @override
  void dispose() {

    _isDisposed = true;

    // Remove listeners safely
    try {
      _tabController.removeListener(_onTabControllerChanged);
      _mobileTabController.removeListener(_onMobileTabControllerChanged);
    } catch (e) {
    }

    // Dispose controllers safely
    try {
      _tabController.dispose();
      _mobileTabController.dispose();
      _searchController.dispose();
      _statsScrollController.dispose();
    } catch (e) {
    }

    // ✅ CRITICAL: Don't touch the WebAppointmentController
    // LogoutHelper.logout() handles its cleanup
    // Just null the local reference
    _controller = null;

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // ✅ PRIORITY 1: Show loading screen if logging out
    if (_isLoggingOut) {
      return Scaffold(
        backgroundColor: const Color.fromARGB(255, 245, 245, 245),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(
                color: const Color.fromARGB(255, 81, 115, 153),
              ),
              const SizedBox(height: 24),
              Text(
                'Logging out...',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        ),
      );
    }

    // ✅ PRIORITY 2: Check if widget is disposed
    if (_isDisposed) {
      return Scaffold(
        backgroundColor: const Color.fromARGB(255, 245, 245, 245),
        body: Container(), // Blank page
      );
    }

    // ✅ PRIORITY 3: Handle initialization errors
    if (_initError != null) {
      return Scaffold(
        backgroundColor: const Color.fromARGB(255, 245, 245, 245),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(32.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.error_outline,
                  size: 80,
                  color: Colors.red[400],
                ),
                const SizedBox(height: 24),
                const Text(
                  'Failed to Load Appointments',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                Text(
                  _initError!,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),
                ElevatedButton.icon(
                  onPressed: _handleLogout, // ✅ Use new logout handler
                  icon: const Icon(Icons.logout),
                  label: const Text('Logout and Try Again'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color.fromARGB(255, 81, 115, 153),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 16,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    // ✅ PRIORITY 4: Wrap entire build in try-catch
    try {
      // Check if controller exists and is valid
      if (_controller == null ||
          !Get.isRegistered<WebAppointmentController>()) {
        return Scaffold(
          backgroundColor: const Color.fromARGB(255, 245, 245, 245),
          body: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(
                  color: const Color.fromARGB(255, 81, 115, 153),
                ),
                const SizedBox(height: 24),
                Text(
                  'Initializing appointments...',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
        );
      }

      // Build normally (rest of your existing build code)
      final screenWidth = MediaQuery.of(context).size.width;
      final isMobile = screenWidth < 768;
      final isTablet = screenWidth < 1200 && screenWidth >= 768;

      return Scaffold(
        backgroundColor: const Color.fromARGB(255, 245, 245, 245),
        body: Column(
          children: [
            if (!isMobile) _buildStatsWithErrorHandling(),
            if (isMobile) _buildMobileStatsWithErrorHandling(),
            _buildSearchAndFilterBarWithErrorHandling(isMobile, isTablet),
            _buildTabBarWithErrorHandling(isMobile, isTablet),
            Expanded(
              child: _buildTabContentWithErrorHandling(isMobile),
            ),
          ],
        ),
      );
    } catch (e) {
      // ✅ Catch ANY error and show blank loading screen
      return Scaffold(
        backgroundColor: const Color.fromARGB(255, 245, 245, 245),
        body: Container(), // Completely blank page
      );
    }
  }

  Widget _buildStatsWithErrorHandling() {
    if (_isLoggingOut) return const SizedBox.shrink();
    try {
      if (_controller == null) return const SizedBox.shrink();
      return const WebAppointmentStats();
    } catch (e) {
      return const SizedBox.shrink();
    }
  }

  Widget _buildMobileStatsWithErrorHandling() {
    if (_isLoggingOut) return const SizedBox.shrink();
    try {
      if (_controller == null) return const SizedBox.shrink();
      return _buildMobileStats();
    } catch (e) {
      return const SizedBox.shrink();
    }
  }

  Widget _buildSearchAndFilterBarWithErrorHandling(
      bool isMobile, bool isTablet) {
    if (_isLoggingOut) return const SizedBox.shrink();
    try {
      if (_controller == null) return const SizedBox.shrink();
      return _buildSearchAndFilterBar(isMobile, isTablet);
    } catch (e) {
      return const SizedBox.shrink();
    }
  }

  Widget _buildTabBarWithErrorHandling(bool isMobile, bool isTablet) {
    if (_isLoggingOut) return const SizedBox.shrink();
    try {
      if (_controller == null) return const SizedBox.shrink();
      return _buildTabBar(isMobile, isTablet);
    } catch (e) {
      return const SizedBox.shrink();
    }
  }

  Widget _buildTabContentWithErrorHandling(bool isMobile) {
    if (_isLoggingOut) return const SizedBox.shrink();
    try {
      if (_controller == null) {
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(
                color: const Color.fromARGB(255, 81, 115, 153),
              ),
              const SizedBox(height: 24),
              Text(
                'Loading appointments...',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        );
      }
      return _buildTabContent(isMobile);
    } catch (e) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.refresh, size: 48, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'Loading...',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      );
    }
  }

  void _setLoggingOut(bool value) {
    if (mounted) {
      setState(() {
        _isLoggingOut = value;
      });
    }
  }

  Widget _buildMobileStats() {
    if (_controller == null) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ✅ Wrap Obx in try-catch to prevent errors during logout
          Builder(
            builder: (context) {
              try {
                if (_isLoggingOut || _controller == null) {
                  return const SizedBox.shrink();
                }

                return Obx(() {
                  // Double check inside Obx
                  if (_isLoggingOut || _controller == null) {
                    return const SizedBox.shrink();
                  }

                  return Container(
                    padding: const EdgeInsets.only(
                        left: 24, right: 24, top: 10, bottom: 10),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          const Color.fromARGB(255, 81, 115, 153),
                          Colors.blue.shade400,
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.withOpacity(0.15),
                          spreadRadius: 1,
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        // ... rest of your existing mobile stats UI
                        Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    DateFormat('EEEE, MMMM dd, yyyy')
                                        .format(DateTime.now()),
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  const Text(
                                    "Appointments",
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    _controller!.selectedCalendarDate.value !=
                                            null
                                        ? "Showing: ${DateFormat('MMM dd, yyyy').format(_controller!.selectedCalendarDate.value!)}"
                                        : "${_controller!.appointmentStats['today']} today",
                                    style: TextStyle(
                                      color: Colors.white.withOpacity(0.9),
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(
                                    Icons.calendar_today,
                                    color: Colors.white,
                                    size: 16,
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    '${_controller!.appointmentStats['total']}',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  Text(
                                    _controller!.viewMode.value.label,
                                    style: TextStyle(
                                      color: Colors.white.withOpacity(0.8),
                                      fontSize: 8,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        // ... rest of your view mode buttons and filters
                      ],
                    ),
                  );
                });
              } catch (e) {
                return const SizedBox.shrink();
              }
            },
          ),
          // ... rest of your stat cards
        ],
      ),
    );
  }

  Widget _buildMobileStatCard(
      String title, int value, IconData icon, Color color) {
    return Container(
      width: 110,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.2)),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.08),
            spreadRadius: 1,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Icon(icon, color: color, size: 16),
              ),
              const SizedBox(width: 8),
              Text(
                value.toString(),
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            title,
            style: TextStyle(
              fontSize: 10,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildSearchAndFilterBar(bool isMobile, bool isTablet) {
    if (_controller == null) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 3,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: isMobile ? _buildMobileSearchBar() : _buildDesktopSearchBar(),
    );
  }

  Widget _buildMobileSearchBar() {
    return Row(
      children: [
        Expanded(
          flex: 3,
          child: TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Search...',
              prefixIcon: const Icon(Icons.search, size: 18),
              suffixIcon: _searchController.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear, size: 18),
                      onPressed: () {
                        _searchController.clear();
                        _controller?.setSearchQuery('');
                      },
                      iconSize: 18,
                    )
                  : null,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide.none,
              ),
              filled: true,
              fillColor: Colors.grey[100],
              contentPadding:
                  const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
              hintStyle: const TextStyle(fontSize: 12),
              isDense: true,
            ),
            style: const TextStyle(fontSize: 12),
            onChanged: (value) => _controller?.setSearchQuery(value),
          ),
        ),
        const SizedBox(width: 6),
        InkWell(
          onTap: () => _showDatePicker(),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey[300]!),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.date_range, size: 18, color: Colors.grey),
          ),
        ),
        const SizedBox(width: 6),
        InkWell(
          onTap: () => _controller?.refreshAppointments(),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey[300]!),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.refresh, size: 18, color: Colors.grey),
          ),
        ),
      ],
    );
  }

  Widget _buildDesktopSearchBar() {
    return Row(
      children: [
        Expanded(
          flex: 3,
          child: TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Search by pet name, owner, or service...',
              prefixIcon: const Icon(Icons.search, size: 20),
              suffixIcon: _searchController.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear, size: 20),
                      onPressed: () {
                        _searchController.clear();
                        _controller?.setSearchQuery('');
                      },
                    )
                  : null,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide.none,
              ),
              filled: true,
              fillColor: Colors.grey[100],
              contentPadding:
                  const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
              isDense: true,
            ),
            onChanged: (value) => _controller?.setSearchQuery(value),
          ),
        ),
        const SizedBox(width: 10),
        OutlinedButton.icon(
          onPressed: () => _showCalendarPicker(),
          icon: const Icon(Icons.calendar_today, size: 14),
          label: Obx(() => Text(
                _controller!.selectedCalendarDate.value != null
                    ? DateFormat('MMM dd, yyyy')
                        .format(_controller!.selectedCalendarDate.value!)
                    : 'Select Date',
                style: const TextStyle(fontSize: 10),
              )),
          style: OutlinedButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            minimumSize: const Size(0, 32),
          ),
        ),
        const SizedBox(width: 10),
        OutlinedButton.icon(
          onPressed: () => _controller?.refreshAppointments(),
          icon: const Icon(Icons.refresh, size: 14),
          label: const Text('Refresh', style: TextStyle(fontSize: 10)),
          style: OutlinedButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            minimumSize: const Size(0, 32),
          ),
        ),
        const SizedBox(width: 10),
        Obx(() => Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: const Color.fromARGB(255, 81, 115, 153).withOpacity(0.1),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                '${_controller!.filteredAppointments.length} results',
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 10,
                  color: Color.fromARGB(255, 81, 115, 153),
                ),
              ),
            )),
      ],
    );
  }

  Widget _buildTabBar(bool isMobile, bool isTablet) {
    if (_controller == null) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Builder(
        builder: (context) {
          try {
            if (_isLoggingOut || _controller == null) {
              return const SizedBox.shrink();
            }

            return Obx(() {
              // Double check inside Obx
              if (_isLoggingOut || _controller == null) {
                return const SizedBox.shrink();
              }

              final stats = _controller!.appointmentStats;
              final tabCtrl = isMobile ? _mobileTabController : _tabController;

              return LayoutBuilder(
                builder: (context, constraints) {
                  final needsScroll = constraints.maxWidth < 1000;

                  return ScrollConfiguration(
                    behavior: ScrollConfiguration.of(context).copyWith(
                      dragDevices: {
                        PointerDeviceKind.touch,
                        PointerDeviceKind.mouse,
                      },
                      scrollbars: false,
                    ),
                    child: TabBar(
                      controller: tabCtrl,
                      isScrollable: needsScroll || isTablet || isMobile,
                      tabAlignment: (needsScroll || isTablet || isMobile)
                          ? TabAlignment.center
                          : null,
                      labelColor: Colors.white,
                      unselectedLabelColor:
                          const Color.fromARGB(255, 81, 115, 153),
                      indicatorColor: Colors.transparent,
                      dividerColor: Colors.transparent,
                      indicator: BoxDecoration(
                        color: const Color.fromARGB(255, 81, 115, 153),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      tabs: [
                        if (isMobile) ...[
                          _buildMobileTab(
                              'Pending', stats['pending'] ?? 0, Icons.pending),
                          _buildMobileTab('Scheduled', stats['scheduled'] ?? 0,
                              Icons.schedule),
                          _buildMobileTab(
                              'In Progress',
                              stats['in_progress'] ?? 0,
                              Icons.medical_services),
                          _buildMobileTab('Completed', stats['completed'] ?? 0,
                              Icons.check_circle),
                          _buildMobileTab('Cancelled', stats['cancelled'] ?? 0,
                              Icons.cancel),
                          _buildMobileTab('Declined', stats['declined'] ?? 0,
                              Icons.cancel_outlined),
                        ] else ...[
                          _buildTab(
                              'Pending', stats['pending'] ?? 0, Icons.pending),
                          _buildTab('Scheduled', stats['scheduled'] ?? 0,
                              Icons.schedule),
                          _buildTab('In Progress', stats['in_progress'] ?? 0,
                              Icons.medical_services),
                          _buildTab('Completed', stats['completed'] ?? 0,
                              Icons.check_circle),
                          _buildTab('Cancelled', stats['cancelled'] ?? 0,
                              Icons.cancel),
                          _buildTab('Declined', stats['declined'] ?? 0,
                              Icons.cancel_outlined),
                        ],
                      ],
                    ),
                  );
                },
              );
            });
          } catch (e) {
            return const SizedBox.shrink();
          }
        },
      ),
    );
  }

  Widget _buildMobileTab(String text, int count, IconData icon) {
    return Tab(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14),
            const SizedBox(width: 4),
            Text(text, style: const TextStyle(fontSize: 11)),
            if (count > 0) ...[
              const SizedBox(width: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                decoration: BoxDecoration(
                  color: _getTabCountColor(text),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  count.toString(),
                  style: const TextStyle(
                    fontSize: 8,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildTab(String text, int count, IconData icon) {
    return Tab(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 18),
            const SizedBox(width: 6),
            Text(text, style: const TextStyle(fontSize: 13)),
            if (count > 0) ...[
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: _getTabCountColor(text),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  count.toString(),
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildTabContent(bool isMobile) {
    if (_controller == null) return const SizedBox.shrink();

    final tabCtrl = isMobile ? _mobileTabController : _tabController;

    return TabBarView(
      controller: tabCtrl,
      children: _tabValues.map((tabValue) {
        return Builder(
          builder: (context) {
            try {
              if (_isLoggingOut || _controller == null) {
                return const SizedBox.shrink();
              }

              return Obx(() {
                // Double check inside Obx
                if (_isLoggingOut || _controller == null) {
                  return const SizedBox.shrink();
                }

                if (_controller!.isLoading.value) {
                  return const Center(child: CircularProgressIndicator());
                }

                final appointments = _controller!.filteredAppointments;

                if (appointments.isEmpty) {
                  return _buildEmptyState(tabValue);
                }

                return RefreshIndicator(
                  onRefresh: () => _controller!.refreshAppointments(),
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    itemCount: appointments.length,
                    itemBuilder: (context, index) {
                      final appointment = appointments[index];
                      return WebAppointmentTile(
                        appointment: appointment,
                        isSelected: false,
                      );
                    },
                  ),
                );
              });
            } catch (e) {
              return const SizedBox.shrink();
            }
          },
        );
      }).toList(),
    );
  }

  Widget _buildAppointmentsList(String tabValue, bool isMobile) {
    return Obx(() {
      if (_controller!.isLoading.value) {
        return const Center(child: CircularProgressIndicator());
      }

      final appointments = _controller!.filteredAppointments;

      if (appointments.isEmpty) {
        return _buildEmptyState(tabValue);
      }

      return RefreshIndicator(
        onRefresh: () => _controller!.refreshAppointments(),
        child: ListView.builder(
          padding: const EdgeInsets.symmetric(vertical: 8),
          itemCount: appointments.length,
          itemBuilder: (context, index) {
            final appointment = appointments[index];
            return WebAppointmentTile(
              appointment: appointment,
              isSelected: false,
            );
          },
        ),
      );
    });
  }

  Widget _buildEmptyState(String tabValue) {
    IconData icon;
    String title;
    String subtitle;

    switch (tabValue) {
      case 'pending':
        icon = Icons.pending_actions;
        title = 'No Pending Appointments';
        subtitle = 'All caught up! No pending appointments to review.';
        break;
      case 'scheduled':
        icon = Icons.schedule;
        title = 'No Scheduled Appointments';
        subtitle = 'Accepted appointments will appear here.';
        break;
      case 'in_progress':
        icon = Icons.medical_services_outlined;
        title = 'No Active Treatments';
        subtitle = 'Patients currently receiving treatment will appear here.';
        break;
      case 'completed':
        icon = Icons.check_circle_outline;
        title = 'No Completed Services';
        subtitle = 'Completed treatments will appear here.';
        break;
      case 'cancelled':
        icon = Icons.event_busy;
        title = 'No Cancelled Appointments';
        subtitle = 'User-cancelled appointments will appear here.';
        break;
      case 'declined':
        icon = Icons.cancel_outlined;
        title = 'No Declined Appointments';
        subtitle = 'Appointments you declined will appear here.';
        break;
      default:
        icon = Icons.help_outline;
        title = 'No Data';
        subtitle = 'No appointments found.';
    }

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            size: 80,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            title,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Text(
              subtitle,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[500],
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }

  void _showDatePicker() async {
    if (_controller == null) return;

    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _controller!.selectedCalendarDate.value ?? DateTime.now(),
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );

    if (picked != null) {
      _controller!.setCalendarDate(picked);

      // Show feedback to user
      if (mounted && Get.context != null) {
        SnackbarHelper.showSuccess(
          context: Get.context!,
          title: "Date Filter Applied",
          message:
              "Showing appointments for ${DateFormat('MMM dd, yyyy').format(picked)}",
        );
      }
    }
  }

  void _showCalendarPicker() async {
    if (_controller == null) return;

    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _controller!.selectedCalendarDate.value ?? DateTime.now(),
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );

    if (picked != null) {
      _controller!.setCalendarDate(picked);

      // Show feedback to user
      if (mounted && Get.context != null) {
        SnackbarHelper.showSuccess(
          context: Get.context!,
          title: "Date Filter Applied",
          message:
              "Showing appointments for ${DateFormat('MMM dd, yyyy').format(picked)}",
        );
      }
    }
  }

  Color _getTabCountColor(String tabName) {
    switch (tabName) {
      case 'Pending':
        return Colors.orange;
      case 'Scheduled':
        return Colors.green;
      case 'In Progress':
        return Colors.purple;
      case 'Completed':
        return Colors.teal;
      case 'Cancelled':
        return Colors.grey;
      case 'Declined':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  Future<void> _handleLogout() async {
    // Step 1: Set logging out flag IMMEDIATELY
    _setLoggingOut(true);

    try {
      // Step 2: Wait for UI to rebuild with loading screen
      await Future.delayed(const Duration(milliseconds: 100));

      // Step 3: Cleanup controller properly
      if (_controller != null && Get.isRegistered<WebAppointmentController>()) {
        try {
          // Call cleanup method
          _controller!.cleanupOnLogout();

          // Wait for cleanup to complete
          await Future.delayed(const Duration(milliseconds: 50));

          // Now delete the controller
          Get.delete<WebAppointmentController>(force: true);

        } catch (e) {
        }
      }

      // Step 4: Clear local reference
      _controller = null;

      // Step 5: Wait a bit before actual logout
      await Future.delayed(const Duration(milliseconds: 50));

      // Step 6: Perform actual logout
      await LogoutHelper.logout();
    } catch (e) {

      // Fallback: Force logout even if cleanup fails
      await LogoutHelper.logout();
    }
  }
}
