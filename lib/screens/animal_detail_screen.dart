import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:paws_without_borders/models/animal.dart';
import 'package:paws_without_borders/models/shelter.dart';
import 'package:paws_without_borders/services/animal_service.dart';
import 'package:paws_without_borders/services/shelter_service.dart';
import 'package:paws_without_borders/providers/language_provider.dart';
import 'package:paws_without_borders/theme.dart';
import 'package:paws_without_borders/widgets/animal_image_carousel.dart';

class AnimalDetailScreen extends StatefulWidget {
  final String animalId;

  const AnimalDetailScreen({super.key, required this.animalId});

  @override
  State<AnimalDetailScreen> createState() => _AnimalDetailScreenState();
}

class _AnimalDetailScreenState extends State<AnimalDetailScreen> {
  final AnimalService _animalService = AnimalService();
  final ShelterService _shelterService = ShelterService();

  List<String> _combineGalleryUrls(Animal animal) {
    final cleaned = <String>[];
    void add(String u) {
      final t = u.trim();
      if (t.isEmpty) return;
      if (!cleaned.contains(t)) cleaned.add(t);
    }

    // Ordered: primary first, then the rest.
    add(animal.imageUrl);
    for (final u in animal.imageUrls) {
      add(u);
    }
    return cleaned;
  }

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
      body: StreamBuilder<Animal?>(
        stream: _animalService.watchAnimalById(widget.animalId),
        builder: (context, animalSnap) {
          final animal = animalSnap.data;
          if (animalSnap.connectionState == ConnectionState.waiting && animal == null) {
            return const Center(child: CircularProgressIndicator());
          }
          if (animal == null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('Animal not found'),
                  ElevatedButton(onPressed: () => context.pop(), child: const Text('Go Back')),
                ],
              ),
            );
          }

          // IMPORTANT: Public UI should render a single ordered gallery:
          // primary imageUrl first, followed by imageUrls.
          // Do not apply additional caps here; display what exists.
          final galleryUrls = _combineGalleryUrls(animal);

          return StreamBuilder<Shelter?>(
            stream: _shelterService.watchShelterById(animal.shelterId),
            builder: (context, shelterSnap) {
              final shelter = shelterSnap.data;
              return SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Stack(
                      children: [
                        AnimalImageCarousel(imageUrls: galleryUrls, height: 400, borderRadius: BorderRadius.zero),
                        Positioned(
                          top: 0,
                          left: 0,
                          right: 0,
                          child: SafeArea(
                            child: Padding(
                              padding: const EdgeInsets.all(20.0),
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
                                      icon: const Icon(Icons.arrow_back_rounded, size: 22),
                                      onPressed: () => context.pop(),
                                      color: AppColors.lightPrimaryText,
                                      padding: EdgeInsets.zero,
                                    ),
                                  ),
                                  Container(
                                    width: 40,
                                    height: 40,
                                    decoration: BoxDecoration(
                                      color: Colors.white.withValues(alpha: 0.8),
                                      borderRadius: BorderRadius.circular(999),
                                    ),
                                    child: IconButton(
                                      icon: const Icon(Icons.favorite_border_rounded, size: 22),
                                      onPressed: () {},
                                      color: AppColors.lightError,
                                      padding: EdgeInsets.zero,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        Positioned(
                          bottom: 20,
                          right: 20,
                          child: IgnorePointer(
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                              decoration: BoxDecoration(
                                color: AppColors.lightSuccess,
                                borderRadius: BorderRadius.circular(999),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.1),
                                    blurRadius: 4,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: Text(
                                animal.status.toUpperCase(),
                                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        ),
              ],
            ),
            Padding(
              padding: AppSpacing.paddingLg,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                spacing: AppSpacing.lg,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          spacing: AppSpacing.xs,
                          children: [
                            Text(
                              animal.name,
                              style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                                fontWeight: FontWeight.w800,
                                color: AppColors.lightPrimaryText,
                              ),
                            ),
                            Row(
                              spacing: AppSpacing.xs,
                              children: [
                                const Icon(Icons.location_on_outlined, color: AppColors.lightSecondaryText, size: 16),
                                Expanded(
                                  child: Text(
                                    '${shelter?.name ?? 'Shelter'}, ${shelter?.location ?? ''}',
                                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                      color: AppColors.lightSecondaryText,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: AppSpacing.paddingMd,
                        decoration: BoxDecoration(
                          color: const Color(0xFFE8F5E9),
                          borderRadius: BorderRadius.circular(AppRadius.lg),
                        ),
                        child: Icon(Icons.pets_rounded, color: Theme.of(context).colorScheme.primary, size: 28),
                      ),
                    ],
                  ),
                  Row(
                    spacing: AppSpacing.md,
                    children: [
                      Expanded(
                        child: InfoTag(label: lang.translate('age'), value: animal.age),
                      ),
                      Expanded(
                        child: InfoTag(label: lang.translate('gender'), value: animal.gender.trim().isEmpty ? '—' : animal.gender),
                      ),
                      Expanded(
                        child: InfoTag(label: lang.translate('weight'), value: animal.weight.trim().isEmpty ? '—' : animal.weight),
                      ),
                    ],
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    spacing: AppSpacing.sm,
                    children: [
                      Text(
                        '${lang.translate('about')} ${animal.name}',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      Text(
                        animal.description,
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: AppColors.lightSecondaryText,
                          height: 1.5,
                        ),
                      ),
                    ],
                  ),
                  Divider(color: Theme.of(context).colorScheme.outline),
                  if (shelter != null)
                    Container(
                      padding: AppSpacing.paddingMd,
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.surface,
                        borderRadius: BorderRadius.circular(AppRadius.lg),
                        border: Border.all(color: Theme.of(context).colorScheme.outline),
                      ),
                      child: Row(
                        spacing: AppSpacing.md,
                        children: [
                          Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(AppRadius.md),
                              color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
                            ),
                            child: Icon(
                              Icons.home_rounded,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                          ),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              spacing: AppSpacing.xs,
                              children: [
                                Text(
                                  shelter.name,
                                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.lightPrimaryText,
                                  ),
                                ),
                                Text(
                                  'Official Partner Shelter',
                                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                    color: Theme.of(context).colorScheme.primary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Icon(Icons.verified_rounded, color: Theme.of(context).colorScheme.primary, size: 20),
                        ],
                      ),
                    ),
                  Column(
                    spacing: AppSpacing.md,
                    children: [
                      Text(
                        '${lang.translate('interestedIn')} ${animal.name}?',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      if (shelter != null) ...[
                        Row(
                          spacing: AppSpacing.md,
                          children: [
                            Expanded(
                              child: ContactAction(
                                backgroundColor: const Color(0xFF25D366),
                                icon: Icons.chat_bubble_rounded,
                                label: 'WhatsApp',
                                textColor: Colors.white,
                                onTap: () => _launchUrl('https://wa.me/${shelter.whatsapp}'),
                              ),
                            ),
                            Expanded(
                              child: ContactAction(
                                backgroundColor: const Color(0xFF0088CC),
                                icon: Icons.send_rounded,
                                label: 'Telegram',
                                textColor: Colors.white,
                                onTap: () => _launchUrl('https://t.me/${shelter.telegram}'),
                              ),
                            ),
                          ],
                        ),
                        GestureDetector(
                          onTap: () => _launchUrl('mailto:${shelter.email}'),
                          child: Container(
                            height: 56,
                            decoration: BoxDecoration(
                              color: Theme.of(context).colorScheme.primary,
                              borderRadius: BorderRadius.circular(AppRadius.md),
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
                              spacing: AppSpacing.sm,
                              children: [
                                Icon(Icons.mail_outline_rounded, color: Theme.of(context).colorScheme.onPrimary, size: 20),
                                Text(
                                  lang.translate('inquireEmail'),
                                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                                    color: Theme.of(context).colorScheme.onPrimary,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: AppSpacing.lg),
                ],
              ),
            ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class InfoTag extends StatelessWidget {
  final String label;
  final String value;

  const InfoTag({super.key, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        border: Border.all(color: Theme.of(context).colorScheme.outline),
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: Column(
        spacing: AppSpacing.xs,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(color: AppColors.lightSecondaryText),
          ),
          Text(
            value,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: AppColors.lightPrimaryText,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}

class ContactAction extends StatelessWidget {
  final Color backgroundColor;
  final IconData icon;
  final String label;
  final Color textColor;
  final VoidCallback onTap;

  const ContactAction({
    super.key,
    required this.backgroundColor,
    required this.icon,
    required this.label,
    required this.textColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 50,
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(AppRadius.md),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          spacing: AppSpacing.sm,
          children: [
            Icon(icon, color: textColor, size: 20),
            Text(
              label,
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                color: textColor,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
