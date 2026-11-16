import 'dart:io';
import 'dart:typed_data';

import 'package:cactus_pocket/services/image_rgb.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;

void main() {
  test('accepts a 2048-by-2048 image and bounds RGB output', () {
    final source = img.Image(
      width: maxInferenceImageSide,
      height: maxInferenceImageSide,
      numChannels: 4,
    );
    final encoded = Uint8List.fromList(img.encodePng(source));

    final rgb = decodeToRgb(encoded);

    expect(rgb.width, maxInferenceImageSide);
    expect(rgb.height, maxInferenceImageSide);
    expect(rgb.bytes.length, rgb.width * rgb.height * 3);
    expect(rgb.bytes.length, lessThanOrEqualTo(maxInferenceRgbBytes));
  });

  test('decodes picker-downsampled output within the supported bounds', () {
    final source = img.Image(width: 1024, height: 768, numChannels: 4);
    final encoded = Uint8List.fromList(img.encodePng(source));

    final rgb = decodeToRgb(encoded);

    expect(rgb.width, 1024);
    expect(rgb.height, 768);
    expect(rgb.bytes.length, rgb.width * rgb.height * 3);
    expect(rgb.bytes.length, lessThanOrEqualTo(maxInferenceRgbBytes));
  });

  test('rejects dimensions above the side limit before pixel decoding', () {
    final source = img.Image(width: maxInferenceImageSide + 1, height: 1);
    final encoded = Uint8List.fromList(img.encodePng(source));

    expect(
      () => decodeToRgb(encoded),
      throwsA(
        isA<FormatException>().having(
          (error) => error.message,
          'message',
          contains('2048 pixels per side'),
        ),
      ),
    );
  });

  test('reads exactly 32 MiB and rejects larger files from metadata', () async {
    final directory = await Directory.systemTemp.createTemp('image-limit-test');
    try {
      final file = File('${directory.path}/image.bin');
      var handle = await file.open(mode: FileMode.write);
      await handle.truncate(maxGalleryImageFileBytes);
      await handle.close();
      final exactLimit = await readBoundedImageFile(file);
      expect(exactLimit.length, maxGalleryImageFileBytes);

      handle = await file.open(mode: FileMode.write);
      await handle.truncate(maxGalleryImageFileBytes + 1);
      await handle.close();
      await expectLater(
        readBoundedImageFile(file),
        throwsA(
          isA<FormatException>().having(
            (error) => error.message,
            'message',
            contains('32 MiB'),
          ),
        ),
      );
    } finally {
      await directory.delete(recursive: true);
    }
  });

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

  test('applies EXIF orientation before producing inference pixels', () {
    final source = img.Image(width: 2, height: 1, numChannels: 3);
    source.setPixelRgb(0, 0, 255, 0, 0);
    source.setPixelRgb(1, 0, 0, 255, 0);
    source.exif.imageIfd.orientation = 6;

    final encoded = Uint8List.fromList(img.encodeJpg(source, quality: 100));
    final rgb = decodeToRgb(encoded);

    expect(rgb.width, 1);
    expect(rgb.height, 2);
  });

  test('rejects unsupported/corrupt data', () {
    expect(
      () => decodeToRgb(Uint8List.fromList([1, 2, 3])),
      throwsFormatException,
    );
  });
}
