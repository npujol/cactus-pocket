import 'dart:typed_data';

import 'package:image/image.dart' as img;

class DecodedRgbImage {
  const DecodedRgbImage({
    required this.bytes,
    required this.width,
    required this.height,
  });

  final Uint8List bytes;
  final int width;
  final int height;
}

/// Decodes common gallery formats, applies EXIF orientation, flattens alpha onto
/// white, and returns packed row-major RGB888 as required by `cactus_describe`.
DecodedRgbImage decodeToRgb(Uint8List encoded) {
  final decoded = img.decodeImage(encoded);
  if (decoded == null) {
    throw const FormatException('Unsupported or corrupt image');
  }
  final oriented = img.bakeOrientation(decoded);
  final rgb = img.Image(
    width: oriented.width,
    height: oriented.height,
    numChannels: 3,
  );
  for (var y = 0; y < oriented.height; y++) {
    for (var x = 0; x < oriented.width; x++) {
      final p = oriented.getPixel(x, y);
      final alpha = p.a.toDouble() / 255.0;
      rgb.setPixelRgb(
        x,
        y,
        (p.r * alpha + 255 * (1 - alpha)).round(),
        (p.g * alpha + 255 * (1 - alpha)).round(),
        (p.b * alpha + 255 * (1 - alpha)).round(),
      );
    }
  }
  return DecodedRgbImage(
    bytes: Uint8List.fromList(rgb.getBytes(order: img.ChannelOrder.rgb)),
    width: rgb.width,
    height: rgb.height,
  );
}
