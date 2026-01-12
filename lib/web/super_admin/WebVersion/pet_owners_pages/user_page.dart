import 'package:capstone_app/web/super_admin/WebVersion/pet_owners_pages/archived_user_dashboard.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:capstone_app/data/repository/auth.repository.dart';
import 'package:capstone_app/data/models/user_model.dart';
import 'package:appwrite/appwrite.dart';
import 'package:capstone_app/utils/appwrite_constant.dart';
import 'package:intl/intl.dart';
import 'package:capstone_app/web/super_admin/WebVersion/vet_clinic_pages/veterinary_clinics/super_ad_vet_clinic_dashboard.dart';
import 'package:capstone_app/web/super_admin/WebVersion/view_report/user_app_feedback/app_feedback.dart';
import 'package:capstone_app/web/super_admin/WebVersion/view_report/user_vet_feedback/vet_deletion_reports.dart';
import 'package:capstone_app/utils/logout_helper.dart';
import 'package:capstone_app/utils/image_helper.dart';

/// ============================================
/// SUPER ADMIN USER MANAGEMENT SCREEN
/// ============================================
class SuperAdminUserManagementScreen extends StatefulWidget {
  const SuperAdminUserManagementScreen({super.key});
  @override
  State<SuperAdminUserManagementScreen> createState() =>
      _SuperAdminUserManagementScreenState();
}

class _SuperAdminUserManagementScreenState
    extends State<SuperAdminUserManagementScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final AuthRepository _authRepository = Get.find<AuthRepository>();

  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  bool _isLoggingOut = false;

  // Real-time subscription
  RealtimeSubscription? _userSubscription;
  RealtimeSubscription? _verificationSubscription;
  RealtimeSubscription? _storageSubscription;
  // User lists
  List<User> _allUsers = [];
  List<User> _verifiedUsers = [];
  List<User> _unverifiedUsers = [];

  

  bool _isLoading = true;
  String _searchQuery = '';
  String _selectedSort = "newest";

  // Colors
  static const Color backgroundColor = Color.fromRGBO(248, 253, 255, 1);
  static const Color primaryBlue = Color.fromRGBO(81, 115, 153, 1);
  static const Color accentTeal = Color(0xFF5B9BD5);
  static const Color lightBlue = Color(0xFF9FC5E8);
  static const Color deepBlue = Color(0xFF2F4F7F);
  static const Color vetGreen = Color(0xFF34D399);
  static const Color vetOrange = Color(0xFFF59E0B);
  static const Color mediumGray = Color(0xFF9CA3AF);
  static const Color darkText = Color(0xFF374151);

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadUsers();
    _setupRealtimeSubscriptions();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _userSubscription?.close();
    _verificationSubscription?.close();
    _storageSubscription?.close();
    super.dispose();
  }

  /// Load all users from database
Future<void> _loadUsers() async {
  setState(() => _isLoading = true);

  try {

    // Get all users from database
    final docs = await _authRepository.appWriteProvider.databases!.listDocuments(
      databaseId: AppwriteConstants.dbID,
      collectionId: AppwriteConstants.usersCollectionID,
      queries: [
        Query.equal('role', ['customer', 'user']),
        Query.orderDesc('\$createdAt'),
        Query.limit(1000),
      ],
    );
    
    
    // Convert to User models
    _allUsers = docs.documents.map((doc) => User.fromMap(doc.data)).toList();
    
    // ============================================
    // CRITICAL: Check verification status from idVerificationCollectionID
    // ============================================
    
    // Get ALL verification records at once (more efficient)
    final verificationDocs = await _authRepository.appWriteProvider.databases!.listDocuments(
      databaseId: AppwriteConstants.dbID,
      collectionId: AppwriteConstants.idVerificationCollectionID,
      queries: [
        Query.equal('status', 'approved'), // Only get approved verifications
        Query.limit(1000),
      ],
    );
    
    
    // Create a Set of verified user IDs for O(1) lookup
    final verifiedUserIds = <String>{};
    for (var verificationDoc in verificationDocs.documents) {
      final userId = verificationDoc.data['userId'] as String?;
      if (userId != null) {
        verifiedUserIds.add(userId);
      }
    }
    
    
    // Update each user's verification status based on ID Verification collection
    int verifiedCount = 0;
    int unverifiedCount = 0;
    
    for (var user in _allUsers) {
      // Check if user exists in verified IDs set
      final isVerified = verifiedUserIds.contains(user.userId);
      
      // IMPORTANT: We're NOT updating the database here
      // Just updating the local object for UI display
      user.idVerified = isVerified;
      
      if (isVerified) {
        verifiedCount++;
      } else {
        unverifiedCount++;
      }
    }
    
    
    // Split into verified and unverified lists
    _categorizeUsers();
    
    setState(() => _isLoading = false);
    
  } catch (e) {
    
    setState(() => _isLoading = false);

    Get.snackbar(
      'Error',
      'Failed to load users: $e',
      backgroundColor: Colors.red,
      colorText: Colors.white,
    );
  }
}

  /// Categorize users into verified and unverified
  void _categorizeUsers() {
    _verifiedUsers = _allUsers.where((user) => user.idVerified).toList();
    _unverifiedUsers = _allUsers.where((user) => !user.idVerified).toList();

    _sortUsers(_verifiedUsers);
    _sortUsers(_unverifiedUsers);

  }
  /// Show sort options modal
