import 'package:capstone_app/utils/logout_helper.dart';
import 'package:capstone_app/utils/appwrite_constant.dart';
import 'package:capstone_app/web/admin_web/components/appointments/admin_web_appointment_controller.dart';
import 'package:capstone_app/web/admin_web/pages/admin_settings_page.dart';
import 'package:capstone_app/data/repository/auth.repository.dart';
import 'package:capstone_app/web/admin_web/pages/admin_web_appointments.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';

class AdminWebProfile extends StatefulWidget {
  final double? right;
  final double? top;
  final double? width;

  const AdminWebProfile(
      {super.key, this.right = 75, this.top = 70, this.width = 250});

  @override
  State<AdminWebProfile> createState() => _AdminWebProfileState();
}

class _AdminWebProfileState extends State<AdminWebProfile> {
  OverlayEntry? _overlayEntry;
  final GetStorage storage = GetStorage();
  late AuthRepository _authRepository;

  String _cachedClinicName = 'Clinic';
  String _cachedProfilePictureId = '';
  bool _isInitialized = false;

  // NEW: Flag to prevent operations during logout
  bool _isLoggingOut = false;

  @override
  void initState() {
    super.initState();
    _authRepository = Get.find<AuthRepository>();
    _loadClinicDataFromStorage();

    // ✅ CRITICAL FIX: Initialize profile data immediately on widget creation
    _initializeProfileData();
  }

  void _loadClinicDataFromStorage() {
    final userRole = storage.read("role") as String? ?? "admin";
    final isStaff = userRole == 'staff';

    if (isStaff) {
      // STAFF: Load staff profile picture
      String? staffProfilePictureId =
          storage.read("staffProfilePictureId") as String? ?? '';

      // Clean the ID if it's a URL
      if (staffProfilePictureId.isNotEmpty) {
        final cleanedId = _extractFileIdFromUrl(staffProfilePictureId);
        if (cleanedId != staffProfilePictureId) {
          staffProfilePictureId = cleanedId;
          storage.write("staffProfilePictureId", cleanedId);
        }
      }

      _cachedProfilePictureId = staffProfilePictureId;
    } else {
      // ADMIN: Load clinic data
      _cachedClinicName = storage.read("clinicName") as String? ?? 'Clinic';

      String? clinicProfilePictureId =
          storage.read("clinicProfilePictureId") as String? ?? '';

      // Clean the ID if it's a URL
      if (clinicProfilePictureId.isNotEmpty) {
        final cleanedId = _extractFileIdFromUrl(clinicProfilePictureId);
        if (cleanedId != clinicProfilePictureId) {
          clinicProfilePictureId = cleanedId;
          storage.write("clinicProfilePictureId", cleanedId);
        }
      }

      _cachedProfilePictureId = clinicProfilePictureId;
    }
  }

  Future<void> _initializeProfileData() async {
    // CRITICAL: Check if we're logging out
    if (_isLoggingOut) {
      return;
    }

    try {
      final userRole = storage.read("role") as String? ?? "admin";
      final isStaff = userRole == 'staff';


      if (isStaff) {
        // STAFF: Fetch staff data from database
        final staffId = storage.read("staffId") as String?;

        if (staffId != null && staffId.isNotEmpty) {

          final staff = await _authRepository.getStaffByDocumentId(staffId);

          if (staff != null) {
            final staffProfilePictureId = staff.image;
            final staffEmail = staff.email.isNotEmpty ? staff.email : 'N/A';
            final staffName = staff.name;


            // CRITICAL: Check if still mounted and not logging out
            if (mounted && !_isLoggingOut) {
              setState(() {
                _cachedProfilePictureId = staffProfilePictureId;
                _isInitialized = true;
              });

              // CRITICAL: Update storage with fresh data
              storage.write('staffProfilePictureId', staffProfilePictureId);
              storage.write('email', staffEmail);
              storage.write('name', staffName);

            }
          } else {
            _isInitialized = true;
          }
        } else {
          _isInitialized = true;
        }
      } else {
        // ADMIN: Fetch clinic data from database
        final clinicId = storage.read("clinicId") as String?;

        if (clinicId == null || clinicId.isEmpty) {
          _isInitialized = true;
          return;
        }

        final clinicDoc = await _authRepository.getClinicById(clinicId);
        if (clinicDoc != null) {
          final newClinicName = clinicDoc.data['clinicName'] ?? 'Clinic';
          final newProfilePictureId = clinicDoc.data['profilePictureId'] ?? '';


          // CRITICAL: Check if still mounted and not logging out
          if (mounted && !_isLoggingOut) {
            setState(() {
              _cachedClinicName = newClinicName;
              _cachedProfilePictureId = newProfilePictureId;
              _isInitialized = true;
            });

            storage.write('clinicName', newClinicName);
            storage.write('clinicProfilePictureId', newProfilePictureId);
          }
        } else {
          _isInitialized = true;
        }
      }

    } catch (e, stackTrace) {
      if (mounted && !_isLoggingOut) {
        _isInitialized = true;
      }
    }
  }

