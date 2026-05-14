import 'package:flutter/material.dart';
import 'package:paws_without_borders/widgets/animal_network_image.dart';

/// Swipeable image carousel for an animal gallery.
///
/// - Uses [PageView] when there are multiple images.
/// - Shows a subtle dot indicator.
/// - Falls back to a single [AnimalNetworkImage] (or placeholder) when empty.
class AnimalImageCarousel extends StatefulWidget {
  final List<String> imageUrls;
  final double height;
  final BorderRadius borderRadius;

  const AnimalImageCarousel({
    super.key,
    required this.imageUrls,
    required this.height,
    required this.borderRadius,
  });

  @override
  State<AnimalImageCarousel> createState() => _AnimalImageCarouselState();
}

class _AnimalImageCarouselState extends State<AnimalImageCarousel> {
  final PageController _controller = PageController();
  int _index = 0;

  @override
  void didUpdateWidget(covariant AnimalImageCarousel oldWidget) {
    super.didUpdateWidget(oldWidget);

    // If the gallery changes (e.g., async load), keep indicator/page in range.
    final urls = widget.imageUrls.map((e) => e.trim()).where((e) => e.isNotEmpty).toList(growable: false);
    final maxIndex = urls.isEmpty ? 0 : urls.length - 1;
    if (_index > maxIndex) {
      _index = maxIndex;
      if (_controller.hasClients) {
        _controller.jumpToPage(_index);
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final urls = widget.imageUrls.map((e) => e.trim()).where((e) => e.isNotEmpty).toList(growable: false);
    final dotColor = Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.75);
    final dotInactive = Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.22);

    Widget child;
    if (urls.length <= 1) {
      child = AnimalNetworkImage(imageUrl: urls.isEmpty ? '' : urls.first, height: widget.height, width: double.infinity, fit: BoxFit.cover);
    } else {
      child = Stack(
        children: [
          PageView.builder(
            controller: _controller,
            physics: const PageScrollPhysics(),
            // Helps accessibility + web trackpad scrolling.
            allowImplicitScrolling: true,
            itemCount: urls.length,
            onPageChanged: (i) => setState(() => _index = i),
            itemBuilder: (context, i) => AnimalNetworkImage(imageUrl: urls[i], height: widget.height, width: double.infinity, fit: BoxFit.cover),
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 14,
            child: IgnorePointer(
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.22),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: List.generate(urls.length, (i) {
                      final active = i == _index;
                      return AnimatedContainer(
                        duration: const Duration(milliseconds: 180),
                        curve: Curves.easeOut,
                        margin: const EdgeInsets.symmetric(horizontal: 3),
                        height: 7,
                        width: active ? 18 : 7,
                        decoration: BoxDecoration(
                          color: active ? dotColor : dotInactive,
                          borderRadius: BorderRadius.circular(99),
                        ),
                      );
                    }),
                  ),
                ),
              ),
            ),
          ),
        ],
      );
    }

    return ClipRRect(
      borderRadius: widget.borderRadius,
      child: SizedBox(height: widget.height, width: double.infinity, child: child),
    );
  }
}