void _showSortMenu() {
  showModalBottomSheet(
    context: context,
    backgroundColor: Colors.transparent,
    builder: (context) => Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Colors.white, backgroundColor],
        ),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: [
          BoxShadow(
            color: primaryBlue.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [primaryBlue.withOpacity(0.2), accentTeal.withOpacity(0.1)],
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.filter_list, color: primaryBlue, size: 24),
              ),
              const SizedBox(width: 12),
              const Text(
                'Sort Users',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: deepBlue,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          _buildSortOption(
            'Newest First',
            'Recently registered users',
            Icons.arrow_downward_rounded,
            'newest',
            [accentTeal, primaryBlue],
          ),
          const SizedBox(height: 12),
          _buildSortOption(
            'Oldest First',
            'Long-time registered users',
            Icons.arrow_upward_rounded,
            'oldest',
            [vetOrange, primaryBlue],
          ),
          const SizedBox(height: 12),
          _buildSortOption(
            'Alphabetical (A-Z)',
            'Sort by user name',
            Icons.sort_by_alpha_rounded,
            'alphabetical',
            [primaryBlue, deepBlue],
          ),
          const SizedBox(height: 16),
        ],
      ),
    ),
  );
}

/// Build individual sort option
Widget _buildSortOption(
  String title,
  String subtitle,
  IconData icon,
  String sortValue,
  List<Color> colors,
) {
  final isSelected = _selectedSort == sortValue;

  return InkWell(
    onTap: () {
      setState(() {
        _selectedSort = sortValue;
        _categorizeUsers(); // Re-categorize and sort
      });
      Navigator.pop(context);
    },
    borderRadius: BorderRadius.circular(16),
    child: Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: isSelected
            ? LinearGradient(colors: [colors[0].withOpacity(0.15), colors[1].withOpacity(0.1)])
            : null,
        color: isSelected ? null : Colors.grey[50],
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isSelected ? colors[0] : Colors.grey[300]!,
          width: isSelected ? 2 : 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: colors),
              borderRadius: BorderRadius.circular(12),
              boxShadow: isSelected
                  ? [BoxShadow(color: colors[0].withOpacity(0.3), blurRadius: 8, offset: const Offset(0, 4))]
                  : null,
            ),
            child: Icon(icon, color: Colors.white, size: 20),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: isSelected ? colors[0] : deepBlue,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
          if (isSelected)
            Icon(Icons.check_circle, color: colors[0], size: 24),
        ],
      ),
    ),
  );
}

    /// Sort users based on selected sort option
    void _sortUsers(List<User> users) {
      switch (_selectedSort) {
        case 'alphabetical':
          users.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
          break;
        case 'oldest':
          // Sort by user creation date (oldest first)
          users.sort((a, b) {
            // Using email as proxy for account age if no creation date available
            return a.userId.compareTo(b.userId);
          });
          break;
        case 'newest':
        default:
          // Sort by user creation date (newest first)
          users.sort((a, b) {
            return b.userId.compareTo(a.userId);
          });
          break;
      }
    }

  /// Setup real-time subscriptions for users and verifications
  void _setupRealtimeSubscriptions() {
  try {
    final realtime = Realtime(_authRepository.appWriteProvider.client);

    // ============================================
    // SUBSCRIPTION: ID Verification Collection Changes (PRIMARY)
    // ============================================
    _verificationSubscription = realtime.subscribe([
      'databases.${AppwriteConstants.dbID}.collections.${AppwriteConstants.idVerificationCollectionID}.documents'
    ]);

    _verificationSubscription!.stream.listen((response) {

      final payload = response.payload;
      final status = payload['status'] as String?;
      final userId = payload['userId'] as String?;
      
      
      // Check if this is a verification approval
      if (status == 'approved' && userId != null) {
        
        // Update the specific user's verification status locally
        _updateUserVerificationStatus(userId, true);
        
        // Show success notification
        Get.snackbar(
          'User Verified',
          'A user has been successfully verified',
          backgroundColor: const Color(0xFF34D399),
          colorText: Colors.white,
          icon: const Icon(Icons.verified_user, color: Colors.white),
          duration: const Duration(seconds: 3),
        );
      } else if (status == 'rejected' && userId != null) {
        _updateUserVerificationStatus(userId, false);
      }
    });

    // ============================================
    // SUBSCRIPTION: Storage Changes (Profile Pictures)
    // ============================================
    _storageSubscription = realtime
        .subscribe(['buckets.${AppwriteConstants.imageBucketID}.files']);

    _storageSubscription!.stream.listen((response) {

      if (response.events.contains('buckets.*.files.*')) {
        _loadUsers();
      }
    });

  } catch (e) {
  }
}
// ADD this NEW method after _setupRealtimeSubscriptions:
void _updateUserVerificationStatus(String userId, bool isVerified) {
  setState(() {
    // Find the user in all users list
    final userIndex = _allUsers.indexWhere((u) => u.userId == userId);
    
    if (userIndex != -1) {
      
      // Update the user object (local only)
      _allUsers[userIndex].idVerified = isVerified;
      
      // Re-categorize users to move between verified/unverified lists
      _categorizeUsers();
      
      
      // Show success snackbar
      Get.snackbar(
        isVerified ? 'User Verified' : 'Verification Removed',
        '${_allUsers[userIndex].name} has been ${isVerified ? "verified and moved to the Verified tab" : "moved to the Unverified tab"}',
        backgroundColor: isVerified ? const Color(0xFF34D399) : const Color(0xFFF59E0B),
        colorText: Colors.white,
        icon: Icon(
          isVerified ? Icons.verified_user : Icons.pending,
          color: Colors.white,
        ),
        duration: const Duration(seconds: 3),
      );
    } else {
      _loadUsers();
    }
  });
}

  Future<bool> _checkUserVerificationStatus(String userId) async {
    try {
      final verificationDoc = await _authRepository.appWriteProvider.databases!.listDocuments(
        databaseId: AppwriteConstants.dbID,
        collectionId: AppwriteConstants.idVerificationCollectionID,
        queries: [
          Query.equal('userId', userId),
          Query.equal('status', 'approved'),
          Query.limit(1),
        ],
      );
      
      return verificationDoc.documents.isNotEmpty;
    } catch (e) {
      return false;
    }
  }

  /// Filter users based on search query
  List<User> _filterUsers(List<User> users) {
    if (_searchQuery.isEmpty) return users;

    return users.where((user) {
      final nameLower = user.name.toLowerCase();
      final emailLower = user.email.toLowerCase();
      final phoneLower = (user.phone ?? '').toLowerCase();
      final queryLower = _searchQuery.toLowerCase();

      return nameLower.contains(queryLower) ||
          emailLower.contains(queryLower) ||
          phoneLower.contains(queryLower);
    }).toList();
  }

  /// Show user details dialog
  void _showUserDetails(User user) {
    showDialog(
      context: context,
      builder: (context) => UserDetailsDialog(
        user: user,
        authRepository: _authRepository,
        onUserUpdated: _loadUsers,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktop = screenWidth > 1024;
    final isTablet = screenWidth > 600 && screenWidth <= 1024;

    return Scaffold(
      key: _scaffoldKey, // ADD THIS LINE
      backgroundColor: backgroundColor,
      drawer: _buildDrawer(context),
      appBar: AppBar(
        surfaceTintColor: Colors.transparent,
        backgroundColor: backgroundColor,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.menu_rounded, color: primaryBlue),
          onPressed: () {
            _scaffoldKey.currentState?.openDrawer();
          },
          tooltip: 'Menu',
        ),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [primaryBlue, accentTeal],
                ),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.people, color: Colors.white, size: 24),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Text(
                'Pet Owner Management',
                style: TextStyle(
                  color: primaryBlue,
                  fontWeight: FontWeight.bold,
                  fontSize: 22,
                ),
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: primaryBlue),
            onPressed: _loadUsers,
            tooltip: 'Refresh',
          ),
          const SizedBox(width: 8),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(160),
          child: Column(
            children: [
              // Search bar section
                  Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: isDesktop ? 32 : 16,
                      vertical: 8,
                    ),
                    child: Row(
                      children: [
                        // Search Bar
                        Expanded(
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: [
                                BoxShadow(
                                  color: primaryBlue.withOpacity(0.1),
                                  blurRadius: 10,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: TextField(
                              onChanged: (value) => setState(() => _searchQuery = value),
                              decoration: InputDecoration(
                                hintText: 'Search by name, email, or phone...',
                                prefixIcon: const Icon(Icons.search, color: primaryBlue),
                                suffixIcon: _searchQuery.isNotEmpty
                                    ? IconButton(
                                        icon: const Icon(Icons.clear, color: mediumGray),
                                        onPressed: () => setState(() => _searchQuery = ''),
                                      )
                                    : null,
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide.none,
                                ),
                                filled: true,
                                fillColor: Colors.white,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        
                        // Sort Button
                        Container(
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [primaryBlue, accentTeal],
                            ),
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: primaryBlue.withOpacity(0.3),
                                blurRadius: 8,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Material(
                            color: Colors.transparent,
                            child: InkWell(
                              onTap: _showSortMenu,
                              borderRadius: BorderRadius.circular(12),
                              child: Container(
                                padding: const EdgeInsets.all(16),
                                child: const Icon(
                                  Icons.filter_list,
                                  color: Colors.white,
                                  size: 24,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Sort Indicator
                    Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: isDesktop ? 32 : 16,
                        vertical: 8,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [primaryBlue.withOpacity(0.15), accentTeal.withOpacity(0.1)],
                              ),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: primaryBlue.withOpacity(0.3)),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  _selectedSort == 'alphabetical'
                                      ? Icons.sort_by_alpha
                                      : _selectedSort == 'oldest'
                                          ? Icons.arrow_upward
                                          : Icons.arrow_downward,
                                  size: 14,
                                  color: primaryBlue,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  _selectedSort == 'alphabetical'
                                      ? 'A-Z'
                                      : _selectedSort == 'oldest'
                                          ? 'Oldest'
                                          : 'Newest',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: primaryBlue,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
              // Tabs section remains the same
              TabBar(
                controller: _tabController,
                indicatorColor: primaryBlue,
                indicatorWeight: 3,
                labelColor: primaryBlue,
                unselectedLabelColor: mediumGray,
                labelStyle: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
                tabs: [
                  Tab(
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.verified_user),
                        const SizedBox(width: 8),
                        Text('Verified (${_verifiedUsers.length})'),
                      ],
                    ),
                  ),
                  Tab(
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.pending),
                        const SizedBox(width: 8),
                        Text('Unverified (${_unverifiedUsers.length})'),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          await _loadUsers();
        },
        child: _isLoading
            ? const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(color: primaryBlue),
                    SizedBox(height: 16),
                    Text(
                      'Loading users...',
                      style: TextStyle(color: mediumGray, fontSize: 16),
                    ),
                  ],
                ),
              )
            : TabBarView(
                controller: _tabController,
                children: [
                  // Verified users tab
                  UserListView(
                    users: _filterUsers(_verifiedUsers),
                    isVerified: true,
                    onUserTap: _showUserDetails,
                  ),
                  // Unverified users tab
                  UserListView(
                    users: _filterUsers(_unverifiedUsers),
                    isVerified: false,
                    onUserTap: _showUserDetails,
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildDrawer(BuildContext context) {
    return Drawer(
      backgroundColor: backgroundColor,
      child: Column(
        children: [
          // Header
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(24, 60, 24, 24),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  primaryBlue,
                  Color.fromRGBO(81, 115, 153, 0.8),
                ],
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.admin_panel_settings_rounded,
                    color: Colors.white,
                    size: 32,
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Developer',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Management Panel',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.9),
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),

          // Menu Items
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(vertical: 8),
              children: [
                _buildDrawerItem(
                  context,
                  icon: Icons.local_hospital_rounded,
                  title: 'Veterinary Clinics',
                  subtitle: 'Manage vet clinics',
                  onTap: () {
                    Navigator.pop(context);
                    // Navigate to SuperAdminVetClinicDashboard
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            const SuperAdminVetClinicDashboard(),
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
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Divider(),
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Divider(),
                ),
                _buildDrawerItem(
                  context,
                  icon: Icons.archive_rounded,
                  title: 'Archived Users',
                  subtitle: 'View & manage archives',
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const ArchivedUsersDashboard(),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),

          // Logout Button
          Container(
            padding: const EdgeInsets.all(16),
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
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [
                            Color.fromRGBO(81, 115, 153, 0.7),
                            Color.fromRGBO(81, 115, 153, 0.5),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor:
                                  AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          ),
                          SizedBox(width: 12),
                          Text(
                            'Logging Out...',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
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
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [
                              Color.fromRGBO(220, 53, 69, 1),
                              Color.fromRGBO(200, 35, 51, 1),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.red.withOpacity(0.3),
                              blurRadius: 8,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.logout_rounded,
                              color: Colors.white,
                              size: 20,
                            ),
                            SizedBox(width: 12),
                            Text(
                              'Log Out',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
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
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: primaryBlue.withOpacity(0.2),
            ),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      primaryBlue.withOpacity(0.2),
                      primaryBlue.withOpacity(0.1),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  icon,
                  color: primaryBlue,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: primaryBlue,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_ios_rounded,
                size: 16,
                color: primaryBlue.withOpacity(0.5),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// ============================================
/// USER LIST VIEW
/// ============================================
class UserListView extends StatelessWidget {
  final List<User> users;
  final bool isVerified;
  final Function(User) onUserTap;

  const UserListView({
    Key? key,
    required this.users,
    required this.isVerified,
    required this.onUserTap,
  }) : super(key: key);

  static const Color backgroundColor = Color.fromRGBO(248, 253, 255, 1);
  static const Color primaryBlue = Color.fromRGBO(81, 115, 153, 1);
  static const Color accentTeal = Color(0xFF5B9BD5);
  static const Color vetGreen = Color(0xFF34D399);
  static const Color vetOrange = Color(0xFFF59E0B);

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktop = screenWidth > 1024;
    final isTablet = screenWidth > 600 && screenWidth <= 1024;

    if (users.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isVerified ? Icons.verified_user : Icons.pending,
              size: 80,
              color: primaryBlue.withOpacity(0.5),
            ),
            const SizedBox(height: 24),
            Text(
              isVerified
                  ? 'No verified users found'
                  : 'No unverified users found',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: primaryBlue.withOpacity(0.7),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              isVerified
                  ? 'All users are pending verification'
                  : 'All users have been verified!',
              style: TextStyle(
                fontSize: 14,
                color: primaryBlue.withOpacity(0.5),
              ),
            ),
          ],
        ),
      );
    }

    // Responsive grid layout
    int crossAxisCount = 1;
    if (isDesktop) {
      crossAxisCount = 3;
    } else if (isTablet) {
      crossAxisCount = 2;
    }

    return GridView.builder(
      padding: EdgeInsets.all(isDesktop ? 32 : 16),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        childAspectRatio: isDesktop ? 2.5 : 2.0,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
      ),
      itemCount: users.length,
      itemBuilder: (context, index) {
        return UserCard(
          user: users[index],
          onTap: () => onUserTap(users[index]),
        );
      },
    );
  }
}

/// ============================================
/// USER CARD (Grid Item)
/// ============================================
class UserCard extends StatefulWidget {
  final User user;
  final VoidCallback onTap;

  const UserCard({
    Key? key,
    required this.user,
    required this.onTap,
  }) : super(key: key);

  @override
  State<UserCard> createState() => _UserCardState();
}

class _UserCardState extends State<UserCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  bool _isHovered = false;

  static const Color primaryBlue = Color.fromRGBO(81, 115, 153, 1);
  static const Color accentTeal = Color(0xFF5B9BD5);
  static const Color lightBlue = Color(0xFF9FC5E8);
  static const Color vetGreen = Color(0xFF34D399);
  static const Color vetOrange = Color(0xFFF59E0B);
  static const Color mediumGray = Color(0xFF9CA3AF);
  static const Color darkText = Color(0xFF374151);

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.03).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );
  }

  Widget _buildPlaceholderAvatar() {
    return Container(
      width: 60,
      height: 60,
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          colors: [primaryBlue, accentTeal],
        ),
      ),
      child: Center(
        child: Text(
          widget.user.name.isNotEmpty ? widget.user.name[0].toUpperCase() : '?',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  String _formatDate(String? dateString) {
    if (dateString == null || dateString.isEmpty) return 'N/A';
    try {
      final date = DateTime.parse(dateString);
      return DateFormat('MMM dd, yyyy').format(date);
    } catch (e) {
      return 'N/A';
    }
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) {
        setState(() => _isHovered = true);
        _controller.forward();
      },
      onExit: (_) {
        setState(() => _isHovered = false);
        _controller.reverse();
      },
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) => Transform.scale(
          scale: _scaleAnimation.value,
          child: GestureDetector(
            onTap: widget.onTap,
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: _isHovered
                      ? [
                          Colors.white,
                          lightBlue.withOpacity(0.2),
                          accentTeal.withOpacity(0.1),
                        ]
                      : [
                          Colors.white,
                          Colors.white.withOpacity(0.9),
                        ],
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: _isHovered
                        ? primaryBlue.withOpacity(0.2)
                        : primaryBlue.withOpacity(0.1),
                    blurRadius: _isHovered ? 15 : 8,
                    offset: Offset(0, _isHovered ? 6 : 3),
                    spreadRadius: _isHovered ? 2 : 1,
                  ),
                ],
                border: Border.all(
                  color: _isHovered
                      ? primaryBlue.withOpacity(0.4)
                      : primaryBlue.withOpacity(0.2),
                  width: _isHovered ? 2 : 1.5,
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    // Avatar with Profile Picture
                    Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: _isHovered ? vetGreen : accentTeal,
                          width: 3,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: primaryBlue.withOpacity(0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: ClipOval(
                        child: widget.user.hasProfilePicture
                            ? Image.network(
                                '${getPetImageUrl(widget.user.profilePictureId)}&cache=${DateTime.now().millisecondsSinceEpoch}',
                                width: 60,
                                height: 60,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) {
                                  return _buildPlaceholderAvatar();
                                },
                                loadingBuilder:
                                    (context, child, loadingProgress) {
                                  if (loadingProgress == null) return child;
                                  return Container(
                                    color: Colors.grey[200],
                                    child: Center(
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
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
                              )
                            : _buildPlaceholderAvatar(),
                      ),
                    ),
                    const SizedBox(width: 16),
                    // User info
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          // Name
                          Text(
                            widget.user.name,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: darkText,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),

                          // Email
                          Row(
                            children: [
                              Icon(Icons.email, size: 14, color: mediumGray),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  widget.user.email,
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: mediumGray,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),

                          // Phone
                          if (widget.user.phone != null &&
                              widget.user.phone!.isNotEmpty)
                            Row(
                              children: [
                                Icon(Icons.phone, size: 14, color: mediumGray),
                                const SizedBox(width: 4),
                                Text(
                                  widget.user.phone!,
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: mediumGray,
                                  ),
                                ),
                              ],
                            ),

                          const SizedBox(height: 8),

                          // Verification badge
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: widget.user.idVerified
                                    ? [vetGreen, vetGreen.withOpacity(0.7)]
                                    : [vetOrange, vetOrange.withOpacity(0.7)],
                              ),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  widget.user.idVerified
                                      ? Icons.verified_user
                                      : Icons.pending,
                                  size: 14,
                                  color: Colors.white,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  widget.user.verificationStatusText,
                                  style: const TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Arrow icon
                    Icon(
                      Icons.arrow_forward_ios,
                      color: _isHovered ? primaryBlue : mediumGray,
                      size: 18,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// ============================================
/// USER DETAILS DIALOG
/// ============================================
class UserDetailsDialog extends StatefulWidget {
  final User user;
  final AuthRepository authRepository;
  final VoidCallback onUserUpdated;

  const UserDetailsDialog({
    Key? key,
    required this.user,
    required this.authRepository,
    required this.onUserUpdated,
  }) : super(key: key);

  @override
  State<UserDetailsDialog> createState() => _UserDetailsDialogState();
}

class _UserDetailsDialogState extends State<UserDetailsDialog> {
  bool _showDeleteConfirm = false;
  bool _isDeleting = false;

  bool _isLoadingVerificationDetails = true;
  String? _verifyByClinicName;
  String? _verifyByClinicId;

  static const Color backgroundColor = Color.fromRGBO(248, 253, 255, 1);
  static const Color primaryBlue = Color.fromRGBO(81, 115, 153, 1);
  static const Color accentTeal = Color(0xFF5B9BD5);
  static const Color lightBlue = Color(0xFF9FC5E8);
  static const Color vetGreen = Color(0xFF34D399);
  static const Color vetOrange = Color(0xFFF59E0B);
  static const Color mediumGray = Color(0xFF9CA3AF);
  static const Color darkText = Color(0xFF374151);


  String _formatDate(String? dateString) {
    if (dateString == null || dateString.isEmpty) return 'Not available';
    try {
      final date = DateTime.parse(dateString);
      return DateFormat('MMMM dd, yyyy - hh:mm a').format(date);
    } catch (e) {
      return 'Invalid date';
    }
  }

Future<void> _loadVerificationDetails() async {
    if (!widget.user.idVerified) {
      setState(() {
        _isLoadingVerificationDetails = false;
      });
      return;
    }
    try {
      // CRITICAL: Fetch verification document by userId, not by documentId
      final verificationDocs = await widget.authRepository.appWriteProvider.databases!.listDocuments(
        databaseId: AppwriteConstants.dbID,
        collectionId: AppwriteConstants.idVerificationCollectionID,
        queries: [
          Query.equal('userId', widget.user.userId),
          Query.equal('status', 'approved'),
          Query.orderDesc('\$createdAt'),
          Query.limit(1),
        ],
      );
        if (verificationDocs.documents.isEmpty) {
      
        setState(() {
          _isLoadingVerificationDetails = false;
        });
        return;
      }
      final verificationDoc = verificationDocs.documents.first;
        // Get the verifyByClinic field
      final verifyByClinic = verificationDoc.data['verifyByClinic'] as String?;
      if (verifyByClinic != null && verifyByClinic.isNotEmpty) {
        // Fetch the clinic details to get the clinic name
        try {
          final clinicDoc = await widget.authRepository.appWriteProvider.databases!.getDocument(
            databaseId: AppwriteConstants.dbID,
            collectionId: AppwriteConstants.clinicsCollectionID,
            documentId: verifyByClinic,
          );
          final clinicName = clinicDoc.data['clinicName'] as String? ?? 'Unknown Clinic';
          setState(() {
            _verifyByClinicId = verifyByClinic;
            _verifyByClinicName = clinicName;
            _isLoadingVerificationDetails = false;
          });

        } catch (e) {
          // Clinic not found, just use the ID
          setState(() {
            _verifyByClinicId = verifyByClinic;
            _verifyByClinicName = 'Clinic (ID: $verifyByClinic)';
            _isLoadingVerificationDetails = false;
          });
        }
      } else {

        setState(() {
          _isLoadingVerificationDetails = false;
        });
      }
    } catch (e, stackTrace) {
          // Error fetching verification details
      setState(() {
        _isLoadingVerificationDetails = false;
      });
    }
  }

  Future<void> _handleArchive() async {
    setState(() => _isDeleting = true);

    try {

      // Get current admin info
      final currentUser = await widget.authRepository.getUser();
      final adminName = currentUser?.name ?? 'Super Admin';

      // Archive the user instead of deleting
      final result = await widget.authRepository.archiveUser(
        userId: widget.user.userId,
        userDocumentId: widget.user.documentId!,
        archivedBy: adminName,
        archiveReason: 'Archived by super admin from user management',
      );

      if (result['success'] == true) {
        Get.snackbar(
          'Success',
          '${widget.user.name} has been archived successfully. Will be permanently deleted in 30 days.',
          backgroundColor: vetGreen,
          colorText: Colors.white,
          icon: const Icon(Icons.archive, color: Colors.white),
          duration: const Duration(seconds: 4),
        );

        widget.onUserUpdated();
        Navigator.of(context).pop();
      } else {
        throw Exception(result['error'] ?? 'Failed to archive user');
      }
    } catch (e) {

      Get.snackbar(
        'Error',
        'Failed to archive user: $e',
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );

      setState(() => _isDeleting = false);
    }
  }

  Widget _buildDialogPlaceholderAvatar() {
    return Container(
      width: 100,
      height: 100,
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          colors: [primaryBlue, accentTeal],
        ),
      ),
      child: Center(
        child: Text(
          widget.user.name.isNotEmpty ? widget.user.name[0].toUpperCase() : '?',
          style: const TextStyle(
            fontSize: 42,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
      if (_isLoadingVerificationDetails && widget.user.idVerified) {
      // Call only once when dialog opens
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _loadVerificationDetails();
        }
      });
    }
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final isDesktop = screenWidth > 768;
    final dialogWidth = isDesktop ? 600.0 : screenWidth * 0.9;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      backgroundColor: Colors.transparent,
      child: Container(
        width: dialogWidth,
        constraints: BoxConstraints(
          maxHeight: screenHeight * 0.9,
          maxWidth: screenWidth * 0.95,
        ),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.white,
              backgroundColor,
            ],
          ),
          boxShadow: [
            BoxShadow(
              color: primaryBlue.withOpacity(0.2),
              blurRadius: 25,
              offset: const Offset(0, 10),
              spreadRadius: 5,
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(isDesktop ? 32 : 24),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [primaryBlue, accentTeal, lightBlue],
                ),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(24),
                  topRight: Radius.circular(24),
                ),
                boxShadow: [
                  BoxShadow(
                    color: primaryBlue.withOpacity(0.3),
                    blurRadius: 15,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Column(
                children: [
                  // Avatar with Profile Picture
                  Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white,
                      border: Border.all(color: Colors.white, width: 4),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.15),
                          blurRadius: 15,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    child: ClipOval(
                      child: widget.user.hasProfilePicture
                          ? Image.network(
                              '${getPetImageUrl(widget.user.profilePictureId)}&cache=${DateTime.now().millisecondsSinceEpoch}',
                              width: 100,
                              height: 100,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                return _buildDialogPlaceholderAvatar();
                              },
                              loadingBuilder:
                                  (context, child, loadingProgress) {
                                if (loadingProgress == null) return child;
                                return Container(
                                  color: Colors.grey[200],
                                  child: Center(
                                    child: CircularProgressIndicator(
                                      strokeWidth: 3,
                                      value:
                                          loadingProgress.expectedTotalBytes !=
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
                            )
                          : _buildDialogPlaceholderAvatar(),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Name
                  Text(
                    widget.user.name,
                    style: const TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),

                  // Role badge
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.25),
                      borderRadius: BorderRadius.circular(15),
                      border: Border.all(
                        color: Colors.white.withOpacity(0.3),
                      ),
                    ),
                    child: Text(
                      widget.user.role.toUpperCase(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 1,
                      ),
                    ),
                  ),
                ],
              ),
            ),
           Flexible(
              child: FutureBuilder<void>(
                future: widget.user.idVerified ? _loadVerificationDetails() : Future.value(),
                builder: (context, snapshot) {
                  return SingleChildScrollView(
                    padding: EdgeInsets.all(isDesktop ? 32 : 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Verification Status Section
                        _buildSectionHeader(
                          'Verification Status',
                          widget.user.idVerified
                              ? Icons.verified_user
                              : Icons.pending,
                          widget.user.idVerified ? vetGreen : vetOrange,
                        ),
                        const SizedBox(height: 16),
                        _buildVerificationStatusCard(),
                        const SizedBox(height: 24),

                        // Contact Information Section
                        _buildSectionHeader(
                          'Contact Information',
                          Icons.contact_mail_outlined,
                          primaryBlue,
                        ),
                        const SizedBox(height: 16),
                        _buildContactInfoCard(),
                        const SizedBox(height: 24),

                        // Account Information Section
                        _buildSectionHeader(
                          'Account Information',
                          Icons.account_circle_outlined,
                          accentTeal,
                        ),
                        const SizedBox(height: 16),
                        _buildAccountInfoCard(),

                        // Delete confirmation
                        if (_showDeleteConfirm) ...[
                          const SizedBox(height: 24),
                          _buildDeleteConfirmation(),
                        ],
                      ],
                    ),
                  );
                },
              ),
            ),
            // Actions
            Container(
              padding: EdgeInsets.all(isDesktop ? 24 : 20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    backgroundColor,
                    lightBlue.withOpacity(0.2),
                  ],
                ),
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(24),
                  bottomRight: Radius.circular(24),
                ),
              ),
              child: _buildActionButtons(screenWidth > 500),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(15),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 12),
          Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: darkText,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVerificationStatusCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: widget.user.idVerified
              ? [
                  vetGreen.withOpacity(0.1),
                  vetGreen.withOpacity(0.05),
                ]
              : [
                  vetOrange.withOpacity(0.1),
                  vetOrange.withOpacity(0.05),
                ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: widget.user.idVerified
              ? vetGreen.withOpacity(0.3)
              : vetOrange.withOpacity(0.3),
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: (widget.user.idVerified ? vetGreen : vetOrange)
                .withOpacity(0.1),
            blurRadius: 10,
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
                  gradient: LinearGradient(
                    colors: widget.user.idVerified
                        ? [vetGreen, vetGreen.withOpacity(0.7)]
                        : [vetOrange, vetOrange.withOpacity(0.7)],
                  ),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: (widget.user.idVerified ? vetGreen : vetOrange)
                          .withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Icon(
                  widget.user.idVerified ? Icons.verified_user : Icons.pending,
                  color: Colors.white,
                  size: 28,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.user.verificationStatusText,
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: widget.user.idVerified ? vetGreen : vetOrange,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      widget.user.idVerified
                          ? 'User identity has been verified'
                          : 'User identity verification pending',
                      style: TextStyle(
                        fontSize: 14,
                        color: mediumGray,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (widget.user.idVerified) ...[
            const SizedBox(height: 16),
            const Divider(color: mediumGray, height: 1),
            const SizedBox(height: 16),
            
            // Show loading indicator while fetching verification details
            if (_isLoadingVerificationDetails)
              Row(
                children: [
                  SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: mediumGray,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Loading verification details...',
                    style: TextStyle(
                      fontSize: 13,
                      color: mediumGray,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ),
            
              // Show "Verified by" if user was verified by a clinic
              if (!_isLoadingVerificationDetails && _verifyByClinicName != null) ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: accentTeal.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: accentTeal.withOpacity(0.3),
                      width: 1.5,
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [accentTeal, accentTeal.withOpacity(0.7)],
                          ),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(
                          Icons.local_hospital,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Verified by:',
                              style: TextStyle(
                                fontSize: 12,
                                color: mediumGray,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _verifyByClinicName!,
                              style: TextStyle(
                                fontSize: 15,
                                color: accentTeal,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Icon(
                        Icons.verified,
                        color: vetGreen,
                        size: 20,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
              ],
              
              // Show "Verified on" date
              if (!_isLoadingVerificationDetails && widget.user.idVerifiedAt != null)
                Row(
                  children: [
                    Icon(Icons.calendar_today, size: 16, color: mediumGray),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Verified on: ${_formatDate(widget.user.idVerifiedAt)}',
                        style: TextStyle(
                          fontSize: 13,
                          color: mediumGray,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
            ],
          ],
        ),
      );
    }

  Widget _buildContactInfoCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: primaryBlue.withOpacity(0.3), width: 2),
        boxShadow: [
          BoxShadow(
            color: primaryBlue.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          _buildInfoRow(
            Icons.email_outlined,
            'Email Address',
            widget.user.email,
            primaryBlue,
          ),
          const SizedBox(height: 16),
          _buildInfoRow(
            Icons.phone_outlined,
            'Phone Number',
            widget.user.phone ?? 'Not provided',
            accentTeal,
          ),
        ],
      ),
    );
  }

  Widget _buildAccountInfoCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: accentTeal.withOpacity(0.3), width: 2),
        boxShadow: [
          BoxShadow(
            color: accentTeal.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          _buildInfoRow(
            Icons.badge_outlined,
            'User ID',
            widget.user.userId,
            primaryBlue,
          ),
          const SizedBox(height: 16),
          _buildInfoRow(
            Icons.assignment_ind_outlined,
            'Document ID',
            widget.user.documentId ?? 'N/A',
            accentTeal,
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(
    IconData icon,
    String label,
    String value,
    Color color,
  ) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, size: 20, color: color),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: mediumGray,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 4),
              SelectableText(
                value,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: darkText,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

    Widget _buildDeleteConfirmation() {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.orange[50],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.orange[300]!, width: 2),
          boxShadow: [
            BoxShadow(
              color: Colors.orange.withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.orange.withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                Icons.archive_outlined,
                color: Colors.orange[700],
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Are you sure you want to archive ${widget.user.name}? The account and ALL related data (pets, appointments, medical records) will be preserved for 30 days before permanent deletion. You can recover everything within this period.',
                style: TextStyle(
                  color: Colors.orange[700],
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      );
    }

  Widget _buildActionButtons(bool isWide) {
    if (_isDeleting) {
      return const Center(
        child: CircularProgressIndicator(color: primaryBlue),
      );
    }

    if (_showDeleteConfirm) {
      return Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: TextButton(
              onPressed: () => setState(() => _showDeleteConfirm = false),
              child: const Text(
                'Cancel',
                style: TextStyle(
                  color: mediumGray,
                  fontWeight: FontWeight.w600,
                  fontSize: 16,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: ElevatedButton.icon(
              onPressed: _handleArchive, // Changed from _handleDelete
              icon: const Icon(Icons.archive, size: 20),
              label: const Text('Confirm Archive'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange, // Changed from red
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 4,
              ),
            ),
          ),
        ],
      );
    }

    if (isWide) {
      return Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          ElevatedButton.icon(
            onPressed: () => setState(() => _showDeleteConfirm = true),
            icon: const Icon(Icons.archive_outlined, size: 20),
            label: const Text('Archive User'), // Changed text
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange, // Changed from red
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(
                horizontal: 24,
                vertical: 16,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 4,
            ),
          ),
          ElevatedButton.icon(
            onPressed: () => Navigator.of(context).pop(),
            icon: const Icon(Icons.close, size: 20),
            label: const Text('Close'),
            style: ElevatedButton.styleFrom(
              backgroundColor: primaryBlue,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(
                horizontal: 32,
                vertical: 16,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 4,
            ),
          ),
        ],
      );
    } else {
      return Column(
        children: [
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () => setState(() => _showDeleteConfirm = true),
              icon: const Icon(Icons.archive_outlined, size: 20),
              label: const Text('Archive User'), // Changed text
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange, // Changed from red
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 4,
              ),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () => Navigator.of(context).pop(),
              icon: const Icon(Icons.close, size: 20),
              label: const Text('Close'),
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryBlue,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 4,
              ),
            ),
          ),
        ],
      );
    }
  }
}
