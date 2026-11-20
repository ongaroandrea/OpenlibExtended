// Search result card: metadata parsing, layout at large text, contrast,
// semantics, and system x app text scale composition.

import 'dart:ui' show SemanticsAction;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:openlib/features/eink/eink.dart';
import 'package:openlib/l10n/app_localizations.dart';
import 'package:openlib/main.dart' show MyApp, composeTextScaler;
import 'package:openlib/state/state.dart';
import 'package:openlib/ui/components/book_card_widget.dart';
import 'package:openlib/ui/onboarding/onboarding_page.dart';
import 'package:openlib/ui/themes.dart';

Widget _card({
  String title = 'PIHKAL: A Chemical Love Story',
  String author = 'Alexander Shulgin & Ann Shulgin',
  String publisher = '13insurgentes',
  String? info = 'Spanish, EPUB, 3.83 MB, 1991',
  String? md5,
  String? source = 'Z-Library',
}) =>
    BookInfoCard(
      title: title,
      author: author,
      publisher: publisher,
      thumbnail: null,
      info: info,
      link: 'https://example.com/book',
      md5: md5,
      source: source,
      onClick: () {},
    );

Future<void> _pump(
  WidgetTester tester,
  Widget child, {
  ThemeData? theme,
  double textScale = 1.0,
  Size size = const Size(390, 800),
  bool downloaded = false,
}) async {
  await tester.binding.setSurfaceSize(size);
  addTearDown(() => tester.binding.setSurfaceSize(null));
  await tester.pumpWidget(ProviderScope(
    overrides: [
      resultCoverProvider.overrideWith((ref, url) async => null),
      checkIdExists.overrideWith((ref, id) async => downloaded),
    ],
    child: MaterialApp(
      theme: theme,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      builder: (context, c) => MediaQuery(
        data: MediaQuery.of(context)
            .copyWith(textScaler: TextScaler.linear(textScale)),
        child: c!,
      ),
      home: Scaffold(body: SingleChildScrollView(child: child)),
    ),
  ));
  await tester.pump();
  await tester.pump();
}

