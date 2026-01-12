import 'package:capstone_app/data/models/clinic_model.dart';
import 'package:capstone_app/data/models/staff_model.dart';
import 'package:capstone_app/data/repository/auth.repository.dart';
import 'package:capstone_app/utils/image_helper.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:appwrite/appwrite.dart';
import 'package:appwrite/models.dart';
import 'dart:async';

class SuperAdminStaffManagementPage extends StatefulWidget {
  final Clinic clinic;

  const SuperAdminStaffManagementPage({
    super.key,
    required this.clinic,
  });

  @override
  State<SuperAdminStaffManagementPage> createState() =>
      _SuperAdminStaffManagementPageState();
}
final AuthRepository authRepository = Get.find<AuthRepository>();
class _SuperAdminStaffManagementPageState
    extends State<SuperAdminStaffManagementPage>
    with SingleTickerProviderStateMixin {
  final AuthRepository authRepository = Get.find<AuthRepository>();
  List<Staff> staffList = [];
  bool isLoading = true;
  String errorMessage = '';
  String searchQuery = '';
  String selectedFilter = 'newest'; // 'newest', 'oldest', 'alphabetical'
  
  StreamSubscription<RealtimeMessage>? _staffSubscription;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;


  // Color Palette
  static const Color primaryColor = Color.fromRGBO(81, 115, 153, 1);
  static const Color backgroundColor = Color.fromARGB(255, 248, 253, 255);
  static const Color lightBlue = Color.fromRGBO(144, 169, 196, 1);
  static const Color darkBlue = Color.fromRGBO(51, 75, 103, 1);
  static const Color accentTeal = Color(0xFF5B9BD5);
  static const Color successGreen = Color(0xFF34D399);
  static const Color warningOrange = Color(0xFFF59E0B);


  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );
    _loadStaff();
    _subscribeToStaffChanges();
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _staffSubscription?.cancel();
    
    super.dispose();
  }

  void _subscribeToStaffChanges() {
    // Subscribe to staff collection changes for real-time updates
   final stream = authRepository.subscribeToClinicChanges();
    // Note: Adjust this based on your Appwrite setup
    // This is a placeholder - implement based on your real-time subscription method
    _loadStaff(); // Initial 
    
  }

  Future<void> _loadStaff() async {
    try {
      setState(() {
        isLoading = true;
        errorMessage = '';
      });

      final staff =
          await authRepository.getClinicStaff(widget.clinic.documentId ?? '');


      for (var s in staff) {
    }


      if (mounted) {
        setState(() {
          staffList = staff;
          isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          errorMessage = 'Error loading staff: ${e.toString()}';
          isLoading = false;
        });
      }
    }
  }

  List<Staff> get filteredAndSortedStaff {
    var filtered = staffList.where((staff) {
      if (searchQuery.isEmpty) return true;
      return staff.name.toLowerCase().contains(searchQuery.toLowerCase()) ||
          staff.email.toLowerCase().contains(searchQuery.toLowerCase()) ||
          staff.department.toLowerCase().contains(searchQuery.toLowerCase());
    }).toList();

    // Apply sorting
    switch (selectedFilter) {
      case 'alphabetical':
        filtered.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
        break;
      case 'oldest':
        filtered.sort((a, b) => a.createdAt.compareTo(b.createdAt));
        break;
      case 'newest':
      default:
        filtered.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        break;
    }

    return filtered;
  }

  void _showFilterMenu() {
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
              color: primaryColor.withOpacity(0.1),
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
                      colors: [primaryColor.withOpacity(0.2), accentTeal.withOpacity(0.1)],
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.filter_list, color: primaryColor, size: 24),
                ),
                const SizedBox(width: 12),
                const Text(
                  'Sort Staff By',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: darkBlue,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            _buildFilterOption(
              'Newest First',
              'Recently added staff members',
              Icons.arrow_downward_rounded,
              'newest',
              [successGreen, accentTeal],
            ),
            const SizedBox(height: 12),
            _buildFilterOption(
              'Oldest First',
              'Earliest registered staff',
              Icons.arrow_upward_rounded,
              'oldest',
              [warningOrange, primaryColor],
            ),
            const SizedBox(height: 12),
            _buildFilterOption(
              'Alphabetical (A-Z)',
              'Sort by name',
              Icons.sort_by_alpha_rounded,
              'alphabetical',
              [primaryColor, darkBlue],
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterOption(
    String title,
    String subtitle,
    IconData icon,
    String filterValue,
    List<Color> colors,
  ) {
    final isSelected = selectedFilter == filterValue;
    
    return InkWell(
      onTap: () {
        setState(() => selectedFilter = filterValue);
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
                      color: isSelected ? colors[0] : darkBlue,
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

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        backgroundColor: backgroundColor,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: primaryColor),
          onPressed: () => Navigator.pop(context),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Staff Management',
              style: TextStyle(
                color: primaryColor,
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
            Text(
              widget.clinic.clinicName,
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 12,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: primaryColor),
            onPressed: _loadStaff,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: Column(
          children: [
            // Search and Filter Bar
            Padding(
              padding: EdgeInsets.symmetric(
                horizontal: screenWidth * 0.05,
                vertical: 16,
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Colors.white, backgroundColor],
                        ),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: primaryColor.withOpacity(0.3), width: 2),
                        boxShadow: [
                          BoxShadow(
                            color: primaryColor.withOpacity(0.1),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: TextField(
                        onChanged: (value) => setState(() => searchQuery = value),
                        decoration: InputDecoration(
                          hintText: 'Search staff...',
                          hintStyle: TextStyle(color: Colors.grey[400]),
                          prefixIcon: Container(
                            margin: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [primaryColor.withOpacity(0.2), accentTeal.withOpacity(0.1)],
                              ),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.search, color: primaryColor, size: 20),
                          ),
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [primaryColor, accentTeal],
                      ),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: primaryColor.withOpacity(0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: _showFilterMenu,
                        borderRadius: BorderRadius.circular(16),
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          child: const Icon(Icons.filter_list, color: Colors.white),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Staff Count and Filter Info
            Padding(
              padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.05),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [successGreen.withOpacity(0.2), accentTeal.withOpacity(0.1)],
                          ),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.people, color: successGreen, size: 16),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '${filteredAndSortedStaff.length} Staff Members',
                        style: const TextStyle(
                          fontSize: 14,
                          color: darkBlue,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [primaryColor.withOpacity(0.15), accentTeal.withOpacity(0.1)],
                      ),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: primaryColor.withOpacity(0.3)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          selectedFilter == 'alphabetical'
                              ? Icons.sort_by_alpha
                              : selectedFilter == 'oldest'
                                  ? Icons.arrow_upward
                                  : Icons.arrow_downward,
                          size: 14,
                          color: primaryColor,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          selectedFilter == 'alphabetical'
                              ? 'A-Z'
                              : selectedFilter == 'oldest'
                                  ? 'Oldest'
                                  : 'Newest',
                          style: const TextStyle(
                            fontSize: 12,
                            color: primaryColor,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),
            Divider(height: 1, color: primaryColor.withOpacity(0.1)),

            // Staff Grid
            Expanded(
              child: isLoading
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [primaryColor.withOpacity(0.1), accentTeal.withOpacity(0.05)],
                              ),
                              shape: BoxShape.circle,
                            ),
                            child: const CircularProgressIndicator(color: primaryColor),
                          ),
                          const SizedBox(height: 16),
                          const Text(
                            'Loading staff members...',
                            style: TextStyle(color: darkBlue, fontWeight: FontWeight.w500),
                          ),
                        ],
                      ),
                    )
                  : errorMessage.isNotEmpty
                      ? _buildErrorState()
                      : filteredAndSortedStaff.isEmpty
                          ? _buildEmptyState()
                          : RefreshIndicator(
                              onRefresh: _loadStaff,
                              color: primaryColor,
                              child: _buildStaffGrid(isMobile),
                            ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStaffGrid(bool isMobile) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        int crossAxisCount;
        
        if (width > 1400) {
          crossAxisCount = 5;
        } else if (width > 1100) {
          crossAxisCount = 4;
        } else if (width > 800) {
          crossAxisCount = 3;
        } else if (width > 600) {
          crossAxisCount = 2;
        } else {
          crossAxisCount = 1;
        }

        return GridView.builder(
          padding: EdgeInsets.all(constraints.maxWidth * 0.05),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            childAspectRatio: 0.75,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
          ),
          itemCount: filteredAndSortedStaff.length,
          itemBuilder: (context, index) {
            final staff = filteredAndSortedStaff[index];
            return _buildStaffCard(staff);
          },
        );
      },
    );
  }

  Widget _buildStaffCard(Staff staff) {
    return _StaffCard(
      staff: staff,
      onTap: () => _showStaffDetails(staff),
      onDelete: () => _confirmDeleteStaff(staff),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [primaryColor.withOpacity(0.1), accentTeal.withOpacity(0.05)],
              ),
              shape: BoxShape.circle,
            ),
            child: Icon(
              searchQuery.isEmpty ? Icons.people_outline : Icons.search_off,
              size: 64,
              color: primaryColor.withOpacity(0.5),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            searchQuery.isEmpty ? 'No staff members yet' : 'No staff found',
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: darkBlue,
            ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 48),
            child: Text(
              searchQuery.isEmpty
                  ? 'Staff members will appear here once they are added to the clinic'
                  : 'Try adjusting your search criteria',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.red[50],
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.error_outline, size: 64, color: Colors.red),
          ),
          const SizedBox(height: 16),
          const Text(
            'Error Loading Staff',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 48),
            child: Text(
              errorMessage,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 14),
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _loadStaff,
            icon: const Icon(Icons.refresh, color: Colors.white),
            label: const Text('Retry', style: TextStyle(color: Colors.white)),
            style: ElevatedButton.styleFrom(
              backgroundColor: primaryColor,
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ],
      ),
    );
  }

 void _showStaffDetails(Staff staff) {
  showDialog(
    context: context,
    builder: (context) => _StaffDetailsDialog(
      staff: staff,
    ),
  );
}

  void _confirmDeleteStaff(Staff staff) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.red[50],
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.warning_rounded, color:  Color.fromRGBO(251, 140, 0, 1), size: 24),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Text(
                'Archive Staff Member',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Are you sure you want to archive ${staff.name}?',
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red[50],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color.fromRGBO(239, 154, 154, 1)),
              ),
              child: const Row(
                children: [
                  Icon(Icons.info_outline,  color: Color.fromRGBO(251, 140, 0, 1), size: 20),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'This action will keep the staff data in the system but will deactivate their account. They will no longer have access to the clinic system.',
                      style: TextStyle(fontSize: 13, color: Colors.red),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await _deleteStaff(staff);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteStaff(Staff staff) async {
    try {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: CircularProgressIndicator(color: primaryColor),
        ),
      );

      await authRepository.deleteStaffAccountPermanently(staff.documentId!);

      if (mounted) Navigator.pop(context);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check_circle, color: Colors.white),
              const SizedBox(width: 12),
              Expanded(child: Text('${staff.name} has been deleted successfully')),
            ],
          ),
          backgroundColor: successGreen,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );

      await _loadStaff();
    } catch (e) {
      if (mounted) Navigator.pop(context);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.error_outline, color: Colors.white),
              const SizedBox(width: 12),
              Expanded(child: Text('Error deleting staff: ${e.toString()}')),
            ],
          ),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    }
  }

  String _formatDate(String isoDate) {
    try {
      final date = DateTime.parse(isoDate);
      return '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
    } catch (e) {
      return isoDate;
    }
  }
}

