// This is a basic Flutter integration test.
//
// Since integration tests run in a full Flutter application, they can interact
// with the host side of a plugin implementation, unlike Dart unit tests.
//
// For more information about Flutter integration tests, please see
// https://flutter.dev/to/integration-testing

import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'package:embedded_media_picker/embedded_media_picker.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('availability check returns a boolean', (
    WidgetTester tester,
  ) async {
    const plugin = EmbeddedMediaPicker();
    final available = await plugin.isEmbeddedPickerAvailable();

    expect(available, isA<bool>());
  });
}
