import 'package:capstone_app/data/models/ratings_and_review_model.dart';
import 'package:capstone_app/data/repository/auth.repository.dart';
import 'package:capstone_app/web/dimensions.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'feedback_deletion_request_dialog.dart';

Widget buildStarRating(double rating, {double size = 30}) {
  return Row(
    mainAxisSize: MainAxisSize.min,
    children: List.generate(5, (index) {
      double starFill = (rating - index).clamp(0.0, 1.0);
      return Stack(
        children: [
          Icon(Icons.star_border_rounded, size: size, color: Colors.amber),
          ClipRect(
            clipper: _StarClipper(starFill),
            child: Icon(Icons.star_rounded, size: size, color: Colors.amber),
          ),
        ],
      );
    }),
  );
}

class _StarClipper extends CustomClipper<Rect> {
  final double fillPercentage;
  _StarClipper(this.fillPercentage);

  @override
  Rect getClip(Size size) {
    return Rect.fromLTRB(0, 0, size.width * fillPercentage, size.height);
  }

  @override
  bool shouldReclip(_StarClipper oldClipper) {
    return oldClipper.fillPercentage != fillPercentage;
  }
}

class AdminRatingsAndReviews extends StatefulWidget {
  final GlobalKey? reviewsEndKey;
  final String clinicId;

  const AdminRatingsAndReviews({
    super.key,
    this.reviewsEndKey,
    required this.clinicId,
  });

  @override
  State<AdminRatingsAndReviews> createState() => _AdminRatingsAndReviewsState();
}


 bool _isMobile(BuildContext context) {
  return MediaQuery.of(context).size.width < mobileWidth;
}

bool _isTablet(BuildContext context) {
  return MediaQuery.of(context).size.width >= mobileWidth && 
         MediaQuery.of(context).size.width < tabletWidth;
}
class _AdminRatingsAndReviewsState extends State<AdminRatingsAndReviews> {
  final AuthRepository _authRepo = Get.find<AuthRepository>();
  List<RatingAndReview> reviews = [];
  ClinicRatingStats? stats;
  bool isLoading = true;
  String searchQuery = '';
  final TextEditingController _controller = TextEditingController();
  bool _showClear = false;

  @override
  void initState() {
    super.initState();
    _loadReviews();
    _controller.addListener(() {
      setState(() {
        _showClear = _controller.text.isNotEmpty;
        searchQuery = _controller.text.toLowerCase();
      });
    });
  }

  Future<void> _loadReviews() async {
    setState(() => isLoading = true);

    try {
      final fetchedReviews = await _authRepo.getClinicReviews(widget.clinicId);
      final fetchedStats =
          await _authRepo.getClinicRatingStats(widget.clinicId);

      setState(() {
        reviews = fetchedReviews;
        stats = fetchedStats;
        isLoading = false;
      });
    } catch (e) {
      setState(() => isLoading = false);
    }
  }

  List<RatingAndReview> get filteredReviews {
    if (searchQuery.isEmpty) return reviews;

    return reviews.where((review) {
      final userName = review.userName.toLowerCase();
      final reviewText = (review.reviewText ?? '').toLowerCase();
      final service = review.serviceName.toLowerCase();

      return userName.contains(searchQuery) ||
          reviewText.contains(searchQuery) ||
          service.contains(searchQuery);
    }).toList();
  }

  double calculateAverageRating() {
    if (reviews.isEmpty) return 0;
    return stats?.averageRating ?? 0;
  }

  Map<int, double> calculateRatingPercentages() {
    if (stats == null) {
      return {1: 0, 2: 0, 3: 0, 4: 0, 5: 0};
    }

    final total = stats!.totalReviews;
    if (total == 0) return {1: 0, 2: 0, 3: 0, 4: 0, 5: 0};

    return {
      1: (stats!.ratingDistribution[1] ?? 0) / total,
      2: (stats!.ratingDistribution[2] ?? 0) / total,
      3: (stats!.ratingDistribution[3] ?? 0) / total,
      4: (stats!.ratingDistribution[4] ?? 0) / total,
      5: (stats!.ratingDistribution[5] ?? 0) / total,
    };
  }

