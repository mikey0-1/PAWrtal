import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:capstone_app/data/repository/auth.repository.dart';
import 'package:capstone_app/data/models/archived_clinic_model.dart';
import 'package:capstone_app/web/super_admin/WebVersion/services/clinic_archive_service.dart';
import 'package:intl/intl.dart';
import 'package:appwrite/appwrite.dart';

/// Super Admin Dashboard for Archived Clinics
class ArchivedClinicsDashboard extends StatefulWidget {
  const ArchivedClinicsDashboard({Key? key}) : super(key: key);

  @override
  State<ArchivedClinicsDashboard> createState() => _ArchivedClinicsDashboardState();
}

class _ArchivedClinicsDashboardState extends State<ArchivedClinicsDashboard> {
  final AuthRepository _authRepository = Get.find<AuthRepository>();
  final ClinicArchiveService _archiveService = Get.find<ClinicArchiveService>();

  List<ArchivedClinic> _archivedClinics = [];
  Map<String, int> _stats = {};
  bool _isLoading = true;
  String _searchQuery = '';
  String _filterStatus = 'active'; // active, recovered, deleted, all
  String _selectedSort = 'newest'; // newest, oldest, alphabetical

  RealtimeSubscription? _archiveSubscription;
  RealtimeSubscription? _storageSubscription;

  // Colors
  static const Color backgroundColor = Color.fromRGBO(248, 253, 255, 1);
  static const Color primaryColor = Color.fromRGBO(81, 115, 153, 1);
  static const Color accentTeal = Color(0xFF5B9BD5);
  static const Color successGreen = Color(0xFF34D399);
  static const Color warningOrange = Color(0xFFF59E0B);
  static const Color darkRed = Color(0xFFDC2626);
  static const Color darkBlue = Color.fromRGBO(51, 75, 103, 1);

  @override
  void initState() {
    super.initState();
    _loadArchivedClinics();
    _loadStats();
    _setupRealtimeSubscription();
  }

  @override
  void dispose() {
    _archiveSubscription?.close();
    super.dispose();
  }

