import 'package:plugin_platform_interface/plugin_platform_interface.dart';

import 'embedded_media_picker.dart';
import 'embedded_media_picker_method_channel.dart';

abstract class EmbeddedMediaPickerPlatform extends PlatformInterface {
  EmbeddedMediaPickerPlatform() : super(token: _token);

  static final Object _token = Object();

  static EmbeddedMediaPickerPlatform _instance =
      MethodChannelEmbeddedMediaPicker();

  static EmbeddedMediaPickerPlatform get instance => _instance;

  static set instance(EmbeddedMediaPickerPlatform instance) {
    PlatformInterface.verifyToken(instance, _token);
    _instance = instance;
  }

  Future<bool> isEmbeddedPickerAvailable() {
    throw UnimplementedError(
      'isEmbeddedPickerAvailable() has not been implemented.',
    );
  }

  Future<List<PickedMedia>> pickMedia({
    EmbeddedMediaPickerOptions options = const EmbeddedMediaPickerOptions(),
  }) {
    throw UnimplementedError('pickMedia() has not been implemented.');
  }
}
