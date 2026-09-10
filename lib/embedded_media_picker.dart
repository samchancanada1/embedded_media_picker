/// A Flutter plugin for Android embedded media picking with iOS and Android
/// modal picker fallbacks.
library;

import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import 'embedded_media_picker_platform_interface.dart';

/// The type of media the picker should show.
enum EmbeddedMediaType {
  /// Show images only.
  image,

  /// Show videos only.
  video,

  /// Show both images and videos.
  imageAndVideo;

  /// The value sent to the platform implementation.
  String get platformValue => switch (this) {
    EmbeddedMediaType.image => 'image',
    EmbeddedMediaType.video => 'video',
    EmbeddedMediaType.imageAndVideo => 'imageAndVideo',
  };
}

/// The detected type of a picked media item.
enum PickedMediaType {
  /// The item is an image.
  image,

  /// The item is a video.
  video,

  /// The platform did not report a known media type.
  unknown;

  /// Parses a platform value into a [PickedMediaType].
  static PickedMediaType fromPlatformValue(Object? value) {
    return switch (value) {
      'image' => PickedMediaType.image,
      'video' => PickedMediaType.video,
      _ => PickedMediaType.unknown,
    };
  }
}

/// The preferred tab to show when a platform picker supports an initial tab.
enum EmbeddedMediaPickerLaunchTab {
  /// Let the platform choose its default starting tab.
  systemDefault,

  /// Start on the photos tab when supported.
  photos,

  /// Start on the albums tab when supported.
  albums;

  /// The value sent to the platform implementation.
  String get platformValue => switch (this) {
    EmbeddedMediaPickerLaunchTab.systemDefault => 'systemDefault',
    EmbeddedMediaPickerLaunchTab.photos => 'photos',
    EmbeddedMediaPickerLaunchTab.albums => 'albums',
  };
}

/// The preferred visual theme for platform picker surfaces that support it.
enum EmbeddedMediaPickerTheme {
  /// Match the system theme.
  system,

  /// Prefer a light picker theme when supported.
  light,

  /// Prefer a dark picker theme when supported.
  dark;

  /// The value sent to the platform implementation.
  String get platformValue => switch (this) {
    EmbeddedMediaPickerTheme.system => 'system',
    EmbeddedMediaPickerTheme.light => 'light',
    EmbeddedMediaPickerTheme.dark => 'dark',
  };
}

/// A media item returned by the platform picker.
@immutable
class PickedMedia {
  /// Creates a picked media description.
  const PickedMedia({
    required this.uri,
    this.type = PickedMediaType.unknown,
    this.mimeType,
    this.fileName,
    this.sizeBytes,
    this.isTemporary = false,
  });

  /// Creates a [PickedMedia] from the platform channel payload.
  factory PickedMedia.fromMap(Map<Object?, Object?> map) {
    return PickedMedia(
      uri: Uri.parse(map['uri'] as String),
      type: PickedMediaType.fromPlatformValue(map['type']),
      mimeType: map['mimeType'] as String?,
      fileName: map['fileName'] as String?,
      sizeBytes: switch (map['sizeBytes']) {
        final int value => value,
        final num value => value.toInt(),
        _ => null,
      },
      isTemporary: map['isTemporary'] as bool? ?? false,
    );
  }

  /// The platform URI for the selected media item.
  final Uri uri;

  /// The detected media type.
  final PickedMediaType type;

  /// The MIME type reported by the platform, if known.
  final String? mimeType;

  /// The display file name reported by the platform, if known.
  final String? fileName;

  /// The file size in bytes, if the platform can query it.
  final int? sizeBytes;

  /// True when the URI points to a copied temporary app file.
  ///
  /// iOS `PHPickerViewController` returns temporary file copies because it does
  /// not grant stable asset URLs to third-party apps.
  final bool isTemporary;

  /// Converts this item to a platform-channel friendly map.
  Map<String, Object?> toMap() {
    return <String, Object?>{
      'uri': uri.toString(),
      'type': switch (type) {
        PickedMediaType.image => 'image',
        PickedMediaType.video => 'video',
        PickedMediaType.unknown => 'unknown',
      },
      'mimeType': mimeType,
      'fileName': fileName,
      'sizeBytes': sizeBytes,
      'isTemporary': isTemporary,
    };
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is PickedMedia &&
            uri == other.uri &&
            type == other.type &&
            mimeType == other.mimeType &&
            fileName == other.fileName &&
            sizeBytes == other.sizeBytes &&
            isTemporary == other.isTemporary;
  }

  @override
  int get hashCode {
    return Object.hash(uri, type, mimeType, fileName, sizeBytes, isTemporary);
  }
}

/// Options used when opening the modal picker or embedded picker view.
@immutable
class EmbeddedMediaPickerOptions {
  /// Creates picker options.
  const EmbeddedMediaPickerOptions({
    this.mediaType = EmbeddedMediaType.imageAndVideo,
    this.maxSelectionLimit = 1,
    this.mimeTypes = const <String>[],
    this.preselectedUris = const <Uri>[],
    this.orderedSelection = false,
    this.accentColorArgb,
    this.launchTab = EmbeddedMediaPickerLaunchTab.systemDefault,
    this.theme = EmbeddedMediaPickerTheme.system,
    this.persistablePermissions = false,
  });

