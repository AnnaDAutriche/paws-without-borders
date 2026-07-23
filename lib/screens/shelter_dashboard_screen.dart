import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:paws_without_borders/models/animal.dart';
import 'package:paws_without_borders/models/shelter.dart';
import 'package:paws_without_borders/providers/auth_provider.dart';
import 'package:paws_without_borders/services/animal_service.dart';
import 'package:paws_without_borders/services/seed_service.dart';
import 'package:paws_without_borders/services/shelter_service.dart';
import 'package:paws_without_borders/theme.dart';
import 'package:paws_without_borders/widgets/app_network_image.dart';
import 'package:paws_without_borders/widgets/animal_network_image.dart';

class ShelterDashboardScreen extends StatefulWidget {
  const ShelterDashboardScreen({super.key});

  @override
  State<ShelterDashboardScreen> createState() => _ShelterDashboardScreenState();
}

class _ShelterDashboardScreenState extends State<ShelterDashboardScreen> {
  final ShelterService _shelterService = ShelterService();
  final AnimalService _animalService = AnimalService();
  final SeedService _seedService = SeedService();

  bool _loading = true;
  Shelter? _shelter;
  bool _saving = false;
  bool _deleting = false;

  final _name = TextEditingController();
  final _location = TextEditingController();
  final _description = TextEditingController();
  final _whatsapp = TextEditingController();
  final _telegram = TextEditingController();
  final _email = TextEditingController();
  final _instagram = TextEditingController();
  final _paypal = TextEditingController();
  bool _intl = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _name.dispose();
    _location.dispose();
    _description.dispose();
    _whatsapp.dispose();
    _telegram.dispose();
    _email.dispose();
    _instagram.dispose();
    _paypal.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final auth = context.read<AuthProvider>();
      final shelter = await _shelterService.getShelterByOwnerId(auth.uid);
      if (!mounted) return;
      setState(() {
        _shelter = shelter;
        _loading = false;
      });
      if (shelter != null) _hydrateControllers(shelter);
    } catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
    }
  }

  void _hydrateControllers(Shelter s) {
    _name.text = s.name;
    _location.text = s.location;
    _description.text = s.description;
    _whatsapp.text = s.whatsapp;
    _telegram.text = s.telegram;
    _email.text = s.email;
    _instagram.text = s.instagram;
    _paypal.text = s.paypal;
    _intl = s.internationalDelivery;
  }

  Future<void> _save() async {
    final auth = context.read<AuthProvider>();
    final existing = _shelter;
    if (existing == null) {
      context.push('/register-shelter');
      return;
    }

    setState(() => _saving = true);
    final now = DateTime.now();
    final updated = existing.copyWith(
      name: _name.text.trim(),
      location: _location.text.trim(),
      description: _description.text.trim(),
      whatsapp: _whatsapp.text.trim(),
      telegram: _telegram.text.trim(),
      email: _email.text.trim(),
      instagram: _instagram.text.trim(),
      paypal: _paypal.text.trim(),
      internationalDelivery: _intl,
      ownerId: auth.uid,
      updatedAt: now,
    );

    await _shelterService.updateShelter(updated);
    if (!mounted) return;
    setState(() {
      _shelter = updated;
      _saving = false;
    });
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Saved')));
  }

  Future<void> _deleteShelter() async {
    final shelter = _shelter;
    if (shelter == null) return;

    final ok = await showModalBottomSheet<bool>(
      context: context,
      showDragHandle: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      builder: (context) => const _ConfirmSheet(
        title: 'Delete shelter?',
        subtitle: 'Your shelter and all its data will be removed from the public listing. This cannot be undone.',
      ),
    );
    if (ok != true) return;

    setState(() => _deleting = true);
    await _shelterService.deleteShelter(shelter.id);
    if (!mounted) return;
    setState(() {
      _shelter = null;
      _deleting = false;
    });
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Shelter deleted.')));
  }

  Future<void> _seedSampleData() async {
    if (!kDebugMode) {
      debugPrint('Seed sample data blocked: not in debug mode.');
      return;
    }

    final auth = context.read<AuthProvider>();
    try {
      final email = (auth.email ?? '').trim();
      if (email.isEmpty) {
        throw StateError('Please sign in with an email account before seeding sample data.');
      }

      await _seedService.seedForUser(uid: auth.uid, email: email);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Sample data added.')));
      await _load();
    } catch (e) {
      if (!mounted) return;
      final msg = e is StateError ? e.message : 'Failed to seed sample data.';
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: _loading || _deleting
            ? const Center(child: CircularProgressIndicator())
            : Column(
                children: [
                  Padding(
                    padding: AppSpacing.paddingLg,
                    child: Row(
                      children: [
                        IconButton(
                          onPressed: () => context.go('/'),
                          icon: const Icon(Icons.arrow_back_rounded),
                          color: AppColors.lightPrimaryText,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Dashboard', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
                              Text(
                                auth.email ?? '',
                                style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.lightSecondaryText),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                        if (kDebugMode && auth.isAdmin)
                          IconButton(
                            tooltip: 'Seed sample data',
                            onPressed: _seedSampleData,
                            icon: Icon(Icons.auto_awesome_rounded, color: Theme.of(context).colorScheme.primary),
                          ),
                        if (_shelter != null)
                          IconButton(
                            tooltip: 'Delete shelter',
                            onPressed: _deleteShelter,
                            icon: const Icon(Icons.delete_outline_rounded, color: Colors.red),
                          ),
                        TextButton.icon(
                          onPressed: () async {
                            await auth.signOut();
                            if (context.mounted) context.go('/');
                          },
                          icon: const Icon(Icons.logout_rounded),
                          label: const Text('Sign out'),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: DefaultTabController(
                      length: 2,
                      child: Column(
                        children: [
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                            child: Container(
                              decoration: BoxDecoration(
                                color: Theme.of(context).colorScheme.surface,
                                borderRadius: BorderRadius.circular(AppRadius.lg),
                                border: Border.all(color: Theme.of(context).colorScheme.outline),
                              ),
                              child: TabBar(
                                dividerColor: Colors.transparent,
                                labelColor: Theme.of(context).colorScheme.primary,
                                unselectedLabelColor: AppColors.lightSecondaryText,
                                indicator: BoxDecoration(
                                  color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.10),
                                  borderRadius: BorderRadius.circular(AppRadius.lg),
                                ),
                                tabs: const [
                                  Tab(text: 'Profile'),
                                  Tab(text: 'Animals'),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: AppSpacing.md),
                          Expanded(
                            child: TabBarView(
                              children: [
                                _ProfileTab(
                                  shelter: _shelter,
                                  name: _name,
                                  location: _location,
                                  description: _description,
                                  whatsapp: _whatsapp,
                                  telegram: _telegram,
                                  email: _email,
                                  instagram: _instagram,
                                  paypal: _paypal,
                                  intl: _intl,
                                  onIntlChanged: (v) => setState(() => _intl = v),
                                  isSaving: _saving,
                                  onSave: _save,
                                  onShelterUpdated: (s) => setState(() => _shelter = s),
                                ),
                                _AnimalsTab(
                                  shelter: _shelter,
                                  animalService: _animalService,
                                ),
                              ],
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

class _ProfileTab extends StatefulWidget {
  final Shelter? shelter;
  final TextEditingController name;
  final TextEditingController location;
  final TextEditingController description;
  final TextEditingController whatsapp;
  final TextEditingController telegram;
  final TextEditingController email;
  final TextEditingController instagram;
  final TextEditingController paypal;
  final bool intl;
  final ValueChanged<bool> onIntlChanged;
  final bool isSaving;
  final VoidCallback onSave;
  final ValueChanged<Shelter> onShelterUpdated;

  const _ProfileTab({
    required this.shelter,
    required this.name,
    required this.location,
    required this.description,
    required this.whatsapp,
    required this.telegram,
    required this.email,
    required this.instagram,
    required this.paypal,
    required this.intl,
    required this.onIntlChanged,
    required this.isSaving,
    required this.onSave,
    required this.onShelterUpdated,
  });

  @override
  State<_ProfileTab> createState() => _ProfileTabState();
}

class _ProfileTabState extends State<_ProfileTab> {
  final ShelterService _shelterService = ShelterService();
  final ImagePicker _picker = ImagePicker();

  bool _uploadingImage = false;
  XFile? _picked;

  Future<void> _pickShelterImage() async {
    if (_uploadingImage) return;
    final shelter = widget.shelter;
    if (shelter == null) return;

    final picked = await _picker.pickImage(source: ImageSource.gallery, imageQuality: 100);
    if (!mounted) return;
    if (picked == null) return;

    final len = await picked.length();
    if (!mounted) return;
    if (len > 1024 * 1024 * 2) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Image too large (max 2MB).')));
      return;
    }

    setState(() => _picked = picked);
    await _uploadShelterImage(shelter: shelter, file: picked);
  }

  Future<void> _uploadShelterImage({required Shelter shelter, required XFile file}) async {
    setState(() => _uploadingImage = true);
    try {
      final url = await _shelterService.uploadShelterImage(shelterId: shelter.id, file: file);
      final updated = shelter.copyWith(imageUrl: url, galleryImages: [url], updatedAt: DateTime.now());
      await _shelterService.updateShelter(updated);
      if (!mounted) return;
      widget.onShelterUpdated(updated);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Photo updated.')));
    } catch (e) {
      if (!mounted) return;
      final msg = e is ShelterImageUploadFailure ? e.message : 'Image upload failed. Please try again.';
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
    } finally {
      if (mounted) setState(() => _uploadingImage = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final shelter = widget.shelter;
    if (shelter == null) {
      return Center(
        child: Padding(
          padding: AppSpacing.paddingLg,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.storefront_rounded, size: 48, color: Theme.of(context).colorScheme.primary),
              const SizedBox(height: 12),
              Text('No shelter profile yet', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Text(
                'Create your shelter profile to appear in the public list.',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppColors.lightSecondaryText),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              SizedBox(
                height: 48,
                child: ElevatedButton.icon(
                  onPressed: () => context.push('/register-shelter'),
                  icon: const Icon(Icons.add_business_rounded, color: Colors.white),
                  label: const Text('Create profile', style: TextStyle(color: Colors.white)),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return SingleChildScrollView(
      padding: AppSpacing.paddingLg,
      child: Column(
        spacing: AppSpacing.md,
        children: [
          _ShelterDashboardImageCard(
            shelter: shelter,
            picked: _picked,
            uploading: _uploadingImage,
            onPick: _pickShelterImage,
          ),
          _Field(label: 'Name', icon: Icons.home_rounded, controller: widget.name),
          _Field(label: 'Location', icon: Icons.location_on_rounded, controller: widget.location),
          _MultilineField(label: 'Description', controller: widget.description),
          _Field(label: 'Email', icon: Icons.email_rounded, controller: widget.email, keyboardType: TextInputType.emailAddress),
          _Field(label: 'WhatsApp', icon: Icons.phone_rounded, controller: widget.whatsapp),
          _Field(label: 'Telegram', icon: Icons.send_rounded, controller: widget.telegram),
          _Field(label: 'Instagram', icon: Icons.camera_alt_rounded, controller: widget.instagram),
          _Field(label: 'PayPal', icon: Icons.payments_rounded, controller: widget.paypal),
          Container(
            padding: AppSpacing.paddingMd,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.circular(AppRadius.lg),
              border: Border.all(color: Theme.of(context).colorScheme.outline),
            ),
            child: Row(
              children: [
                Icon(Icons.public_rounded, color: Theme.of(context).colorScheme.primary),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('International delivery', style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700)),
                      const SizedBox(height: 2),
                      Text(
                        'Show a badge on your public profile.',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.lightSecondaryText),
                      ),
                    ],
                  ),
                ),
                Switch(value: widget.intl, onChanged: widget.onIntlChanged),
              ],
            ),
          ),
          const SizedBox(height: 4),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton.icon(
              onPressed: widget.isSaving ? null : widget.onSave,
              icon: widget.isSaving
                  ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Icon(Icons.save_rounded, color: Colors.white),
              label: const Text('Save changes', style: TextStyle(color: Colors.white)),
            ),
          ),
        ],
      ),
    );
  }
}

class _ShelterDashboardImageCard extends StatelessWidget {
  final Shelter shelter;
  final XFile? picked;
  final bool uploading;
  final VoidCallback onPick;

  const _ShelterDashboardImageCard({required this.shelter, required this.picked, required this.uploading, required this.onPick});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 180,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(AppRadius.xl),
        border: Border.all(color: Theme.of(context).colorScheme.outline),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppRadius.xl),
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (picked != null)
              FutureBuilder(
                future: picked!.readAsBytes(),
                builder: (context, snap) {
                  final bytes = snap.data;
                  if (bytes == null) return const SizedBox.shrink();
                  return Image.memory(bytes, fit: BoxFit.cover);
                },
              )
            else if (shelter.imageUrl.trim().startsWith('http'))
              AppNetworkImage(url: shelter.imageUrl, fit: BoxFit.cover)
            else if (shelter.imageUrl.trim().startsWith('assets/'))
              Image.asset(shelter.imageUrl, fit: BoxFit.cover)
            else
              Container(
                color: Theme.of(context).colorScheme.surface,
                alignment: Alignment.center,
                child: Icon(Icons.photo_rounded, color: Theme.of(context).colorScheme.onSurfaceVariant, size: 44),
              ),
            Positioned(
              right: 12,
              bottom: 12,
              child: FilledButton.icon(
                onPressed: uploading ? null : onPick,
                icon: uploading
                    ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                    : const Icon(Icons.upload_rounded),
                label: const Text('Update photo'),
              ),
            ),
            Positioned(
              left: 12,
              bottom: 12,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.85),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  '1 photo max • 2MB limit',
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(color: AppColors.lightPrimaryText, fontWeight: FontWeight.w600),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AnimalsTab extends StatelessWidget {
  final Shelter? shelter;
  final AnimalService animalService;

  const _AnimalsTab({required this.shelter, required this.animalService});

  @override
  Widget build(BuildContext context) {
    if (shelter == null) {
      return Center(
        child: Text('Create your profile first.', style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppColors.lightSecondaryText)),
      );
    }

    return Stack(
      children: [
        StreamBuilder<List<Animal>>(
          stream: animalService.watchAnimalsByShelterId(shelter!.id),
          builder: (context, snap) {
            final items = snap.data ?? const <Animal>[];
            if (snap.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (items.isEmpty) {
              return Center(
                child: Padding(
                  padding: AppSpacing.paddingLg,
                  child: Text(
                    'No animals yet. Tap "Add animal" to create the first one.',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppColors.lightSecondaryText),
                    textAlign: TextAlign.center,
                  ),
                ),
              );
            }

            return ListView.separated(
              padding: AppSpacing.paddingLg.copyWith(bottom: 100),
              itemCount: items.length,
              separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.md),
              itemBuilder: (context, i) => _AnimalManageCard(animal: items[i], onDelete: () async {
                await animalService.deleteAnimal(items[i].id);
              }),
            );
          },
        ),
        Positioned(
          left: AppSpacing.lg,
          right: AppSpacing.lg,
          bottom: AppSpacing.lg,
          child: SizedBox(
            height: 52,
            child: ElevatedButton.icon(
              onPressed: () => context.push('/dashboard/animal/new'),
              icon: const Icon(Icons.add_rounded, color: Colors.white),
              label: const Text('Add animal', style: TextStyle(color: Colors.white)),
            ),
          ),
        ),
      ],
    );
  }
}

class _AnimalManageCard extends StatelessWidget {
  final Animal animal;
  final VoidCallback onDelete;

  const _AnimalManageCard({required this.animal, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(AppRadius.xl),
        border: Border.all(color: Theme.of(context).colorScheme.outline),
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: const BorderRadius.horizontal(left: Radius.circular(AppRadius.xl)),
            child: SizedBox(
               width: 96,
               height: 96,
               child: AnimalNetworkImage(
                 imageUrl: animal.imageUrl.trim().isNotEmpty
                     ? animal.imageUrl
                     : (animal.imageUrls.isNotEmpty ? animal.imageUrls.first : ''),
                 fit: BoxFit.cover,
               ),
            ),
          ),
          Expanded(
            child: Padding(
              padding: AppSpacing.paddingMd,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(animal.name, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  Text(
                    animal.status,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.lightSecondaryText),
                  ),
                ],
              ),
            ),
          ),
          Column(
            children: [
              IconButton(
                onPressed: () => context.push('/dashboard/animal/${animal.id}/edit'),
                icon: const Icon(Icons.edit_rounded),
                color: Theme.of(context).colorScheme.primary,
              ),
              IconButton(
                onPressed: () async {
                  final ok = await showModalBottomSheet<bool>(
                    context: context,
                    showDragHandle: true,
                    backgroundColor: Theme.of(context).colorScheme.surface,
                    builder: (context) => const _ConfirmSheet(title: 'Delete animal?', subtitle: 'This can\'t be undone.'),
                  );
                  if (ok == true) onDelete();
                },
                icon: const Icon(Icons.delete_outline_rounded),
                color: Colors.red,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ConfirmSheet extends StatelessWidget {
  final String title;
  final String subtitle;

  const _ConfirmSheet({required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: AppSpacing.paddingLg,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(title, style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text(subtitle, style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppColors.lightSecondaryText)),
          const SizedBox(height: AppSpacing.lg),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(onPressed: () => context.pop(false), child: const Text('Cancel')),
              ),
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

class _Field extends StatelessWidget {
  final String label;
  final IconData icon;
  final TextEditingController controller;
  final TextInputType? keyboardType;

  const _Field({required this.label, required this.icon, required this.controller, this.keyboardType});

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        prefixIcon: Icon(icon),
        hintText: label,
      ),
    );
  }
}

class _MultilineField extends StatelessWidget {
  final String label;
  final TextEditingController controller;

  const _MultilineField({required this.label, required this.controller});

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      maxLines: 4,
      decoration: InputDecoration(hintText: label),
    );
  }
}
