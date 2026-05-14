import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:paws_without_borders/models/shelter.dart';
import 'package:paws_without_borders/services/shelter_service.dart';
import 'package:paws_without_borders/providers/language_provider.dart';
import 'package:paws_without_borders/providers/auth_provider.dart';
import 'package:paws_without_borders/theme.dart';

class ShelterRegistrationScreen extends StatefulWidget {
  const ShelterRegistrationScreen({super.key});

  @override
  State<ShelterRegistrationScreen> createState() => _ShelterRegistrationScreenState();
}

class _ShelterRegistrationScreenState extends State<ShelterRegistrationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _locationController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _emailController = TextEditingController();
  final _whatsappController = TextEditingController();
  final _telegramController = TextEditingController();
  final _instagramController = TextEditingController();
  final _paypalController = TextEditingController();
  final ShelterService _shelterService = ShelterService();
  final ImagePicker _picker = ImagePicker();

  XFile? _pickedImage;
  bool _isSubmitting = false;

  @override
  void dispose() {
    _nameController.dispose();
    _locationController.dispose();
    _descriptionController.dispose();
    _emailController.dispose();
    _whatsappController.dispose();
    _telegramController.dispose();
    _instagramController.dispose();
    _paypalController.dispose();
    super.dispose();
  }

  Future<void> _submitForm() async {
    final auth = context.read<AuthProvider>();
    if (!auth.isSignedIn) {
      context.push('/auth?from=%2Fregister-shelter');
      return;
    }

    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() => _isSubmitting = true);

    try {
      final now = DateTime.now();
      final shelterId = DateTime.now().millisecondsSinceEpoch.toString();

      // Create shelter first so Storage rules can validate ownership (if configured that way).
      // Then upload/update image_url.
      var shelter = Shelter(
        id: shelterId,
        name: _nameController.text.trim(),
        location: _locationController.text.trim(),
        description: _descriptionController.text.trim(),
        imageUrl: '',
        galleryImages: const [],
        rating: 5.0,
        email: _emailController.text.trim(),
        whatsapp: _whatsappController.text.trim(),
        telegram: _telegramController.text.trim(),
        instagram: _instagramController.text.trim(),
        paypal: _paypalController.text.trim(),
        internationalDelivery: false,
        ownerId: auth.uid,
        createdAt: now,
        updatedAt: now,
      );

      await _shelterService.addShelter(shelter);

      if (_pickedImage != null) {
        final bytes = await _pickedImage!.readAsBytes();
        if (bytes.lengthInBytes > 1024 * 1024) {
          throw const ShelterImagePickFailure('Image too large (max 1MB).');
        }
        final imageUrl = await _shelterService.uploadShelterImage(shelterId: shelterId, file: _pickedImage!);
        shelter = shelter.copyWith(imageUrl: imageUrl, galleryImages: [imageUrl], updatedAt: DateTime.now());
        await _shelterService.updateShelter(shelter);
      }

      if (!mounted) return;
      context.pop();
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Shelter registered successfully!')));
    } catch (e) {
      if (!mounted) return;
      final msg = switch (e) {
        ShelterImagePickFailure(:final message) => message,
        ShelterImageUploadFailure(:final message) => message,
        _ => 'Failed to register shelter. Please try again.',
      };
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  Future<void> _pickImage() async {
    final picked = await _picker.pickImage(source: ImageSource.gallery, imageQuality: 100);
    if (!mounted) return;
    if (picked == null) return;

    // Pre-validate file size (1MB) before any upload.
    final len = await picked.length();
    if (!mounted) return;
    if (len > 1024 * 1024) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Image too large (max 1MB).')));
      return;
    }

    setState(() => _pickedImage = picked);
  }

  @override
  Widget build(BuildContext context) {
    final lang = Provider.of<LanguageProvider>(context);
    
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: Column(
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
                    lang.translate('registerShelter'),
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(width: 48),
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: AppSpacing.paddingLg,
                child: Form(
                  key: _formKey,
                  child: Column(
                    spacing: AppSpacing.lg,
                    children: [
                      SectionHeader(icon: Icons.photo_camera_rounded, title: 'Shelter photo'),
                      _ShelterImagePickerCard(
                        pickedImage: _pickedImage,
                        onPick: _isSubmitting ? null : _pickImage,
                      ),
                      Text(
                        'Optional. You can add or change this later from your Dashboard → Profile.',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.lightSecondaryText),
                        textAlign: TextAlign.left,
                      ),
                      Container(
                        padding: AppSpacing.paddingLg,
                        decoration: BoxDecoration(
                          color: const Color(0xFFE8F5E9),
                          borderRadius: BorderRadius.circular(AppRadius.lg),
                          border: Border.all(color: const Color(0xFFC8E6C9)),
                        ),
                        child: Row(
                          spacing: AppSpacing.md,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(Icons.info_outline_rounded, color: Theme.of(context).colorScheme.primary, size: 24),
                            Expanded(
                              child: Text(
                                'Join our network of rescuers. Fill out the details below to list your shelter on Paws Without Borders.',
                                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  color: AppColors.lightPrimaryText,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      SectionHeader(
                        icon: Icons.business_rounded,
                        title: lang.translate('basicInfo'),
                      ),
                      FormInput(
                        label: lang.translate('shelterName'),
                        hint: 'e.g. Happy Paws Sanctuary',
                        icon: Icons.home_rounded,
                        controller: _nameController,
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Please enter shelter name';
                          }
                          return null;
                        },
                      ),
                      FormInput(
                        label: lang.translate('country'),
                        hint: 'e.g. Berlin, Germany',
                        icon: Icons.location_on_rounded,
                        controller: _locationController,
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Please enter location';
                          }
                          return null;
                        },
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        spacing: AppSpacing.xs,
                        children: [
                          Text(
                            lang.translate('description'),
                            style: Theme.of(context).textTheme.labelLarge?.copyWith(
                              color: AppColors.lightPrimaryText,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          TextFormField(
                            controller: _descriptionController,
                            maxLines: 4,
                            decoration: InputDecoration(
                              hintText: 'Tell us about your mission and the animals you care for...',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(AppRadius.md),
                                borderSide: BorderSide(color: Theme.of(context).colorScheme.outline),
                              ),
                            ),
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'Please enter description';
                              }
                              return null;
                            },
                          ),
                        ],
                      ),
                      SectionHeader(
                        icon: Icons.contact_support_rounded,
                        title: lang.translate('contactSocial'),
                      ),
                      FormInput(
                        label: lang.translate('email'),
                        hint: 'contact@shelter.org',
                        icon: Icons.email_rounded,
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Please enter email';
                          }
                          if (!value.contains('@')) {
                            return 'Please enter valid email';
                          }
                          return null;
                        },
                      ),
                      FormInput(
                        label: lang.translate('whatsapp'),
                        hint: '+1234567890',
                        icon: Icons.phone_rounded,
                        controller: _whatsappController,
                        keyboardType: TextInputType.phone,
                      ),
                      FormInput(
                        label: lang.translate('telegram'),
                        hint: '@shelter_handle',
                        icon: Icons.send_rounded,
                        controller: _telegramController,
                      ),
                      FormInput(
                        label: lang.translate('instagram'),
                        hint: 'instagram.com/shelter',
                        icon: Icons.camera_alt_rounded,
                        controller: _instagramController,
                      ),
                      SectionHeader(
                        icon: Icons.favorite_rounded,
                        title: lang.translate('support'),
                      ),
                      FormInput(
                        label: lang.translate('paypal'),
                        hint: 'paypal.me/your-shelter',
                        icon: Icons.payments_rounded,
                        controller: _paypalController,
                      ),
                      Text(
                        'This link will be used for the \'Donate\' button on your profile.',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.lightSecondaryText),
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      SizedBox(
                        width: double.infinity,
                        height: 48,
                        child: ElevatedButton.icon(
                          onPressed: _isSubmitting ? null : _submitForm,
                          icon: _isSubmitting
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                )
                              : const Icon(Icons.check_circle_rounded),
                          label: Text(lang.translate('submitRegistration')),
                        ),
                      ),
                      Center(
                        child: Text(
                          'By submitting, you agree to our community guidelines.',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.lightHint),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xl),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class ShelterImagePickFailure implements Exception {
  final String message;
  const ShelterImagePickFailure(this.message);
}

