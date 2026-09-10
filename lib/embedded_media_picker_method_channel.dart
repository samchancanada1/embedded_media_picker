import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'embedded_media_picker.dart';
import 'embedded_media_picker_platform_interface.dart';

/// Method-channel implementation of [EmbeddedMediaPickerPlatform].
class MethodChannelEmbeddedMediaPicker extends EmbeddedMediaPickerPlatform {
  /// The method channel used to communicate with native platform code.
  @visibleForTesting
  final methodChannel = const MethodChannel('embedded_media_picker');

  /// Returns whether the current platform can show an embedded picker view.
  @override
  Future<bool> isEmbeddedPickerAvailable() async {
    final available = await methodChannel.invokeMethod<bool>(
      'isEmbeddedPickerAvailable',
    );
    return available ?? false;
  }

  /// Opens the modal platform picker and parses selected media items.
  @override
  Future<List<PickedMedia>> pickMedia({
    EmbeddedMediaPickerOptions options = const EmbeddedMediaPickerOptions(),
  }) async {
    final result = await methodChannel.invokeListMethod<Object?>(
      'pickMedia',
      options.toMap(),
    );
    return (result ?? const <Object?>[])
        .whereType<Map<Object?, Object?>>()
        .map(PickedMedia.fromMap)
        .toList(growable: false);
  }
}