  /// Which media types should be shown.
  final EmbeddedMediaType mediaType;

  /// The maximum selected item count.
  ///
  /// Android and iOS may cap this to their current system picker limit.
  /// On iOS, `0` means unlimited selection.
  final int maxSelectionLimit;

  /// Optional MIME type filters sent to platforms that support them.
  final List<String> mimeTypes;

  /// Optional media URIs that should start selected when supported.
  final List<Uri> preselectedUris;

  /// Whether the platform should show and preserve selection order.
  final bool orderedSelection;

  /// ARGB accent color for picker UI surfaces that support tinting.
  final int? accentColorArgb;

  /// Reserved for AndroidX versions that expose picker start-tab selection.
  final EmbeddedMediaPickerLaunchTab launchTab;

  /// Preferred picker theme for platforms that support theme selection.
  final EmbeddedMediaPickerTheme theme;

  /// Requests persisted read access for Android fallback results when the
  /// platform returns persistable document URIs.
  final bool persistablePermissions;

  /// Converts the options to a platform-channel friendly map.
  Map<String, Object?> toMap() {
    return <String, Object?>{
      'mediaType': mediaType.platformValue,
      'maxSelectionLimit': maxSelectionLimit,
      'mimeTypes': mimeTypes,
      'preselectedUris': preselectedUris.map((uri) => uri.toString()).toList(),
      'orderedSelection': orderedSelection,
      'accentColorArgb': accentColorArgb,
      'launchTab': launchTab.platformValue,
      'theme': theme.platformValue,
      'persistablePermissions': persistablePermissions,
    };
  }
}

/// Callback used when a picker reports a list of selected or permissioned items.
typedef EmbeddedMediaPickerItemsCallback =
    void Function(List<PickedMedia> items);

/// Callback used when a picker reports a platform error.
typedef EmbeddedMediaPickerErrorCallback =
    void Function(String code, String message);

/// Controller for observing state from an [EmbeddedMediaPickerView].
class EmbeddedMediaPickerController extends ChangeNotifier {
  final StreamController<List<PickedMedia>> _selectionChanges =
      StreamController<List<PickedMedia>>.broadcast(sync: true);
  final StreamController<List<PickedMedia>> _permissionGrants =
      StreamController<List<PickedMedia>>.broadcast(sync: true);
  final StreamController<List<PickedMedia>> _permissionRevocations =
      StreamController<List<PickedMedia>>.broadcast(sync: true);
  final StreamController<(String, String)> _errors =
      StreamController<(String, String)>.broadcast(sync: true);

  List<PickedMedia> _selectedItems = const <PickedMedia>[];
  bool _isSessionOpen = false;

  /// The current selected items known by the embedded picker controller.
  List<PickedMedia> get selectedItems => _selectedItems;

  /// Whether an embedded picker session has opened.
  bool get isSessionOpen => _isSessionOpen;

  /// Emits whenever the embedded picker selection changes.
  Stream<List<PickedMedia>> get selectionChanges => _selectionChanges.stream;

  /// Emits when the embedded picker grants URI access.
  Stream<List<PickedMedia>> get permissionGrants => _permissionGrants.stream;

  /// Emits when the embedded picker revokes URI access.
  Stream<List<PickedMedia>> get permissionRevocations =>
      _permissionRevocations.stream;

  /// Emits platform errors reported by the embedded picker.
  Stream<(String, String)> get errors => _errors.stream;

  /// Clears the controller's current selected item state.
  void clearSelection() {
    _setSelectedItems(const <PickedMedia>[]);
  }

  void _openSession() {
    _isSessionOpen = true;
    notifyListeners();
  }

  void _grantItems(List<PickedMedia> items) {
    final byUri = <Uri, PickedMedia>{
      for (final item in _selectedItems) item.uri: item,
      for (final item in items) item.uri: item,
    };
    _setSelectedItems(byUri.values.toList(growable: false));
    _permissionGrants.add(items);
  }

  void _revokeItems(List<PickedMedia> items) {
    final revokedUris = items.map((item) => item.uri).toSet();
    _setSelectedItems(
      _selectedItems
          .where((item) => !revokedUris.contains(item.uri))
          .toList(growable: false),
    );
    _permissionRevocations.add(items);
  }

  void _setSelectedItems(List<PickedMedia> items) {
    _selectedItems = List<PickedMedia>.unmodifiable(items);
    _selectionChanges.add(_selectedItems);
    notifyListeners();
  }

  void _addError(String code, String message) {
    _errors.add((code, message));
  }

  @override
  void dispose() {
    _selectionChanges.close();
    _permissionGrants.close();
    _permissionRevocations.close();
    _errors.close();
    super.dispose();
  }
}

/// Entry point for opening modal platform media pickers.
class EmbeddedMediaPicker {
  /// Creates an embedded media picker API wrapper.
  const EmbeddedMediaPicker();

