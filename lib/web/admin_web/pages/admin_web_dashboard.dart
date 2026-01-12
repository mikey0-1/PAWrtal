import 'package:capstone_app/data/repository/auth.repository.dart';
import 'package:capstone_app/utils/logout_helper.dart';
import 'package:capstone_app/utils/user_session_service.dart';
import 'package:capstone_app/data/models/appointment_model.dart';
import 'package:capstone_app/web/admin_web/components/appointments/admin_web_appointment_controller.dart';
import 'package:capstone_app/web/admin_web/components/dashboard/admin_dashboard_controller.dart';
import 'package:capstone_app/web/pages/web_admin_home/web_admin_home_controller.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart';

// Helper class for pending conversation data - MUST BE OUTSIDE THE MAIN CLASS
class PendingConversationData {
  final String? conversationId;
  final String userId;
  final String userName;

  PendingConversationData({
    required this.conversationId,
    required this.userId,
    required this.userName,
  });
}

class AdminWebDashboard extends StatefulWidget {
  const AdminWebDashboard({super.key});

  @override
  State<AdminWebDashboard> createState() => _AdminWebDashboardState();
}

class _AdminWebDashboardState extends State<AdminWebDashboard> {
  late AdminDashboardController controller;
  late WebAdminHomeController permissionController;
  bool _isInitialized = false;

  bool _isLoggingOut = false;

  @override
  void initState() {
    super.initState();
    _initializeController();

    // ✅ NEW: Listen to global logout flag
    ever(LogoutHelper.isLoggingOut, (isLoggingOut) {
      if (mounted && isLoggingOut) {
        setState(() {
          _isLoggingOut = true;
        });
      }
    });
  }

  @override
  void dispose() {
    // CRITICAL: DON'T delete controller on dispose - only on logout
    super.dispose();
  }

  void _initializeController() {
    permissionController = Get.find<WebAdminHomeController>();

    // CRITICAL: Only create controller if it doesn't exist
    if (!Get.isRegistered<AdminDashboardController>()) {
      controller = Get.put(
        AdminDashboardController(
          authRepository: Get.find<AuthRepository>(),
          session: Get.find<UserSessionService>(),
        ),
        permanent: true, // CHANGED: Make it permanent for caching
      );
    } else {
      controller = Get.find<AdminDashboardController>();
    }

    _runMigrationOnce();

    setState(() {
      _isInitialized = true;
    });
  }

  Future<void> _runMigrationOnce() async {
    final storage = GetStorage();
    final migrationRun = storage.read('staff_migration_completed') ?? false;

    if (!migrationRun) {
      try {
        final authRepo = Get.find<AuthRepository>();
        await authRepo.migrateExistingStaffRecords();

        storage.write('staff_migration_completed', true);
      } catch (e) {}
    }
  }

  bool _canAccessFeature(String featureName) {
    return permissionController.canAccessFeature(featureName);
  }

