import 'package:cactus_pocket/services/cactus_inference.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const channel = MethodChannel('com.cactuscompute.cactus_pocket/mirage');
  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
  final inference = CactusInference(channel: channel);

  tearDown(() => messenger.setMockMethodCallHandler(channel, null));

  test('validates packed RGB size before platform call', () async {
    var called = false;
    messenger.setMockMethodCallHandler(channel, (call) async {
      called = true;
      return '{}';
    });
    await expectLater(
      inference.describe(rgb: Uint8List(2), width: 1, height: 1),
      throwsA(
        isA<CactusInferenceException>().having(
          (e) => e.code,
          'code',
          'invalid_image',
        ),
      ),
    );
    expect(called, isFalse);
  });

  test('passes RGB bytes/dimensions/options and returns native JSON', () async {
    messenger.setMockMethodCallHandler(channel, (call) async {
      expect(call.method, 'describe');
      expect(call.arguments['rgb'], Uint8List.fromList([1, 2, 3, 4, 5, 6]));
      expect(call.arguments['width'], 2);
      expect(call.arguments['height'], 1);
      expect(call.arguments['options'], '{"sections":["objects"]}');
      return '{"scene":{}}';
    });
    expect(
      await inference.describe(
        rgb: Uint8List.fromList([1, 2, 3, 4, 5, 6]),
        width: 2,
        height: 1,
        options: const {
          'sections': ['objects'],
        },
      ),
      '{"scene":{}}',
    );
  });

  test('loads a model and queries bridge readiness', () async {
    messenger.setMockMethodCallHandler(channel, (call) async {
      if (call.method == 'loadModel') {
        expect(call.arguments['model'], Uint8List.fromList([7, 8]));
        return true;
      }
      expect(call.method, 'isModelReady');
      return false;
    });

    await inference.loadModel(Uint8List.fromList([7, 8]));
    expect(await inference.isModelReady(), isFalse);
  });

  test('rejects an empty native response', () async {
    messenger.setMockMethodCallHandler(channel, (call) async => null);
    await expectLater(
      inference.describe(rgb: Uint8List(3), width: 1, height: 1),
      throwsA(
        isA<CactusInferenceException>().having(
          (e) => e.code,
          'code',
          'empty_response',
        ),
      ),
    );
  });

  test('maps structured platform errors', () async {
    messenger.setMockMethodCallHandler(channel, (call) async {
      throw PlatformException(code: 'native_failure', message: 'bad model');
    });
    await expectLater(
      inference.loadModel(Uint8List.fromList([1])),
      throwsA(
        isA<CactusInferenceException>()
            .having((e) => e.code, 'code', 'native_failure')
            .having((e) => e.message, 'message', 'bad model'),
      ),
    );
  });
}