  /// Returns true when the Android embedded picker view is available.
  ///
  /// iOS currently returns false because only modal `PHPickerViewController`
  /// fallback is supported there.
  Future<bool> isEmbeddedPickerAvailable() {
    return EmbeddedMediaPickerPlatform.instance.isEmbeddedPickerAvailable();
  }

  /// Opens the platform modal media picker and returns selected items.
  Future<List<PickedMedia>> pickMedia({
    EmbeddedMediaPickerOptions options = const EmbeddedMediaPickerOptions(),
  }) {
    return EmbeddedMediaPickerPlatform.instance.pickMedia(options: options);
  }
}

/// A Flutter widget that hosts Android's embedded photo picker view.
///
/// This widget is only available on Android versions that support
/// `EmbeddedPhotoPickerView`. Use [EmbeddedMediaPicker.isEmbeddedPickerAvailable]
/// before showing it in production UI.
class EmbeddedMediaPickerView extends StatefulWidget {
  /// Creates an Android embedded picker view.
  const EmbeddedMediaPickerView({
    super.key,
    this.options = const EmbeddedMediaPickerOptions(),
    this.controller,
    this.onSelectionChanged,
    this.onSelectionComplete,
    this.onUriPermissionGranted,
    this.onUriPermissionRevoked,
    this.onSessionOpened,
    this.onError,
  });

  /// Options passed to the embedded picker view.
  final EmbeddedMediaPickerOptions options;

  /// Optional controller that receives embedded picker state changes.
  final EmbeddedMediaPickerController? controller;

  /// Called when the selected media list changes.
  final EmbeddedMediaPickerItemsCallback? onSelectionChanged;

  /// Called when the user completes the embedded picker session.
  final VoidCallback? onSelectionComplete;

  /// Called when the platform grants URI access for selected items.
  final EmbeddedMediaPickerItemsCallback? onUriPermissionGranted;

  /// Called when the platform revokes URI access for deselected items.
  final EmbeddedMediaPickerItemsCallback? onUriPermissionRevoked;

  /// Called when the embedded picker session opens successfully.
  final VoidCallback? onSessionOpened;

  /// Called when the embedded picker reports an error.
  final EmbeddedMediaPickerErrorCallback? onError;

  @override
  State<EmbeddedMediaPickerView> createState() =>
      _EmbeddedMediaPickerViewState();
}

class _EmbeddedMediaPickerViewState extends State<EmbeddedMediaPickerView> {
  static const String _androidViewType = 'embedded_media_picker/view';

  MethodChannel? _viewChannel;

  @override
  Widget build(BuildContext context) {
    if (defaultTargetPlatform != TargetPlatform.android) {
      scheduleMicrotask(() {
        _addError(
          'unsupported_platform',
          'Embedded picker views are currently only available on Android.',
        );
      });
      return const SizedBox.shrink();
    }

    return AndroidView(
      viewType: _androidViewType,
      creationParams: widget.options.toMap(),
      creationParamsCodec: const StandardMessageCodec(),
      onPlatformViewCreated: _onPlatformViewCreated,
    );
  }

  void _onPlatformViewCreated(int id) {
    _viewChannel = MethodChannel('embedded_media_picker/view_$id');
    _viewChannel!.setMethodCallHandler(_handleViewMethodCall);
  }

  Future<void> _handleViewMethodCall(MethodCall call) async {
    switch (call.method) {
      case 'sessionOpened':
        widget.controller?._openSession();
        widget.onSessionOpened?.call();
      case 'selectionComplete':
        widget.onSelectionComplete?.call();
      case 'uriPermissionGranted':
        final items = _parseItems(call.arguments);
        widget.controller?._grantItems(items);
        widget.onUriPermissionGranted?.call(items);
        widget.onSelectionChanged?.call(
          widget.controller?.selectedItems ?? items,
        );
      case 'uriPermissionRevoked':
        final items = _parseItems(call.arguments);
        widget.controller?._revokeItems(items);
        widget.onUriPermissionRevoked?.call(items);
        widget.onSelectionChanged?.call(
          widget.controller?.selectedItems ?? const <PickedMedia>[],
        );
      case 'sessionError':
      case 'unsupported':
        final error = _parseError(call.arguments);
        _addError(error.$1, error.$2);
    }
  }

  List<PickedMedia> _parseItems(Object? arguments) {
    if (arguments is! List<Object?>) {
      return const <PickedMedia>[];
    }
    return arguments
        .whereType<Map<Object?, Object?>>()
        .map(PickedMedia.fromMap)
        .toList(growable: false);
  }

  (String, String) _parseError(Object? arguments) {
    if (arguments case <Object?, Object?>{
      'code': final String code,
      'message': final String message,
    }) {
      return (code, message);
    }
    return ('unknown', 'Unknown embedded media picker error.');
  }

  void _addError(String code, String message) {
    widget.controller?._addError(code, message);
    widget.onError?.call(code, message);
  }

  @override
  void dispose() {
    _viewChannel?.setMethodCallHandler(null);
    super.dispose();
  }
}
