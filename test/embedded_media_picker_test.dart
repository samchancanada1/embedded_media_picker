import 'package:embedded_media_picker/embedded_media_picker.dart';
import 'package:embedded_media_picker/embedded_media_picker_method_channel.dart';
import 'package:embedded_media_picker/embedded_media_picker_platform_interface.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

class MockEmbeddedMediaPickerPlatform
    with MockPlatformInterfaceMixin
    implements EmbeddedMediaPickerPlatform {
  @override
  Future<bool> isEmbeddedPickerAvailable() => Future.value(true);

  @override
  Future<List<PickedMedia>> pickMedia({
    EmbeddedMediaPickerOptions options = const EmbeddedMediaPickerOptions(),
  }) {
    return Future.value(<PickedMedia>[
      PickedMedia(
        uri: Uri.parse('content://media/1'),
        type: PickedMediaType.image,
        mimeType: 'image/jpeg',
        fileName: 'photo.jpg',
        sizeBytes: 42,
      ),
    ]);
  }
}

void main() {
  final EmbeddedMediaPickerPlatform initialPlatform =
      EmbeddedMediaPickerPlatform.instance;

  test('$MethodChannelEmbeddedMediaPicker is the default instance', () {
    expect(initialPlatform, isInstanceOf<MethodChannelEmbeddedMediaPicker>());
  });

  test('isEmbeddedPickerAvailable delegates to platform', () async {
    const embeddedMediaPicker = EmbeddedMediaPicker();
    final fakePlatform = MockEmbeddedMediaPickerPlatform();
    EmbeddedMediaPickerPlatform.instance = fakePlatform;

    expect(await embeddedMediaPicker.isEmbeddedPickerAvailable(), isTrue);
  });

  test('pickMedia delegates to platform', () async {
    const embeddedMediaPicker = EmbeddedMediaPicker();
    final fakePlatform = MockEmbeddedMediaPickerPlatform();
    EmbeddedMediaPickerPlatform.instance = fakePlatform;

    expect(await embeddedMediaPicker.pickMedia(), <PickedMedia>[
      PickedMedia(
        uri: Uri.parse('content://media/1'),
        type: PickedMediaType.image,
        mimeType: 'image/jpeg',
        fileName: 'photo.jpg',
        sizeBytes: 42,
      ),
    ]);
  });

  test('options serialize to platform map', () {
    final options = EmbeddedMediaPickerOptions(
      mediaType: EmbeddedMediaType.image,
      maxSelectionLimit: 4,
      mimeTypes: const <String>['image/png'],
      preselectedUris: <Uri>[Uri.parse('content://media/1')],
      orderedSelection: true,
      accentColorArgb: 0xff6750a4,
      launchTab: EmbeddedMediaPickerLaunchTab.albums,
      theme: EmbeddedMediaPickerTheme.dark,
    );

    expect(options.toMap(), <String, Object?>{
      'mediaType': 'image',
      'maxSelectionLimit': 4,
      'mimeTypes': <String>['image/png'],
      'preselectedUris': <String>['content://media/1'],
      'orderedSelection': true,
      'accentColorArgb': 0xff6750a4,
      'launchTab': 'albums',
      'theme': 'dark',
      'persistablePermissions': false,
    });
  });

  test('picked media parses platform maps', () {
    final item = PickedMedia.fromMap(<Object?, Object?>{
      'uri': 'file:///tmp/photo.jpg',
      'type': 'image',
      'mimeType': 'image/jpeg',
      'fileName': 'photo.jpg',
      'sizeBytes': 128,
      'isTemporary': true,
    });

    expect(item.uri, Uri.parse('file:///tmp/photo.jpg'));
    expect(item.type, PickedMediaType.image);
    expect(item.mimeType, 'image/jpeg');
    expect(item.fileName, 'photo.jpg');
    expect(item.sizeBytes, 128);
    expect(item.isTemporary, isTrue);
  });

  test('controller exposes public selection state and stream', () async {
    final controller = EmbeddedMediaPickerController();
    addTearDown(controller.dispose);

    final selectionEvents = <List<PickedMedia>>[];
    final selectionSub = controller.selectionChanges.listen(
      selectionEvents.add,
    );
    addTearDown(selectionSub.cancel);

    controller.clearSelection();

    expect(selectionEvents.single, isEmpty);
    expect(controller.selectedItems, isEmpty);
  });
}
