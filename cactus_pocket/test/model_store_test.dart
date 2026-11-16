import 'dart:async';
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
    int? contentLength,
  }) {
    final bodyBytes = utf8.encode(body);
    return http.StreamedResponse(
      Stream<List<int>>.value(bodyBytes),
      statusCode,
      headers: headers,
      contentLength: contentLength ?? bodyBytes.length,
      request: http.Request(
        'GET',
        Uri.parse('https://example.test/model.cact'),
      ),
    );
  }

  Future<void> expectNoPromotedModel(ModelStore store) async {
    expect(await store.isReady(), isFalse);
    final file = await store.modelFile;
    expect(await file.exists(), isFalse);
    expect(await File('${file.path}.part').exists(), isFalse);
    expect(await temp.list().toList(), isEmpty);
  }

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
      expectedBytes: utf8.encode(bytes).length,
    );

    final progress = <double>[];
    final file = await store.download(onProgress: progress.add);
    expect(await file.readAsString(), bytes);
    expect(await store.isReady(), isTrue);
    expect(progress.last, 1.0);
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
        expectedBytes: utf8.encode(bytes).length,
      );

      await expectLater(store.download(), throwsA(isA<ModelStoreException>()));
      await expectNoPromotedModel(store);
      store.dispose();
    },
  );

  test('cancels a stalled response and removes its partial file', () async {
    final subscribed = Completer<void>();
    final canceled = Completer<void>();
    final body = StreamController<List<int>>(
      onListen: subscribed.complete,
      onCancel: canceled.complete,
    );
    final client = _FixtureClient(
      (_) async => http.StreamedResponse(
        body.stream,
        200,
        contentLength: utf8.encode(bytes).length,
      ),
    );
    final store = ModelStore(
      client: client,
      directoryProvider: () async => temp,
      modelUrl: 'https://example.test/model.cact',
      expectedSha256: digest,
      expectedBytes: utf8.encode(bytes).length,
    );

    final download = store.download();
    await subscribed.future;
    await store.cancel();
    await expectLater(
      download,
      throwsA(
        isA<ModelStoreException>().having(
          (error) => error.message,
          'message',
          'Download cancelled',
        ),
      ),
    );
    await canceled.future;
    await expectNoPromotedModel(store);
    store.dispose();
  });

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
      expectedBytes: utf8.encode(bytes).length,
    );

    await expectLater(store.download(), throwsA(isA<ModelStoreException>()));
    await expectNoPromotedModel(store);
    expect(await store.download(), isA<File>());
    expect(await store.isReady(), isTrue);
    store.dispose();
  });

  test('pins the expected model size and transfer deadlines', () {
    expect(mirageModelSizeBytes, 21611043);
    expect(mirageModelDownloadDeadline, const Duration(minutes: 10));
    expect(mirageModelIdleTimeout, const Duration(seconds: 60));
  });

  test('rejects an oversized advertised response before writing it', () async {
    final client = _FixtureClient(
      (_) async =>
          response(bytes, 200, contentLength: mirageModelSizeBytes + 1),
    );
    final store = ModelStore(
      client: client,
      directoryProvider: () async => temp,
      modelUrl: 'https://example.test/model.cact',
      expectedSha256: digest,
      expectedBytes: utf8.encode(bytes).length,
    );

    await expectLater(
      store.download(),
      throwsA(
        isA<ModelStoreException>().having(
          (error) => error.message,
          'message',
          contains('size limit'),
        ),
      ),
    );
    await expectNoPromotedModel(store);
    store.dispose();
  });

  test('stops streaming when the body exceeds the byte cap', () async {
    Stream<List<int>> oversizedBody() async* {
      var remaining = mirageModelSizeBytes + 1;
      while (remaining > 0) {
        final length = remaining > 1024 * 1024 ? 1024 * 1024 : remaining;
        yield List<int>.filled(length, 0);
        remaining -= length;
      }
    }

    final client = _FixtureClient(
      (_) async => http.StreamedResponse(
        oversizedBody(),
        200,
        request: http.Request(
          'GET',
          Uri.parse('https://example.test/model.cact'),
        ),
      ),
    );
    final store = ModelStore(
      client: client,
      directoryProvider: () async => temp,
      modelUrl: 'https://example.test/model.cact',
      expectedSha256: digest,
      expectedBytes: utf8.encode(bytes).length,
    );

    await expectLater(
      store.download(),
      throwsA(
        isA<ModelStoreException>().having(
          (error) => error.message,
          'message',
          contains('size limit'),
        ),
      ),
    );
    await expectNoPromotedModel(store);
    store.dispose();
  });

  test(
    'rejects a short body even when the header advertises the exact size',
    () async {
      final shortBody = bytes.substring(0, bytes.length - 1);
      final client = _FixtureClient(
        (_) async =>
            response(shortBody, 200, contentLength: utf8.encode(bytes).length),
      );
      final store = ModelStore(
        client: client,
        directoryProvider: () async => temp,
        modelUrl: 'https://example.test/model.cact',
        expectedSha256: digest,
        expectedBytes: utf8.encode(bytes).length,
      );

      await expectLater(
        store.download(),
        throwsA(
          isA<ModelStoreException>().having(
            (error) => error.message,
            'message',
            contains('size mismatch'),
          ),
        ),
      );
      await expectNoPromotedModel(store);
      store.dispose();
    },
  );

  test(
    'aborts an idle stalled response and removes its partial file',
    () async {
      final subscribed = Completer<void>();
      final canceled = Completer<void>();
      final body = StreamController<List<int>>(
        onListen: subscribed.complete,
        onCancel: canceled.complete,
      );
      final client = _FixtureClient(
        (_) async => http.StreamedResponse(
          body.stream,
          200,
          contentLength: utf8.encode(bytes).length,
          request: http.Request(
            'GET',
            Uri.parse('https://example.test/model.cact'),
          ),
        ),
      );
      final store = ModelStore(
        client: client,
        directoryProvider: () async => temp,
        modelUrl: 'https://example.test/model.cact',
        expectedSha256: digest,
        expectedBytes: utf8.encode(bytes).length,
        totalTimeout: const Duration(seconds: 2),
        idleTimeout: const Duration(milliseconds: 30),
      );

      final download = store.download();
      await subscribed.future;
      await expectLater(
        download,
        throwsA(
          isA<ModelStoreException>().having(
            (error) => error.message,
            'message',
            contains('no data'),
          ),
        ),
      );
      await canceled.future;
      await expectNoPromotedModel(store);
      store.dispose();
    },
  );

  test('enforces the total deadline and permits a successful retry', () async {
    var requests = 0;
    final abortObserved = Completer<void>();
    final client = _FixtureClient((request) {
      requests++;
      if (requests == 1) {
        if (request is! http.AbortableRequest || request.abortTrigger == null) {
          throw StateError('Expected an abortable model request');
        }
        unawaited(
          request.abortTrigger!.then((_) {
            if (!abortObserved.isCompleted) abortObserved.complete();
          }),
        );
        return Completer<http.StreamedResponse>().future;
      }
      return Future.value(response(bytes, 200));
    });
    final store = ModelStore(
      client: client,
      directoryProvider: () async => temp,
      modelUrl: 'https://example.test/model.cact',
      expectedSha256: digest,
      expectedBytes: utf8.encode(bytes).length,
      totalTimeout: const Duration(milliseconds: 40),
      idleTimeout: const Duration(seconds: 2),
    );

    await expectLater(
      store.download(),
      throwsA(
        isA<ModelStoreException>().having(
          (error) => error.message,
          'message',
          contains('total deadline'),
        ),
      ),
    );
    await abortObserved.future;
    await expectNoPromotedModel(store);
    final file = await store.download();
    expect(await file.readAsString(), bytes);
    expect(await store.isReady(), isTrue);
    expect(requests, 2);
    store.dispose();
  });
}
