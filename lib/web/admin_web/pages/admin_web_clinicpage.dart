import 'package:capstone_app/data/repository/auth.repository.dart';
import 'package:capstone_app/utils/user_session_service.dart';
import 'package:capstone_app/web/admin_web/components/clinic/clinic_settings_controller.dart';
import 'package:capstone_app/web/admin_web/components/clinic/admin_pin_maps_page.dart';
import 'package:capstone_app/web/admin_web/components/clinic/admin_clinic_preview.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:table_calendar/table_calendar.dart';

class AdminWebClinicpage extends StatefulWidget {
  const AdminWebClinicpage({super.key, this.initialTabIndex = 0});

  final int initialTabIndex;

  @override
  State<AdminWebClinicpage> createState() => _AdminWebClinicpageState();
}

class _AdminWebClinicpageState extends State<AdminWebClinicpage>
    with TickerProviderStateMixin, AutomaticKeepAliveClientMixin {
  late TabController _tabController;
  late ClinicSettingsController controller;
  bool _showEditingPage = false;
  bool _initialized = false;

  String _fullAddressFromMap = '';

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();

    // Check if there's a stored initial tab index
    final storage = GetStorage();
    final storedTabIndex = storage.read('clinicPageInitialTab') as int?;

    // Clear the stored value after reading
    if (storedTabIndex != null) {
      storage.remove('clinicPageInitialTab');
    }

    _initializeTabController(
      initialTab: storedTabIndex ?? widget.initialTabIndex,
    );

    if (controller.addressController.text.isNotEmpty) {
      _fullAddressFromMap = controller.addressController.text;
    }
  }

  void _initializeTabController({int initialTab = 0}) {
    try {
      // CRITICAL FIX: Delete old controller if it exists to prevent stale data
      if (Get.isRegistered<ClinicSettingsController>()) {
        Get.delete<ClinicSettingsController>(force: true);
      }

      // CRITICAL FIX: Always create a fresh instance for current clinic
      controller = Get.put(
        ClinicSettingsController(
          authRepository: Get.find<AuthRepository>(),
          session: Get.find<UserSessionService>(),
        ),
        permanent: false, // CHANGED: Don't persist across logins
      );

      _tabController = TabController(
        length: 3,
        vsync: this,
        initialIndex: initialTab, // ✅ Use the initial tab parameter
      );

      setState(() {
        _initialized = true;
      });
    } catch (e) {
      setState(() {
        _initialized = false;
      });
    }
  }

  @override
  void dispose() {
    if (_initialized) {
      _tabController.dispose();
    }
    // Don't delete controller here - let GetX handle it
    super.dispose();
  }

  void _toggleView() {
    setState(() {
      _showEditingPage = !_showEditingPage;
    });
  }

  bool _isMobileLayout(double screenWidth) {
    return screenWidth <= 785;
  }

  bool _isTabletLayout(double screenWidth) {
    return screenWidth > 785 && screenWidth < 1100;
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    if (!_initialized) {
      return const Scaffold(
        backgroundColor: Color(0xFFF8FAFC),
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = _isMobileLayout(screenWidth);
    final isTablet = _isTabletLayout(screenWidth);

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: Obx(() {
        if (controller.isLoading.value) {
          return const Center(child: CircularProgressIndicator());
        }

        return Stack(
          children: [
            if (!_showEditingPage)
              _buildPreviewPage()
            else
              _buildEditingPage(isMobile),
            if (!_showEditingPage) ...[
              // MODIFIED: Moved Edit Settings button higher
              Positioned(
                bottom: isMobile ? 77 : 85, // Increased from 76/92 to 86/102
                right: isMobile ? 16 : 32,
                child: FloatingActionButton.extended(
                  onPressed: _toggleView,
                  backgroundColor: const Color.fromARGB(255, 81, 115, 153),
                  icon: const Icon(Icons.edit, color: Colors.white),
                  label: const Text(
                    'Edit Settings',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              // Book Appointment FAB stays at original position (bottom: 16/32)
            ]
          ],
        );
      }),
    );
  }

  Widget _buildPreviewPage() {
    return AdminClinicPreview(
      controller: controller,
      onNavigateToSettings: () {
        setState(() {
          _showEditingPage = true; // Switch to editing page
        });
        // Switch to Settings tab
        if (_tabController.index != 2) {
          _tabController.animateTo(2); // Animate to Settings tab
        }
      },
    );
  }

  Widget _buildEditingPage(bool isMobile) {
    return Column(
      children: [
        Container(
          padding: EdgeInsets.all(isMobile ? 16 : 24),
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.1),
                spreadRadius: 1,
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: isMobile
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        IconButton(
                          onPressed: _toggleView,
                          icon: const Icon(Icons.arrow_back),
                          tooltip: 'Back to Preview',
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            controller.clinic.value?.clinicName ??
                                "Clinic Settings",
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      "Manage gallery, schedule, and advanced settings",
                      style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                    ),
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: controller.clinicStatusColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: controller.clinicStatusColor.withOpacity(0.3),
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            controller.isClinicOpen.value
                                ? Icons.check_circle
                                : Icons.cancel,
                            color: controller.clinicStatusColor,
                            size: 18,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              "Clinic Status: ${controller.clinicStatusText}",
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: controller.clinicStatusColor,
                              ),
                            ),
                          ),
                          Transform.scale(
                            scale: 0.8,
                            child: Switch(
                              value: controller.isClinicOpen.value,
                              onChanged: (value) =>
                                  controller.toggleClinicStatus(),
                              activeColor: Colors.green,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                )
              : Row(
                  children: [
                    IconButton(
                      onPressed: _toggleView,
                      icon: const Icon(Icons.arrow_back),
                      tooltip: 'Back to Preview',
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            controller.clinic.value?.clinicName ??
                                "Clinic Settings",
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            "Manage gallery, schedule, and advanced settings",
                            style: TextStyle(
                                fontSize: 14, color: Colors.grey[600]),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: controller.clinicStatusColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: controller.clinicStatusColor.withOpacity(0.3),
                        ),
                      ),
                      child: Column(
                        children: [
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                controller.isClinicOpen.value
                                    ? Icons.check_circle
                                    : Icons.cancel,
                                color: controller.clinicStatusColor,
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                "Clinic Status: ${controller.clinicStatusText}",
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  color: controller.clinicStatusColor,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Switch(
                            value: controller.isClinicOpen.value,
                            onChanged: (value) =>
                                controller.toggleClinicStatus(),
                            activeColor: Colors.green,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
        ),
        Container(
          color: Colors.white,
          child: TabBar(
            controller: _tabController,
            labelColor: const Color.fromARGB(255, 81, 115, 153),
            unselectedLabelColor: Colors.grey,
            indicatorColor: const Color.fromARGB(255, 81, 115, 153),
            labelStyle: TextStyle(fontSize: isMobile ? 12 : 13),
            tabs: const [
              Tab(text: "Gallery"),
              Tab(text: "Schedule"),
              Tab(text: "Settings"),
            ],
          ),
        ),
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              _buildGalleryTab(isMobile),
              _buildScheduleTab(isMobile),
              _buildSettingsTab(isMobile),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildGalleryTab(bool isMobile) {
    return SingleChildScrollView(
      padding: EdgeInsets.all(isMobile ? 12 : 20),
      child: Column(
        children: [
          _buildSectionCard(
            title: "Clinic Gallery",
            isMobile: isMobile,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                isMobile
                    ? Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Upload images of your clinic to show customers",
                            style: TextStyle(
                                fontSize: 13, color: Colors.grey[700]),
                          ),
                          const SizedBox(height: 12),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              onPressed: controller.isSaving.value
                                  ? null
                                  : controller.addGalleryImages,
                              icon: const Icon(Icons.add_photo_alternate),
                              label: const Text("Add Images"),
                              style: ElevatedButton.styleFrom(
                                backgroundColor:
                                    const Color.fromARGB(255, 81, 115, 153),
                                foregroundColor: Colors.white,
                              ),
                            ),
                          ),
                        ],
                      )
                    : Row(
                        children: [
                          Text(
                            "Upload images of your clinic to show customers",
                            style: TextStyle(
                                fontSize: 14, color: Colors.grey[700]),
                          ),
                          const Spacer(),
                          ElevatedButton.icon(
                            onPressed: controller.isSaving.value
                                ? null
                                : controller.addGalleryImages,
                            icon: const Icon(Icons.add_photo_alternate),
                            label: const Text("Add Images"),
                            style: ElevatedButton.styleFrom(
                              backgroundColor:
                                  const Color.fromARGB(255, 81, 115, 153),
                              foregroundColor: Colors.white,
                            ),
                          ),
                        ],
                      ),
                const SizedBox(height: 16),
                if (!isMobile) const SizedBox(height: 16),
                Obx(() {
                  if (controller.galleryImages.isEmpty) {
                    return Container(
                      height: 200,
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey[300]!),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.photo_library,
                                size: isMobile ? 36 : 48, color: Colors.grey),
                            const SizedBox(height: 8),
                            Text("No images uploaded yet",
                                style: TextStyle(fontSize: isMobile ? 12 : 14)),
                            Text("Click 'Add Images' to get started",
                                style: TextStyle(fontSize: isMobile ? 11 : 12)),
                          ],
                        ),
                      ),
                    );
                  }

                  return GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: isMobile ? 2 : 4,
                      crossAxisSpacing: 8,
                      mainAxisSpacing: 8,
                      childAspectRatio: 1,
                    ),
                    itemCount: controller.galleryImages.length,
                    itemBuilder: (context, index) {
                      return Stack(
                        children: [
                          Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.grey[300]!),
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(7),
                              child: Image.network(
                                controller.galleryImages[index],
                                fit: BoxFit.cover,
                                width: double.infinity,
                                height: double.infinity,
                                loadingBuilder:
                                    (context, child, loadingProgress) {
                                  if (loadingProgress == null) return child;
                                  return Container(
                                    color: Colors.grey[200],
                                    child: Center(
                                      child: CircularProgressIndicator(
                                        value: loadingProgress
                                                    .expectedTotalBytes !=
                                                null
                                            ? loadingProgress
                                                    .cumulativeBytesLoaded /
                                                loadingProgress
                                                    .expectedTotalBytes!
                                            : null,
                                      ),
                                    ),
                                  );
                                },
                                errorBuilder: (context, error, stackTrace) {
                                  return Container(
                                    color: Colors.grey[200],
                                    child: Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        const Icon(Icons.error,
                                            color: Colors.red),
                                        const SizedBox(height: 4),
                                        Text("Failed to load",
                                            style: TextStyle(
                                              fontSize: 10,
                                              color: Colors.red[700],
                                            )),
                                      ],
                                    ),
                                  );
                                },
                              ),
                            ),
                          ),
                          Positioned(
                            top: 4,
                            right: 4,
                            child: InkWell(
                              onTap: () => controller.removeGalleryImage(index),
                              child: Container(
                                padding: const EdgeInsets.all(4),
                                decoration: const BoxDecoration(
                                  color: Colors.red,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(Icons.close,
                                    color: Colors.white, size: 16),
                              ),
                            ),
                          ),
                        ],
                      );
                    },
                  );
                }),
              ],
            ),
          ),
          const SizedBox(height: 24),
          // Dashboard Preview Section - MODIFIED
          _buildSectionCard(
            title: "Dashboard Preview",
            isMobile: isMobile,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "This is how your clinic appears on the user dashboard",
                  style: TextStyle(
                    fontSize: isMobile ? 13 : 14,
                    color: Colors.grey[700],
                  ),
                ),
                const SizedBox(height: 16),
                // Dashboard Tile Preview - MODIFIED TO MATCH WEB DASHBOARD TILE
                Obx(() {
                  return _buildDashboardTilePreview(isMobile);
                }),
                const SizedBox(height: 24),
                // Control Buttons
                Obx(() {
                  return Column(
                    children: [
                      if (controller.dashboardPicChanged.value)
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.orange[50],
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: Colors.orange[200]!,
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.info, color: Colors.orange[700]),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  "Picture selected. Click 'Save Picture' to confirm changes.",
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.orange[700],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      if (controller.dashboardPicChanged.value)
                        const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          if (controller.dashboardPicChanged.value)
                            TextButton(
                              onPressed: controller.isSaving.value
                                  ? null
                                  : controller.cancelDashboardPictureSelection,
                              child: const Text("Cancel"),
                            ),
                          const SizedBox(width: 8),
                          ElevatedButton.icon(
                            onPressed: controller.isSaving.value
                                ? null
                                : controller.setDashboardPicture,
                            icon: controller.isSaving.value
                                ? SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                        Colors.white,
                                      ),
                                    ),
                                  )
                                : const Icon(Icons.image_search),
                            label: Text(
                              controller.isSaving.value
                                  ? "Uploading..."
                                  : "Add/Replace Picture",
                              style: TextStyle(fontSize: isMobile ? 12 : 13),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor:
                                  const Color.fromARGB(255, 81, 115, 153),
                              foregroundColor: Colors.white,
                            ),
                          ),
                          if (controller.dashboardPicChanged.value) ...[
                            const SizedBox(width: 8),
                            ElevatedButton.icon(
                              onPressed: controller.isSaving.value
                                  ? null
                                  : controller.saveDashboardPicture,
                              icon: controller.isSaving.value
                                  ? SizedBox(
                                      width: 16,
                                      height: 16,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        valueColor:
                                            AlwaysStoppedAnimation<Color>(
                                          Colors.white,
                                        ),
                                      ),
                                    )
                                  : const Icon(Icons.save),
                              label: Text(
                                controller.isSaving.value
                                    ? "Saving..."
                                    : "Save Picture",
                                style: TextStyle(fontSize: isMobile ? 12 : 13),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.green,
                                foregroundColor: Colors.white,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  );
                }),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScheduleTab(bool isMobile) {
    return SingleChildScrollView(
      padding: EdgeInsets.all(isMobile ? 12 : 20),
      child: Column(
        children: [
          _buildSectionCard(
            title: "Operating Hours",
            isMobile: isMobile,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Set your clinic's operating hours for each day",
                  style: TextStyle(
                    fontSize: isMobile ? 13 : 14,
                    color: Colors.grey[700],
                  ),
                ),
                const SizedBox(height: 16),
                Obx(() {
                  final days = [
                    'monday',
                    'tuesday',
                    'wednesday',
                    'thursday',
                    'friday',
                    'saturday',
                    'sunday'
                  ];
                  return Column(
                    children: days.map((day) {
                      final dayData = controller.operatingHours[day] ??
                          {
                            'isOpen': false,
                            'openTime': '09:00',
                            'closeTime': '17:00'
                          };
                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: EdgeInsets.all(isMobile ? 10 : 12),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey[300]!),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: isMobile
                            ? Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      SizedBox(
                                        width: 70,
                                        child: Text(
                                          day.capitalize!,
                                          style: const TextStyle(
                                            fontWeight: FontWeight.w600,
                                            fontSize: 13,
                                          ),
                                        ),
                                      ),
                                      const Spacer(),
                                      Transform.scale(
                                        scale: 0.8,
                                        child: Switch(
                                          value: dayData['isOpen'] ?? false,
                                          onChanged: (value) {
                                            final newData =
                                                Map<String, dynamic>.from(
                                                    dayData);
                                            newData['isOpen'] = value;
                                            controller.updateOperatingHours(
                                                day, newData);
                                          },
                                        ),
                                      ),
                                    ],
                                  ),
                                  if (dayData['isOpen'] == true) ...[
                                    const SizedBox(height: 8),
                                    Row(
                                      children: [
                                        Expanded(
                                          child: _buildTimeField(
                                            value:
                                                dayData['openTime'] ?? '09:00',
                                            label: "Open",
                                            onChanged: (time) {
                                              final newData =
                                                  Map<String, dynamic>.from(
                                                      dayData);
                                              newData['openTime'] = time;
                                              controller.updateOperatingHours(
                                                  day, newData);
                                            },
                                            isMobile: isMobile,
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: _buildTimeField(
                                            value:
                                                dayData['closeTime'] ?? '17:00',
                                            label: "Close",
                                            onChanged: (time) {
                                              final newData =
                                                  Map<String, dynamic>.from(
                                                      dayData);
                                              newData['closeTime'] = time;
                                              controller.updateOperatingHours(
                                                  day, newData);
                                            },
                                            isMobile: isMobile,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ] else ...[
                                    const SizedBox(height: 4),
                                    const Text(
                                      "Closed",
                                      style: TextStyle(
                                        color: Colors.grey,
                                        fontStyle: FontStyle.italic,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ],
                              )
                            : Row(
                                children: [
                                  SizedBox(
                                    width: 90,
                                    child: Text(
                                      day.capitalize!,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w600,
                                        fontSize: 14,
                                      ),
                                    ),
                                  ),
                                  Switch(
                                    value: dayData['isOpen'] ?? false,
                                    onChanged: (value) {
                                      final newData =
                                          Map<String, dynamic>.from(dayData);
                                      newData['isOpen'] = value;
                                      controller.updateOperatingHours(
                                          day, newData);
                                    },
                                  ),
                                  const SizedBox(width: 12),
                                  if (dayData['isOpen'] == true) ...[
                                    Expanded(
                                      child: Row(
                                        children: [
                                          Expanded(
                                            child: _buildTimeField(
                                              value: dayData['openTime'] ??
                                                  '09:00',
                                              label: "Open",
                                              onChanged: (time) {
                                                final newData =
                                                    Map<String, dynamic>.from(
                                                        dayData);
                                                newData['openTime'] = time;
                                                controller.updateOperatingHours(
                                                    day, newData);
                                              },
                                              isMobile: isMobile,
                                            ),
                                          ),
                                          const SizedBox(width: 12),
                                          Expanded(
                                            child: _buildTimeField(
                                              value: dayData['closeTime'] ??
                                                  '17:00',
                                              label: "Close",
                                              onChanged: (time) {
                                                final newData =
                                                    Map<String, dynamic>.from(
                                                        dayData);
                                                newData['closeTime'] = time;
                                                controller.updateOperatingHours(
                                                    day, newData);
                                              },
                                              isMobile: isMobile,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ] else ...[
                                    const Expanded(
                                      child: Text(
                                        "Closed",
                                        style: TextStyle(
                                          color: Colors.grey,
                                          fontStyle: FontStyle.italic,
                                        ),
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                      );
                    }).toList(),
                  );
                }),
                const SizedBox(height: 20),
                Row(
                  children: [
                    const Spacer(),
                    ElevatedButton.icon(
                      onPressed: controller.isSaving.value
                          ? null
                          : controller.saveClinicSettings,
                      icon: controller.isSaving.value
                          ? SizedBox(
                              width: isMobile ? 13 : 16,
                              height: isMobile ? 13 : 16,
                              child: const CircularProgressIndicator(
                                  strokeWidth: 2),
                            )
                          : const Icon(Icons.save),
                      label: Text(
                          controller.isSaving.value
                              ? "Saving..."
                              : "Save Schedule",
                          style: TextStyle(fontSize: isMobile ? 12 : 13)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor:
                            const Color.fromARGB(255, 81, 115, 153),
                        foregroundColor: Colors.white,
                        padding: EdgeInsets.symmetric(
                            horizontal: isMobile ? 12 : 20,
                            vertical: isMobile ? 8 : 10),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 20), // NEW: Add spacing

          // NEW: Add closed dates section
          _buildClosedDatesSection(isMobile),
        ],
      ),
    );
  }

  Widget _buildSettingsTab(bool isMobile) {
    return SingleChildScrollView(
      padding: EdgeInsets.all(isMobile ? 12 : 20),
      child: Column(
        children: [
          _buildSectionCard(
            title: "Appointment Settings",
            isMobile: isMobile,
            child: Column(
              children: [
                isMobile
                    ? Column(
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                "Default Appointment Duration",
                                style: TextStyle(
                                    fontWeight: FontWeight.w600, fontSize: 13),
                              ),
                              const SizedBox(height: 8),
                              Obx(() => DropdownButtonFormField<int>(
                                    initialValue:
                                        controller.appointmentDuration.value,
                                    decoration: const InputDecoration(
                                      border: OutlineInputBorder(),
                                      suffixText: "minutes",
                                      contentPadding:
                                          EdgeInsets.symmetric(horizontal: 8),
                                    ),
                                    isExpanded: true,
                                    items: [15, 30, 45, 60, 90].map((duration) {
                                      return DropdownMenuItem(
                                        value: duration,
                                        child: Text("$duration minutes",
                                            style:
                                                const TextStyle(fontSize: 12)),
                                      );
                                    }).toList(),
                                    onChanged: (value) {
                                      if (value != null) {
                                        controller.appointmentDuration.value =
                                            value;
                                      }
                                    },
                                  )),
                            ],
                          ),
                          const SizedBox(height: 14),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                "Maximum Advance Booking",
                                style: TextStyle(
                                    fontWeight: FontWeight.w600, fontSize: 13),
                              ),
                              const SizedBox(height: 8),
                              Obx(() => DropdownButtonFormField<int>(
                                    initialValue:
                                        controller.maxAdvanceBooking.value,
                                    decoration: const InputDecoration(
                                      border: OutlineInputBorder(),
                                      suffixText: "days",
                                      contentPadding:
                                          EdgeInsets.symmetric(horizontal: 8),
                                    ),
                                    isExpanded: true,
                                    items: [7, 14, 30, 60, 90].map((days) {
                                      return DropdownMenuItem(
                                        value: days,
                                        child: Text("$days days",
                                            style:
                                                const TextStyle(fontSize: 12)),
                                      );
                                    }).toList(),
                                    onChanged: (value) {
                                      if (value != null) {
                                        controller.maxAdvanceBooking.value =
                                            value;
                                      }
                                    },
                                  )),
                            ],
                          ),
                        ],
                      )
                    : Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  "Default Appointment Duration",
                                  style: TextStyle(fontWeight: FontWeight.w600),
                                ),
                                const SizedBox(height: 8),
                                Obx(() => DropdownButtonFormField<int>(
                                      value:
                                          controller.appointmentDuration.value,
                                      decoration: const InputDecoration(
                                        border: OutlineInputBorder(),
                                        suffixText: "minutes",
                                      ),
                                      items:
                                          [15, 30, 45, 60, 90].map((duration) {
                                        return DropdownMenuItem(
                                          value: duration,
                                          child: Text("$duration minutes"),
                                        );
                                      }).toList(),
                                      onChanged: (value) {
                                        if (value != null) {
                                          controller.appointmentDuration.value =
                                              value;
                                        }
                                      },
                                    )),
                              ],
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  "Maximum Advance Booking",
                                  style: TextStyle(fontWeight: FontWeight.w600),
                                ),
                                const SizedBox(height: 8),
                                Obx(() => DropdownButtonFormField<int>(
                                      initialValue:
                                          controller.maxAdvanceBooking.value,
                                      decoration: const InputDecoration(
                                        border: OutlineInputBorder(),
                                        suffixText: "days",
                                      ),
                                      items: [7, 14, 30, 60, 90].map((days) {
                                        return DropdownMenuItem(
                                          value: days,
                                          child: Text("$days days"),
                                        );
                                      }).toList(),
                                      onChanged: (value) {
                                        if (value != null) {
                                          controller.maxAdvanceBooking.value =
                                              value;
                                        }
                                      },
                                    )),
                              ],
                            ),
                          ),
                        ],
                      ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: controller.emergencyContactController,
                        keyboardType: TextInputType.phone,
                        style: TextStyle(fontSize: isMobile ? 12 : 13),
                        decoration: const InputDecoration(
                          labelText: "Emergency Contact",
                          prefixIcon: Icon(Icons.emergency),
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: controller.specialInstructionsController,
                  maxLines: 3,
                  style: TextStyle(fontSize: isMobile ? 12 : 13),
                  decoration: const InputDecoration(
                    labelText: "Special Instructions for Customers",
                    prefixIcon: Icon(Icons.info),
                    hintText:
                        "Any special instructions or notes for customers...",
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    const Spacer(),
                    ElevatedButton.icon(
                      onPressed: controller.isSaving.value
                          ? null
                          : controller.saveClinicSettings,
                      icon: controller.isSaving.value
                          ? SizedBox(
                              width: isMobile ? 13 : 16,
                              height: isMobile ? 13 : 16,
                              child: const CircularProgressIndicator(
                                  strokeWidth: 2),
                            )
                          : const Icon(Icons.save),
                      label: Text(
                          controller.isSaving.value
                              ? "Saving..."
                              : "Save Settings",
                          style: TextStyle(fontSize: isMobile ? 12 : 13)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor:
                            const Color.fromARGB(255, 81, 115, 153),
                        foregroundColor: Colors.white,
                        padding: EdgeInsets.symmetric(
                            horizontal: isMobile ? 12 : 20,
                            vertical: isMobile ? 8 : 10),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // MODIFIED: Wrap the location section in its own isolated card
          // with overflow handling to prevent dropdown clipping
          _buildLocationSectionCard(isMobile),
        ],
      ),
    );
  }

  Widget _buildLocationSectionCard(bool isMobile) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 20),
      padding: EdgeInsets.all(isMobile ? 12 : 16),
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
          Text(
            "Clinic Location",
            style: TextStyle(
              fontSize: isMobile ? 16 : 18,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            "Pin your clinic's location on the map and provide complete address details",
            style: TextStyle(
              fontSize: isMobile ? 13 : 14,
              color: Colors.grey[700],
            ),
          ),
          const SizedBox(height: 16),

          // MODIFIED: Add onAddressChanged callback
          ClipRect(
            child: Obx(() => AdminPinMapsPage(
                  currentLocation: controller.selectedLocation.value,
                  onLocationSelected: (location) {
                    controller.selectedLocation.value = location;
                  },
                  // NEW: Handle address updates from map component
                  onAddressChanged: (address) {
                    setState(() {
                      _fullAddressFromMap = address;
                    });
                    // Update controller's address if needed
                    if (address.isNotEmpty) {
                      controller.addressController.text = address;
                    }
                  },
                )),
          ),

          const SizedBox(height: 16),

          // NEW: Show current address preview
          if (_fullAddressFromMap.isNotEmpty)
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.green[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.green[200]!),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.check_circle, color: Colors.green[700], size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Complete Address:',
                          style: TextStyle(
                            fontSize: isMobile ? 11 : 12,
                            fontWeight: FontWeight.w600,
                            color: Colors.green[700],
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _fullAddressFromMap,
                          style: TextStyle(
                            fontSize: isMobile ? 12 : 13,
                            color: Colors.black87,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

          const SizedBox(height: 16),
          Row(
            children: [
              const Spacer(),
              ElevatedButton.icon(
                onPressed: controller.isSaving.value
                    ? null
                    : () async {
                        // Ensure address is saved to controller before saving
                        if (_fullAddressFromMap.isNotEmpty) {
                          controller.addressController.text =
                              _fullAddressFromMap;
                        }
                        await controller.saveClinicSettings();
                      },
                icon: controller.isSaving.value
                    ? SizedBox(
                        width: isMobile ? 13 : 16,
                        height: isMobile ? 13 : 16,
                        child: const CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.save),
                label: Text(
                    controller.isSaving.value ? "Saving..." : "Save Location",
                    style: TextStyle(fontSize: isMobile ? 12 : 13)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color.fromARGB(255, 81, 115, 153),
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(
                      horizontal: isMobile ? 12 : 20,
                      vertical: isMobile ? 8 : 10),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSectionCard(
      {required String title, required Widget child, required bool isMobile}) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 20),
      padding: EdgeInsets.all(isMobile ? 12 : 16),
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
          Text(
            title,
            style: TextStyle(
              fontSize: isMobile ? 16 : 18,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }

  Widget _buildTimeField({
    required String value,
    required String label,
    required Function(String) onChanged,
    bool isMobile = false,
  }) {
    // Convert stored 24-hour format to 12-hour for display
    String displayValue = _convert24To12Hour(value);

    return TextField(
      readOnly: true,
      style: TextStyle(fontSize: isMobile ? 12 : 13),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(fontSize: isMobile ? 12 : 13),
        border: const OutlineInputBorder(),
        suffixIcon: const Icon(Icons.access_time, size: 18),
        contentPadding: EdgeInsets.symmetric(
            horizontal: isMobile ? 8 : 10, vertical: isMobile ? 10 : 12),
      ),
      controller: TextEditingController(text: displayValue),
      onTap: () async {
        // Parse current time (24-hour format from storage)
        final parts = value.split(':');
        final currentHour = int.parse(parts[0]);
        final currentMinute = int.parse(parts[1]);

        final TimeOfDay? time = await showTimePicker(
          context: context,
          initialTime: TimeOfDay(hour: currentHour, minute: currentMinute),
          builder: (context, child) {
            return MediaQuery(
              data: MediaQuery.of(context).copyWith(
                alwaysUse24HourFormat: false, // Force 12-hour format in picker
              ),
              child: child!,
            );
          },
        );

        if (time != null) {
          // Store in 24-hour format (for backend compatibility)
          final formattedTime24 =
              '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
          onChanged(formattedTime24);
        }
      },
    );
  }

  // Helper method to convert 24-hour to 12-hour format for display
  String _convert24To12Hour(String time24) {
    try {
      final parts = time24.split(':');
      final hour = int.parse(parts[0]);
      final minute = int.parse(parts[1]);
      final period = hour >= 12 ? 'PM' : 'AM';
      final displayHour = hour == 0 ? 12 : (hour > 12 ? hour - 12 : hour);

      return '${displayHour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')} $period';
    } catch (e) {
      return time24;
    }
  }

  Widget _buildClosedDatesSection(bool isMobile) {
    return _buildSectionCard(
      title: "Closed Dates",
      isMobile: isMobile,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  "Mark specific dates when your clinic will be closed (holidays, vacations, etc.)",
                  style: TextStyle(
                    fontSize: isMobile ? 13 : 14,
                    color: Colors.grey[700],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Date picker button
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => _showClosedDatePicker(isMobile),
                  icon: const Icon(Icons.event_busy),
                  label: const Text("Add Closed Date"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange[600],
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(
                      horizontal: isMobile ? 12 : 16,
                      vertical: isMobile ? 10 : 12,
                    ),
                  ),
                ),
              ),
              if (!isMobile) const SizedBox(width: 12),
              if (!isMobile)
                TextButton.icon(
                  onPressed: controller.selectedClosedDates.isEmpty
                      ? null
                      : () => _showClearClosedDatesDialog(),
                  icon: const Icon(Icons.clear_all),
                  label: const Text("Clear All"),
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.red,
                  ),
                ),
            ],
          ),

          const SizedBox(height: 16),

          // List of closed dates
          Obx(() {
            if (controller.selectedClosedDates.isEmpty) {
              return Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey[300]!),
                ),
                child: Center(
                  child: Column(
                    children: [
                      Icon(Icons.event_available,
                          size: isMobile ? 36 : 48, color: Colors.grey[400]),
                      const SizedBox(height: 8),
                      Text(
                        "No closed dates set",
                        style: TextStyle(
                          fontSize: isMobile ? 13 : 14,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }

            // Sort dates for display
            final sortedDates =
                List<DateTime>.from(controller.selectedClosedDates)
                  ..sort((a, b) => a.compareTo(b));

            return Container(
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey[300]!),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                children: [
                  // Header
                  Container(
                    padding: EdgeInsets.all(isMobile ? 10 : 12),
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(7),
                        topRight: Radius.circular(7),
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.event_busy,
                            size: isMobile ? 16 : 18,
                            color: Colors.orange[700]),
                        const SizedBox(width: 8),
                        Text(
                          "${sortedDates.length} Closed Date(s)",
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: isMobile ? 13 : 14,
                          ),
                        ),
                        const Spacer(),
                        if (isMobile)
                          IconButton(
                            icon: const Icon(Icons.clear_all, size: 18),
                            onPressed: () => _showClearClosedDatesDialog(),
                            tooltip: "Clear All",
                            color: Colors.red,
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                          ),
                      ],
                    ),
                  ),

                  // List of dates
                  ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: sortedDates.length,
                    separatorBuilder: (context, index) => Divider(
                      height: 1,
                      color: Colors.grey[300],
                    ),
                    itemBuilder: (context, index) {
                      final date = sortedDates[index];
                      final isToday = _isToday(date);
                      final isPast = date.isBefore(DateTime.now()) && !isToday;

                      return Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: isMobile ? 10 : 12,
                          vertical: isMobile ? 8 : 10,
                        ),
                        color: isPast ? Colors.grey[100] : null,
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: isPast
                                    ? Colors.grey[300]
                                    : Colors.orange[100],
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Icon(
                                Icons.event_busy,
                                color: isPast
                                    ? Colors.grey[600]
                                    : Colors.orange[700],
                                size: isMobile ? 18 : 20,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    _formatDateForDisplay(date),
                                    style: TextStyle(
                                      fontWeight: FontWeight.w600,
                                      fontSize: isMobile ? 13 : 14,
                                      color: isPast ? Colors.grey[600] : null,
                                      decoration: isPast
                                          ? TextDecoration.lineThrough
                                          : null,
                                    ),
                                  ),
                                  Text(
                                    _getDayOfWeek(date),
                                    style: TextStyle(
                                      fontSize: isMobile ? 11 : 12,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            if (isToday)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.blue[100],
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  "Today",
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.blue[700],
                                  ),
                                ),
                              ),
                            if (isPast)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.grey[300],
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  "Past",
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.grey[700],
                                  ),
                                ),
                              ),
                            const SizedBox(width: 8),
                            IconButton(
                              icon: Icon(
                                Icons.delete_outline,
                                size: isMobile ? 18 : 20,
                              ),
                              onPressed: () => _confirmRemoveClosedDate(date),
                              color: Colors.red,
                              tooltip: "Remove",
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ],
              ),
            );
          }),

          // Cleanup button for past dates
          Obx(() {
            final hasPastDates = controller.selectedClosedDates.any((date) {
              return date.isBefore(DateTime.now()) && !_isToday(date);
            });

            if (!hasPastDates) return const SizedBox.shrink();

            return Column(
              children: [
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () => _confirmRemovePastDates(),
                    icon: const Icon(Icons.cleaning_services),
                    label: const Text("Remove Past Dates"),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.grey[700],
                      side: BorderSide(color: Colors.grey[400]!),
                    ),
                  ),
                ),
              ],
            );
          }),

          const SizedBox(height: 20),

          // Save button
          Row(
            children: [
              const Spacer(),
              ElevatedButton.icon(
                onPressed: controller.isSaving.value
                    ? null
                    : controller.saveClinicSettings,
                icon: controller.isSaving.value
                    ? SizedBox(
                        width: isMobile ? 13 : 16,
                        height: isMobile ? 13 : 16,
                        child: const CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.save),
                label: Text(
                  controller.isSaving.value ? "Saving..." : "Save Closed Dates",
                  style: TextStyle(fontSize: isMobile ? 12 : 13),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color.fromARGB(255, 81, 115, 153),
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(
                    horizontal: isMobile ? 12 : 20,
                    vertical: isMobile ? 8 : 10,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showClosedDatePicker(bool isMobile) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        DateTime? selectedDate;

        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text("Select Closed Date"),
              content: SizedBox(
                width: isMobile ? double.maxFinite : 400,
                child: TableCalendar(
                  focusedDay: selectedDate ?? DateTime.now(),
                  firstDay: DateTime.now(),
                  lastDay: DateTime.now().add(const Duration(days: 365)),
                  selectedDayPredicate: (day) =>
                      selectedDate != null && isSameDay(day, selectedDate),
                  onDaySelected: (selected, focused) {
                    setState(() => selectedDate = selected);
                  },
                  calendarStyle: CalendarStyle(
                    selectedDecoration: const BoxDecoration(
                      color: Colors.orange,
                      shape: BoxShape.circle,
                    ),
                    todayDecoration: BoxDecoration(
                      color: Colors.orange.withOpacity(0.3),
                      shape: BoxShape.circle,
                    ),
                    // Mark already closed dates
                    disabledDecoration: BoxDecoration(
                      color: Colors.grey[300],
                      shape: BoxShape.circle,
                    ),
                  ),
                  enabledDayPredicate: (day) {
                    // Disable dates that are already closed
                    return !controller.isDateClosed(day);
                  },
                  headerStyle: const HeaderStyle(
                    formatButtonVisible: false,
                    titleCentered: true,
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text("Cancel"),
                ),
                ElevatedButton(
                  onPressed: selectedDate == null
                      ? null
                      : () {
                          controller.addClosedDate(selectedDate!);
                          Navigator.pop(context);
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange[600],
                    foregroundColor: Colors.white,
                  ),
                  child: const Text("Add Date"),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _confirmRemoveClosedDate(DateTime date) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text("Remove Closed Date"),
          content: Text(
            "Remove ${_formatDateForDisplay(date)} from closed dates?",
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancel"),
            ),
            ElevatedButton(
              onPressed: () {
                controller.removeClosedDate(date);
                Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              child: const Text("Remove"),
            ),
          ],
        );
      },
    );
  }

  void _showClearClosedDatesDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text("Clear All Closed Dates"),
          content: Text(
            "Remove all ${controller.selectedClosedDates.length} closed dates?",
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancel"),
            ),
            ElevatedButton(
              onPressed: () {
                controller.clearAllClosedDates();
                Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              child: const Text("Clear All"),
            ),
          ],
        );
      },
    );
  }

  void _confirmRemovePastDates() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text("Remove Past Dates"),
          content: const Text(
            "Remove all closed dates that have already passed?",
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancel"),
            ),
            ElevatedButton(
              onPressed: () {
                controller.removePastClosedDates();
                Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                foregroundColor: Colors.white,
              ),
              child: const Text("Remove"),
            ),
          ],
        );
      },
    );
  }

  bool _isToday(DateTime date) {
    final now = DateTime.now();
    return date.year == now.year &&
        date.month == now.month &&
        date.day == now.day;
  }

  String _formatDateForDisplay(DateTime date) {
    final months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec'
    ];
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }

  String _getDayOfWeek(DateTime date) {
    final days = [
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
      'Sunday'
    ];
    return days[date.weekday - 1];
  }

  Widget _buildDashboardTilePreview(bool isMobile) {
    final clinic = controller.clinic.value;
    final settings = controller.clinicSettings.value;
    final displayImage = controller.tempDashboardPic.value.isNotEmpty
        ? controller.tempDashboardPic.value
        : (clinic?.image ?? '');

    // Get services for display (similar to WebDashboardTile)
    List<String> services = [];
    if (settings != null && settings.services.isNotEmpty) {
      services = settings.services.take(3).toList();
    } else if (clinic?.services.isNotEmpty ?? false) {
      services = clinic!.services
          .split(RegExp(r'[,;|\n]'))
          .map((s) => s.trim())
          .where((s) => s.isNotEmpty)
          .take(3)
          .toList();
    }

    // Calculate tile dimensions
    final tileWidth = isMobile ? double.infinity : 350.0;
    final tileHeight = isMobile ? 450.0 : 490.0;

    return Container(
      width: tileWidth,
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Image with status badge
          Stack(
            children: [
              SizedBox(
                height: tileHeight * 0.7,
                width: double.infinity,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(15),
                  child: displayImage.isNotEmpty
                      ? Image.network(
                          displayImage,
                          fit: BoxFit.cover,
                          width: double.infinity,
                          loadingBuilder: (context, child, loadingProgress) {
                            if (loadingProgress == null) return child;
                            return Container(
                              color: Colors.grey[200],
                              child: const Center(
                                child: CircularProgressIndicator(),
                              ),
                            );
                          },
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              color: Colors.grey[200],
                              child: Center(
                                child: Icon(Icons.image_not_supported,
                                    size: 48, color: Colors.grey[400]),
                              ),
                            );
                          },
                        )
                      : Container(
                          color: Colors.grey[200],
                          child: Center(
                            child: Icon(Icons.photo,
                                size: 48, color: Colors.grey[400]),
                          ),
                        ),
                ),
              ),
              // Status Badge
              Positioned(
                top: 10,
                left: 10,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: controller.isClinicOpen.value
                        ? Colors.green
                        : Colors.red,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    controller.isClinicOpen.value ? "OPEN" : "CLOSED",
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 8,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          // Clinic Name and Rating
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  clinic?.clinicName ?? "Clinic Name",
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const Row(
                children: [
                  Icon(Icons.star, color: Colors.amber, size: 18),
                  SizedBox(width: 3),
                  Text(
                    "4.95",
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 4),
          // Address
          Row(
            children: [
              Expanded(
                child: Text(
                  clinic?.address ?? "Address",
                  style: const TextStyle(
                    color: Colors.grey,
                    fontSize: 13,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          // Hours
          Row(
            children: [
              Icon(
                Icons.access_time,
                size: 14,
                color: Colors.grey[600],
              ),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  settings?.getTodayHours() ?? "Hours",
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          // Services display
          if (services.isNotEmpty) ...[
            const SizedBox(height: 4),
            Row(
              children: [
                const Padding(
                  padding: EdgeInsets.only(right: 8),
                  child: Text(
                    "Services",
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                ),
                Expanded(
                  child: Row(
                    children: services.take(2).map((service) {
                      return Padding(
                        padding: const EdgeInsets.only(right: 4),
                        child: Tooltip(
                          message: service,
                          child: Icon(
                            _getServiceIconForPreview(service),
                            size: 18,
                            color: Colors.grey[600],
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

// NEW: Add helper method for service icons
  IconData _getServiceIconForPreview(String service) {
    String serviceLower = service.toLowerCase();
    if (serviceLower.contains('vaccination') ||
        serviceLower.contains('vaccine')) {
      return Icons.vaccines_outlined;
    } else if (serviceLower.contains('surgery') ||
        serviceLower.contains('operation')) {
      return Icons.local_hospital_outlined;
    } else if (serviceLower.contains('checkup') ||
        serviceLower.contains('examination')) {
      return Icons.health_and_safety_outlined;
    } else if (serviceLower.contains('grooming')) {
      return Icons.pets_outlined;
    } else if (serviceLower.contains('dental')) {
      return Icons.medication_outlined;
    } else {
      return Icons.medical_services_outlined;
    }
  }
}
