import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:paws_without_borders/models/shelter.dart';
import 'package:paws_without_borders/models/animal.dart';
import 'package:paws_without_borders/models/review.dart';
import 'package:paws_without_borders/services/shelter_service.dart';
import 'package:paws_without_borders/services/animal_service.dart';
import 'package:paws_without_borders/services/review_service.dart';
import 'package:paws_without_borders/providers/language_provider.dart';
import 'package:paws_without_borders/providers/auth_provider.dart';
import 'package:paws_without_borders/theme.dart';
import 'package:paws_without_borders/widgets/app_network_image.dart';
import 'package:paws_without_borders/widgets/animal_network_image.dart';

class ShelterDetailScreen extends StatefulWidget {
  final String shelterId;

  const ShelterDetailScreen({super.key, required this.shelterId});

  @override
  State<ShelterDetailScreen> createState() => _ShelterDetailScreenState();
}

class _ShelterDetailScreenState extends State<ShelterDetailScreen> {
  final ShelterService _shelterService = ShelterService();
  final AnimalService _animalService = AnimalService();
  final ReviewService _reviewService = ReviewService();

  Future<void> _launchUrl(String url) async {
    final Uri uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    final lang = Provider.of<LanguageProvider>(context);
    return Scaffold(
      body: StreamBuilder<Shelter?>(
        stream: _shelterService.watchShelterById(widget.shelterId),
        builder: (context, shelterSnap) {
          final shelter = shelterSnap.data;
          if (shelterSnap.connectionState == ConnectionState.waiting && shelter == null) {
            return const Center(child: CircularProgressIndicator());
          }
          if (shelter == null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('Shelter not found'),
                  ElevatedButton(onPressed: () => context.pop(), child: const Text('Go Back')),
                ],
              ),
            );
          }

          return StreamBuilder<List<Animal>>(
            stream: _animalService.watchAnimalsByShelterId(widget.shelterId),
            builder: (context, animalsSnap) {
              final animals = animalsSnap.data ?? const <Animal>[];
              return StreamBuilder<List<Review>>(
                stream: _reviewService.watchReviewsByShelterId(widget.shelterId),
                builder: (context, reviewSnap) {
                  final reviews = reviewSnap.data ?? const <Review>[];
                  return SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Stack(
                          children: [
                            AppNetworkImage(url: shelter.imageUrl, height: 280, width: double.infinity, fit: BoxFit.cover),
                            Container(
                              height: 280,
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                  colors: [
                                    Colors.black.withValues(alpha: 0.7),
                                    Colors.transparent,
                                  ],
                                  stops: const [0.0, 0.6],
                                ),
                              ),
                            ),
                            Positioned(
                              bottom: AppSpacing.lg,
                              left: AppSpacing.lg,
                              right: AppSpacing.lg,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                spacing: AppSpacing.xs,
                                children: [
                                  if (shelter.internationalDelivery)
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: Colors.white.withValues(alpha: 0.85),
                                        borderRadius: BorderRadius.circular(999),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        spacing: 6,
                                        children: [
                                          Icon(Icons.public_rounded, size: 16, color: Theme.of(context).colorScheme.primary),
                                          Text(
                                            'International delivery',
                                            style: Theme.of(context).textTheme.labelMedium?.copyWith(
                                              color: AppColors.lightPrimaryText,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  Text(
                                    shelter.name,
                                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  Row(
                                    spacing: AppSpacing.xs,
                                    children: [
                                      const Icon(Icons.location_on, color: Colors.white, size: 16),
                                      Text(
                                        shelter.location,
                                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.white),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            SafeArea(
                              child: Padding(
                                padding: const EdgeInsets.all(16.0),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Container(
                                      width: 40,
                                      height: 40,
                                      decoration: BoxDecoration(
                                        color: Colors.white.withValues(alpha: 0.8),
                                        borderRadius: BorderRadius.circular(999),
                                      ),
                                      child: IconButton(
                                        icon: const Icon(Icons.arrow_back_ios_new, size: 20),
                                        onPressed: () => context.pop(),
                                        color: AppColors.lightPrimaryText,
                                        padding: EdgeInsets.zero,
                                      ),
                                    ),
                                    Consumer<AuthProvider>(
                                      builder: (context, auth, _) {
                                        // Client-side UI gate only (NOT a security boundary).
                                        // Real access control must be enforced with Firestore/Storage rules.
                                        if (!auth.isAdmin) return const SizedBox.shrink();
                                        return Row(
                                          children: [
                                            Container(
                                              width: 40,
                                              height: 40,
                                              decoration: BoxDecoration(
                                                color: Colors.white.withValues(alpha: 0.8),
                                                borderRadius: BorderRadius.circular(999),
                                              ),
                                              child: IconButton(
                                                icon: const Icon(Icons.edit_rounded, size: 20),
                                                onPressed: () => context.push('/admin/shelter/${widget.shelterId}/edit'),
                                                color: AppColors.lightPrimaryText,
                                                padding: EdgeInsets.zero,
                                              ),
                                            ),
                                            const SizedBox(width: 10),
                                            Container(
                                              width: 40,
                                              height: 40,
                                              decoration: BoxDecoration(
                                                color: Colors.white.withValues(alpha: 0.8),
                                                borderRadius: BorderRadius.circular(999),
                                              ),
                                              child: IconButton(
                                                icon: const Icon(Icons.delete_outline_rounded, size: 20),
                                                onPressed: () async {
                                                  final ok = await showModalBottomSheet<bool>(
                                                    context: context,
                                                    showDragHandle: true,
                                                    backgroundColor: Theme.of(context).colorScheme.surface,
                                                    builder: (context) => _AdminDeleteSheet(name: shelter.name),
                                                  );
                                                  if (ok == true) {
                                                    await _shelterService.deleteShelter(widget.shelterId);
                                                    if (context.mounted) context.go('/');
                                                  }
                                                },
                                                color: Colors.red,
                                                padding: EdgeInsets.zero,
                                              ),
                                            ),
                                          ],
                                        );
                                      },
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
            Padding(
              padding: AppSpacing.paddingLg,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                spacing: AppSpacing.md,
                children: [
                  Text(
                    lang.translate('gallery'),
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: shelter.galleryImages.map((img) => GalleryImage(imageUrl: img)).toList(),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: AppSpacing.horizontalLg,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                spacing: AppSpacing.sm,
                children: [
                  Text(
                    lang.translate('aboutShelter'),
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  Text(
                    shelter.description,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppColors.lightSecondaryText,
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            GestureDetector(
              onTap: () => _launchUrl('https://${shelter.paypalLink}'),
              child: Container(
                margin: AppSpacing.horizontalLg,
                height: 56,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary,
                  borderRadius: BorderRadius.circular(AppRadius.lg),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.2),
                      blurRadius: 6,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  spacing: AppSpacing.md,
                  children: [
                    Icon(Icons.favorite, color: Theme.of(context).colorScheme.onPrimary, size: 24),
                    Text(
                      lang.translate('donate'),
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onPrimary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            Padding(
              padding: AppSpacing.horizontalLg,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                spacing: AppSpacing.md,
                children: [
                  Text(
                    lang.translate('connectWith'),
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  Row(
                    spacing: AppSpacing.md,
                    children: [
                      Expanded(
                        child: ContactButton(
                          icon: Icons.phone,
                          iconColor: const Color(0xFF25D366),
                          label: 'WhatsApp',
                          onTap: () => _launchUrl('https://wa.me/${shelter.whatsapp}'),
                        ),
                      ),
                      Expanded(
                        child: ContactButton(
                          icon: Icons.send,
                          iconColor: const Color(0xFF0088cc),
                          label: 'Telegram',
                          onTap: () => _launchUrl('https://t.me/${shelter.telegram}'),
                        ),
                      ),
                    ],
                  ),
                  Row(
                    spacing: AppSpacing.md,
                    children: [
                      Expanded(
                        child: ContactButton(
                          icon: Icons.email,
                          iconColor: Theme.of(context).colorScheme.primary,
                          label: 'Email',
                          onTap: () => _launchUrl('mailto:${shelter.email}'),
                        ),
                      ),
                      Expanded(
                        child: ContactButton(
                          icon: Icons.camera_alt,
                          iconColor: const Color(0xFFE1306C),
                          label: 'Instagram',
                          onTap: () => _launchUrl('https://${shelter.instagram}'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            if (animals.isNotEmpty) ...[
              const SizedBox(height: AppSpacing.lg),
              Padding(
                padding: AppSpacing.horizontalLg,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      lang.translate('meetResidents'),
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    GestureDetector(
                      onTap: () => context.push('/shelter/${widget.shelterId}/animals'),
                      child: Text(
                        lang.translate('viewAll'),
                        style: Theme.of(context).textTheme.labelLarge?.copyWith(
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: AppSpacing.horizontalLg,
                child: Row(
                  children: animals.take(3).map((animal) => AnimalCard(animal: animal)).toList(),
                ),
              ),
            ],
            const SizedBox(height: AppSpacing.lg),
            Padding(
              padding: AppSpacing.horizontalLg,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    lang.translate('reviews'),
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  TextButton(
                    onPressed: () => context.push('/shelter/${widget.shelterId}/reviews'),
                    child: Text(lang.translate('writeReview')),
                  ),
                ],
              ),
            ),
            ...reviews.take(2).map((review) => ReviewItem(review: review)),
            const SizedBox(height: AppSpacing.lg),
                      ],
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}

class GalleryImage extends StatelessWidget {
  final String imageUrl;

  const GalleryImage({super.key, required this.imageUrl});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 120,
      height: 120,
      margin: const EdgeInsets.only(right: AppSpacing.md),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppRadius.md),
        child: AppNetworkImage(url: imageUrl, fit: BoxFit.cover),
      ),
    );
  }
}

class ContactButton extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String label;
  final VoidCallback onTap;

  const ContactButton({
    super.key,
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 48,
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(AppRadius.md),
          border: Border.all(color: Theme.of(context).colorScheme.outline),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          spacing: AppSpacing.sm,
          children: [
            Icon(icon, color: iconColor, size: 20),
            Text(
              label,
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                color: AppColors.lightPrimaryText,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AdminDeleteSheet extends StatelessWidget {
  final String name;
  const _AdminDeleteSheet({required this.name});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: AppSpacing.paddingLg,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Delete shelter?', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text(
            'This will permanently remove "$name" from the platform.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppColors.lightSecondaryText),
          ),
          const SizedBox(height: AppSpacing.lg),
          Row(
            children: [
              Expanded(child: OutlinedButton(onPressed: () => context.pop(false), child: const Text('Cancel'))),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: () => context.pop(true),
                  child: const Text('Delete', style: TextStyle(color: Colors.white)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class AnimalCard extends StatelessWidget {
  final Animal animal;

  const AnimalCard({super.key, required this.animal});

  @override
  Widget build(BuildContext context) {
    final lang = Provider.of<LanguageProvider>(context);
    
    return GestureDetector(
      onTap: () => context.push('/animal/${animal.id}'),
      child: Container(
        width: 160,
        margin: const EdgeInsets.only(right: AppSpacing.md),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          border: Border.all(color: Theme.of(context).colorScheme.outline),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 2,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(AppRadius.lg)),
              child: AnimalNetworkImage(
                imageUrl: animal.imageUrl.trim().isNotEmpty
                    ? animal.imageUrl
                    : (animal.imageUrls.isNotEmpty ? animal.imageUrls.first : ''),
                height: 120,
                fit: BoxFit.cover,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(AppRadius.lg)),
              ),
            ),
            Padding(
              padding: AppSpacing.paddingSm,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                spacing: AppSpacing.xs,
                children: [
                  Text(
                    animal.name,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      color: AppColors.lightPrimaryText,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Row(
                    spacing: AppSpacing.xs,
                    children: [
                      const Icon(Icons.event_note, size: 14, color: AppColors.lightSecondaryText),
                      Text(
                        animal.age,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.lightSecondaryText),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: animal.status == 'Available' ? const Color(0xFFE8F5E9) : const Color(0xFFE0E0E0),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      lang.translate(animal.status.toLowerCase()),
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: animal.status == 'Available' ? const Color(0xFF2E7D32) : AppColors.lightSecondaryText,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class ReviewItem extends StatelessWidget {
  final Review review;

  const ReviewItem({super.key, required this.review});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.sm),
      padding: AppSpacing.paddingMd,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: Theme.of(context).colorScheme.outline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: AppSpacing.sm,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                spacing: AppSpacing.sm,
                children: [
                  CircleAvatar(
                    radius: 16,
                    backgroundColor: Theme.of(context).colorScheme.secondary,
                    child: Text(
                      review.initials,
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSecondary,
                      ),
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        review.userName,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      Text(
                        '${review.createdAt.difference(DateTime.now()).inDays.abs()} days ago',
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(color: AppColors.lightHint),
                      ),
                    ],
                  ),
                ],
              ),
              Row(
                spacing: 2,
                children: List.generate(
                  5,
                  (index) => Icon(
                    index < review.rating.floor() ? Icons.star : (index < review.rating ? Icons.star_half : Icons.star_outline),
                    size: 16,
                    color: AppColors.lightAccent,
                  ),
                ),
              ),
            ],
          ),
          Text(
            review.comment,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppColors.lightSecondaryText),
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
