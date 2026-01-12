import 'package:capstone_app/mobile/user/controllers/user_messaging_controller.dart';
import 'package:capstone_app/data/models/conversation_model.dart';
import 'package:capstone_app/data/models/message_model.dart';
import 'package:capstone_app/data/models/conversation_starter_model.dart';
import 'package:capstone_app/utils/appwrite_constant.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:capstone_app/web/dimensions.dart';

class MessagesNextPage extends StatefulWidget {
  final Conversation conversation;
  final String receiverId;
  final String receiverType;
  final String receiverName;
  final String receiverImage;
  final String? receiverProfilePictureId;

  const MessagesNextPage({
    super.key,
    required this.conversation,
    required this.receiverId,
    required this.receiverType,
    required this.receiverName,
    required this.receiverImage,
    this.receiverProfilePictureId,
  });

  @override
  State<MessagesNextPage> createState() => _MessagesNextPageState();
}

class _MessagesNextPageState extends State<MessagesNextPage> {
  final MessagingController _messagingController = Get.find<MessagingController>();
  bool _showStarters = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _messagingController.openConversation(
        widget.conversation,
        widget.receiverId,
        widget.receiverType,
      );
    });
  }

  String _getProfileImageUrl(String profilePictureId) {
    return '${AppwriteConstants.endPoint}/storage/buckets/${AppwriteConstants.imageBucketID}/files/$profilePictureId/view?project=${AppwriteConstants.projectID}';
  }

  Widget _buildProfileImage(double size) {
    final profilePictureId = widget.receiverProfilePictureId ?? '';
    final fallbackImage = widget.receiverImage;
    final clinicName = widget.receiverName;

    if (profilePictureId.isNotEmpty) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(size / 2),
        child: Image.network(
          _getProfileImageUrl(profilePictureId),
          height: size,
          width: size,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            // Fallback to regular image if profile picture fails
            return fallbackImage.isNotEmpty
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(size / 2),
                    child: Image.network(
                      fallbackImage,
                      height: size,
                      width: size,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return _buildDefaultAvatar(clinicName, size);
                      },
                    ),
                  )
                : _buildDefaultAvatar(clinicName, size);
          },
        ),
      );
    } else if (fallbackImage.isNotEmpty) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(size / 2),
        child: Image.network(
          fallbackImage,
          height: size,
          width: size,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            return _buildDefaultAvatar(clinicName, size);
          },
        ),
      );
    } else {
      return _buildDefaultAvatar(clinicName, size);
    }
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
            fontWeight: FontWeight.bold,
            fontSize: size * 0.4,
          ),
        ),
      ),
    );
  }

  String _getLayoutType(double width) {
  if (width < mobileWidth) {
    return 'mobile';
  } else if (width < tabletWidth) {
    return 'tablet';
  } else {
    return 'desktop';
  }
}

