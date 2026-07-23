import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:paws_without_borders/models/shelter.dart';
import 'package:paws_without_borders/providers/auth_provider.dart';
import 'package:paws_without_borders/services/shelter_service.dart';
import 'package:paws_without_borders/theme.dart';
import 'package:paws_without_borders/widgets/app_network_image.dart';

class AdminShelterEditorScreen extends StatefulWidget {
  final String shelterId;
  const AdminShelterEditorScreen({super.key, required this.shelterId});

  @override
  State<AdminShelterEditorScreen> createState() => _AdminShelterEditorScreenState();
}

class _AdminShelterEditorScreenState extends State<AdminShelterEditorScreen> {
  final ShelterService _shelterService = ShelterService();
  final ImagePicker _picker = ImagePicker();

  bool _loading = true;
  bool _saving = false;
  Shelter? _shelter;

  bool _uploadingImage = false;
  XFile? _picked;

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
    final s = await _shelterService.getShelterById(widget.shelterId);
    if (!mounted) return;
    setState(() {
      _shelter = s;
      _loading = false;
    });
    if (s == null) return;
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
    final existing = _shelter;
    if (existing == null) return;
    setState(() => _saving = true);
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
      updatedAt: DateTime.now(),
    );
    await _shelterService.updateShelter(updated);
    if (!mounted) return;
    setState(() {
      _shelter = updated;
      _saving = false;
    });
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Saved')));
  }

  Future<void> _pickShelterImage() async {
    if (_uploadingImage) return;
    final shelter = _shelter;
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
      setState(() => _shelter = updated);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Photo updated.')));
    } catch (e) {
      if (!mounted) return;
      final msg = e is ShelterImageUploadFailure ? e.message : 'Image upload failed. Please try again.';
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
    } finally {
      if (mounted) setState(() => _uploadingImage = false);
    }
  }

  Future<void> _approveShelter() async {
    final shelter = _shelter;
    if (shelter == null) return;
    setState(() => _saving = true);
    final updated = shelter.copyWith(status: 'active', updatedAt: DateTime.now());
    await _shelterService.updateShelter(updated);
    if (!mounted) return;
    setState(() {
      _shelter = updated;
      _saving = false;
    });
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Shelter approved and now visible to public.')));
  }

  Future<void> _suspendShelter() async {
    final shelter = _shelter;
    if (shelter == null) return;
    setState(() => _saving = true);
    final updated = shelter.copyWith(status: 'suspended', updatedAt: DateTime.now());
    await _shelterService.updateShelter(updated);
    if (!mounted) return;
    setState(() {
      _shelter = updated;
      _saving = false;
    });
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Shelter suspended.')));
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    if (!auth.isAdmin) {
      return Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        body: Center(
          child: Padding(
            padding: AppSpacing.paddingLg,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.lock_outline_rounded, size: 48),
                const SizedBox(height: 12),
                Text('Admin access required', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),
                ElevatedButton(onPressed: () => context.go('/'), child: const Text('Go home', style: TextStyle(color: Colors.white))),
              ],
            ),
          ),
        ),
      );
    }

    final shelter = _shelter;
    final isPending = shelter?.status == 'pending';
    final isSuspended = shelter?.status == 'suspended';

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : Column(
                children: [
                  Padding(
                    padding: AppSpacing.paddingLg,
                    child: Row(
                      children: [
                        IconButton(
                          onPressed: () => context.pop(),
                          icon: const Icon(Icons.arrow_back_rounded),
                          color: AppColors.lightPrimaryText,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Edit shelter', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
                              if (isPending)
                                Container(
                                  margin: const EdgeInsets.only(top: 4),
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: Colors.orange.withValues(alpha: 0.15),
                                    borderRadius: BorderRadius.circular(999),
                                  ),
                                  child: Text('Pending approval', style: Theme.of(context).textTheme.labelSmall?.copyWith(color: Colors.orange)),
                                )
                              else if (isSuspended)
                                Container(
                                  margin: const EdgeInsets.only(top: 4),
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: Colors.red.withValues(alpha: 0.15),
                                    borderRadius: BorderRadius.circular(999),
                                  ),
                                  child: Text('Suspended', style: Theme.of(context).textTheme.labelSmall?.copyWith(color: Colors.red)),
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (isPending || isSuspended)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                      child: SizedBox(
                        width: double.infinity,
                        height: 48,
                        child: ElevatedButton.icon(
                          onPressed: _saving ? null : _approveShelter,
                          style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                          icon: const Icon(Icons.check_circle_outline_rounded, color: Colors.white),
                          label: const Text('Approve & make public', style: TextStyle(color: Colors.white)),
                        ),
                      ),
                    ),
                  if (shelter != null && shelter.status == 'active')
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                      child: SizedBox(
                        width: double.infinity,
                        height: 48,
                        child: OutlinedButton.icon(
                          onPressed: _saving ? null : _suspendShelter,
                          style: OutlinedButton.styleFrom(foregroundColor: Colors.red, side: const BorderSide(color: Colors.red)),
                          icon: const Icon(Icons.block_rounded),
                          label: const Text('Suspend shelter'),
                        ),
                      ),
                    ),
                  if (isPending || isSuspended || (shelter != null && shelter.status == 'active'))
                    const SizedBox(height: AppSpacing.md),
                  Expanded(
                    child: SingleChildScrollView(
                      padding: AppSpacing.paddingLg,
                      child: Column(
                        spacing: AppSpacing.md,
                        children: [
                          _AdminShelterImageCard(
                            shelter: _shelter,
                            picked: _picked,
                            uploading: _uploadingImage,
                            onPick: _pickShelterImage,
                          ),
                          TextField(controller: _name, decoration: const InputDecoration(prefixIcon: Icon(Icons.home_rounded), hintText: 'Name')),
                          TextField(controller: _location, decoration: const InputDecoration(prefixIcon: Icon(Icons.location_on_rounded), hintText: 'Location')),
                          TextField(controller: _description, maxLines: 4, decoration: const InputDecoration(hintText: 'Description')),
                          TextField(controller: _email, decoration: const InputDecoration(prefixIcon: Icon(Icons.email_rounded), hintText: 'Email')),
                          TextField(controller: _whatsapp, decoration: const InputDecoration(prefixIcon: Icon(Icons.phone_rounded), hintText: 'WhatsApp')),
                          TextField(controller: _telegram, decoration: const InputDecoration(prefixIcon: Icon(Icons.send_rounded), hintText: 'Telegram')),
                          TextField(controller: _instagram, decoration: const InputDecoration(prefixIcon: Icon(Icons.camera_alt_rounded), hintText: 'Instagram')),
                          TextField(controller: _paypal, decoration: const InputDecoration(prefixIcon: Icon(Icons.payments_rounded), hintText: 'PayPal')),
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
                                const Expanded(child: Text('International delivery')),
                                Switch(value: _intl, onChanged: (v) => setState(() => _intl = v)),
                              ],
                            ),
                          ),
                          const SizedBox(height: 4),
                          SizedBox(
                            width: double.infinity,
                            height: 52,
                            child: ElevatedButton.icon(
                              onPressed: _saving ? null : _save,
                              icon: _saving
                                  ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                                  : const Icon(Icons.save_rounded, color: Colors.white),
                              label: const Text('Save', style: TextStyle(color: Colors.white)),
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

class _AdminShelterImageCard extends StatelessWidget {
  final Shelter? shelter;
  final XFile? picked;
  final bool uploading;
  final VoidCallback onPick;

  const _AdminShelterImageCard({required this.shelter, required this.picked, required this.uploading, required this.onPick});

  @override
  Widget build(BuildContext context) {
    final s = shelter;
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
            else if (s != null && s.imageUrl.trim().startsWith('http'))
              AppNetworkImage(url: s.imageUrl, fit: BoxFit.cover)
            else if (s != null && s.imageUrl.trim().startsWith('assets/'))
              Image.asset(s.imageUrl, fit: BoxFit.cover)
            else
              Container(
                alignment: Alignment.center,
                color: Theme.of(context).colorScheme.surface,
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
