import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import 'embedded_media_picker_platform_interface.dart';

enum EmbeddedMediaType {
  image,
  video,
  imageAndVideo;

  String get platformValue => switch (this) {
    EmbeddedMediaType.image => 'image',
    EmbeddedMediaType.video => 'video',
    EmbeddedMediaType.imageAndVideo => 'imageAndVideo',
  };
}

enum PickedMediaType {
  image,
  video,
  unknown;

  static PickedMediaType fromPlatformValue(Object? value) {
    return switch (value) {
      'image' => PickedMediaType.image,
      'video' => PickedMediaType.video,
      _ => PickedMediaType.unknown,
    };
  }
}

enum EmbeddedMediaPickerLaunchTab {
  systemDefault,
  photos,
  albums;

  String get platformValue => switch (this) {
    EmbeddedMediaPickerLaunchTab.systemDefault => 'systemDefault',
    EmbeddedMediaPickerLaunchTab.photos => 'photos',
    EmbeddedMediaPickerLaunchTab.albums => 'albums',
  };
}

enum EmbeddedMediaPickerTheme {
  system,
  light,
  dark;

  String get platformValue => switch (this) {
    EmbeddedMediaPickerTheme.system => 'system',
    EmbeddedMediaPickerTheme.light => 'light',
    EmbeddedMediaPickerTheme.dark => 'dark',
  };
}

@immutable
class PickedMedia {
  const PickedMedia({
    required this.uri,
    this.type = PickedMediaType.unknown,
    this.mimeType,
    this.fileName,
    this.sizeBytes,
    this.isTemporary = false,
  });

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

  final Uri uri;
  final PickedMediaType type;
  final String? mimeType;
  final String? fileName;
  final int? sizeBytes;

  /// True when the URI points to a copied temporary app file.
  ///
  /// iOS `PHPickerViewController` returns temporary file copies because it does
  /// not grant stable asset URLs to third-party apps.
  final bool isTemporary;

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

@immutable
class EmbeddedMediaPickerOptions {
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

  final EmbeddedMediaType mediaType;

  /// The maximum selected item count.
  ///
  /// Android and iOS may cap this to their current system picker limit.
  /// On iOS, `0` means unlimited selection.
  final int maxSelectionLimit;
  final List<String> mimeTypes;
  final List<Uri> preselectedUris;
  final bool orderedSelection;
  final int? accentColorArgb;

  /// Reserved for AndroidX versions that expose picker start-tab selection.
  final EmbeddedMediaPickerLaunchTab launchTab;
  final EmbeddedMediaPickerTheme theme;

  /// Requests persisted read access for Android fallback results when the
  /// platform returns persistable document URIs.
  final bool persistablePermissions;

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

typedef EmbeddedMediaPickerItemsCallback =
    void Function(List<PickedMedia> items);
typedef EmbeddedMediaPickerErrorCallback =
    void Function(String code, String message);

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

  List<PickedMedia> get selectedItems => _selectedItems;
  bool get isSessionOpen => _isSessionOpen;

  Stream<List<PickedMedia>> get selectionChanges => _selectionChanges.stream;
  Stream<List<PickedMedia>> get permissionGrants => _permissionGrants.stream;
  Stream<List<PickedMedia>> get permissionRevocations =>
      _permissionRevocations.stream;
  Stream<(String, String)> get errors => _errors.stream;

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

class EmbeddedMediaPicker {
  const EmbeddedMediaPicker();

  Future<bool> isEmbeddedPickerAvailable() {
    return EmbeddedMediaPickerPlatform.instance.isEmbeddedPickerAvailable();
  }

  Future<List<PickedMedia>> pickMedia({
    EmbeddedMediaPickerOptions options = const EmbeddedMediaPickerOptions(),
  }) {
    return EmbeddedMediaPickerPlatform.instance.pickMedia(options: options);
  }
}

class EmbeddedMediaPickerView extends StatefulWidget {
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

  final EmbeddedMediaPickerOptions options;
  final EmbeddedMediaPickerController? controller;
  final EmbeddedMediaPickerItemsCallback? onSelectionChanged;
  final VoidCallback? onSelectionComplete;
  final EmbeddedMediaPickerItemsCallback? onUriPermissionGranted;
  final EmbeddedMediaPickerItemsCallback? onUriPermissionRevoked;
  final VoidCallback? onSessionOpened;
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
