import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:paws_without_borders/models/animal.dart';
import 'package:paws_without_borders/models/shelter.dart';
import 'package:paws_without_borders/services/animal_service.dart';
import 'package:paws_without_borders/services/shelter_service.dart';
import 'package:paws_without_borders/providers/language_provider.dart';
import 'package:paws_without_borders/theme.dart';
import 'package:paws_without_borders/widgets/animal_network_image.dart';

class AnimalsListScreen extends StatefulWidget {
  final String shelterId;

  const AnimalsListScreen({super.key, required this.shelterId});

  @override
  State<AnimalsListScreen> createState() => _AnimalsListScreenState();
}

class _AnimalsListScreenState extends State<AnimalsListScreen> {
  final AnimalService _animalService = AnimalService();
  final ShelterService _shelterService = ShelterService();
  String _selectedFilter = 'All';

  @override
  Widget build(BuildContext context) {
    final lang = Provider.of<LanguageProvider>(context);

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: StreamBuilder<Shelter?>(
          stream: _shelterService.watchShelterById(widget.shelterId),
          builder: (context, shelterSnap) {
            final shelter = shelterSnap.data;
            return StreamBuilder<List<Animal>>(
              stream: _animalService.watchAnimalsByShelterId(widget.shelterId),
              builder: (context, animalsSnap) {
                final animals = animalsSnap.data ?? const <Animal>[];
                final filteredAnimals = _selectedFilter == 'All'
                    ? animals
                    : animals.where((a) => a.breed.toLowerCase().contains(_selectedFilter.toLowerCase())).toList();
                final isLoading = (shelterSnap.connectionState == ConnectionState.waiting && shelter == null) || animalsSnap.connectionState == ConnectionState.waiting;

                if (isLoading && animals.isEmpty) {
                  return const Center(child: CircularProgressIndicator());
                }
                return Stack(
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Container(
                          padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.lg, AppSpacing.lg, AppSpacing.sm),
                          child: Column(
                            spacing: AppSpacing.md,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Container(
                                    decoration: BoxDecoration(
                                      color: Theme.of(context).colorScheme.surface,
                                      borderRadius: BorderRadius.circular(AppRadius.md),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withValues(alpha: 0.05),
                                          blurRadius: 2,
                                          offset: const Offset(0, 1),
                                        ),
                                      ],
                                    ),
                                    child: IconButton(
                                      icon: const Icon(Icons.arrow_back_rounded),
                                      onPressed: () => context.pop(),
                                      color: AppColors.lightPrimaryText,
                                    ),
                                  ),
                                  Row(
                                    spacing: AppSpacing.sm,
                                    children: [
                                      IconButton(icon: const Icon(Icons.search_rounded), onPressed: () {}, color: AppColors.lightPrimaryText),
                                      IconButton(icon: const Icon(Icons.tune_rounded), onPressed: () {}, color: AppColors.lightPrimaryText),
                                    ],
                                  ),
                                ],
                              ),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                spacing: AppSpacing.xs,
                                children: [
                                  Text(lang.translate('ourResidents'), style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold)),
                                  Text(
                                    '${shelter?.name ?? 'Shelter'} • ${animals.length} ${lang.translate('animals')} looking for a home',
                                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppColors.lightSecondaryText),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          padding: const EdgeInsets.fromLTRB(AppSpacing.lg, 0, AppSpacing.lg, AppSpacing.md),
                          child: Row(
                            children: [
                              FilterChip(label: lang.translate('all'), selected: _selectedFilter == 'All', onTap: () => setState(() => _selectedFilter = 'All')),
                              FilterChip(label: lang.translate('dogs'), selected: _selectedFilter == 'Dogs', onTap: () => setState(() => _selectedFilter = 'Dogs')),
                              FilterChip(label: lang.translate('cats'), selected: _selectedFilter == 'Cats', onTap: () => setState(() => _selectedFilter = 'Cats')),
                              FilterChip(label: lang.translate('birds'), selected: _selectedFilter == 'Birds', onTap: () => setState(() => _selectedFilter = 'Birds')),
                              FilterChip(label: lang.translate('others'), selected: _selectedFilter == 'Others', onTap: () => setState(() => _selectedFilter = 'Others')),
                            ],
                          ),
                        ),
                        Expanded(
                          child: GridView.builder(
                            padding: const EdgeInsets.fromLTRB(AppSpacing.lg, 0, AppSpacing.lg, AppSpacing.lg),
                            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 2,
                              crossAxisSpacing: AppSpacing.lg,
                              mainAxisSpacing: AppSpacing.lg,
                              childAspectRatio: 0.75,
                            ),
                            itemCount: filteredAnimals.length,
                            itemBuilder: (context, index) => AnimalGridCard(animal: filteredAnimals[index]),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.md),
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.surface,
                            border: Border(top: BorderSide(color: Theme.of(context).colorScheme.outline)),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(lang.translate('cantAdopt'), style: Theme.of(context).textTheme.labelLarge?.copyWith(color: AppColors.lightSecondaryText)),
                                  Text(lang.translate('supportShelter'), style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold)),
                                ],
                              ),
                              ElevatedButton.icon(onPressed: () {}, icon: const Icon(Icons.favorite_rounded), label: Text(lang.translate('donateNow'))),
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
    );
  }
}

class FilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const FilterChip({super.key, required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        margin: const EdgeInsets.only(right: 8),
        decoration: BoxDecoration(
          color: selected ? Theme.of(context).colorScheme.primary : Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: selected ? Theme.of(context).colorScheme.primary : Theme.of(context).colorScheme.outline,
          ),
        ),
        child: Text(
          label,
          style: Theme.of(context).textTheme.labelLarge?.copyWith(
            color: selected ? Theme.of(context).colorScheme.onPrimary : AppColors.lightSecondaryText,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }
}

class AnimalGridCard extends StatelessWidget {
  final Animal animal;

  const AnimalGridCard({super.key, required this.animal});

  @override
  Widget build(BuildContext context) {
    final imageUrl = animal.imageUrl.trim().isNotEmpty
        ? animal.imageUrl
        : (animal.imageUrls.isNotEmpty ? animal.imageUrls.first : '');
    return GestureDetector(
      onTap: () => context.push('/animal/${animal.id}'),
      child: Container(
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
            Stack(
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(AppRadius.lg)),
                  child: AnimalNetworkImage(
                    imageUrl: imageUrl,
                    height: 160,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(AppRadius.lg)),
                  ),
                ),
                Positioned(
                  top: 8,
                  right: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: animal.status.toLowerCase() == 'available' ? AppColors.lightSuccess : AppColors.lightSecondary,
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      animal.status.toUpperCase(),
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            Padding(
              padding: AppSpacing.paddingMd,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                spacing: AppSpacing.xs,
                children: [
                  Text(
                    animal.name,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: AppColors.lightPrimaryText,
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Row(
                    spacing: AppSpacing.xs,
                    children: [
                      const Icon(Icons.history_rounded, size: 14, color: AppColors.lightSecondaryText),
                      Text(
                        animal.age,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.lightSecondaryText),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        spacing: 4,
                        children: [
                          Icon(Icons.location_on_rounded, size: 14, color: Theme.of(context).colorScheme.primary),
                          Text(
                            animal.gender,
                            style: Theme.of(context).textTheme.labelSmall?.copyWith(color: AppColors.lightSecondaryText),
                          ),
                        ],
                      ),
                      const Icon(Icons.favorite_border_rounded, size: 20, color: AppColors.lightError),
                    ],
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
