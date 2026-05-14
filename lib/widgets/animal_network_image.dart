import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:paws_without_borders/theme.dart';

/// Renders an animal image strictly from Firestore field `image_url`.
///
/// - Uses `Image.network` (no asset placeholder override when URL is present).
/// - Fallback placeholder is shown ONLY when `imageUrl` is null/empty (or not http).
class AnimalNetworkImage extends StatelessWidget {
  final String imageUrl;
  final BoxFit fit;
  final double? height;
  final double? width;
  final BorderRadius? borderRadius;

  const AnimalNetworkImage({
    super.key,
    required this.imageUrl,
    this.fit = BoxFit.cover,
    this.height,
    this.width,
    this.borderRadius,
  });

  @override
  Widget build(BuildContext context) {
    final url = imageUrl.trim();

    // We only support network URLs here. Non-http values are treated as missing.
    final isValidNetwork = url.startsWith('http://') || url.startsWith('https://');
    if (url.isEmpty || !isValidNetwork) {
      final child = Container(
        height: height,
        width: width,
        color: Theme.of(context).colorScheme.surface,
        alignment: Alignment.center,
        child: Icon(Icons.pets_rounded, color: Theme.of(context).colorScheme.onSurfaceVariant),
      );
      if (borderRadius == null) return child;
      return ClipRRect(borderRadius: borderRadius!, child: child);
    }

    final img = Image.network(
      url,
      height: height,
      width: width,
      fit: fit,
      // Flutter Web (CanvasKit) fetches image bytes and can fail
      // with Firebase Storage URLs if CORS is not configured. Prefer an <img> element on web.
      webHtmlElementStrategy: kIsWeb ? WebHtmlElementStrategy.prefer : WebHtmlElementStrategy.never,
      // Keeps UI stable while loading.
      loadingBuilder: (context, child, loadingProgress) {
        if (loadingProgress == null) return child;
        final expected = loadingProgress.expectedTotalBytes;
        final loaded = loadingProgress.cumulativeBytesLoaded;
        final value = (expected != null && expected > 0) ? loaded / expected : null;
        return Container(
          height: height,
          width: width,
          color: Theme.of(context).colorScheme.surface,
          alignment: Alignment.center,
          child: SizedBox(
            width: 22,
            height: 22,
            child: CircularProgressIndicator(strokeWidth: 2, value: value, color: Theme.of(context).colorScheme.primary),
          ),
        );
      },
      errorBuilder: (context, error, stackTrace) {
        debugPrint('AnimalNetworkImage: failed to load url="$url" error=$error\n$stackTrace');
        return Container(
          height: height,
          width: width,
          color: Theme.of(context).colorScheme.surface,
          alignment: Alignment.center,
          child: const Icon(Icons.broken_image_outlined, color: AppColors.lightSecondaryText),
        );
      },
    );

    if (borderRadius == null) return img;
    return ClipRRect(borderRadius: borderRadius!, child: img);
  }
}
