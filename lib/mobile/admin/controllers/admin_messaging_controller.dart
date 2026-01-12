import 'dart:async';
import 'package:appwrite/appwrite.dart' as models;
import 'package:capstone_app/data/models/conversation_model.dart';
import 'package:capstone_app/data/models/message_model.dart';
import 'package:capstone_app/data/models/conversation_starter_model.dart';
import 'package:capstone_app/data/models/user_status_model.dart';
import 'package:capstone_app/data/repository/auth.repository.dart';
import 'package:capstone_app/utils/appwrite_constant.dart';
import 'package:capstone_app/utils/user_session_service.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class AdminMessagingController extends GetxController {
  final AuthRepository _authRepository = Get.find<AuthRepository>();
  final UserSessionService _userSession = Get.find<UserSessionService>();

  // Observable variables
  final conversations = <Conversation>[].obs;
  final currentMessages = <Message>[].obs;
  final conversationStarters = <ConversationStarter>[].obs;
  final userStatuses = <String, UserStatus>{}.obs;

  // Loading states
  final isLoading = false.obs;
  final isSendingMessage = false.obs;
  final isLoadingConversation = false.obs;
  final isLoadingStarters = false.obs;

  // Current conversation data
  final currentConversation = Rxn<Conversation>();
  final currentReceiverId = ''.obs;
  final currentReceiverType = ''.obs;
  final currentClinicId = ''.obs;

  // Text controllers
  final messageController = TextEditingController();
  final scrollController = ScrollController();
  final searchController = TextEditingController();

  // Conversation starters management
  final starterTriggerController = TextEditingController();
  final starterResponseController = TextEditingController();
  final selectedCategory = 'general'.obs;
  final categories = ['general', 'appointment', 'services', 'emergency'].obs;

  // Real-time subscriptions
  StreamSubscription<models.RealtimeMessage>? _messageSubscription;
  StreamSubscription<models.RealtimeMessage>? _conversationSubscription;
  StreamSubscription<models.RealtimeMessage>? _statusSubscription;

  // Track active subscriptions
  String? _activeConversationId;
  String? _activeClinicId;

  @override
  void onInit() {
    super.onInit();
    setUserOnline();
  }

  @override
  void onClose() {

    try {
      _cancelAllSubscriptions();
      _disposeControllers();
      _clearAllData();
      _setUserOfflineWithTimeout();
    } catch (e) {
    } finally {
      super.onClose();
    }
  }

  Future<void> cleanupBeforeLogout() async {

    try {
      _cancelAllSubscriptions();
      _clearAllData();
      await _setUserOfflineWithTimeout();
    } catch (e) {
    }
  }

  void _cancelAllSubscriptions() {

    try {
      _messageSubscription?.cancel();
      _messageSubscription = null;
      _activeConversationId = null;
    } catch (e) {
    }

    try {
      _conversationSubscription?.cancel();
      _conversationSubscription = null;
      _activeClinicId = null;
    } catch (e) {
    }

    try {
      _statusSubscription?.cancel();
      _statusSubscription = null;
    } catch (e) {
    }

  }

  void _disposeControllers() {

    try {
      messageController.dispose();
      scrollController.dispose();
      searchController.dispose();
      starterTriggerController.dispose();
      starterResponseController.dispose();
    } catch (e) {
    }

  }

  void _clearAllData() {

    try {
      conversations.clear();
      currentMessages.clear();
      conversationStarters.clear();
      userStatuses.clear();

      currentConversation.value = null;
      currentReceiverId.value = '';
      currentReceiverType.value = '';
      currentClinicId.value = '';
      selectedCategory.value = 'general';

      isLoading.value = false;
      isSendingMessage.value = false;
      isLoadingConversation.value = false;
      isLoadingStarters.value = false;

    } catch (e) {
    }
  }

  Future<void> _setUserOfflineWithTimeout() async {
    try {
      await setUserOffline().timeout(
        const Duration(seconds: 2),
        onTimeout: () {
        },
      );
    } catch (e) {
    }
  }

  // ============= CLINIC SETUP =============

  Future<void> initializeForClinic(String clinicId) async {
    try {
      currentClinicId.value = clinicId;


      if (!AppwriteConstants.messagingCollectionsConfigured) {
        Get.snackbar(
          'Setup Required',
          'Please create messaging collections in AppWrite first.',
          backgroundColor: Colors.orange,
          colorText: Colors.white,
          duration: const Duration(seconds: 5),
        );
        return;
      }

      await Future.wait([
        loadClinicConversations(clinicId),
        initializeConversationStarters(clinicId),
      ]);

      subscribeToClinicConversationUpdates(clinicId);

    } catch (e) {
      Get.snackbar(
        'Initialization Error',
        'Failed to initialize messaging: $e',
        backgroundColor: Colors.red,
        colorText: Colors.white,
        duration: const Duration(seconds: 5),
      );
    }
  }

  Future<void> initializeConversationStarters(String clinicId) async {
    try {
      isLoadingStarters.value = true;


      // ADDED: Run migration for existing starters
      try {
        await _authRepository.migrateConversationStarters();
      } catch (e) {
      }

      final starters =
          await _authRepository.getClinicConversationStarters(clinicId);
      conversationStarters.value = starters;


      if (starters.isEmpty) {
        await _authRepository.initializeDefaultConversationStarters(clinicId);

        await Future.delayed(const Duration(milliseconds: 500));

        final newStarters =
            await _authRepository.getClinicConversationStarters(clinicId);
        conversationStarters.value = newStarters;


        if (newStarters.isNotEmpty) {
          Get.snackbar(
            'Default Starters Created',
            '${newStarters.length} conversation starters have been set up for your clinic.',
            backgroundColor: Colors.green,
            colorText: Colors.white,
            duration: const Duration(seconds: 3),
          );
        }
      }
    } catch (e) {
      Get.snackbar(
        'Starters Error',
        'Could not load conversation starters: $e',
        backgroundColor: Colors.red,
        colorText: Colors.white,
        duration: const Duration(seconds: 5),
      );
    } finally {
      isLoadingStarters.value = false;
    }
  }

  // ============= CONVERSATION METHODS =============

  Future<void> loadClinicConversations(String clinicId) async {
    try {
      isLoading.value = true;
      final clinicConversations =
          await _authRepository.getClinicConversations(clinicId);
      conversations.value = clinicConversations;
    } catch (e) {
      Get.snackbar('Error', 'Failed to load conversations: $e',
          backgroundColor: Colors.red, colorText: Colors.white);
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> openConversation(
      Conversation conversation, String receiverId, String receiverType) async {
    try {

      isLoadingConversation.value = true;

      currentConversation.value = conversation;
      currentReceiverId.value = receiverId;
      currentReceiverType.value = receiverType;

      await loadConversationMessages(conversation.documentId!);

      subscribeToMessages(conversation.documentId!);

      await markConversationAsRead(conversation.documentId!);

      await loadUserStatus(receiverId);

    } catch (e) {
      Get.snackbar('Error', 'Failed to open conversation: $e',
          backgroundColor: Colors.red, colorText: Colors.white);
    } finally {
      isLoadingConversation.value = false;
    }
  }

  // ============= MESSAGE METHODS =============

  Future<void> loadConversationMessages(String conversationId) async {
    try {
      final messages =
          await _authRepository.getConversationMessages(conversationId);
      currentMessages.value = messages;
    } catch (e) {
      Get.snackbar('Error', 'Failed to load messages: $e',
          backgroundColor: Colors.red, colorText: Colors.white);
    }
  }

  void _scrollToBottom() {
    if (scrollController.hasClients) {
      scrollController.animateTo(
        0.0,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  Future<void> sendMessage({String? text, String? attachmentUrl}) async {
    final messageText = text ?? messageController.text.trim();
    if (messageText.isEmpty && attachmentUrl == null) return;

    if (currentConversation.value == null) return;

    try {
      isSendingMessage.value = true;

      if (text == null) messageController.clear();


      final sentMessage = await _authRepository.sendMessage(
        conversationId: currentConversation.value!.documentId!,
        senderId: _userSession.userId,
        messageText: messageText,
        attachment: attachmentUrl,
      );


      final updatedConversation = currentConversation.value!.copyWith(
        lastMessageId: sentMessage.documentId,
        lastMessageText: messageText,
        lastMessageTime: sentMessage.createdAt,
        clinicUnreadCount: 0,
      );
      currentConversation.value = updatedConversation;

      final index = conversations
          .indexWhere((c) => c.documentId == updatedConversation.documentId);
      if (index != -1) {
        conversations.removeAt(index);
        conversations.insert(0, updatedConversation);
      }

    } catch (e) {
      Get.snackbar('Error', 'Failed to send message: $e',
          backgroundColor: Colors.red, colorText: Colors.white);
    } finally {
      isSendingMessage.value = false;
    }
  }

  bool hasUnreadMessages(Conversation conversation) {
    return conversation.clinicUnreadCount > 0;
  }

  Future<void> markConversationAsRead(String conversationId) async {
    try {

      await _authRepository.markMessagesAsRead(
          conversationId, _userSession.userId);

      if (currentConversation.value != null &&
          currentConversation.value!.documentId == conversationId &&
          currentConversation.value!.clinicUnreadCount > 0) {

        final updatedConversation = currentConversation.value!.copyWith(
          clinicUnreadCount: 0,
        );
        currentConversation.value = updatedConversation;

        final index =
            conversations.indexWhere((c) => c.documentId == conversationId);
        if (index != -1) {
          conversations[index] = updatedConversation;
        }

      } else {
      }

    } catch (e) {
    }
  }

  // ============= CONVERSATION STARTERS MANAGEMENT =============

  Future<void> loadConversationStarters(String clinicId) async {
    try {
      isLoadingStarters.value = true;
      final starters =
          await _authRepository.getClinicConversationStarters(clinicId);
      conversationStarters.value = starters;

      if (starters.isEmpty) {
        await _authRepository.initializeDefaultConversationStarters(clinicId);
        final newStarters =
            await _authRepository.getClinicConversationStarters(clinicId);
        conversationStarters.value = newStarters;
      }
    } catch (e) {
    } finally {
      isLoadingStarters.value = false;
    }
  }

  Future<void> addConversationStarter() async {
    if (starterTriggerController.text.trim().isEmpty ||
        starterResponseController.text.trim().isEmpty ||
        currentClinicId.value.isEmpty) {
      return;
    }

    try {
      final starter = ConversationStarter(
        clinicId: currentClinicId.value,
        triggerText: starterTriggerController.text.trim(),
        responseText: starterResponseController.text.trim(),
        category: selectedCategory.value,
        displayOrder: conversationStarters.length + 1,
      );

      final doc = await _authRepository.createConversationStarter(starter);
      final createdStarter = starter.copyWith(documentId: doc.$id);

      conversationStarters.add(createdStarter);

      starterTriggerController.clear();
      starterResponseController.clear();
      selectedCategory.value = 'general';

      Get.snackbar('Success', 'Conversation starter added successfully!',
          backgroundColor: Colors.green, colorText: Colors.white);
    } catch (e) {
      Get.snackbar('Error', 'Failed to add conversation starter: $e',
          backgroundColor: Colors.red, colorText: Colors.white);
    }
  }

  Future<void> updateConversationStarter(ConversationStarter starter) async {
    try {
      await _authRepository.updateConversationStarter(starter);

      final index = conversationStarters
          .indexWhere((s) => s.documentId == starter.documentId);
      if (index != -1) {
        conversationStarters[index] = starter;
      }

      Get.snackbar('Success', 'Conversation starter updated successfully!',
          backgroundColor: Colors.green, colorText: Colors.white);
    } catch (e) {
      Get.snackbar('Error', 'Failed to update conversation starter: $e',
          backgroundColor: Colors.red, colorText: Colors.white);
    }
  }

  Future<void> deleteConversationStarter(String starterId) async {
    try {
      await _authRepository.deleteConversationStarter(starterId);
      conversationStarters.removeWhere((s) => s.documentId == starterId);

      Get.snackbar('Success', 'Conversation starter deleted successfully!',
          backgroundColor: Colors.green, colorText: Colors.white);
    } catch (e) {
      Get.snackbar('Error', 'Failed to delete conversation starter: $e',
          backgroundColor: Colors.red, colorText: Colors.white);
    }
  }

  void toggleStarterStatus(ConversationStarter starter) async {
    final updatedStarter = starter.copyWith(isActive: !starter.isActive);
    await updateConversationStarter(updatedStarter);
  }

  /// Set a conversation starter as the auto-reply for first messages
  Future<void> setAutoReplyStarter(String starterId) async {
    try {

      // First, unset any existing auto-reply starter
      final currentAutoReply = conversationStarters.firstWhereOrNull(
        (s) => s.isAutoReply == true,
      );

      if (currentAutoReply != null &&
          currentAutoReply.documentId != starterId) {
        final unsetStarter = currentAutoReply.copyWith(isAutoReply: false);
        await _authRepository.updateConversationStarter(unsetStarter);

        // Update local list
        final index = conversationStarters.indexWhere(
          (s) => s.documentId == currentAutoReply.documentId,
        );
        if (index != -1) {
          conversationStarters[index] = unsetStarter;
        }
      }

      // Set the new auto-reply starter
      final starterIndex = conversationStarters.indexWhere(
        (s) => s.documentId == starterId,
      );

      if (starterIndex != -1) {
        final updatedStarter = conversationStarters[starterIndex].copyWith(
          isAutoReply: true,
          isActive: true, // Ensure it's active
        );

        await _authRepository.updateConversationStarter(updatedStarter);
        conversationStarters[starterIndex] = updatedStarter;
        // ❌ REMOVE THIS LINE: conversationStarters.refresh();

        Get.snackbar(
          'Success',
          'Auto-reply message configured',
          backgroundColor: Colors.green,
          colorText: Colors.white,
        );
      }
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to set auto-reply: $e',
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }

  /// Unset auto-reply for a starter
  Future<void> unsetAutoReplyStarter(String starterId) async {
    try {
      final starterIndex = conversationStarters.indexWhere(
        (s) => s.documentId == starterId,
      );

      if (starterIndex != -1) {
        final updatedStarter = conversationStarters[starterIndex].copyWith(
          isAutoReply: false,
        );

        await _authRepository.updateConversationStarter(updatedStarter);
        conversationStarters[starterIndex] = updatedStarter;
        // ❌ REMOVE THIS LINE: conversationStarters.refresh();

        Get.snackbar(
          'Success',
          'Auto-reply disabled',
          backgroundColor: Colors.green,
          colorText: Colors.white,
        );
      }
    } catch (e) {
    }
  }

  /// Get the current auto-reply starter
  ConversationStarter? getAutoReplyStarter() {
    try {

      for (var starter in conversationStarters) {
      }

      final autoReply = conversationStarters.firstWhereOrNull(
        (s) => (s.isAutoReply == true) && (s.isActive == true),
      );

      if (autoReply != null) {
      } else {
      }

      return autoReply;
    } catch (e) {
      return null;
    }
  }

  /// Check if a conversation is new (first message from user)
  Future<bool> isFirstUserMessage(String conversationId) async {
    try {

      final messages = await _authRepository.getConversationMessages(
        conversationId,
        limit: 100,
      );


      int userMessageCount = 0;
      int clinicMessageCount = 0;

      for (int i = 0; i < messages.length; i++) {
        final msg = messages[i];
        final isFromClinic = msg.senderId == currentClinicId.value;
        final isFromAdmin = msg.senderId == _userSession.userId;
        final isFromUser = !isFromClinic && !isFromAdmin;


        if (isFromClinic || isFromAdmin) {
          clinicMessageCount++;
        } else if (isFromUser) {
          userMessageCount++;
        }
      }


      // If clinic has NEVER replied = first user message
      final isFirst = clinicMessageCount == 0;

      if (isFirst) {
      } else {
      }

      return isFirst;
    } catch (e) {
      return false;
    }
  }

  /// Send auto-reply if it's the first user message
  Future<void> sendAutoReplyIfFirstMessage(String conversationId) async {
    // This method is now mainly for manual/UI triggers
    // Background auto-reply is handled by _checkAndSendAutoReply
    await _checkAndSendAutoReply(conversationId);
  }

  // ============= USER STATUS METHODS =============

  Future<void> setUserOnline() async {
    try {
      await _authRepository.setUserOnline(_userSession.userId);
    } catch (e) {
    }
  }

  Future<void> setUserOffline() async {
    try {
      await _authRepository.setUserOffline(_userSession.userId);
    } catch (e) {
    }
  }

  Future<void> loadUserStatus(String userId) async {
    try {
      final status = await _authRepository.getUserStatus(userId);
      if (status != null) {
        userStatuses[userId] = status;
      }
    } catch (e) {
    }
  }

  // ============= REAL-TIME SUBSCRIPTION METHODS =============

  void subscribeToClinicConversationUpdates(String clinicId) {

    if (_activeClinicId == clinicId && _conversationSubscription != null) {
      return;
    }

    _conversationSubscription?.cancel();
    _activeClinicId = null;

    try {
      _conversationSubscription =
          _authRepository.subscribeToConversations(clinicId).listen(
        (realtimeMessage) {

          try {
            final conversationData = realtimeMessage.payload;
            final updatedConversation = Conversation.fromMap(conversationData);
            final conversationWithId = updatedConversation.copyWith(
              documentId: conversationData['\$id'],
            );


            if (conversationWithId.clinicId == clinicId) {

              if (realtimeMessage.events
                  .contains('databases.*.collections.*.documents.*.update')) {
                _handleConversationUpdate(conversationWithId);

                // CRITICAL FIX: Check for auto-reply on conversation UPDATE
                // This catches when user sends a message (conversation gets updated)
                if (conversationWithId.lastMessageId != null) {
                  _checkAndSendAutoReply(conversationWithId.documentId!);
                }
              } else if (realtimeMessage.events
                  .contains('databases.*.collections.*.documents.*.create')) {
                _handleNewConversation(conversationWithId);

                // CRITICAL: Check for auto-reply on NEW conversation
                if (conversationWithId.lastMessageId != null) {
                  _checkAndSendAutoReply(conversationWithId.documentId!);
                }
              }
            } else {
            }
          } catch (e) {
          }
        },
        onError: (error) {
          Future.delayed(const Duration(seconds: 2), () {
            if (_activeClinicId == clinicId) {
              subscribeToClinicConversationUpdates(clinicId);
            }
          });
        },
        onDone: () {
          _activeClinicId = null;
        },
      );

      _activeClinicId = clinicId;
    } catch (e) {
    }
  }

  void _handleConversationUpdate(Conversation updatedConversation) {

    final index = conversations.indexWhere(
      (c) => c.documentId == updatedConversation.documentId,
    );

    if (index != -1) {

      final isCurrentConversation = currentConversation.value?.documentId ==
          updatedConversation.documentId;

      if (isCurrentConversation) {
        final resetClinicUnread =
            updatedConversation.copyWith(clinicUnreadCount: 0);
        conversations[index] = resetClinicUnread;
        currentConversation.value = resetClinicUnread;
      } else {
        conversations[index] = updatedConversation;
      }

      if (updatedConversation.clinicUnreadCount > 0 && index != 0) {
        final conv = conversations.removeAt(index);
        conversations.insert(0, conv);
      }

      // CRITICAL: Trigger auto-reply check when conversation is updated with new message
      if (updatedConversation.lastMessageId != null) {
        sendAutoReplyIfFirstMessage(updatedConversation.documentId!);
      }

    } else {
      _handleNewConversation(updatedConversation);
    }
  }

  void _handleNewConversation(Conversation newConversation) {

    final exists =
        conversations.any((c) => c.documentId == newConversation.documentId);

    if (!exists) {
      conversations.insert(0, newConversation);

      // CRITICAL: Trigger auto-reply for NEW conversations
      if (newConversation.lastMessageId != null) {
        sendAutoReplyIfFirstMessage(newConversation.documentId!);
      }
    } else {
    }
  }

  void subscribeToMessages(String conversationId) {

    if (_activeConversationId == conversationId &&
        _messageSubscription != null) {
      return;
    }

    _messageSubscription?.cancel();
    _activeConversationId = null;

    try {
      _activeConversationId = conversationId;
      _messageSubscription = _authRepository
          .subscribeToMessages(conversationId)
          .listen((realtimeMessage) {

        if (realtimeMessage.events
            .contains('databases.*.collections.*.documents.*.create')) {
          try {
            final messageData = realtimeMessage.payload;
            final message = Message.fromMap(messageData);
            final messageWithId =
                message.copyWith(documentId: messageData['\$id']);

            // Check for duplicates
            final existingIndex = currentMessages
                .indexWhere((m) => m.documentId == messageWithId.documentId);

            if (existingIndex == -1) {
              currentMessages.add(messageWithId);

              // CRITICAL FIX: Remove .refresh() call!
              // Since currentMessages is .obs and inside Obx(), it's already reactive
              // The .add() operation alone will trigger the Obx to rebuild efficiently
              // .refresh() forces a FULL list rebuild which causes the "reload" effect

              // currentMessages.refresh(); // ❌ REMOVE THIS LINE!

              // Scroll to bottom after the widget tree updates
              WidgetsBinding.instance.addPostFrameCallback((_) {
                _scrollToBottom();
              });

              // Mark as read if message is from other user
              if (messageWithId.senderId != _userSession.userId &&
                  currentConversation.value?.documentId == conversationId) {
                markConversationAsRead(conversationId);
              }
            } else {
            }
          } catch (e) {
          }
        }
      }, onError: (error) {
        _activeConversationId = null;
      });

    } catch (e) {
      _activeConversationId = null;
    }
  }

  Future<void> _checkAndSendAutoReply(String conversationId) async {
    try {

      // Get auto-reply starter
      final autoReplyStarter = getAutoReplyStarter();

      if (autoReplyStarter == null) {
        return;
      }


      // Check if this is the first user message
      final isFirst = await isFirstUserMessage(conversationId);

      if (!isFirst) {
        return;
      }


      // Send the auto-reply
      await _authRepository.sendConversationStarterResponse(
        conversationId: conversationId,
        clinicId: currentClinicId.value,
        responseText: autoReplyStarter.responseText,
      );


      // ❌ REMOVE THIS ENTIRE BLOCK! This is causing the reload!
      // The real-time subscription will pick up the new message automatically
      // if (currentConversation.value?.documentId == conversationId) {
      //   await Future.delayed(const Duration(milliseconds: 500));
      //   await loadConversationMessages(conversationId);
      //   print('>>> ✅ Messages reloaded for current conversation');
      // }

      // ✅ ADD THIS INSTEAD: Just log that real-time will handle it
    } catch (e) {
    }
  }

  // ============= HELPER METHODS =============

  bool isCurrentUser(String senderId) {
    // Admin can send messages as:
    // 1. Their own user ID (admin user ID)
    // 2. The clinic ID (when sending clinic responses)

    final isAdminUserId = senderId == _userSession.userId;
    final isClinicId = senderId == currentClinicId.value;


    return isAdminUserId || isClinicId;
  }

  UserStatus? getUserStatus(String userId) {
    return userStatuses[userId];
  }

  int getTotalUnreadCount() {
    return conversations.fold(0, (total, conversation) {
      return total + conversation.clinicUnreadCount;
    });
  }

  List<Conversation> get filteredConversations {
    if (searchController.text.isEmpty) {
      return conversations;
    }
    return conversations;
  }

  void disposeMessageSubscriptions() {
    _cancelAllSubscriptions();
  }

  void pauseMessageSubscription() {
    _messageSubscription?.cancel();
    _messageSubscription = null;
    _activeConversationId = null;
  }

  void resumeMessageSubscription(String conversationId) {
    subscribeToMessages(conversationId);
  }
}