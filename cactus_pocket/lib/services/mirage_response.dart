import 'dart:convert';

class MirageResponse {
  const MirageResponse({required this.description, required this.rawJson});

  final String description;
  final String rawJson;
}

MirageResponse parseMirageResponse(String raw) {
  final decoded = jsonDecode(raw);
  if (decoded is! Map<String, dynamic>) {
    throw const FormatException('Expected a JSON object from Mirage');
  }

  final scene = decoded['scene'];
  final description = scene is Map
      ? [
          scene['background'],
          scene['style'],
        ].whereType<String>().where((value) => value.isNotEmpty).join(' · ')
      : '';
  final reasoning = decoded['reasoning'];
  return MirageResponse(
    description: description.isNotEmpty
        ? description
        : (reasoning is String ? reasoning : 'Mirage returned a result.'),
    rawJson: const JsonEncoder.withIndent('  ').convert(decoded),
  );
}
