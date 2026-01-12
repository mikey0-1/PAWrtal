import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:capstone_app/utils/appwrite_constant.dart';

class ArgosService {
  /// Generate ARGOS Liveform URL for ID verification
  /// This URL will be opened in a WebView or browser
  String generateVerificationUrl({
    required String userId,
    required String email,
  }) {
    final baseUrl = AppwriteConstants.argosLiveformBaseUrl;
    final pid = AppwriteConstants.argosProjectId;

    // Build URL with query parameters
    final uri = Uri.parse(baseUrl).replace(
      queryParameters: {
        'pid': pid,
        'email': email,
        // CRITICAL: Pass your app's userId to ARGOS
        // This will be returned in webhook as customUserId or userId
        'customUserId': userId,  // Try this first
        'userId': userId,         // Fallback
        'custom_user_id': userId, // Another fallback
      },
    );

    return uri.toString();
  }

  /// Get submission details from ARGOS API
  Future<Map<String, dynamic>?> getSubmissionDetails(
      String submissionId) async {
    try {
      final url = Uri.parse(
        '${AppwriteConstants.argosApiBaseUrl}/submission/$submissionId',
      );

      final response = await http.get(
        url,
        headers: {
          'Authorization': 'Bearer ${AppwriteConstants.argosApiKey}',
          'Content-Type': 'application/json',
        },
      );


      if (response.statusCode == 200) {
        final data = json.decode(response.body) as Map<String, dynamic>;
        return data;
      } else {
        return null;
      }
    } catch (e) {
      return null;
    }
  }

  /// Parse webhook data from ARGOS
  /// This method will be called when your backend receives a webhook
  Map<String, dynamic> parseWebhookData(Map<String, dynamic> webhookPayload) {
    try {
      // ARGOS webhook structure (based on documentation)
      final event = webhookPayload['event'] as String?;
      final data = webhookPayload['data'] as Map<String, dynamic>?;

      if (data == null) {
        return {'success': false, 'error': 'No data in webhook'};
      }

      // Extract important fields
      final userId = data['userId'] as String?;
      final email = data['email'] as String?;
      final status =
          data['status'] as String?; // 'approved', 'rejected', 'pending'
      final submissionId =
          data['submissionId'] as String? ?? data['id'] as String?;
      final fullName = data['name'] as String?;
      final birthDate = data['birthDate'] as String?;
      final idType = data['idType'] as String?;
      final countryCode = data['country'] as String?;
      final rejectReason = data['rejectReason'] as String?;

      return {
        'success': true,
        'event': event,
        'userId': userId,
        'email': email,
        'status': status,
        'submissionId': submissionId,
        'fullName': fullName,
        'birthDate': birthDate,
        'idType': idType,
        'countryCode': countryCode,
        'rejectReason': rejectReason,
        'rawData': data,
      };
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }

  /// Verify webhook signature (for security)
  /// Implement this if ARGOS provides a signature in the webhook
  bool verifyWebhookSignature(
    String payload,
    String signature,
    String secret,
  ) {
    // TODO: Implement signature verification
    // This depends on ARGOS's signature algorithm
    // Usually it's HMAC-SHA256
    return true;
  }

  /// Check if user needs verification
  /// Returns true if verification is required
  bool requiresVerification(String userRole) {
    // Only regular users need ID verification
    // Admins and staff don't need it
    return userRole == 'customer' || userRole == 'user';
  }

  /// Get verification status text for UI
  String getVerificationStatusText(String status) {
    switch (status.toLowerCase()) {
      case 'approved':
        return 'Verified';
      case 'pending':
        return 'Verification Pending';
      case 'in_progress':
        return 'Verification In Progress';
      case 'rejected':
        return 'Verification Rejected';
      default:
        return 'Not Verified';
    }
  }

  /// Get verification status color for UI
  String getVerificationStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'approved':
        return '#4CAF50'; // Green
      case 'pending':
      case 'in_progress':
        return '#FF9800'; // Orange
      case 'rejected':
        return '#F44336'; // Red
      default:
        return '#9E9E9E'; // Grey
    }
  }
}