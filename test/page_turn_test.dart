// Page turning for the readers (lib/features/eink/page_keys.dart and
// page_scroll.dart): the key mapping, PageTurnKeys, the volume-key
// channel, the EPUB-style edge tap zones that scroll by one screen, and
// the results page's "Load more" button in E-ink mode.

// Flutter imports:
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

// Package imports:
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

// Project imports:
import 'package:openlib/features/eink/eink.dart';
import 'package:openlib/l10n/app_localizations.dart';
import 'package:openlib/services/annas_archieve.dart';
import 'package:openlib/state/state.dart';
import 'package:openlib/ui/results_page.dart';

/// A tall list under tap zones and page keys, scrolled the way the EPUB
/// reader does it: find the position under [bookKey], scroll by a page.
class _PagedList extends StatelessWidget {
  const _PagedList({required this.animate, this.turns});

  final bool animate;
  final List<PageTurn>? turns;
  static final bookKey = GlobalKey();

  void _turn(PageTurn turn) {
    turns?.add(turn);
    final position = findVerticalScrollPosition(bookKey.currentContext!);
    scrollByPage(position!, turn, animate: animate);
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        body: PageTurnKeys(
          onTurn: _turn,
          child: PageTapZones(
            onTurn: _turn,
            child: KeyedSubtree(
              key: bookKey,
              child: ListView.builder(
                itemCount: 200,
                itemExtent: 50,
                itemBuilder: (_, i) => Text('Line $i'),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

void main() {
  group('pageTurnForKey', () {
    test('forward keys', () {
      for (final key in [
        LogicalKeyboardKey.pageDown,
        LogicalKeyboardKey.arrowRight,
        LogicalKeyboardKey.arrowDown,
        LogicalKeyboardKey.space,
      ]) {
        expect(pageTurnForKey(key), PageTurn.next, reason: key.debugName);
      }
    });

    test('backward keys', () {
      for (final key in [
        LogicalKeyboardKey.pageUp,
        LogicalKeyboardKey.arrowLeft,
        LogicalKeyboardKey.arrowUp,
      ]) {
        expect(pageTurnForKey(key), PageTurn.previous, reason: key.debugName);
      }
      expect(pageTurnForKey(LogicalKeyboardKey.space, shift: true),
          PageTurn.previous);
    });

    test('other keys are left alone', () {
      expect(pageTurnForKey(LogicalKeyboardKey.keyA), isNull);
      expect(pageTurnForKey(LogicalKeyboardKey.enter), isNull);
    });
  });

  group('PageTurnKeys', () {
    testWidgets('key presses turn pages, Shift+Space goes back',
        (tester) async {
      final turns = <PageTurn>[];
      await tester.pumpWidget(MaterialApp(
        home: PageTurnKeys(onTurn: turns.add, child: const SizedBox()),
      ));
      await tester.pump();

      await tester.sendKeyEvent(LogicalKeyboardKey.pageDown);
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowLeft);
      await tester.sendKeyEvent(LogicalKeyboardKey.space);
      await tester.sendKeyDownEvent(LogicalKeyboardKey.shiftLeft);
      await tester.sendKeyEvent(LogicalKeyboardKey.space);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.shiftLeft);
      await tester.sendKeyEvent(LogicalKeyboardKey.keyA);

      expect(turns, [
        PageTurn.next,
        PageTurn.previous,
        PageTurn.next,
        PageTurn.previous,
      ]);
    });

    testWidgets(
        'volume keys: enables the channel only while mounted and maps '
        'pageKey calls', (tester) async {
      debugDefaultTargetPlatformOverride = TargetPlatform.android;
      final calls = <Object?>[];
      final messenger = tester.binding.defaultBinaryMessenger;
      messenger.setMockMethodCallHandler(VolumeKeyPaging.channel,
          (call) async {
        if (call.method == 'setVolumeKeyPaging') calls.add(call.arguments);
        return null;
      });

      final turns = <PageTurn>[];
      Future<void> pump(bool volumeKeys) => tester.pumpWidget(MaterialApp(
            home: PageTurnKeys(
                onTurn: turns.add,
                volumeKeys: volumeKeys,
                child: const SizedBox()),
          ));

      await pump(false);
      expect(calls, isEmpty);
      expect(VolumeKeyPaging.active, isFalse);

      await pump(true);
      expect(calls, [true]);
      expect(VolumeKeyPaging.active, isTrue);

      // MainActivity forwards the keys as pageKey calls.
      Future<void> press(String which) => messenger.handlePlatformMessage(
          VolumeKeyPaging.channel.name,
          const StandardMethodCodec()
              .encodeMethodCall(MethodCall('pageKey', which)),
          (_) {});
      await press('next');
      await press('previous');
      expect(turns, [PageTurn.next, PageTurn.previous]);

      // Turning the setting off, or leaving the reader, gives the volume
      // keys back.
      await pump(false);
      expect(calls, [true, false]);
      await pump(true);
      await tester.pumpWidget(const SizedBox());
      expect(calls, [true, false, true, false]);
      expect(VolumeKeyPaging.active, isFalse);

      messenger.setMockMethodCallHandler(VolumeKeyPaging.channel, null);
      debugDefaultTargetPlatformOverride = null;
    });

    test('volume key paging follows E-ink mode until the user chooses', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      expect(container.read(volumeKeyPagingProvider), isFalse);
      container.read(einkModeProvider.notifier).state = true;
      expect(container.read(volumeKeyPagingProvider), isTrue);
    });
  });

  group('tap zones and scrolling by a page', () {
    // 800x600 test surface: one page = 600 - 10% overlap = 540 px.
    const page = 540.0;

    ScrollPosition position(WidgetTester tester) =>
        tester.state<ScrollableState>(find.byType(Scrollable)).position;

    testWidgets('right edge = next page, left edge = previous, middle = none',
        (tester) async {
      final turns = <PageTurn>[];
      await tester.pumpWidget(_PagedList(animate: false, turns: turns));

      await tester.tapAt(const Offset(780, 300));
      await tester.pump();
      expect(position(tester).pixels, page);

      await tester.tapAt(const Offset(780, 300));
      await tester.pump();
      expect(position(tester).pixels, 2 * page);

      await tester.tapAt(const Offset(400, 300));
      await tester.pump();
      expect(position(tester).pixels, 2 * page);

      await tester.tapAt(const Offset(20, 300));
      await tester.pump();
      expect(position(tester).pixels, page);
      expect(turns, [PageTurn.next, PageTurn.next, PageTurn.previous]);
    });

    testWidgets('drags and long presses in an edge zone do not turn',
        (tester) async {
      final turns = <PageTurn>[];
      await tester.pumpWidget(_PagedList(animate: false, turns: turns));

      await tester.dragFrom(const Offset(780, 400), const Offset(0, -100));
      await tester.pump();
      await tester.longPressAt(const Offset(780, 300));
      await tester.pump();
      expect(turns, isEmpty);
    });

    testWidgets('page keys scroll the list by a page', (tester) async {
      await tester.pumpWidget(const _PagedList(animate: false));
      await tester.pump();

      await tester.sendKeyEvent(LogicalKeyboardKey.pageDown);
      await tester.pump();
      expect(position(tester).pixels, page);
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      await tester.pump();
      expect(position(tester).pixels, 2 * page);
      await tester.sendKeyEvent(LogicalKeyboardKey.pageUp);
      await tester.pump();
      expect(position(tester).pixels, page);
    });

    testWidgets('stops at the ends instead of overscrolling', (tester) async {
      await tester.pumpWidget(const _PagedList(animate: false));
      await tester.sendKeyEvent(LogicalKeyboardKey.pageUp);
      await tester.pump();
      expect(position(tester).pixels, 0);

      final max = position(tester).maxScrollExtent;
      position(tester).jumpTo(max - 10);
      await tester.sendKeyEvent(LogicalKeyboardKey.pageDown);
      await tester.pump();
      expect(position(tester).pixels, max);
    });

    testWidgets('jumps in one frame when not animating, animates otherwise',
        (tester) async {
      await tester.pumpWidget(const _PagedList(animate: true));
      await tester.tapAt(const Offset(780, 300));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      final mid = position(tester).pixels;
      expect(mid, greaterThan(0));
      expect(mid, lessThan(page));
      await tester.pumpAndSettle();
      expect(position(tester).pixels, page);
    });
  });

  group('results page in E-ink mode', () {
    Future<List<BookData>> fakeSearch(SearchPageKey key, List<int> calls) async {
      calls.add(key.page);
      if (key.page >= 3) return [];
      return List.generate(
          20,
          (i) => BookData(
                title: 'Book ${key.page}-$i',
                link: 'https://example.com/md5/p${key.page}-$i',
                md5: 'md5-p${key.page}-$i',
              ));
    }

    Future<List<int>> pumpResults(WidgetTester tester,
        {required bool eink}) async {
      final calls = <int>[];
      await tester.pumpWidget(ProviderScope(
        overrides: [
          einkModeProvider.overrideWith((ref) => eink),
          searchProvider.overrideWith((ref, key) => fakeSearch(key, calls)),
        ],
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: const ResultPage(searchQuery: 'docker'),
        ),
      ));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      return calls;
    }

    testWidgets('scrolling to the end shows Load more instead of loading',
        (tester) async {
      final calls = await pumpResults(tester, eink: true);
      expect(calls, [1]);

      await tester.drag(find.byType(CustomScrollView), const Offset(0, -6000));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      expect(calls, [1], reason: 'no auto-load in E-ink mode');
      expect(find.text('Book 2-0'), findsNothing);

      final loadMore = find.byKey(const Key('load-more-results'));
      expect(loadMore, findsOneWidget);
      expect(find.text('Load more'), findsOneWidget);

      await tester.tap(loadMore);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      expect(calls, [1, 2]);
      await tester.drag(find.byType(CustomScrollView), const Offset(0, -6000));
      await tester.pump();
      expect(find.text('Book 2-19'), findsOneWidget);
      expect(calls, [1, 2]);
    });

    testWidgets('normal mode keeps auto-loading and has no button',
        (tester) async {
      final calls = await pumpResults(tester, eink: false);
      await tester.drag(find.byType(CustomScrollView), const Offset(0, -6000));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      expect(calls, contains(2));
      expect(find.byKey(const Key('load-more-results')), findsNothing);
    });
  });
}