class _ShelterImagePickerCard extends StatelessWidget {
  final XFile? pickedImage;
  final VoidCallback? onPick;

  const _ShelterImagePickerCard({required this.pickedImage, required this.onPick});

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
            if (pickedImage != null)
              FutureBuilder(
                future: pickedImage!.readAsBytes(),
                builder: (context, snap) {
                  final bytes = snap.data;
                  if (bytes == null) return const SizedBox.shrink();
                  return Image.memory(bytes, fit: BoxFit.cover);
                },
              )
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
                onPressed: onPick,
                icon: const Icon(Icons.upload_rounded),
                label: Text(pickedImage != null ? 'Change photo' : 'Add photo'),
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
                  '1 photo max • 1MB limit',
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

class SectionHeader extends StatelessWidget {
  final IconData icon;
  final String title;

  const SectionHeader({super.key, required this.icon, required this.title});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: AppSpacing.xs,
      children: [
        Row(
          spacing: AppSpacing.sm,
          children: [
            Icon(icon, color: Theme.of(context).colorScheme.primary, size: 20),
            Text(
              title,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: AppColors.lightPrimaryText,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        Divider(color: Theme.of(context).colorScheme.outline),
      ],
    );
  }
}

class FormInput extends StatelessWidget {
  final String label;
  final String hint;
  final IconData icon;
  final TextEditingController controller;
  final TextInputType? keyboardType;
  final String? Function(String?)? validator;

  const FormInput({
    super.key,
    required this.label,
    required this.hint,
    required this.icon,
    required this.controller,
    this.keyboardType,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: AppSpacing.xs,
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.labelLarge?.copyWith(
            color: AppColors.lightPrimaryText,
            fontWeight: FontWeight.w600,
          ),
        ),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          decoration: InputDecoration(
            hintText: hint,
            prefixIcon: Icon(icon),
          ),
          validator: validator,
        ),
      ],
    );
  }
}
