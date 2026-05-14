import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/// A defensive image renderer used across the app.
///
/// This widget supports both:
/// - Network URLs (http/https) via [Image.network]
/// - Local assets (assets/...) via [Image.asset]
class AppNetworkImage extends StatelessWidget {
  final String url;
  final BoxFit fit;
  final double? height;
  final double? width;
  final BorderRadius? borderRadius;

  const AppNetworkImage({super.key, required this.url, this.fit = BoxFit.cover, this.height, this.width, this.borderRadius});

  @override
  Widget build(BuildContext context) {
    final effectiveUrl = url.trim();
    final surface = Theme.of(context).colorScheme.surface;
    final onSurfaceVariant = Theme.of(context).colorScheme.onSurfaceVariant;

    Widget child;
    if (effectiveUrl.isEmpty) {
      child = Container(
        height: height,
        width: width,
        color: surface,
        alignment: Alignment.center,
        child: Icon(Icons.image_outlined, color: onSurfaceVariant),
      );
    } else if (effectiveUrl.startsWith('http://') || effectiveUrl.startsWith('https://')) {
      child = Image.network(
        effectiveUrl,
        height: height,
        width: width,
        fit: fit,
        // Flutter Web (CanvasKit) fetches image bytes and can fail
        // with Firebase Storage URLs if CORS is not configured. Prefer an <img> element on web.
        webHtmlElementStrategy: kIsWeb ? WebHtmlElementStrategy.prefer : WebHtmlElementStrategy.never,
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          final expected = loadingProgress.expectedTotalBytes;
          final loaded = loadingProgress.cumulativeBytesLoaded;
          final value = (expected != null && expected > 0) ? loaded / expected : null;
          return Container(
            height: height,
            width: width,
            color: surface,
            alignment: Alignment.center,
            child: SizedBox(
              width: 22,
              height: 22,
              child: CircularProgressIndicator(strokeWidth: 2, value: value, color: Theme.of(context).colorScheme.primary),
            ),
          );
        },
        errorBuilder: (context, error, stackTrace) {
          debugPrint('AppNetworkImage: failed to load url="$effectiveUrl" error=$error\n$stackTrace');
          return Container(
            height: height,
            width: width,
            color: surface,
            alignment: Alignment.center,
            child: const Icon(Icons.broken_image_outlined),
          );
        },
      );
    } else if (effectiveUrl.startsWith('assets/')) {
      child = Image.asset(effectiveUrl, height: height, width: width, fit: fit);
    } else {
      child = Container(
        height: height,
        width: width,
        color: surface,
        alignment: Alignment.center,
        child: const Icon(Icons.broken_image_outlined),
      );
    }

    if (borderRadius == null) return child;
    return ClipRRect(borderRadius: borderRadius!, child: child);
  }
}
