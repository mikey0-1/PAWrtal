import 'package:capstone_app/data/models/appointment_model.dart';
import 'package:capstone_app/data/models/clinic_model.dart';
import 'package:capstone_app/data/models/pet_model.dart';
import 'package:capstone_app/data/models/ratings_and_review_model.dart';
import 'package:capstone_app/data/repository/auth.repository.dart';
import 'package:capstone_app/utils/user_session_service.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:io';

/// Mobile Rating Dialog for submitting ratings and reviews
/// Shows after completed appointments

class MobileRatingDialog extends StatefulWidget {
  final Appointment appointment;
  final Clinic? clinic;
  final Pet? pet;

  const MobileRatingDialog({
    super.key,
    required this.appointment,
    this.clinic,
    this.pet,
  });

  @override
  State<MobileRatingDialog> createState() => _MobileRatingDialogState();
}

class _MobileRatingDialogState extends State<MobileRatingDialog> {
  double selectedRating = 0.0;
  final TextEditingController reviewController = TextEditingController();
  List<PlatformFile> selectedImages = [];
  bool isSubmitting = false;

  @override
  void dispose() {
    reviewController.dispose();
    super.dispose();
  }

  String _getRatingText(double rating) {
    if (rating >= 4.5) return 'Excellent';
    if (rating >= 3.5) return 'Very Good';
    if (rating >= 2.5) return 'Good';
    if (rating >= 1.5) return 'Fair';
    if (rating > 0) return 'Poor';
    return '';
  }

  Color _getRatingColor(double rating) {
    if (rating >= 4.5) return Colors.green;
    if (rating >= 3.5) return Colors.lightGreen;
    if (rating >= 2.5) return Colors.amber;
    if (rating >= 1.5) return Colors.orange;
    if (rating > 0) return Colors.red;
    return Colors.grey;
  }