  Future<void> _refreshClinicDataInBackground() async {
    // CRITICAL: Don't refresh if logging out
    if (_isLoggingOut) {
      return;
    }

    try {
      final userRole = storage.read("role") as String? ?? "admin";
      final isStaff = userRole == 'staff';


      if (isStaff) {
        // STAFF: Refresh staff data
        final staffId = storage.read("staffId") as String?;
        if (staffId != null && staffId.isNotEmpty) {

          final staff = await _authRepository.getStaffByDocumentId(staffId);
          if (staff != null && !_isLoggingOut) {
            final staffProfilePictureId = staff.image;
            final staffEmail = staff.email.isNotEmpty ? staff.email : 'N/A';


            if (mounted && !_isLoggingOut) {
              setState(() {
                _cachedProfilePictureId = staffProfilePictureId;
              });

              storage.write('staffProfilePictureId', staffProfilePictureId);
              storage.write('email', staffEmail);

            }
          }
        }
      } else {
        // ADMIN: Refresh clinic data
        final clinicId = storage.read("clinicId") as String?;
        if (clinicId == null || clinicId.isEmpty) return;

        final clinicDoc = await _authRepository.getClinicById(clinicId);
        if (clinicDoc != null && !_isLoggingOut) {
          final newClinicName = clinicDoc.data['clinicName'] ?? 'Clinic';
          final newProfilePictureId = clinicDoc.data['profilePictureId'] ?? '';

          if (mounted && !_isLoggingOut) {
            setState(() {
              _cachedClinicName = newClinicName;
              _cachedProfilePictureId = newProfilePictureId;
            });
            storage.write('clinicName', newClinicName);
            storage.write('clinicProfilePictureId', newProfilePictureId);
          }
        }
      }

    } catch (e) {
    }
  }

  void _togglePopup(BuildContext context) {
    // CRITICAL: Don't toggle popup if logging out
    if (_isLoggingOut) {
      return;
    }

    if (_overlayEntry == null) {
      _refreshClinicDataInBackground();
      _overlayEntry = _createOverlayEntry(context);
      Overlay.of(context).insert(_overlayEntry!);
    } else {
      _closePopup();
    }
  }

  void _closePopup() {
    _overlayEntry?.remove();
    _overlayEntry = null;
  }

