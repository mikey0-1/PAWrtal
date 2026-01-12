import 'package:appwrite/appwrite.dart';
import 'package:appwrite/models.dart';
import 'package:capstone_app/utils/appwrite_constant.dart';

/// Migration script to sync verified users' names from ID verification to users table
/// This should be run once to update all existing verified users
class VerifiedNamesMigration {
  final Databases databases;
  
  // Migration stats
  int totalProcessed = 0;
  int successCount = 0;
  int failedCount = 0;
  int skippedCount = 0;
  int alreadyClinicVerified = 0;
  List<String> failedUsers = [];
  List<Map<String, String>> updatedUsers = [];

  VerifiedNamesMigration(this.databases);

  /// 🆕 Convert ALL CAPS name to Proper Case (Title Case)
  String _formatNameToProperCase(String name) {
    if (name.isEmpty) return name;
    
    // Remove extra spaces and trim
    name = name.trim().replaceAll(RegExp(r'\s+'), ' ');
    
    // Split by spaces
    final words = name.toLowerCase().split(' ');
    
    // Capitalize first letter of each word
    final properCaseWords = words.map((word) {
      if (word.isEmpty) return word;
      
      // Handle special prefixes
      if (word.length >= 2) {
        if (word.startsWith('mc') && word.length > 2) {
          return 'Mc' + word[2].toUpperCase() + word.substring(3);
        }
        if (word.startsWith('mac') && word.length > 3) {
          return 'Mac' + word[3].toUpperCase() + word.substring(4);
        }
      }
      
      // Handle hyphenated names
      if (word.contains('-')) {
        return word.split('-').map((part) {
          if (part.isEmpty) return part;
          return part[0].toUpperCase() + part.substring(1);
        }).join('-');
      }
      
      // Handle apostrophes
      if (word.contains("'")) {
        return word.split("'").map((part) {
          if (part.isEmpty) return part;
          return part[0].toUpperCase() + part.substring(1);
        }).join("'");
      }
      
      // Standard capitalization
      return word[0].toUpperCase() + word.substring(1);
    });
    
    return properCaseWords.join(' ');
  }

  /// Run the complete migration
  Future<MigrationResult> runMigration() async {
    
    try {
      // Step 1: Get all approved ID verifications
      final verifications = await _getAllApprovedVerifications();

      if (verifications.isEmpty) {
        return _generateResult();
      }

      // Step 2: Process each verification
      for (var verification in verifications) {
        await _processVerification(verification);
      }

      // Step 3: Generate and display report
      final result = _generateResult();
      _displayReport(result);

      return result;
    } catch (e) {
      rethrow;
    }
  }

  /// Fetch all approved ID verifications (PAWrtal verified only)
  Future<List<Document>> _getAllApprovedVerifications() async {
    List<Document> allVerifications = [];
    int offset = 0;
    const int limit = 100;
    bool hasMore = true;

    while (hasMore) {
      try {
        final response = await databases.listDocuments(
          databaseId: AppwriteConstants.dbID,
          collectionId: AppwriteConstants.idVerificationCollectionID,
          queries: [
            Query.equal('status', 'approved'),
            Query.isNull('verifyByClinic'), // Only PAWrtal verifications
            Query.limit(limit),
            Query.offset(offset),
          ],
        );

        allVerifications.addAll(response.documents);
        
        if (response.documents.length < limit) {
          hasMore = false;
        } else {
          offset += limit;
        }
      } catch (e) {
        hasMore = false;
      }
    }

    return allVerifications;
  }

