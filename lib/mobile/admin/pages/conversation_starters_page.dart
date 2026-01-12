import 'package:capstone_app/mobile/admin/controllers/admin_messaging_controller.dart';
import 'package:capstone_app/data/models/conversation_starter_model.dart';
import 'package:capstone_app/utils/snackbar_helper.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class ConversationStartersPage extends StatefulWidget {
  const ConversationStartersPage({super.key});

  @override
  State<ConversationStartersPage> createState() =>
      _ConversationStartersPageState();
}

class _ConversationStartersPageState extends State<ConversationStartersPage> {
  final AdminMessagingController _controller =
      Get.find<AdminMessagingController>();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text('Conversation Starters'),
        backgroundColor: const Color.fromARGB(255, 81, 115, 153),
        foregroundColor: Colors.white,
      ),
      body: Obx(() {
        if (_controller.isLoadingStarters.value) {
          return const Center(
            child: CircularProgressIndicator(
              color: Color.fromARGB(255, 81, 115, 153),
            ),
          );
        }

        if (_controller.conversationStarters.isEmpty) {
          return _buildEmptyState();
        }

        return Column(
          children: [
            // Auto-reply info banner
            Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color.fromARGB(255, 81, 115, 153).withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: const Color.fromARGB(255, 81, 115, 153),
                  width: 1,
                ),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.info_outline,
                    color: Color.fromARGB(255, 81, 115, 153),
                    size: 24,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Auto-Reply for First Messages',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Color.fromARGB(255, 81, 115, 153),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Select one starter to automatically reply when users message your clinic for the first time.',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[700],
                          ),
                        ),
                        const SizedBox(height: 8),
                        Obx(() {
                          final autoReply = _controller.getAutoReplyStarter();
                          if (autoReply != null) {
                            return Row(
                              children: [
                                const Icon(
                                  Icons.check_circle,
                                  color: Colors.green,
                                  size: 16,
                                ),
                                const SizedBox(width: 6),
                                Expanded(
                                  child: Text(
                                    'Active: "${autoReply.triggerText}"',
                                    style: const TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.green,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            );
                          } else {
                            return Row(
                              children: [
                                Icon(
                                  Icons.warning_amber_rounded,
                                  color: Colors.orange[700],
                                  size: 16,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  'No auto-reply configured',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.orange[700],
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            );
                          }
                        }),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: _controller.conversationStarters.length,
                itemBuilder: (context, index) {
                  final starter = _controller.conversationStarters[index];
                  return _buildStarterCard(starter);
                },
              ),
            ),
          ],
        );
      }),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddEditDialog(),
        backgroundColor: const Color.fromARGB(255, 81, 115, 153),
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('Add Starter', style: TextStyle(color: Colors.white)),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.auto_awesome, size: 80, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            'No Conversation Starters',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.grey[700],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Create starters to help users quickly\nbegin conversations',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey[600]),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () => _showAddEditDialog(),
            icon: const Icon(Icons.add),
            label: const Text('Create First Starter'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color.fromARGB(255, 81, 115, 153),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStarterCard(ConversationStarter starter) {
    // CRITICAL FIX: Ensure isAutoReply is never null
    final isAutoReply = starter.isAutoReply == true;
    final isActive = starter.isActive == true;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                // Radio button for auto-reply selection
                Radio<bool>(
                  value: true,
                  groupValue: isAutoReply, // Now guaranteed to be bool
                  onChanged: (value) {
                    if (value == true) {
                      _showAutoReplyConfirmation(starter);
                    }
                  },
                  activeColor: const Color.fromARGB(255, 81, 115, 153),
                ),
                Tooltip(
                  message: 'Set as auto-reply for first messages',
                  child: Icon(
                    Icons.auto_awesome,
                    size: 20,
                    color: isAutoReply
                        ? const Color.fromARGB(255, 81, 115, 153)
                        : Colors.grey[400],
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: _getCategoryColor(starter.category),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    starter.categoryDisplayName,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const Spacer(),
                Switch(
                  value: isActive, // Now guaranteed to be bool
                  onChanged: (value) {
                    _controller.toggleStarterStatus(starter);
                  },
                  activeColor: const Color.fromARGB(255, 81, 115, 153),
                ),
                IconButton(
                  icon: const Icon(Icons.edit,
                      color: Color.fromARGB(255, 81, 115, 153)),
                  onPressed: () => _showAddEditDialog(starter: starter),
                ),
                IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red),
                  onPressed: () => _confirmDelete(starter),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              starter.triggerText,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              starter.responseText,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[700],
              ),
            ),
            // Show auto-reply indicator
            if (isAutoReply) ...[
              const SizedBox(height: 8),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color:
                      const Color.fromARGB(255, 81, 115, 153).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: const Color.fromARGB(255, 81, 115, 153),
                    width: 1,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.auto_awesome,
                      size: 16,
                      color: Color.fromARGB(255, 81, 115, 153),
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      'Active auto-reply for first messages',
                      style: TextStyle(
                        fontSize: 12,
                        color: Color.fromARGB(255, 81, 115, 153),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Color _getCategoryColor(String category) {
    switch (category) {
      case 'appointment':
        return Colors.blue;
      case 'services':
        return Colors.green;
      case 'emergency':
        return Colors.red;
      case 'general':
      default:
        return Colors.grey;
    }
  }

  void _showAutoReplyConfirmation(ConversationStarter starter) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            const Icon(
              Icons.auto_awesome,
              color: Color.fromARGB(255, 81, 115, 153),
            ),
            const SizedBox(width: 8),
            const Expanded(
              child: Text('Set Auto-Reply'),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'This message will be automatically sent when a user messages your clinic for the first time.',
              style: TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Auto-Reply Message:',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey[700],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    starter.responseText,
                    style: const TextStyle(fontSize: 13),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Note: This will replace any existing auto-reply.',
              style: TextStyle(
                fontSize: 12,
                color: Colors.orange[700],
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              _controller.setAutoReplyStarter(starter.documentId!);
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color.fromARGB(255, 81, 115, 153),
              foregroundColor: Colors.white,
            ),
            child: const Text('Set Auto-Reply'),
          ),
        ],
      ),
    );
  }

  void _showAddEditDialog({ConversationStarter? starter}) {
    final isEdit = starter != null;
    final triggerController =
        TextEditingController(text: starter?.triggerText ?? '');
    final responseController =
        TextEditingController(text: starter?.responseText ?? '');
    final selectedCategory = (starter?.category ?? 'general').obs;

    showDialog(
      context: context,
      builder: (context) => Dialog(
        child: Container(
          width: MediaQuery.of(context).size.width * 0.9,
          constraints: const BoxConstraints(maxWidth: 600),
          padding: const EdgeInsets.all(24),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isEdit
                      ? 'Edit Conversation Starter'
                      : 'Add Conversation Starter',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 24),

                // Category Selector
                const Text(
                  'Category',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                Obx(() => DropdownButtonFormField<String>(
                      value: selectedCategory.value,
                      decoration: InputDecoration(
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 8),
                      ),
                      items: _controller.categories
                          .map((category) => DropdownMenuItem(
                                value: category,
                                child: Text(category[0].toUpperCase() +
                                    category.substring(1)),
                              ))
                          .toList(),
                      onChanged: (value) {
                        if (value != null) selectedCategory.value = value;
                      },
                    )),
                const SizedBox(height: 16),

                // Trigger Text
                const Text(
                  'Trigger Text',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: triggerController,
                  maxLines: 3,
                  decoration: InputDecoration(
                    hintText:
                        'What users will click on (e.g., "Book an appointment")',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    contentPadding: const EdgeInsets.all(12),
                  ),
                ),
                const SizedBox(height: 16),

                // Response Text
                const Text(
                  'Response Text',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: responseController,
                  maxLines: 5,
                  decoration: InputDecoration(
                    hintText: 'Automated response message that will be sent',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    contentPadding: const EdgeInsets.all(12),
                  ),
                ),
                const SizedBox(height: 24),

                // Action Buttons
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Cancel'),
                    ),
                    const SizedBox(width: 12),
                    ElevatedButton(
                      onPressed: () {
                        if (triggerController.text.trim().isEmpty ||
                            responseController.text.trim().isEmpty) {
                          SnackbarHelper.showError(
                            context: context,
                            title: "Error",
                            message: "Please fill in all fields",
                          );
                          return;
                        }

                        if (isEdit) {
                          final updatedStarter = starter.copyWith(
                            triggerText: triggerController.text.trim(),
                            responseText: responseController.text.trim(),
                            category: selectedCategory.value,
                          );
                          _controller.updateConversationStarter(updatedStarter);
                        } else {
                          _controller.starterTriggerController.text =
                              triggerController.text.trim();
                          _controller.starterResponseController.text =
                              responseController.text.trim();
                          _controller.selectedCategory.value =
                              selectedCategory.value;
                          _controller.addConversationStarter();
                        }

                        Navigator.pop(context);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor:
                            const Color.fromARGB(255, 81, 115, 153),
                        foregroundColor: Colors.white,
                      ),
                      child: Text(isEdit ? 'Update' : 'Add'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _confirmDelete(ConversationStarter starter) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Starter'),
        content:
            Text('Are you sure you want to delete "${starter.triggerText}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              _controller.deleteConversationStarter(starter.documentId!);
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}
