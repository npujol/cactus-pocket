import 'dart:typed_data';

import 'package:cactus_pocket/services/image_rgb.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;

void main() {
  test(
    'converts RGBA pixels into packed RGB and composites alpha on white',
    () {
      final source = img.Image(width: 2, height: 1, numChannels: 4);
      source.setPixelRgba(0, 0, 10, 20, 30, 255);
      source.setPixelRgba(1, 0, 100, 50, 0, 128);
      final encoded = Uint8List.fromList(img.encodePng(source));
      final rgb = decodeToRgb(encoded);
      expect(rgb.width, 2);
      expect(rgb.height, 1);
      expect(rgb.bytes, [10, 20, 30, 177, 152, 127]);
    },
  );

  test('rejects unsupported/corrupt data', () {
    expect(
      () => decodeToRgb(Uint8List.fromList([1, 2, 3])),
      throwsFormatException,
    );
  });
}