  Future<void> _loadArchivedClinics() async {
    setState(() => _isLoading = true);

    try {
      final clinics = await _authRepository.getAllArchivedClinics(
        includePermanentlyDeleted: _filterStatus == 'all' || _filterStatus == 'deleted',
        limit: 500,
      );

      setState(() {
        _archivedClinics = clinics;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _loadStats() async {
    try {
      final stats = await _archiveService.getArchiveStats();
      setState(() => _stats = stats);
    } catch (e) {
    }
  }

  void _setupRealtimeSubscription() {
    try {
      final subscription = _authRepository.subscribeToArchivedClinics();
      _archiveSubscription = subscription as RealtimeSubscription?;

      subscription.listen((event) {
        _loadArchivedClinics();
        _loadStats();
      });
    } catch (e) {
    }
  }

  List<ArchivedClinic> get _filteredClinics {
    var filtered = _archivedClinics.where((clinic) {
      // Filter by status
      switch (_filterStatus) {
        case 'active':
          if (clinic.isPermanentlyDeleted || clinic.isRecovered) return false;
          break;
        case 'recovered':
          if (!clinic.isRecovered) return false;
          break;
        case 'deleted':
          if (!clinic.isPermanentlyDeleted) return false;
          break;
        case 'all':
          break;
      }

      // Filter by search query
      if (_searchQuery.isNotEmpty) {
        final query = _searchQuery.toLowerCase();
        return clinic.clinicName.toLowerCase().contains(query) ||
            clinic.email.toLowerCase().contains(query) ||
            clinic.address.toLowerCase().contains(query);
      }

      return true;
    }).toList();

    // Apply sorting
    switch (_selectedSort) {
      case 'alphabetical':
        filtered.sort((a, b) => a.clinicName.toLowerCase().compareTo(b.clinicName.toLowerCase()));
        break;
      case 'oldest':
        filtered.sort((a, b) => a.scheduledDeletionAt.compareTo(b.scheduledDeletionAt));
        break;
      case 'newest':
      default:
        filtered.sort((a, b) => b.archivedAt.compareTo(a.archivedAt));
        break;
    }

    return filtered;
  }

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
                  'Sort Archived Clinics',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: darkBlue,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            _buildSortOption(
              'Newest First',
              'Recently archived clinics',
              Icons.arrow_downward_rounded,
              'newest',
              [successGreen, accentTeal],
            ),
            const SizedBox(height: 12),
            _buildSortOption(
              'Oldest First',
              'Clinics due for deletion soon',
              Icons.arrow_upward_rounded,
              'oldest',
              [warningOrange, primaryColor],
            ),
            const SizedBox(height: 12),
            _buildSortOption(
              'Alphabetical (A-Z)',
              'Sort by clinic name',
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
        setState(() => _selectedSort = sortValue);
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

  Future<void> _recoverClinic(ArchivedClinic clinic) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Recover Clinic'),
        content: Text('Are you sure you want to recover ${clinic.clinicName}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: successGreen),
            child: const Text('Recover'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      final currentUser = await _authRepository.getUser();
      final result = await _authRepository.recoverArchivedClinic(
        adminId: clinic.adminId,
        recoveredBy: currentUser?.name ?? 'Super Admin',
      );

      if (result['success'] == true) {
        Get.snackbar(
          'Success',
          '${clinic.clinicName} has been recovered successfully',
          backgroundColor: successGreen,
          colorText: Colors.white,
        );
        _loadArchivedClinics();
        _loadStats();
      } else {
        throw Exception(result['error']);
      }
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to recover clinic: $e',
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }

 Future<void> _processScheduledDeletionsNow() async {
    // ============================================
    // STEP 1: FIRST CONFIRMATION - WARNING DIALOG
    // ============================================
    final firstConfirm = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: Container(
          constraints: const BoxConstraints(maxWidth: 500),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.white,
                darkRed.withOpacity(0.05),
              ],
            ),
            borderRadius: BorderRadius.circular(24),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [darkRed, darkRed.withOpacity(0.8)],
                  ),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(24),
                    topRight: Radius.circular(24),
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.warning_rounded,
                        color: Colors.white,
                        size: 32,
                      ),
                    ),
                    const SizedBox(width: 16),
                    const Expanded(
                      child: Text(
                        'Permanent Deletion Warning',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Content
              Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'You are about to permanently delete archived clinics!',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: darkBlue,
                      ),
                    ),
                    const SizedBox(height: 16),
                    
                    // Warning boxes
                    _buildWarningBox(
                      icon: Icons.delete_forever,
                      title: 'All Clinic Data Will Be Lost',
                      description: 'This includes appointments, medical records, conversations, and staff accounts.',
                      color: darkRed,
                    ),
                    const SizedBox(height: 12),
                    
                    _buildWarningBox(
                      icon: Icons.schedule,
                      title: 'Only Expired Archives',
                      description: 'Only clinics past their 30-day retention period will be deleted.',
                      color: warningOrange,
                    ),
                    const SizedBox(height: 12),
                    
                    _buildWarningBox(
                      icon: Icons.restore_from_trash,
                      title: 'No Recovery Possible',
                      description: 'Once deleted, these clinics cannot be recovered by any means.',
                      color: darkBlue,
                    ),
                    
                    const SizedBox(height: 20),
                    
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: darkRed.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: darkRed.withOpacity(0.3)),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.info_outline, color: darkRed, size: 20),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'This action is IRREVERSIBLE and will permanently remove all data.',
                              style: TextStyle(
                                fontSize: 13,
                                color: darkRed,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // Actions
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                child: Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(context, false),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          side: BorderSide(color: primaryColor),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text(
                          'Cancel',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: primaryColor,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [darkRed, darkRed.withOpacity(0.8)],
                          ),
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: darkRed.withOpacity(0.3),
                              blurRadius: 8,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: ElevatedButton(
                          onPressed: () => Navigator.pop(context, true),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.transparent,
                            shadowColor: Colors.transparent,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Text(
                            'I Understand, Continue',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );

    if (firstConfirm != true) return;

    // ============================================
    // STEP 2: GET CLINICS DUE FOR DELETION
    // ============================================
    List<ArchivedClinic> clinicsDue = [];
    try {
      Get.dialog(
        const Center(
          child: Card(
            child: Padding(
              padding: EdgeInsets.all(24.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Checking clinics due for deletion...'),
                ],
              ),
            ),
          ),
        ),
        barrierDismissible: false,
      );

      final allArchived = await _authRepository.getAllArchivedClinics(
        includePermanentlyDeleted: false,
        limit: 500,
      );

      final now = DateTime.now();
      clinicsDue = allArchived.where((clinic) {
        return !clinic.isPermanentlyDeleted &&
            !clinic.isRecovered &&
            clinic.scheduledDeletionAt.isBefore(now);
      }).toList();

      Get.back(); // Close loading dialog
    } catch (e) {
      Get.back(); // Close loading dialog
      Get.snackbar(
        'Error',
        'Failed to check deletion status: $e',
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
      return;
    }

    // If no clinics due for deletion
    if (clinicsDue.isEmpty) {
      Get.dialog(
        AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: successGreen.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.check_circle, color: successGreen),
              ),
              const SizedBox(width: 12),
              const Text('No Deletions Needed'),
            ],
          ),
          content: const Text(
            'There are no archived clinics currently due for permanent deletion. All clinics are still within their 30-day retention period.',
          ),
          actions: [
            ElevatedButton(
              onPressed: () => Get.back(),
              style: ElevatedButton.styleFrom(
                backgroundColor: successGreen,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text('OK'),
            ),
          ],
        ),
      );
      return;
    }

    // ============================================
    // STEP 3: SECOND CONFIRMATION - TYPE TO CONFIRM
    // ============================================
    final TextEditingController confirmController = TextEditingController();
    final confirmText = 'DELETE ${clinicsDue.length} CLINICS';
    
    final secondConfirm = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          final isConfirmTextValid = confirmController.text == confirmText;
          
          return Dialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
            child: Container(
              constraints: const BoxConstraints(maxWidth: 550),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Colors.white, backgroundColor],
                ),
                borderRadius: BorderRadius.circular(24),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Header
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [darkRed, Colors.red.shade900],
                      ),
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(24),
                        topRight: Radius.circular(24),
                      ),
                    ),
                    child: Column(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.warning_amber_rounded,
                            color: Colors.white,
                            size: 48,
                          ),
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'Final Confirmation Required',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Content
                  Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Clinics count
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                darkRed.withOpacity(0.15),
                                darkRed.withOpacity(0.05),
                              ],
                            ),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: darkRed.withOpacity(0.3)),
                          ),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: darkRed,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  '${clinicsDue.length}',
                                  style: const TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 16),
                              const Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Clinics Ready for Deletion',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: darkBlue,
                                      ),
                                    ),
                                    SizedBox(height: 4),
                                    Text(
                                      'All have exceeded 30-day retention',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        
                        const SizedBox(height: 20),
                        
                        // Clinics list preview
                        if (clinicsDue.isNotEmpty) ...[
                          const Text(
                            'Clinics to be deleted:',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: darkBlue,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Container(
                            constraints: const BoxConstraints(maxHeight: 150),
                            decoration: BoxDecoration(
                              color: Colors.grey.shade50,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.grey.shade300),
                            ),
                            child: ListView.separated(
                              shrinkWrap: true,
                              itemCount: clinicsDue.length,
                              separatorBuilder: (_, __) => Divider(height: 1, color: Colors.grey.shade300),
                              itemBuilder: (context, index) {
                                final clinic = clinicsDue[index];
                                return Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                  child: Row(
                                    children: [
                                      Icon(Icons.local_hospital, size: 16, color: darkRed),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          clinic.clinicName,
                                          style: const TextStyle(fontSize: 13),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                      Text(
                                        clinic.email,
                                        style: TextStyle(
                                          fontSize: 11,
                                          color: Colors.grey.shade600,
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),
                          ),
                          const SizedBox(height: 20),
                        ],
                        
                        // Confirmation instruction
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: warningOrange.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: warningOrange.withOpacity(0.3)),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(Icons.keyboard, color: warningOrange, size: 20),
                                  const SizedBox(width: 8),
                                  const Text(
                                    'Type the following to confirm:',
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                      color: darkBlue,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: darkRed),
                                ),
                                child: SelectableText(
                                  confirmText,
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: darkRed,
                                    fontFamily: 'monospace',
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        
                        const SizedBox(height: 16),
                        
                        // Input field
                        TextField(
                          controller: confirmController,
                          onChanged: (value) => setState(() {}),
                          decoration: InputDecoration(
                            labelText: 'Type confirmation text',
                            hintText: confirmText,
                            prefixIcon: Icon(
                              isConfirmTextValid ? Icons.check_circle : Icons.edit,
                              color: isConfirmTextValid ? successGreen : Colors.grey,
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(
                                color: isConfirmTextValid ? successGreen : Colors.grey,
                                width: 2,
                              ),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(
                                color: isConfirmTextValid ? successGreen : Colors.grey.shade300,
                                width: 2,
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(
                                color: isConfirmTextValid ? successGreen : primaryColor,
                                width: 2,
                              ),
                            ),
                          ),
                          style: const TextStyle(
                            fontFamily: 'monospace',
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Actions
                  Padding(
                    padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                    child: Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () {
                              confirmController.dispose();
                              Navigator.pop(context, false);
                            },
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              side: BorderSide(color: primaryColor),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: const Text(
                              'Cancel',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: primaryColor,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Container(
                            decoration: BoxDecoration(
                              gradient: isConfirmTextValid
                                  ? LinearGradient(
                                      colors: [darkRed, Colors.red.shade900],
                                    )
                                  : null,
                              color: isConfirmTextValid ? null : Colors.grey.shade300,
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: isConfirmTextValid
                                  ? [
                                      BoxShadow(
                                        color: darkRed.withOpacity(0.3),
                                        blurRadius: 8,
                                        offset: const Offset(0, 4),
                                      ),
                                    ]
                                  : null,
                            ),
                            child: ElevatedButton(
                              onPressed: isConfirmTextValid
                                  ? () {
                                      confirmController.dispose();
                                      Navigator.pop(context, true);
                                    }
                                  : null,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.transparent,
                                disabledBackgroundColor: Colors.transparent,
                                shadowColor: Colors.transparent,
                                padding: const EdgeInsets.symmetric(vertical: 16),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: Text(
                                'Permanently Delete',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: isConfirmTextValid ? Colors.white : Colors.grey.shade600,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );

    if (secondConfirm != true) return;

    // ============================================
    // STEP 4: PROCESS DELETION
    // ============================================
    try {
      Get.dialog(
        WillPopScope(
          onWillPop: () async => false,
          child: Center(
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(
                      width: 50,
                      height: 50,
                      child: CircularProgressIndicator(
                        strokeWidth: 5,
                        color: darkRed,
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      'Processing ${clinicsDue.length} deletions...',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'This may take a few moments',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        barrierDismissible: false,
      );

      final result = await _archiveService.processNow();

      Get.back(); // Close loading dialog

      // ============================================
      // STEP 5: SHOW RESULTS
      // ============================================
      Get.dialog(
        AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [successGreen, accentTeal],
                  ),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.check, color: Colors.white),
              ),
              const SizedBox(width: 12),
              const Text('Deletion Complete'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildResultRow(
                icon: Icons.check_circle,
                label: 'Clinics processed',
                value: '${result['processed']}',
                color: successGreen,
              ),
              if (result['errors'] != null && (result['errors'] as List).isNotEmpty) ...[
                const SizedBox(height: 12),
                _buildResultRow(
                  icon: Icons.error,
                  label: 'Errors encountered',
                  value: '${(result['errors'] as List).length}',
                  color: darkRed,
                ),
              ],
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: successGreen.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: successGreen.withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, color: successGreen, size: 20),
                    const SizedBox(width: 8),
                    const Expanded(
                      child: Text(
                        'All expired archived clinics have been permanently deleted.',
                        style: TextStyle(fontSize: 12),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            ElevatedButton(
              onPressed: () => Get.back(),
              style: ElevatedButton.styleFrom(
                backgroundColor: successGreen,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text('OK', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      );

      _loadArchivedClinics();
      _loadStats();
    } catch (e) {
      Get.back(); // Close loading dialog
      Get.snackbar(
        'Error',
        'Failed to process deletions: $e',
        backgroundColor: Colors.red,
        colorText: Colors.white,
        duration: const Duration(seconds: 5),
      );
    }
  }
 
  Widget _buildWarningBox({
    required IconData icon,
    required String title,
    required String description,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Icon(icon, color: Colors.white, size: 16),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey.shade700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResultRow({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Row(
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(width: 8),
        Text(
          '$label: ',
          style: const TextStyle(fontSize: 14),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        surfaceTintColor: Colors.transparent,
        backgroundColor: backgroundColor,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: primaryColor),
          onPressed: () => Navigator.pop(context),
        ),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [primaryColor, accentTeal],
                ),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.archive, color: Colors.white, size: 24),
            ),
            const SizedBox(width: 12),
            const Text(
              'Archived Clinics',
              style: TextStyle(
                color: primaryColor,
                fontWeight: FontWeight.bold,
                fontSize: 22,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: primaryColor),
            onPressed: () {
              _loadArchivedClinics();
              _loadStats();
            },
            tooltip: 'Refresh',
          ),
          IconButton(
            icon: const Icon(Icons.delete_forever, color: darkRed),
            onPressed: _processScheduledDeletionsNow,
            tooltip: 'Process Deletions Now',
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Column(
        children: [
          _buildStatsSection(),
          _buildSearchAndFilter(),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator(color: primaryColor))
                : _filteredClinics.isEmpty
                    ? _buildEmptyState()
                    : _buildClinicList(),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsSection() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [primaryColor.withOpacity(0.1), accentTeal.withOpacity(0.1)],
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
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildStatItem(
                'Total Archived',
                _stats['total']?.toString() ?? '0',
                Icons.archive,
                primaryColor,
              ),
              _buildStatItem(
                'Active',
                _stats['activeArchives']?.toString() ?? '0',
                Icons.hourglass_empty,
                warningOrange,
              ),
              _buildStatItem(
                'Due Soon',
                _stats['dueSoon']?.toString() ?? '0',
                Icons.warning,
                darkRed,
              ),
              _buildStatItem(
                'Recovered',
                _stats['recovered']?.toString() ?? '0',
                Icons.restore,
                successGreen,
              ),
            ],
          ),
          const SizedBox(height: 16),
          Obx(() {
            final serviceStatus = _archiveService.getServiceStatus();
            final isRunning = serviceStatus['isRunning'] as bool;
            final lastRun = serviceStatus['lastRunTime'] as String;

            return Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: isRunning
                      ? [warningOrange.withOpacity(0.1), primaryColor.withOpacity(0.05)]
                      : [successGreen.withOpacity(0.1), accentTeal.withOpacity(0.05)],
                ),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: isRunning ? warningOrange.withOpacity(0.3) : successGreen.withOpacity(0.3),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    isRunning ? Icons.sync : Icons.check_circle,
                    color: isRunning ? warningOrange : successGreen,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      isRunning
                          ? 'Auto-deletion service is running...'
                          : 'Auto-deletion service active. Last run: ${lastRun.isNotEmpty ? _formatDateTime(lastRun) : "Never"}',
                      style: TextStyle(
                        fontSize: 12,
                        color: isRunning ? warningOrange : successGreen,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon, Color color) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [color.withOpacity(0.2), color.withOpacity(0.1)],
            ),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: color.withOpacity(0.3)),
          ),
          child: Icon(icon, color: color, size: 28),
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: color.withOpacity(0.7),
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildSearchAndFilter() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          Row(
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
                    onChanged: (value) => setState(() => _searchQuery = value),
                    decoration: InputDecoration(
                      hintText: 'Search by name, email, or address...',
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
                      suffixIcon: _searchQuery.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear, color: primaryColor),
                              onPressed: () => setState(() => _searchQuery = ''),
                            )
                          : null,
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
                    onTap: _showSortMenu,
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
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _buildFilterChip('Active', 'active'),
                    _buildFilterChip('Recovered', 'recovered'),
                    _buildFilterChip('Deleted', 'deleted'),
                    _buildFilterChip('All', 'all'),
                  ],
                ),
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
                      _selectedSort == 'alphabetical'
                          ? Icons.sort_by_alpha
                          : _selectedSort == 'oldest'
                              ? Icons.arrow_upward
                              : Icons.arrow_downward,
                      size: 14,
                      color: primaryColor,
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
                        color: primaryColor,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, String value) {
    final isSelected = _filterStatus == value;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        label: Text(label),
        selected: isSelected,
        onSelected: (selected) {
          if (selected) {
            setState(() => _filterStatus = value);
            _loadArchivedClinics();
          }
        },
        backgroundColor: Colors.white,
        selectedColor: primaryColor.withOpacity(0.2),
        checkmarkColor: primaryColor,
        labelStyle: TextStyle(
          color: isSelected ? primaryColor : Colors.grey[700],
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.archive_outlined,
            size: 80,
            color: primaryColor.withOpacity(0.3),
          ),
          const SizedBox(height: 16),
          Text(
            'No archived clinics found',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: primaryColor.withOpacity(0.7),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Archived clinics will appear here',
            style: TextStyle(
              fontSize: 14,
              color: primaryColor.withOpacity(0.5),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildClinicList() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _filteredClinics.length,
      itemBuilder: (context, index) {
        return _buildClinicCard(_filteredClinics[index]);
      },
    );
  }

  Widget _buildClinicCard(ArchivedClinic clinic) {
    final daysLeft = clinic.daysUntilDeletion;
    final isDueSoon = daysLeft <= 7 && daysLeft > 0;
    final isDueNow = clinic.isDeletionDue;

    Color statusColor;
    if (clinic.isPermanentlyDeleted) {
      statusColor = Colors.grey;
    } else if (clinic.isRecovered) {
      statusColor = successGreen;
    } else if (isDueNow) {
      statusColor = darkRed;
    } else if (isDueSoon) {
      statusColor = warningOrange;
    } else {
      statusColor = primaryColor;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: statusColor.withOpacity(0.3), width: 2),
      ),
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.white, backgroundColor.withOpacity(0.5)],
          ),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        colors: [statusColor, statusColor.withOpacity(0.7)],
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: statusColor.withOpacity(0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Center(
                      child: Icon(
                        Icons.local_hospital,
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          clinic.clinicName,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: darkBlue,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          clinic.email,
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [statusColor.withOpacity(0.2), statusColor.withOpacity(0.1)],
                      ),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: statusColor.withOpacity(0.3)),
                    ),
                    child: Text(
                      clinic.statusText,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: statusColor,
                      ),
                    ),
                  ),
                ],
              ),
              const Divider(height: 24),
              _buildDetailRow(Icons.person, 'Archived by', clinic.archivedBy),
              const SizedBox(height: 8),
              _buildDetailRow(
                Icons.calendar_today,
                'Archived on',
                _formatDateTime(clinic.archivedAt.toIso8601String()),
              ),
              const SizedBox(height: 8),
              _buildDetailRow(
                Icons.delete_forever,
                'Scheduled deletion',
                _formatDateTime(clinic.scheduledDeletionAt.toIso8601String()),
              ),
              if (clinic.archiveReason.isNotEmpty && clinic.archiveReason != 'No reason provided') ...[
                const SizedBox(height: 8),
                _buildDetailRow(Icons.info_outline, 'Reason', clinic.archiveReason),
              ],
              if (isDueSoon || isDueNow) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: isDueNow
                          ? [darkRed.withOpacity(0.15), darkRed.withOpacity(0.05)]
                          : [warningOrange.withOpacity(0.15), warningOrange.withOpacity(0.05)],
                    ),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: isDueNow ? darkRed.withOpacity(0.3) : warningOrange.withOpacity(0.3),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        isDueNow ? Icons.error : Icons.warning,
                        color: isDueNow ? darkRed : warningOrange,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          isDueNow
                              ? 'This clinic is due for permanent deletion'
                              : 'Will be permanently deleted in $daysLeft days',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: isDueNow ? darkRed : warningOrange,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              if (!clinic.isPermanentlyDeleted && !clinic.isRecovered) ...[
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [successGreen, accentTeal],
                      ),
                      borderRadius: BorderRadius.circular(8),
                      boxShadow: [
                        BoxShadow(
                          color: successGreen.withOpacity(0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: ElevatedButton.icon(
                      onPressed: () => _recoverClinic(clinic),
                      icon: const Icon(Icons.restore, size: 18, color: Colors.white),
                      label: const Text(
                        'Recover Clinic',
                        style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        shadowColor: Colors.transparent,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [primaryColor.withOpacity(0.05), accentTeal.withOpacity(0.03)],
        ),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: primaryColor.withOpacity(0.1)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [primaryColor.withOpacity(0.2), accentTeal.withOpacity(0.1)],
              ),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Icon(icon, size: 14, color: primaryColor),
          ),
          const SizedBox(width: 10),
          Text(
            '$label: ',
            style: TextStyle(
              fontSize: 11,
              color: Colors.grey[600],
              fontWeight: FontWeight.w600,
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: darkBlue,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  String _formatDateTime(String isoString) {
    try {
      final date = DateTime.parse(isoString);
      return DateFormat('MMM dd, yyyy - hh:mm a').format(date);
    } catch (e) {
      return 'Invalid date';
    }
  }
}