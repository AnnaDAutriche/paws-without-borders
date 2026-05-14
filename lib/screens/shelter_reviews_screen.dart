import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:paws_without_borders/models/review.dart';
import 'package:paws_without_borders/models/shelter.dart';
import 'package:paws_without_borders/services/review_service.dart';
import 'package:paws_without_borders/services/shelter_service.dart';
import 'package:paws_without_borders/providers/language_provider.dart';
import 'package:paws_without_borders/providers/auth_provider.dart';
import 'package:paws_without_borders/theme.dart';

class ShelterReviewsScreen extends StatefulWidget {
  final String shelterId;

  const ShelterReviewsScreen({super.key, required this.shelterId});

  @override
  State<ShelterReviewsScreen> createState() => _ShelterReviewsScreenState();
}

class _ShelterReviewsScreenState extends State<ShelterReviewsScreen> {
  final ReviewService _reviewService = ReviewService();
  final ShelterService _shelterService = ShelterService();
  final TextEditingController _commentController = TextEditingController();
  List<Review> _reviews = [];
  int _selectedRating = 5;
  bool _isLoading = true;
  bool _isSubmitting = false;
  Shelter? _shelter;

  @override
  void initState() {
    super.initState();
    _loadShelterAndReviews();
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _loadShelterAndReviews() async {
    try {
      final shelter = await _shelterService.getShelterById(widget.shelterId);
      if (!mounted) return;

      // Strict public-visibility enforcement: if the shelter is not publicly
      // visible, we do not load reviews and we do not allow submissions.
      if (shelter == null) {
        setState(() {
          _shelter = null;
          _reviews = [];
          _isLoading = false;
        });
        return;
      }

      final reviews = await _reviewService.getReviewsByShelterId(widget.shelterId);
      if (mounted) {
        setState(() {
          _shelter = shelter;
          _reviews = reviews;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _submitReview() async {
    if (_shelter == null) return;
    if (_commentController.text.trim().isEmpty) return;

    setState(() => _isSubmitting = true);

    final auth = context.read<AuthProvider>();
    final uid = auth.isSignedIn ? auth.uid : 'guest_${DateTime.now().millisecondsSinceEpoch}';
    final name = auth.isSignedIn ? (auth.email ?? 'User') : 'Anonymous User';

    final review = Review(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      shelterId: widget.shelterId,
      userId: uid,
      userName: name,
      rating: _selectedRating.toDouble(),
      comment: _commentController.text.trim(),
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    await _reviewService.addReview(review);
    _commentController.clear();
    setState(() {
      _selectedRating = 5;
      _isSubmitting = false;
    });
    await _loadShelterAndReviews();

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Review submitted successfully!')),
      );
    }
  }

  double get _averageRating {
    if (_reviews.isEmpty) return 0;
    return _reviews.map((r) => r.rating).reduce((a, b) => a + b) / _reviews.length;
  }

  @override
  Widget build(BuildContext context) {
    final lang = Provider.of<LanguageProvider>(context);

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : (_shelter == null
                ? Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Container(
                        padding: AppSpacing.paddingLg,
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.surface,
                          border: Border(bottom: BorderSide(color: Theme.of(context).colorScheme.outline)),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            IconButton(icon: const Icon(Icons.arrow_back_rounded), onPressed: () => context.pop(), color: AppColors.lightPrimaryText),
                            Text(
                              '${lang.translate('reviews')}',
                              style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(width: 48),
                          ],
                        ),
                      ),
                      const Spacer(),
                      Padding(
                        padding: AppSpacing.paddingLg,
                        child: Text(
                          'This shelter is not available.',
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.bodyLarge,
                        ),
                      ),
                      const Spacer(),
                    ],
                  )
                : Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Container(
                    padding: AppSpacing.paddingLg,
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surface,
                      border: Border(bottom: BorderSide(color: Theme.of(context).colorScheme.outline)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.arrow_back_rounded),
                          onPressed: () => context.pop(),
                          color: AppColors.lightPrimaryText,
                        ),
                        Text(
                          '${lang.translate('reviews')}',
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        IconButton(
                          icon: const Icon(Icons.share_rounded),
                          onPressed: () {},
                          color: AppColors.lightPrimaryText,
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Container(
                            margin: AppSpacing.paddingLg,
                            padding: AppSpacing.paddingLg,
                            decoration: BoxDecoration(
                              color: Theme.of(context).colorScheme.primary,
                              borderRadius: BorderRadius.circular(AppRadius.xl),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.2),
                                  blurRadius: 6,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Row(
                              spacing: AppSpacing.lg,
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        _averageRating.toStringAsFixed(1),
                                        style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                                          color: Theme.of(context).colorScheme.onPrimary,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      Row(
                                        spacing: 2,
                                        children: List.generate(
                                          5,
                                          (index) => Icon(
                                            index < _averageRating.floor()
                                                ? Icons.star_rounded
                                                : (index < _averageRating ? Icons.star_half_rounded : Icons.star_outline_rounded),
                                            color: AppColors.lightAccent,
                                            size: 20,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        '${lang.translate('basedOnReviews')} ${_reviews.length} ${lang.translate('reviews').toLowerCase()}',
                                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                          color: Theme.of(context).colorScheme.onPrimary.withValues(alpha: 0.8),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Container(
                                  width: 1,
                                  height: 60,
                                  color: Theme.of(context).colorScheme.onPrimary.withValues(alpha: 0.2),
                                ),
                                Expanded(
                                  child: Column(
                                    spacing: AppSpacing.xs,
                                    children: [
                                      _buildRatingBar(context, 5, 0.8),
                                      _buildRatingBar(context, 4, 0.15),
                                      _buildRatingBar(context, 3, 0.05),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            margin: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.lg),
                            padding: AppSpacing.paddingLg,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(AppRadius.lg),
                              border: Border.all(color: Theme.of(context).colorScheme.primary, width: 2),
                              color: Theme.of(context).colorScheme.surface,
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              spacing: AppSpacing.md,
                              children: [
                                Text(
                                  lang.translate('writeReview'),
                                  style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                                ),
                                Text(
                                  lang.translate('shareExperience'),
                                  style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.lightSecondaryText),
                                ),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  spacing: AppSpacing.sm,
                                  children: List.generate(
                                    5,
                                    (index) => IconButton(
                                      icon: Icon(
                                        index < _selectedRating ? Icons.star_rounded : Icons.star_outline_rounded,
                                        color: index < _selectedRating ? AppColors.lightAccent : Theme.of(context).colorScheme.outline,
                                        size: 32,
                                      ),
                                      onPressed: () => setState(() => _selectedRating = index + 1),
                                    ),
                                  ),
                                ),
                                TextField(
                                  controller: _commentController,
                                  maxLines: 3,
                                  decoration: InputDecoration(
                                    hintText: 'Describe your visit or adoption process...',
                                    filled: true,
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(AppRadius.md),
                                      borderSide: BorderSide(color: Theme.of(context).colorScheme.outline),
                                    ),
                                  ),
                                ),
                                SizedBox(
                                  width: double.infinity,
                                  height: 48,
                                  child: ElevatedButton(
                                    onPressed: _isSubmitting ? null : _submitReview,
                                    child: _isSubmitting
                                        ? const SizedBox(
                                            width: 20,
                                            height: 20,
                                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                          )
                                        : Text(lang.translate('submitReview')),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Padding(
                            padding: AppSpacing.horizontalLg,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  lang.translate('recentReviews'),
                                  style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                                ),
                                Row(
                                  spacing: AppSpacing.xs,
                                  children: [
                                    Text(
                                      lang.translate('sortBy'),
                                      style: Theme.of(context).textTheme.labelMedium?.copyWith(color: AppColors.lightSecondaryText),
                                    ),
                                    const Icon(Icons.keyboard_arrow_down_rounded, color: AppColors.lightSecondaryText, size: 18),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: AppSpacing.md),
                          ..._reviews.map((review) => ReviewCard(review: review)),
                          const SizedBox(height: AppSpacing.lg),
                        ],
                      ),
                    ),
                  ),
                ],
              )),
      ),
    );
  }

  Widget _buildRatingBar(BuildContext context, int stars, double percentage) {
    return Row(
      spacing: AppSpacing.sm,
      children: [
        SizedBox(
          width: 10,
          child: Text(
            '$stars',
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: Theme.of(context).colorScheme.onPrimary,
            ),
          ),
        ),
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(2),
            child: LinearProgressIndicator(
              value: percentage,
              backgroundColor: Theme.of(context).colorScheme.onPrimary.withValues(alpha: 0.2),
              valueColor: AlwaysStoppedAnimation<Color>(AppColors.lightAccent),
              minHeight: 4,
            ),
          ),
        ),
      ],
    );
  }
}

class ReviewCard extends StatelessWidget {
  final Review review;

  const ReviewCard({super.key, required this.review});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.sm),
      padding: AppSpacing.paddingLg,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 2,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: AppSpacing.sm,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                spacing: AppSpacing.md,
                children: [
                  CircleAvatar(
                    radius: 20,
                    backgroundColor: Theme.of(context).scaffoldBackgroundColor,
                    child: Text(
                      review.initials,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        review.userName,
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      Text(
                        '${review.createdAt.difference(DateTime.now()).inDays.abs()} days ago',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.lightHint),
                      ),
                    ],
                  ),
                ],
              ),
              Row(
                spacing: 2,
                children: [
                  const Icon(Icons.star, size: 16, color: AppColors.lightAccent),
                  Text(
                    review.rating.toStringAsFixed(1),
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      color: AppColors.lightPrimaryText,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ],
          ),
          Text(
            review.comment,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: AppColors.lightSecondaryText,
              height: 1.5,
            ),
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
