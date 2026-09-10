import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'embedded_media_picker.dart';
import 'embedded_media_picker_platform_interface.dart';

class MethodChannelEmbeddedMediaPicker extends EmbeddedMediaPickerPlatform {
  @visibleForTesting
  final methodChannel = const MethodChannel('embedded_media_picker');

  @override
  Future<bool> isEmbeddedPickerAvailable() async {
    final available = await methodChannel.invokeMethod<bool>(
      'isEmbeddedPickerAvailable',
    );
    return available ?? false;
  }

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
