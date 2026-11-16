import 'dart:async';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:http/http.dart' as http;

const mirageModelUrl =
    'https://huggingface.co/Cactus-Compute/mirage/resolve/76c1e9e53381aca8fc3843c636216c96ff220122/mirage.cact';
const mirageModelSha256 =
    '4249a0f7515272ff76b9414bec17d7e7daf84b15b66c7fb4f17fce1e66f9f237';
const mirageModelSizeBytes = 21611043;
const mirageModelDownloadDeadline = Duration(minutes: 10);
const mirageModelIdleTimeout = Duration(seconds: 60);
const _modelFileName = 'mirage-76c1e9e53381aca8fc3843c636216c96ff220122.cact';

class ModelStoreException implements Exception {
  const ModelStoreException(this.message);
  final String message;
  @override
  String toString() => message;
}

enum _DownloadAbortReason { canceled, totalTimeout, idleTimeout }

String _formatDuration(Duration duration) {
  if (duration.inMinutes > 0) {
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds;
    final minuteText = '$minutes minute${minutes == 1 ? '' : 's'}';
    return seconds == minutes * 60
        ? minuteText
        : '$minuteText ($seconds seconds)';
  }
  if (duration.inSeconds > 0) {
    final seconds = duration.inSeconds;
    return '$seconds second${seconds == 1 ? '' : 's'}';
  }
  final milliseconds = duration.inMilliseconds;
  return '$milliseconds millisecond${milliseconds == 1 ? '' : 's'}';
}

class ModelStore {
  ModelStore({
    http.Client? client,
    required this._directoryProvider,
    this._modelUrl = mirageModelUrl,
    this._expectedSha256 = mirageModelSha256,
    this.expectedBytes = mirageModelSizeBytes,
    this.totalTimeout = mirageModelDownloadDeadline,
    this.idleTimeout = mirageModelIdleTimeout,
  }) : _client = client ?? http.Client();

  final http.Client _client;
  final Future<Directory> Function() _directoryProvider;
  final String _modelUrl;
  final String _expectedSha256;
  final int expectedBytes;
  final Duration totalTimeout;
  final Duration idleTimeout;
  StreamController<double>? _progressController;
  Future<File>? _downloadTask;
  IOSink? _activeSink;
  Completer<_DownloadAbortReason>? _abortController;

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
    final abortController = Completer<_DownloadAbortReason>();
    _abortController = abortController;
    _DownloadAbortReason? abortReason;
    Timer? totalTimer;
    Timer? idleTimer;
    File? tempFile;
    StreamController<double>? controller;

    ModelStoreException abortException(
      _DownloadAbortReason reason,
    ) => switch (reason) {
      _DownloadAbortReason.canceled => const ModelStoreException(
        'Download cancelled',
      ),
      _DownloadAbortReason.totalTimeout => ModelStoreException(
        'Model download timed out (total deadline: ${_formatDuration(totalTimeout)})',
      ),
      _DownloadAbortReason.idleTimeout => ModelStoreException(
        'Model download timed out (no data for ${_formatDuration(idleTimeout)})',
      ),
    };

    void abort(_DownloadAbortReason reason) {
      if (abortReason != null) return;
      abortReason = reason;
      abortController.complete(reason);
    }

    void throwIfAborted() {
      final reason = abortReason;
      if (reason != null) throw abortException(reason);
    }

    void resetIdleTimer() {
      idleTimer?.cancel();
      idleTimer = Timer(
        idleTimeout,
        () => abort(_DownloadAbortReason.idleTimeout),
      );
    }

