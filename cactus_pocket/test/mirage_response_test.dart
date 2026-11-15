import 'package:cactus_pocket/services/mirage_response.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('extracts verified scene fields and preserves pretty raw JSON', () {
    final response = parseMirageResponse(
      '{"scene":{"background":"white","style":"minimalist"},"objects":[]}',
    );

    expect(response.description, 'white · minimalist');
    expect(response.rawJson, contains('"objects": []'));
  });

  test('falls back to reasoning when scene fields are unavailable', () {
    final response = parseMirageResponse('{"reasoning":"A red cup."}');

    expect(response.description, 'A red cup.');
  });

  test('rejects malformed JSON and non-object payloads', () {
    expect(() => parseMirageResponse('{'), throwsFormatException);
    expect(() => parseMirageResponse('[]'), throwsA(isA<FormatException>()));
  });
}
