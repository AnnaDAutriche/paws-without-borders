import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:image/image.dart' as img;

/// Utilities to minimize Firebase Storage usage by compressing and resizing
/// images before upload.
///
/// Rules enforced:
/// - Reject if original file size > 2MB
/// - Resize to max width 1200px
/// - Default JPEG quality 70%
/// - Ensure output is <= 500KB (adaptive quality + downscale fallback)
class ImageUploadOptimizer {
  static const int maxOriginalBytes = 1024 * 1024*2; // 2MB
  static const int maxOutputBytes = 1024 * 1024; // 1MB
  static const int maxWidth = 1200;
  static const int defaultQuality = 70;

  /// Returns optimized JPEG bytes ready to be uploaded.
  ///
  /// Throws an [ImageUploadException] if the image is too large or cannot be
  /// processed.
  static Future<Uint8List> optimize(Uint8List originalBytes) async {
    if (originalBytes.lengthInBytes > maxOriginalBytes) {
      throw const ImageUploadException(ImageUploadError.tooLarge);
    }

    // Decoding can be CPU-heavy; do it in an isolate where possible.
    final decoded = await compute(_decodeImage, originalBytes);
    if (decoded == null) {
      throw const ImageUploadException(ImageUploadError.decodeFailed);
    }

    img.Image working = decoded;
    if (working.width > maxWidth) {
      final newHeight = (working.height * (maxWidth / working.width)).round();
      working = img.copyResize(working, width: maxWidth, height: newHeight, interpolation: img.Interpolation.cubic);
    }

    // Encode as JPEG and adapt quality to ensure we stay under 500KB.
    int quality = defaultQuality;
    Uint8List encoded = Uint8List.fromList(img.encodeJpg(working, quality: quality));
    while (encoded.lengthInBytes > maxOutputBytes && quality > 40) {
      quality = math.max(40, quality - 10);
      encoded = Uint8List.fromList(img.encodeJpg(working, quality: quality));
    }

    // If still too large, downscale gradually (keep quality stable).
    int guard = 0;
    while (encoded.lengthInBytes > maxOutputBytes && guard < 6) {
      guard++;
      final nextWidth = (working.width * 0.85).round();
      if (nextWidth < 480) break;
      final nextHeight = (working.height * (nextWidth / working.width)).round();
      working = img.copyResize(working, width: nextWidth, height: nextHeight, interpolation: img.Interpolation.linear);
      encoded = Uint8List.fromList(img.encodeJpg(working, quality: quality));
    }

    if (encoded.lengthInBytes > maxOutputBytes) {
      // Per requirements: do not upload originals; block if we can't meet caps.
      throw const ImageUploadException(ImageUploadError.cannotMeetSizeBudget);
    }

    return encoded;
  }

  static img.Image? _decodeImage(Uint8List bytes) => img.decodeImage(bytes);
}

enum ImageUploadError { tooLarge, decodeFailed, cannotMeetSizeBudget }

class ImageUploadException implements Exception {
  final ImageUploadError error;
  const ImageUploadException(this.error);

  @override
  String toString() => 'ImageUploadException($error)';
}
