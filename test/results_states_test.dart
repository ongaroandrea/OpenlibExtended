// Results page states beyond plain pagination: offline / every source
// down, a partial-failure notice, the no-results next steps, active
// filter chips with a reset that persists defaults, filters the source
// could not apply, the end-of-results marker, the wide-window layout,
// and the error widget logging once.

// Flutter imports:
import 'package:flutter/material.dart';

// Package imports:
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

// Project imports:
import 'package:openlib/l10n/app_localizations.dart';
import 'package:openlib/services/annas_archieve.dart';
import 'package:openlib/services/logger.dart';
import 'package:openlib/services/network_error.dart';
import 'package:openlib/services/search_manager.dart';
import 'package:openlib/state/state.dart';
import 'package:openlib/ui/components/book_card_widget.dart';
import 'package:openlib/ui/components/error_widget.dart';
import 'package:openlib/ui/results_page.dart';

class _FailingProvider implements SearchProvider {
  _FailingProvider(this.id, this.displayName);
  @override
  final SearchProviderId id;
  @override
  final String displayName;
  @override
  Future<List<BookData>> search(SearchQuery query) async =>
      throw StateError('$displayName is down');
}

class _FakeManager extends SearchManager {
  _FakeManager(List<SearchProvider> providers) : super(providers: providers);
  @override
  Future<Set<SearchProviderId>> enabledProviders() async =>
      {SearchProviderId.libgen, SearchProviderId.zlibrary};
}

List<BookData> _books(int n, {String prefix = 'Book', String? source}) =>
    List.generate(
        n,
        (i) => BookData(
              title: '$prefix $i',
              link: 'https://example.com/md5/$prefix$i',
              md5: 'md5-$prefix$i',
              source: source,
            ));

Widget _app(List<Override> overrides, {Widget? home}) => ProviderScope(
      overrides: overrides,
      child: MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: home ?? const ResultPage(searchQuery: 'docker'),
      ),
    );

Future<void> _settle(WidgetTester tester) async {
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 100));
  await tester.pump(const Duration(milliseconds: 100));
}

