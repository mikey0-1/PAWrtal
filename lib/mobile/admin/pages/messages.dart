import 'package:capstone_app/mobile/admin/controllers/admin_messaging_controller.dart';
import 'package:capstone_app/mobile/admin/pages/admin_messages_next_page.dart';
import 'package:capstone_app/mobile/admin/pages/conversation_starters_page.dart';
import 'package:capstone_app/data/models/conversation_model.dart';
import 'package:capstone_app/data/models/user_model.dart';
import 'package:capstone_app/data/repository/auth.repository.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

class MessagesPage extends StatefulWidget {
  final String clinicId;

  const MessagesPage({
    super.key,
    required this.clinicId,
  });

  @override
  State<MessagesPage> createState() => _MessagesPageState();
}

class _MessagesPageState extends State<MessagesPage>
    with WidgetsBindingObserver {
  late final AdminMessagingController _messagingController;
  final AuthRepository _authRepository = Get.find<AuthRepository>();
  final Map<String, dynamic> _userCache = {};

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    if (Get.isRegistered<AdminMessagingController>()) {
      _messagingController = Get.find<AdminMessagingController>();
    } else {
      _messagingController = Get.put(AdminMessagingController());
    }

    _messagingController.initializeForClinic(widget.clinicId);
    _setupRealtimeUpdates();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);

    if (state == AppLifecycleState.resumed) {
      _messagingController.loadClinicConversations(widget.clinicId);
    }
  }

  void _setupRealtimeUpdates() {
    _messagingController.subscribeToClinicConversationUpdates(widget.clinicId);
    _startPeriodicRefresh();
  }

  void _startPeriodicRefresh() {
    Future.delayed(const Duration(seconds: 10), () {
      if (mounted) {
        _messagingController.loadClinicConversations(widget.clinicId);
        _startPeriodicRefresh();
      }
    });
  }

  Future<Map<String, dynamic>> _getUserData(String userId) async {
    if (_userCache.containsKey(userId)) {
      return _userCache[userId];
    }

    try {
      final userDoc = await _authRepository.getUserById(userId);
      if (userDoc != null) {
        final user = User.fromMap(userDoc.data);

        final userData = {
          'name': user.name,
          'email': user.email,
          'phone': user.phone ?? '',
          'isOnline': false,
        };

        _userCache[userId] = userData;
        return userData;
      }
    } catch (e) {
    }

    return {
      'name': 'Unknown User',
      'email': '',
      'phone': '',
      'isOnline': false,
    };
  }

  Widget _buildConversationTile(Conversation conversation) {
    return FutureBuilder<Map<String, dynamic>>(
      future: _getUserData(conversation.userId),
      builder: (context, snapshot) {
        final userData = snapshot.data ??
            {
              'name': 'Loading...',
              'email': '',
              'phone': '',
              'isOnline': false,
            };

        final hasUnreadMessages = conversation.clinicUnreadCount > 0;

        return InkWell(
          onTap: () async {
            await Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => AdminMessagesNextPage(
                  conversation: conversation,
                  receiverId: conversation.userId,
                  receiverType: 'user',
                  receiverName: userData['name'],
                  receiverEmail: userData['email'],
                ),
              ),
            );
            _messagingController.loadClinicConversations(widget.clinicId);
          },
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: hasUnreadMessages
                  ? Border.all(
                      color: const Color.fromARGB(255, 81, 115, 153),
                      width: 2,
                    )
                  : null,
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.1),
                  spreadRadius: 1,
                  blurRadius: 3,
                  offset: const Offset(0, 1),
                ),
              ],
            ),
            child: Row(
              children: [
                Stack(
                  children: [
                    CircleAvatar(
                      radius: 25,
                      backgroundColor: const Color.fromARGB(255, 81, 115, 153),
                      child: Text(
                        userData['name'].isNotEmpty
                            ? userData['name'][0].toUpperCase()
                            : '?',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    Obx(() {
                      final status = _messagingController
                          .getUserStatus(conversation.userId);
                      if (status?.isOnline == true) {
                        return Positioned(
                          bottom: 0,
                          right: 0,
                          child: Container(
                            width: 14,
                            height: 14,
                            decoration: BoxDecoration(
                              color: Colors.green,
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 2),
                            ),
                          ),
                        );
                      }
                      return const SizedBox.shrink();
                    }),
                  ],
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              userData['name'].isNotEmpty
                                  ? userData['name']
                                  : 'Unknown User',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (conversation.lastMessageTime != null)
                            Text(
                              conversation.timeAgo,
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 12,
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              conversation.conversationPreview,
                              style: TextStyle(
                                fontSize: 14,
                                color: hasUnreadMessages
                                    ? Colors.black87
                                    : Colors.grey[600],
                                fontWeight: hasUnreadMessages
                                    ? FontWeight.w600
                                    : FontWeight.normal,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (hasUnreadMessages)
                            Container(
                              margin: const EdgeInsets.only(left: 8),
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 6, vertical: 2),
                              decoration: const BoxDecoration(
                                color: Color.fromARGB(255, 81, 115, 153),
                                shape: BoxShape.circle,
                              ),
                              child: Text(
                                conversation.clinicUnreadCount > 99
                                    ? '99+'
                                    : conversation.clinicUnreadCount.toString(),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.blue.shade50,
      body: Column(
        children: [
          Container(
            height: 75,
            padding: const EdgeInsets.only(top: 20),
            child: Row(
              children: [
                Expanded(
                  child: Center(
                    child: Text(
                      "Messages",
                      style: GoogleFonts.inter(
                        fontWeight: FontWeight.bold,
                        fontSize: 20,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: Container(
              width: double.maxFinite,
              decoration: const BoxDecoration(
                color: Color.fromARGB(255, 248, 253, 255),
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(20),
                  topRight: Radius.circular(20),
                ),
              ),
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Container(
                      height: 50,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(25.0),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.grey.shade400,
                            spreadRadius: 2,
                            blurRadius: 3,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: TextField(
                        controller: _messagingController.searchController,
                        decoration: const InputDecoration(
                          hintText: 'Search conversations...',
                          border: InputBorder.none,
                          prefixIcon: Icon(Icons.search),
                          contentPadding: EdgeInsets.symmetric(
                              horizontal: 16, vertical: 14),
                        ),
                        onChanged: (value) {
                          setState(() {});
                        },
                      ),
                    ),
                  ),
                  Expanded(
                    child: Obx(() {
                      if (_messagingController.isLoading.value) {
                        return const Center(
                          child: CircularProgressIndicator(
                            color: Color.fromARGB(255, 81, 115, 153),
                          ),
                        );
                      }

                      final conversations =
                          _messagingController.filteredConversations;

                      if (conversations.isEmpty) {
                        return Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.chat_bubble_outline,
                                size: 64,
                                color: Colors.grey[400],
                              ),
                              const SizedBox(height: 16),
                              Text(
                                "No conversations yet",
                                style: TextStyle(
                                  fontSize: 18,
                                  color: Colors.grey[600],
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                "Users will appear here when they\nstart conversations with your clinic",
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey[500],
                                ),
                              ),
                            ],
                          ),
                        );
                      }

                      return RefreshIndicator(
                        onRefresh: () async {
                          await _messagingController
                              .loadClinicConversations(widget.clinicId);
                        },
                        child: ListView.builder(
                          padding: const EdgeInsets.only(bottom: 20),
                          itemCount: conversations.length,
                          itemBuilder: (context, index) {
                            final conversation = conversations[index];
                            return _buildConversationTile(conversation);
                          },
                        ),
                      );
                    }),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        heroTag: "admin_messages_fab",
        backgroundColor: const Color.fromARGB(255, 81, 115, 153),
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const ConversationStartersPage(),
            ),
          );
        },
        child: const Icon(
          Icons.auto_awesome,
          color: Colors.white,
        ),
      ),
    );
  }
}