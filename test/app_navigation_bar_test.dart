import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:openlib/l10n/app_localizations.dart';
import 'package:openlib/ui/components/app_navigation_bar.dart';

Future<void> pumpBar(WidgetTester tester, List<int> selected) async {
  var index = 0;
  await tester.pumpWidget(MaterialApp(
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: StatefulBuilder(
      builder: (context, update) => Scaffold(
        body: const SizedBox.expand(key: ValueKey('page-content')),
        bottomNavigationBar: AppNavigationBar(
          selectedIndex: index,
          onSelected: (value) => update(() {
            index = value;
            selected.add(value);
          }),
        ),
      ),
    ),
  ));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('bottom bar leaves the page body visible', (tester) async {
    await tester.binding.setSurfaceSize(const Size(385, 834));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await pumpBar(tester, []);
    final body = tester.getRect(find.byKey(const ValueKey('page-content')));
    final bar = tester.getRect(find.byType(AppNavigationBar));
    expect(body.height, greaterThan(700));
    expect(bar.height, lessThan(120));
    expect(body.bottom, bar.top);
  });

  testWidgets('fits compact phone widths without overflowing', (tester) async {
    for (final width in [320.0, 360.0]) {
      await tester.binding.setSurfaceSize(Size(width, 640));
      await pumpBar(tester, []);
      expect(tester.takeException(), isNull, reason: 'width $width');
    }
    await tester.binding.setSurfaceSize(null);
  });

  testWidgets('tabs are icon only, with names kept for screen readers',
      (tester) async {
    final semantics = tester.ensureSemantics();
    await pumpBar(tester, []);
    for (final label in ['Home', 'Search', 'My Library', 'Settings']) {
      expect(find.text(label), findsNothing,
          reason: 'no text label is drawn on the bar');
      expect(find.bySemanticsLabel(label), findsOneWidget,
          reason: 'TalkBack still announces the tab');
    }
    // Selecting a tab must not reveal a label either.
    await tester.tap(find.byIcon(Icons.search).last);
    await tester.pumpAndSettle();
    expect(find.text('Search'), findsNothing);
    semantics.dispose();
  });

  testWidgets('a second tab tap is accepted while the first pill is animating',
      (tester) async {
    final selected = <int>[];
    await pumpBar(tester, selected);
    await tester.tap(find.byIcon(Icons.search).last);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 40));
    await tester.tap(find.byIcon(Icons.settings).last);
    await tester.pump();
    expect(selected, [1, 3],
        reason: 'animation must never lock out a subsequent navigation tap');
    await tester.pump(const Duration(milliseconds: 200));
    expect(tester.takeException(), isNull);
  });
}
