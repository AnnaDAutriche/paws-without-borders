import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:paws_without_borders/models/shelter.dart';
import 'package:paws_without_borders/models/animal.dart';
import 'package:paws_without_borders/services/shelter_service.dart';
import 'package:paws_without_borders/services/animal_service.dart';
import 'package:paws_without_borders/providers/language_provider.dart';
import 'package:paws_without_borders/providers/auth_provider.dart';
import 'package:paws_without_borders/theme.dart';
import 'package:paws_without_borders/widgets/app_network_image.dart';
import 'package:url_launcher/url_launcher.dart';

class SheltersListScreen extends StatefulWidget {
  const SheltersListScreen({super.key});

  @override
  State<SheltersListScreen> createState() => _SheltersListScreenState();
}

class _SheltersListScreenState extends State<SheltersListScreen> {
  final ShelterService _shelterService = ShelterService();
  final AnimalService _animalService = AnimalService();

  static final Uri _supportPaypalUri = Uri.parse('https://paypal.me/pawwithoutborders');

  Future<void> _openSupportLink() async {
    try {
      final ok = await launchUrl(_supportPaypalUri, mode: LaunchMode.externalApplication);
      if (!ok) debugPrint('Failed to open support link: $_supportPaypalUri');
    } catch (e) {
      debugPrint('Failed to open support link: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final lang = Provider.of<LanguageProvider>(context);
    final auth = context.watch<AuthProvider>();

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: StreamBuilder<List<Shelter>>(
          stream: _shelterService.watchShelters(),
          builder: (context, shelterSnap) {
            final shelters = shelterSnap.data ?? const <Shelter>[];

            return StreamBuilder<List<Animal>>(
              stream: _animalService.watchAllAnimals(),
              builder: (context, animalsSnap) {
                final totalAnimals = animalsSnap.data?.length ?? 0;
                final isLoading = shelterSnap.connectionState == ConnectionState.waiting ||
                    animalsSnap.connectionState == ConnectionState.waiting;

                if (isLoading && shelters.isEmpty) {
                  return const Center(child: CircularProgressIndicator());
                }

                return Stack(
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Container(
                          padding: AppSpacing.paddingLg,
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.surface,
                            border: Border(
                              bottom: BorderSide(
                                color: Theme.of(context).colorScheme.outline,
                                width: 1,
                              ),
                            ),
                          ),
                          child: Column(
                            spacing: AppSpacing.md,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: LayoutBuilder(
                                      builder: (context, constraints) {
                                        final isCompact = constraints.maxWidth < 520;

                                        final titleBlock = Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          spacing: AppSpacing.xs,
                                          children: [
                                            Text(
                                              lang.translate('appTitle'),
                                              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                                                    fontWeight: FontWeight.w800,
                                                    color: Theme.of(context).colorScheme.primary,
                                                  ),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                            Text(
                                              lang.translate('appSubtitle'),
                                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                                    color: AppColors.lightSecondaryText,
                                                  ),
                                              maxLines: 2,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ],
                                        );

                                        final actions = Wrap(
                                          spacing: AppSpacing.sm,
                                          runSpacing: AppSpacing.sm,
                                          alignment: WrapAlignment.end,
                                          crossAxisAlignment: WrapCrossAlignment.center,
                                          children: [
                                            const AuthActionChip(),
                                            LanguageSelector(currentLanguage: lang.currentLanguage),
                                          ],
                                        );

                                        if (isCompact) {
                                          return Column(
                                            crossAxisAlignment: CrossAxisAlignment.stretch,
                                            spacing: AppSpacing.sm,
                                            children: [
                                              titleBlock,
                                              Align(
                                                alignment: Alignment.centerRight,
                                                child: actions,
                                              ),
                                            ],
                                          );
                                        }

                                        return Row(
                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                          children: [
                                            Expanded(child: titleBlock),
                                            const SizedBox(width: AppSpacing.md),
                                            actions,
                                          ],
                                        );
                                      },
                                    ),
                                  ),
                                ],
                              ),
                              Row(
                                spacing: AppSpacing.md,
                                children: [
                                  Expanded(
                                    child: Container(
                                      padding: AppSpacing.paddingMd,
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFE8F5E9),
                                        borderRadius: BorderRadius.circular(AppRadius.lg),
                                        border: Border.all(color: const Color(0xFFC8E6C9)),
                                      ),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        spacing: 4,
                                        children: [
                                          Text(
                                            '${shelters.length}',
                                            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                                  color: const Color(0xFF2E7D32),
                                                  fontWeight: FontWeight.bold,
                                                ),
                                          ),
                                          Text(
                                            lang.translate('shelters'),
                                            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                                  color: const Color(0xFF2E7D32),
                                                ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                  Expanded(
                                    child: Container(
                                      padding: AppSpacing.paddingMd,
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFFFF3E0),
                                        borderRadius: BorderRadius.circular(AppRadius.lg),
                                        border: Border.all(color: const Color(0xFFFFE0B2)),
                                      ),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        spacing: 4,
                                        children: [
                                          Text(
                                            '$totalAnimals',
                                            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                                  color: const Color(0xFFEF6C00),
                                                  fontWeight: FontWeight.bold,
                                                ),
                                          ),
                                          Text(
                                            lang.translate('animals'),
                                            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                                  color: const Color(0xFFEF6C00),
                                                ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                  Expanded(
                                    child: Container(
                                      padding: AppSpacing.paddingMd,
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFE3F2FD),
                                        borderRadius: BorderRadius.circular(AppRadius.lg),
                                        border: Border.all(color: const Color(0xFFBBDEFB)),
                                      ),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        spacing: 4,
                                        children: [
                                          Text(
                                            '120',
                                            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                                  color: const Color(0xFF1565C0),
                                                  fontWeight: FontWeight.bold,
                                                ),
                                          ),
                                          Text(
                                            lang.translate('adopted'),
                                            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                                  color: const Color(0xFF1565C0),
                                                ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        Expanded(
                          child: ListView(
                            padding: AppSpacing.paddingLg,
                            children: [
                              SupportAppCard(onTap: _openSupportLink),
                              const SizedBox(height: AppSpacing.lg),

                              if (auth.isAdmin)
                                StreamBuilder<List<Shelter>>(
                                  stream: _shelterService.watchPendingShelters(),
                                  builder: (context, pendingSnap) {
                                    final pending = pendingSnap.data ?? const <Shelter>[];

                                    if (pending.isEmpty) {
                                      return const SizedBox.shrink();
                                    }

                                    return Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                          decoration: BoxDecoration(
                                            color: Colors.orange.withValues(alpha: 0.10),
                                            borderRadius: BorderRadius.circular(AppRadius.lg),
                                            border: Border.all(
                                              color: Colors.orange.withValues(alpha: 0.30),
                                            ),
                                          ),
                                          child: Row(
                                            children: [
                                              const Icon(
                                                Icons.hourglass_top_rounded,
                                                color: Colors.orange,
                                                size: 18,
                                              ),
                                              const SizedBox(width: 8),
                                              Text(
                                                '${pending.length} shelter${pending.length == 1 ? '' : 's'} pending approval',
                                                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                                                      color: Colors.orange[800],
                                                    ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        const SizedBox(height: AppSpacing.md),
                                        ...pending.map(
                                          (shelter) => _PendingShelterCard(shelter: shelter),
                                        ),
                                        const SizedBox(height: AppSpacing.lg),
                                        Divider(color: Theme.of(context).colorScheme.outline),
                                        const SizedBox(height: AppSpacing.lg),
                                      ],
                                    );
                                  },
                                ),

                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    lang.translate('nearbyShelters'),
                                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                          fontWeight: FontWeight.bold,
                                        ),
                                  ),
                                  Text(
                                    lang.translate('seeAll'),
                                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                                          color: Theme.of(context).colorScheme.primary,
                                        ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: AppSpacing.md),
                              ...shelters.map((shelter) => ShelterCard(shelter: shelter)),
                              const SizedBox(height: 80),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                );
              },
            );
          },
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          final auth = context.read<AuthProvider>();

          if (!auth.isSignedIn) {
            context.push('/auth?from=%2Fregister-shelter');
            return;
          }

          context.push('/register-shelter');
        },
        icon: const Icon(Icons.add),
        label: Text(lang.translate('registerShelter')),
      ),
    );
  }
}

class _PendingShelterCard extends StatefulWidget {
  final Shelter shelter;

  const _PendingShelterCard({required this.shelter});

  @override
  State<_PendingShelterCard> createState() => _PendingShelterCardState();
}

class _PendingShelterCardState extends State<_PendingShelterCard> {
  final ShelterService _shelterService = ShelterService();
  bool _isUpdating = false;

  Future<void> _approveShelter() async {
    setState(() => _isUpdating = true);

    try {
      await _shelterService.approveShelter(widget.shelter.id);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${widget.shelter.name} approved and published.'),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to approve shelter. Please try again.'),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isUpdating = false);
      }
    }
  }

  Future<void> _rejectShelter() async {
    final ok = await showModalBottomSheet<bool>(
      context: context,
      showDragHandle: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      builder: (context) => Padding(
        padding: AppSpacing.paddingLg,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Reject shelter?',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              'This will remove "${widget.shelter.name}" from the pending approval list.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.lightSecondaryText,
                  ),
            ),
            const SizedBox(height: AppSpacing.lg),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => context.pop(false),
                    child: const Text('Cancel'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => context.pop(true),
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                    child: const Text(
                      'Reject',
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );

    if (ok != true) return;

    setState(() => _isUpdating = true);

    try {
      await _shelterService.rejectShelter(widget.shelter.id);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${widget.shelter.name} rejected.'),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to reject shelter. Please try again.'),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isUpdating = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final shelter = widget.shelter;

    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(AppRadius.xl),
        border: Border.all(color: Colors.orange.withValues(alpha: 0.40)),
      ),
      child: Padding(
        padding: AppSpacing.paddingMd,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: Colors.orange.withValues(alpha: 0.10),
                    borderRadius: BorderRadius.circular(AppRadius.md),
                  ),
                  child: const Icon(
                    Icons.storefront_rounded,
                    color: Colors.orange,
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    spacing: 4,
                    children: [
                      Text(
                        shelter.name,
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        shelter.location,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: AppColors.lightSecondaryText,
                            ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (shelter.email.isNotEmpty)
                        Text(
                          shelter.email,
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: AppColors.lightSecondaryText,
                              ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _isUpdating ? null : _rejectShelter,
                    icon: const Icon(Icons.close_rounded),
                    label: const Text('Reject'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _isUpdating ? null : _approveShelter,
                    icon: _isUpdating
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Icons.check_rounded),
                    label: const Text('Approve'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class AuthActionChip extends StatelessWidget {
  const AuthActionChip({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, auth, _) {
        if (auth.isSignedIn) {
          return InkWell(
            onTap: () => context.push('/dashboard'),
            borderRadius: BorderRadius.circular(999),
            child: Container(
              height: 40,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                borderRadius: BorderRadius.circular(999),
                border: Border.all(color: Theme.of(context).colorScheme.outline),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                spacing: 8,
                children: [
                  Icon(
                    Icons.dashboard_rounded,
                    size: 18,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  Text(
                    'Dashboard',
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                          color: AppColors.lightPrimaryText,
                        ),
                  ),
                ],
              ),
            ),
          );
        }

        return InkWell(
          onTap: () => context.push('/auth'),
          borderRadius: BorderRadius.circular(999),
          child: Container(
            height: 40,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.circular(999),
              border: Border.all(color: Theme.of(context).colorScheme.outline),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              spacing: 8,
              children: [
                Icon(
                  Icons.login_rounded,
                  size: 18,
                  color: Theme.of(context).colorScheme.primary,
                ),
                Text(
                  'Login',
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        color: AppColors.lightPrimaryText,
                      ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class LanguageSelector extends StatelessWidget {
  final String currentLanguage;

  const LanguageSelector({
    super.key,
    required this.currentLanguage,
  });

  @override
  Widget build(BuildContext context) {
    final lang = Provider.of<LanguageProvider>(context, listen: false);

    return Container(
      width: 140,
      height: 40,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: Theme.of(context).colorScheme.outline),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: currentLanguage,
          icon: Icon(
            Icons.language_rounded,
            color: Theme.of(context).colorScheme.primary,
            size: 20,
          ),
          dropdownColor: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(AppRadius.md),
          items: ['English', 'German', 'Ukrainian', 'Russian'].map((String language) {
            return DropdownMenuItem<String>(
              value: language,
              child: Text(
                language,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppColors.lightPrimaryText,
                    ),
              ),
            );
          }).toList(),
          onChanged: (String? newValue) {
            if (newValue != null) {
              lang.setLanguage(newValue);
            }
          },
        ),
      ),
    );
  }
}

class ShelterCard extends StatelessWidget {
  final Shelter shelter;

  const ShelterCard({
    super.key,
    required this.shelter,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => context.push('/shelter/${shelter.id}'),
      child: Container(
        margin: const EdgeInsets.only(bottom: AppSpacing.lg),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(AppRadius.xl),
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
            Stack(
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(AppRadius.xl),
                  ),
                  child: AppNetworkImage(
                    url: shelter.imageUrl,
                    height: 180,
                    width: double.infinity,
                    fit: BoxFit.cover,
                  ),
                ),
                Positioned(
                  top: 12,
                  right: 12,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.8),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Row(
                      spacing: 4,
                      children: [
                        const Icon(
                          Icons.star_rounded,
                          color: AppColors.lightAccent,
                          size: 16,
                        ),
                        Text(
                          shelter.rating.toStringAsFixed(1),
                          style: Theme.of(context).textTheme.labelMedium?.copyWith(
                                color: AppColors.lightPrimaryText,
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                      ],
                    ),
                  ),
                ),
                Positioned(
                  top: 12,
                  left: 12,
                  child: Consumer<AuthProvider>(
                    builder: (context, auth, _) {
                      if (!auth.isAdmin) return const SizedBox.shrink();

                      return Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.85),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: IconButton(
                          icon: const Icon(Icons.delete_outline_rounded, size: 18),
                          color: Colors.red,
                          padding: EdgeInsets.zero,
                          onPressed: () async {
                            final ok = await showModalBottomSheet<bool>(
                              context: context,
                              showDragHandle: true,
                              backgroundColor: Theme.of(context).colorScheme.surface,
                              builder: (context) => _AdminDeleteShelterSheet(
                                name: shelter.name,
                              ),
                            );

                            if (ok == true) {
                              await ShelterService().deleteShelter(shelter.id);
                            }
                          },
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
            Padding(
              padding: AppSpacing.paddingLg,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                spacing: AppSpacing.xs,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          shelter.name,
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const Icon(
                        Icons.arrow_forward_ios_rounded,
                        size: 16,
                        color: AppColors.lightHint,
                      ),
                    ],
                  ),
                  Row(
                    spacing: 4,
                    children: [
                      Icon(
                        Icons.location_on_rounded,
                        size: 16,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      Expanded(
                        child: Text(
                          shelter.location,
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: AppColors.lightSecondaryText,
                              ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    shelter.description,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppColors.lightSecondaryText,
                        ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
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

class SupportAppCard extends StatelessWidget {
  final VoidCallback onTap;

  const SupportAppCard({
    super.key,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadius.xl),
      child: Container(
        padding: AppSpacing.paddingLg,
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(AppRadius.xl),
          border: Border.all(color: Theme.of(context).colorScheme.outline),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(AppRadius.lg),
              ),
              child: Icon(
                Icons.volunteer_activism_rounded,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Support Paws New Home',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Donate via PayPal',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppColors.lightSecondaryText,
                        ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary,
                borderRadius: BorderRadius.circular(999),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.open_in_new_rounded,
                    size: 16,
                    color: Colors.white,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'PayPal',
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
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

class _AdminDeleteShelterSheet extends StatelessWidget {
  final String name;

  const _AdminDeleteShelterSheet({
    required this.name,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: AppSpacing.paddingLg,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Delete shelter?',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            'Remove "$name" from the public list.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.lightSecondaryText,
                ),
          ),
          const SizedBox(height: AppSpacing.lg),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => context.pop(false),
                  child: const Text('Cancel'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: () => context.pop(true),
                  child: const Text(
                    'Delete',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
