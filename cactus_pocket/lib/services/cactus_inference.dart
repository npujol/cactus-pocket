import 'dart:convert';

import 'package:flutter/services.dart';

class CactusInferenceException implements Exception {
  const CactusInferenceException(this.code, this.message);

  final String code;
  final String message;

  @override
  String toString() => '$code: $message';
}

/// Flutter facade for the app's serialized Android Cactus Mirage bridge.
class CactusInference {
  CactusInference({MethodChannel? channel})
    : _channel = channel ?? const MethodChannel(_channelName);

  static const _channelName = 'com.cactuscompute.cactus_pocket/mirage';
  final MethodChannel _channel;

  Future<void> loadModel(Uint8List bytes) async {
    try {
      await _channel.invokeMethod<void>('loadModel', {'model': bytes});
    } on PlatformException catch (error) {
      throw CactusInferenceException(
        error.code,
        error.message ?? 'Model loading failed',
      );
    }
  }

  Future<bool> isModelReady() async {
    try {
      return await _channel.invokeMethod<bool>('isModelReady') ?? false;
    } on PlatformException catch (error) {
      throw CactusInferenceException(
        error.code,
        error.message ?? 'Unable to query model state',
      );
    }
  }

  Future<String> describe({
    required Uint8List rgb,
    required int width,
    required int height,
    Map<String, Object?> options = const {},
    String language = 'en',
    String keywords = '',
  }) async {
    if (width <= 0 || height <= 0 || rgb.length != width * height * 3) {
      throw const CactusInferenceException(
        'invalid_image',
        'RGB buffer length must be width * height * 3',
      );
    }
    try {
      final result = await _channel.invokeMethod<String>('describe', {
        'rgb': rgb,
        'width': width,
        'height': height,
        'options': jsonEncode(options),
        'language': language,
        'keywords': keywords,
      });
      if (result == null) {
        throw const CactusInferenceException(
          'empty_response',
          'Native inference returned no response',
        );
      }
      return result;
    } on PlatformException catch (error) {
      throw CactusInferenceException(
        error.code,
        error.message ?? 'Image inference failed',
      );
    }
  }
}