void main() {
  group('every source failed', () {
    List<Override> failing({required bool online}) => [
          searchManagerProvider.overrideWithValue(_FakeManager([
            _FailingProvider(SearchProviderId.libgen, 'Library Genesis'),
            _FailingProvider(SearchProviderId.zlibrary, 'Z-Library'),
          ])),
          internetCheckProvider.overrideWithValue(() async => online),
        ];

    testWidgets('offline says so, offers retry, never says restart',
        (tester) async {
      await tester.pumpWidget(_app(failing(online: false)));
      await _settle(tester);
      expect(find.text("You're offline"), findsOneWidget);
      expect(find.text('Try Again'), findsOneWidget);
      expect(find.textContaining('restart'), findsNothing);
    });

    testWidgets('online names the sources that failed', (tester) async {
      await tester.pumpWidget(_app(failing(online: true)));
      await _settle(tester);
      expect(find.text('No source responded'), findsOneWidget);
      expect(find.textContaining('Library Genesis, Z-Library'), findsOneWidget);
      expect(find.textContaining('restart'), findsNothing);
    });
  });

  test('the provider throws typed errors for offline and sources down',
      () async {
    for (final online in [false, true]) {
      final container = ProviderContainer(overrides: [
        searchManagerProvider.overrideWithValue(_FakeManager([
          _FailingProvider(SearchProviderId.libgen, 'Library Genesis'),
          _FailingProvider(SearchProviderId.zlibrary, 'Z-Library'),
        ])),
        internetCheckProvider.overrideWithValue(() async => online),
      ]);
      addTearDown(container.dispose);
      final sub = container.listen(
          searchProvider(const SearchPageKey('x', 1)), (_, __) {});
      addTearDown(sub.close);
      try {
        await container.read(searchProvider(const SearchPageKey('x', 1)).future);
        fail('expected an error');
      } on NetworkError catch (e) {
        expect(e.type,
            online ? NetworkErrorType.serverUnavailable : NetworkErrorType.noInternet);
        expect(e.failedSources,
            online ? ['Library Genesis', 'Z-Library'] : isEmpty);
      }
    }
  });

  testWidgets('partial failure shows a non-blocking notice with retry',
      (tester) async {
    var calls = 0;
    await tester.pumpWidget(_app([
      searchProvider.overrideWith((ref, key) async {
        if (key.page > 1) return [];
        calls++;
        return SearchResultPage(_books(3, source: 'Z-Library'),
            failedSources: ['Library Genesis'], resultSource: 'Z-Library');
      }),
    ]));
    await _settle(tester);
    expect(find.byType(BookInfoCard), findsWidgets);
    final notice = find.byKey(const Key('results-failed-sources'));
    expect(notice, findsOneWidget);
    expect(find.text("Library Genesis didn't respond"), findsOneWidget);
    await tester.tap(find.descendant(of: notice, matching: find.text('Retry')));
    await _settle(tester);
    expect(calls, 2);
    expect(find.byType(BookInfoCard), findsWidgets);
  });

  testWidgets('no matches while a source was down is not a dead end',
      (tester) async {
    final requests = <SearchPageKey>[];
    await tester.pumpWidget(_app([
      searchProvider.overrideWith((ref, key) async {
        requests.add(key);
        return SearchResultPage(const [],
            failedSources: key.source == null ? ['Library Genesis'] : []);
      }),
    ]));
    await _settle(tester);
    expect(find.text('No results found'), findsOneWidget);
    expect(find.textContaining("Library Genesis didn't respond"), findsOneWidget);
    expect(find.byKey(const Key('no-results-retry')), findsOneWidget);
    // No filters active: no clear-filters button.
    expect(find.byKey(const Key('clear-filters')), findsNothing);

    await tester.tap(find.byKey(const Key('try-another-source')));
    await tester.pump();
    await tester.tap(find.text('Z-Library').last);
    await _settle(tester);
    expect(requests.last.source, SearchProviderId.zlibrary);
    expect(find.textContaining("didn't respond"), findsNothing);
    expect(find.text('Check the spelling, try fewer words, or search another source.'),
        findsOneWidget);
  });

  testWidgets('edit search goes back to the search field', (tester) async {
    await tester.pumpWidget(_app([
      searchProvider.overrideWith((ref, key) async => SearchResultPage(const [])),
    ], home: Builder(
      builder: (context) => Scaffold(
        body: TextButton(
          onPressed: () => Navigator.push(context, MaterialPageRoute(
              builder: (_) => const ResultPage(searchQuery: 'docker'))),
          child: const Text('search field'),
        ),
      ),
    )));
    await tester.tap(find.text('search field'));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('edit-search')), findsOneWidget);
    await tester.tap(find.byKey(const Key('edit-search')));
    await tester.pumpAndSettle();
    expect(find.byType(ResultPage), findsNothing);
    expect(find.text('search field'), findsOneWidget);
  });

  testWidgets('active filters show as chips; reset persists defaults and searches again',
      (tester) async {
    final writes = <String, String>{};
    final searchedTypes = <String>[];
    await tester.pumpWidget(_app([
      selectedTypeState.overrideWith((ref) => 'Fiction Books'),
      selectedFileTypeState.overrideWith((ref) => 'Epub'),
      resultsPreferenceWriterProvider
          .overrideWithValue((key, value) async => writes[key] = value),
      searchProvider.overrideWith((ref, key) async {
        final type = ref.watch(selectedTypeState);
        if (key.page > 1) return [];
        searchedTypes.add(type);
        return _books(2, prefix: type == 'All' ? 'Any' : 'Fiction');
      }),
    ]));
    await _settle(tester);
    expect(find.byKey(const Key('active-filter-chips')), findsOneWidget);
    expect(find.text('Type: Fiction books'), findsOneWidget);
    expect(find.text('File type: Epub'), findsOneWidget);
    expect(find.text('Fiction 0'), findsOneWidget);

    await tester.tap(find.byKey(const Key('clear-filters')));
    await _settle(tester);
    expect(writes, {
      'filterType': 'All',
      'filterSort': 'Most Relevant',
      // The default file type is "Supported formats".
      'filterFileType': 'Supported',
      'filterLanguage': 'All',
      'filterYear': 'All',
    });
    expect(find.byKey(const Key('active-filter-chips')), findsNothing);
    expect(searchedTypes.last, 'All');
    expect(find.text('Any 0'), findsOneWidget);
    expect(find.text('Fiction 0'), findsNothing);
  });

  testWidgets('removing one chip resets only that filter', (tester) async {
    final writes = <String, String>{};
    await tester.pumpWidget(_app([
      selectedTypeState.overrideWith((ref) => 'Fiction Books'),
      selectedYearState.overrideWith((ref) => '2020'),
      resultsPreferenceWriterProvider
          .overrideWithValue((key, value) async => writes[key] = value),
      searchProvider.overrideWith((ref, key) async {
        ref.watch(selectedYearState);
        return key.page > 1 ? [] : _books(2);
      }),
    ]));
    await _settle(tester);
    await tester.tap(find.byTooltip('Remove filter').last);
    await _settle(tester);
    expect(writes, {'filterYear': 'All'});
    expect(find.text('Type: Fiction books'), findsOneWidget);
    expect(find.text('Year published: 2020'), findsNothing);
  });

  testWidgets('filters the source could not apply are called out',
      (tester) async {
    await tester.pumpWidget(_app([
      searchProvider.overrideWith((ref, key) async {
        if (key.page > 1) return [];
        return SearchResultPage(_books(2, source: 'Library Genesis'),
            resultSource: 'Library Genesis',
            ignoredFilters: {SearchFilter.sort, SearchFilter.type},
            clientSideFilters: {SearchFilter.sort});
      }),
    ]));
    await _settle(tester);
    expect(find.byKey(const Key('results-ignored-filters')), findsOneWidget);
    expect(
        find.text("Type, Sort by aren't supported by Library Genesis, "
            "so results aren't filtered by them."),
        findsOneWidget);
    expect(find.byKey(const Key('results-sorted-per-page')), findsOneWidget);
  });

  testWidgets('the last page shows an end-of-results marker', (tester) async {
    // Long list: the marker appears only after scrolling to the end.
    await tester.pumpWidget(_app([
      searchProvider.overrideWith(
          (ref, key) async => key.page > 1 ? [] : _books(20)),
    ]));
    await _settle(tester);
    expect(find.byKey(const Key('end-of-results')), findsNothing);
    await tester.drag(find.byType(CustomScrollView), const Offset(0, -6000));
    await _settle(tester);
    await tester.drag(find.byType(CustomScrollView), const Offset(0, -6000));
    await _settle(tester);
    expect(find.text('End of results · 20 books'), findsOneWidget);
  });

  testWidgets('a short single page ends without scrolling', (tester) async {
    await tester.pumpWidget(_app([
      searchProvider.overrideWith(
          (ref, key) async => key.page > 1 ? [] : _books(2)),
    ]));
    // Too short to scroll: the pager probes page 2 by itself, finds it
    // empty and says the list is complete.
    await _settle(tester);
    expect(find.text('End of results · 2 books'), findsOneWidget);
  });

  group('wide windows', () {
    Future<void> pumpAt(WidgetTester tester, double width) async {
      tester.view.physicalSize = Size(width, 900);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(_app([
        searchProvider.overrideWith(
            (ref, key) async => key.page > 1 ? [] : _books(6)),
      ]));
      await _settle(tester);
    }

    testWidgets('medium width keeps one readable column', (tester) async {
      await pumpAt(tester, 700);
      expect(find.byKey(const Key('results-grid-row')), findsNothing);
      expect(tester.getSize(find.byType(BookInfoCard).first).width,
          lessThanOrEqualTo(720));
    });

    testWidgets('expanded width lays results out in two columns',
        (tester) async {
      await pumpAt(tester, 1400);
      expect(find.byKey(const Key('results-grid-row')), findsWidgets);
      final first = tester.getRect(find.byType(BookInfoCard).at(0));
      final second = tester.getRect(find.byType(BookInfoCard).at(1));
      expect(first.top, second.top);
      expect(second.left, greaterThan(first.right));
      expect(second.right - first.left, lessThanOrEqualTo(1200));
    });

    testWidgets('phone width stays a single full-width list', (tester) async {
      await pumpAt(tester, 400);
      expect(find.byKey(const Key('results-grid-row')), findsNothing);
    });
  });

  testWidgets('CustomErrorWidget logs once, not on every rebuild',
      (tester) async {
    final error = StateError('boom');
    late StateSetter rebuild;
    await tester.pumpWidget(MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(
        body: StatefulBuilder(builder: (context, setState) {
          rebuild = setState;
          return CustomErrorWidget(
              error: error, stackTrace: StackTrace.empty, onRefresh: () {});
        }),
      ),
    ));
    final afterFirst = AppLogger().logCount;
    for (var i = 0; i < 3; i++) {
      rebuild(() {});
      await tester.pump();
    }
    expect(AppLogger().logCount, afterFirst);
    expect(find.text('Something went wrong'), findsOneWidget);
    expect(find.textContaining('restart'), findsNothing);
  });

  test('NetworkError localized copy covers offline and failed sources', () async {
    final l10n = await AppLocalizations.delegate.load(const Locale('en'));
    expect(NetworkError.offline().title(l10n), "You're offline");
    final down = NetworkError.sourcesUnavailable(['WeLib']);
    expect(down.title(l10n), 'No source responded');
    expect(down.advice(l10n), startsWith("WeLib didn't respond"));
    expect(NetworkError.fromException(Exception('x')).solution,
        isNot(contains('restart')));
  });
}
