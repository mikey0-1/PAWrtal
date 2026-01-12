import 'package:capstone_app/utils/appwrite_constant.dart';
import 'package:get/get.dart';
import 'package:capstone_app/data/repository/auth.repository.dart';
import 'package:capstone_app/data/models/user_model.dart';
import 'package:capstone_app/data/models/id_verification_model.dart';
import 'package:get_storage/get_storage.dart';

class AdminVerifyUserController extends GetxController {
  final AuthRepository authRepository;
  final GetStorage storage = GetStorage();

  AdminVerifyUserController(this.authRepository);

  final isVerifying = false.obs;
  final errorMessage = ''.obs;

  /// Verify user manually by admin
  Future<bool> verifyUser(User user) async {
    try {

      isVerifying.value = true;
      errorMessage.value = '';

      // Get admin's clinic ID
      final clinicId = storage.read('clinicId') as String?;
      final adminName = storage.read('name') as String? ?? 'Admin';

      if (clinicId == null || clinicId.isEmpty) {
        errorMessage.value = 'Admin clinic ID not found';
        return false;
      }


      // Step 1: Check if user already has a verification record
      final existingVerification =
          await authRepository.getIdVerificationByUserId(user.userId);

      IdVerification? verificationRecord;

      if (existingVerification != null) {

        // Update existing record
        verificationRecord = existingVerification.copyWith(
          status: 'approved',
          verifyByClinic: clinicId,
          verifiedAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        await authRepository.updateIdVerification(verificationRecord);
      } else {

        // Create new verification record
        verificationRecord = IdVerification(
          userId: user.userId,
          email: user.email,
          status: 'approved',
          verifyByClinic: clinicId,
          verificationType: 'clinic_verified',
          verifiedAt: DateTime.now(),
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        await authRepository.createIdVerification(verificationRecord);
      }

      // Step 2: Update user's verification status in Users collection

      if (user.documentId == null || user.documentId!.isEmpty) {
        errorMessage.value = 'User document ID not found';
        return false;
      }

      await authRepository.appWriteProvider.databases!.updateDocument(
        databaseId: AppwriteConstants.dbID,
        collectionId: AppwriteConstants.usersCollectionID,
        documentId: user.documentId!,
        data: {
          'idVerified': true,
          'idVerifiedAt': DateTime.now().toIso8601String(),
          'verificationDocumentId': verificationRecord.documentId,
        },
      );



      return true;
    } catch (e) {

      errorMessage.value = 'Failed to verify user: ${e.toString()}';
      return false;
    } finally {
      isVerifying.value = false;
    }
  }

  /// Get verification details for a user
  Future<Map<String, dynamic>> getVerificationDetails(String userId) async {
    try {

      final verification =
          await authRepository.getIdVerificationByUserId(userId);

      if (verification == null) {
        return {
          'hasVerification': false,
          'status': 'not_verified',
          'isVerified': false,
        };
      }

      // Get clinic name if verified by clinic
      String? clinicName;
      if (verification.verifyByClinic != null &&
          verification.verifyByClinic!.isNotEmpty) {
        try {
          final clinicDoc = await authRepository.appWriteProvider.getClinicById(
            verification.verifyByClinic!,
          );
          if (clinicDoc != null) {
            clinicName = clinicDoc.data['clinicName'] ?? 'Unknown Clinic';
          }
        } catch (e) {
        }
      }

      return {
        'hasVerification': true,
        'status': verification.status,
        'isVerified': verification.status == 'approved',
        'verifiedByClinic': verification.verifyByClinic,
        'clinicName': clinicName,
        'verifiedAt': verification.verifiedAt,
        'verificationType': verification.verificationType,
      };
    } catch (e) {
      return {
        'hasVerification': false,
        'status': 'error',
        'isVerified': false,
        'error': e.toString(),
      };
    }
  }

  /// Check if current admin's clinic already verified this user
  Future<bool> isVerifiedByCurrentClinic(String userId) async {
    try {
      final clinicId = storage.read('clinicId') as String?;
      if (clinicId == null) return false;

      final verification =
          await authRepository.getIdVerificationByUserId(userId);

      if (verification == null) return false;

      return verification.verifyByClinic == clinicId &&
          verification.status == 'approved';
    } catch (e) {
      return false;
    }
  }

  @override
  void onClose() {
    isVerifying.close();
    errorMessage.close();
    super.onClose();
  }
}
