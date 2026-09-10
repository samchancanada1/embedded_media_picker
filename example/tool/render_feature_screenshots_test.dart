import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final binding = TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(_loadScreenshotFont);

  testWidgets('android feature screenshot', (tester) async {
    await binding.setSurfaceSize(const Size(420, 900));
    addTearDown(() => binding.setSurfaceSize(null));

    await tester.pumpWidget(
      const _FeatureScreenshotApp(
        platform: TargetPlatform.android,
        title: 'Android embedded picker',
        subtitle:
            'The picker lives inside your screen while the app keeps running.',
        chips: ['Inline SurfaceView', 'Live URI callbacks', 'Scoped access'],
        body: _AndroidContextPanel(),
        preview: _AndroidPickerPreview(),
      ),
    );
    await tester.pumpAndSettle();

    await expectLater(
      find.byType(_FeatureScreenshotApp),
      matchesGoldenFile('../screenshots/android.png'),
    );
  });

  testWidgets('ios feature screenshot', (tester) async {
    await binding.setSurfaceSize(const Size(420, 900));
    addTearDown(() => binding.setSurfaceSize(null));

    await tester.pumpWidget(
      const _FeatureScreenshotApp(
        platform: TargetPlatform.iOS,
        title: 'iOS privacy picker',
        subtitle: 'The app receives only the items the user chooses.',
        chips: ['PHPicker', 'No full-library grant', 'Temporary file copies'],
        body: _IosContextPanel(),
        preview: _IosPickerPreview(),
      ),
    );
    await tester.pumpAndSettle();

    await expectLater(
      find.byType(_FeatureScreenshotApp),
      matchesGoldenFile('../screenshots/ios.png'),
    );
  });
}

class _FeatureScreenshotApp extends StatelessWidget {
  const _FeatureScreenshotApp({
    required this.platform,
    required this.title,
    required this.subtitle,
    required this.chips,
    required this.body,
    required this.preview,
  });

  final TargetPlatform platform;
  final String title;
  final String subtitle;
  final List<String> chips;
  final Widget body;
  final Widget preview;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xff4863a8),
          brightness: Brightness.light,
        ),
        fontFamily: 'ScreenshotFont',
        platform: platform,
      ),
      home: _FeaturePoster(
        title: title,
        subtitle: subtitle,
        chips: chips,
        body: body,
        preview: preview,
      ),
    );
  }
}

class _FeaturePoster extends StatelessWidget {
  const _FeaturePoster({
    required this.title,
    required this.subtitle,
    required this.chips,
    required this.body,
    required this.preview,
  });

