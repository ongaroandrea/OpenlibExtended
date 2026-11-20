// EPUB reader page turning against a real (long) epub: the edge tap
// zones and the page keys scroll epub_view's list by one screen minus the
// overlap, the middle does nothing, and the help overlay lists only the
// controls that exist. Kept in its own file for the same sqlite reason as
// reader_ux_test.dart.

// Dart imports:
import 'dart:io';

// Flutter imports:
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

// Package imports:
import 'package:archive/archive.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';

// Project imports:
import 'package:openlib/features/eink/eink.dart';
import 'package:openlib/ui/components/reader_help_overlay.dart';
import 'package:openlib/ui/epub_viewer.dart';
import 'package:openlib/l10n/app_localizations.dart';
import 'package:openlib/state/state.dart' show filePathProvider;

class _FakePathProvider extends PathProviderPlatform {
  Future<String> _dir(String name) async {
    final dir = Directory('/tmp/openlib_epub_page_test/$name');
    await dir.create(recursive: true);
    return dir.path;
  }

  @override
  Future<String?> getApplicationSupportPath() => _dir('support');

  @override
  Future<String?> getApplicationDocumentsPath() => _dir('documents');

  @override
  Future<String?> getTemporaryPath() => _dir('temp');

  @override
  Future<String?> getLibraryPath() => _dir('library');
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    if (Platform.isLinux || Platform.isWindows || Platform.isMacOS) {
      sqfliteFfiInit();
      databaseFactory = databaseFactoryFfi;
      PathProviderPlatform.instance = _FakePathProvider();
    }
  });

  late Directory tmpDir;

  setUp(() {
    tmpDir = Directory.systemTemp.createTempSync('openlib_epub_page_test');
  });

  tearDown(() {
    tmpDir.deleteSync(recursive: true);
  });

  Future<void> pumpReader(WidgetTester tester, File file) async {
    await tester.pumpWidget(ProviderScope(
      overrides: [
        filePathProvider.overrideWith((ref, fileName) => file.path),
      ],
      child: MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: const EpubViewerWidget(fileName: 'long.epub'),
      ),
    ));
    // The document opens with real file I/O, outside the fake clock.
    for (var i = 0; i < 20 && find.textContaining('Paragraph 0').evaluate().isEmpty; i++) {
      await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 50)));
      await tester.pump();
    }
  }

  ScrollPosition bookPosition(WidgetTester tester) {
    final scrollable = tester
        .stateList<ScrollableState>(find.byType(Scrollable))
        .firstWhere((s) => s.position.axis == Axis.vertical);
    return scrollable.position;
  }

  testWidgets('edge taps and page keys turn a page in the EPUB reader',
      (tester) async {
    final file = File('${tmpDir.path}/long.epub');
    _writeLongEpub(file);
    await pumpReader(tester, file);
    expect(find.textContaining('Paragraph 0'), findsWidgets,
        reason: 'the book must have loaded');
    // First run shows the help overlay; close it to reach the book.
    if (find.byType(ReaderHelpOverlay).evaluate().isNotEmpty) {
      await tester.tap(find.text('Got it'));
      await tester.pump();
    }
    expect(find.byType(PageTapZones), findsOneWidget);
    expect(find.byType(PageTurnKeys), findsOneWidget);

    final position = bookPosition(tester);
    final page = position.viewportDimension * (1 - pageTurnOverlap);
    final start = position.pixels;
    final bodyRect = tester.getRect(find.byType(PageTapZones));

    // Right edge: next page (animated outside E-ink mode).
    await tester.tapAt(Offset(bodyRect.right - 10, bodyRect.center.dy));
    await tester.pumpAndSettle();
    expect(position.pixels, moreOrLessEquals(start + page));

    // Middle: nothing.
    await tester.tapAt(bodyRect.center);
    await tester.pumpAndSettle();
    expect(position.pixels, moreOrLessEquals(start + page));

    // Left edge: back.
    await tester.tapAt(Offset(bodyRect.left + 10, bodyRect.center.dy));
    await tester.pumpAndSettle();
    expect(position.pixels, moreOrLessEquals(start));

    // Keys.
    await tester.sendKeyEvent(LogicalKeyboardKey.pageDown);
    await tester.pumpAndSettle();
    expect(position.pixels, moreOrLessEquals(start + page));
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowUp);
    await tester.pumpAndSettle();
    expect(position.pixels, moreOrLessEquals(start));

    // Position saves (chapter change, leaving the reader) go to sqlite;
    // let the real writes land, then run out sqflite's fake-clock
    // transaction timers.
    await tester.pumpWidget(const SizedBox());
    await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 300)));
    await tester.pump(const Duration(seconds: 11));
  });

  testWidgets('help overlay lists the real controls', (tester) async {
    Future<void> pump(bool volumeKeys) => tester.pumpWidget(MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: ReaderHelpOverlay(volumeKeys: volumeKeys, onDismiss: () {}),
        ));
    await pump(false);
    expect(find.text('Tap the edges'), findsOneWidget);
    expect(find.text('Page keys'), findsOneWidget);
    expect(find.text('Volume keys'), findsNothing);
    expect(find.textContaining('Pinch'), findsNothing);
    await pump(true);
    expect(find.text('Volume keys'), findsOneWidget);
  });
}

