import 'package:embedded_media_picker/embedded_media_picker.dart';
import 'package:embedded_media_picker/embedded_media_picker_method_channel.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final platform = MethodChannelEmbeddedMediaPicker();
  const channel = MethodChannel('embedded_media_picker');
  final calls = <MethodCall>[];

  setUp(() {
    calls.clear();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (methodCall) async {
          calls.add(methodCall);
          return switch (methodCall.method) {
            'isEmbeddedPickerAvailable' => true,
            'pickMedia' => <Map<String, Object?>>[
              <String, Object?>{
                'uri': 'content://media/1',
                'type': 'video',
                'mimeType': 'video/mp4',
                'fileName': 'clip.mp4',
                'sizeBytes': 2048,
                'isTemporary': false,
              },
            ],
            _ => null,
          };
        });
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
  });

  test('isEmbeddedPickerAvailable calls platform channel', () async {
    expect(await platform.isEmbeddedPickerAvailable(), isTrue);
    expect(calls.single.method, 'isEmbeddedPickerAvailable');
  });

  test('pickMedia serializes options and parses media maps', () async {
    final items = await platform.pickMedia(
      options: const EmbeddedMediaPickerOptions(
        mediaType: EmbeddedMediaType.video,
        maxSelectionLimit: 2,
      ),
    );

    expect(items, <PickedMedia>[
      PickedMedia(
        uri: Uri.parse('content://media/1'),
        type: PickedMediaType.video,
        mimeType: 'video/mp4',
        fileName: 'clip.mp4',
        sizeBytes: 2048,
      ),
    ]);
    expect(calls.single.method, 'pickMedia');
    expect(calls.single.arguments, containsPair('mediaType', 'video'));
    expect(calls.single.arguments, containsPair('maxSelectionLimit', 2));
  });
}
