import 'package:capstone_app/data/models/conversation_model.dart';
import 'package:flutter/material.dart';

class AdminMessageTile extends StatelessWidget {
  final Conversation conversation;
  final Map<String, dynamic> userData;
  final VoidCallback onTap;

  const AdminMessageTile({
    super.key,
    required this.conversation,
    required this.userData,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    // Use clinicUnreadCount for admin side
    final hasUnreadMessages = conversation.clinicUnreadCount > 0;
    
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.all(16),
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
                // User Avatar with Status
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
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    // Online status indicator
                    if (userData['isOnline'] == true)
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
                const SizedBox(width: 16),
                
                // Conversation Details
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // User name and timestamp
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              userData['name'].isNotEmpty 
                                  ? userData['name'] 
                                  : 'Unknown User',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.black87,
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
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ],
                      ),
                      
                      const SizedBox(height: 4),
                      
                      // Contact info (if available)
                      if (userData['email'].isNotEmpty)
                        Text(
                          userData['email'],
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      
                      const SizedBox(height: 6),
                      
                      // Last message and unread indicator
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
                          
                          // Unread count badge
                          if (hasUnreadMessages) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8, 
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: const Color.fromARGB(255, 81, 115, 153),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                conversation.clinicUnreadCount > 99 
                                    ? '99+' 
                                    : conversation.clinicUnreadCount.toString(),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
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
                
                // Chevron icon
                Icon(
                  Icons.chevron_right,
                  color: Colors.grey[400],
                  size: 20,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}