import 'package:plugin_platform_interface/plugin_platform_interface.dart';

import 'embedded_media_picker.dart';
import 'embedded_media_picker_method_channel.dart';

/// Platform interface used by native implementations of the plugin.
abstract class EmbeddedMediaPickerPlatform extends PlatformInterface {
  /// Creates a platform interface instance.
  EmbeddedMediaPickerPlatform() : super(token: _token);

  static final Object _token = Object();

  static EmbeddedMediaPickerPlatform _instance =
      MethodChannelEmbeddedMediaPicker();

  /// The active platform implementation.
  static EmbeddedMediaPickerPlatform get instance => _instance;

  /// Sets the active platform implementation.
  static set instance(EmbeddedMediaPickerPlatform instance) {
    PlatformInterface.verifyToken(instance, _token);
    _instance = instance;
  }

  /// Returns whether the current platform supports the embedded picker view.
  Future<bool> isEmbeddedPickerAvailable() {
    throw UnimplementedError(
      'isEmbeddedPickerAvailable() has not been implemented.',
    );
  }

  /// Opens the modal platform picker and returns selected media items.
  Future<List<PickedMedia>> pickMedia({
    EmbeddedMediaPickerOptions options = const EmbeddedMediaPickerOptions(),
  }) {
    throw UnimplementedError('pickMedia() has not been implemented.');
  }
}
