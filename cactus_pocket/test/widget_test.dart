import 'package:flutter_test/flutter_test.dart';

import 'package:cactus_pocket/main.dart';

void main() {
  testWidgets('Mirage landing screen shows setup and image input', (
    tester,
  ) async {
    await tester.pumpWidget(const MirageApp());
    expect(find.text('MIRAGE'), findsOneWidget);
    expect(find.text('Choose an image to describe'), findsOneWidget);
    expect(find.text('Get model'), findsOneWidget);
  });
}
