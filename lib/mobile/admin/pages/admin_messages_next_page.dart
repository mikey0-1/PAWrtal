import 'package:capstone_app/mobile/admin/controllers/admin_messaging_controller.dart';
import 'package:capstone_app/data/models/conversation_model.dart';
import 'package:capstone_app/data/models/message_model.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class AdminMessagesNextPage extends StatefulWidget {
  final Conversation conversation;
  final String receiverId;
  final String receiverType;
  final String receiverName;
  final String receiverEmail;

  const AdminMessagesNextPage({
    super.key,
    required this.conversation,
    required this.receiverId,
    required this.receiverType,
    required this.receiverName,
    required this.receiverEmail,
  });

  @override
  State<AdminMessagesNextPage> createState() => _AdminMessagesNextPageState();
}

class _AdminMessagesNextPageState extends State<AdminMessagesNextPage> {
  final AdminMessagingController _messagingController = Get.find<AdminMessagingController>();

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(70),
        child: Padding(
          padding: const EdgeInsets.only(top: 5),
          child: AppBar(
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
                    CircleAvatar(
                      radius: 20,
                      backgroundColor: const Color.fromARGB(255, 81, 115, 153),
                      child: Text(
                        widget.receiverName.isNotEmpty 
                            ? widget.receiverName[0].toUpperCase()
                            : '?',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    // Online status indicator
                    Obx(() {
                      final status = _messagingController.getUserStatus(widget.receiverId);
                      if (status?.isOnline == true) {
                        return Positioned(
                          bottom: 0,
                          right: 0,
                          child: Container(
                            width: 12,
                            height: 12,
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
                      Obx(() {
                        final status = _messagingController.getUserStatus(widget.receiverId);
                        return Text(
                          status?.statusText ?? 'Offline',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        );
                      }),
                    ],
                  ),
                ),
              ],
            ),
            actions: [
              IconButton(
                icon: const Icon(
                  Icons.call_rounded,
                  size: 24,
                ),
                onPressed: () {
                  // Implement call functionality
                },
              ),
              IconButton(
                icon: const Icon(
                  Icons.info_outline,
                  size: 24,
                ),
                onPressed: () {
                  _showUserInfoDialog();
                },
              ),
            ],
          ),
        ),
      ),
      body: Column(
        children: [
          // Messages
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
                reverse: true, // This makes newest messages appear at bottom
                itemCount: _messagingController.currentMessages.length,
                itemBuilder: (context, index) {
                  // Reverse the index to show messages in correct order
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
          Text(
            "Send a message to ${widget.receiverName}",
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
            // Attachment button
            IconButton(
              icon: Icon(
                Icons.attach_file,
                color: Colors.grey[600],
              ),
              onPressed: () {
                // Implement attachment functionality
              },
            ),
            
            // Photo button
            IconButton(
              icon: Icon(
                Icons.photo,
                color: Colors.grey[600],
              ),
              onPressed: () {
                // Implement photo picker functionality
              },
            ),
            
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

  void _showUserInfoDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('User Information'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.person, color: Colors.grey),
                const SizedBox(width: 8),
                Text('Name: ${widget.receiverName}'),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.email, color: Colors.grey),
                const SizedBox(width: 8),
                Expanded(child: Text('Email: ${widget.receiverEmail}')),
              ],
            ),
            const SizedBox(height: 16),
            Obx(() {
              final status = _messagingController.getUserStatus(widget.receiverId);
              return Row(
                children: [
                  Icon(
                    status?.isOnline == true ? Icons.circle : Icons.circle_outlined,
                    color: status?.isOnline == true ? Colors.green : Colors.grey,
                    size: 16,
                  ),
                  const SizedBox(width: 8),
                  Text('Status: ${status?.statusText ?? 'Unknown'}'),
                ],
              );
            }),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}