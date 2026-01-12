import 'dart:convert';
import 'package:appwrite/appwrite.dart';
import 'package:appwrite/models.dart';
import 'package:capstone_app/data/models/clinic_model.dart';
import 'package:capstone_app/data/models/medical_record_model.dart';
import 'package:capstone_app/data/models/clinic_settings_model.dart';
import 'package:capstone_app/data/models/notification_model.dart';
import 'package:capstone_app/data/models/pet_model.dart';
import 'package:capstone_app/data/models/ratings_and_review_model.dart';
import 'package:capstone_app/data/models/staff_model.dart';
import 'package:capstone_app/data/models/vet_clinic_registration_request_model.dart';
import 'package:capstone_app/data/provider/appwrite_provider.dart';
import 'package:appwrite/models.dart' as models;
import 'package:capstone_app/utils/appwrite_constant.dart';
import 'package:capstone_app/web/admin_web/components/appointments/admin_web_appointment_controller.dart';
import 'package:capstone_app/web/super_admin/WebVersion/vet_clinic_pages/veterinary_clinics/super_ad_staff_management_page.dart';
import 'package:file_picker/file_picker.dart';
import 'package:get/get.dart';
import 'package:get/get_core/src/get_main.dart';
import 'package:get_storage/get_storage.dart';
import '../models/appointment_model.dart';
import 'package:capstone_app/data/models/conversation_model.dart';
import 'package:capstone_app/data/models/message_model.dart';
import 'package:capstone_app/data/models/conversation_starter_model.dart';
import 'package:capstone_app/data/models/user_status_model.dart';
import 'package:capstone_app/data/models/archived_user_model.dart';
import 'package:capstone_app/data/models/archived_clinic_model.dart';
import 'package:capstone_app/data/models/id_verification_model.dart';
import 'package:capstone_app/data/models/vaccination_model.dart';
import 'package:capstone_app/data/models/feedback_deletion_request_model.dart';
import '../models/feedback_and_report_model.dart';

class AuthRepository {
  final AppWriteProvider appWriteProvider;
  AuthRepository(this.appWriteProvider);
  Client get client => appWriteProvider.appwriteClient;

  Future<models.User> signup(Map map) => appWriteProvider.signup(map);
  Future<models.Document> createUser(Map map) =>
      appWriteProvider.createUser(map);

  Future<Map<String, dynamic>> login(Map map) async {
    try {
      final email = map["email"];
      final password = map["password"];

      // First check if this is a staff account BY CHECKING DATABASE
      final staffCheck = await appWriteProvider.checkIfStaffAccount(email);

      if (staffCheck['isStaff'] == true) {
        final staffLoginResult =
            await appWriteProvider.staffLogin(email, password);

        return staffLoginResult;
      }

      // Regular user login
      final result = await appWriteProvider.login(map);

      return result;
    } catch (e) {
      rethrow;
    }
  }

  Future<dynamic> logout(String sessionId) =>
      appWriteProvider.logout(sessionId);

  Future<models.User?> getUser() => appWriteProvider.getUser();

  Future<models.File> uploadImage(dynamic image) =>
      appWriteProvider.uploadImage(image);
  Future<dynamic> deleteImage(String fileID) =>
      appWriteProvider.deleteImage(fileID);
  Future<models.Document> createStaff(Map map) =>
      appWriteProvider.createStaff(map);
  Future<models.DocumentList> getStaff() => appWriteProvider.getStaff();
  Future<models.Document> updateStaff(Map map, {String? currentImage}) {
    return appWriteProvider.updateStaff(map, currentImage: currentImage);
  }

  Future<dynamic> deleteStaff(Map map) => appWriteProvider.deleteStaff(map);

  Future<models.Document?> getClinicByAdminId(String adminId) =>
      appWriteProvider.getClinicByAdminId(adminId);

  Future<models.Document?> getClinicById(String clinicId) =>
      appWriteProvider.getClinicById(clinicId);

  Future<models.Document> updateClinic(
          String documentId, Map<String, dynamic> data) =>
      appWriteProvider.updateClinic(documentId, data);

  Future<List<Clinic>> getAllClinics() async {
    try {
      final docs = await appWriteProvider.getAllClinics();
      return docs.map((doc) {
        final clinic = Clinic.fromMap(doc.data);
        clinic.documentId = doc.$id;
        return clinic;
      }).toList();
    } catch (e) {
      return [];
    }
  }

  Future<List<Appointment>> getClinicAppointments(String clinicId) async {
    try {
      final rawAppointments =
          await appWriteProvider.getClinicAppointments(clinicId);
      return rawAppointments.map((data) {
        try {
          return Appointment.fromMap(Map<String, dynamic>.from(data));
        } catch (e) {
          throw Exception('Invalid appointment data: $e');
        }
      }).toList();
    } catch (e) {
      return [];
    }
  }

  Future<Map<String, int>> getClinicAppointmentStats(String clinicId) =>
      appWriteProvider.getClinicAppointmentStats(clinicId);

  Future<void> updateAppointmentStatus(String documentId, String status) {
    return appWriteProvider.updateAppointmentStatus(documentId, status);
  }

  Future<void> updateFullAppointment(
      String documentId, Map<String, dynamic> data) {
    // CRITICAL: Validate that no medical data is being sent
    final medicalFields = [
      'diagnosis',
      'treatment',
      'prescription',
      'vetNotes',
      'vitals'
    ];
    final foundMedicalFields =
        data.keys.where((key) => medicalFields.contains(key)).toList();

    if (foundMedicalFields.isNotEmpty) {
      // Remove medical fields
      for (var field in foundMedicalFields) {
        data.remove(field);
      }
    }

    // Call the provider method which will clean data again (defense in depth)
    return appWriteProvider.updateFullAppointment(documentId, data);
  }

  Future<models.Document?> getStaffByClinicId(String clinicId) =>
      appWriteProvider.getStaffByClinicId(clinicId);

  Future<models.Document?> getUserById(String userId) =>
      appWriteProvider.getUserById(userId);

  Future<models.Document> createPet(Map map) => appWriteProvider.createPet(map);

  Future<models.Document?> getPetById(String petId) async {
    try {
      // STRATEGY 1: Try as document ID first
      try {
        final result = await appWriteProvider.databases!.getDocument(
          databaseId: AppwriteConstants.dbID,
          collectionId: AppwriteConstants.petsCollectionID,
          documentId: petId,
        );

        return result;
      } catch (e) {}

      // STRATEGY 2: Try as petId field (for backward compatibility)
      final result = await appWriteProvider.databases!.listDocuments(
        databaseId: AppwriteConstants.dbID,
        collectionId: AppwriteConstants.petsCollectionID,
        queries: [Query.equal("petId", petId)],
      );

      if (result.documents.isNotEmpty) {
        return result.documents.first;
      }

      return null;
    } catch (e) {
      return null;
    }
  }

  Future<models.Document?> getPetByName(String petName) =>
      appWriteProvider.getPetByName(petName);

  Future<List<models.Document>> getUserPets(String userId) =>
      appWriteProvider.getUserPets(userId);

  Future<models.Document> updatePet(Pet pet) =>
      appWriteProvider.updatePet(pet.toMap(), pet.documentId!);

  Future<void> deletePet(String documentId) =>
      appWriteProvider.deletePet(documentId);

  Future<void> createAppointment(Appointment appointment) async {
    try {
      // CRITICAL: Check if service is medical from clinic settings
      final clinicSettings =
          await getClinicSettingsByClinicId(appointment.clinicId);

      bool isMedicalService = false;
      if (clinicSettings != null) {
        isMedicalService = clinicSettings.isServiceMedical(appointment.service);
      } else {}

      // Create appointment with correct medical status
      final appointmentWithMedicalStatus = appointment.copyWith(
        isMedicalService: isMedicalService,
      );

      return appWriteProvider
          .createAppointment(appointmentWithMedicalStatus.toMap());
    } catch (e) {
      rethrow;
    }
  }

  Future<List<Appointment>> getUserAppointments(String userId) async {
    try {
      final rawAppointments =
          await appWriteProvider.getUserAppointments(userId);
      return rawAppointments.map((data) {
        try {
          return Appointment.fromMap(Map<String, dynamic>.from(data));
        } catch (e) {
          throw Exception('Invalid appointment data: $e');
        }
      }).toList();
    } catch (e) {
      return [];
    }
  }

  Future<models.Document> createMedicalRecord(MedicalRecord medicalRecord) {
    final recordMap = medicalRecord.toMap();

    // CRITICAL: Validate that vitals column is null
    if (recordMap['vitals'] != null) {
      recordMap['vitals'] = null;
    }

    // Validate required fields
    if (recordMap['diagnosis'] == null ||
        recordMap['diagnosis'].toString().isEmpty) {
      throw Exception('Diagnosis is required for medical records');
    }
    if (recordMap['treatment'] == null ||
        recordMap['treatment'].toString().isEmpty) {
      throw Exception('Treatment is required for medical records');
    }

    return appWriteProvider.createMedicalRecord(recordMap);
  }

  Future<List<MedicalRecord>> getPetMedicalRecords(String petId) async {
    try {
      final rawRecords = await appWriteProvider.getPetMedicalRecords(petId);

      final records = rawRecords.map((data) {
        // Log each record's data

        return MedicalRecord.fromMap(data);
      }).toList();

      return records;
    } catch (e, stackTrace) {
      return [];
    }
  }

  Future<List<Appointment>> getPetMedicalAppointments(String petId) async {
    try {
      final rawAppointments = await appWriteProvider.getUserAppointments(petId);

      final appointments = rawAppointments.map((data) {
        return Appointment.fromMap(Map<String, dynamic>.from(data));
      }).toList();

      // Filter only medical service appointments that are completed
      final medicalAppointments = appointments.where((appointment) {
        return appointment.isMedicalService &&
            (appointment.isCompleted || appointment.hasServiceCompleted);
      }).toList();

      return medicalAppointments;
    } catch (e) {
      return [];
    }
  }