  void _navigateToAdminSettings(int index) {
    // CRITICAL: Don't navigate if logging out
    if (_isLoggingOut) {
      return;
    }

    _closePopup();
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => AdminSettingsPage(initialIndex: index),
      ),
    );
  }

  void _showLogoutDialog(BuildContext context) {
    if (_isLoggingOut) {
      return;
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Logout'),
          content: const Text('Are you sure you want to logout?'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                Navigator.of(context).pop();


                // ✅ CRITICAL: Set logout flag IMMEDIATELY
                setState(() {
                  _isLoggingOut = true;
                });

                // ✅ CRITICAL: Notify AdminWebAppointments page to set its logout flag
                _notifyAppointmentsPageLogout();

                // CRITICAL: Close any open overlay/popup
                _closePopup();

                // CRITICAL: Show loading before logout
                showDialog(
                  context: context,
                  barrierDismissible: false,
                  builder: (BuildContext context) {
                    return WillPopScope(
                      onWillPop: () async => false,
                      child: const Center(
                        child: CircularProgressIndicator(),
                      ),
                    );
                  },
                );

                try {
                  // Call the logout helper
                  await LogoutHelper.logout();
                } catch (e) {

                  if (context.mounted) {
                    Navigator.of(context).pop();
                  }

                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(
                            'Logout error. You have been signed out locally.'),
                        backgroundColor: Colors.orange,
                      ),
                    );
                  }
                } finally {
                  if (mounted) {
                    setState(() {
                      _isLoggingOut = false;
                    });
                  }
                }
              },
              child: const Text(
                'Logout',
                style: TextStyle(color: Colors.red),
              ),
            ),
          ],
        );
      },
    );
  }

  void _notifyAppointmentsPageLogout() {
    try {
      // ✅ Use Get.context to find the current BuildContext in scope
      final currentContext = Get.context;

      if (currentContext == null) {
        return;
      }

      // ✅ Use the generic form of findAncestorStateOfType (no explicit type argument)
      final dynamic ancestorState = currentContext.findAncestorStateOfType();

      // ✅ Safely call _setLoggingOut if that method exists
      if (ancestorState != null &&
          ancestorState.mounted &&
          ancestorState is State &&
          ancestorState.widget is AdminWebAppointments &&
          (ancestorState as dynamic)._setLoggingOut != null) {
        (ancestorState as dynamic)._setLoggingOut(true);
      } else {
      }
    } catch (e, stackTrace) {
    }
  }

  OverlayEntry _createOverlayEntry(BuildContext context) {
    final userName = storage.read("name") as String? ?? "User";
    final userRole = storage.read("role") as String? ?? "user";
    final isStaff = userRole == 'staff';

    final userEmail = storage.read("email") as String? ?? "N/A";

    String? profilePictureId;
    if (isStaff) {
      profilePictureId = storage.read("staffProfilePictureId") as String?;
    } else {
      profilePictureId = storage.read("clinicProfilePictureId") as String?;
    }

    return OverlayEntry(
      builder: (context) => Stack(
        children: [
          Positioned.fill(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: _closePopup,
              child: Container(),
            ),
          ),
          Positioned(
            right: widget.right,
            top: widget.top,
            width: widget.width,
            child: Material(
              elevation: 5,
              borderRadius: BorderRadius.circular(10),
              color: Colors.white,
              child: Padding(
                padding: const EdgeInsets.only(top: 10, bottom: 10),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ListTile(
                      leading: _buildProfileAvatar(profilePictureId, isStaff),
                      title: Text(
                        userName,
                        style: const TextStyle(
                          color: Colors.black87,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${userRole.toUpperCase()} • $_cachedClinicName',
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 11,
                            ),
                          ),
                          if (userEmail != "N/A")
                            Text(
                              userEmail,
                              style: TextStyle(
                                color: Colors.grey[500],
                                fontSize: 10,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                        ],
                      ),
                    ),
                    const Divider(color: Colors.black87, height: 1),
                    SizedBox(
                      width: double.infinity,
                      child: _popupItem(
                        "Profile",
                        Icons.person_outline,
                        () {
                          _navigateToAdminSettings(0);
                        },
                      ),
                    ),
                    SizedBox(
                      width: double.infinity,
                      child: _popupItem(
                        "Settings",
                        Icons.settings_outlined,
                        () {
                          _navigateToAdminSettings(1);
                        },
                      ),
                    ),
                    // NEW: Verify User menu item (only show for admins, not staff)
                    if (!isStaff)
                      SizedBox(
                        width: double.infinity,
                        child: _popupItem(
                          "Verify User",
                          Icons.verified_user_outlined,
                          () {
                            _navigateToAdminSettings(2);
                          },
                        ),
                      ),
                    SizedBox(
                      width: double.infinity,
                      child: _popupItem(
                        "Help & Support",
                        Icons.help_outline,
                        () {
                          _navigateToAdminSettings(3);
                        },
                      ),
                    ),
                    SizedBox(
                      width: double.infinity,
                      child: _popupItem(
                        "Send Feedback",
                        Icons.feedback_outlined,
                        () {
                          _navigateToAdminSettings(4);
                        },
                      ),
                    ),
                    const Divider(color: Colors.black87, height: 1),
                    SizedBox(
                      width: double.infinity,
                      child: _popupItem(
                        "Sign out",
                        Icons.logout_outlined,
                        () {
                          _closePopup();
                          _showLogoutDialog(context);
                        },
                        isDestructive: true,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileAvatar(String? profilePictureId, bool isStaff) {

    // Clean the profile picture ID
    if (profilePictureId != null && profilePictureId.isNotEmpty) {
      final cleanedId = _extractFileIdFromUrl(profilePictureId);
      profilePictureId = cleanedId;
    }


    if (profilePictureId != null && profilePictureId.isNotEmpty) {
      final imageUrl = _getProfilePictureUrl(profilePictureId);

      return CircleAvatar(
        radius: 20,
        backgroundColor: Colors.grey[200],
        child: ClipOval(
          child: Image.network(
            imageUrl,
            width: 40,
            height: 40,
            fit: BoxFit.cover,
            loadingBuilder: (context, child, loadingProgress) {
              if (loadingProgress == null) {
                return child;
              }
              return Center(
                child: CircularProgressIndicator(
                  value: loadingProgress.expectedTotalBytes != null
                      ? loadingProgress.cumulativeBytesLoaded /
                          loadingProgress.expectedTotalBytes!
                      : null,
                  strokeWidth: 2,
                  color: Colors.purple,
                ),
              );
            },
            errorBuilder: (context, error, stackTrace) {

              return _buildDefaultAvatar(isStaff);
            },
          ),
        ),
      );
    }

    return _buildDefaultAvatar(isStaff);
  }

  String _extractFileIdFromUrl(String urlOrId) {
    if (!urlOrId.contains('http')) {
      return urlOrId;
    }

    try {
      final uri = Uri.parse(urlOrId);
      final pathSegments = uri.pathSegments;
      final filesIndex = pathSegments.indexOf('files');
      if (filesIndex != -1 && filesIndex + 1 < pathSegments.length) {
        return pathSegments[filesIndex + 1];
      }
    } catch (e) {
    }

    return urlOrId;
  }

  Widget _buildDefaultAvatar(bool isStaff) {
    return CircleAvatar(
      radius: 20,
      backgroundColor: Colors.purple.withOpacity(0.7),
      child: Icon(
        isStaff ? Icons.person : Icons.local_hospital,
        color: Colors.white,
        size: 18,
      ),
    );
  }

  String _getProfilePictureUrl(String profilePictureId) {
    return '${AppwriteConstants.endPoint}/storage/buckets/${AppwriteConstants.imageBucketID}/files/$profilePictureId/view?project=${AppwriteConstants.projectID}';
  }

  Widget _popupItem(
    String text,
    IconData icon,
    VoidCallback onTap, {
    bool isDestructive = false,
  }) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10.0, horizontal: 12),
        child: Row(
          children: [
            Icon(
              icon,
              size: 18,
              color: isDestructive ? Colors.red[600] : Colors.grey[700],
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                text,
                style: TextStyle(
                  color: isDestructive ? Colors.red[600] : Colors.black87,
                  fontSize: 13,
                  fontWeight: isDestructive ? FontWeight.w600 : FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // CRITICAL: Don't build profile if logging out
    if (_isLoggingOut) {
      return const SizedBox.shrink();
    }

    final userName = storage.read("name") as String? ?? "User";
    final userRole = storage.read("role") as String? ?? "user";
    final isStaff = userRole == 'staff';


    // Use the cached profile picture ID that was loaded/initialized
    String? profilePictureId;
    if (_cachedProfilePictureId.isNotEmpty) {
      profilePictureId = _cachedProfilePictureId;
    }

    return Padding(
      padding: const EdgeInsets.only(right: 16),
      child: Tooltip(
        message: userName,
        child: InkWell(
          onTap: () => _togglePopup(context),
          borderRadius: BorderRadius.circular(50),
          child: _buildProfileAvatar(profilePictureId, isStaff),
        ),
      ),
    );
  }

  @override
  void dispose() {
    // CRITICAL: Close overlay before disposing
    _overlayEntry?.remove();
    _overlayEntry = null;
    super.dispose();
  }
}
