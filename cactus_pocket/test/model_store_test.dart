import 'dart:convert';
import 'dart:io';

import 'package:cactus_pocket/services/model_store.dart';
import 'package:crypto/crypto.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;

class _FixtureClient extends http.BaseClient {
  _FixtureClient(this.respond);

  final Future<http.StreamedResponse> Function(http.BaseRequest request)
  respond;

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) =>
      respond(request);
}

void main() {
  late Directory temp;
  const bytes = 'fixture model';
  final digest = sha256.convert(utf8.encode(bytes)).toString();

  setUp(() async {
    temp = await Directory.systemTemp.createTemp('mirage-model-test');
  });

  tearDown(() async {
    await temp.delete(recursive: true);
  });

  http.StreamedResponse response(
    String body,
    int statusCode, {
    Map<String, String> headers = const {},
  }) => http.StreamedResponse(
    Stream<List<int>>.value(utf8.encode(body)),
    statusCode,
    headers: headers,
    contentLength: utf8.encode(body).length,
  );

  test('verifies downloaded bytes before promoting ready file', () async {
    final client = _FixtureClient((request) async {
      expect(request.url.toString(), 'https://example.test/model.cact');
      return response(bytes, 200);
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
      final client = _FixtureClient((_) async => response(bytes, 200));
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
    final client = _FixtureClient((_) async {
      requests++;
      return requests == 1 ? response('offline', 503) : response(bytes, 200);
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
