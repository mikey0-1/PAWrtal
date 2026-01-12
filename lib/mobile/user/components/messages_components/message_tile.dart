import 'package:capstone_app/mobile/user/pages/messages_next_page.dart';
import 'package:capstone_app/data/models/conversation_model.dart';
import 'package:capstone_app/data/repository/auth.repository.dart';
import 'package:capstone_app/data/models/clinic_model.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class MyMessageTile extends StatelessWidget {
  final Conversation conversation;
  
  const MyMessageTile({
    super.key,
    required this.conversation,
  });

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<String, dynamic>>(
      future: _getConversationData(),
      builder: (context, snapshot) {
        final data = snapshot.data ?? {
          'name': 'Loading...',
          'image': '',
          'isOnline': false,
        };

        final hasUnreadMessages = conversation.userUnreadCount > 0;

        return InkWell(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => MessagesNextPage(
                  conversation: conversation,
                  receiverId: conversation.clinicId,
                  receiverType: 'clinic',
                  receiverName: data['name'],
                  receiverImage: data['image'],
                ),
              ),
            );
          },
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
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
                    ClipRRect(
                      borderRadius: BorderRadius.circular(25),
                      child: data['image'].isNotEmpty
                          ? Image.network(
                              data['image'],
                              height: 50,
                              width: 50,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                return _buildDefaultAvatar(data['name']);
                              },
                            )
                          : _buildDefaultAvatar(data['name']),
                    ),
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
                          Expanded(
                            child: Text(
                              data['name'],
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (conversation.lastMessageTime != null) ...[
                            const SizedBox(width: 8),
                            Text(
                              conversation.timeAgo,
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 6),
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
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (hasUnreadMessages) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
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

  Widget _buildDefaultAvatar(String name) {
    return Container(
      height: 50,
      width: 50,
      decoration: BoxDecoration(
        color: const Color.fromARGB(255, 81, 115, 153),
        borderRadius: BorderRadius.circular(25),
      ),
      child: Center(
        child: Text(
          name.isNotEmpty ? name[0].toUpperCase() : '?',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Future<Map<String, dynamic>> _getConversationData() async {
    try {
      final AuthRepository authRepository = Get.find<AuthRepository>();
      final clinicDoc = await authRepository.getClinicById(conversation.clinicId);
      
      if (clinicDoc != null) {
        final clinic = Clinic.fromMap(clinicDoc.data);
        return {
          'name': clinic.clinicName,
          'image': clinic.image,
          'isOnline': false,
        };
      }
    } catch (e) {
    }

    return {
      'name': 'Unknown Clinic',
      'image': '',
      'isOnline': false,
    };
  }
}