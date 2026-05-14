import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:paws_without_borders/models/animal.dart';
import 'package:paws_without_borders/models/shelter.dart';
import 'package:paws_without_borders/providers/auth_provider.dart';
import 'package:paws_without_borders/services/animal_service.dart';
import 'package:paws_without_borders/services/shelter_service.dart';
import 'package:paws_without_borders/theme.dart';
import 'package:paws_without_borders/widgets/animal_network_image.dart';

class AnimalEditorScreen extends StatefulWidget {
  final String? animalId;
  const AnimalEditorScreen({super.key, this.animalId});

  @override
  State<AnimalEditorScreen> createState() => _AnimalEditorScreenState();
}

class _AnimalEditorScreenState extends State<AnimalEditorScreen> {
  final ShelterService _shelterService = ShelterService();
  final AnimalService _animalService = AnimalService();
  final ImagePicker _picker = ImagePicker();

  bool _loading = true;
  bool _saving = false;
  Shelter? _shelter;
  Animal? _animal;
  List<XFile> _picked = const [];

  final _name = TextEditingController();
  final _age = TextEditingController();
  final _description = TextEditingController();
  final _weight = TextEditingController();
  String _gender = '';
  String _status = 'available';

  @override
  void initState() {
    super.initState();
    _init();
  }

  @override
  void dispose() {
    _name.dispose();
    _age.dispose();
    _description.dispose();
    _weight.dispose();
    super.dispose();
  }

  Future<void> _init() async {
    try {
      final auth = context.read<AuthProvider>();
      final shelter = await _shelterService.getShelterByOwnerId(auth.uid);
      Animal? animal;
      if (widget.animalId != null) {
        animal = await _animalService.getAnimalById(widget.animalId!);
      }

      if (!mounted) return;
      setState(() {
        _shelter = shelter;
        _animal = animal;
        _loading = false;
      });

      if (animal != null) {
        _name.text = animal.name;
        _age.text = animal.age;
        _description.text = animal.description;
        _status = animal.status.toLowerCase();
        _gender = animal.gender;
        _weight.text = animal.weight;
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
    }
  }

  Future<void> _pickImage() async {
    final existingCount = _countExistingNetworkImages(_animal);
    if (existingCount >= 2) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Maximum 2 images allowed')));
      return;
    }

    final remaining = 2 - existingCount;
    final picked = await _picker.pickMultiImage();
    if (!mounted) return;
    if (picked.isEmpty) return;
    if (picked.length > remaining) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Maximum 2 images allowed')));
      return;
    }