  Future<List<MedicalRecord>> getClinicMedicalRecords(String clinicId) async {
    try {
      final rawRecords =
          await appWriteProvider.getClinicMedicalRecords(clinicId);

      final records = rawRecords.map((data) {
        // Log vitals data for debugging

        return MedicalRecord.fromMap(data);
      }).toList();

      return records;
    } catch (e) {
      return [];
    }
  }

  Future<models.Document> createClinicSettings(ClinicSettings clinicSettings) =>
      appWriteProvider.createClinicSettings(clinicSettings.toMap());

  Future<ClinicSettings?> getClinicSettingsByClinicId(String clinicId) async {
    try {
      final doc = await appWriteProvider.getClinicSettingsByClinicId(clinicId);
      if (doc != null) {
        final settings = ClinicSettings.fromMap(doc.data);
        settings.documentId = doc.$id;
        return settings;
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  Future<models.Document> updateClinicSettings(ClinicSettings clinicSettings) =>
      appWriteProvider.updateClinicSettings(
        clinicSettings.documentId!,
        clinicSettings.toMap(),
      );

  Future<void> deleteClinicSettings(String documentId) =>
      appWriteProvider.deleteClinicSettings(documentId);

  Future<List<models.File>> uploadClinicGalleryImages(
          List<PlatformFile> files) =>
      appWriteProvider.uploadClinicGalleryImages(files);

  Future<void> deleteClinicGalleryImages(List<String> fileIds) =>
      appWriteProvider.deleteClinicGalleryImages(fileIds);

  String getImageUrl(String fileId) => appWriteProvider.getImageUrl(fileId);

  Future<ClinicSettings> initializeClinicSettings(String clinicId) async {
    try {
      final defaultSettings = ClinicSettings(clinicId: clinicId);
      final doc = await createClinicSettings(defaultSettings);
      defaultSettings.documentId = doc.$id;
      return defaultSettings;
    } catch (e) {
      rethrow;
    }
  }

  Future<models.Document> createConversation(Conversation conversation) =>
      appWriteProvider.createConversation(conversation.toMap());

  Future<Conversation?> getOrCreateConversation(
      String userId, String clinicId) async {
    try {
      final doc =
          await appWriteProvider.getOrCreateConversation(userId, clinicId);
      if (doc != null) {
        var conversation = Conversation.fromMap(doc.data);
        conversation = conversation.copyWith(documentId: doc.$id);
        return conversation;
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  Future<List<Conversation>> getUserConversations(String userId) async {
    try {
      final docs = await appWriteProvider.getUserConversations(userId);
      return docs.map((doc) {
        final conversation = Conversation.fromMap(doc.data);
        return conversation.copyWith(documentId: doc.$id);
      }).toList();
    } catch (e) {
      return [];
    }
  }

  Future<List<Conversation>> getClinicConversations(String clinicId) async {
    try {
      final docs = await appWriteProvider.getClinicConversations(clinicId);
      return docs.map((doc) {
        final conversation = Conversation.fromMap(doc.data);
        return conversation.copyWith(documentId: doc.$id);
      }).toList();
    } catch (e) {
      return [];
    }
  }

  Future<models.Document> updateConversation(Conversation conversation) =>
      appWriteProvider.updateConversation(
        conversation.documentId!,
        conversation.toMap(),
      );

  Future<models.Document> createMessage(Message message) =>
      appWriteProvider.createMessage(message.toMap());

  Future<List<Message>> getConversationMessages(String conversationId,
      {int limit = 50, String? lastMessageId}) async {
    try {
      final docs = await appWriteProvider.getConversationMessages(
          conversationId,
          limit: limit,
          lastMessageId: lastMessageId);
      return docs.map((doc) {
        final message = Message.fromMap(doc.data);
        return message.copyWith(documentId: doc.$id);
      }).toList();
    } catch (e) {
      return [];
    }
  }

  Future<models.Document> updateMedicalRecord(
      String documentId, Map<String, dynamic> data) async {
    // Ensure vitals column is null
    if (data.containsKey('vitals') && data['vitals'] != null) {
      data['vitals'] = null;
    }

    // Log individual vitals

    return appWriteProvider.updateMedicalRecord(documentId, data);
  }

  Future<void> migrateMedicalRecordsVitals(String clinicId) async {
    try {
      final rawRecords =
          await appWriteProvider.getClinicMedicalRecords(clinicId);

      int migratedCount = 0;
      int alreadyMigratedCount = 0;
      int errorCount = 0;

      for (var recordData in rawRecords) {
        try {
          final recordId = recordData['\$id'];

          // Check if already migrated (has individual fields)
          final hasIndividualFields = recordData['temperature'] != null ||
              recordData['weight'] != null ||
              recordData['bloodPressure'] != null ||
              recordData['heartRate'] != null;

          if (hasIndividualFields) {
            alreadyMigratedCount++;
            continue;
          }

          // Check if has old vitals JSON
          final vitalsData = recordData['vitals'];
          if (vitalsData == null) {
            alreadyMigratedCount++;
            continue;
          }

          // Parse old vitals JSON
          Map<String, dynamic> vitals;
          if (vitalsData is String) {
            vitals = jsonDecode(vitalsData);
          } else if (vitalsData is Map) {
            vitals = Map<String, dynamic>.from(vitalsData);
          } else {
            continue;
          }

          // Update with individual fields
          final updateData = <String, dynamic>{
            'temperature': vitals['temperature'] != null
                ? double.tryParse(vitals['temperature'].toString())
                : null,
            'weight': vitals['weight'] != null
                ? double.tryParse(vitals['weight'].toString())
                : null,
            'bloodPressure': vitals['bloodPressure']?.toString(),
            'heartRate': vitals['heartRate'] != null
                ? int.tryParse(vitals['heartRate'].toString())
                : null,
            'vitals': null, // Clear the old column
          };

          await appWriteProvider.updateMedicalRecord(recordId, updateData);

          migratedCount++;
        } catch (e) {
          errorCount++;
        }
      }
    } catch (e) {
      rethrow;
    }
  }

  Future<models.Document> updateMessage(Message message) =>
      appWriteProvider.updateMessage(message.documentId!, message.toMap());

  Future<void> markMessagesAsRead(String conversationId, String receiverId) =>
      appWriteProvider.markMessagesAsRead(conversationId, receiverId);

  Future<Message> sendMessage({
    required String conversationId,
    required String senderId,
    required String messageText,
    String? attachment,
  }) async {
    try {
      // Prepare message data with all required fields (WITHOUT isStarterMessage)
      final messageMap = {
        'conversationId': conversationId,
        'senderId': senderId,
        'messageText': messageText,
        'messageType': 'text', // Default message type
        'attachment': attachment,
        'attachmentUrl': attachment,
        // REMOVED: isStarterMessage field
        'isRead': false,
        'isDeleted': false,
        'timestamp': DateTime.now().toIso8601String(),
        'sentAt': DateTime.now().toIso8601String(),
      };

      // The createMessage method will add senderType and receiverId automatically
      final messageDoc = await appWriteProvider.createMessage(messageMap);

      // Create Message object for return
      final createdMessage = Message(
        documentId: messageDoc.$id,
        conversationId: conversationId,
        senderId: senderId,
        messageText: messageText,
        // REMOVED: isStarterMessage field
        attachment: attachment,
        receiverId: messageDoc.data['receiverId'], // Get from created doc
        createdAt: DateTime.parse(messageDoc.data['timestamp']),
        updatedAt: DateTime.now(),
      );

      return createdMessage;
    } catch (e) {
      rethrow;
    }
  }

  /// Alternative method if you need to send with more context
  Future<Message> sendMessageAdvanced({
    required String conversationId,
    required String senderId,
    required String messageText,
    bool isStarterMessage = false,
    String? attachment,
    bool updateUnreadCount = true,
  }) async {
    try {
      final message = Message(
        conversationId: conversationId,
        senderId: senderId,
        messageText: messageText,
        isStarterMessage: isStarterMessage,
        attachment: attachment,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final messageDoc = await createMessage(message);
      final createdMessage = message.copyWith(documentId: messageDoc.$id);

      // Update conversation
      final updateData = {
        'lastMessageId': messageDoc.$id,
        'lastMessageText': messageText,
        'lastMessageTime': DateTime.now().toIso8601String(),
        'updatedAt': DateTime.now().toIso8601String(),
      };

      await appWriteProvider.updateConversation(conversationId, updateData);

      return createdMessage;
    } catch (e) {
      rethrow;
    }
  }

  /// Mark a single message as read
  Future<void> markMessageAsRead(String messageId) async {
    try {
      await appWriteProvider.updateMessage(messageId, {
        'isRead': true,
        'updatedAt': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      rethrow;
    }
  }

  Future<List<Conversation>> getClinicConversationsWithAccurateTime(
      String clinicId) async {
    try {
      final docs = await appWriteProvider.getClinicConversations(clinicId);

      return docs.map((doc) {
        final conversation = Conversation.fromMap(doc.data);
        final withDocId = conversation.copyWith(documentId: doc.$id);

        // Ensure lastMessageTime is set correctly
        if (withDocId.lastMessageTime == null &&
            doc.data['updatedAt'] != null) {
          return withDocId.copyWith(
            lastMessageTime: DateTime.parse(doc.data['updatedAt']),
          );
        }

        return withDocId;
      }).toList();
    } catch (e) {
      return [];
    }
  }

  Future<List<Conversation>> getUserConversationsWithAccurateTime(
      String userId) async {
    try {
      final docs = await appWriteProvider.getUserConversations(userId);

      return docs.map((doc) {
        final conversation = Conversation.fromMap(doc.data);
        final withDocId = conversation.copyWith(documentId: doc.$id);

        // Ensure lastMessageTime is set correctly
        if (withDocId.lastMessageTime == null &&
            doc.data['updatedAt'] != null) {
          return withDocId.copyWith(
            lastMessageTime: DateTime.parse(doc.data['updatedAt']),
          );
        }

        return withDocId;
      }).toList();
    } catch (e) {
      return [];
    }
  }

  Future<models.Document> createConversationStarter(
          ConversationStarter starter) =>
      appWriteProvider.createConversationStarter(starter.toMap());

  Future<List<ConversationStarter>> getClinicConversationStarters(
      String clinicId) async {
    try {
      final docs =
          await appWriteProvider.getClinicConversationStarters(clinicId);
      return docs.map((doc) {
        final starter = ConversationStarter.fromMap(doc.data);
        return starter.copyWith(documentId: doc.$id);
      }).toList();
    } catch (e) {
      return [];
    }
  }

  Future<models.Document> updateConversationStarter(
          ConversationStarter starter) =>
      appWriteProvider.updateConversationStarter(
        starter.documentId!,
        starter.toMap(),
      );

  Future<void> deleteConversationStarter(String documentId) =>
      appWriteProvider.deleteConversationStarter(documentId);

  Future<void> initializeDefaultConversationStarters(String clinicId) =>
      appWriteProvider.initializeDefaultConversationStarters(clinicId);

  Future<models.Document> createOrUpdateUserStatus(UserStatus status) =>
      appWriteProvider.createOrUpdateUserStatus(status.userId, status.toMap());

  Future<UserStatus?> getUserStatus(String userId) async {
    try {
      final doc = await appWriteProvider.getUserStatus(userId);
      if (doc != null) {
        final status = UserStatus.fromMap(doc.data);
        return status.copyWith(documentId: doc.$id);
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  Future<void> setUserOnline(String userId) =>
      appWriteProvider.setUserOnline(userId);

  Future<void> setUserOffline(String userId) =>
      appWriteProvider.setUserOffline(userId);

  Stream<RealtimeMessage> subscribeToMessages(String conversationId) =>
      appWriteProvider.subscribeToMessages(conversationId);

  Stream<RealtimeMessage> subscribeToConversations(String userId) =>
      appWriteProvider.subscribeToConversations(userId);

  Stream<RealtimeMessage> subscribeToUserStatus(String userId) =>
      appWriteProvider.subscribeToUserStatus(userId);

  void disposeMessageSubscriptions() =>
      appWriteProvider.disposeMessageSubscriptions();

  Future<List<Map<String, dynamic>>> getClinicsWithSettings() async {
    try {
      final clinics = await getAllClinics();
      final List<Map<String, dynamic>> clinicsWithSettings = [];

      for (final clinic in clinics) {
        final settings =
            await getClinicSettingsByClinicId(clinic.documentId ?? '');

        // CRITICAL: Pass dashboard picture from settings to clinic
        if (settings != null && settings.dashboardPic.isNotEmpty) {
          clinic.dashboardPic = settings.dashboardPic;
        } else {}

        clinicsWithSettings.add({
          'clinic': clinic,
          'settings': settings,
        });
      }

      return clinicsWithSettings;
    } catch (e) {
      return [];
    }
  }

  Stream<RealtimeMessage> subscribeToUserAppointments(String userId) {
    return appWriteProvider.subscribeToUserAppointments(userId);
  }

  Stream<RealtimeMessage> subscribeToClinicAppointments(String clinicId) {
    return appWriteProvider.subscribeToClinicAppointments(clinicId);
  }

  Future<List<String>> getOccupiedTimeSlots(String clinicId, DateTime date) {
    return appWriteProvider.getOccupiedTimeSlots(clinicId, date);
  }

  Future<Map<String, dynamic>> createStaffAccount({
    required String name,
    required String username,
    required String password,
    required String clinicId,
    required List<String> authorities,
    String? department,
    String? image,
    String? phone,
    String? email,
    String? createdBy,
    bool isDoctor = false, // NEW: Add isDoctor parameter
  }) {
    return appWriteProvider.createStaffAccount(
      name: name,
      username: username,
      password: password,
      clinicId: clinicId,
      authorities: authorities,
      department: department,
      image: image,
      phone: phone,
      email: email,
      createdBy: createdBy,
      isDoctor: isDoctor, // NEW: Pass isDoctor to provider
    );
  }

  Future<List<Staff>> getClinicStaff(String clinicId) async {
    try {
      final docs = await appWriteProvider.getClinicStaff(clinicId);
      return docs.map((doc) {
        final staff = Staff.fromMap(doc.data);
        staff.documentId = doc.$id;
        return staff;
      }).toList();
    } catch (e) {
      return [];
    }
  }

  Future<Staff?> getStaffByUserId(String userId) async {
    try {
      final doc = await appWriteProvider.getStaffByUserId(userId);
      if (doc != null) {
        final staff = Staff.fromMap(doc.data);
        staff.documentId = doc.$id;
        return staff;
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  Future<Staff?> getStaffByUsername(String username) async {
    try {
      final doc = await appWriteProvider.getStaffByUsername(username);
      if (doc != null) {
        final staff = Staff.fromMap(doc.data);
        staff.documentId = doc.$id;
        return staff;
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  Future<void> fixStaffUserId(String staffDocId, String correctUserId) {
    return appWriteProvider.fixStaffUserId(staffDocId, correctUserId);
  }

  Future<void> migrateExistingStaffRecords() {
    return appWriteProvider.migrateExistingStaffRecords();
  }

  Future<void> updateStaffAuthorities(
    String staffDocumentId,
    List<String> authorities,
  ) async {
    try {
      await appWriteProvider.updateStaffAuthorities(
          staffDocumentId, authorities);
    } catch (e) {
      rethrow;
    }
  }

  Future<void> updateStaffInfo({
    required String staffDocumentId,
    String? name,
    String? department,
    String? image,
    String? email,
    String? phone,
    bool? isDoctor, // NEW: Add isDoctor parameter
    List<String>? authorities,
  }) async {
    try {
      await appWriteProvider.updateStaffInfo(
        staffDocumentId: staffDocumentId,
        name: name,
        department: department,
        image: image,
        phone: phone,
        isDoctor: isDoctor, // NEW: Pass isDoctor to provider
        authorities: authorities,
      );
    } catch (e) {
      rethrow;
    }
  }

  Future<void> updateStaffDoctorStatus(
    String staffDocumentId,
    bool isDoctor,
  ) async {
    try {
      await appWriteProvider.databases!.updateDocument(
        // Added ! null check
        databaseId: AppwriteConstants.dbID,
        collectionId: AppwriteConstants.staffCollectionID,
        documentId: staffDocumentId,
        data: {
          'isDoctor': isDoctor,
          'updatedAt': DateTime.now().toIso8601String(),
        },
      );
    } catch (e) {
      rethrow;
    }
  }

  Future<List<Staff>> getClinicDoctors(String clinicId) async {
    try {
      final docs = await appWriteProvider.getClinicDoctors(clinicId);
      return docs.map((doc) {
        final staff = Staff.fromMap(doc.data);
        staff.documentId = doc.$id;
        return staff;
      }).toList();
    } catch (e) {
      return [];
    }
  }

  Future<List<Staff>> getClinicNonDoctorStaff(String clinicId) async {
    try {
      final docs = await appWriteProvider.getClinicNonDoctorStaff(clinicId);
      return docs.map((doc) {
        final staff = Staff.fromMap(doc.data);
        staff.documentId = doc.$id;
        return staff;
      }).toList();
    } catch (e) {
      return [];
    }
  }

  Future<bool> isStaffDoctor(String staffDocumentId) async {
    try {
      return await appWriteProvider.isStaffDoctor(staffDocumentId);
    } catch (e) {
      return false;
    }
  }

  Future<Map<String, int>> getClinicStaffStatsWithDoctors(String clinicId) {
    return appWriteProvider.getClinicStaffStatsWithDoctors(clinicId);
  }

  Future<void> deactivateStaffAccount(String staffDocumentId, String userId) {
    return appWriteProvider.deactivateStaffAccount(staffDocumentId, userId);
  }

  Future<void> deleteStaffAccountPermanently(String staffDocumentId) {
    return appWriteProvider.deleteStaffAccount(staffDocumentId);
  }

  Future<Map<String, dynamic>> staffLogin(String username, String password) {
    return appWriteProvider.staffLogin(username, password);
  }

  Future<bool> checkStaffAuthority(String userId, String authority) {
    return appWriteProvider.checkStaffAuthority(userId, authority);
  }

  Future<Map<String, int>> getClinicStaffStats(String clinicId) {
    return appWriteProvider.getClinicStaffStats(clinicId);
  }

  Future<Map<String, dynamic>> deleteClinicCompletely(String clinicId) {
    return appWriteProvider.deleteClinicCompletely(clinicId);
  }

  Future<Map<String, dynamic>?> getClinicWithSettings(String clinicId) {
    return appWriteProvider.getClinicWithSettings(clinicId);
  }

  Stream<RealtimeMessage> subscribeToClinicChanges() {
    return appWriteProvider.subscribeToClinicChanges();
  }

  Stream<RealtimeMessage> subscribeToClinicSettingsChanges() {
    return appWriteProvider.subscribeToClinicSettingsChanges();
  }

  Future<Document> createIdVerification(IdVerification idVerification) {
    return appWriteProvider.createIdVerification(idVerification.toMap());
  }

  Future<IdVerification?> getIdVerificationByUserId(String userId) async {
    try {
      final doc = await appWriteProvider.getIdVerificationByUserId(userId);
      if (doc != null) {
        final verification = IdVerification.fromMap(doc.data);
        verification.documentId = doc.$id;
        return verification;
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  Future<IdVerification?> getIdVerificationBySubmissionId(
      String submissionId) async {
    try {
      final doc =
          await appWriteProvider.getIdVerificationBySubmissionId(submissionId);
      if (doc != null) {
        final verification = IdVerification.fromMap(doc.data);
        verification.documentId = doc.$id;
        return verification;
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  Future<Document> updateIdVerification(IdVerification idVerification) {
    return appWriteProvider.updateIdVerification(
      idVerification.documentId!,
      idVerification.toMap(),
    );
  }

  Future<Map<String, dynamic>> processArgosWebhook(
    Map<String, dynamic> webhookData,
  ) {
    return appWriteProvider.processArgosWebhook(webhookData);
  }

  Future<bool> isUserIdVerified(String userId) {
    return appWriteProvider.isUserIdVerified(userId);
  }

  Future<Map<String, dynamic>> getUserVerificationStatus(String userId) {
    return appWriteProvider.getUserVerificationStatus(userId);
  }

  Stream<RealtimeMessage> subscribeToIdVerification(String userId) {
    return appWriteProvider.subscribeToIdVerification(userId);
  }

  Future<void> cleanupStuckVerifications(String userId) {
    return appWriteProvider.cleanupStuckVerifications(userId);
  }

  Future<RatingAndReview> createRatingAndReview(RatingAndReview review) async {
    try {
      final doc = await appWriteProvider.createRatingAndReview(review.toMap());
      return review.copyWith(documentId: doc.$id);
    } catch (e) {
      rethrow;
    }
  }

  Future<bool> hasUserReviewedAppointment(String appointmentId) {
    return appWriteProvider.hasUserReviewedAppointment(appointmentId);
  }

  Future<List<RatingAndReview>> getClinicReviews(
    String clinicId, {
    int limit = 50,
    String? lastDocumentId,
  }) async {
    try {
      final docs = await appWriteProvider.getClinicReviews(
        clinicId,
        limit: limit,
        lastDocumentId: lastDocumentId,
      );
      return docs.map((doc) {
        final review = RatingAndReview.fromMap(doc.data);
        return review.copyWith(documentId: doc.$id);
      }).toList();
    } catch (e) {
      return [];
    }
  }

  Future<List<RatingAndReview>> getUserReviews(String userId) async {
    try {
      final docs = await appWriteProvider.getUserReviews(userId);
      return docs.map((doc) {
        final review = RatingAndReview.fromMap(doc.data);
        return review.copyWith(documentId: doc.$id);
      }).toList();
    } catch (e) {
      return [];
    }
  }

  Future<RatingAndReview?> getReviewByAppointmentId(
      String appointmentId) async {
    try {
      final doc =
          await appWriteProvider.getReviewByAppointmentId(appointmentId);
      if (doc != null) {
        final review = RatingAndReview.fromMap(doc.data);
        return review.copyWith(documentId: doc.$id);
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  Future<RatingAndReview> updateRatingAndReview(RatingAndReview review) async {
    try {
      if (review.documentId == null) {
        throw Exception('Cannot update review without documentId');
      }
      final doc = await appWriteProvider.updateRatingAndReview(
        review.documentId!,
        review.toMap(),
      );
      return RatingAndReview.fromMap(doc.data).copyWith(documentId: doc.$id);
    } catch (e) {
      rethrow;
    }
  }

  Future<void> deleteRatingAndReview(
      String documentId, List<String> imageIds) async {
    try {
      if (imageIds.isNotEmpty) {
        await appWriteProvider.deleteReviewImages(imageIds);
      }
      await appWriteProvider.deleteRatingAndReview(documentId);
    } catch (e) {
      rethrow;
    }
  }

  Future<RatingAndReview> addClinicResponse(
    String documentId,
    String response,
  ) async {
    try {
      final doc =
          await appWriteProvider.addClinicResponse(documentId, response);
      return RatingAndReview.fromMap(doc.data).copyWith(documentId: doc.$id);
    } catch (e) {
      rethrow;
    }
  }

  Future<ClinicRatingStats> getClinicRatingStats(String clinicId) async {
    try {
      final stats = await appWriteProvider.getClinicRatingStats(clinicId);
      return ClinicRatingStats(
        averageRating: stats['averageRating'],
        totalReviews: stats['totalReviews'],
        ratingDistribution: Map<int, int>.from(stats['ratingDistribution']),
        reviewsWithText: stats['reviewsWithText'],
        reviewsWithImages: stats['reviewsWithImages'],
      );
    } catch (e) {
      return ClinicRatingStats(
        averageRating: 0.0,
        totalReviews: 0,
        ratingDistribution: {1: 0, 2: 0, 3: 0, 4: 0, 5: 0},
        reviewsWithText: 0,
        reviewsWithImages: 0,
      );
    }
  }

  Future<List<models.File>> uploadReviewImages(List<PlatformFile> files) {
    return appWriteProvider.uploadReviewImages(files);
  }

  Future<void> deleteReviewImages(List<String> fileIds) {
    return appWriteProvider.deleteReviewImages(fileIds);
  }

  Stream<RealtimeMessage> subscribeToClinicReviews(String clinicId) {
    return appWriteProvider.subscribeToClinicReviews(clinicId);
  }

  Future<Vaccination> createVaccination(Vaccination vaccination) async {
    try {
      final doc = await appWriteProvider.createVaccination(vaccination.toMap());
      return vaccination.copyWith(documentId: doc.$id);
    } catch (e) {
      rethrow;
    }
  }

  Future<List<Vaccination>> getPetVaccinations(String petId) async {
    try {
      final rawVaccinations = await appWriteProvider.getPetVaccinations(petId);

      final vaccinations = rawVaccinations.map((data) {
        return Vaccination.fromMap(data);
      }).toList();

      return vaccinations;
    } catch (e) {
      return [];
    }
  }

  Future<List<Vaccination>> getClinicVaccinations(String clinicId) async {
    try {
      final rawVaccinations =
          await appWriteProvider.getClinicVaccinations(clinicId);
      return rawVaccinations.map((data) => Vaccination.fromMap(data)).toList();
    } catch (e) {
      return [];
    }
  }

  Future<Vaccination> updateVaccination(Vaccination vaccination) async {
    try {
      if (vaccination.documentId == null) {
        throw Exception('Cannot update vaccination without documentId');
      }
      final doc = await appWriteProvider.updateVaccination(
        vaccination.documentId!,
        vaccination.toMap(),
      );
      return Vaccination.fromMap(doc.data).copyWith(documentId: doc.$id);
    } catch (e) {
      rethrow;
    }
  }

  Future<void> deleteVaccination(String documentId) async {
    try {
      await appWriteProvider.deleteVaccination(documentId);
    } catch (e) {
      rethrow;
    }
  }

  Future<FeedbackAndReport> createFeedbackAndReport(
      FeedbackAndReport feedback) async {
    try {
      final doc =
          await appWriteProvider.createFeedbackAndReport(feedback.toMap());
      return feedback.copyWith(documentId: doc.$id);
    } catch (e) {
      rethrow;
    }
  }

  Future<List<FeedbackAndReport>> getAllFeedback({
    FeedbackStatus? status,
    Priority? priority,
    int limit = 100,
  }) async {
    try {
      final docs = await appWriteProvider.getAllFeedback(
        status: status,
        priority: priority,
        limit: limit,
      );
      return docs.map((doc) {
        final feedback = FeedbackAndReport.fromMap(doc.data);
        return feedback.copyWith(documentId: doc.$id);
      }).toList();
    } catch (e) {
      return [];
    }
  }

  Future<List<FeedbackAndReport>> getUserFeedback(String userId) async {
    try {
      final docs = await appWriteProvider.getUserFeedback(userId);
      return docs.map((doc) {
        final feedback = FeedbackAndReport.fromMap(doc.data);
        return feedback.copyWith(documentId: doc.$id);
      }).toList();
    } catch (e) {
      return [];
    }
  }

  /// Get all feedback reported by admins
  Future<List<FeedbackAndReport>> getAdminFeedback({
    int limit = 100,
    String? clinicId,
  }) async {
    try {
      final docs = await appWriteProvider.getAllFeedback(
        limit: limit,
      );

      return docs.where((doc) {
        final feedback = FeedbackAndReport.fromMap(doc.data);
        // Filter for admin feedback
        if (feedback.reportedBy != 'admin') return false;
        // If clinicId is specified, filter by that clinic
        if (clinicId != null && feedback.clinicId != clinicId) return false;
        return true;
      }).map((doc) {
        final feedback = FeedbackAndReport.fromMap(doc.data);
        return feedback.copyWith(documentId: doc.$id);
      }).toList();
    } catch (e) {
      return [];
    }
  }

  /// Get all feedback reported by staff
  Future<List<FeedbackAndReport>> getStaffFeedback({
    int limit = 100,
    String? clinicId,
  }) async {
    try {
      final docs = await appWriteProvider.getAllFeedback(
        limit: limit,
      );

      return docs.where((doc) {
        final feedback = FeedbackAndReport.fromMap(doc.data);
        // Filter for staff feedback
        if (feedback.reportedBy != 'staff') return false;
        // If clinicId is specified, filter by that clinic
        if (clinicId != null && feedback.clinicId != clinicId) return false;
        return true;
      }).map((doc) {
        final feedback = FeedbackAndReport.fromMap(doc.data);
        return feedback.copyWith(documentId: doc.$id);
      }).toList();
    } catch (e) {
      return [];
    }
  }

  /// Get feedback for a specific admin
  Future<List<FeedbackAndReport>> getFeedbackByAdminId(String adminId) async {
    try {
      final docs = await appWriteProvider.getAllFeedback(limit: 1000);

      return docs.where((doc) {
        final feedback = FeedbackAndReport.fromMap(doc.data);
        return feedback.adminId == adminId;
      }).map((doc) {
        final feedback = FeedbackAndReport.fromMap(doc.data);
        return feedback.copyWith(documentId: doc.$id);
      }).toList();
    } catch (e) {
      return [];
    }
  }

  /// Get feedback for a specific staff member
  Future<List<FeedbackAndReport>> getFeedbackByStaffId(String staffId) async {
    try {
      final docs = await appWriteProvider.getAllFeedback(limit: 1000);

      return docs.where((doc) {
        final feedback = FeedbackAndReport.fromMap(doc.data);
        return feedback.staffId == staffId;
      }).map((doc) {
        final feedback = FeedbackAndReport.fromMap(doc.data);
        return feedback.copyWith(documentId: doc.$id);
      }).toList();
    } catch (e) {
      return [];
    }
  }

  /// Get all feedback for a specific clinic (from both admin and staff)
  Future<List<FeedbackAndReport>> getClinicFeedback(String clinicId) async {
    try {
      final docs = await appWriteProvider.getAllFeedback(limit: 1000);

      return docs.where((doc) {
        final feedback = FeedbackAndReport.fromMap(doc.data);
        return feedback.clinicId == clinicId;
      }).map((doc) {
        final feedback = FeedbackAndReport.fromMap(doc.data);
        return feedback.copyWith(documentId: doc.$id);
      }).toList();
    } catch (e) {
      return [];
    }
  }

  /// Get feedback by report type (admin, staff, user)
  Future<List<FeedbackAndReport>> getFeedbackByReportedBy(
      String reportedBy) async {
    try {
      final docs = await appWriteProvider.getAllFeedback(limit: 1000);

      return docs.where((doc) {
        final feedback = FeedbackAndReport.fromMap(doc.data);
        return feedback.reportedBy == reportedBy;
      }).map((doc) {
        final feedback = FeedbackAndReport.fromMap(doc.data);
        return feedback.copyWith(documentId: doc.$id);
      }).toList();
    } catch (e) {
      return [];
    }
  }

  Future<void> updateFeedbackStatus(String documentId, FeedbackStatus status) {
    return appWriteProvider.updateFeedbackStatus(documentId, status);
  }

  Future<void> updateFeedbackPriority(String documentId, Priority priority) {
    return appWriteProvider.updateFeedbackPriority(documentId, priority);
  }

  /// Toggle pin status of feedback
  Future<Document> toggleFeedbackPin(
    String documentId,
    bool isPinned,
    String pinnedBy,
  ) {
    return appWriteProvider.toggleFeedbackPin(documentId, isPinned, pinnedBy);
  }

  Future<void> addFeedbackReply(
    String documentId,
    String reply,
    String adminName,
  ) {
    return appWriteProvider.addFeedbackReply(documentId, reply, adminName);
  }

  Future<void> archiveFeedback(String documentId, String archivedBy) async {
    try {
      await appWriteProvider.archiveFeedback(documentId, archivedBy);
    } catch (e) {
      rethrow;
    }
  }

  Future<void> deleteFeedback(String documentId, List<String> attachmentIds) {
    return appWriteProvider.deleteFeedback(documentId, attachmentIds);
  }

  Future<List<models.File>> uploadFeedbackAttachments(
      List<PlatformFile> files) {
    return appWriteProvider.uploadFeedbackAttachments(files);
  }

  Future<void> migrateFeedbackArchiveField() {
    return appWriteProvider.migrateFeedbackArchiveField();
  }

  Future<void> deleteFeedbackAttachments(List<String> fileIds) {
    return appWriteProvider.deleteFeedbackAttachments(fileIds);
  }

  String getFeedbackAttachmentUrl(String fileId) {
    return appWriteProvider.getFeedbackAttachmentUrl(fileId);
  }

  Stream<RealtimeMessage> subscribeToFeedbackChanges() {
    return appWriteProvider.subscribeToFeedbackChanges();
  }

  Future<Map<String, int>> getFeedbackStatistics() {
    return appWriteProvider.getFeedbackStatistics();
  }

  // ============= ARCHIVE USER METHODS (REPOSITORY LAYER) =============

  /// Archive user (soft delete)
  Future<Map<String, dynamic>> archiveUser({
    required String userId,
    required String userDocumentId,
    required String archivedBy,
    String archiveReason = 'No reason provided',
  }) {
    return appWriteProvider.archiveUser(
      userId: userId,
      userDocumentId: userDocumentId,
      archivedBy: archivedBy,
      archiveReason: archiveReason,
    );
  }

  /// Get archived user by userId
  Future<ArchivedUser?> getArchivedUserByUserId(String userId) async {
    try {
      final doc = await appWriteProvider.getArchivedUserByUserId(userId);
      if (doc != null) {
        final archivedUser = ArchivedUser.fromMap(doc.data);
        return archivedUser.copyWith(documentId: doc.$id);
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  /// Get all archived users
  Future<List<ArchivedUser>> getAllArchivedUsers({
    bool includePermanentlyDeleted = false,
    int limit = 100,
  }) async {
    try {
      final docs = await appWriteProvider.getAllArchivedUsers(
        includePermanentlyDeleted: includePermanentlyDeleted,
        limit: limit,
      );

      return docs.map((doc) {
        final archivedUser = ArchivedUser.fromMap(doc.data);
        return archivedUser.copyWith(documentId: doc.$id);
      }).toList();
    } catch (e) {
      return [];
    }
  }

  /// Get users due for permanent deletion
  Future<List<ArchivedUser>> getUsersDueForDeletion() async {
    try {
      final docs = await appWriteProvider.getUsersDueForDeletion();

      return docs.map((doc) {
        final archivedUser = ArchivedUser.fromMap(doc.data);
        return archivedUser.copyWith(documentId: doc.$id);
      }).toList();
    } catch (e) {
      return [];
    }
  }

  /// Permanently delete user
  Future<Map<String, dynamic>> permanentlyDeleteUser(String userId) {
    return appWriteProvider.permanentlyDeleteUser(userId);
  }

  /// Recover archived user
  Future<Map<String, dynamic>> recoverArchivedUser({
    required String userId,
    required String recoveredBy,
  }) {
    return appWriteProvider.recoverArchivedUser(
      userId: userId,
      recoveredBy: recoveredBy,
    );
  }

  /// Process scheduled deletions (background job)
  Future<Map<String, dynamic>> processScheduledDeletions() {
    return appWriteProvider.processScheduledDeletions();
  }

  /// Subscribe to archived users changes
  Stream<RealtimeMessage> subscribeToArchivedUsers() {
    return appWriteProvider.subscribeToArchivedUsers();
  }

  /// Get archive statistics
  Future<Map<String, int>> getArchiveStatistics() {
    return appWriteProvider.getArchiveStatistics();
  }

// ============= ARCHIVE CLINIC METHODS (REPOSITORY LAYER) =============

  /// Archive clinic (soft delete)
  Future<Map<String, dynamic>> archiveClinic({
    required String clinicId,
    required String clinicDocumentId,
    required String archivedBy,
    String archiveReason = 'No reason provided',
  }) {
    return appWriteProvider.archiveClinic(
      clinicId: clinicId,
      clinicDocumentId: clinicDocumentId,
      archivedBy: archivedBy,
      archiveReason: archiveReason,
    );
  }

  /// Get archived clinic by clinicId
  Future<ArchivedClinic?> getArchivedClinicByAdminId(String adminId) async {
    try {
      final doc = await appWriteProvider.getArchivedClinicByAdminId(adminId);
      if (doc != null) {
        final archivedClinic = ArchivedClinic.fromMap(doc.data);
        return archivedClinic.copyWith(documentId: doc.$id);
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  /// Get all archived clinics
  Future<List<ArchivedClinic>> getAllArchivedClinics({
    bool includePermanentlyDeleted = false,
    int limit = 100,
  }) async {
    try {
      final docs = await appWriteProvider.getAllArchivedClinics(
        includePermanentlyDeleted: includePermanentlyDeleted,
        limit: limit,
      );

      return docs.map((doc) {
        final archivedClinic = ArchivedClinic.fromMap(doc.data);
        return archivedClinic.copyWith(documentId: doc.$id);
      }).toList();
    } catch (e) {
      return [];
    }
  }

  /// Get clinics due for permanent deletion
  Future<List<ArchivedClinic>> getClinicsDueForDeletion() async {
    try {
      final docs = await appWriteProvider.getClinicsDueForDeletion();

      return docs.map((doc) {
        final archivedClinic = ArchivedClinic.fromMap(doc.data);
        return archivedClinic.copyWith(documentId: doc.$id);
      }).toList();
    } catch (e) {
      return [];
    }
  }

  /// Permanently delete clinic
  Future<Map<String, dynamic>> permanentlyDeleteClinic(String clinicId) {
    return appWriteProvider.permanentlyDeleteClinic(clinicId);
  }

  /// Recover archived clinic
  Future<Map<String, dynamic>> recoverArchivedClinic({
    required String adminId,
    required String recoveredBy,
  }) {
    return appWriteProvider.recoverArchivedClinic(
      adminId: adminId,
      recoveredBy: recoveredBy,
    );
  }

  /// Process scheduled clinic deletions (background job)
  Future<Map<String, dynamic>> processScheduledClinicDeletions() {
    return appWriteProvider.processScheduledClinicDeletions();
  }

  /// Subscribe to archived clinics changes
  Stream<RealtimeMessage> subscribeToArchivedClinics() {
    return appWriteProvider.subscribeToArchivedClinics();
  }

  /// Get clinic archive statistics
  Future<Map<String, int>> getClinicArchiveStatistics() {
    return appWriteProvider.getClinicArchiveStatistics();
  }

  // ============= CLINIC PROFILE PICTURE REPOSITORY METHODS =============

  /// Upload clinic profile picture
  Future<models.File> uploadClinicProfilePicture(dynamic image) {
    return appWriteProvider.uploadClinicProfilePicture(image);
  }

  /// Delete clinic profile picture
  Future<void> deleteClinicProfilePicture(String fileId) {
    return appWriteProvider.deleteClinicProfilePicture(fileId);
  }

  /// Get clinic profile picture URL
  String getClinicProfilePictureUrl(String profilePictureId) {
    return appWriteProvider.getClinicProfilePictureUrl(profilePictureId);
  }

  /// Update clinic profile picture (with automatic old picture deletion)
  Future<String> updateClinicProfilePicture(
    String clinicId,
    String? oldProfilePictureId,
    dynamic newImage,
  ) {
    return appWriteProvider.updateClinicProfilePicture(
      clinicId,
      oldProfilePictureId,
      newImage,
    );
  }

  /// Get clinic with profile picture URL
  Future<Map<String, dynamic>?> getClinicWithProfilePicture(String clinicId) {
    return appWriteProvider.getClinicWithProfilePicture(clinicId);
  }

  Future<models.File> uploadUserProfilePicture(dynamic image) {
    return appWriteProvider.uploadUserProfilePicture(image);
  }

  /// Delete user profile picture
  Future<void> deleteUserProfilePicture(String fileId) {
    return appWriteProvider.deleteUserProfilePicture(fileId);
  }

  /// Get user profile picture URL
  String getUserProfilePictureUrl(String profilePictureId) {
    return appWriteProvider.getUserProfilePictureUrl(profilePictureId);
  }

  /// Update user profile picture (with automatic old picture deletion)
  Future<String> updateUserProfilePicture(
    String userDocumentId,
    String? oldProfilePictureId,
    dynamic newImage,
  ) {
    return appWriteProvider.updateUserProfilePicture(
      userDocumentId,
      oldProfilePictureId,
      newImage,
    );
  }

  /// Get user with profile picture URL
  Future<Map<String, dynamic>?> getUserWithProfilePicture(String userId) {
    return appWriteProvider.getUserWithProfilePicture(userId);
  }
  // ============= ADD TO auth.repository.dart =============

  Future<Document> createFeedbackDeletionRequest({
    required String reviewId,
    required String clinicId,
    required String userId,
    required String appointmentId,
    required String requestedBy,
    required String reason,
    String? additionalDetails,
    List<String>? attachmentIds,
  }) async {
    try {
      final data = {
        'reviewId': reviewId,
        'clinicId': clinicId,
        'userId': userId,
        'appointmentId': appointmentId,
        'requestedBy': requestedBy,
        'reason': reason,
        'additionalDetails': additionalDetails ?? '',
        'attachments': attachmentIds != null
            ? jsonEncode(attachmentIds)
            : '', // Convert to JSON string
        'status': 'pending',
        'requestedAt': DateTime.now().toIso8601String(),
        'updatedAt': DateTime.now().toIso8601String(),
        'reviewedBy': '',
        'reviewedAt': '',
        'reviewNotes': '',
      };

      final doc = await appWriteProvider.createFeedbackDeletionRequest(data);
      return doc;
    } catch (e) {
      rethrow;
    }
  }

  Future<List<models.File>> uploadFeedbackDeletionAttachments(
      List<PlatformFile> files) {
    return appWriteProvider.uploadFeedbackDeletionAttachments(files);
  }

  Future<void> deleteFeedbackDeletionAttachments(List<String> fileIds) {
    return appWriteProvider.deleteFeedbackDeletionAttachments(fileIds);
  }

  Future<Document?> getFeedbackDeletionRequestById(String requestId) {
    return appWriteProvider.getFeedbackDeletionRequestById(requestId);
  }

  Future<List<FeedbackDeletionRequest>> getClinicDeletionRequests(
    String clinicId, {
    String? status,
  }) async {
    try {
      final docs = await appWriteProvider.getClinicDeletionRequests(
        clinicId,
        status: status,
      );

      final requests = docs.map((doc) {
        final request = FeedbackDeletionRequest.fromMap(doc.data);
        return request.copyWith(documentId: doc.$id);
      }).toList();

      return requests;
    } catch (e, stackTrace) {
      return [];
    }
  }

  Future<List<Document>> getPendingDeletionRequests(String clinicId) {
    return appWriteProvider.getPendingDeletionRequests(clinicId);
  }

  Future<Map<String, dynamic>> approveDeletionRequest(
    String requestId,
    String reviewId,
    String reviewedBy,
    String? reviewNotes,
  ) {
    return appWriteProvider.approveDeletionRequest(
      requestId,
      reviewId,
      reviewedBy,
      reviewNotes,
    );
  }

  Future<Map<String, dynamic>> rejectDeletionRequest(
    String requestId,
    String reviewedBy,
    String? reviewNotes,
  ) {
    return appWriteProvider.rejectDeletionRequest(
      requestId,
      reviewedBy,
      reviewNotes,
    );
  }

  Future<Map<String, int>> getDeletionRequestStats(String clinicId) {
    return appWriteProvider.getDeletionRequestStats(clinicId);
  }

  /// Send conversation starter response (from clinic/admin)
  Future<Document> sendConversationStarterResponse({
    required String conversationId,
    required String clinicId,
    required String responseText,
  }) {
    return appWriteProvider.sendConversationStarterResponse(
      conversationId: conversationId,
      clinicId: clinicId,
      responseText: responseText,
    );
  }

  // ============= IN-APP NOTIFICATION REPOSITORY METHODS =============

  /// Create a notification
  Future<Document> createNotification(AppNotification notification) {
    return appWriteProvider.createNotification(notification.toMap());
  }

  /// Get all notifications for a user
  Future<List<Document>> getUserNotifications(
    String userId, {
    int limit = 50,
    bool unreadOnly = false,
  }) {
    return appWriteProvider.getUserNotifications(
      userId,
      limit: limit,
      unreadOnly: unreadOnly,
    );
  }

  /// Get unread notification count
  Future<int> getUnreadNotificationCount(String userId) {
    return appWriteProvider.getUnreadNotificationCount(userId);
  }

  /// Mark notification as read
  Future<Document> markNotificationAsRead(String notificationId) {
    return appWriteProvider.markNotificationAsRead(notificationId);
  }

  /// Mark all notifications as read for a user
  Future<void> markAllNotificationsAsRead(String userId) {
    return appWriteProvider.markAllNotificationsAsRead(userId);
  }

  /// Delete a notification
  Future<void> deleteNotification(String notificationId) {
    return appWriteProvider.deleteNotification(notificationId);
  }

  /// Delete all notifications for a user
  Future<void> deleteAllNotifications(String userId) {
    return appWriteProvider.deleteAllNotifications(userId);
  }

  /// Subscribe to user notifications (real-time)
  Stream<RealtimeMessage> subscribeToUserNotifications(String userId) {
    return appWriteProvider.subscribeToUserNotifications(userId);
  }

  /// Get notification statistics
  Future<Map<String, int>> getNotificationStats(String userId) {
    return appWriteProvider.getNotificationStats(userId);
  }

  /// Create appointment notification
  Future<void> createAppointmentNotification({
    required String recipientId,
    required String title,
    required String message,
    required String type,
    required String appointmentId,
    String? clinicId,
    String? petId,
    String? senderId,
    Map<String, dynamic>? metadata,
  }) {
    return appWriteProvider.createAppointmentNotification(
      recipientId: recipientId,
      title: title,
      message: message,
      type: type,
      appointmentId: appointmentId,
      clinicId: clinicId,
      petId: petId,
      senderId: senderId,
      metadata: metadata,
    );
  }

  /// Create deletion request notification
  Future<void> createDeletionRequestNotification({
    required String clinicAdminId,
    required String title,
    required String message,
    required String status,
    required String requestId,
    String? clinicId,
    String? reviewId,
    Map<String, dynamic>? metadata,
  }) {
    return appWriteProvider.createDeletionRequestNotification(
      clinicAdminId: clinicAdminId,
      title: title,
      message: message,
      status: status,
      requestId: requestId,
      clinicId: clinicId,
      reviewId: reviewId,
      metadata: metadata,
    );
  }

  // Add this method to the AuthRepository class
  Future<void> migrateConversationStarters() {
    return appWriteProvider.migrateConversationStarters();
  }

  Future<List<Map<String, dynamic>>> getPetMedicalAppointmentsAllClinics(
    String petId,
  ) async {
    // ... keep existing implementation unchanged ...
    try {
      final petDoc = await getPetById(petId);
      String? petName;

      if (petDoc != null) {
        petName = petDoc.data['name'] as String?;
      } else {}

      final rawAppointments =
          await appWriteProvider.getPetMedicalAppointmentsAllClinics(petId);

      List<Map<String, dynamic>> enrichedAppointments = [];

      for (var appointmentData in rawAppointments) {
        try {
          final clinicId = appointmentData['clinicId'];
          final clinicDoc = await appWriteProvider.getClinicById(clinicId);

          if (clinicDoc != null) {
            appointmentData['clinicName'] =
                clinicDoc.data['clinicName'] ?? 'Unknown Clinic';
            appointmentData['clinicAddress'] =
                clinicDoc.data['address'] ?? 'N/A';
            appointmentData['clinicContact'] =
                clinicDoc.data['contact'] ?? 'N/A';
          } else {
            appointmentData['clinicName'] = 'Unknown Clinic';
            appointmentData['clinicAddress'] = 'N/A';
            appointmentData['clinicContact'] = 'N/A';
          }

          enrichedAppointments.add(appointmentData);
        } catch (e) {
          appointmentData['clinicName'] = 'Unknown Clinic';
          appointmentData['clinicAddress'] = 'N/A';
          appointmentData['clinicContact'] = 'N/A';
          enrichedAppointments.add(appointmentData);
        }
      }

      return enrichedAppointments;
    } catch (e) {
      return [];
    }
  }

  Future<models.Document?> getPetByPetId(String petId) async {
    try {
      final result = await appWriteProvider.databases!.listDocuments(
        databaseId: AppwriteConstants.dbID,
        collectionId: AppwriteConstants.petsCollectionID,
        queries: [Query.equal("petId", petId)],
      );

      if (result.documents.isNotEmpty) {
        return result.documents.first;
      }

      return null;
    } catch (e) {
      return null;
    }
  }

  Future<void> debugPetVaccinations(String petId) async {
    return appWriteProvider.debugPetVaccinations(petId);
  }

  /// Debug method to check medical records and appointments relationship
  Future<void> debugMedicalRecordsForPet(String petId) async {
    try {
      // Get medical records
      final records = await getPetMedicalRecords(petId);

      for (var record in records) {}

      // Get medical appointments
      final appointments = await getPetMedicalAppointmentsAllClinics(petId);

      for (var appointment in appointments) {
        // Check if has matching medical record
        final hasRecord =
            records.any((r) => r.appointmentId == appointment['\$id']);
      }
    } catch (e) {}
  }

  Future<bool> sendAutomatedAppointmentMessage({
    required String userId,
    required String clinicId,
    required String messageText,
  }) async {
    try {
      // Step 1: Get or create conversation
      final conversation = await getOrCreateConversation(userId, clinicId);

      if (conversation == null) {
        return false;
      }

      // Step 2: Send the message
      final messageData = {
        'conversationId': conversation.documentId!,
        'senderId': clinicId, // Use clinic ID as sender
        'senderType': 'clinic',
        'receiverId': userId,
        'messageText': messageText,
        'messageType': 'text',
        'timestamp': DateTime.now().toIso8601String(),
        'isRead': false,
        'isDeleted': false,
        'sentAt': DateTime.now().toIso8601String(),
      };

      await appWriteProvider.createMessage(messageData);

      return true;
    } catch (e) {
      return false;
    }
  }

  Future<bool> isUserVerifiedByIdCollection(String userId) async {
    try {
      final verificationDoc = await appWriteProvider.databases!.listDocuments(
        databaseId: AppwriteConstants.dbID,
        collectionId: AppwriteConstants.idVerificationCollectionID,
        queries: [
          Query.equal('userId', userId),
          Query.equal('status', 'approved'),
          Query.limit(1),
        ],
      );

      final isVerified = verificationDoc.documents.isNotEmpty;

      return isVerified;
    } catch (e) {
      return false;
    }
  }

  /// Get all verified user IDs from ID Verification collection
  Future<Set<String>> getAllVerifiedUserIds() async {
    try {
      final verificationDocs = await appWriteProvider.databases!.listDocuments(
        databaseId: AppwriteConstants.dbID,
        collectionId: AppwriteConstants.idVerificationCollectionID,
        queries: [
          Query.equal('status', 'approved'),
          Query.limit(1000),
        ],
      );

      final verifiedIds = <String>{};
      for (var doc in verificationDocs.documents) {
        final userId = doc.data['userId'] as String?;
        if (userId != null) {
          verifiedIds.add(userId);
        }
      }

      return verifiedIds;
    } catch (e) {
      return {};
    }
  }

  Future<bool> hasPendingDeletionRequest(String reviewId) async {
    try {
      final requests = await appWriteProvider.databases!.listDocuments(
        databaseId: AppwriteConstants.dbID,
        collectionId: AppwriteConstants.feedbackDeletionRequestCollectionID,
        queries: [
          Query.equal('reviewId', reviewId),
          Query.equal('status', 'pending'),
          Query.limit(1),
        ],
      );

      return requests.documents.isNotEmpty;
    } catch (e) {
      return false;
    }
  }

  Future<Staff?> getStaffByDocumentId(String documentId) async {
    try {
      final doc = await appWriteProvider.databases!.getDocument(
        // Added ! null check
        databaseId: AppwriteConstants.dbID,
        collectionId: AppwriteConstants.staffCollectionID,
        documentId: documentId,
      );

      final staff = Staff.fromMap(doc.data);
      staff.documentId = doc.$id;
      return staff;
    } catch (e) {
      return null;
    }
  }

  String getStaffProfilePictureUrl(String imageId) {
    if (imageId.isEmpty) {
      return '';
    }

    final url = authRepository.getImageUrl(imageId);
    return url;
  }

  Future<void> debugStaffProfilePicture(String staffDocumentId) async {
    try {
      final staff = await getStaffByDocumentId(staffDocumentId);

      if (staff != null) {
        if (staff.image.isNotEmpty) {
          final imageUrl = getStaffProfilePictureUrl(staff.image);

          // Try to verify the image exists
          try {
            final imageDoc = await appWriteProvider.storage!.getFile(
              bucketId: AppwriteConstants.imageBucketID,
              fileId: staff.image,
            );
          } catch (e) {}
        } else {}
      } else {}
    } catch (e) {}
  }

  Future<void> fixStaffImageUrls() {
    return appWriteProvider.fixStaffImageUrls();
  }

  Future<Document> toggleDeletionRequestPin(
    String requestId,
    bool isPinned,
    String pinnedBy,
  ) {
    return appWriteProvider.toggleDeletionRequestPin(
        requestId, isPinned, pinnedBy);
  }

  /// Get closed dates for a clinic within a date range
  Future<List<String>> getClinicClosedDates(
    String clinicId,
    DateTime startDate,
    DateTime endDate,
  ) {
    return appWriteProvider.getClinicClosedDates(clinicId, startDate, endDate);
  }

  /// Check if a specific date is closed for a clinic
  Future<bool> isClinicClosedOnDate(String clinicId, DateTime date) {
    return appWriteProvider.isClinicClosedOnDate(clinicId, date);
  }

  /// Add a closed date to clinic settings
  Future<void> addClosedDateToClinic(String clinicId, DateTime date) {
    return appWriteProvider.addClosedDateToClinic(clinicId, date);
  }

  /// Remove a closed date from clinic settings
  Future<void> removeClosedDateFromClinic(String clinicId, DateTime date) {
    return appWriteProvider.removeClosedDateFromClinic(clinicId, date);
  }

  /// Clear all closed dates for a clinic
  Future<void> clearAllClosedDatesForClinic(String clinicId) {
    return appWriteProvider.clearAllClosedDatesForClinic(clinicId);
  }

  /// Remove past closed dates (cleanup utility)
  Future<void> removePastClosedDatesForClinic(String clinicId) {
    return appWriteProvider.removePastClosedDatesForClinic(clinicId);
  }

  /// Get available time slots excluding closed dates
  Future<List<String>> getAvailableTimeSlotsExcludingClosedDates(
    String clinicId,
    DateTime date,
  ) {
    return appWriteProvider.getAvailableTimeSlotsExcludingClosedDates(
      clinicId,
      date,
    );
  }

  /// Bulk add closed dates
  Future<void> bulkAddClosedDates(String clinicId, List<DateTime> dates) {
    return appWriteProvider.bulkAddClosedDates(clinicId, dates);
  }

  /// Get clinic settings with closed dates information
  Future<Map<String, dynamic>> getClinicSettingsWithClosedDatesInfo(
    String clinicId,
  ) async {
    try {
      final settings = await getClinicSettingsByClinicId(clinicId);

      if (settings == null) {
        return {
          'hasClosedDates': false,
          'totalClosedDates': 0,
          'upcomingClosedDates': 0,
          'pastClosedDates': 0,
        };
      }

      final today = DateTime.now();
      final todayStr =
          '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';

      int upcoming = 0;
      int past = 0;

      for (var dateStr in settings.closedDates) {
        if (dateStr.compareTo(todayStr) >= 0) {
          upcoming++;
        } else {
          past++;
        }
      }

      return {
        'hasClosedDates': settings.closedDates.isNotEmpty,
        'totalClosedDates': settings.closedDates.length,
        'upcomingClosedDates': upcoming,
        'pastClosedDates': past,
        'closedDates': settings.closedDates,
        'settings': settings,
      };
    } catch (e) {
      return {
        'hasClosedDates': false,
        'totalClosedDates': 0,
        'upcomingClosedDates': 0,
        'pastClosedDates': 0,
        'error': e.toString(),
      };
    }
  }

  /// Validate closed date before adding (business logic)
  Future<Map<String, dynamic>> validateClosedDate(
    String clinicId,
    DateTime date,
  ) async {
    try {
      // Check if date is in the past
      final today = DateTime.now();
      if (date.isBefore(DateTime(today.year, today.month, today.day))) {
        return {
          'isValid': false,
          'error': 'Cannot add past dates as closed dates',
        };
      }

      // Check if date is already closed
      final isAlreadyClosed = await isClinicClosedOnDate(clinicId, date);
      if (isAlreadyClosed) {
        return {
          'isValid': false,
          'error': 'This date is already marked as closed',
        };
      }

      // Check if there are existing appointments on this date
      final appointments = await getClinicAppointments(clinicId);
      final dateStr =
          '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

      final appointmentsOnDate = appointments.where((apt) {
        // FIXED: apt.dateTime is already a DateTime object
        final aptDate = apt.dateTime; // Remove DateTime.parse()
        final aptDateStr =
            '${aptDate.year}-${aptDate.month.toString().padLeft(2, '0')}-${aptDate.day.toString().padLeft(2, '0')}';
        return aptDateStr == dateStr &&
            (apt.status == 'pending' || apt.status == 'accepted');
      }).toList();

      if (appointmentsOnDate.isNotEmpty) {
        return {
          'isValid': false,
          'error':
              'There are ${appointmentsOnDate.length} active appointment(s) on this date',
          'appointmentCount': appointmentsOnDate.length,
          'hasConflicts': true,
        };
      }

      return {
        'isValid': true,
        'message': 'Date can be marked as closed',
      };
    } catch (e) {
      return {
        'isValid': false,
        'error': 'Validation failed: ${e.toString()}',
      };
    }
  }

  Future<List<Map<String, dynamic>>> getPetMedicalAppointmentsByClinic(
    String petId,
    String clinicId,
  ) async {
    try {
      final rawAppointments = await appWriteProvider
          .getPetMedicalAppointmentsByClinic(petId, clinicId);

      // Enrich with clinic information
      List<Map<String, dynamic>> enrichedAppointments = [];

      for (var appointmentData in rawAppointments) {
        try {
          final clinicId = appointmentData['clinicId'];

          // Fetch clinic details
          final clinicDoc = await appWriteProvider.getClinicById(clinicId);

          if (clinicDoc != null) {
            appointmentData['clinicName'] =
                clinicDoc.data['clinicName'] ?? 'Unknown Clinic';
            appointmentData['clinicAddress'] =
                clinicDoc.data['address'] ?? 'N/A';
            appointmentData['clinicContact'] =
                clinicDoc.data['contact'] ?? 'N/A';
          } else {
            appointmentData['clinicName'] = 'Unknown Clinic';
            appointmentData['clinicAddress'] = 'N/A';
            appointmentData['clinicContact'] = 'N/A';
          }

          enrichedAppointments.add(appointmentData);
        } catch (e) {
          appointmentData['clinicName'] = 'Unknown Clinic';
          appointmentData['clinicAddress'] = 'N/A';
          appointmentData['clinicContact'] = 'N/A';
          enrichedAppointments.add(appointmentData);
        }
      }

      return enrichedAppointments;
    } catch (e) {
      return [];
    }
  }

  Future<Map<String, dynamic>> sendPasswordResetEmail(String email) {
    return appWriteProvider.sendPasswordResetEmail(email);
  }

  /// Validate password reset token
  Future<bool> validatePasswordResetSecret(String userId, String secret) {
    return appWriteProvider.validatePasswordResetSecret(userId, secret);
  }

  /// Reset password
  Future<bool> resetPassword({
    required String userId,
    required String secret,
    required String newPassword,
  }) {
    return appWriteProvider.resetPassword(
      userId: userId,
      secret: secret,
      newPassword: newPassword,
    );
  }

  Stream<RealtimeMessage> subscribeToUserConversations(String userId) {
    return appWriteProvider.subscribeToUserConversations(userId);
  }

  Stream<RealtimeMessage> subscribeToClinicConversations(String clinicId) {
    return appWriteProvider.subscribeToClinicConversations(clinicId);
  }

  Future<Document> updateUserProfile({
    required String documentId,
    Map<String, dynamic>? fields,
  }) {
    return appWriteProvider.updateUserProfile(
      documentId: documentId,
      fields: fields,
    );
  }

  Future<Map<String, dynamic>?> getPetWithImage(String petId) {
    return appWriteProvider.getPetWithImage(petId);
  }

  Future<void> cleanupAppointmentController() async {
    try {
      if (Get.isRegistered<WebAppointmentController>()) {
        final controller = Get.find<WebAppointmentController>();
        controller.cleanupOnLogout();

        // Delete the controller instance
        Get.delete<WebAppointmentController>(force: true);
      }
    } catch (e) {}
  }

  String _formatNameToProperCase(String name) {
    if (name.isEmpty) return name;

    // Remove extra spaces and trim
    name = name.trim().replaceAll(RegExp(r'\s+'), ' ');

    // Split by spaces
    final words = name.toLowerCase().split(' ');

    // Capitalize first letter of each word
    final properCaseWords = words.map((word) {
      if (word.isEmpty) return word;

      // Handle special prefixes (e.g., "Mc", "Mac", "De", "Van")
      if (word.length >= 2) {
        // Handle "Mc" prefix (e.g., "McDonald" becomes "McDonald")
        if (word.startsWith('mc') && word.length > 2) {
          return 'Mc${word[2].toUpperCase()}${word.substring(3)}';
        }

        // Handle "Mac" prefix (e.g., "Macdonald" becomes "MacDonald")
        if (word.startsWith('mac') && word.length > 3) {
          return 'Mac${word[3].toUpperCase()}${word.substring(4)}';
        }
      }

      // Handle hyphenated names (e.g., "Jean-Paul")
      if (word.contains('-')) {
        return word.split('-').map((part) {
          if (part.isEmpty) return part;
          return part[0].toUpperCase() + part.substring(1);
        }).join('-');
      }

      // Handle apostrophes (e.g., "O'Brien")
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

  Future<bool> updateAuthAccountName(String newName) async {
    try {
      // 🆕 Ensure proper capitalization
      final formattedName = _formatNameToProperCase(newName);

      await appWriteProvider.account!.updateName(name: formattedName);
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Fetch verified name from ID Verification document
  Future<String?> getVerifiedNameFromIdVerification(String userId) async {
    try {
      final documents = await appWriteProvider.databases!.listDocuments(
        databaseId: AppwriteConstants.dbID,
        collectionId: AppwriteConstants.idVerificationCollectionID,
        queries: [
          Query.equal('userId', userId),
          Query.equal('status', 'approved'),
          Query.orderDesc('\$createdAt'),
          Query.limit(1),
        ],
      );

      if (documents.documents.isNotEmpty) {
        final verificationDoc = documents.documents.first.data;
        final rawName = verificationDoc['fullName'] as String?;

        if (rawName != null && rawName.isNotEmpty) {
          // 🆕 Convert to proper case
          final properName = _formatNameToProperCase(rawName);
          return properName;
        }
      }

      return null;
    } catch (e) {
      return null;
    }
  }

  /// Update user's name from verified ID (PAWrtal verification only)
  Future<bool> syncVerifiedNameToUserProfile(
      String userId, String userDocumentId) async {
    try {
      // Get verified name from ID verification (already formatted to proper case)
      final verifiedName = await getVerifiedNameFromIdVerification(userId);

      if (verifiedName == null || verifiedName.isEmpty) {
        return false;
      }

      // 1. Update user document (database collection)
      await appWriteProvider.databases!.updateDocument(
        databaseId: AppwriteConstants.dbID,
        collectionId: AppwriteConstants.usersCollectionID,
        documentId: userDocumentId,
        data: {'name': verifiedName},
      );

      // 2. Update Appwrite Auth account name
      await appWriteProvider.account!.updateName(name: verifiedName);

      // 3. Update GetStorage
      await GetStorage().write('userName', verifiedName);

      return true;
    } catch (e) {
      return false;
    }
  }

  Future<void> syncAuthNameOnLogin(String userId) async {
    try {
      final userDoc = await appWriteProvider.databases!.listDocuments(
        databaseId: AppwriteConstants.dbID,
        collectionId: AppwriteConstants.usersCollectionID,
        queries: [
          Query.equal('userId', userId),
          Query.limit(1),
        ],
      );

      if (userDoc.documents.isEmpty) {
        return;
      }

      final databaseName = userDoc.documents.first.data['name'] as String?;

      if (databaseName == null || databaseName.isEmpty) {
        return;
      }

      // 🆕 Ensure proper capitalization
      final formattedName = _formatNameToProperCase(databaseName);

      final currentUser = await appWriteProvider.account!.get();
      final authName = currentUser.name;

      if (authName != formattedName) {
        await appWriteProvider.account!.updateName(name: formattedName);

        // Also update database if it wasn't properly formatted
        if (databaseName != formattedName) {
          await appWriteProvider.databases!.updateDocument(
            databaseId: AppwriteConstants.dbID,
            collectionId: AppwriteConstants.usersCollectionID,
            documentId: userDoc.documents.first.$id,
            data: {'name': formattedName},
          );
        }

        await GetStorage().write('userName', formattedName);
      } else {}
    } catch (e) {}
  }

// ============= VET CLINIC REGISTRATION REQUEST METHODS =============
// Add these methods to your AuthRepository class

  /// Create vet clinic registration request
  Future<Document> createVetRegistrationRequest(Map<String, dynamic> data) {
    return appWriteProvider.createVetRegistrationRequest(data);
  }

  /// Get all vet registration requests
  Future<List<VetClinicRegistrationRequest>> getAllVetRegistrationRequests({
    String? status,
  }) async {
    try {
      final docs = await appWriteProvider.getAllVetRegistrationRequests(
        status: status,
      );

      return docs.map((doc) {
        final request = VetClinicRegistrationRequest.fromMap(doc.data);
        return request.copyWith(documentId: doc.$id);
      }).toList();
    } catch (e) {
      return [];
    }
  }

  /// Get single registration request by ID
  Future<VetClinicRegistrationRequest?> getVetRegistrationRequestById(
    String requestId,
  ) async {
    try {
      final doc =
          await appWriteProvider.getVetRegistrationRequestById(requestId);
      if (doc != null) {
        final request = VetClinicRegistrationRequest.fromMap(doc.data);
        return request.copyWith(documentId: doc.$id);
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  /// Update registration request status
  Future<void> updateVetRegistrationRequestStatus(
    String requestId,
    String status,
    String reviewedBy,
    String? reviewNotes,
  ) {
    return appWriteProvider.updateVetRegistrationRequestStatus(
      requestId,
      status,
      reviewedBy,
      reviewNotes,
    );
  }

  /// Upload registration document
  Future<models.File> uploadVetRegistrationDocument(PlatformFile file) {
    return appWriteProvider.uploadVetRegistrationDocument(file);
  }

  /// Delete registration document
  Future<void> deleteVetRegistrationDocument(String fileId) {
    return appWriteProvider.deleteVetRegistrationDocument(fileId);
  }

  /// Get registration document URL
  String getVetRegistrationDocumentUrl(String fileId) {
    return appWriteProvider.getVetRegistrationDocumentUrl(fileId);
  }

  /// Subscribe to registration requests changes (real-time)
  Stream<RealtimeMessage> subscribeToVetRegistrationRequests() {
    return appWriteProvider.subscribeToVetRegistrationRequests();
  }

  /// Get registration statistics
  Future<Map<String, int>> getVetRegistrationStats() {
    return appWriteProvider.getVetRegistrationStats();
  }
}