  final String title;
  final String subtitle;
  final List<String> chips;
  final Widget body;
  final Widget preview;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xfff6f7fb),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: const Color(0xff141922),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                subtitle,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: const Color(0xff4d5665),
                  height: 1.25,
                ),
              ),
              const SizedBox(height: 14),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [for (final chip in chips) _Chip(label: chip)],
              ),
              const SizedBox(height: 16),
              body,
              const SizedBox(height: 14),
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(28),
                  child: DecoratedBox(
                    decoration: const BoxDecoration(color: Colors.white),
                    child: preview,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AndroidContextPanel extends StatelessWidget {
  const _AndroidContextPanel();

  @override
  Widget build(BuildContext context) {
    return const _ContextPanel(
      title: 'App UI stays visible',
      detail:
          'Selection changes stream back while the user keeps browsing media.',
      rows: [
        'draft.md',
        'cover-photo.jpg selected',
        'onUriPermissionGranted()',
      ],
    );
  }
}

class _IosContextPanel extends StatelessWidget {
  const _IosContextPanel();

  @override
  Widget build(BuildContext context) {
    return const _ContextPanel(
      title: 'Privacy boundary is visible',
      detail:
          'The system picker shows the user exactly what the app can receive.',
      rows: ['selectionLimit: 5', 'ordered selection', 'file:// temp results'],
    );
  }
}

class _AndroidPickerPreview extends StatelessWidget {
  const _AndroidPickerPreview();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
          color: const Color(0xffffffff),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Compose post',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: Color(0xff121826),
                      ),
                    ),
                  ),
                  _CounterPill(label: '3 selected'),
                ],
              ),
              const SizedBox(height: 10),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xfff2f5fa),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Text(
                  'Caption, upload status, validation, and selected media all stay live above the picker.',
                  style: TextStyle(
                    fontSize: 13,
                    height: 1.25,
                    color: Color(0xff526071),
                  ),
                ),
              ),
            ],
          ),
        ),
        const Divider(height: 1, color: Color(0xffdde3ee)),
        Expanded(
          child: Container(
            color: const Color(0xfff8f8fc),
            child: Column(
              children: [
                const SizedBox(height: 12),
                Container(
                  width: 56,
                  height: 5,
                  decoration: BoxDecoration(
                    color: const Color(0xff454a56),
                    borderRadius: BorderRadius.circular(99),
                  ),
                ),
                const SizedBox(height: 18),
                const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _SelectedTab(label: 'Photos'),
                    SizedBox(width: 10),
                    _PlainTab(label: 'Albums'),
                  ],
                ),
                const SizedBox(height: 14),
                Expanded(
                  child: GridView.count(
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisCount: 3,
                    childAspectRatio: 0.82,
                    mainAxisSpacing: 2,
                    crossAxisSpacing: 2,
                    children: const [
                      _MediaTile(color: Color(0xffc7d2fe), label: 'URI +'),
                      _MediaTile(color: Color(0xffd8b4fe), label: 'Grant'),
                      _MediaTile(color: Color(0xffbfdbfe), label: 'Cloud'),
                      _MediaTile(color: Color(0xfffecaca), label: 'Video'),
                      _MediaTile(color: Color(0xffbbf7d0), label: 'Live'),
                      _MediaTile(color: Color(0xffffedd5), label: 'Revoke'),
                      _MediaTile(color: Color(0xffbae6fd), label: 'Photo'),
                      _MediaTile(color: Color(0xffddd6fe), label: 'Order'),
                      _MediaTile(color: Color(0xfffde68a), label: 'Done'),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _IosPickerPreview extends StatelessWidget {
  const _IosPickerPreview();

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      child: Column(
        children: [
          const SizedBox(height: 14),
          const Text(
            'Choose up to 5 items',
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w800,
              color: Color(0xff151923),
            ),
          ),
          const SizedBox(height: 14),
          const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _SelectedTab(label: 'Photos'),
              SizedBox(width: 8),
              _PlainTab(label: 'Albums'),
            ],
          ),
          const SizedBox(height: 14),
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 14),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xfff0f1f5),
              borderRadius: BorderRadius.circular(18),
            ),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Private photo access',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                    color: Color(0xff10131a),
                  ),
                ),
                SizedBox(height: 6),
                Text(
                  'Your library appears here, but the app can only read the items you pick.',
                  style: TextStyle(
                    fontSize: 13,
                    height: 1.25,
                    color: Color(0xff606774),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: GridView.count(
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 3,
              childAspectRatio: 0.82,
              mainAxisSpacing: 2,
              crossAxisSpacing: 2,
              children: const [
                _MediaTile(color: Color(0xfff9a8d4), label: '1'),
                _MediaTile(color: Color(0xff93c5fd), label: '2'),
                _MediaTile(color: Color(0xff86efac), label: '3'),
                _MediaTile(color: Color(0xffffd7a8), label: '4'),
                _MediaTile(color: Color(0xffc4b5fd), label: '5'),
                _MediaTile(color: Color(0xffa7f3d0), label: 'Only selected'),
                _MediaTile(color: Color(0xfffde68a), label: 'Temp'),
                _MediaTile(color: Color(0xffbae6fd), label: 'Order'),
                _MediaTile(color: Color(0xfffecdd3), label: 'Done'),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ContextPanel extends StatelessWidget {
  const _ContextPanel({
    required this.title,
    required this.detail,
    required this.rows,
  });

  final String title;
  final String detail;
  final List<String> rows;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xffd9deea)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w800,
              color: const Color(0xff151b26),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            detail,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: const Color(0xff5e6675),
              height: 1.25,
            ),
          ),
          const SizedBox(height: 10),
          for (final row in rows)
            Padding(
              padding: const EdgeInsets.only(top: 5),
              child: Row(
                children: [
                  const _Dot(),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      row,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: const Color(0xff293241),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _CounterPill extends StatelessWidget {
  const _CounterPill({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: const Color(0xffecfdf5),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        child: Text(
          label,
          style: const TextStyle(
            color: Color(0xff047857),
            fontWeight: FontWeight.w800,
            fontSize: 12,
          ),
        ),
      ),
    );
  }
}

class _SelectedTab extends StatelessWidget {
  const _SelectedTab({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xff4863a8),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 16,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _PlainTab extends StatelessWidget {
  const _PlainTab({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xffeceef5),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: Color(0xff3d4350),
          fontSize: 16,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _MediaTile extends StatelessWidget {
  const _MediaTile({required this.color, required this.label});

  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(color: color),
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.36),
            borderRadius: BorderRadius.circular(999),
          ),
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: const Color(0xffe8edf9),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
        child: Text(
          label,
          style: Theme.of(context).textTheme.labelMedium?.copyWith(
            color: const Color(0xff334c8a),
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}

class _Dot extends StatelessWidget {
  const _Dot();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 7,
      height: 7,
      decoration: const BoxDecoration(
        color: Color(0xff4863a8),
        shape: BoxShape.circle,
      ),
    );
  }
}

Future<void> _loadScreenshotFont() async {
  final textFont = File('/System/Library/Fonts/Supplemental/Arial.ttf');
  final textBytes = await textFont.readAsBytes();

  await (FontLoader(
    'ScreenshotFont',
  )..addFont(Future<ByteData>.value(ByteData.sublistView(textBytes)))).load();
}
