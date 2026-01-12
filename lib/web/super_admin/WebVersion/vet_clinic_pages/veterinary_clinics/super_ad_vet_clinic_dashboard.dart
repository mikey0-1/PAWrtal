import 'package:capstone_app/data/models/clinic_model.dart';
import 'package:capstone_app/data/models/clinic_settings_model.dart';
import 'package:capstone_app/web/super_admin/WebVersion/vet_clinic_pages/archive_clinics/archived_clinics_dashboard.dart';
import 'package:capstone_app/web/super_admin/WebVersion/vet_clinic_pages/veterinary_clinics/super_ad_vet_clinic_detail_page.dart';
import 'package:capstone_app/web/super_admin/WebVersion/vet_clinic_requests/vet_clinic_requests_dashboard.dart';
import 'package:capstone_app/web/super_admin/desktop/super_admin_desktop_home_page.dart';
import 'package:capstone_app/web/super_admin/WebVersion/vet_clinic_pages/sa_dashboard_components/sa_sort_button.dart';
import 'package:capstone_app/web/super_admin/WebVersion/vet_clinic_pages/sa_dashboard_components/sa_search_bar.dart';
import 'package:capstone_app/web/super_admin/WebVersion/vet_clinic_pages/sa_dashboard_components/sa_vet_clinic_dash_tile.dart';
import 'package:capstone_app/web/super_admin/WebVersion/vet_clinic_pages/veterinary_clinics/super_ad_vet_clinic_register.dart';
import 'package:capstone_app/web/super_admin/mobile/super_admin_mobile_home_page.dart';
import 'package:capstone_app/web/super_admin/tablet/super_admin_tablet_home_page.dart';
import 'package:capstone_app/web/dimensions.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:capstone_app/pages/super_admin_home/super_admin_home_controller.dart';
import 'dart:async';
import 'package:capstone_app/web/super_admin/WebVersion/view_report/user_app_feedback/app_feedback.dart';
import 'package:capstone_app/web/super_admin/WebVersion/view_report/user_vet_feedback/vet_deletion_reports.dart';
import 'package:capstone_app/web/super_admin/WebVersion/pet_owners_pages/user_page.dart';
import 'package:capstone_app/utils/logout_helper.dart';

class SuperAdminVetClinicDashboard extends StatefulWidget {
  const SuperAdminVetClinicDashboard({super.key});

  @override
  State<SuperAdminVetClinicDashboard> createState() =>
      _SuperAdminVetClinicDashboardState();
}

