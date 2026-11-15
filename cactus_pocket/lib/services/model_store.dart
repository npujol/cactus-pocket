import 'dart:async';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:http/http.dart' as http;

const mirageModelUrl =
    'https://huggingface.co/Cactus-Compute/mirage/resolve/76c1e9e53381aca8fc3843c636216c96ff220122/mirage.cact';
const mirageModelSha256 =
    '4249a0f7515272ff76b9414bec17d7e7daf84b15b66c7fb4f17fce1e66f9f237';
const _modelFileName = 'mirage-76c1e9e53381aca8fc3843c636216c96ff220122.cact';

class ModelStoreException implements Exception {
  const ModelStoreException(this.message);
  final String message;
  @override
  String toString() => message;
}

class ModelStore {
  ModelStore({
    http.Client? client,
    required this._directoryProvider,
    this._modelUrl = mirageModelUrl,
    this._expectedSha256 = mirageModelSha256,
  }) : _client = client ?? http.Client();

  final http.Client _client;
  final Future<Directory> Function() _directoryProvider;
  final String _modelUrl;
  final String _expectedSha256;
  StreamController<double>? _progressController;
  Future<File>? _downloadTask;
  IOSink? _activeSink;
  bool _cancelled = false;

  Stream<double>? get progress => _progressController?.stream;

  Future<File> get modelFile async {
    final dir = await _directoryProvider();
    return File('${dir.path}/$_modelFileName');
  }

  Future<bool> isReady() async {
    final file = await modelFile;
    if (!await file.exists()) return false;
    return await _sha256(file) == _expectedSha256;
  }

  Future<File> download({void Function(double progress)? onProgress}) {
    return _downloadTask ??= _download(onProgress: onProgress).whenComplete(() {
      _downloadTask = null;
    });
  }

  Future<File> _download({void Function(double progress)? onProgress}) async {
    final readyFile = await modelFile;
    if (await isReady()) return readyFile;

    _cancelled = false;
    final tempFile = File('${readyFile.path}.part');
    await tempFile.parent.create(recursive: true);
    if (await tempFile.exists()) await tempFile.delete();
    final controller = StreamController<double>();
    _progressController = controller;

    try {
      final request = http.Request('GET', Uri.parse(_modelUrl));
      final response = await _client.send(request);
      if (response.statusCode != HttpStatus.ok) {
        throw ModelStoreException(
          'Model server returned HTTP ${response.statusCode}',
        );
      }
      final total = response.contentLength ?? 0;
      var received = 0;
      _activeSink = tempFile.openWrite();
      await for (final chunk in response.stream) {
        if (_cancelled) throw const ModelStoreException('Download cancelled');
        _activeSink!.add(chunk);
        received += chunk.length;
        if (total > 0) {
          final value = received / total;
          controller.add(value);
          onProgress?.call(value);
        }
      }
      await _activeSink!.flush();
      await _activeSink!.close();
      _activeSink = null;
      if (_cancelled) throw const ModelStoreException('Download cancelled');

      final actual = await _sha256(tempFile);
      if (actual != _expectedSha256) {
        throw ModelStoreException('Mirage checksum mismatch (got $actual)');
      }
      await tempFile.rename(readyFile.path);
      controller.add(1.0);
      return readyFile;
    } on FileSystemException catch (error) {
      throw ModelStoreException(
        'Unable to store Mirage model: ${error.message}',
      );
    } finally {
      await _activeSink?.close();
      _activeSink = null;
      if (await tempFile.exists()) await tempFile.delete();
      controller.close();
      _progressController = null;
    }
  }

  Future<void> cancel() async {
    _cancelled = true;
    await _activeSink?.flush();
    await _activeSink?.close();
    _activeSink = null;
  }

  Future<String> _sha256(File file) async {
    final digest = await sha256.bind(file.openRead()).first;
    return digest.toString();
  }

  void dispose() => _client.close();
}
