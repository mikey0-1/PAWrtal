import 'package:capstone_app/data/models/clinic_model.dart';
import 'package:capstone_app/data/models/ratings_and_review_model.dart';
import 'package:capstone_app/data/repository/auth.repository.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class ClinicReviewsPage extends StatefulWidget {
  final Clinic clinic;

  const ClinicReviewsPage({super.key, required this.clinic});

  @override
  State<ClinicReviewsPage> createState() => _ClinicReviewsPageState();
}

class _ClinicReviewsPageState extends State<ClinicReviewsPage> {
  final AuthRepository _authRepo = Get.find<AuthRepository>();
  final TextEditingController _searchController = TextEditingController();
  
  List<RatingAndReview> reviews = [];
  ClinicRatingStats? stats;
  bool _isLoading = true;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadReviews();
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text.toLowerCase();
      });
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadReviews() async {
    setState(() => _isLoading = true);
    
    try {
      final fetchedReviews = await _authRepo.getClinicReviews(widget.clinic.documentId!);
      final fetchedStats = await _authRepo.getClinicRatingStats(widget.clinic.documentId!);
      
      setState(() {
        reviews = fetchedReviews;
        stats = fetchedStats;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  List<RatingAndReview> get filteredReviews {
    if (_searchQuery.isEmpty) return reviews;
    
    return reviews.where((review) {
      final userName = review.userName.toLowerCase();
      final reviewText = (review.reviewText ?? '').toLowerCase();
      final service = review.serviceName.toLowerCase();
      
      return userName.contains(_searchQuery) ||
             reviewText.contains(_searchQuery) ||
             service.contains(_searchQuery);
    }).toList();
  }

  double get averageRating {
    return stats?.averageRating ?? 0.0;
  }

  Map<int, double> calculateRatingPercentages() {
    if (stats == null || stats!.totalReviews == 0) {
      return {1: 0, 2: 0, 3: 0, 4: 0, 5: 0};
    }
    
    return {
      5: (stats!.ratingDistribution[5] ?? 0) / stats!.totalReviews,
      4: (stats!.ratingDistribution[4] ?? 0) / stats!.totalReviews,
      3: (stats!.ratingDistribution[3] ?? 0) / stats!.totalReviews,
      2: (stats!.ratingDistribution[2] ?? 0) / stats!.totalReviews,
      1: (stats!.ratingDistribution[1] ?? 0) / stats!.totalReviews,
    };
  }

  Widget buildStarRating(double rating, {double size = 20}) {
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

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          leading: IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.close_rounded, color: Colors.black),
          ),
          title: const Text(
            'Ratings & Reviews',
            style: TextStyle(
              color: Colors.black,
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          centerTitle: true,
        ),
        body: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    Map<int, double> ratingPercentages = calculateRatingPercentages();

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        scrolledUnderElevation: 0,
        elevation: 0,
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.close_rounded, color: Colors.black),
        ),
        title: const Text(
          'Ratings & Reviews',
          style: TextStyle(
            color: Colors.black,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
      ),
      body: reviews.isEmpty
          ? _buildNoReviews()
          : Column(
              children: [
                const Divider(height: 1),
                // Rating Summary
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
                  child: Column(
                    children: [
                      Text(
                        averageRating.toStringAsFixed(1),
                        style: const TextStyle(
                          fontSize: 36,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 6),
                      buildStarRating(averageRating, size: 18),
                      const SizedBox(height: 6),
                      Text(
                        "${reviews.length} reviews",
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey[600],
                        ),
                      ),
                      const SizedBox(height: 12),
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
                                width: 30,
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
                const Divider(height: 1),
                // Search Bar
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'Search reviews',
                      hintStyle: const TextStyle(fontSize: 14),
                      prefixIcon: const Icon(Icons.search_rounded),
                      suffixIcon: _searchQuery.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.close_rounded),
                              onPressed: () {
                                _searchController.clear();
                                setState(() {
                                  _searchQuery = '';
                                });
                              },
                            )
                          : null,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.grey.shade300),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Colors.black, width: 1.5),
                      ),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    ),
                  ),
                ),
                // Reviews List
                Expanded(
                  child: filteredReviews.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.search_off, size: 64, color: Colors.grey[400]),
                              const SizedBox(height: 16),
                              Text(
                                'No reviews found',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                        )
                      : ListView.separated(
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                          itemCount: filteredReviews.length,
                          separatorBuilder: (context, index) => const Divider(height: 32),
                          itemBuilder: (context, index) {
                            final review = filteredReviews[index];
                            return _ReviewCard(review: review, authRepo: _authRepo);
                          },
                        ),
                ),
              ],
            ),
    );
  }

  Widget _buildNoReviews() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.rate_review_outlined,
            size: 64,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'No reviews yet',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.grey[700],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Be the first to review this clinic!',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }
}

class _ReviewCard extends StatelessWidget {
  final RatingAndReview review;
  final AuthRepository authRepo;

  const _ReviewCard({
    required this.review,
    required this.authRepo,
  });

  Widget buildStarRating(double rating) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (index) {
        double starFill = (rating - index).clamp(0.0, 1.0);
        return Stack(
          children: [
            Icon(Icons.star_border_rounded, size: 16, color: Colors.amber),
            ClipRect(
              clipper: _StarClipper(starFill),
              child: Icon(Icons.star_rounded, size: 16, color: Colors.amber),
            ),
          ],
        );
      }),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CircleAvatar(
              radius: 20,
              backgroundColor: const Color.fromARGB(255, 81, 115, 153).withOpacity(0.1),
              child: Text(
                review.userName[0].toUpperCase(),
                style: const TextStyle(
                  color: Color.fromARGB(255, 81, 115, 153),
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    review.userName,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(height: 4),
                  buildStarRating(review.rating),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      '${review.serviceName}${review.petName != null ? ' • ${review.petName}' : ''}',
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey.shade700,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          review.getTimeAgo(),
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
          ),
        ),
        if (review.hasReview) ...[
          const SizedBox(height: 8),
          Text(
            review.reviewText!,
            style: const TextStyle(
              fontSize: 14,
              height: 1.4,
            ),
          ),
        ],
        if (review.hasImages) ...[
          const SizedBox(height: 12),
          SizedBox(
            height: 80,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: review.images.length,
              itemBuilder: (context, index) {
                final imageUrl = authRepo.getImageUrl(review.images[index]);
                
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
                          child: const Icon(Icons.image_not_supported, size: 24),
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
    );
  }
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