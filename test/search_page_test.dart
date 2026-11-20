import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:openlib/l10n/app_localizations.dart';
import 'package:openlib/services/download_manager.dart';
import 'package:openlib/state/state.dart';
import 'package:openlib/ui/search_page.dart';

class _Downloads implements DownloadManager {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _Harness {
  _Harness(this.tester);
  final WidgetTester tester;
  final searches = <String>[];
  late ProviderContainer container;

  Future<void> pump({
    double textScale = 1.0,
    List<Override> overrides = const [],
  }) async {
    await tester.pumpWidget(ProviderScope(
      overrides: [
        downloadManagerProvider.overrideWithValue(_Downloads()),
        activeDownloadsProvider
            .overrideWith((ref) => Stream.value(<String, DownloadTask>{})),
        ...overrides,
      ],
      child: MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context)
              .copyWith(textScaler: TextScaler.linear(textScale)),
          child: child!,
        ),
        home: Scaffold(
          body: SearchPage(onSearch: (_, query) => searches.add(query)),
        ),
      ),
    ));
    container = ProviderScope.containerOf(
        tester.element(find.byType(SearchPage)));
    await tester.pump();
  }

  Finder get field => find.byType(TextField).first;
}

void main() {
  test('year list starts at the current year and keeps "All"', () {
    expect(yearValues.first, 'All');
    expect(yearValues[1], '${DateTime.now().year}');
    final future = buildYearValues(DateTime(2031, 1, 1));
    expect(future.sublist(0, 3), ['All', '2031', '2030']);
    expect(future, containsAllInOrder(['2015', '2010-2014', 'Before 1980']));
  });

  testWidgets('typing shows no suggestions and makes no network request',
      (tester) async {
    final h = _Harness(tester);
    final clients = _CountingHttpOverrides();
    await HttpOverrides.runWithHttpOverrides(() async {
      await h.pump();
      await tester.enterText(h.field, 'du');
      await tester.pump(const Duration(milliseconds: 100));
      await tester.enterText(h.field, 'dune');
      await tester.pump(const Duration(seconds: 2));
    }, clients);

    expect(clients.created, 0, reason: 'typing must not contact any server');
    expect(find.byType(ListTile), findsNothing);
    expect(h.container.read(searchQueryProvider), 'dune');
    expect(h.searches, isEmpty, reason: 'search runs only on submit');
  });

  testWidgets('clear button empties the field and the query', (tester) async {
    final h = _Harness(tester);
    await h.pump();

    // No clear button while empty.
    expect(find.byTooltip('Clear search'), findsNothing);

    await tester.enterText(h.field, 'dune');
    await tester.pump();
    await tester.tap(find.byTooltip('Clear search'));
    await tester.pump();

    expect(tester.widget<TextField>(h.field).controller!.text, isEmpty);
    expect(h.container.read(searchQueryProvider), isEmpty);
    expect(find.byTooltip('Clear search'), findsNothing);
  });

  testWidgets('keyboard search action submits the trimmed query',
      (tester) async {
    final h = _Harness(tester);
    await h.pump();

    final field = tester.widget<TextField>(h.field);
    expect(field.textInputAction, TextInputAction.search);
    expect(field.autocorrect, isFalse);
    expect(field.style!.fontSize, greaterThanOrEqualTo(16));

    await tester.enterText(h.field, 'dune ');
    await tester.testTextInput.receiveAction(TextInputAction.search);
    await tester.pump();
    expect(h.searches, ['dune']);
  });

  testWidgets('submit button has a tooltip and an empty query does not search',
      (tester) async {
    final h = _Harness(tester);
    await h.pump();

    await tester.tap(find.byTooltip('Search'));
    await tester.pump();
    expect(h.searches, isEmpty);
    expect(find.text('Search field is empty'), findsOneWidget);
  });

  testWidgets('filters wrap without overflow at 320 dp and 2x text',
      (tester) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(320, 2400);
    addTearDown(tester.view.reset);

    final h = _Harness(tester);
    await h.pump(
      textScale: 2.0,
      overrides: [
        selectedTypeState.overrideWith((ref) => 'Standards Document'),
        selectedSortState.overrideWith((ref) => 'Most Relevant'),
        selectedYearState.overrideWith((ref) => 'Before 1980'),
      ],
    );

    expect(tester.takeException(), isNull);
    expect(find.text('Standards document'), findsOneWidget);
    expect(find.text('Year published'), findsOneWidget);
    for (final element
        in find.byType(DropdownButtonFormField<String>).evaluate()) {
      final box = element.renderObject! as RenderBox;
      expect(box.size.width, lessThanOrEqualTo(320));
    }
  });

  testWidgets('a persisted filter value that no longer exists falls back',
      (tester) async {
    final h = _Harness(tester);
    await h.pump(
      overrides: [selectedYearState.overrideWith((ref) => '1850')],
    );
    expect(tester.takeException(), isNull);
  });
}

/// Counts HTTP clients created while typing; any network use would
/// create one.
class _CountingHttpOverrides extends HttpOverrides {
  int created = 0;

  @override
  HttpClient createHttpClient(SecurityContext? context) {
    created++;
    return super.createHttpClient(context);
  }
}
