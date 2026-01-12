import 'package:flutter/material.dart';
import 'package:capstone_app/data/repository/auth.repository.dart';
import 'package:capstone_app/data/id_verification/screens/id_verification_screen.dart';
import 'package:get/get.dart';

/// Reusable widget to display verification status
/// Can be used anywhere in the app (profile, settings, appointment pages, etc.)
class VerificationStatusWidget extends StatefulWidget {
  final String userId;
  final String email;
  final String userRole;
  final bool showButton;
  final VoidCallback? onVerificationComplete;

  const VerificationStatusWidget({
    Key? key,
    required this.userId,
    required this.email,
    required this.userRole,
    this.showButton = true,
    this.onVerificationComplete,
  }) : super(key: key);

  @override
  State<VerificationStatusWidget> createState() =>
      _VerificationStatusWidgetState();
}

class _VerificationStatusWidgetState extends State<VerificationStatusWidget> {
  final AuthRepository _authRepository = Get.find<AuthRepository>();
  bool _isLoading = true;
  Map<String, dynamic>? _verificationStatus;

  @override
  void initState() {
    super.initState();
    _loadVerificationStatus();
    _authRepository.cleanupStuckVerifications(widget.userId);
  }

  void refresh() {
    _loadVerificationStatus();
  }

  Future<void> _loadVerificationStatus() async {
    setState(() => _isLoading = true);

    try {
      final status =
          await _authRepository.getUserVerificationStatus(widget.userId);
      setState(() {
        _verificationStatus = status;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _handleVerifyNow() async {
    final result = await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => IdVerificationScreen(
          userId: widget.userId,
          email: widget.email,
          authRepository: _authRepository,
        ),
      ),
    );

    if (result == true) {
      _loadVerificationStatus();
      widget.onVerificationComplete?.call();
    }
  }

  Color _getStatusColor() {
    if (_verificationStatus == null) return Colors.grey;

    final status = _verificationStatus!['status'] as String? ?? 'not_started';

    switch (status) {
      case 'approved':
        return const Color(0xFF4CAF50); // Green
      case 'pending':
      case 'in_progress':
        return const Color(0xFFFF9800); // Orange
      case 'rejected':
        return const Color(0xFFF44336); // Red
      default:
        return const Color(0xFF9E9E9E); // Grey
    }
  }

  IconData _getStatusIcon() {
    if (_verificationStatus == null) return Icons.badge_outlined;

    final status = _verificationStatus!['status'] as String? ?? 'not_started';

    switch (status) {
      case 'approved':
        return Icons.verified_user;
      case 'pending':
      case 'in_progress':
        return Icons.hourglass_empty;
      case 'rejected':
        return Icons.cancel_outlined;
      default:
        return Icons.badge_outlined;
    }
  }

  String _getStatusText() {
    if (_verificationStatus == null) return 'Not Verified';

    final status = _verificationStatus!['status'] as String? ?? 'not_started';

    switch (status) {
      case 'approved':
        return 'ID Verified';
      case 'pending':
        return 'Verification Pending';
      case 'in_progress':
        return 'Verification In Progress';
      case 'rejected':
        return 'Verification Rejected';
      default:
        return 'ID Not Verified';
    }
  }

  String _getStatusDescription() {
    if (_verificationStatus == null)
      return 'Verify your ID to access all features';

    final status = _verificationStatus!['status'] as String? ?? 'not_started';

    switch (status) {
      case 'approved':
        return 'Your identity has been verified';
      case 'pending':
        return 'Your verification is being reviewed';
      case 'in_progress':
        return 'Complete your verification process';
      case 'rejected':
        final reason = _verificationStatus!['verificationDoc']
            ?['rejectionReason'] as String?;
        return reason ?? 'Your verification was rejected. Please try again.';
      default:
        return 'Verify your ID to book appointments';
    }
  }

  bool _shouldShowButton() {
    if (!widget.showButton) return false;
    if (_verificationStatus == null) return true;

    final status = _verificationStatus!['status'] as String? ?? 'not_started';
    return status != 'approved' && status != 'in_progress';
  }

  @override
  Widget build(BuildContext context) {
    // Don't show for admin/staff
    if (widget.userRole == 'admin' || widget.userRole == 'staff') {
      return const SizedBox.shrink();
    }

    if (_isLoading) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: Center(
            child: CircularProgressIndicator(),
          ),
        ),
      );
    }

    final statusColor = _getStatusColor();
    final statusIcon = _getStatusIcon();
    final statusText = _getStatusText();
    final statusDescription = _getStatusDescription();

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              statusColor.withOpacity(0.1),
              Colors.white,
            ],
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    statusIcon,
                    color: statusColor,
                    size: 28,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        statusText,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: statusColor,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        statusDescription,
                        style: const TextStyle(
                          fontSize: 14,
                          color: Colors.black87,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            if (_shouldShowButton()) ...[
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _handleVerifyNow,
                  icon: const Icon(Icons.verified_user),
                  label: Text(
                    _verificationStatus?['status'] == 'rejected'
                        ? 'Retry Verification'
                        : 'Verify Now',
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1976D2),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Compact version for use in app bars or small spaces
class VerificationBadge extends StatelessWidget {
  final bool isVerified;
  final VoidCallback? onTap;

  const VerificationBadge({
    Key? key,
    required this.isVerified,
    this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isVerified
              ? const Color(0xFF4CAF50).withOpacity(0.1)
              : const Color(0xFFFF9800).withOpacity(0.1),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color:
                isVerified ? const Color(0xFF4CAF50) : const Color(0xFFFF9800),
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isVerified ? Icons.verified_user : Icons.badge_outlined,
              color: isVerified
                  ? const Color(0xFF4CAF50)
                  : const Color(0xFFFF9800),
              size: 16,
            ),
            const SizedBox(width: 6),
            Text(
              isVerified ? 'Verified' : 'Not Verified',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: isVerified
                    ? const Color(0xFF4CAF50)
                    : const Color(0xFFFF9800),
              ),
            ),
          ],
        ),
      ),
    );
  }
}