class _SuperAdminVetClinicDashboardState
    extends State<SuperAdminVetClinicDashboard>
    with SingleTickerProviderStateMixin {
  final SuperAdminHomeController controller = SuperAdminHomeController.instance;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  bool _isLoggingOut = false;

  StreamSubscription? _clinicSubscription;
  StreamSubscription? _settingsSubscription;

  late AnimationController _fabAnimationController;
  late Animation<double> _fabScaleAnimation;
  late DashboardResponsive _responsive;

  @override
  void initState() {
    super.initState();
    _setupRealtimeListeners();
    _setupAnimations();

    Future.delayed(const Duration(seconds: 1), () {
      if (mounted) {
        controller.debugDashboardPictures();
      }
    });
  }

  void _setupAnimations() {
    _fabAnimationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _fabScaleAnimation = CurvedAnimation(
      parent: _fabAnimationController,
      curve: Curves.easeOutBack,
    );
    _fabAnimationController.forward();
  }

  @override
  void dispose() {
    _clinicSubscription?.cancel();
    _settingsSubscription?.cancel();
    _fabAnimationController.dispose();
    super.dispose();
  }

  void _setupRealtimeListeners() {
    _clinicSubscription =
        controller.authRepository.subscribeToClinicChanges().listen((event) {
      final eventType = event.events.first;

      if (eventType.contains('.create')) {
        _showRealTimeNotification(
          'New clinic added',
          Icons.add_business_rounded,
          Colors.green,
        );
        controller.fetchAllClinics();
      } else if (eventType.contains('.update')) {
        controller.fetchAllClinics();
      } else if (eventType.contains('.delete')) {
        _showRealTimeNotification(
          'Clinic removed',
          Icons.delete_rounded,
          Colors.red,
        );
        controller.fetchAllClinics();
      }
    }, onError: (error) {});

    _settingsSubscription = controller.authRepository
        .subscribeToClinicSettingsChanges()
        .listen((event) {
      final eventType = event.events.first;

      if (eventType.contains('.update')) {
        final clinicId = event.payload['clinicId'] as String?;

        if (clinicId != null) {
          _showRealTimeNotification(
            'Clinic settings updated',
            Icons.settings_rounded,
            Colors.orange,
          );
          controller.fetchAllClinics();
        }
      } else if (eventType.contains('.create')) {
        controller.fetchAllClinics();
      }
    }, onError: (error) {});
  }

  void _showRealTimeNotification(String message, IconData icon, Color color) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Container(
          padding: EdgeInsets.symmetric(vertical: _responsive.scale(8)),
          child: Row(
            children: [
              Container(
                padding: EdgeInsets.all(_responsive.scale(10)),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: color, size: _responsive.scale(22)),
              ),
              SizedBox(width: _responsive.scale(16)),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Status Update',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: _responsive.scale(13),
                        color: Colors.white,
                      ),
                    ),
                    SizedBox(height: _responsive.scale(2)),
                    Text(
                      message,
                      style: TextStyle(
                        fontSize: _responsive.scale(12),
                        color: Colors.white.withOpacity(0.9),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: EdgeInsets.all(_responsive.scale(6)),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.wifi_tethering_rounded,
                  color: Colors.white,
                  size: _responsive.scale(16),
                ),
              ),
            ],
          ),
        ),
        backgroundColor: const Color.fromRGBO(81, 115, 153, 0.95),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(_responsive.scale(16)),
        ),
        margin: EdgeInsets.all(_responsive.scale(16)),
        duration: const Duration(seconds: 3),
        elevation: 8,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    _responsive = DashboardResponsive(context);

    return Scaffold(
      key: _scaffoldKey,
      appBar: _buildAppBar(context),
      drawer: _buildDrawer(context),
      backgroundColor: const Color(0xFFF8FAFC),
      body: Obx(() {
        if (controller.isLoading.value) {
          return _buildLoadingState();
        }

        if (controller.errorMessage.value.isNotEmpty) {
          return _buildErrorState();
        }

        final filteredClinics = controller.filteredClinics;

        return Column(
          children: [
            _buildHeader(context, filteredClinics.length),
            _buildSearchBar(),
            SizedBox(height: _responsive.verticalSpacing),
            if (filteredClinics.isEmpty)
              _buildEmptyState()
            else
              Expanded(
                child: RefreshIndicator(
                  onRefresh: controller.fetchAllClinics,
                  color: const Color.fromRGBO(81, 115, 153, 1),
                  child: _buildClinicGrid(filteredClinics),
                ),
              ),
          ],
        );
      }),
      floatingActionButton: _buildFAB(),
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context) {
    return AppBar(
      surfaceTintColor: Colors.transparent,
      leading: IconButton(
        icon: Icon(
          Icons.menu_rounded,
          color: const Color.fromRGBO(81, 115, 153, 1),
          size: _responsive.iconSize,
        ),
        onPressed: () => _scaffoldKey.currentState?.openDrawer(),
        tooltip: 'Menu',
      ),
      backgroundColor: const Color(0xFFF8FAFC),
      centerTitle: true,
      toolbarHeight: _responsive.appBarHeight,
      flexibleSpace: Container(
        margin: EdgeInsets.only(
          top: _responsive.appBarLogoMarginTop,
          left: _responsive.horizontalPadding * 0.5,
          right: _responsive.horizontalPadding * 0.5,
        ),
        child: Center(
          child: Image.asset(
            "lib/images/PAWrtal_logo.png",
            height: double.infinity,
            width: double.infinity,
            fit: BoxFit.contain,
          ),
        ),
      ),
    );
  }

  Widget _buildDrawer(BuildContext context) {
    return Drawer(
      backgroundColor: const Color.fromRGBO(248, 253, 255, 1),
      child: Column(
        children: [
          _buildDrawerHeader(),
          Expanded(
            child: ListView(
              padding: EdgeInsets.symmetric(vertical: _responsive.scale(8)),
              children: [
                _buildDrawerItem(
                  context,
                  icon: Icons.people_rounded,
                  title: 'Pet Owner Management',
                  subtitle: 'Manage user accounts',
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            const SuperAdminUserManagementScreen(),
                      ),
                    );
                  },
                ),
                _buildDrawerItem(
                  context,
                  icon: Icons.feedback_rounded,
                  title: 'System Reports',
                  subtitle: 'User feedback & reports',
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const AdminFeedbackManagement(),
                      ),
                    );
                  },
                ),
                _buildDrawerItem(
                  context,
                  icon: Icons.delete_forever_rounded,
                  title: 'Vet Reports',
                  subtitle: 'Deletion requests',
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const VeterinaryReport(),
                      ),
                    );
                  },
                ),
                Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: _responsive.scale(14),
                    vertical: _responsive.scale(7),
                  ),
                  child: const Divider(),
                ),
                _buildDrawerItem(
                  context,
                  icon: Icons.archive_rounded,
                  title: 'Archived Clinics',
                  subtitle: 'View & manage archives',
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const ArchivedClinicsDashboard(),
                      ),
                    );
                  },
                ),
                _buildDrawerItem(
                  context,
                  icon: Icons.pending_actions_rounded,
                  title: 'Registration Requests',
                  subtitle: 'Review clinic applications',
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            const VetClinicRequestsDashboard(),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
          _buildLogoutButton(),
        ],
      ),
    );
  }

  Widget _buildDrawerHeader() {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(
        _responsive.drawerHeaderPadding,
        _responsive.drawerHeaderPaddingTop,
        _responsive.drawerHeaderPadding,
        _responsive.drawerHeaderPadding,
      ),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color.fromRGBO(81, 115, 153, 1),
            Color.fromRGBO(81, 115, 153, 0.8),
          ],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: EdgeInsets.all(_responsive.scale(11)),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(_responsive.scale(11)),
            ),
            child: Icon(
              Icons.admin_panel_settings_rounded,
              color: Colors.white,
              size: _responsive.scale(30),
            ),
          ),
          SizedBox(height: _responsive.scale(14)),
          Text(
            'Developer',
            style: TextStyle(
              color: Colors.white,
              fontSize: _responsive.scale(22),
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: _responsive.scale(4)),
          Text(
            'Management Panel',
            style: TextStyle(
              color: Colors.white.withOpacity(0.9),
              fontSize: _responsive.scale(13),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDrawerItem(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: _responsive.scale(7),
        vertical: _responsive.scale(3.5),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(_responsive.scale(11)),
        child: Container(
          padding: EdgeInsets.all(_responsive.scale(14)),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(_responsive.scale(11)),
            border: Border.all(
              color: const Color.fromRGBO(81, 115, 153, 0.2),
            ),
          ),
          child: Row(
            children: [
              Container(
                padding: EdgeInsets.all(_responsive.scale(9)),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [
                      Color.fromRGBO(81, 115, 153, 0.2),
                      Color.fromRGBO(81, 115, 153, 0.1),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(_responsive.scale(9)),
                ),
                child: Icon(
                  icon,
                  color: const Color.fromRGBO(81, 115, 153, 1),
                  size: _responsive.scale(22),
                ),
              ),
              SizedBox(width: _responsive.scale(14)),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: _responsive.scale(14),
                        fontWeight: FontWeight.w600,
                        color: const Color.fromRGBO(81, 115, 153, 1),
                      ),
                    ),
                    SizedBox(height: _responsive.scale(2)),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: _responsive.scale(11),
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_ios_rounded,
                size: _responsive.scale(15),
                color: const Color.fromRGBO(81, 115, 153, 0.5),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLogoutButton() {
    return Container(
      padding: EdgeInsets.all(_responsive.scale(14)),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: _isLoggingOut
            ? Container(
                padding: EdgeInsets.symmetric(vertical: _responsive.scale(15)),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [
                      Color.fromRGBO(81, 115, 153, 0.7),
                      Color.fromRGBO(81, 115, 153, 0.5),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(_responsive.scale(11)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SizedBox(
                      width: _responsive.scale(19),
                      height: _responsive.scale(19),
                      child: const CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    ),
                    SizedBox(width: _responsive.scale(11)),
                    Text(
                      'Logging Out...',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: _responsive.scale(15),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              )
            : InkWell(
                onTap: () async {
                  setState(() => _isLoggingOut = true);
                  try {
                    await LogoutHelper.logout();
                  } catch (e) {
                    if (mounted) {
                      setState(() => _isLoggingOut = false);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Logout failed: ${e.toString()}'),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                  }
                },
                borderRadius: BorderRadius.circular(_responsive.scale(11)),
                child: Container(
                  padding:
                      EdgeInsets.symmetric(vertical: _responsive.scale(15)),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [
                        Color.fromRGBO(220, 53, 69, 1),
                        Color.fromRGBO(200, 35, 51, 1),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(_responsive.scale(11)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.red.withOpacity(0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.logout_rounded,
                        color: Colors.white,
                        size: _responsive.scale(19),
                      ),
                      SizedBox(width: _responsive.scale(11)),
                      Text(
                        'Log Out',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: _responsive.scale(15),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
      ),
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: EdgeInsets.all(_responsive.scale(24)),
            decoration: BoxDecoration(
              color: const Color.fromRGBO(81, 115, 153, 0.1),
              shape: BoxShape.circle,
            ),
            child: CircularProgressIndicator(
              color: const Color.fromRGBO(81, 115, 153, 1),
              strokeWidth: _responsive.scale(3.5),
            ),
          ),
          SizedBox(height: _responsive.scale(20)),
          Text(
            'Loading clinics...',
            style: TextStyle(
              fontSize: _responsive.scale(15),
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context, int clinicCount) {
    return TweenAnimationBuilder<double>(
      duration: const Duration(milliseconds: 600),
      tween: Tween(begin: 0.0, end: 1.0),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) {
        return Opacity(
          opacity: value,
          child: Transform.translate(
            offset: Offset(0, 20 * (1 - value)),
            child: Container(
              margin: EdgeInsets.only(
                top: _responsive.headerMarginTop,
                left: _responsive.horizontalPadding,
                right: _responsive.horizontalPadding,
                bottom: _responsive.headerMarginBottom,
              ),
              padding: EdgeInsets.all(_responsive.headerPadding),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Colors.white,
                    const Color.fromRGBO(81, 115, 153, 0.03),
                  ],
                ),
                borderRadius: BorderRadius.circular(_responsive.headerRadius),
                boxShadow: [
                  BoxShadow(
                    color: const Color.fromRGBO(81, 115, 153, 0.1),
                    blurRadius: _responsive.headerShadow,
                    offset: const Offset(0, 4),
                  ),
                ],
                border: Border.all(
                  color: const Color.fromRGBO(81, 115, 153, 0.1),
                  width: 1,
                ),
              ),
              child: _responsive.isMobile
                  ? _buildMobileHeader(clinicCount)
                  : _buildDesktopHeader(clinicCount),
            ),
          ),
        );
      },
    );
  }

  Widget _buildMobileHeader(int clinicCount) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: EdgeInsets.all(_responsive.scale(8)),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [
                    Color.fromRGBO(81, 115, 153, 0.2),
                    Color.fromRGBO(81, 115, 153, 0.1),
                  ],
                ),
                borderRadius: BorderRadius.circular(_responsive.scale(10)),
              ),
              child: Icon(
                Icons.dashboard_rounded,
                color: const Color.fromRGBO(81, 115, 153, 1),
                size: _responsive.scale(20),
              ),
            ),
            SizedBox(width: _responsive.scale(12)),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Veterinary Clinics',
                    style: TextStyle(
                      fontSize: _responsive.scale(17),
                      fontWeight: FontWeight.bold,
                      color: const Color.fromRGBO(81, 115, 153, 1),
                    ),
                  ),
                  Text(
                    'Management Dashboard',
                    style: TextStyle(
                      fontSize: _responsive.scale(11),
                      color: Colors.grey[600],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        SizedBox(height: _responsive.scale(12)),
        _buildClinicCountBadge(clinicCount),
      ],
    );
  }

  Widget _buildDesktopHeader(int clinicCount) {
    return Row(
      children: [
        Container(
          padding: EdgeInsets.all(_responsive.scale(11)),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [
                Color.fromRGBO(81, 115, 153, 0.2),
                Color.fromRGBO(81, 115, 153, 0.1),
              ],
            ),
            borderRadius: BorderRadius.circular(_responsive.scale(13)),
          ),
          child: Icon(
            Icons.dashboard_rounded,
            color: const Color.fromRGBO(81, 115, 153, 1),
            size: _responsive.scale(26),
          ),
        ),
        SizedBox(width: _responsive.scale(15)),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Veterinary Clinics Management',
                style: TextStyle(
                  fontSize: _responsive.scale(20),
                  fontWeight: FontWeight.bold,
                  color: const Color.fromRGBO(81, 115, 153, 1),
                ),
              ),
              SizedBox(height: _responsive.scale(3.5)),
              Text(
                'Registered Veterinary Clinics Dashboard',
                style: TextStyle(
                  fontSize: _responsive.scale(12.5),
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
        _buildClinicCountBadge(clinicCount),
      ],
    );
  }

  Widget _buildClinicCountBadge(int clinicCount) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: _responsive.scale(17),
        vertical: _responsive.scale(10),
      ),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            Color.fromRGBO(81, 115, 153, 0.15),
            Color.fromRGBO(81, 115, 153, 0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(_responsive.scale(14)),
        border: Border.all(
          color: const Color.fromRGBO(81, 115, 153, 0.2),
          width: 1.5,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.store_rounded,
            color: const Color.fromRGBO(81, 115, 153, 1),
            size: _responsive.scale(21),
          ),
          SizedBox(width: _responsive.scale(9)),
          Text(
            '$clinicCount',
            style: TextStyle(
              fontWeight: FontWeight.w900,
              color: const Color.fromRGBO(81, 115, 153, 1),
              fontSize: _responsive.scale(16.5),
            ),
          ),
          SizedBox(width: _responsive.scale(4)),
          Text(
            clinicCount == 1 ? 'Clinic' : 'Clinics',
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: const Color.fromRGBO(81, 115, 153, 1).withOpacity(0.8),
              fontSize: _responsive.scale(14.5),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: _responsive.horizontalPadding),
      child: _responsive.isMobile
          ? Column(
              children: [
                SuperAdminSearchBar(
                  onChanged: controller.updateSearchQuery,
                ),
                SizedBox(height: _responsive.scale(8)),
                SuperAdminSortButton(
                  onSortChanged: controller.updateSortBy,
                ),
              ],
            )
          : Row(
              children: [
                Expanded(
                  child: SuperAdminSearchBar(
                    onChanged: controller.updateSearchQuery,
                  ),
                ),
                SizedBox(width: _responsive.scale(11)),
                SuperAdminSortButton(
                  onSortChanged: controller.updateSortBy,
                ),
              ],
            ),
    );
  }

  Widget _buildClinicGrid(List<Map<String, dynamic>> filteredClinics) {
    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final gridConfig = _responsive.getGridConfig(filteredClinics.length);

          return Container(
            constraints: BoxConstraints(
              minHeight: MediaQuery.of(context).size.height * 0.6,
            ),
            child: GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              padding: EdgeInsets.only(
                top: gridConfig.paddingTop,
                left: _responsive.gridHorizontalPadding,
                right: _responsive.gridHorizontalPadding,
                bottom: gridConfig.paddingBottom,
              ),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: gridConfig.crossAxisCount,
                crossAxisSpacing: gridConfig.crossAxisSpacing,
                mainAxisSpacing: gridConfig.mainAxisSpacing,
                childAspectRatio: gridConfig.childAspectRatio,
              ),
              itemCount: filteredClinics.length,
              itemBuilder: (context, index) {
                final clinicData = filteredClinics[index];
                final clinic = clinicData['clinic'] as Clinic;
                final settings = clinicData['settings'] as ClinicSettings?;

                return TweenAnimationBuilder<double>(
                  duration: Duration(milliseconds: 400 + (index * 50)),
                  tween: Tween(begin: 0.0, end: 1.0),
                  curve: Curves.easeOutCubic,
                  builder: (context, value, child) {
                    return Opacity(
                      opacity: value,
                      child: Transform.translate(
                        offset: Offset(0, 30 * (1 - value)),
                        child: GestureDetector(
                          onTap: () async {
                            final result = await Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    SuperAdminVetClinicDetailPage(
                                  clinic: clinic,
                                  settings: settings,
                                ),
                              ),
                            );

                            if (result == true) {
                              controller.fetchAllClinics();
                            }
                          },
                          child: SuperAdminVetClinicTile(
                            clinic: clinic,
                            settings: settings,
                            isMobile: _responsive.isMobile,
                            isTablet: _responsive.isTablet,
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          );
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    return Expanded(
      child: Center(
        child: TweenAnimationBuilder<double>(
          duration: const Duration(milliseconds: 600),
          tween: Tween(begin: 0.0, end: 1.0),
          curve: Curves.easeOutCubic,
          builder: (context, value, child) {
            return Opacity(
              opacity: value,
              child: Transform.scale(
                scale: 0.8 + (0.2 * value),
                child: Padding(
                  padding: EdgeInsets.all(_responsive.scale(28)),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: EdgeInsets.all(_responsive.scale(26)),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              const Color.fromRGBO(81, 115, 153, 0.15),
                              const Color.fromRGBO(81, 115, 153, 0.05),
                            ],
                          ),
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: const Color.fromRGBO(81, 115, 153, 0.2),
                              blurRadius: 20,
                              spreadRadius: 5,
                            ),
                          ],
                        ),
                        child: Icon(
                          controller.searchQuery.value.isEmpty
                              ? Icons.medical_services_outlined
                              : Icons.search_off_rounded,
                          size: _responsive.scale(66),
                          color: const Color.fromRGBO(81, 115, 153, 0.6),
                        ),
                      ),
                      SizedBox(height: _responsive.scale(21)),
                      Text(
                        controller.searchQuery.value.isEmpty
                            ? 'No clinics registered yet'
                            : 'No clinics found',
                        style: TextStyle(
                          fontSize: _responsive.scale(20),
                          color: Colors.grey[700],
                          fontWeight: FontWeight.w700,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      SizedBox(height: _responsive.scale(10)),
                      Text(
                        controller.searchQuery.value.isEmpty
                            ? 'Start by adding your first veterinary clinic'
                            : 'Try adjusting your search terms',
                        style: TextStyle(
                          fontSize: _responsive.scale(14.5),
                          color: Colors.grey[600],
                        ),
                        textAlign: TextAlign.center,
                      ),
                      if (controller.searchQuery.value.isEmpty) ...[
                        SizedBox(height: _responsive.scale(28)),
                        ElevatedButton.icon(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const VetClinicRegister(),
                              ),
                            );
                          },
                          icon: Icon(
                            Icons.add_rounded,
                            size: _responsive.scale(22),
                          ),
                          label: Text(
                            'Add First Clinic',
                            style: TextStyle(
                              fontSize: _responsive.scale(15),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor:
                                const Color.fromRGBO(81, 115, 153, 1),
                            foregroundColor: Colors.white,
                            padding: EdgeInsets.symmetric(
                              horizontal: _responsive.scale(28),
                              vertical: _responsive.scale(14),
                            ),
                            elevation: 4,
                            shadowColor:
                                const Color.fromRGBO(81, 115, 153, 0.3),
                            shape: RoundedRectangleBorder(
                              borderRadius:
                                  BorderRadius.circular(_responsive.scale(12)),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(_responsive.scale(28)),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: EdgeInsets.all(_responsive.scale(26)),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.red.withOpacity(0.2),
                    blurRadius: 20,
                    spreadRadius: 5,
                  ),
                ],
              ),
              child: Icon(
                Icons.error_outline_rounded,
                size: _responsive.scale(66),
                color: Colors.red[700],
              ),
            ),
            SizedBox(height: _responsive.scale(21)),
            Text(
              'Oops! Something went wrong',
              style: TextStyle(
                fontSize: _responsive.scale(20),
                fontWeight: FontWeight.w600,
                color: Colors.grey[800],
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: _responsive.scale(10)),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: _responsive.scale(24)),
              child: Text(
                controller.errorMessage.value,
                style: TextStyle(
                  fontSize: _responsive.scale(14.5),
                  color: Colors.grey[600],
                ),
                textAlign: TextAlign.center,
              ),
            ),
            SizedBox(height: _responsive.scale(28)),
            ElevatedButton.icon(
              onPressed: controller.fetchAllClinics,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color.fromRGBO(81, 115, 153, 1),
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(
                  horizontal: _responsive.scale(28),
                  vertical: _responsive.scale(14),
                ),
                elevation: 4,
                shadowColor: const Color.fromRGBO(81, 115, 153, 0.3),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(_responsive.scale(12)),
                ),
              ),
              icon: Icon(
                Icons.refresh_rounded,
                size: _responsive.scale(22),
              ),
              label: Text(
                'Try Again',
                style: TextStyle(
                  fontSize: _responsive.scale(15),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFAB() {
    return ScaleTransition(
      scale: _fabScaleAnimation,
      child: _responsive.isMobile
          ? FloatingActionButton(
              backgroundColor: const Color.fromRGBO(81, 115, 153, 1),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const VetClinicRegister(),
                  ),
                );
              },
              elevation: 6,
              child: Icon(
                Icons.add_rounded,
                color: Colors.white,
                size: _responsive.scale(26),
              ),
            )
          : FloatingActionButton.extended(
              backgroundColor: const Color.fromRGBO(81, 115, 153, 1),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const VetClinicRegister(),
                  ),
                );
              },
              elevation: 6,
              icon: Icon(
                Icons.add_rounded,
                color: Colors.white,
                size: _responsive.scale(21),
              ),
              label: Text(
                'Add Clinic',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: _responsive.scale(15),
                ),
              ),
            ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// DASHBOARD RESPONSIVE CONFIGURATION
// Centralized responsive configuration for the entire dashboard
// ═══════════════════════════════════════════════════════════════

class DashboardResponsive {
  final BuildContext context;
  final double screenWidth;
  final double screenHeight;
  final bool isMobile;
  final bool isTablet;
  final bool isDesktop;

  // Core dimensions
  final double horizontalPadding;
  final double gridHorizontalPadding;
  final double verticalSpacing;

  // AppBar
  final double appBarHeight;
  final double appBarLogoMarginTop;
  final double iconSize;

  // Drawer
  final double drawerHeaderPadding;
  final double drawerHeaderPaddingTop;

  // Header section
  final double headerMarginTop;
  final double headerMarginBottom;
  final double headerPadding;
  final double headerRadius;
  final double headerShadow;

  DashboardResponsive._(
    this.context, {
    required this.screenWidth,
    required this.screenHeight,
    required this.isMobile,
    required this.isTablet,
    required this.isDesktop,
    required this.horizontalPadding,
    required this.gridHorizontalPadding,
    required this.verticalSpacing,
    required this.appBarHeight,
    required this.appBarLogoMarginTop,
    required this.iconSize,
    required this.drawerHeaderPadding,
    required this.drawerHeaderPaddingTop,
    required this.headerMarginTop,
    required this.headerMarginBottom,
    required this.headerPadding,
    required this.headerRadius,
    required this.headerShadow,
  });

  factory DashboardResponsive(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final isMobile = screenWidth < mobileWidth;
    final isTablet = screenWidth >= mobileWidth && screenWidth < tabletWidth;
    final isDesktop = !isMobile && !isTablet;

    if (isMobile) {
      return DashboardResponsive._(
        context,
        screenWidth: screenWidth,
        screenHeight: screenHeight,
        isMobile: true,
        isTablet: false,
        isDesktop: false,
        horizontalPadding: 12.0,
        gridHorizontalPadding: 12.0,
        verticalSpacing: 10.0,
        appBarHeight: screenHeight * 0.07,
        appBarLogoMarginTop: screenHeight * 0.012,
        iconSize: 22.0,
        drawerHeaderPadding: 18.0,
        drawerHeaderPaddingTop: 50.0,
        headerMarginTop: 10.0,
        headerMarginBottom: 10.0,
        headerPadding: 14.0,
        headerRadius: 14.0,
        headerShadow: 10.0,
      );
    } else if (isTablet) {
      return DashboardResponsive._(
        context,
        screenWidth: screenWidth,
        screenHeight: screenHeight,
        isMobile: false,
        isTablet: true,
        isDesktop: false,
        horizontalPadding: 20.0,
        gridHorizontalPadding: 20.0,
        verticalSpacing: 12.0,
        appBarHeight: screenHeight * 0.08,
        appBarLogoMarginTop: screenHeight * 0.015,
        iconSize: 24.0,
        drawerHeaderPadding: 20.0,
        drawerHeaderPaddingTop: 55.0,
        headerMarginTop: 12.0,
        headerMarginBottom: 12.0,
        headerPadding: 16.0,
        headerRadius: 16.0,
        headerShadow: 12.0,
      );
    } else {
      // Desktop
      return DashboardResponsive._(
        context,
        screenWidth: screenWidth,
        screenHeight: screenHeight,
        isMobile: false,
        isTablet: false,
        isDesktop: true,
        horizontalPadding: (screenWidth * 0.05).clamp(32.0, 80.0),
        gridHorizontalPadding: (screenWidth * 0.08).clamp(40.0, 80.0),
        verticalSpacing: 16.0,
        appBarHeight: screenHeight * 0.1,
        appBarLogoMarginTop: screenHeight * 0.02,
        iconSize: 28.0,
        drawerHeaderPadding: 24.0,
        drawerHeaderPaddingTop: 60.0,
        headerMarginTop: 16.0,
        headerMarginBottom: 16.0,
        headerPadding: 20.0,
        headerRadius: 20.0,
        headerShadow: 15.0,
      );
    }
  }

  // Universal scaling helper
  double scale(double value) {
    if (isMobile) return value * 0.95;
    if (isTablet) return value;
    return value * 1.05;
  }

  // Grid configuration based on item count and screen type
  GridConfig getGridConfig(int itemCount) {
    if (isMobile) {
      return GridConfig(
        crossAxisCount: 1,
        childAspectRatio: 0.88,
        crossAxisSpacing: 0,
        mainAxisSpacing: 14,
        paddingTop: 6,
        paddingBottom: 80,
      );
    } else if (isTablet) {
      return GridConfig(
        crossAxisCount: 2,
        childAspectRatio: 0.95,
        crossAxisSpacing: 14,
        mainAxisSpacing: 14,
        paddingTop: 8,
        paddingBottom: 90,
      );
    } else {
      // Desktop - dynamic columns
      int crossAxisCount;
      double aspectRatio;

      if (itemCount == 1) {
        crossAxisCount = 1;
        aspectRatio = 2.5;
      } else if (itemCount == 2) {
        crossAxisCount = 2;
        aspectRatio = 1.4;
      } else if (itemCount == 3) {
        crossAxisCount = 3;
        aspectRatio = 1.2;
      } else {
        crossAxisCount = screenWidth > 1400 ? 4 : 3;
        aspectRatio = 1.15;
      }

      final spacing = (screenWidth * 0.02).clamp(16.0, 24.0);

      return GridConfig(
        crossAxisCount: crossAxisCount,
        childAspectRatio: aspectRatio,
        crossAxisSpacing: spacing,
        mainAxisSpacing: spacing,
        paddingTop: 16,
        paddingBottom: 24,
      );
    }
  }
}

// Grid configuration data class
class GridConfig {
  final int crossAxisCount;
  final double childAspectRatio;
  final double crossAxisSpacing;
  final double mainAxisSpacing;
  final double paddingTop;
  final double paddingBottom;

  GridConfig({
    required this.crossAxisCount,
    required this.childAspectRatio,
    required this.crossAxisSpacing,
    required this.mainAxisSpacing,
    required this.paddingTop,
    required this.paddingBottom,
  });
}
