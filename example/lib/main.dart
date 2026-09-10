import 'package:embedded_media_picker/embedded_media_picker.dart';
import 'package:flutter/material.dart';

void main() {
  runApp(const ExampleApp());
}

class ExampleApp extends StatelessWidget {
  const ExampleApp({super.key, this.platform, this.fontFamily});

  final TargetPlatform? platform;
  final String? fontFamily;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xff6750a4)),
        platform: platform,
        fontFamily: fontFamily,
      ),
      home: const PickerExampleScreen(),
    );
  }
}

class PickerExampleScreen extends StatefulWidget {
  const PickerExampleScreen({super.key});

  @override
  State<PickerExampleScreen> createState() => _PickerExampleScreenState();
}

class _PickerExampleScreenState extends State<PickerExampleScreen> {
  static const options = EmbeddedMediaPickerOptions(
    maxSelectionLimit: 5,
    orderedSelection: true,
    accentColorArgb: 0xff6750a4,
  );

  final _picker = const EmbeddedMediaPicker();
  final _controller = EmbeddedMediaPickerController();
  var _embeddedAvailable = false;
  var _selectedItems = <PickedMedia>[];
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadAvailability();
  }

  Future<void> _loadAvailability() async {
    final available = await _picker.isEmbeddedPickerAvailable();
    if (!mounted) {
      return;
    }
    setState(() => _embeddedAvailable = available);
  }

  Future<void> _pickWithFallback() async {
    try {
      final items = await _picker.pickMedia(options: options);
      if (!mounted) {
        return;
      }
      setState(() {
        _selectedItems = items;
        _error = null;
      });
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() => _error = error.toString());
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Embedded media picker')),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  FilledButton.icon(
                    onPressed: _pickWithFallback,
                    icon: const Icon(Icons.photo_library_outlined),
                    label: const Text('Pick media'),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      _embeddedAvailable
                          ? 'Embedded picker available'
                          : 'Using modal fallback',
                    ),
                  ),
                ],
              ),
            ),
            if (_error != null)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  _error!,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              ),
            Expanded(
              child: _embeddedAvailable
                  ? EmbeddedMediaPickerView(
                      options: options,
                      controller: _controller,
                      onSelectionChanged: (items) {
                        setState(() {
                          _selectedItems = items;
                          _error = null;
                        });
                      },
                      onError: (code, message) {
                        setState(() => _error = '$code: $message');
                      },
                    )
                  : _SelectedItemsList(items: _selectedItems),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}

class _SelectedItemsList extends StatelessWidget {
  const _SelectedItemsList({required this.items});

  final List<PickedMedia> items;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return const Center(child: Text('No media selected'));
    }
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: items.length,
      separatorBuilder: (_, _) => const Divider(height: 1),
      itemBuilder: (context, index) {
        final item = items[index];
        return ListTile(
          leading: const Icon(Icons.perm_media_outlined),
          title: Text(
            item.fileName ?? item.uri.toString(),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          subtitle: Text(
            [
              item.type.name,
              if (item.mimeType != null) item.mimeType,
              if (item.sizeBytes != null) '${item.sizeBytes} bytes',
            ].join(' · '),
          ),
        );
      },
    );
  }
}