// Staff Card Widget
class _StaffCard extends StatefulWidget {
  final Staff staff;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const _StaffCard({
    required this.staff,
    required this.onTap,
    required this.onDelete,
  });

  @override
  State<_StaffCard> createState() => _StaffCardState();
}

class _StaffCardState extends State<_StaffCard> with SingleTickerProviderStateMixin {
  bool _isHovered = false;
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  static const Color primaryColor = Color.fromRGBO(81, 115, 153, 1);
  static const Color backgroundColor = Color.fromARGB(255, 248, 253, 255);
  static const Color accentTeal = Color(0xFF5B9BD5);
  static const Color successGreen = Color(0xFF34D399);
  static const Color warningOrange = Color(0xFFF59E0B);
  static const Color darkBlue = Color.fromRGBO(51, 75, 103, 1);

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

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
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
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: _isHovered
                      ? [Colors.white, backgroundColor, accentTeal.withOpacity(0.1)]
                      : [Colors.white, backgroundColor],
                ),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: _isHovered ? primaryColor : primaryColor.withOpacity(0.3),
                  width: _isHovered ? 2 : 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: _isHovered ? primaryColor.withOpacity(0.2) : primaryColor.withOpacity(0.1),
                    blurRadius: _isHovered ? 16 : 8,
                    offset: Offset(0, _isHovered ? 8 : 4),
                  ),
                ],
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Profile Image
                  Stack(
                    children: [
                      Container(
                        width: 90,
                        height: 90,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: widget.staff.image.isEmpty
                              ? LinearGradient(
                                  colors: [primaryColor.withOpacity(0.2), accentTeal.withOpacity(0.1)],
                                )
                              : null,
                          border: Border.all(
                            color: _isHovered ? primaryColor : primaryColor.withOpacity(0.5),
                            width: _isHovered ? 3 : 2,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: primaryColor.withOpacity(0.2),
                              blurRadius: _isHovered ? 12 : 8,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        image: widget.staff.image.isNotEmpty
                          ? DecorationImage(
                              image: NetworkImage(
                                widget.staff.image.startsWith('http')
                                    ? widget.staff.image
                                    : authRepository.getImageUrl(widget.staff.image),
                              ),
                              fit: BoxFit.cover,
                            )
                          : null,
                        ),
                        child: widget.staff.image.isEmpty
                            ? const Icon(Icons.person, size: 40, color: primaryColor)
                            : null,
                      ),
                      // Status Badge
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: widget.staff.isActive
                                  ? [successGreen, accentTeal]
                                  : [Colors.grey, Colors.grey[400]!],
                            ),
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 3),
                            boxShadow: [
                              BoxShadow(
                                color: (widget.staff.isActive ? successGreen : Colors.grey).withOpacity(0.3),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Icon(
                            widget.staff.isActive ? Icons.check : Icons.close,
                            color: Colors.white,
                            size: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Name
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Text(
                      widget.staff.name,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: darkBlue,
                      ),
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(height: 8),

                  // Email
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [primaryColor.withOpacity(0.1), accentTeal.withOpacity(0.05)],
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        widget.staff.email,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[700],
                          fontWeight: FontWeight.w500,
                        ),
                        textAlign: TextAlign.center,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Department & Role
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _buildInfoChip(Icons.work_outline, widget.staff.department),
                        const SizedBox(width: 8),
                        _buildInfoChip(Icons.badge_outlined, widget.staff.role),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Authorities
                  if (widget.staff.authorities.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [backgroundColor, Colors.white],
                          ),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: primaryColor.withOpacity(0.2)),
                        ),
                        child: Column(
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(4),
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: [primaryColor.withOpacity(0.2), accentTeal.withOpacity(0.1)],
                                    ),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: const Icon(Icons.security, size: 12, color: primaryColor),
                                ),
                                const SizedBox(width: 6),
                                const Text(
                                  'Permissions',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: darkBlue,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Wrap(
                              spacing: 4,
                              runSpacing: 4,
                              alignment: WrapAlignment.center,
                              children: widget.staff.authorities.take(3).map((auth) {
                                return Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: [
                                        _getAuthorityColor(auth).withOpacity(0.2),
                                        _getAuthorityColor(auth).withOpacity(0.1),
                                      ],
                                    ),
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                      color: _getAuthorityColor(auth).withOpacity(0.3),
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        _getAuthorityIcon(auth),
                                        size: 10,
                                        color: _getAuthorityColor(auth),
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        auth,
                                        style: TextStyle(
                                          fontSize: 9,
                                          fontWeight: FontWeight.w600,
                                          color: _getAuthorityColor(auth),
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              }).toList(),
                            ),
                            if (widget.staff.authorities.length > 3)
                              Padding(
                                padding: const EdgeInsets.only(top: 4),
                                child: Text(
                                  '+${widget.staff.authorities.length - 3} more',
                                  style: TextStyle(
                                    fontSize: 9,
                                    color: Colors.grey[600],
                                    fontStyle: FontStyle.italic,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInfoChip(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: Colors.grey[600]),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              color: Colors.grey[700],
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  IconData _getAuthorityIcon(String authority) {
    switch (authority) {
      case 'Clinic':
        return Icons.local_hospital_rounded;
      case 'Appointments':
        return Icons.calendar_month_rounded;
      case 'Messages':
        return Icons.message_rounded;
      default:
        return Icons.check_circle;
    }
  }

  Color _getAuthorityColor(String authority) {
    switch (authority) {
      case 'Clinic':
        return primaryColor;
      case 'Appointments':
        return accentTeal;
      case 'Messages':
        return warningOrange;
      default:
        return Colors.grey;
    }
  }
}

// Staff Details Dialog
class _StaffDetailsDialog extends StatelessWidget {
  final Staff staff;

  const _StaffDetailsDialog({
    required this.staff,
  });

  static const Color primaryColor = Color.fromRGBO(81, 115, 153, 1);
  static const Color backgroundColor = Color.fromARGB(255, 248, 253, 255);
  static const Color accentTeal = Color(0xFF5B9BD5);
  static const Color successGreen = Color(0xFF34D399);
  static const Color darkBlue = Color.fromRGBO(51, 75, 103, 1);

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 600, maxHeight: 700),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Colors.white, backgroundColor],
          ),
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: primaryColor.withOpacity(0.2),
              blurRadius: 30,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(28),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [primaryColor, accentTeal],
                ),
                borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                boxShadow: [
                  BoxShadow(
                    color: primaryColor.withOpacity(0.3),
                    blurRadius: 15,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Column(
                children: [
                  // Profile Image
                  Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white,
                      border: Border.all(color: Colors.white, width: 4),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.2),
                          blurRadius: 15,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    image: staff.image.isNotEmpty
                      ? DecorationImage(
                          image: NetworkImage(
                            staff.image.startsWith('http')
                                ? staff.image
                                : authRepository.getImageUrl(staff.image),
                          ),
                          fit: BoxFit.cover,
                        )
                      : null,
                    ),
                    child: staff.image.isEmpty
                        ? Container(
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: LinearGradient(
                                colors: [primaryColor.withOpacity(0.3), accentTeal.withOpacity(0.2)],
                              ),
                            ),
                            child: const Icon(Icons.person, size: 45, color: primaryColor),
                          )
                        : null,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    staff.name,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.25),
                      borderRadius: BorderRadius.circular(15),
                      border: Border.all(color: Colors.white.withOpacity(0.3)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          staff.isActive ? Icons.check_circle : Icons.cancel,
                          color: Colors.white,
                          size: 16,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          staff.isActive ? 'Active' : 'Inactive',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Content
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Contact Information Section
                    _buildSectionHeader('Contact Information', Icons.contact_mail),
                    const SizedBox(height: 16),
                    _buildInfoCard([
                      _buildInfoRow(Icons.email, 'Email', staff.email),
                      _buildInfoRow(Icons.phone, 'Phone', staff.phone ?? 'Not provided'),
                      _buildInfoRow(Icons.work, 'Department', staff.department),
                      _buildInfoRow(Icons.badge, 'Role', staff.role),
                      _buildInfoRow(Icons.fingerprint, 'User ID', staff.userId),
                    ]),
                    const SizedBox(height: 24),

                    // Permissions Section
                    _buildSectionHeader('Access Permissions', Icons.security),
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [backgroundColor, Colors.white],
                        ),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: primaryColor.withOpacity(0.2)),
                      ),
                      child: staff.authorities.isEmpty
                          ? Center(
                              child: Padding(
                                padding: const EdgeInsets.all(16),
                                child: Text(
                                  'No permissions assigned',
                                  style: TextStyle(
                                    color: Colors.grey[600],
                                    fontStyle: FontStyle.italic,
                                  ),
                                ),
                              ),
                            )
                          : Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: staff.authorities.map((authority) {
                                return Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: [
                                        _getAuthorityColor(authority).withOpacity(0.2),
                                        _getAuthorityColor(authority).withOpacity(0.1),
                                      ],
                                    ),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: _getAuthorityColor(authority).withOpacity(0.3),
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        _getAuthorityIcon(authority),
                                        size: 16,
                                        color: _getAuthorityColor(authority),
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        authority,
                                        style: TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w600,
                                          color: _getAuthorityColor(authority),
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              }).toList(),
                            ),
                    ),
                    const SizedBox(height: 24),

                    // Timestamps Section
                    _buildSectionHeader('Timeline', Icons.schedule),
                    const SizedBox(height: 16),
                    _buildInfoCard([
                      _buildInfoRow(Icons.calendar_today, 'Created', _formatDate(staff.createdAt)),
                      _buildInfoRow(Icons.update, 'Last Updated', _formatDate(staff.updatedAt)),
                    ]),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [primaryColor.withOpacity(0.1), accentTeal.withOpacity(0.05)],
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [primaryColor.withOpacity(0.2), accentTeal.withOpacity(0.1)],
              ),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: primaryColor, size: 18),
          ),
          const SizedBox(width: 12),
          Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: darkBlue,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard(List<Widget> children) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: primaryColor.withOpacity(0.2)),
      ),
      child: Column(
        children: children.map((child) {
          final index = children.indexOf(child);
          return Column(
            children: [
              child,
              if (index < children.length - 1)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: Divider(height: 1, color: primaryColor.withOpacity(0.1)),
                ),
            ],
          );
        }).toList(),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [primaryColor.withOpacity(0.1), accentTeal.withOpacity(0.05)],
            ),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, size: 18, color: primaryColor),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: darkBlue,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  IconData _getAuthorityIcon(String authority) {
    switch (authority) {
      case 'Clinic':
        return Icons.local_hospital_rounded;
      case 'Appointments':
        return Icons.calendar_month_rounded;
      case 'Messages':
        return Icons.message_rounded;
      default:
        return Icons.check_circle;
    }
  }

  Color _getAuthorityColor(String authority) {
    switch (authority) {
      case 'Clinic':
        return primaryColor;
      case 'Appointments':
        return accentTeal;
      case 'Messages':
        return const Color(0xFFF59E0B);
      default:
        return Colors.grey;
    }
  }

  String _formatDate(String isoDate) {
    try {
      final date = DateTime.parse(isoDate);
      return '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
    } catch (e) {
      return isoDate;
    }
  }
}