@override
Widget build(BuildContext context) {
  return LayoutBuilder(
    builder: (context, constraints) {
      final currentLayout = _getLayoutType(constraints.maxWidth);
      
      // If we're no longer on mobile, preserve state and pop back
      if (currentLayout != 'mobile') {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted && Navigator.of(context).canPop()) {
            // Preserve the conversation state before popping
            _messagingController.preserveConversationForTransition();
            Navigator.of(context).pop();
          }
        });
      }
      
      return Scaffold(
        backgroundColor: Colors.white,
        appBar: PreferredSize(
          preferredSize: const Size.fromHeight(70),
          child: Padding(
            padding: const EdgeInsets.only(top: 5),
            child: AppBar(
              elevation: 0,
              scrolledUnderElevation: 0,
              backgroundColor: Colors.white,
              leading: IconButton(
                icon: const Icon(
                  Icons.keyboard_arrow_left_rounded,
                  size: 30,
                ),
                onPressed: () {
                  Navigator.pop(context);
                },
              ),
              title: Row(
                children: [
                  Stack(
                    children: [
                      _buildProfileImage(40),
                      // Online status indicator
                      // Obx(() {
                      //   final status = _messagingController.getUserStatus(widget.receiverId);
                      //   if (status?.isOnline == true) {
                      //     return Positioned(
                      //       bottom: 0,
                      //       right: 0,
                      //       child: Container(
                      //         width: 12,
                      //         height: 12,
                      //         decoration: BoxDecoration(
                      //           color: Colors.green,
                      //           shape: BoxShape.circle,
                      //           border: Border.all(color: Colors.white, width: 2),
                      //         ),
                      //       ),
                      //     );
                      //   }
                      //   return const SizedBox.shrink();
                      // }),
                    ],
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.receiverName,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        // Obx(() {
                        //   final status = _messagingController.getUserStatus(widget.receiverId);
                        //   return Text(
                        //     status?.statusText ?? 'Offline',
                        //     style: TextStyle(
                        //       fontSize: 12,
                        //       color: Colors.grey[600],
                        //     ),
                        //   );
                        // }),
                      ],
                    ),
                  ),
                ],
              ),
              actions: [
                if (widget.receiverType == 'clinic')
                  IconButton(
                    icon: const Icon(
                      Icons.auto_awesome_rounded,
                      size: 24,
                    ),
                    onPressed: () {
                      setState(() {
                        _showStarters = !_showStarters;
                      });
                    },
                  ),
              ],
            ),
          ),
        ),
        body: Column(
          children: [
            // Conversation Starters
            if (_showStarters && widget.receiverType == 'clinic')
              Container(
                height: 120,
                color: Colors.grey[50],
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Obx(() {
                  if (_messagingController.conversationStarters.isEmpty) {
                    return const Center(
                      child: Text(
                        'No conversation starters available',
                        style: TextStyle(color: Colors.grey),
                      ),
                    );
                  }
                  
                  return ListView.builder(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: _messagingController.conversationStarters.length,
                    itemBuilder: (context, index) {
                      final starter = _messagingController.conversationStarters[index];
                      return _buildConversationStarter(starter);
                    },
                  );
                }),
              ),
            
            // Messages with Reverse ListView
            Expanded(
              child: Obx(() {
                if (_messagingController.isLoadingConversation.value) {
                  return const Center(
                    child: CircularProgressIndicator(
                      color: Color.fromARGB(255, 81, 115, 153),
                    ),
                  );
                }

                if (_messagingController.currentMessages.isEmpty) {
                  return _buildEmptyMessageState();
                }

                return ListView.builder(
                  controller: _messagingController.scrollController,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  reverse: true,
                  itemCount: _messagingController.currentMessages.length,
                  itemBuilder: (context, index) {
                    final reversedIndex = _messagingController.currentMessages.length - 1 - index;
                    final message = _messagingController.currentMessages[reversedIndex];
                    return _buildMessageBubble(message);
                  },
                );
              }),
            ),
            
            // Message Input
            _buildMessageInput(),
          ],
        ),
      );
    },
  );
}

  Widget _buildConversationStarter(ConversationStarter starter) {
    return Container(
      margin: const EdgeInsets.only(right: 8),
      child: InkWell(
        onTap: () {
          _messagingController.sendStarterMessage(starter);
          setState(() {
            _showStarters = false;
          });
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          constraints: const BoxConstraints(maxWidth: 200),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color.fromARGB(255, 81, 115, 153), width: 1),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.2),
                spreadRadius: 1,
                blurRadius: 2,
                offset: const Offset(0, 1),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: const Color.fromARGB(255, 81, 115, 153).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      starter.categoryDisplayName,
                      style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: Color.fromARGB(255, 81, 115, 153),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                starter.triggerText,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyMessageState() {
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
            "Start a conversation",
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          if (widget.receiverType == 'clinic')
            Text(
              "Use the sparkle button above to see\nconversation starters",
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

  Widget _buildMessageBubble(Message message) {
    final isCurrentUser = _messagingController.isCurrentUser(message.senderId);
    final isStarterMessage = message.isStarterMessage;
    
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: isCurrentUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isCurrentUser) ...[
            CircleAvatar(
              radius: 12,
              backgroundColor: const Color.fromARGB(255, 81, 115, 153),
              child: Text(
                widget.receiverName[0].toUpperCase(),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(width: 8),
          ],
          
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: isCurrentUser 
                    ? const Color.fromARGB(255, 81, 115, 153)
                    : isStarterMessage 
                        ? Colors.blue[50] 
                        : Colors.grey[200],
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(16),
                  topRight: const Radius.circular(16),
                  bottomLeft: Radius.circular(isCurrentUser ? 16 : 4),
                  bottomRight: Radius.circular(isCurrentUser ? 4 : 16),
                ),
                border: isStarterMessage 
                    ? Border.all(color: Colors.blue[200]!, width: 1)
                    : null,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (isStarterMessage)
                    Container(
                      margin: const EdgeInsets.only(bottom: 6),
                      child: Text(
                        "Auto-response",
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: Colors.blue[700],
                        ),
                      ),
                    ),
                  Text(
                    message.messageText,
                    style: TextStyle(
                      color: isCurrentUser ? Colors.white : Colors.black87,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        message.timeFormatted,
                        style: TextStyle(
                          color: isCurrentUser 
                              ? Colors.white.withOpacity(0.8) 
                              : Colors.grey[600],
                          fontSize: 11,
                        ),
                      ),
                      if (isCurrentUser && message.isRead) ...[
                        const SizedBox(width: 4),
                        Icon(
                          Icons.done_all,
                          size: 12,
                          color: Colors.white.withOpacity(0.8),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ),
          
          if (isCurrentUser) const SizedBox(width: 8),
        ],
      ),
    );
  }

  Widget _buildMessageInput() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.2),
            spreadRadius: 1,
            blurRadius: 3,
            offset: const Offset(0, -1),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            // Camera button
            // IconButton(
            //   icon: Icon(
            //     Icons.camera_alt_rounded,
            //     color: Colors.grey[600],
            //   ),
            //   onPressed: () {
            //     // Implement camera functionality
            //   },
            // ),
            
            // // Photo button
            // IconButton(
            //   icon: Icon(
            //     Icons.photo,
            //     color: Colors.grey[600],
            //   ),
            //   onPressed: () {
            //     // Implement photo picker functionality
            //   },
            // ),
            
            // Message input
            Expanded(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(24),
                  color: Colors.grey.shade200,
                ),
                child: TextField(
                  controller: _messagingController.messageController,
                  decoration: const InputDecoration(
                    hintText: "Type a message...",
                    border: InputBorder.none,
                  ),
                  maxLines: null,
                  onSubmitted: (value) {
                    if (value.trim().isNotEmpty) {
                      _messagingController.sendMessage();
                    }
                  },
                ),
              ),
            ),
            
            const SizedBox(width: 8),
            
            // Send button
            Obx(() => CircleAvatar(
              backgroundColor: const Color.fromARGB(255, 81, 115, 153),
              child: IconButton(
                icon: _messagingController.isSendingMessage.value
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : const Icon(
                        Icons.send_rounded,
                        color: Colors.white,
                        size: 20,
                      ),
                onPressed: _messagingController.isSendingMessage.value 
                    ? null 
                    : () {
                        if (_messagingController.messageController.text.trim().isNotEmpty) {
                          _messagingController.sendMessage();
                        }
                      },
              ),
            )),
          ],
        ),
      ),
    );
  }
  
}