    try {
      if (expectedBytes <= 0 || expectedBytes > mirageModelSizeBytes) {
        throw const ModelStoreException('Invalid pinned model size');
      }
      final readyFile = await modelFile;
      if (await isReady()) return readyFile;

      final partialFile = File('${readyFile.path}.part');
      tempFile = partialFile;
      final progressController = StreamController<double>();
      controller = progressController;
      _progressController = progressController;
      await partialFile.parent.create(recursive: true);
      if (await partialFile.exists()) await partialFile.delete();
      throwIfAborted();

      final request = http.AbortableRequest(
        'GET',
        Uri.parse(_modelUrl),
        abortTrigger: abortController.future.then<void>((_) {}),
      );
      totalTimer = Timer(
        totalTimeout,
        () => abort(_DownloadAbortReason.totalTimeout),
      );
      resetIdleTimer();
      final response = await Future.any<http.StreamedResponse>([
        _client.send(request),
        abortController.future.then<http.StreamedResponse>(
          (reason) => throw abortException(reason),
        ),
      ]);
      final finalUrl = response.request?.url ?? request.url;
      if (finalUrl.scheme != 'https') {
        throw const ModelStoreException('Model download must use HTTPS');
      }
      if (response.statusCode != HttpStatus.ok) {
        throw ModelStoreException(
          'Model server returned HTTP ${response.statusCode}',
        );
      }
      final advertisedBytes = response.contentLength ?? -1;
      if (advertisedBytes > mirageModelSizeBytes) {
        throw const ModelStoreException(
          'Model response exceeds the 21611043-byte size limit',
        );
      }
      if (advertisedBytes >= 0 && advertisedBytes != expectedBytes) {
        throw ModelStoreException(
          'Model size mismatch: expected $expectedBytes bytes, server advertised $advertisedBytes',
        );
      }

      var received = 0;
      _activeSink = partialFile.openWrite();
      final iterator = StreamIterator<List<int>>(response.stream);
      try {
        while (true) {
          final hasChunk = await Future.any<bool>([
            iterator.moveNext(),
            abortController.future.then<bool>(
              (reason) => throw abortException(reason),
            ),
          ]);
          if (!hasChunk) break;
          final chunk = iterator.current;
          if (chunk.isEmpty) continue;
          if (chunk.length > mirageModelSizeBytes - received) {
            throw const ModelStoreException(
              'Model response exceeds the 21611043-byte size limit',
            );
          }
          _activeSink!.add(chunk);
          received += chunk.length;
          resetIdleTimer();
          final value = received / expectedBytes;
          progressController.add(value);
          onProgress?.call(value);
        }
      } finally {
        await iterator.cancel();
      }
      totalTimer.cancel();
      totalTimer = null;
      idleTimer?.cancel();
      idleTimer = null;
      throwIfAborted();
      if (received != expectedBytes) {
        throw ModelStoreException(
          'Model size mismatch: expected $expectedBytes bytes, received $received',
        );
      }

      await _activeSink!.flush();
      await _activeSink!.close();
      _activeSink = null;
      throwIfAborted();
      final actual = await _sha256(partialFile);
      throwIfAborted();
      if (actual != _expectedSha256) {
        throw ModelStoreException('Mirage checksum mismatch (got $actual)');
      }
      await partialFile.rename(readyFile.path);
      progressController.add(1.0);
      return readyFile;
    } on FileSystemException catch (error) {
      throw ModelStoreException(
        'Unable to store Mirage model (check available storage): ${error.message}',
      );
    } catch (error) {
      final reason = abortReason;
      if (reason != null) {
        throw abortException(reason);
      }
      rethrow;
    } finally {
      totalTimer?.cancel();
      idleTimer?.cancel();
      await _activeSink?.close();
      _activeSink = null;
      if (tempFile != null && await tempFile.exists()) await tempFile.delete();
      controller?.close();
      if (identical(_progressController, controller)) {
        _progressController = null;
      }
      if (identical(_abortController, abortController)) _abortController = null;
    }
  }

  Future<void> cancel() async {
    final abortController = _abortController;
    if (abortController != null && !abortController.isCompleted) {
      abortController.complete(_DownloadAbortReason.canceled);
    }
  }

  Future<String> _sha256(File file) async {
    final digest = await sha256.bind(file.openRead()).first;
    return digest.toString();
  }

  void dispose() => _client.close();
}