  Future<void> _pickImages() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.image,
        allowMultiple: true,
        withData: true,
      );

      if (result != null && result.files.isNotEmpty) {
        List<PlatformFile> validFiles = [];
        List<String> rejectedFiles = [];

        for (var file in result.files) {
          // Check 5MB limit
          if (file.size <= 5 * 1024 * 1024) {
            validFiles.add(file);
          } else {
            rejectedFiles.add(file.name);
          }
        }

        if (rejectedFiles.isNotEmpty) {
          Get.snackbar(
            'File Size Limit',
            'Some files exceed 5MB and were not added:\n${rejectedFiles.join(", ")}',
            backgroundColor: Colors.orange.shade50,
            colorText: Colors.orange.shade700,
            duration: const Duration(seconds: 3),
            snackPosition: SnackPosition.BOTTOM,
          );
        }

        setState(() {
          selectedImages.addAll(validFiles);
          if (selectedImages.length > 5) {
            selectedImages = selectedImages.take(5).toList();
          }
        });
      }
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to pick images',
        backgroundColor: Colors.red.shade50,
        colorText: Colors.red.shade700,
      );
    }
  }

  void _removeImage(int index) {
    setState(() {
      selectedImages.removeAt(index);
    });
  }

  Future<void> _submitRating() async {
    if (selectedRating == 0) {
      Get.snackbar(
        'Rating Required',
        'Please select a rating before submitting',
        backgroundColor: Colors.orange.shade50,
        colorText: Colors.orange.shade700,
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }

    setState(() => isSubmitting = true);

    try {
      // Get user info
      final session = Get.find<UserSessionService>();
      final userName = session.userName;

      // Check if already reviewed
      final alreadyReviewed = await Get.find<AuthRepository>()
          .hasUserReviewedAppointment(widget.appointment.documentId!);

      if (alreadyReviewed) {
        Get.back();
        Get.snackbar(
          'Already Reviewed',
          'You have already reviewed this appointment.',
          backgroundColor: Colors.orange.shade50,
          colorText: Colors.orange.shade700,
          icon: const Icon(Icons.info, color: Colors.orange),
        );
        return;
      }

      // Upload images if any
      List<String> imageIds = [];
      if (selectedImages.isNotEmpty) {
        try {
          final uploadedFiles = await Get.find<AuthRepository>()
              .uploadReviewImages(selectedImages);
          imageIds = uploadedFiles.map((file) => file.$id).toList();
        } catch (e) {}
      }

      // Create review
      final review = RatingAndReview(
        userId: widget.appointment.userId,
        clinicId: widget.appointment.clinicId,
        appointmentId: widget.appointment.documentId!,
        rating: selectedRating,
        reviewText:
            reviewController.text.isNotEmpty ? reviewController.text : null,
        images: imageIds,
        userName: userName,
        petName: widget.pet?.name,
        serviceName: widget.appointment.service,
      );

      await Get.find<AuthRepository>().createRatingAndReview(review);

      // Close dialog
      Get.back(result: true);

      // Show success message
      Get.snackbar(
        'Review Submitted!',
        'Thank you for your feedback. Your ${selectedRating.toStringAsFixed(0)}-star review helps other pet owners.',
        backgroundColor: Colors.green.shade50,
        colorText: Colors.green.shade700,
        icon: const Icon(Icons.check_circle, color: Colors.green),
        duration: const Duration(seconds: 3),
        snackPosition: SnackPosition.BOTTOM,
      );
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to submit review: ${e.toString()}',
        backgroundColor: Colors.red.shade50,
        colorText: Colors.red.shade700,
        icon: const Icon(Icons.error, color: Colors.red),
      );
    } finally {
      setState(() => isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding: const EdgeInsets.all(16),
      child: Container(
        constraints: const BoxConstraints(maxHeight: 700),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.amber.shade50, Colors.orange.shade50],
                ),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(28),
                  topRight: Radius.circular(28),
                ),
              ),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                  ),
                  const Expanded(
                    child: Text(
                      'Rate & Review',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.amber.shade100,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.rate_review, color: Colors.amber),
                  ),
                ],
              ),
            ),

            // Content
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Appointment info card
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade50,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey.shade200),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.local_hospital,
                                  color: Colors.blue.shade600, size: 20),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  widget.clinic?.clinicName ?? 'Unknown Clinic',
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '${widget.appointment.service} • ${widget.pet?.name ?? widget.appointment.petId}',
                            style: TextStyle(
                                color: Colors.grey.shade700, fontSize: 14),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            DateFormat('MMM dd, yyyy')
                                .format(widget.appointment.dateTime),
                            style: TextStyle(
                                color: Colors.grey.shade600, fontSize: 12),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Rating section
                    const Text(
                      'How would you rate your experience?',
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 16),

                    // Star rating
                    Center(
                      child: Wrap(
                        spacing: 8,
                        children: List.generate(5, (index) {
                          final starValue = index + 1;
                          return GestureDetector(
                            onTap: () {
                              setState(() {
                                selectedRating = starValue.toDouble();
                              });
                            },
                            child: Icon(
                              selectedRating >= starValue
                                  ? Icons.star
                                  : Icons.star_border,
                              color: selectedRating >= starValue
                                  ? Colors.amber
                                  : Colors.grey.shade400,
                              size: 40,
                            ),
                          );
                        }),
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Rating slider
                    Slider(
                      value: selectedRating,
                      min: 0.0,
                      max: 5.0,
                      divisions: 5, 
                      activeColor: Colors.amber,
                      inactiveColor: Colors.grey.shade300,
                      label: selectedRating > 0
                          ? selectedRating.toStringAsFixed(0)
                          : null,
                      onChanged: (value) {
                        setState(() {
                          selectedRating =
                              value.roundToDouble(); 
                        });
                      },
                    ),

                    if (selectedRating > 0)
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            '${selectedRating.toStringAsFixed(0)} stars',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey.shade600,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Text(
                            _getRatingText(selectedRating),
                            style: TextStyle(
                              fontSize: 14,
                              color: _getRatingColor(selectedRating),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),

                    const SizedBox(height: 24),

                    // Review text
                    const Text(
                      'Share your experience (Optional)',
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 12),

                    TextField(
                      controller: reviewController,
                      maxLines: 4,
                      maxLength: 500,
                      decoration: InputDecoration(
                        hintText:
                            'Tell us about your visit, the service quality, staff friendliness, etc...',
                        hintStyle: TextStyle(color: Colors.grey.shade500),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        counterStyle: TextStyle(color: Colors.grey.shade500),
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Photos section
                    const Text(
                      'Add Photos (Optional)',
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 12),

                    InkWell(
                      onTap: selectedImages.length < 5 ? _pickImages : null,
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          border:
                              Border.all(color: Colors.grey.shade300, width: 2),
                          borderRadius: BorderRadius.circular(12),
                          color: Colors.grey.shade50,
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.add_photo_alternate,
                                color: Colors.grey.shade600),
                            const SizedBox(width: 8),
                            Text(
                              selectedImages.isEmpty
                                  ? 'Add photos (up to 5, max 5MB each)'
                                  : '${selectedImages.length} photo${selectedImages.length > 1 ? 's' : ''} selected',
                              style: TextStyle(
                                color: Colors.grey.shade700,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    if (selectedImages.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      SizedBox(
                        height: 100,
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          itemCount: selectedImages.length,
                          itemBuilder: (context, index) {
                            final file = selectedImages[index];
                            return Stack(
                              children: [
                                Container(
                                  margin: const EdgeInsets.only(right: 8),
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(8),
                                    child: file.bytes != null
                                        ? Image.memory(
                                            file.bytes!,
                                            width: 100,
                                            height: 100,
                                            fit: BoxFit.cover,
                                          )
                                        : file.path != null
                                            ? Image.file(
                                                File(file.path!),
                                                width: 100,
                                                height: 100,
                                                fit: BoxFit.cover,
                                              )
                                            : Container(
                                                width: 100,
                                                height: 100,
                                                color: Colors.grey.shade200,
                                                child: const Icon(Icons.image),
                                              ),
                                  ),
                                ),
                                Positioned(
                                  top: 4,
                                  right: 12,
                                  child: GestureDetector(
                                    onTap: () => _removeImage(index),
                                    child: Container(
                                      padding: const EdgeInsets.all(4),
                                      decoration: const BoxDecoration(
                                        color: Colors.red,
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Icon(
                                        Icons.close,
                                        color: Colors.white,
                                        size: 16,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            );
                          },
                        ),
                      ),
                    ],

                    const SizedBox(height: 24),

                    // Submit button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: isSubmitting || selectedRating == 0
                            ? null
                            : _submitRating,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: selectedRating > 0
                              ? Colors.amber
                              : Colors.grey.shade300,
                          foregroundColor: selectedRating > 0
                              ? Colors.white
                              : Colors.grey.shade500,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: isSubmitting
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                      Colors.white),
                                ),
                              )
                            : Text(
                                selectedRating > 0
                                    ? 'Submit Review'
                                    : 'Select a Rating',
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