    // Pre-validate file size (1MB) before upload.
    for (final f in picked) {
      final len = await f.length();
      if (len > 1024 * 1024) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Image too large')));
        return;
      }
    }

    setState(() => _picked = picked);
  }

  Future<void> _save() async {
    final shelter = _shelter;
    if (shelter == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Create your shelter profile first.')));
      return;
    }
    if (_name.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please enter a name.')));
      return;
    }

    setState(() => _saving = true);
    try {
      final now = DateTime.now();
      final existingUrls = _existingNetworkUrls(_animal);
      final nextUrls = [...existingUrls];

      if (_picked.isNotEmpty) {
        if (nextUrls.length + _picked.length > 2) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Maximum 2 images allowed')));
          return;
        }
        for (final f in _picked) {
          try {
            final uploaded = await _animalService.uploadAnimalImage(shelterId: shelter.id, file: f);
            nextUrls.add(uploaded);
          } catch (e) {
            if (!mounted) return;
            final msg = e is ImageUploadFailure ? e.message : 'Image upload failed. Please try again.';
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
            return;
          }
        }
      }

      // We never auto-insert hardcoded placeholder images. UI can show a placeholder when empty.
      final imageUrl = nextUrls.isNotEmpty ? nextUrls.first : '';

      if (_animal == null) {
        final animal = Animal(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          shelterId: shelter.id,
          name: _name.text.trim(),
          description: _description.text.trim(),
          age: _age.text.trim(),
          imageUrl: imageUrl,
          imageUrls: nextUrls,
          status: _status,
          gender: _gender.trim(),
          breed: '',
          weight: _weight.text.trim(),
          createdAt: now,
          updatedAt: now,
        );
        await _animalService.addAnimal(animal);
      } else {
        final updated = _animal!.copyWith(
          name: _name.text.trim(),
          description: _description.text.trim(),
          age: _age.text.trim(),
          imageUrl: imageUrl,
          imageUrls: nextUrls,
          status: _status,
          gender: _gender.trim(),
          weight: _weight.text.trim(),
          updatedAt: now,
        );
        await _animalService.updateAnimal(updated);
      }

      if (!mounted) return;
      context.pop();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Failed to save animal.')));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  int _countExistingNetworkImages(Animal? a) => _existingNetworkUrls(a).length;

  List<String> _existingNetworkUrls(Animal? a) {
    if (a == null) return const [];
    final urls = <String>[];
    void add(String u) {
      final t = u.trim();
      if (t.isEmpty) return;
      if (!t.startsWith('http')) return;
      if (!urls.contains(t)) urls.add(t);
    }

    add(a.imageUrl);
    for (final u in a.imageUrls) add(u);
    if (urls.length > 2) return urls.sublist(0, 2);
    return urls;
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.animalId != null;
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
                          child: Text(
                            isEdit ? 'Edit animal' : 'Add animal',
                            style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: SingleChildScrollView(
                      padding: AppSpacing.paddingLg,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Container(
                            height: 160,
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
                                  if (_picked.isNotEmpty)
                                    FutureBuilder(
                                      future: _picked.first.readAsBytes(),
                                      builder: (context, snap) {
                                        final bytes = snap.data;
                                        if (bytes == null) return const SizedBox.shrink();
                                        return Image.memory(bytes, fit: BoxFit.cover);
                                      },
                                    )
                                  else
                                    AnimalNetworkImage(
                                      imageUrl: _animal?.imageUrl.trim().isNotEmpty == true
                                          ? _animal!.imageUrl
                                          : (_animal?.imageUrls.isNotEmpty == true ? _animal!.imageUrls.first : ''),
                                      fit: BoxFit.cover,
                                    ),
                                  Align(
                                    alignment: Alignment.bottomRight,
                                    child: Padding(
                                      padding: const EdgeInsets.all(12),
                                      child: FilledButton.icon(
                                        onPressed: _pickImage,
                                        icon: const Icon(Icons.photo_rounded),
                                        label: const Text('Upload'),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: AppSpacing.lg),
                          TextField(controller: _name, decoration: const InputDecoration(prefixIcon: Icon(Icons.pets_rounded), hintText: 'Name')),
                          const SizedBox(height: AppSpacing.md),
                          TextField(controller: _age, decoration: const InputDecoration(prefixIcon: Icon(Icons.event_note_rounded), hintText: 'Age')),
                          const SizedBox(height: AppSpacing.md),
                          DropdownButtonFormField<String>(
                            value: _gender,
                            decoration: const InputDecoration(prefixIcon: Icon(Icons.wc_rounded), hintText: 'Gender'),
                            items: const [
                              DropdownMenuItem(value: '', child: Text('Not set')),
                              DropdownMenuItem(value: 'Male', child: Text('Male')),
                              DropdownMenuItem(value: 'Female', child: Text('Female')),
                              DropdownMenuItem(value: 'Unknown', child: Text('Unknown')),
                            ],
                            onChanged: (v) => setState(() => _gender = v ?? ''),
                          ),
                          const SizedBox(height: AppSpacing.md),
                          TextField(
                            controller: _weight,
                            decoration: const InputDecoration(prefixIcon: Icon(Icons.monitor_weight_outlined), hintText: 'Weight (e.g., 18 kg)'),
                            textInputAction: TextInputAction.next,
                          ),
                          const SizedBox(height: AppSpacing.md),
                          DropdownButtonFormField<String>(
                            value: _status,
                            decoration: const InputDecoration(prefixIcon: Icon(Icons.flag_rounded)),
                            items: const [
                              DropdownMenuItem(value: 'available', child: Text('available')),
                              DropdownMenuItem(value: 'adopted', child: Text('adopted')),
                            ],
                            onChanged: (v) => setState(() => _status = v ?? 'available'),
                          ),
                          const SizedBox(height: AppSpacing.md),
                          TextField(controller: _description, maxLines: 4, decoration: const InputDecoration(hintText: 'Description')),
                          const SizedBox(height: AppSpacing.xl),
                          SizedBox(
                            height: 52,
                            child: ElevatedButton.icon(
                              onPressed: _saving ? null : _save,
                              icon: _saving
                                  ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                                  : const Icon(Icons.save_rounded, color: Colors.white),
                              label: Text(isEdit ? 'Save' : 'Create', style: const TextStyle(color: Colors.white)),
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
