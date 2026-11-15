import 'dart:convert';
import 'dart:io';

import 'package:cactus_pocket/services/model_store.dart';
import 'package:crypto/crypto.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  late Directory temp;
  const bytes = 'fixture model';
  final digest = sha256.convert(utf8.encode(bytes)).toString();

  setUp(
    () async =>
        temp = await Directory.systemTemp.createTemp('mirage-model-test'),
  );
  tearDown(() async => temp.delete(recursive: true));

  test('verifies downloaded bytes before promoting ready file', () async {
    final client = MockClient((request) async {
      expect(request.url.toString(), 'https://example.test/model.cact');
      return http.Response(
        bytes,
        200,
        headers: {'content-length': '${utf8.encode(bytes).length}'},
      );
    });
    final store = ModelStore(
      client: client,
      directoryProvider: () async => temp,
      modelUrl: 'https://example.test/model.cact',
      expectedSha256: digest,
    );
    final file = await store.download();
    expect(await file.readAsString(), bytes);
    expect(await store.isReady(), isTrue);
    expect(await File('${file.path}.part').exists(), isFalse);
    store.dispose();
  });

  test(
    'rejects checksum mismatch and leaves no ready or partial file',
    () async {
      final client = MockClient((_) async => http.Response(bytes, 200));
      final store = ModelStore(
        client: client,
        directoryProvider: () async => temp,
        modelUrl: 'https://example.test/model.cact',
        expectedSha256: '0' * 64,
      );
      await expectLater(store.download(), throwsA(isA<ModelStoreException>()));
      expect(await store.isReady(), isFalse);
      expect(await temp.list().toList(), isEmpty);
      store.dispose();
    },
  );

  test('rejects non-200 responses and allows retry', () async {
    var requests = 0;
    final client = MockClient((_) async {
      requests++;
      return requests == 1
          ? http.Response('offline', 503)
          : http.Response(bytes, 200);
    });
    final store = ModelStore(
      client: client,
      directoryProvider: () async => temp,
      modelUrl: 'https://example.test/model.cact',
      expectedSha256: digest,
    );
    await expectLater(store.download(), throwsA(isA<ModelStoreException>()));
    expect(await temp.list().toList(), isEmpty);
    expect(await store.download(), isA<File>());
    expect(await store.isReady(), isTrue);
    store.dispose();
  });
}