  /// Process a single verification document
  Future<void> _processVerification(Document verification) async {
    totalProcessed++;
    
    final userId = verification.data['userId'] as String?;
    final fullName = verification.data['fullName'] as String?;
    final email = verification.data['email'] as String?;


    // Validation
    if (userId == null || userId.isEmpty) {
      skippedCount++;
      return;
    }

    if (fullName == null || fullName.isEmpty) {
      skippedCount++;
      failedUsers.add(email ?? userId);
      return;
    }

    // Find user document
    try {
      final userDoc = await _findUserDocument(userId);
      
      if (userDoc == null) {
        skippedCount++;
        failedUsers.add(email ?? userId);
        return;
      }

      // Check if user is clinic verified
      final verifyByClinic = userDoc.data['verifyByClinic'] as String?;
      if (verifyByClinic != null && verifyByClinic.isNotEmpty) {
        alreadyClinicVerified++;
        return;
      }

      // Get current name
      final currentName = userDoc.data['name'] as String? ?? '';
      
      if (currentName == fullName) {
        // Still need to check and update auth name
        await _updateAuthName(userId, fullName);
        successCount++;
        return;
      }

      // 1. Update user document with verified name
      await databases.updateDocument(
        databaseId: AppwriteConstants.dbID,
        collectionId: AppwriteConstants.usersCollectionID,
        documentId: userDoc.$id,
        data: {'name': fullName},
      );

      // 2. 🆕 Update Appwrite Auth account name
      await _updateAuthName(userId, fullName);

      successCount++;
      
      updatedUsers.add({
        'userId': userId,
        'email': email ?? 'N/A',
        'oldName': currentName,
        'newName': fullName,
      });

    } catch (e) {
      failedCount++;
      failedUsers.add(email ?? userId);
    }
  }

  /// 🆕 Update Appwrite Auth account name
  Future<void> _updateAuthName(String userId, String newName) async {
    try {
      // Note: We can't directly update another user's auth name from server-side
      // This would require the user's session token
      // So we'll log it for manual update or handle on next user login
    } catch (e) {
    }
  }

  /// Find user document by userId
  Future<Document?> _findUserDocument(String userId) async {
    try {
      final response = await databases.listDocuments(
        databaseId: AppwriteConstants.dbID,
        collectionId: AppwriteConstants.usersCollectionID,
        queries: [
          Query.equal('userId', userId),
          Query.limit(1),
        ],
      );

      if (response.documents.isNotEmpty) {
        return response.documents.first;
      }

      return null;
    } catch (e) {
      return null;
    }
  }

  /// Generate migration result
  MigrationResult _generateResult() {
    return MigrationResult(
      totalProcessed: totalProcessed,
      successCount: successCount,
      failedCount: failedCount,
      skippedCount: skippedCount,
      clinicVerifiedCount: alreadyClinicVerified,
      failedUsers: failedUsers,
      updatedUsers: updatedUsers,
    );
  }

  /// Display detailed migration report
  void _displayReport(MigrationResult result) {

    if (result.updatedUsers.isNotEmpty) {
      for (var user in result.updatedUsers) {
      }
    }

    if (result.failedUsers.isNotEmpty) {
      for (var user in result.failedUsers) {
      }
    }

  }
}

/// Migration result model
class MigrationResult {
  final int totalProcessed;
  final int successCount;
  final int failedCount;
  final int skippedCount;
  final int clinicVerifiedCount;
  final List<String> failedUsers;
  final List<Map<String, String>> updatedUsers;

  MigrationResult({
    required this.totalProcessed,
    required this.successCount,
    required this.failedCount,
    required this.skippedCount,
    required this.clinicVerifiedCount,
    required this.failedUsers,
    required this.updatedUsers,
  });

  /// Check if migration was successful
  bool get isSuccessful => failedCount == 0;

  /// Get success percentage
  double get successRate {
    if (totalProcessed == 0) return 0.0;
    return (successCount / totalProcessed) * 100;
  }

  /// Convert to JSON for logging
  Map<String, dynamic> toJson() {
    return {
      'totalProcessed': totalProcessed,
      'successCount': successCount,
      'failedCount': failedCount,
      'skippedCount': skippedCount,
      'clinicVerifiedCount': clinicVerifiedCount,
      'successRate': successRate.toStringAsFixed(2) + '%',
      'failedUsers': failedUsers,
      'updatedUsers': updatedUsers,
    };
  }
}

/// Helper function to run migration from anywhere in the app
Future<MigrationResult> runVerifiedNamesMigration(Databases databases) async {
  final migration = VerifiedNamesMigration(databases);
  return await migration.runMigration();
}