/// Writes a valid EPUB 3 book with one long chapter (many screens).
void _writeLongEpub(File file) {
  final archive = Archive();
  archive.addFile(ArchiveFile('mimetype', 20, 'application/epub+zip'.codeUnits)
    ..compression = CompressionType.none);
  archive.addFile(ArchiveFile.string('META-INF/container.xml', '''
<?xml version="1.0"?>
<container version="1.0" xmlns="urn:oasis:names:tc:opendocument:xmlns:container">
  <rootfiles>
    <rootfile full-path="OEBPS/content.opf" media-type="application/oebps-package+xml"/>
  </rootfiles>
</container>'''));
  archive.addFile(ArchiveFile.string('OEBPS/content.opf', '''
<?xml version="1.0" encoding="UTF-8"?>
<package xmlns="http://www.idpf.org/2007/opf" version="3.0" unique-identifier="bookid">
  <metadata xmlns:dc="http://purl.org/dc/elements/1.1/">
    <dc:identifier id="bookid">urn:uuid:0d3f1a5a-9d0a-4d0e-a4e9-6b6e6f6f6e6e</dc:identifier>
    <dc:title>Sample Book</dc:title>
    <dc:language>en</dc:language>
  </metadata>
  <manifest>
    <item id="nav" href="nav.xhtml" media-type="application/xhtml+xml" properties="nav"/>
    <item id="ch1" href="chapter1.xhtml" media-type="application/xhtml+xml"/>
  </manifest>
  <spine>
    <itemref idref="ch1"/>
  </spine>
</package>'''));
  archive.addFile(ArchiveFile.string('OEBPS/nav.xhtml', '''
<?xml version="1.0" encoding="UTF-8"?>
<html xmlns="http://www.w3.org/1999/xhtml" xmlns:epub="http://www.idpf.org/2007/ops">
  <head><title>Contents</title></head>
  <body><nav epub:type="toc"><ol><li><a href="chapter1.xhtml">Chapter 1</a></li></ol></nav></body>
</html>'''));
  archive.addFile(ArchiveFile.string('OEBPS/chapter1.xhtml', '''
<?xml version="1.0" encoding="UTF-8"?>
<html xmlns="http://www.w3.org/1999/xhtml" xmlns:epub="http://www.idpf.org/2007/ops">
  <head><title>Chapter 1</title></head>
  <body><h1>Sample Chapter</h1>${List.generate(300, (i) => '<p>Paragraph $i of the long chapter.</p>').join()}</body>
</html>'''));

  final data = ZipEncoder().encode(archive);
  file.writeAsBytesSync(data);
}
