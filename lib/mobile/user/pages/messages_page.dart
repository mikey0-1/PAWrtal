import 'package:capstone_app/mobile/user/controllers/user_messaging_controller.dart';
import 'package:capstone_app/mobile/user/pages/messages_next_page.dart';
import 'package:capstone_app/data/models/conversation_model.dart';
import 'package:capstone_app/data/repository/auth.repository.dart';
import 'package:capstone_app/data/models/clinic_model.dart';
import 'package:capstone_app/utils/appwrite_constant.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:get/get.dart';

class Messages extends StatefulWidget {
  const Messages({super.key});

  @override
  State<Messages> createState() => _MessagesState();
}

class _MessagesState extends State<Messages> with WidgetsBindingObserver {
  late final MessagingController _messagingController;
  final AuthRepository _authRepository = Get.find<AuthRepository>();
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  final Map<String, dynamic> _clinicCache = {};

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    _messagingController = Get.put(MessagingController(), permanent: false);

    // STEP 1: Load conversations once
    _messagingController.loadUserConversations();

    // STEP 2: CRITICAL - Subscribe to real-time updates
    _messagingController.subscribeToConversationUpdates();

    // STEP 3: Check if we need to restore a conversation from layout transition
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (_messagingController.shouldRestoreConversation()) {
        final data = _messagingController.selectedConversationData.value!;
        final conversation = data['conversation'] as Conversation;
        final receiverId = data['receiverId'] as String;
        final receiverType = data['receiverType'] as String;

        final conversationData = await _getConversationData(conversation);

        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => MessagesNextPage(
              conversation: conversation,
              receiverId: receiverId,
              receiverType: receiverType,
              receiverName: conversationData['name'],
              receiverImage: conversationData['image'],
              receiverProfilePictureId: conversationData['profilePictureId'],
            ),
          ),
        );

        _messagingController.clearPreservedConversation();
      }
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _searchController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);

    // Only refresh when app resumes (to catch any missed real-time updates)
    if (state == AppLifecycleState.resumed) {
      _messagingController.loadUserConversations();
    }
  }

  List<Conversation> get _filteredConversations {
    if (_searchQuery.isEmpty) {
      return _messagingController.conversations;
    }

    final query = _searchQuery.toLowerCase();
    return _messagingController.conversations.where((conversation) {
      final clinicData = _clinicCache[conversation.clinicId];
      final clinicName = clinicData?['name']?.toString().toLowerCase() ?? '';
      final lastMessage = conversation.lastMessageText?.toLowerCase() ?? '';

      return clinicName.contains(query) || lastMessage.contains(query);
    }).toList();
  }

  Future<Map<String, dynamic>> _getConversationData(
      Conversation conversation) async {
    String cacheKey = conversation.clinicId;

    if (_clinicCache.containsKey(cacheKey)) {
      return _clinicCache[cacheKey];
    }

    try {
      final clinicDoc =
          await _authRepository.getClinicById(conversation.clinicId);
      if (clinicDoc != null) {
        final clinic = Clinic.fromMap(clinicDoc.data);
        clinic.documentId = clinicDoc.$id;

        final conversationData = {
          'name': clinic.clinicName,
          'image': clinic.image,
          'profilePictureId': clinic.profilePictureId ?? '',
          'isOnline': false,
        };

        _clinicCache[cacheKey] = conversationData;
        return conversationData;
      }
    } catch (e) {
    }

    return {
      'name': 'Unknown Clinic',
      'image': '',
      'profilePictureId': '',
      'isOnline': false,
    };
  }

  String _getProfileImageUrl(String profilePictureId) {
    return '${AppwriteConstants.endPoint}/storage/buckets/${AppwriteConstants.imageBucketID}/files/$profilePictureId/view?project=${AppwriteConstants.projectID}';
  }

  Widget _buildProfileImage(Map<String, dynamic> clinicData, double size) {
    final profilePictureId = clinicData['profilePictureId'] as String? ?? '';
    final fallbackImage = clinicData['image'] as String? ?? '';
    final clinicName = clinicData['name'] as String? ?? 'Clinic';

    return ClipRRect(
      borderRadius: BorderRadius.circular(size / 2),
      child: profilePictureId.isNotEmpty
          ? Image.network(
              _getProfileImageUrl(profilePictureId),
              height: size,
              width: size,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return fallbackImage.isNotEmpty
                    ? Image.network(
                        fallbackImage,
                        height: size,
                        width: size,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return _buildDefaultAvatar(clinicName, size);
                        },
                      )
                    : _buildDefaultAvatar(clinicName, size);
              },
            )
          : fallbackImage.isNotEmpty
              ? Image.network(
                  fallbackImage,
                  height: size,
                  width: size,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return _buildDefaultAvatar(clinicName, size);
                  },
                )
              : _buildDefaultAvatar(clinicName, size),
    );
  }

  Widget _buildDefaultAvatar(String name, double size) {
    return Container(
      height: size,
      width: size,
      decoration: BoxDecoration(
        color: const Color.fromARGB(255, 81, 115, 153),
        borderRadius: BorderRadius.circular(size / 2),
      ),
      child: Center(
        child: Text(
          name.isNotEmpty ? name[0].toUpperCase() : '?',
          style: TextStyle(
            color: Colors.white,
            fontSize: size * 0.4,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _buildConversationTile(Conversation conversation) {
    return FutureBuilder<Map<String, dynamic>>(
      future: _getConversationData(conversation),
      builder: (context, snapshot) {
        final data = snapshot.data ??
            {
              'name': 'Loading...',
              'image': '',
              'profilePictureId': '',
              'isOnline': false
            };

        final hasUnreadMessages = conversation.userUnreadCount > 0;

        return InkWell(
          onTap: () async {
            await Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => MessagesNextPage(
                  conversation: conversation,
                  receiverId: conversation.clinicId,
                  receiverType: 'clinic',
                  receiverName: data['name'],
                  receiverImage: data['image'],
                  receiverProfilePictureId: data['profilePictureId'],
                ),
              ),
            );
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
                    _buildProfileImage(data, 50),
                    if (data['isOnline'])
                      Positioned(
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
                      ),
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
                          Text(
                            data['name'],
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
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
                                conversation.userUnreadCount.toString(),
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
          // Header
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

          // Main Content
          Expanded(
            child: Container(
              width: double.maxFinite,
              height: double.maxFinite,
              decoration: const BoxDecoration(
                color: Color.fromARGB(255, 248, 253, 255),
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(20),
                  topRight: Radius.circular(20),
                ),
              ),
              child: Column(
                children: [
                  // Search Bar
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
                        controller: _searchController,
                        decoration: InputDecoration(
                          hintText: "Search conversations...",
                          border: InputBorder.none,
                          prefixIcon: const Icon(Icons.search),
                          suffixIcon: _searchQuery.isNotEmpty
                              ? IconButton(
                                  icon: const Icon(Icons.clear),
                                  onPressed: () {
                                    setState(() {
                                      _searchController.clear();
                                      _searchQuery = '';
                                    });
                                  },
                                )
                              : null,
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 14),
                        ),
                        onChanged: (value) {
                          setState(() {
                            _searchQuery = value;
                          });
                        },
                      ),
                    ),
                  ),

                  // Conversations List
                  Expanded(
                    child: Obx(() {
                      if (_messagingController.isLoading.value) {
                        return const Center(
                          child: CircularProgressIndicator(
                            color: Color.fromARGB(255, 81, 115, 153),
                          ),
                        );
                      }

                      if (_messagingController.conversations.isEmpty) {
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
                                "Start a conversation with a clinic\nto ask questions or book appointments",
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

                      final filteredConversations = _filteredConversations;

                      if (filteredConversations.isEmpty) {
                        return Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.search_off,
                                size: 64,
                                color: Colors.grey[400],
                              ),
                              const SizedBox(height: 16),
                              Text(
                                "No conversations found",
                                style: TextStyle(
                                  fontSize: 18,
                                  color: Colors.grey[600],
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                "Try a different search term",
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

                      return ListView.builder(
                        padding: const EdgeInsets.only(bottom: 20),
                        itemCount: filteredConversations.length,
                        itemBuilder: (context, index) {
                          final conversation = filteredConversations[index];
                          return _buildConversationTile(conversation);
                        },
                      );
                    }),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
