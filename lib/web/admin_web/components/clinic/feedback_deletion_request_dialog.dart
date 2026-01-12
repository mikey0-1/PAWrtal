import 'package:flutter/material.dart';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:get/get.dart';
import 'package:capstone_app/data/repository/auth.repository.dart';

class FeedbackDeletionRequestDialog extends StatefulWidget {
  final String reviewId;
  final String clinicId;
  final String userId;
  final String appointmentId;
  final String requestedBy; // Admin/Staff user ID
  final Function(Map<String, dynamic>) onSuccess;
  final Function(String)? onError;

  const FeedbackDeletionRequestDialog({
    Key? key,
    required this.reviewId,
    required this.clinicId,
    required this.userId,
    required this.appointmentId,
    required this.requestedBy,
    required this.onSuccess,
    this.onError,
  }) : super(key: key);

  @override
  State<FeedbackDeletionRequestDialog> createState() =>
      _FeedbackDeletionRequestDialogState();
}

class _FeedbackDeletionRequestDialogState
    extends State<FeedbackDeletionRequestDialog> {
  final _formKey = GlobalKey<FormState>();
  final _additionalDetailsController = TextEditingController();

  String? _selectedReason;
  List<PlatformFile> _selectedFiles = [];
  bool _isSubmitting = false;
  String? _errorMessage;

  final List<String> _reasons = [
    'User is not telling the truth',
    'Feedback is a troll',
    'Contains offensive content',
    'Irrelevant to the service',
    'Duplicate feedback',
    'Violates community guidelines',
    'Others',
  ];

  @override
  void dispose() {
    _additionalDetailsController.dispose();
    super.dispose();
  }

  bool get _hasProgress {
    return _selectedReason != null ||
        _additionalDetailsController.text.trim().isNotEmpty ||
        _selectedFiles.isNotEmpty;
  }

  bool _isMobileLayout(double screenWidth) {
    return screenWidth <= 600;
  }

  double _getDialogWidth(double screenWidth) {
    if (_isMobileLayout(screenWidth)) {
      return screenWidth * 0.9;
    }
    return 600;
  }

  double _getDialogMaxHeight(double screenWidth) {
    if (_isMobileLayout(screenWidth)) {
      return double.infinity;
    }
    return 800;
  }

  double _getGridCrossAxisCount(double screenWidth) {
    if (_isMobileLayout(screenWidth)) {
      return 2;
    }
    return 3;
  }

  Future<bool> _confirmClose() async {
    if (!_hasProgress || _isSubmitting) return true;

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Discard Changes?'),
        content: const Text(
          'You have unsaved changes. Are you sure you want to close without submitting?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Discard'),
          ),
        ],
      ),
    );

    return result ?? false;
  }

  Future<void> _pickFiles() async {
    if (_selectedFiles.length >= 5) {
      setState(() {
        _errorMessage = 'Maximum 5 files allowed';
      });
      return;
    }

    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.image,
        allowMultiple: true,
        withData: true,
      );

      if (result != null) {
        final validFiles = result.files.where((file) {
          final extension = file.extension?.toLowerCase();
          return extension == 'jpg' ||
              extension == 'jpeg' ||
              extension == 'png';
        }).toList();

        if (validFiles.length != result.files.length) {
          setState(() {
            _errorMessage = 'Only JPG and PNG files are allowed';
          });
        } else {
          setState(() {
            _errorMessage = null;
          });
        }

        setState(() {
          final remainingSlots = 5 - _selectedFiles.length;
          _selectedFiles.addAll(validFiles.take(remainingSlots));
        });

        if (_selectedFiles.length >= 5) {
          setState(() {
            _errorMessage = 'Maximum 5 files reached';
          });
        }
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Error picking files: $e';
      });
    }
  }

  void _removeFile(int index) {
    setState(() {
      _selectedFiles.removeAt(index);
      if (_errorMessage != null &&
          (_errorMessage!.contains('Maximum') ||
              _errorMessage!.contains('files'))) {
        _errorMessage = null;
      }
    });
  }

  bool _validateForm() {
    if (_selectedReason == null) {
      setState(() {
        _errorMessage = 'Please select a reason for the deletion request';
      });
      return false;
    }

    if (_selectedReason == 'Others' &&
        _additionalDetailsController.text.trim().isEmpty) {
      setState(() {
        _errorMessage =
            'Additional details are required when selecting "Others"';
      });
      return false;
    }

    setState(() {
      _errorMessage = null;
    });
    return true;
  }

  Future<void> _confirmAndSubmit() async {
    if (!_validateForm()) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Submission'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Are you sure you want to submit this deletion request?',
              style: TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Reason: ',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      Expanded(child: Text(_selectedReason!)),
                    ],
                  ),
                  if (_additionalDetailsController.text.trim().isNotEmpty) ...[
                    const SizedBox(height: 8),
                    const Text(
                      'Details: ',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    Text(
                      _additionalDetailsController.text.trim(),
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                  if (_selectedFiles.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text(
                      'Attachments: ${_selectedFiles.length} file(s)',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'This request will be reviewed by the super admin.',
              style: TextStyle(fontSize: 13, color: Colors.black54),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Submit'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await _submitRequest();
    }
  }

  Future<void> _submitRequest() async {
    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
    });

    try {
      final authRepo = Get.find<AuthRepository>();


      List<String> uploadedFileIds = [];
      if (_selectedFiles.isNotEmpty) {
        try {
          final uploadedFiles =
              await authRepo.uploadFeedbackDeletionAttachments(_selectedFiles);
          uploadedFileIds = uploadedFiles.map((f) => f.$id).toList();
        } catch (e) {
          throw Exception('Failed to upload files: $e');
        }
      }

      final requestDoc = await authRepo.createFeedbackDeletionRequest(
        reviewId: widget.reviewId,
        clinicId: widget.clinicId,
        userId: widget.userId,
        appointmentId: widget.appointmentId,
        requestedBy: widget.requestedBy,
        reason: _selectedReason!,
        additionalDetails: _additionalDetailsController.text.trim().isEmpty
            ? null
            : _additionalDetailsController.text.trim(),
        attachmentIds: uploadedFileIds,
      );


      if (mounted) {
        Navigator.of(context).pop();

        widget.onSuccess({
          'success': true,
          'requestId': requestDoc.$id,
          'message': 'Deletion request submitted successfully',
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Deletion request submitted successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {

      if (mounted) {
        setState(() {
          _errorMessage = 'Failed to submit request: $e';
          _isSubmitting = false;
        });

        widget.onError?.call(e.toString());
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final isMobile = _isMobileLayout(screenWidth);
    final dialogWidth = _getDialogWidth(screenWidth);
    final dialogMaxHeight = _getDialogMaxHeight(screenWidth);
    final gridCrossAxisCount = _getGridCrossAxisCount(screenWidth).toInt();

    return WillPopScope(
      onWillPop: _confirmClose,
      child: Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(isMobile ? 12 : 16),
        ),
        insetPadding: EdgeInsets.all(isMobile ? 12 : 20),
        child: Container(
          width: dialogWidth,
          constraints: BoxConstraints(
            maxHeight: isMobile ? screenHeight * 0.9 : dialogMaxHeight,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header
              Container(
                padding: EdgeInsets.all(isMobile ? 12 : 20),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(isMobile ? 12 : 16),
                    topRight: Radius.circular(isMobile ? 12 : 16),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(Icons.report_problem,
                        color: Colors.red.shade700, size: isMobile ? 24 : 28),
                    SizedBox(width: isMobile ? 8 : 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Request Feedback Deletion',
                            style: TextStyle(
                              fontSize: isMobile ? 16 : 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(height: isMobile ? 2 : 4),
                          Text(
                            'Submit a request to archive this review',
                            style: TextStyle(
                              fontSize: isMobile ? 12 : 14,
                              color: Colors.black54,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: Icon(Icons.close, size: isMobile ? 20 : 24),
                      onPressed: _isSubmitting
                          ? null
                          : () async {
                              final canClose = await _confirmClose();
                              if (canClose && mounted) {
                                Navigator.of(context).pop();
                              }
                            },
                      padding: EdgeInsets.all(isMobile ? 4 : 8),
                    ),
                  ],
                ),
              ),

              // Error Message Banner
              if (_errorMessage != null)
                Container(
                  width: double.infinity,
                  padding: EdgeInsets.all(isMobile ? 8 : 12),
                  color: Colors.red.shade50,
                  child: Row(
                    children: [
                      Icon(Icons.error_outline,
                          color: Colors.red.shade700, size: isMobile ? 18 : 20),
                      SizedBox(width: isMobile ? 6 : 8),
                      Expanded(
                        child: Text(
                          _errorMessage!,
                          style: TextStyle(
                            color: Colors.red.shade700,
                            fontSize: isMobile ? 12 : 13,
                          ),
                        ),
                      ),
                      IconButton(
                        icon: Icon(Icons.close, size: isMobile ? 16 : 18),
                        onPressed: () {
                          setState(() {
                            _errorMessage = null;
                          });
                        },
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                    ],
                  ),
                ),

              // Content
              Flexible(
                child: SingleChildScrollView(
                  padding: EdgeInsets.all(isMobile ? 16 : 24),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Reason Selection
                        Row(
                          children: [
                            Text(
                              'Reason for Deletion',
                              style: TextStyle(
                                fontSize: isMobile ? 14 : 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            SizedBox(width: isMobile ? 2 : 4),
                            Text(
                              '*',
                              style: TextStyle(
                                fontSize: isMobile ? 14 : 16,
                                fontWeight: FontWeight.w600,
                                color: Colors.red.shade700,
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: isMobile ? 6 : 8),
                        Text(
                          'Select the primary reason for requesting this feedback to be archived',
                          style: TextStyle(
                            fontSize: isMobile ? 12 : 13,
                            color: Colors.black54,
                          ),
                        ),
                        SizedBox(height: isMobile ? 8 : 12),
                        Container(
                          decoration: BoxDecoration(
                            border: Border.all(
                              color: _errorMessage != null &&
                                      _errorMessage!.contains('reason')
                                  ? Colors.red.shade300
                                  : Colors.grey.shade300,
                            ),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Column(
                            children: _reasons.map((reason) {
                              final isSelected = _selectedReason == reason;
                              return InkWell(
                                onTap: _isSubmitting
                                    ? null
                                    : () {
                                        setState(() {
                                          _selectedReason = reason;
                                          if (_errorMessage != null &&
                                              _errorMessage!
                                                  .contains('reason')) {
                                            _errorMessage = null;
                                          }
                                        });
                                      },
                                child: Container(
                                  padding: EdgeInsets.symmetric(
                                    horizontal: isMobile ? 12 : 16,
                                    vertical: isMobile ? 10 : 12,
                                  ),
                                  decoration: BoxDecoration(
                                    color: isSelected
                                        ? Colors.red.shade50
                                        : Colors.transparent,
                                    border: Border(
                                      bottom: reason != _reasons.last
                                          ? BorderSide(
                                              color: Colors.grey.shade200,
                                            )
                                          : BorderSide.none,
                                    ),
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(
                                        isSelected
                                            ? Icons.radio_button_checked
                                            : Icons.radio_button_unchecked,
                                        color: isSelected
                                            ? Colors.red.shade700
                                            : Colors.grey,
                                        size: isMobile ? 18 : 20,
                                      ),
                                      SizedBox(width: isMobile ? 10 : 12),
                                      Expanded(
                                        child: Text(
                                          reason,
                                          style: TextStyle(
                                            fontSize: isMobile ? 13 : 14,
                                            fontWeight: isSelected
                                                ? FontWeight.w600
                                                : FontWeight.normal,
                                            color: isSelected
                                                ? Colors.red.shade700
                                                : Colors.black87,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                        ),

                        // Additional Details
                        SizedBox(height: isMobile ? 16 : 20),
                        Row(
                          children: [
                            Text(
                              'Additional Details',
                              style: TextStyle(
                                fontSize: isMobile ? 14 : 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            SizedBox(width: isMobile ? 2 : 4),
                            if (_selectedReason == 'Others')
                              Text(
                                '*',
                                style: TextStyle(
                                  fontSize: isMobile ? 14 : 16,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.red.shade700,
                                ),
                              )
                            else
                              Text(
                                '(optional)',
                                style: TextStyle(
                                  fontSize: isMobile ? 11 : 13,
                                  color: Colors.grey.shade600,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                          ],
                        ),
                        SizedBox(height: isMobile ? 6 : 8),
                        Text(
                          _selectedReason == 'Others'
                              ? 'Please provide specific details about why this feedback should be deleted'
                              : 'Provide additional context or supporting information (optional)',
                          style: TextStyle(
                            fontSize: isMobile ? 12 : 13,
                            color: Colors.black54,
                          ),
                        ),
                        SizedBox(height: isMobile ? 8 : 12),
                        TextFormField(
                          controller: _additionalDetailsController,
                          enabled: !_isSubmitting,
                          maxLines: isMobile ? 3 : 4,
                          maxLength: 1000,
                          onChanged: (value) {
                            if (_errorMessage != null &&
                                _errorMessage!.contains('Additional details')) {
                              setState(() {
                                _errorMessage = null;
                              });
                            }
                          },
                          style: TextStyle(fontSize: isMobile ? 12 : 14),
                          decoration: InputDecoration(
                            hintText: 'Enter additional details...',
                            hintStyle: TextStyle(fontSize: isMobile ? 12 : 14),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: BorderSide(
                                color: _errorMessage != null &&
                                        _errorMessage!
                                            .contains('Additional details')
                                    ? Colors.red
                                    : Colors.grey.shade300,
                              ),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: BorderSide(
                                color: _errorMessage != null &&
                                        _errorMessage!
                                            .contains('Additional details')
                                    ? Colors.red.shade300
                                    : Colors.grey.shade300,
                              ),
                            ),
                            filled: true,
                            fillColor: Colors.grey.shade50,
                            contentPadding: EdgeInsets.symmetric(
                              horizontal: isMobile ? 10 : 12,
                              vertical: isMobile ? 8 : 10,
                            ),
                          ),
                        ),

                        // File Attachments Section
                        SizedBox(height: isMobile ? 16 : 20),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Supporting Evidence',
                                  style: TextStyle(
                                    fontSize: isMobile ? 14 : 16,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                SizedBox(height: isMobile ? 2 : 4),
                                Text(
                                  'Upload images (JPG/PNG only, max 5)',
                                  style: TextStyle(
                                    fontSize: isMobile ? 11 : 13,
                                    color: Colors.black54,
                                  ),
                                ),
                              ],
                            ),
                            OutlinedButton.icon(
                              onPressed:
                                  _isSubmitting || _selectedFiles.length >= 5
                                      ? null
                                      : _pickFiles,
                              icon: Icon(Icons.add_photo_alternate,
                                  size: isMobile ? 18 : 20),
                              label: Text(
                                'Add Images',
                                style: TextStyle(
                                  fontSize: isMobile ? 12 : 14,
                                ),
                              ),
                              style: OutlinedButton.styleFrom(
                                padding: EdgeInsets.symmetric(
                                  horizontal: isMobile ? 8 : 12,
                                  vertical: isMobile ? 8 : 10,
                                ),
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: isMobile ? 8 : 12),

                        // File Preview Grid
                        if (_selectedFiles.isNotEmpty)
                          GridView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            gridDelegate:
                                SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: gridCrossAxisCount,
                              crossAxisSpacing: isMobile ? 6 : 8,
                              mainAxisSpacing: isMobile ? 6 : 8,
                            ),
                            itemCount: _selectedFiles.length,
                            itemBuilder: (context, index) {
                              final file = _selectedFiles[index];
                              return Stack(
                                children: [
                                  Container(
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(
                                        color: Colors.grey.shade300,
                                      ),
                                    ),
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(8),
                                      child: file.bytes != null
                                          ? Image.memory(
                                              file.bytes!,
                                              fit: BoxFit.cover,
                                            )
                                          : file.path != null
                                              ? Image.file(
                                                  File(file.path!),
                                                  fit: BoxFit.cover,
                                                )
                                              : Center(
                                                  child: Icon(
                                                    Icons.image,
                                                    color: Colors.grey.shade400,
                                                  ),
                                                ),
                                    ),
                                  ),
                                  Positioned(
                                    top: 4,
                                    right: 4,
                                    child: CircleAvatar(
                                      radius: isMobile ? 12 : 14,
                                      backgroundColor: Colors.red,
                                      child: IconButton(
                                        padding: EdgeInsets.zero,
                                        icon: Icon(
                                          Icons.close,
                                          size: isMobile ? 14 : 16,
                                          color: Colors.white,
                                        ),
                                        onPressed: _isSubmitting
                                            ? null
                                            : () => _removeFile(index),
                                      ),
                                    ),
                                  ),
                                ],
                              );
                            },
                          )
                        else
                          Container(
                            height: isMobile ? 100 : 120,
                            decoration: BoxDecoration(
                              color: Colors.grey.shade50,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: Colors.grey.shade300,
                              ),
                            ),
                            child: Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.image_outlined,
                                    size: isMobile ? 32 : 40,
                                    color: Colors.grey.shade400,
                                  ),
                                  SizedBox(height: isMobile ? 6 : 8),
                                  Text(
                                    'No images selected',
                                    style: TextStyle(
                                      color: Colors.grey.shade600,
                                      fontSize: isMobile ? 12 : 14,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),

                        SizedBox(height: isMobile ? 16 : 20),
                      ],
                    ),
                  ),
                ),
              ),

              // Footer Actions
              Container(
                padding: EdgeInsets.all(isMobile ? 12 : 20),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  border: Border(
                    top: BorderSide(color: Colors.grey.shade200),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: _isSubmitting
                          ? null
                          : () async {
                              final canClose = await _confirmClose();
                              if (canClose && mounted) {
                                Navigator.of(context).pop();
                              }
                            },
                      child: Text(
                        'Cancel',
                        style: TextStyle(fontSize: isMobile ? 12 : 14),
                      ),
                    ),
                    SizedBox(width: isMobile ? 8 : 12),
                    ElevatedButton.icon(
                      onPressed: _isSubmitting ? null : _confirmAndSubmit,
                      icon: _isSubmitting
                          ? SizedBox(
                              width: isMobile ? 14 : 16,
                              height: isMobile ? 14 : 16,
                              child: const CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor:
                                    AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            )
                          : Icon(Icons.send, size: isMobile ? 16 : 18),
                      label: Text(
                        _isSubmitting ? 'Submitting...' : 'Submit Request',
                        style: TextStyle(fontSize: isMobile ? 12 : 14),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white,
                        padding: EdgeInsets.symmetric(
                          horizontal: isMobile ? 16 : 24,
                          vertical: isMobile ? 8 : 12,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