  double responsiveDialogWidth(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;
    if (screenWidth >= tabletWidth) {
      return 1020;
    } else {
      return screenWidth * 0.9;
    }
  }

  void _showDeletionRequestDialog(RatingAndReview review) {
    // Get the current admin/staff user ID from GetStorage
    final GetStorage storage = GetStorage();
    final String requestedBy = storage.read('userId') ?? 'unknown';

    showDialog(
      context: context,
      barrierDismissible: false, // Prevent closing without saving
      builder: (context) => FeedbackDeletionRequestDialog(
        reviewId: review.documentId!,
        clinicId: widget.clinicId,
        userId: review.userId,
        appointmentId: review.appointmentId,
        requestedBy: requestedBy, // The admin/staff user ID making the request
        onSuccess: (result) {

          // Refresh the reviews list
          _loadReviews();

          // Optional: Show success message to user
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content:
                    Text(result['message'] ?? 'Deletion request submitted'),
                backgroundColor: Colors.green,
                duration: const Duration(seconds: 3),
              ),
            );
          }
        },
        onError: (error) {

          // Show error to user
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Error: $error'),
                backgroundColor: Colors.red,
                duration: const Duration(seconds: 3),
              ),
            );
          }
        },
      ),
    );
  }

  @override
Widget build(BuildContext context) {
  final isMobile = _isMobile(context);
  final isTablet = _isTablet(context);

  if (isLoading) {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(40),
        child: CircularProgressIndicator(),
      ),
    );
  }

  double averageRating = calculateAverageRating();
  Map<int, double> ratingPercentages = calculateRatingPercentages();
  final displayReviews = filteredReviews.take(5).toList();

  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      // Header - Responsive
      Row(
        children: [
          Expanded(
            child: Text(
              "Ratings & Reviews",
              style: TextStyle(
                fontSize: isMobile ? 18 : 22,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          if (reviews.isNotEmpty)
            Row(
              children: [
                Text(
                  "${averageRating.toStringAsFixed(1)} / 5",
                  style: TextStyle(
                    fontSize: isMobile ? 16 : 20,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Icon(
                  Icons.star_rate_rounded,
                  color: Colors.amber,
                  size: isMobile ? 24 : 34,
                )
              ],
            ),
        ],
      ),
      
      if (reviews.isEmpty)
        _buildNoReviews(isMobile)
      else ...[
        const SizedBox(height: 16),
        
        // Rating Distribution - Make it compact on mobile
        Container(
          padding: EdgeInsets.all(isMobile ? 12 : 16),
          decoration: BoxDecoration(
            color: Colors.grey.shade50,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: Column(
            children: (ratingPercentages.entries.toList()
                  ..sort((a, b) => b.key.compareTo(a.key)))
                .map((entry) {
              return Padding(
                padding: EdgeInsets.symmetric(vertical: isMobile ? 3 : 4),
                child: Row(
                  children: [
                    Text(
                      entry.key.toString(),
                      style: TextStyle(
                        fontSize: isMobile ? 12 : 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    SizedBox(width: isMobile ? 6 : 8),
                    Icon(
                      Icons.star,
                      size: isMobile ? 12 : 16,
                      color: Colors.amber,
                    ),
                    SizedBox(width: isMobile ? 6 : 8),
                    Expanded(
                      child: Stack(
                        children: [
                          Container(
                            height: isMobile ? 6 : 8,
                            decoration: BoxDecoration(
                              color: Colors.grey[300],
                              borderRadius: BorderRadius.circular(isMobile ? 3 : 4),
                            ),
                          ),
                          FractionallySizedBox(
                            widthFactor: entry.value,
                            child: Container(
                              height: isMobile ? 6 : 8,
                              decoration: BoxDecoration(
                                color: Colors.black,
                                borderRadius: BorderRadius.circular(isMobile ? 3 : 4),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(width: isMobile ? 6 : 8),
                    SizedBox(
                      width: isMobile ? 30 : 40,
                      child: Text(
                        '${(entry.value * 100).toInt()}%',
                        style: TextStyle(
                          fontSize: isMobile ? 11 : 14,
                          color: Colors.grey[600],
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ),
        
        SizedBox(height: isMobile ? 16 : 24),
        
        // Reviews List
        ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: displayReviews.length,
          separatorBuilder: (context, index) => SizedBox(height: isMobile ? 16 : 24),
          itemBuilder: (context, index) {
            return _buildReviewCard(displayReviews[index], isMobile);
          },
        ),
      ],
      
      SizedBox(height: isMobile ? 24 : 32),
      
      if (reviews.isNotEmpty)
        GestureDetector(
          onTap: () => _showAllReviewsDialog(averageRating, ratingPercentages),
          child: Container(
            padding: EdgeInsets.symmetric(
              horizontal: isMobile ? 16 : 18,
              vertical: isMobile ? 10 : 8,
            ),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.black, width: isMobile ? 1.5 : 1),
            ),
            key: widget.reviewsEndKey,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  "Show all ${reviews.length} reviews",
                  style: TextStyle(
                    fontSize: isMobile ? 14 : 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                SizedBox(width: isMobile ? 6 : 8),
                Icon(
                  Icons.arrow_forward_rounded,
                  size: isMobile ? 18 : 20,
                ),
              ],
            ),
          ),
        )
    ],
  );
}

      Widget _buildNoReviews(bool isMobile) {
      return Container(
        margin: EdgeInsets.symmetric(vertical: isMobile ? 24 : 40),
        padding: EdgeInsets.all(isMobile ? 32 : 48),
        decoration: BoxDecoration(
          color: Colors.grey.shade50,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Center(
          child: Column(
            children: [
              Icon(
                Icons.rate_review_outlined,
                size: isMobile ? 48 : 64,
                color: Colors.grey.shade400,
              ),
              SizedBox(height: isMobile ? 12 : 16),
              Text(
                'No reviews yet',
                style: TextStyle(
                  fontSize: isMobile ? 16 : 18,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey.shade700,
                ),
              ),
              SizedBox(height: isMobile ? 6 : 8),
              Text(
                'Be the first to review this clinic!',
                style: TextStyle(
                  fontSize: isMobile ? 12 : 14,
                  color: Colors.grey.shade600,
                ),
              ),
            ],
          ),
        ),
      );
    }

  Widget _buildReviewCard(RatingAndReview review, bool isMobile) {
    
      return FutureBuilder<bool>(
      future: _authRepo.appWriteProvider.hasReviewPendingDeletionRequest(
        review.documentId!,
      ),
      builder: (context, snapshot) {
        final hasPendingRequest = snapshot.data ?? false;

        return Container(
          padding: EdgeInsets.all(isMobile ? 16 : 20),
          decoration: BoxDecoration(
            color: hasPendingRequest ? Colors.orange.shade50 : Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: hasPendingRequest
                  ? Colors.orange.shade300
                  : Colors.grey.shade200,
              width: hasPendingRequest ? 2 : 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Pending deletion banner
              if (hasPendingRequest) ...[
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: isMobile ? 8 : 12,
                    vertical: isMobile ? 6 : 8,
                  ),
                  margin: EdgeInsets.only(bottom: isMobile ? 10 : 12),
                  decoration: BoxDecoration(
                    color: Colors.orange.shade100,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.orange.shade300),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.pending_outlined,
                        size: isMobile ? 16 : 18,
                        color: Colors.orange.shade800,
                      ),
                      SizedBox(width: isMobile ? 6 : 8),
                      Expanded(
                        child: Text(
                          isMobile 
                              ? 'Deletion pending'
                              : 'Deletion request pending approval',
                          style: TextStyle(
                            fontSize: isMobile ? 11 : 13,
                            fontWeight: FontWeight.w600,
                            color: Colors.orange.shade800,
                          ),
                        ),
                      ),
                      Icon(
                        Icons.hourglass_empty,
                        size: isMobile ? 14 : 16,
                        color: Colors.orange.shade700,
                      ),
                    ],
                  ),
                ),
              ],

              // Review header
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CircleAvatar(
                    radius: isMobile ? 20 : 24,
                    backgroundColor:
                        const Color.fromARGB(255, 81, 115, 153).withOpacity(0.1),
                    child: Text(
                      review.userName[0].toUpperCase(),
                      style: TextStyle(
                        color: const Color.fromARGB(255, 81, 115, 153),
                        fontWeight: FontWeight.bold,
                        fontSize: isMobile ? 16 : 18,
                      ),
                    ),
                  ),
                  SizedBox(width: isMobile ? 10 : 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          review.userName,
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: isMobile ? 14 : 16,
                          ),
                        ),
                        SizedBox(height: isMobile ? 2 : 4),
                        buildStarRating(review.rating, size: isMobile ? 16 : 20),
                        SizedBox(height: isMobile ? 6 : 8),
                        // Service badge
                        Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: isMobile ? 8 : 10,
                            vertical: isMobile ? 4 : 6,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade100,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            '${review.serviceName}${review.petName != null ? ' • ${review.petName}' : ''}',
                            style: TextStyle(
                              fontSize: isMobile ? 11 : 12,
                              color: Colors.grey.shade700,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (!isMobile) ...[
                    SizedBox(width: isMobile ? 6 : 8),
                    Tooltip(
                      message: hasPendingRequest
                          ? 'Deletion request already pending'
                          : 'Request deletion',
                      child: IconButton(
                        icon: Icon(
                          hasPendingRequest
                              ? Icons.hourglass_empty
                              : Icons.delete_outline,
                          color: hasPendingRequest
                              ? Colors.orange.shade600
                              : Colors.red.shade600,
                          size: 20,
                        ),
                        onPressed: hasPendingRequest
                            ? null
                            : () => _showDeletionRequestDialog(review),
                      ),
                    ),
                  ],
                ],
              ),
              SizedBox(height: isMobile ? 6 : 8),

              // Time ago
              Text(
                review.getTimeAgo(),
                style: TextStyle(
                  fontSize: isMobile ? 11 : 12,
                  color: Colors.grey.shade600,
                ),
              ),

              // Review text
              if (review.hasReview) ...[
                SizedBox(height: isMobile ? 8 : 12),
                Text(
                  review.reviewText!,
                  style: TextStyle(
                    fontSize: isMobile ? 13 : 14,
                    height: 1.4,
                  ),
                  maxLines: isMobile ? null : 3,
                  overflow: isMobile ? TextOverflow.visible : TextOverflow.ellipsis,
                ),
              ],

              // Review images
              if (review.hasImages) ...[
                SizedBox(height: isMobile ? 10 : 12),
                SizedBox(
                  height: isMobile ? 80 : 80,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: isMobile
                        ? review.images.length
                        : (review.images.length > 3 ? 3 : review.images.length),
                    itemBuilder: (context, index) {
                      final imageUrl = _authRepo.getImageUrl(review.images[index]);
                      return Container(
                        margin: EdgeInsets.only(right: isMobile ? 6 : 8),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.network(
                            imageUrl,
                            width: isMobile ? 80 : 80,
                            height: isMobile ? 80 : 80,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return Container(
                                width: isMobile ? 80 : 80,
                                height: isMobile ? 80 : 80,
                                color: Colors.grey.shade200,
                                child: Icon(
                                  Icons.image_not_supported,
                                  size: isMobile ? 20 : 24,
                                ),
                              );
                            },
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],

              // Mobile delete button
              if (isMobile) ...[
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: hasPendingRequest
                        ? null
                        : () => _showDeletionRequestDialog(review),
                    icon: Icon(
                      hasPendingRequest
                          ? Icons.hourglass_empty
                          : Icons.delete_outline,
                      size: 18,
                    ),
                    label: Text(
                      hasPendingRequest
                          ? 'Deletion Pending'
                          : 'Request Deletion',
                      style: const TextStyle(fontSize: 13),
                    ),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: hasPendingRequest
                          ? Colors.orange.shade600
                          : Colors.red.shade600,
                      side: BorderSide(
                        color: hasPendingRequest
                            ? Colors.orange.shade300
                            : Colors.red.shade300,
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
}

  Widget _buildReviewImages(List<String> imageIds) {
    return SizedBox(
      height: 80,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: imageIds.length > 3 ? 3 : imageIds.length,
        itemBuilder: (context, index) {
          final imageUrl = _authRepo.getImageUrl(imageIds[index]);

          return Container(
            margin: const EdgeInsets.only(right: 8),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.network(
                imageUrl,
                width: 80,
                height: 80,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    width: 80,
                    height: 80,
                    color: Colors.grey.shade200,
                    child: const Icon(Icons.image_not_supported),
                  );
                },
              ),
            ),
          );
        },
      ),
    );
  }

  void _showAllReviewsDialog(
    double averageRating, Map<int, double> ratingPercentages) {
  final isMobile = _isMobile(context);
  final isTablet = _isTablet(context);
  
  showDialog(
    context: context,
    builder: (BuildContext context) {
      return Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        insetPadding: EdgeInsets.symmetric(
          vertical: isMobile ? 40 : 60,
          horizontal: isMobile ? 16 : 40,
        ),
        child: Container(
          width: isMobile
              ? MediaQuery.of(context).size.width - 32
              : (isTablet ? 800 : 1020),
          height: isMobile ? MediaQuery.of(context).size.height - 80 : 700,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
          ),
          clipBehavior: Clip.hardEdge,
          child: Column(
            children: [
              // Header
              Container(
                padding: EdgeInsets.all(isMobile ? 12 : 16),
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(color: Colors.grey.shade300),
                  ),
                ),
                child: Row(
                  children: [
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close_rounded, size: 24),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                    SizedBox(width: isMobile ? 12 : 16),
                    Expanded(
                      child: Text(
                        'All Reviews',
                        style: TextStyle(
                          fontSize: isMobile ? 18 : 20,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Content
              Expanded(
                child: isMobile
                    ? _buildMobileDialogContent(
                        averageRating,
                        ratingPercentages,
                      )
                    : _buildDesktopDialogContent(
                        averageRating,
                        ratingPercentages,
                      ),
              ),
            ],
          ),
        ),
      );
    },
  );
}

Widget _buildFullReviewCard(RatingAndReview review, bool isMobile) {
  return FutureBuilder<bool>(
    future: _authRepo.appWriteProvider.hasReviewPendingDeletionRequest(
      review.documentId!,
    ),
    builder: (context, snapshot) {
      final hasPendingRequest = snapshot.data ?? false;

      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: hasPendingRequest ? Colors.orange.shade50 : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: hasPendingRequest
                ? Colors.orange.shade300
                : Colors.grey.shade200,
            width: hasPendingRequest ? 2 : 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Pending deletion banner
            if (hasPendingRequest) ...[
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: Colors.orange.shade100,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.orange.shade300),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.pending_outlined,
                      size: 18,
                      color: Colors.orange.shade800,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Deletion request pending approval by super admin',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: Colors.orange.shade800,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            // Review header
            Row(
              children: [
                CircleAvatar(
                  radius: 24,
                  backgroundColor:
                      const Color.fromARGB(255, 81, 115, 153).withOpacity(0.1),
                  child: Text(
                    review.userName[0].toUpperCase(),
                    style: const TextStyle(
                      color: Color.fromARGB(255, 81, 115, 153),
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            review.userName,
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                      Text(
                        review.getTimeAgo(),
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
                buildStarRating(review.rating, size: 20),
                const SizedBox(width: 8),
                Tooltip(
                  message: hasPendingRequest
                      ? 'Deletion request already pending'
                      : 'Request deletion',
                  child: IconButton(
                    icon: Icon(
                      hasPendingRequest
                          ? Icons.hourglass_empty
                          : Icons.delete_outline,
                      color: hasPendingRequest
                          ? Colors.orange.shade600
                          : Colors.red.shade600,
                      size: 20,
                    ),
                    onPressed: hasPendingRequest
                        ? null
                        : () {
                            _showDeletionRequestDialog(review);
                          },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Service badge
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                '${review.serviceName}${review.petName != null ? ' • ${review.petName}' : ''}',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade700,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),

            // Review text
            if (review.hasReview) ...[
              const SizedBox(height: 12),
              Text(
                review.reviewText!,
                style: const TextStyle(
                  fontSize: 14,
                  height: 1.5,
                ),
              ),
            ],

            // Review images
            if (review.hasImages) ...[
              const SizedBox(height: 12),
              SizedBox(
                height: 100,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: review.images.length,
                  itemBuilder: (context, index) {
                    final imageUrl = _authRepo.getImageUrl(review.images[index]);

                    return Container(
                      margin: const EdgeInsets.only(right: 8),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.network(
                          imageUrl,
                          width: 100,
                          height: 100,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              width: 100,
                              height: 100,
                              color: Colors.grey.shade200,
                              child: const Icon(Icons.image_not_supported),
                            );
                          },
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ],
        ),
      );
    },
  );
}

Widget _buildMobileDialogContent(
  double averageRating,
  Map<int, double> ratingPercentages,
) {
  return SingleChildScrollView(
    child: Column(
      children: [
        // Statistics section
        Container(
          padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
          decoration: BoxDecoration(
            color: Colors.grey.shade50,
            border: Border(
              bottom: BorderSide(color: Colors.grey.shade300),
            ),
          ),
          child: Column(
            children: [
              Text(
                averageRating.toStringAsFixed(1),
                style: const TextStyle(
                  fontSize: 36,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              buildStarRating(averageRating, size: 20),
              const SizedBox(height: 8),
              Text(
                "${reviews.length} reviews",
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 16),
              // Rating bars
              ...((ratingPercentages.entries.toList()
                    ..sort((a, b) => b.key.compareTo(a.key)))
                  .map((entry) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 3),
                  child: Row(
                    children: [
                      Text(
                        entry.key.toString(),
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(width: 6),
                      const Icon(Icons.star, size: 12, color: Colors.amber),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Stack(
                          children: [
                            Container(
                              height: 6,
                              decoration: BoxDecoration(
                                color: Colors.grey[300],
                                borderRadius: BorderRadius.circular(3),
                              ),
                            ),
                            FractionallySizedBox(
                              widthFactor: entry.value,
                              child: Container(
                                height: 6,
                                decoration: BoxDecoration(
                                  color: Colors.black,
                                  borderRadius: BorderRadius.circular(3),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 6),
                      SizedBox(
                        width: 35,
                        child: Text(
                          '${(entry.value * 100).toInt()}%',
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey[600],
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              })),
            ],
          ),
        ),

        // Search bar
        Padding(
          padding: const EdgeInsets.all(16),
          child: TextField(
            controller: _controller,
            decoration: InputDecoration(
              hintText: 'Search reviews',
              hintStyle: const TextStyle(fontSize: 14),
              prefixIcon: const Icon(Icons.search_rounded),
              suffixIcon: _showClear
                  ? IconButton(
                      icon: const Icon(Icons.close_rounded),
                      onPressed: () {
                        _controller.clear();
                        setState(() {
                          _showClear = false;
                          searchQuery = '';
                        });
                      },
                    )
                  : null,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Colors.black, width: 1.5),
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 12,
              ),
            ),
          ),
        ),

        // Reviews list
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: filteredReviews.length,
            separatorBuilder: (_, __) => const SizedBox(height: 16),
            itemBuilder: (context, index) {
              return _buildFullReviewCard(filteredReviews[index], true);
            },
          ),
        ),
        const SizedBox(height: 20),
      ],
    ),
  );
}

Widget _buildDesktopDialogContent(
  double averageRating,
  Map<int, double> ratingPercentages,
) {
  return Padding(
    padding: const EdgeInsets.only(left: 16, right: 16),
    child: Row(
      children: [
        // Left side - Statistics
        Flexible(
          flex: 2,
          child: Padding(
            padding: const EdgeInsets.only(left: 42, top: 16),
            child: Column(
              children: [
                Text(
                  averageRating.toStringAsFixed(1),
                  style: const TextStyle(
                    fontSize: 48,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 28),
                buildStarRating(averageRating),
                const SizedBox(height: 28),
                const SizedBox(
                  width: 300,
                  child: Divider(height: 1, thickness: 0.5),
                ),
                const SizedBox(height: 28),
                Text(
                  "${reviews.length} reviews",
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 28),
                const SizedBox(
                  width: 300,
                  child: Divider(height: 1, thickness: 0.5),
                ),
                const SizedBox(height: 28),
                const Text(
                  "Overall Rating",
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
                SizedBox(
                  height: 200,
                  width: 300,
                  child: Padding(
                    padding: const EdgeInsets.only(top: 16.0),
                    child: Column(
                      children: (ratingPercentages.entries.toList()
                            ..sort((a, b) => b.key.compareTo(a.key)))
                          .map((entry) {
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          child: Row(
                            children: [
                              Text(
                                entry.key.toString(),
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Stack(
                                  children: [
                                    Container(
                                      height: 8,
                                      decoration: BoxDecoration(
                                        color: Colors.grey[300],
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                    ),
                                    FractionallySizedBox(
                                      widthFactor: entry.value,
                                      child: Container(
                                        height: 8,
                                        decoration: BoxDecoration(
                                          color: Colors.black,
                                          borderRadius: BorderRadius.circular(4),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),

        const SizedBox(width: 32),

        // Right side - Reviews list
        Flexible(
          flex: 3,
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.only(bottom: 32, top: 16),
                child: SizedBox(
                  width: 525,
                  height: 50,
                  child: TextField(
                    controller: _controller,
                    decoration: InputDecoration(
                      hintText: 'Search reviews',
                      hintStyle: const TextStyle(fontSize: 14),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(15),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(15),
                        borderSide: const BorderSide(
                          color: Colors.black,
                          width: 1.5,
                        ),
                      ),
                      suffixIcon: _showClear
                          ? IconButton(
                              icon: const Icon(Icons.close_rounded),
                              onPressed: () {
                                _controller.clear();
                                setState(() {
                                  _showClear = false;
                                  searchQuery = '';
                                });
                              },
                            )
                          : const Icon(Icons.search_rounded),
                    ),
                  ),
                ),
              ),
              const SizedBox(
                width: 600,
                child: Divider(height: 1, thickness: 0.5),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: SizedBox(
                    width: 610,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 40),
                      child: ListView.separated(
                        itemCount: filteredReviews.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 24),
                        itemBuilder: (context, index) {
                          return _buildFullReviewCard(
                            filteredReviews[index],
                            false,
                          );
                        },
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 30),
            ],
          ),
        ),
      ],
    ),
  );
}
}
