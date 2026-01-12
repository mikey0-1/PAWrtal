class RatingAndReview {
  final String? documentId;
  final String userId;
  final String clinicId;
  final String appointmentId;
  final double rating; // 0.5 to 5.0
  final String? reviewText;
  final List<String> images; // Array of image file IDs
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool isEdited;
  final String userName;
  final String? petName;
  final String serviceName;
  final int helpfulCount;
  final bool isArchived; // NEW: Archive status

  RatingAndReview({
    this.documentId,
    required this.userId,
    required this.clinicId,
    required this.appointmentId,
    required this.rating,
    this.reviewText,
    this.images = const [],
    DateTime? createdAt,
    DateTime? updatedAt,
    this.isEdited = false,
    required this.userName,
    this.petName,
    required this.serviceName,
    this.helpfulCount = 0,
    this.isArchived = false, // NEW: Default to false
  })  : createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  factory RatingAndReview.fromMap(Map<String, dynamic> map) {
    return RatingAndReview(
      documentId: map['\$id'],
      userId: map['userId'] ?? '',
      clinicId: map['clinicId'] ?? '',
      appointmentId: map['appointmentId'] ?? '',
      rating: (map['rating'] ?? 0.0).toDouble(),
      reviewText: map['reviewText'],
      images: map['images'] != null ? List<String>.from(map['images']) : [],
      createdAt: map['createdAt'] != null
          ? DateTime.parse(map['createdAt'])
          : DateTime.now(),
      updatedAt: map['updatedAt'] != null
          ? DateTime.parse(map['updatedAt'])
          : DateTime.now(),
      isEdited: map['isEdited'] ?? false,
      userName: map['userName'] ?? 'Anonymous',
      petName: map['petName'],
      serviceName: map['serviceName'] ?? 'Service',
      helpfulCount: map['helpfulCount'] ?? 0,
      isArchived: map['isArchived'] ?? false, // NEW
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'clinicId': clinicId,
      'appointmentId': appointmentId,
      'rating': rating,
      'reviewText': reviewText,
      'images': images,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'isEdited': isEdited,
      'userName': userName,
      'petName': petName,
      'serviceName': serviceName,
      'helpfulCount': helpfulCount,
      'isArchived': isArchived, // NEW
    };
  }

  RatingAndReview copyWith({
    String? documentId,
    String? userId,
    String? clinicId,
    String? appointmentId,
    double? rating,
    String? reviewText,
    List<String>? images,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isEdited,
    String? userName,
    String? petName,
    String? serviceName,
    int? helpfulCount,
    bool? isArchived, // NEW
  }) {
    return RatingAndReview(
      documentId: documentId ?? this.documentId,
      userId: userId ?? this.userId,
      clinicId: clinicId ?? this.clinicId,
      appointmentId: appointmentId ?? this.appointmentId,
      rating: rating ?? this.rating,
      reviewText: reviewText ?? this.reviewText,
      images: images ?? this.images,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isEdited: isEdited ?? this.isEdited,
      userName: userName ?? this.userName,
      petName: petName ?? this.petName,
      serviceName: serviceName ?? this.serviceName,
      helpfulCount: helpfulCount ?? this.helpfulCount,
      isArchived: isArchived ?? this.isArchived, // NEW
    );
  }

  // Helper methods
  bool get hasReview => reviewText != null && reviewText!.isNotEmpty;
  bool get hasImages => images.isNotEmpty;

  String get ratingText {
    if (rating >= 4.5) return 'Excellent';
    if (rating >= 3.5) return 'Very Good';
    if (rating >= 2.5) return 'Good';
    if (rating >= 1.5) return 'Fair';
    return 'Poor';
  }

  // Get time ago string
  String getTimeAgo() {
    final now = DateTime.now();
    final difference = now.difference(createdAt);

    if (difference.inDays > 365) {
      final years = (difference.inDays / 365).floor();
      return '$years ${years == 1 ? 'year' : 'years'} ago';
    } else if (difference.inDays > 30) {
      final months = (difference.inDays / 30).floor();
      return '$months ${months == 1 ? 'month' : 'months'} ago';
    } else if (difference.inDays > 0) {
      return '${difference.inDays} ${difference.inDays == 1 ? 'day' : 'days'} ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} ${difference.inHours == 1 ? 'hour' : 'hours'} ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} ${difference.inMinutes == 1 ? 'minute' : 'minutes'} ago';
    } else {
      return 'Just now';
    }
  }
}

// Helper class for clinic rating statistics
class ClinicRatingStats {
  final double averageRating;
  final int totalReviews;
  final Map<int, int> ratingDistribution; // 1-5 stars count
  final int reviewsWithText;
  final int reviewsWithImages;

  ClinicRatingStats({
    required this.averageRating,
    required this.totalReviews,
    required this.ratingDistribution,
    required this.reviewsWithText,
    required this.reviewsWithImages,
  });

  factory ClinicRatingStats.fromReviews(List<RatingAndReview> reviews) {
    if (reviews.isEmpty) {
      return ClinicRatingStats(
        averageRating: 0.0,
        totalReviews: 0,
        ratingDistribution: {1: 0, 2: 0, 3: 0, 4: 0, 5: 0},
        reviewsWithText: 0,
        reviewsWithImages: 0,
      );
    }

    final totalRating =
        reviews.fold<double>(0, (sum, review) => sum + review.rating);
    final avgRating = totalRating / reviews.length;

    final distribution = <int, int>{1: 0, 2: 0, 3: 0, 4: 0, 5: 0};
    for (var review in reviews) {
      final starRating = review.rating.ceil();
      distribution[starRating] = (distribution[starRating] ?? 0) + 1;
    }

    final withText = reviews.where((r) => r.hasReview).length;
    final withImages = reviews.where((r) => r.hasImages).length;

    return ClinicRatingStats(
      averageRating: double.parse(avgRating.toStringAsFixed(1)),
      totalReviews: reviews.length,
      ratingDistribution: distribution,
      reviewsWithText: withText,
      reviewsWithImages: withImages,
    );
  }

  String get formattedAverage => averageRating.toStringAsFixed(1);

  int getPercentageForRating(int stars) {
    if (totalReviews == 0) return 0;
    final count = ratingDistribution[stars] ?? 0;
    return ((count / totalReviews) * 100).round();
  }
}