  // NEW: Check if staff has NO permissions at all
  bool _hasNoPermissions() {
    if (permissionController.isAdmin) return false;
    if (permissionController.isStaff) {
      return permissionController.userAuthorities.isEmpty;
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    // ✅ PRIORITY 1: Show loading screen if logging out
    if (_isLoggingOut) {
      return Scaffold(
        backgroundColor: const Color(0xFFF8FAFC),
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

    // ✅ PRIORITY 2: Check if widget is disposed or not initialized
    if (!_isInitialized) {
      return const Scaffold(
        backgroundColor: Color(0xFFF8FAFC),
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    // ✅ PRIORITY 3: Check if NO permissions
    if (_hasNoPermissions()) {
      return _buildNoPermissionsView(context);
    }

    // ✅ PRIORITY 4: Wrap entire build in try-catch
    try {
      // Check if controller exists and is valid
      if (!Get.isRegistered<AdminDashboardController>()) {
        return Scaffold(
          backgroundColor: const Color(0xFFF8FAFC),
          body: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(
                  color: const Color.fromARGB(255, 81, 115, 153),
                ),
                const SizedBox(height: 24),
                Text(
                  'Initializing dashboard...',
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

      // Build normally
      final screenWidth = MediaQuery.of(context).size.width;
      final isMobile = screenWidth < 768;
      final isTablet = screenWidth < 1200 && screenWidth >= 768;

      return Scaffold(
        backgroundColor: const Color(0xFFF8FAFC),
        body: Obx(() {
          // ✅ Check inside Obx too
          if (_isLoggingOut || !Get.isRegistered<AdminDashboardController>()) {
            return const SizedBox.shrink();
          }

          if (controller.isLoading.value) {
            return const Center(child: CircularProgressIndicator());
          }

          return RefreshIndicator(
            onRefresh: () => controller.refreshDashboard(),
            child: SingleChildScrollView(
              padding: EdgeInsets.all(isMobile ? 16 : 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ✅ USE ERROR-SAFE WRAPPERS
                  _buildHeaderWithErrorHandling(controller, isMobile),
                  const SizedBox(height: 24),
                  _buildQuickStatsWithErrorHandling(
                      controller, isMobile, isTablet),
                  const SizedBox(height: 32),
                  // ✅ USE ERROR-SAFE LAYOUT METHODS
                  if (isMobile)
                    _buildMobileLayoutWithErrorHandling(controller)
                  else if (isTablet)
                    _buildTabletLayoutWithErrorHandling(controller)
                  else
                    _buildDesktopLayoutWithErrorHandling(controller),
                ],
              ),
            ),
          );
        }),
      );
    } catch (e) {
      // ✅ Catch ANY error and show blank loading screen
      return Scaffold(
        backgroundColor: const Color(0xFFF8FAFC),
        body: Container(), // Completely blank page
      );
    }
  }

  Widget _buildHeaderWithErrorHandling(
      AdminDashboardController controller, bool isMobile) {
    if (_isLoggingOut) return const SizedBox.shrink();
    try {
      if (!Get.isRegistered<AdminDashboardController>())
        return const SizedBox.shrink();
      return _buildHeader(controller, isMobile);
    } catch (e) {
      return const SizedBox.shrink();
    }
  }

  Widget _buildQuickStatsWithErrorHandling(
      AdminDashboardController controller, bool isMobile, bool isTablet) {
    if (_isLoggingOut) return const SizedBox.shrink();
    try {
      if (!Get.isRegistered<AdminDashboardController>())
        return const SizedBox.shrink();
      if (!Get.isRegistered<WebAppointmentController>())
        return const SizedBox.shrink();
      return _buildQuickStats(controller, isMobile, isTablet);
    } catch (e) {
      return const SizedBox.shrink();
    }
  }

  Widget _buildMobileLayoutWithErrorHandling(
      AdminDashboardController controller) {
    if (_isLoggingOut) return const SizedBox.shrink();
    try {
      if (!Get.isRegistered<AdminDashboardController>())
        return const SizedBox.shrink();
      return _buildMobileLayout(controller);
    } catch (e) {
      return const SizedBox.shrink();
    }
  }

  Widget _buildTabletLayoutWithErrorHandling(
      AdminDashboardController controller) {
    if (_isLoggingOut) return const SizedBox.shrink();
    try {
      if (!Get.isRegistered<AdminDashboardController>())
        return const SizedBox.shrink();
      return _buildTabletLayout(controller);
    } catch (e) {
      return const SizedBox.shrink();
    }
  }

  Widget _buildDesktopLayoutWithErrorHandling(
      AdminDashboardController controller) {
    if (_isLoggingOut) return const SizedBox.shrink();
    try {
      if (!Get.isRegistered<AdminDashboardController>())
        return const SizedBox.shrink();
      return _buildDesktopLayout(controller);
    } catch (e) {
      return const SizedBox.shrink();
    }
  }

  // NEW: Build no permissions view
  Widget _buildNoPermissionsView(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 768;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: Center(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(isMobile ? 24 : 48),
          child: Container(
            constraints: const BoxConstraints(maxWidth: 600),
            child: Card(
              elevation: 8,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              child: Padding(
                padding: EdgeInsets.all(isMobile ? 32 : 48),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Lock Icon
                    Container(
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        color: Colors.orange.shade50,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.lock_outline,
                        size: 60,
                        color: Colors.orange.shade700,
                      ),
                    ),
                    const SizedBox(height: 32),

                    // Title
                    Text(
                      'No Permissions Assigned',
                      style: TextStyle(
                        fontSize: isMobile ? 24 : 28,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey.shade800,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),

                    // Subtitle
                    Text(
                      'You currently don\'t have any permissions to access the dashboard features.',
                      style: TextStyle(
                        fontSize: isMobile ? 16 : 18,
                        color: Colors.grey.shade600,
                        height: 1.5,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 32),

                    // Info Card
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.blue.shade50,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: Colors.blue.shade200,
                          width: 1,
                        ),
                      ),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.info_outline,
                                color: Colors.blue.shade700,
                                size: 24,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  'What can you do?',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.blue.shade900,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          _buildInfoItem(
                            icon: Icons.contact_mail,
                            text:
                                'Contact your administrator to request access',
                            color: Colors.blue,
                          ),
                          const SizedBox(height: 12),
                          _buildInfoItem(
                            icon: Icons.schedule,
                            text:
                                'Check back later after permissions are granted',
                            color: Colors.blue,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInfoItem({
    required IconData icon,
    required String text,
    required MaterialColor color,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          icon,
          size: 20,
          color: color.shade700,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              fontSize: 14,
              color: color.shade900,
              height: 1.4,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildHeader(AdminDashboardController controller, bool isMobile) {
    try {
      if (_isLoggingOut || !Get.isRegistered<WebAppointmentController>()) {
        return const SizedBox.shrink();
      }

      // Get the appointment controller
      final appointmentController = Get.find<WebAppointmentController>();

      return Obx(() {
        // ✅ Double check inside Obx
        if (_isLoggingOut || !Get.isRegistered<WebAppointmentController>()) {
          return const SizedBox.shrink();
        }

        // Get today's count from appointment controller stats
        final todayCount = appointmentController.appointmentStats['today'] ?? 0;

        return Container(
          padding: EdgeInsets.all(isMobile ? 20 : 24),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                const Color.fromARGB(255, 81, 115, 153),
                Colors.blue.shade400,
              ],
            ),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.2),
                spreadRadius: 2,
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.dashboard_rounded,
                        color: Colors.white, size: 32),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          controller.clinicData.value?.clinicName ??
                              'Admin Dashboard',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: isMobile ? 20 : 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          DateFormat('EEEE, MMMM dd, yyyy')
                              .format(DateTime.now()),
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.9),
                            fontSize: isMobile ? 14 : 16,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (!isMobile && _canAccessFeature('appointments')) ...[
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        children: [
                          const Icon(Icons.pets, color: Colors.white, size: 24),
                          const SizedBox(height: 8),
                          Text(
                            '$todayCount',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            "Today's Patients",
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.8),
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        );
      });
    } catch (e) {
      return const SizedBox.shrink();
    }
  }

  Widget _buildQuickStats(
      AdminDashboardController controller, bool isMobile, bool isTablet) {
    // ✅ CRITICAL: Wrap Obx in try-catch
    try {
      if (_isLoggingOut || !Get.isRegistered<WebAppointmentController>()) {
        return const SizedBox.shrink();
      }

      // Get the appointment controller
      final appointmentController = Get.find<WebAppointmentController>();

      return Obx(() {
        // ✅ Double check inside Obx
        if (_isLoggingOut || !Get.isRegistered<WebAppointmentController>()) {
          return const SizedBox.shrink();
        }

        // Get stats from appointment controller
        final stats = appointmentController.appointmentStats;

        final statsList = [
          {
            'title': 'Today\'s Appointments',
            'value': stats['today']?.toString() ?? '0',
            'subtitle': 'Scheduled today',
            'icon': Icons.event_available,
            'color': Colors.blue,
            'permission': 'appointments',
            'onTap': () => _handleNavigateToAppointments('today'),
          },
          {
            'title': 'Pending Appointments',
            'value': stats['pending']?.toString() ?? '0',
            'subtitle': 'Need approval',
            'icon': Icons.pending_actions,
            'color': Colors.orange,
            'permission': 'appointments',
            'onTap': () => _handleNavigateToAppointments('pending'),
          },
          {
            'title': 'Today\'s In Progress',
            'value': stats['in_progress']?.toString() ?? '0',
            'subtitle': 'Currently being treated',
            'icon': Icons.medical_services,
            'color': Colors.purple,
            'permission': 'appointments',
            'onTap': () => _handleNavigateToAppointments('in_progress'),
          },
          {
            'title': 'Today\'s Completed',
            'value': stats['completed']?.toString() ?? '0',
            'subtitle': 'Finished appointments today',
            'icon': Icons.check_circle,
            'color': Colors.green,
            'permission': 'appointments',
            'onTap': () => _handleNavigateToAppointments('completed'),
          },
        ];

        final visibleStats = statsList
            .where((s) => _canAccessFeature(s['permission'] as String))
            .toList();

        if (visibleStats.isEmpty) {
          return const SizedBox.shrink();
        }

        // ... (rest of the existing layout code)
        if (isMobile) {
          return Column(
            children: [
              Row(
                children: [
                  if (visibleStats.isNotEmpty)
                    Expanded(child: _buildStatCard(visibleStats[0])),
                  const SizedBox(width: 12),
                  if (visibleStats.length > 1)
                    Expanded(child: _buildStatCard(visibleStats[1]))
                  else
                    Expanded(child: Container()),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  if (visibleStats.length > 2)
                    Expanded(child: _buildStatCard(visibleStats[2])),
                  const SizedBox(width: 12),
                  if (visibleStats.length > 3)
                    Expanded(child: _buildStatCard(visibleStats[3]))
                  else
                    Expanded(child: Container()),
                ],
              ),
            ],
          );
        } else if (isTablet) {
          return Column(
            children: [
              Row(
                children: [
                  if (visibleStats.isNotEmpty)
                    Expanded(child: _buildStatCard(visibleStats[0])),
                  const SizedBox(width: 16),
                  if (visibleStats.length > 1)
                    Expanded(child: _buildStatCard(visibleStats[1]))
                  else
                    Expanded(child: Container()),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  if (visibleStats.length > 2)
                    Expanded(child: _buildStatCard(visibleStats[2])),
                  const SizedBox(width: 16),
                  if (visibleStats.length > 3)
                    Expanded(child: _buildStatCard(visibleStats[3]))
                  else
                    Expanded(child: Container()),
                ],
              ),
            ],
          );
        } else {
          return Row(
            children: visibleStats.map((stat) {
              return Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(right: 16),
                  child: _buildStatCard(stat),
                ),
              );
            }).toList(),
          );
        }
      });
    } catch (e) {
      return const SizedBox.shrink();
    }
  }

  void _handleNavigateToAppointments(String filter) {
    if (!permissionController.canAccessFeature('appointments')) {
      permissionController.showPermissionDeniedDialog('Appointments');
      return;
    }

    final appointmentsIndex =
        permissionController.navigationLabels.indexOf('Appointments');

    if (appointmentsIndex == -1) {
      return;
    }

    permissionController.setSelectedIndex(appointmentsIndex);
    controller.navigateToAppointments(filter);
  }

  void _handleNavigateToMessagesWithConversation(
    String? conversationId,
    String userId,
    String userName,
  ) {
    if (!permissionController.canAccessFeature('messages')) {
      permissionController.showPermissionDeniedDialog('Messages');
      return;
    }

    final messagesIndex =
        permissionController.navigationLabels.indexOf('Messages');

    if (messagesIndex == -1) {
      return;
    }

    // Store the conversation data to be opened
    Get.put(
      PendingConversationData(
        conversationId: conversationId,
        userId: userId,
        userName: userName,
      ),
      tag: 'pending_conversation',
    );

    // Navigate to messages page
    permissionController.setSelectedIndex(messagesIndex);
  }

  Widget _buildStatCard(Map<String, dynamic> stat) {
    return InkWell(
      onTap: stat['onTap'],
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: stat['color'].withOpacity(0.2)),
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
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: stat['color'].withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(stat['icon'], color: stat['color'], size: 20),
                ),
                const Spacer(),
                Icon(Icons.arrow_forward_ios,
                    size: 16, color: Colors.grey[400]),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              stat['value'],
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: stat['color'],
              ),
            ),
            const SizedBox(height: 4),
            Text(
              stat['title'],
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
            Text(
              stat['subtitle'],
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMobileLayout(AdminDashboardController controller) {
    if (_isLoggingOut || !Get.isRegistered<AdminDashboardController>()) {
      return const SizedBox.shrink();
    }

    try {
      final children = <Widget>[];

      if (_canAccessFeature('appointments')) {
        children
            .add(_buildPendingAppointmentsWithErrorHandling(controller, true));
        children.add(const SizedBox(height: 24));
      }

      if (_canAccessFeature('messages')) {
        children.add(_buildRecentMessagesWithErrorHandling(controller, true));
        children.add(const SizedBox(height: 24));
      }

      if (_canAccessFeature('appointments')) {
        children
            .add(_buildUpcomingAppointmentsWithErrorHandling(controller, true));
      }

      return Column(children: children);
    } catch (e) {
      return const SizedBox.shrink();
    }
  }

  Widget _buildTabletLayout(AdminDashboardController controller) {
    if (_isLoggingOut || !Get.isRegistered<AdminDashboardController>()) {
      return const SizedBox.shrink();
    }

    try {
      final hasAppointments = _canAccessFeature('appointments');
      final hasMessages = _canAccessFeature('messages');
      final children = <Widget>[];

      if (hasAppointments) {
        children
            .add(_buildPendingAppointmentsWithErrorHandling(controller, false));
        children.add(const SizedBox(height: 24));
      }

      final rowChildren = <Widget>[];
      if (hasMessages) {
        rowChildren.add(Expanded(
            child: _buildRecentMessagesWithErrorHandling(controller, false)));
        if (hasAppointments) {
          rowChildren.add(const SizedBox(width: 24));
          rowChildren.add(Expanded(
              child: _buildUpcomingAppointmentsWithErrorHandling(
                  controller, false)));
        }
      } else if (hasAppointments) {
        rowChildren.add(Expanded(
            child: _buildUpcomingAppointmentsWithErrorHandling(
                controller, false)));
      }

      if (rowChildren.isNotEmpty) {
        children.add(Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: rowChildren,
        ));
      }

      return Column(children: children);
    } catch (e) {
      return const SizedBox.shrink();
    }
  }

  Widget _buildDesktopLayout(AdminDashboardController controller) {
    if (_isLoggingOut || !Get.isRegistered<AdminDashboardController>()) {
      return const SizedBox.shrink();
    }

    try {
      final hasAppointments = _canAccessFeature('appointments');
      final hasMessages = _canAccessFeature('messages');
      final children = <Widget>[];

      if (hasAppointments) {
        children.add(Expanded(
          flex: 2,
          child: Column(
            children: [
              _buildPendingAppointmentsWithErrorHandling(controller, false),
              const SizedBox(height: 24),
              _buildUpcomingAppointmentsWithErrorHandling(controller, false),
            ],
          ),
        ));
        children.add(const SizedBox(width: 24));
      }

      if (hasAppointments || hasMessages) {
        final rightChildren = <Widget>[];

        if (hasAppointments) {
          rightChildren
              .add(_buildAppointmentCalendarWithErrorHandling(controller));
          rightChildren.add(const SizedBox(height: 24));
        }

        if (hasMessages) {
          rightChildren
              .add(_buildRecentMessagesWithErrorHandling(controller, false));
        }

        if (rightChildren.isNotEmpty) {
          children.add(Expanded(
            flex: 1,
            child: Column(children: rightChildren),
          ));
        }
      }

      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: children,
      );
    } catch (e) {
      return const SizedBox.shrink();
    }
  }

  Widget _buildPendingAppointments(
      AdminDashboardController controller, bool isMobile) {
    try {
      return _buildDashboardCard(
        title: 'Pending Appointments',
        subtitle: '${controller.todayAppointments.length} awaiting approval',
        icon: Icons.pending_actions,
        child: Obx(() {
          // ✅ Check if logging out inside Obx
          if (_isLoggingOut || !Get.isRegistered<AdminDashboardController>()) {
            return const SizedBox.shrink();
          }

          if (controller.todayAppointments.isEmpty) {
            return _buildEmptyState(
                'No pending appointments', Icons.pending_actions);
          }

          return Column(
            children: controller.todayAppointments.take(5).map((appointment) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _buildAppointmentItem(controller, appointment, isMobile),
              );
            }).toList(),
          );
        }),
        actionLabel: 'View All',
        onAction: () => _handleNavigateToAppointments('pending'),
      );
    } catch (e) {
      return const SizedBox.shrink();
    }
  }

  Widget _buildAppointmentItem(AdminDashboardController controller,
      Appointment appointment, bool isMobile) {
    if (_isLoggingOut || !Get.isRegistered<AdminDashboardController>()) {
      return const SizedBox.shrink();
    }

    try {
      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: _getStatusColor(appointment.status).withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
              color: _getStatusColor(appointment.status).withOpacity(0.3)),
        ),
        child: Column(
          children: [
            Row(
              children: [
                // 🔧 FIXED: Use Obx to observe cached pet images
                Obx(() {
                  // ✅ Check if logging out inside Obx
                  if (_isLoggingOut ||
                      !Get.isRegistered<AdminDashboardController>()) {
                    return const SizedBox.shrink();
                  }

                  final profilePictureUrl =
                      controller.petProfilePictures[appointment.petId];
                  final isLoading =
                      controller.petImageLoadingStates[appointment.petId] ??
                          false;

                  if (isLoading) {
                    return Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(25),
                        color: Colors.grey[200],
                      ),
                      child: Center(
                        child: SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              _getStatusColor(appointment.status),
                            ),
                          ),
                        ),
                      ),
                    );
                  }

                  if (profilePictureUrl != null &&
                      profilePictureUrl.isNotEmpty) {
                    return Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(25),
                        border: Border.all(
                          color: _getStatusColor(appointment.status),
                          width: 2,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.grey.withOpacity(0.3),
                            spreadRadius: 1,
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(25),
                        child: Image.network(
                          profilePictureUrl,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return _buildPetAvatarFallback(appointment.status);
                          },
                          loadingBuilder: (context, child, loadingProgress) {
                            if (loadingProgress == null) return child;
                            return Container(
                              color: Colors.grey[200],
                              child: Center(
                                child: CircularProgressIndicator(
                                  value: loadingProgress.expectedTotalBytes !=
                                          null
                                      ? loadingProgress.cumulativeBytesLoaded /
                                          loadingProgress.expectedTotalBytes!
                                      : null,
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    _getStatusColor(appointment.status),
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    );
                  }

                  return _buildPetAvatarFallback(appointment.status);
                }),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        controller.getPetName(appointment.petId),
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      Text(
                        controller.getOwnerName(appointment.userId),
                        style: TextStyle(color: Colors.grey[600], fontSize: 14),
                      ),
                      Text(
                        appointment.service,
                        style: TextStyle(color: Colors.grey[500], fontSize: 12),
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      DateFormat('hh:mm a').format(appointment.dateTime),
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: _getStatusColor(appointment.status),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        _getStatusDisplayText(appointment.status),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            if (appointment.status == 'pending') ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => controller
                          .confirmQuickDeclineAppointment(appointment),
                      icon: const Icon(Icons.close, size: 16),
                      label: const Text('Decline'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.red,
                        side: const BorderSide(color: Colors.red),
                        padding: const EdgeInsets.symmetric(vertical: 8),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () =>
                          controller.confirmQuickAcceptAppointment(appointment),
                      icon: const Icon(Icons.check, size: 16),
                      label: const Text('Accept'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 8),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      );
    } catch (e) {
      return const SizedBox.shrink();
    }
  }

  // 🆕 ADD THIS HELPER METHOD for fallback avatar
  Widget _buildPetAvatarFallback(String status) {
    return Container(
      width: 50,
      height: 50,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(25),
        gradient: LinearGradient(
          colors: _getStatusGradient(status),
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: const Icon(Icons.pets, color: Colors.white, size: 24),
    );
  }

// 🆕 ADD THIS HELPER METHOD for gradient colors
  List<Color> _getStatusGradient(String status) {
    switch (status) {
      case 'pending':
        return [Colors.orange, Colors.orange.shade300];
      case 'accepted':
        return [Colors.blue, Colors.blue.shade300];
      case 'in_progress':
        return [Colors.purple, Colors.purple.shade300];
      case 'completed':
        return [Colors.green, Colors.green.shade300];
      case 'cancelled':
        return [Colors.grey, Colors.grey.shade300];
      case 'declined':
        return [Colors.red, Colors.red.shade300];
      default:
        return [Colors.grey, Colors.grey.shade300];
    }
  }

  Widget _buildRecentMessages(
      AdminDashboardController controller, bool isMobile) {
    try {
      return _buildDashboardCard(
        title: 'Recent Messages',
        subtitle:
            '${controller.recentMessages.where((m) => m['unreadCount'] > 0).length} unread',
        icon: Icons.message,
        child: Obx(() {
          // ✅ Check if logging out inside Obx
          if (_isLoggingOut || !Get.isRegistered<AdminDashboardController>()) {
            return const SizedBox.shrink();
          }

          if (controller.recentMessages.isEmpty) {
            return _buildEmptyState('No recent messages', Icons.message);
          }

          return Column(
            children: controller.recentMessages.take(3).map((message) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _buildMessageItem(message, isMobile),
              );
            }).toList(),
          );
        }),
        actionLabel: 'View All',
        onAction: () {
          if (!permissionController.canAccessFeature('messages')) {
            permissionController.showPermissionDeniedDialog('Messages');
            return;
          }

          final messagesIndex =
              permissionController.navigationLabels.indexOf('Messages');

          if (messagesIndex == -1) {
            return;
          }

          permissionController.setSelectedIndex(messagesIndex);
        },
      );
    } catch (e) {
      return const SizedBox.shrink();
    }
  }

  Widget _buildMessageItem(Map<String, dynamic> message, bool isMobile) {
    final isUnread = (message['unreadCount'] ?? 0) > 0;

    // Format the time
    final messageTime = message['time'] as DateTime;
    final now = DateTime.now();

    final isToday = messageTime.year == now.year &&
        messageTime.month == now.month &&
        messageTime.day == now.day;

    String timeDisplay;

    if (isToday) {
      final hour = messageTime.hour == 0
          ? 12
          : messageTime.hour > 12
              ? messageTime.hour - 12
              : messageTime.hour;
      final minute = messageTime.minute.toString().padLeft(2, '0');
      final period = messageTime.hour >= 12 ? 'PM' : 'AM';
      timeDisplay = '$hour:$minute $period';
    } else {
      final yesterday = now.subtract(const Duration(days: 1));
      if (messageTime.year == yesterday.year &&
          messageTime.month == yesterday.month &&
          messageTime.day == yesterday.day) {
        timeDisplay = 'Yesterday';
      } else {
        final difference = now.difference(messageTime);
        if (difference.inDays < 7) {
          final days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
          timeDisplay = days[messageTime.weekday - 1];
        } else {
          timeDisplay =
              '${messageTime.month}/${messageTime.day}/${messageTime.year.toString().substring(2)}';
        }
      }
    }

    // Extract conversation ID and user details
    final conversationId = message['conversationId'] as String?;
    final senderId = message['senderId'] as String;
    final senderName = message['senderName'] as String;

    return InkWell(
      onTap: () {
        _handleNavigateToMessagesWithConversation(
          conversationId,
          senderId,
          senderName,
        );
      },
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isUnread
              ? Colors.blue.withOpacity(0.1)
              : Colors.grey.withOpacity(0.05),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isUnread
                ? Colors.blue.withOpacity(0.3)
                : Colors.grey.withOpacity(0.2),
          ),
        ),
        child: Row(
          children: [
            _buildMessageUserAvatar(message),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          senderName,
                          style: TextStyle(
                            fontWeight:
                                isUnread ? FontWeight.bold : FontWeight.w600,
                            fontSize: 14,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Text(
                        timeDisplay,
                        style: TextStyle(
                          color: isUnread ? Colors.blue[700] : Colors.grey[500],
                          fontSize: 12,
                          fontWeight:
                              isUnread ? FontWeight.w600 : FontWeight.normal,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    message['message'] ?? '',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: isUnread ? Colors.black87 : Colors.grey[700],
                      fontSize: 13,
                      fontWeight:
                          isUnread ? FontWeight.w500 : FontWeight.normal,
                    ),
                  ),
                ],
              ),
            ),
            if (isUnread)
              Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                  color: Colors.blue,
                  shape: BoxShape.circle,
                ),
                margin: const EdgeInsets.only(left: 8),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildMessageUserAvatar(Map<String, dynamic> messageData) {
    final hasProfilePicture = messageData['hasProfilePicture'] ?? false;
    final profilePictureUrl = messageData['profilePictureUrl'] ?? '';
    final userName = messageData['senderName'] ?? 'U';

    return Stack(
      children: [
        if (hasProfilePicture && profilePictureUrl.isNotEmpty)
          Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: Colors.grey.shade200,
                width: 2,
              ),
            ),
            child: CircleAvatar(
              radius: 20,
              backgroundColor: Colors.grey[200],
              backgroundImage: NetworkImage(profilePictureUrl),
              onBackgroundImageError: (exception, stackTrace) {},
              child: Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.black.withOpacity(0.0),
                ),
              ),
            ),
          )
        else
          Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: Colors.grey.shade200,
                width: 2,
              ),
            ),
            child: CircleAvatar(
              radius: 20,
              backgroundColor: const Color.fromARGB(255, 81, 115, 153),
              child: Text(
                userName.isNotEmpty ? userName[0].toUpperCase() : 'U',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        Positioned(
          bottom: 0,
          right: 0,
          child: Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(
              color: Colors.grey[400],
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 2),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildUpcomingAppointments(
      AdminDashboardController controller, bool isMobile) {
    try {
      return _buildDashboardCard(
        title: 'Upcoming Appointments',
        subtitle: 'Next ${controller.upcomingAppointments.length} scheduled',
        icon: Icons.schedule,
        child: Obx(() {
          // ✅ Check if logging out inside Obx
          if (_isLoggingOut || !Get.isRegistered<AdminDashboardController>()) {
            return const SizedBox.shrink();
          }

          if (controller.upcomingAppointments.isEmpty) {
            return _buildEmptyState(
                'No upcoming appointments', Icons.event_available);
          }

          return Column(
            children: controller.upcomingAppointments.map((appointment) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _buildUpcomingAppointmentItem(
                    controller, appointment, isMobile),
              );
            }).toList(),
          );
        }),
        actionLabel: 'View All',
        onAction: () => _handleNavigateToAppointments('all'),
      );
    } catch (e) {
      return const SizedBox.shrink();
    }
  }

  Widget _buildUpcomingAppointmentItem(AdminDashboardController controller,
      Appointment appointment, bool isMobile) {
    if (_isLoggingOut || !Get.isRegistered<AdminDashboardController>()) {
      return const SizedBox.shrink();
    }

    try {
      final daysDifference =
          appointment.dateTime.difference(DateTime.now()).inDays;
      final isToday = daysDifference == 0;
      final isTomorrow = daysDifference == 1;

      String dateLabel;
      if (isToday) {
        dateLabel = 'Today';
      } else if (isTomorrow) {
        dateLabel = 'Tomorrow';
      } else {
        dateLabel = DateFormat('MMM dd').format(appointment.dateTime);
      }

      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.green.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.green.withOpacity(0.3)),
        ),
        child: Row(
          children: [
            Container(
              width: 60,
              padding: const EdgeInsets.symmetric(vertical: 8),
              decoration: BoxDecoration(
                color: isToday ? Colors.orange : Colors.green,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                children: [
                  Text(
                    dateLabel,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  Text(
                    DateFormat('hh:mm a').format(appointment.dateTime),
                    style: const TextStyle(
                      fontSize: 10,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Obx(() {
              // ✅ Check if logging out inside Obx
              if (_isLoggingOut ||
                  !Get.isRegistered<AdminDashboardController>()) {
                return const SizedBox.shrink();
              }

              final profilePictureUrl =
                  controller.petProfilePictures[appointment.petId];

              if (profilePictureUrl != null && profilePictureUrl.isNotEmpty) {
                return Container(
                  width: 40,
                  height: 40,
                  margin: const EdgeInsets.only(right: 12),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: Colors.green,
                      width: 2,
                    ),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: Image.network(
                      profilePictureUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          decoration: BoxDecoration(
                            color: Colors.green.shade100,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Icon(
                            Icons.pets,
                            color: Colors.green,
                            size: 20,
                          ),
                        );
                      },
                    ),
                  ),
                );
              }

              return Container(
                width: 40,
                height: 40,
                margin: const EdgeInsets.only(right: 12),
                decoration: BoxDecoration(
                  color: Colors.green.shade100,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: Colors.green,
                    width: 2,
                  ),
                ),
                child: const Icon(
                  Icons.pets,
                  color: Colors.green,
                  size: 20,
                ),
              );
            }),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    controller.getPetName(appointment.petId),
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                  Text(
                    controller.getOwnerName(appointment.userId),
                    style: TextStyle(color: Colors.grey[600], fontSize: 12),
                  ),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.blue.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      appointment.service,
                      style: TextStyle(
                        color: Colors.blue[700],
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    } catch (e) {
      return const SizedBox.shrink();
    }
  }

  Widget _buildAppointmentCalendar(AdminDashboardController controller) {
    if (_isLoggingOut || !Get.isRegistered<AdminDashboardController>()) {
      return const SizedBox.shrink();
    }

    try {
      final today = DateTime.now();
      final todayDate = DateTime(today.year, today.month, today.day);

      return _buildDashboardCard(
        title: 'Appointment Calendar',
        subtitle: 'Monthly overview',
        icon: Icons.calendar_month,
        child: Obx(() {
          // ✅ Check if logging out inside Obx
          if (_isLoggingOut || !Get.isRegistered<AdminDashboardController>()) {
            return const SizedBox.shrink();
          }

          return TableCalendar<Appointment>(
            firstDay: DateTime.utc(2020, 1, 1),
            lastDay: DateTime.utc(2030, 12, 31),
            focusedDay: controller.selectedDate.value,
            calendarFormat: CalendarFormat.month,
            eventLoader: (day) {
              return controller.calendarAppointments[
                      DateTime(day.year, day.month, day.day)] ??
                  [];
            },
            startingDayOfWeek: StartingDayOfWeek.monday,
            calendarStyle: CalendarStyle(
              outsideDaysVisible: false,
              weekendTextStyle: const TextStyle(color: Colors.red),
              todayDecoration: const BoxDecoration(
                color: Color.fromARGB(255, 81, 115, 153),
                shape: BoxShape.circle,
              ),
              selectedDecoration: BoxDecoration(
                color: Colors.blue.shade600,
                shape: BoxShape.circle,
              ),
            ),
            calendarBuilders: CalendarBuilders(
              markerBuilder: (context, date, events) {
                if (events.isEmpty) return const SizedBox.shrink();

                return Positioned(
                  bottom: -2,
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.green.shade400,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      '${events.length}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                );
              },
            ),
            headerStyle: const HeaderStyle(
              formatButtonVisible: false,
              titleCentered: true,
            ),
            onDaySelected: (selectedDay, focusedDay) {
              final selectedDate = DateTime(
                  selectedDay.year, selectedDay.month, selectedDay.day);
              if (!selectedDate.isBefore(todayDate)) {
                controller.setSelectedDate(selectedDay);
              }
            },
            selectedDayPredicate: (day) {
              return isSameDay(controller.selectedDate.value, day);
            },
          );
        }),
      );
    } catch (e) {
      return const SizedBox.shrink();
    }
  }

  Widget _buildDashboardCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required Widget child,
    String? actionLabel,
    VoidCallback? onAction,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color:
                      const Color.fromARGB(255, 81, 115, 153).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  icon,
                  color: const Color.fromARGB(255, 81, 115, 153),
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
              if (actionLabel != null && onAction != null)
                TextButton(
                  onPressed: onAction,
                  child: Text(actionLabel),
                ),
            ],
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }

  Widget _buildEmptyState(String message, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(32),
      child: Column(
        children: [
          Icon(
            icon,
            size: 48,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            message,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'pending':
        return Colors.orange;
      case 'accepted':
        return Colors.blue;
      case 'in_progress':
        return Colors.purple;
      case 'completed':
        return Colors.green;
      case 'cancelled':
        return Colors.grey;
      case 'declined':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  String _getStatusDisplayText(String status) {
    switch (status) {
      case 'pending':
        return 'PENDING';
      case 'accepted':
        return 'SCHEDULED';
      case 'in_progress':
        return 'IN PROGRESS';
      case 'completed':
        return 'COMPLETED';
      case 'cancelled':
        return 'CANCELLED';
      case 'declined':
        return 'DECLINED';
      default:
        return status.toUpperCase();
    }
  }

  // ✅ NEW: Error-safe wrapper for pending appointments
  Widget _buildPendingAppointmentsWithErrorHandling(
      AdminDashboardController controller, bool isMobile) {
    if (_isLoggingOut || !Get.isRegistered<AdminDashboardController>()) {
      return const SizedBox.shrink();
    }

    try {
      return _buildPendingAppointments(controller, isMobile);
    } catch (e) {
      return const SizedBox.shrink();
    }
  }

// ✅ NEW: Error-safe wrapper for recent messages
  Widget _buildRecentMessagesWithErrorHandling(
      AdminDashboardController controller, bool isMobile) {
    if (_isLoggingOut || !Get.isRegistered<AdminDashboardController>()) {
      return const SizedBox.shrink();
    }

    try {
      return _buildRecentMessages(controller, isMobile);
    } catch (e) {
      return const SizedBox.shrink();
    }
  }

// ✅ NEW: Error-safe wrapper for upcoming appointments
  Widget _buildUpcomingAppointmentsWithErrorHandling(
      AdminDashboardController controller, bool isMobile) {
    if (_isLoggingOut || !Get.isRegistered<AdminDashboardController>()) {
      return const SizedBox.shrink();
    }

    try {
      return _buildUpcomingAppointments(controller, isMobile);
    } catch (e) {
      return const SizedBox.shrink();
    }
  }

// ✅ NEW: Error-safe wrapper for appointment calendar
  Widget _buildAppointmentCalendarWithErrorHandling(
      AdminDashboardController controller) {
    if (_isLoggingOut || !Get.isRegistered<AdminDashboardController>()) {
      return const SizedBox.shrink();
    }

    try {
      return _buildAppointmentCalendar(controller);
    } catch (e) {
      return const SizedBox.shrink();
    }
  }
}