void main() {
  group('BookMeta.parse', () {
    test('libgen / z-library style info', () {
      final m = BookMeta.parse('Spanish, EPUB, 3.83 MB, 1991');
      expect(m.format, 'EPUB');
      expect(m.size, '3.83 MB');
      expect(m.year, '1991');
      expect(m.language, 'Spanish');
    });

    test('any format, not only pdf/epub/cbr/cbz', () {
      expect(BookMeta.parse('English, DJVU, 12 MB, 2004').format, 'DJVU');
      expect(BookMeta.parse('German, mobi, 700 KB').format, 'MOBI');
      expect(BookMeta.parse('Russian, FB2, 1.2 MB').format, 'FB2');
      expect(BookMeta.parse('English, AZW3').format, 'AZW3');
      expect(getFileType('French, ODT, 1 MB'), 'ODT');
    });

    test("anna's archive style info", () {
      final m = BookMeta.parse('English, PDF, 5.2MB, 📗 Book (unknown)');
      expect(m.format, 'PDF');
      expect(m.size, '5.2MB');
      expect(m.year, isNull);
    });

    test('language codes are not taken for a format', () {
      final m = BookMeta.parse('EN, 5 MB');
      expect(m.format, isNull);
      expect(m.size, '5 MB');
    });

    test('empty info', () {
      final m = BookMeta.parse(null);
      expect([m.format, m.size, m.year, m.language], everyElement(isNull));
    });
  });

  testWidgets('card shows author, format, size and year', (tester) async {
    await _pump(tester, _card());
    expect(find.text('Alexander Shulgin & Ann Shulgin'), findsOneWidget);
    expect(find.text('EPUB'), findsOneWidget);
    expect(find.text('3.83 MB · 1991'), findsOneWidget);
    expect(find.text('Z-Library'), findsOneWidget);

    // Author sits right under the title, at >= 13 sp.
    final titleY =
        tester.getTopLeft(find.text('PIHKAL: A Chemical Love Story')).dy;
    final authorY =
        tester.getTopLeft(find.text('Alexander Shulgin & Ann Shulgin')).dy;
    final publisherY =
        tester.getTopLeft(find.text('Publisher: 13insurgentes')).dy;
    expect(authorY, greaterThan(titleY));
    expect(authorY, lessThan(publisherY));
    final authorText =
        tester.widget<Text>(find.text('Alexander Shulgin & Ann Shulgin'));
    expect(authorText.style!.fontSize, greaterThanOrEqualTo(13));
  });

  testWidgets('missing author reads as localized Unknown', (tester) async {
    await _pump(tester, _card(author: 'Unknown', info: null, source: null));
    expect(find.text('Unknown'), findsWidgets);
  });

  testWidgets('no overflow at text scale 2.0 on a 320 dp screen',
      (tester) async {
    await _pump(
      tester,
      Column(children: [
        _card(
          title: 'A very long title that keeps going and going so that it '
              'needs several lines even on a wide screen, and then some more',
          author: 'Firstname Middlename Lastname, Another Coauthor Person, '
              'And A Third Author',
          publisher: 'An Extremely Long Publisher Name Incorporated',
          info: 'English, EPUB, 13.83 MB, 1991',
          source: "Anna's Archive",
        ),
        _card(),
      ]),
      textScale: 2.0,
      size: const Size(320, 2000),
    );
    expect(tester.takeException(), isNull);
    // The card grew past its 140 dp minimum instead of clipping.
    final card = tester.getSize(find.byType(BookInfoCard).first);
    expect(card.height, greaterThan(150));
    expect(card.height, greaterThanOrEqualTo(48));
  });

  for (final (name, theme) in [('light', lightTheme), ('dark', darkTheme)]) {
    testWidgets('author and chips reach 4.5:1 in $name theme', (tester) async {
      await _pump(tester, _card(), theme: theme);
      final scheme = theme.colorScheme;
      final cardColor = scheme.tertiaryContainer;

      final author =
          tester.widget<Text>(find.text('Alexander Shulgin & Ann Shulgin'));
      expect(wcagContrast(author.style!.color!, cardColor),
          greaterThanOrEqualTo(4.5));

      final details = tester.widget<Text>(find.text('3.83 MB · 1991'));
      expect(wcagContrast(details.style!.color!, cardColor),
          greaterThanOrEqualTo(4.5));

      for (final label in ['EPUB', 'Z-Library']) {
        final text = tester.widget<Text>(find.text(label));
        final box = tester.widget<Container>(find
            .ancestor(of: find.text(label), matching: find.byType(Container))
            .first);
        final fill = (box.decoration! as BoxDecoration).color!;
        expect(fill.a, 1.0, reason: '$label chip is opaque');
        expect(
            wcagContrast(text.style!.color!, fill), greaterThanOrEqualTo(4.5),
            reason: '$label chip text');
      }
    });
  }

  testWidgets('chips stay opaque black-on-white in E-ink mode', (tester) async {
    await _pump(tester, _card(), theme: einkTheme(lightTheme));
    for (final label in ['EPUB', 'Z-Library']) {
      final text = tester.widget<Text>(find.text(label));
      final box = tester.widget<Container>(find
          .ancestor(of: find.text(label), matching: find.byType(Container))
          .first);
      expect((box.decoration! as BoxDecoration).color, Colors.black);
      expect(text.style!.color, Colors.white);
    }
  });

  testWidgets('card is one button node with title, author, format, size',
      (tester) async {
    final handle = tester.ensureSemantics();
    await _pump(tester, _card());
    final node = tester.getSemantics(find.bySemanticsLabel(RegExp('^PIHKAL')));
    final label = node.label;
    expect(label, contains('PIHKAL: A Chemical Love Story'));
    expect(label, contains('Alexander Shulgin & Ann Shulgin'));
    expect(label, contains('EPUB'));
    expect(label, contains('3.83 MB'));
    expect(label, contains('1991'));
    expect(label, isNot(contains('Already downloaded')));
    expect(node.flagsCollection.isButton, isTrue);
    expect(node.getSemanticsData().hasAction(SemanticsAction.tap), isTrue);
    handle.dispose();
  });

  testWidgets('downloaded badge is announced', (tester) async {
    final handle = tester.ensureSemantics();
    await _pump(tester, _card(md5: 'abc'), downloaded: true);
    expect(find.byIcon(Icons.check), findsOneWidget);
    final icon = tester.widget<Icon>(find.byIcon(Icons.check));
    expect(icon.semanticLabel, 'Already downloaded');
    expect(tester.getSemantics(find.bySemanticsLabel(RegExp('^PIHKAL'))).label,
        contains('Already downloaded'));
    handle.dispose();
  });

  group('text scale composition', () {
    test('system scale is multiplied by the app scale', () {
      final s = composeTextScaler(const TextScaler.linear(1.5), 1.2);
      expect(s.scale(10), closeTo(18, 1e-9));
      expect(composeTextScaler(TextScaler.noScaling, 1.4).scale(10),
          closeTo(14, 1e-9));
    });

    test('combined scale is capped at 3x', () {
      final s = composeTextScaler(const TextScaler.linear(2.0), 2.0);
      expect(s.scale(10), closeTo(30, 1e-9));
    });

    testWidgets('MyApp keeps the system font size and adds the slider',
        (tester) async {
      tester.platformDispatcher.textScaleFactorTestValue = 1.5;
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      await tester.pumpWidget(ProviderScope(
        overrides: [fontSizeScaleProvider.overrideWith((ref) => 1.2)],
        child: const MyApp(onboardingCompleted: false),
      ));
      await tester.pump();
      final context = tester.element(find.byType(OnboardingPage).first);
      expect(MediaQuery.textScalerOf(context).scale(10), closeTo(18, 1e-9));
    });
  });
}
