import 'dart:io';

import 'package:embedded_media_picker_example/main.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final binding = TestWidgetsFlutterBinding.ensureInitialized();
  const channel = MethodChannel('embedded_media_picker');
  var fontsLoaded = false;

  setUp(() async {
    if (!fontsLoaded) {
      await _loadScreenshotFont();
      fontsLoaded = true;
    }
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (methodCall) async {
          if (methodCall.method == 'isEmbeddedPickerAvailable') {
            return false;
          }
          return null;
        });
  });

  tearDown(() async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
  });

  testWidgets('android screenshot', (tester) async {
    await binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => binding.setSurfaceSize(null));

    await tester.pumpWidget(
      const ExampleApp(
        platform: TargetPlatform.android,
        fontFamily: 'ScreenshotFont',
      ),
    );
    await tester.pump();

    await expectLater(
      find.byType(ExampleApp),
      matchesGoldenFile('../screenshots/android.png'),
    );
  });

  testWidgets('ios screenshot', (tester) async {
    await binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => binding.setSurfaceSize(null));

    await tester.pumpWidget(
      const ExampleApp(
        platform: TargetPlatform.iOS,
        fontFamily: 'ScreenshotFont',
      ),
    );
    await tester.pump();

    await expectLater(
      find.byType(ExampleApp),
      matchesGoldenFile('../screenshots/ios.png'),
    );
  });
}

Future<void> _loadScreenshotFont() async {
  final file = File('/System/Library/Fonts/Supplemental/Arial.ttf');
  final bytes = await file.readAsBytes();
  final fontLoader = FontLoader('ScreenshotFont')
    ..addFont(Future<ByteData>.value(ByteData.sublistView(bytes)));
  await fontLoader.load();
}
