import 'dart:io';

import 'package:embedded_media_picker/embedded_media_picker.dart';
import 'package:embedded_media_picker_example/main.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

final _selectedItems = <PickedMedia>[
  PickedMedia(
    uri: Uri.parse('content://media/external/images/media/8128'),
    type: PickedMediaType.image,
    mimeType: 'image/jpeg',
    fileName: 'mountain-sunrise.jpg',
    sizeBytes: 2483000,
  ),
  PickedMedia(
    uri: Uri.parse('content://media/external/video/media/451'),
    type: PickedMediaType.video,
    mimeType: 'video/mp4',
    fileName: 'city-walk.mp4',
    sizeBytes: 18724000,
  ),
  PickedMedia(
    uri: Uri.parse('file:///tmp/portrait-edited.png'),
    type: PickedMediaType.image,
    mimeType: 'image/png',
    fileName: 'portrait-edited.png',
    sizeBytes: 842000,
    isTemporary: true,
  ),
];

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
          if (methodCall.method == 'pickMedia') {
            return _selectedItems.map((item) => item.toMap()).toList();
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
      ExampleApp(
        platform: TargetPlatform.android,
        fontFamily: 'ScreenshotFont',
        initialSelectedItems: _selectedItems,
      ),
    );
    await tester.pump();

    await expectLater(
      find.byType(ExampleApp),
      matchesGoldenFile('../screenshots/selected-android.png'),
    );
  });

  testWidgets('ios screenshot', (tester) async {
    await binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => binding.setSurfaceSize(null));

    await tester.pumpWidget(
      ExampleApp(
        platform: TargetPlatform.iOS,
        fontFamily: 'ScreenshotFont',
        initialSelectedItems: _selectedItems,
      ),
    );
    await tester.pump();

    await expectLater(
      find.byType(ExampleApp),
      matchesGoldenFile('../screenshots/selected-ios.png'),
    );
  });
}

Future<void> _loadScreenshotFont() async {
  final textFont = File('/System/Library/Fonts/Supplemental/Arial.ttf');
  final textBytes = await textFont.readAsBytes();
  final iconFont = _materialIconsFont();
  final iconBytes = await iconFont.readAsBytes();

  await (FontLoader(
    'ScreenshotFont',
  )..addFont(Future<ByteData>.value(ByteData.sublistView(textBytes)))).load();
  await (FontLoader(
    'MaterialIcons',
  )..addFont(Future<ByteData>.value(ByteData.sublistView(iconBytes)))).load();
}

File _materialIconsFont() {
  final flutterRoot = Platform.environment['FLUTTER_ROOT'];
  if (flutterRoot != null && flutterRoot.isNotEmpty) {
    final file = File(
      '$flutterRoot/bin/cache/artifacts/material_fonts/MaterialIcons-Regular.otf',
    );
    if (file.existsSync()) {
      return file;
    }
  }

  var directory = File(Platform.resolvedExecutable).parent;
  for (var index = 0; index < 8; index += 1) {
    final file = File(
      '${directory.path}/cache/artifacts/material_fonts/MaterialIcons-Regular.otf',
    );
    if (file.existsSync()) {
      return file;
    }
    directory = directory.parent;
  }

  throw StateError('Unable to locate MaterialIcons-Regular.otf.');
}
