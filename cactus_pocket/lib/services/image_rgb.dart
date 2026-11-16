import 'dart:io';
import 'dart:typed_data';

import 'package:image/image.dart' as img;

const maxGalleryImageFileBytes = 32 * 1024 * 1024;
const maxInferenceImageSide = 2048;
const maxInferenceImagePixels = 4 * 1024 * 1024;
const maxInferenceRgbBytes = maxInferenceImagePixels * 3;

Future<Uint8List> readBoundedImageFile(File file) async {
  final fileSize = await file.length();
  if (fileSize > maxGalleryImageFileBytes) {
    throw const FormatException(
      'Image file exceeds the 32 MiB limit. Choose a smaller image.',
    );
  }
  final bytes = await file.readAsBytes();
  if (bytes.length > maxGalleryImageFileBytes) {
    throw const FormatException(
      'Image file exceeds the 32 MiB limit. Choose a smaller image.',
    );
  }
  return bytes;
}

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
  if (encoded.length > maxGalleryImageFileBytes) {
    throw const FormatException(
      'Image file exceeds the 32 MiB limit. Choose a smaller image.',
    );
  }
  final decoder = img.findDecoderForData(encoded);
  if (decoder == null) {
    throw const FormatException(
      'This image is unsupported or corrupt. Choose a different image.',
    );
  }
  final info = decoder.startDecode(encoded);
  if (info == null) {
    throw const FormatException(
      'This image is unsupported or corrupt. Choose a different image.',
    );
  }
  _validateDimensions(info.width, info.height);

  final decoded = decoder.decodeFrame(0);
  if (decoded == null) {
    throw const FormatException(
      'This image is unsupported or corrupt. Choose a different image.',
    );
  }
  final oriented = img.bakeOrientation(decoded);
  _validateDimensions(oriented.width, oriented.height);
  final rgbByteCount = oriented.width * oriented.height * 3;
  if (rgbByteCount > maxInferenceRgbBytes) {
    throw const FormatException('Image exceeds the supported pixel limit.');
  }

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
  final rgbBytes = Uint8List.fromList(
    rgb.getBytes(order: img.ChannelOrder.rgb),
  );
  if (rgbBytes.length != rgbByteCount ||
      rgbBytes.length > maxInferenceRgbBytes) {
    throw const FormatException('Unable to safely prepare this image.');
  }
  return DecodedRgbImage(bytes: rgbBytes, width: rgb.width, height: rgb.height);
}

void _validateDimensions(int width, int height) {
  if (width <= 0 ||
      height <= 0 ||
      width > maxInferenceImageSide ||
      height > maxInferenceImageSide ||
      width > maxInferenceImagePixels ~/ height) {
    throw const FormatException(
      'Image dimensions exceed 2048 pixels per side or 4 megapixels. '
      'Choose a smaller image.',
    );
  }
}
