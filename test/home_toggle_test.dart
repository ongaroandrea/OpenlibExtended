// The Trending / Genres switch on the home header: both icons must stay
// visible in every theme (the unselected one used to be black on black),
// and screen readers must hear which one is selected.

// Flutter imports:
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

// Project imports:
import 'package:openlib/features/eink/eink.dart';
import 'package:openlib/l10n/app_localizations.dart';
import 'package:openlib/ui/home_page.dart';
import 'package:openlib/ui/themes.dart';

double _contrast(Color a, Color b) {
  final la = a.computeLuminance(), lb = b.computeLuminance();
  final hi = la > lb ? la : lb, lo = la > lb ? lb : la;
  return (hi + 0.05) / (lo + 0.05);
}

Future<List<int>> _pump(WidgetTester tester, ThemeData theme, int selected) async {
  final taps = <int>[];
  await tester.pumpWidget(MaterialApp(
    theme: theme,
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: Scaffold(
      body: Center(
        child: PelletContainer(
          selectedIndex: selected,
          onTrendingSelected: () => taps.add(0),
          onCategoriesSelected: () => taps.add(1),
        ),
      ),
    ),
  ));
  await tester.pumpAndSettle();
  return taps;
}

void _expectVisible(WidgetTester tester, IconData icon, String reason) {
  final iconWidget = tester.widget<Icon>(find.byIcon(icon));
  final segment = tester.widget<AnimatedContainer>(find.ancestor(
      of: find.byIcon(icon), matching: find.byType(AnimatedContainer)));
  final fill = (segment.decoration as BoxDecoration?)?.color;
  expect(fill, isNotNull, reason: '$reason: segment has a fill');
  expect(_contrast(iconWidget.color!, fill!), greaterThan(3),
      reason: '$reason: icon vs fill');
}

void main() {
  for (final (name, theme) in [
    ('light', lightTheme),
    ('dark', darkTheme),
    ('light e-ink', einkTheme(lightTheme)),
    ('dark e-ink', einkTheme(darkTheme)),
  ]) {
    for (final selected in [0, 1]) {
      testWidgets('both icons visible in $name theme, tab $selected selected',
          (tester) async {
        await _pump(tester, theme, selected);
        _expectVisible(tester, Icons.trending_up, '$name trending');
        _expectVisible(tester, Icons.dashboard_rounded, '$name genres');
      });
    }
  }

  testWidgets('taps switch tabs and screen readers hear the selection',
      (tester) async {
    final semantics = tester.ensureSemantics();
    final taps = await _pump(tester, lightTheme, 0);

    expect(
        tester.getSemantics(find.bySemanticsLabel('Trending')),
        matchesSemantics(
            label: 'Trending',
            isButton: true,
            hasSelectedState: true,
            isSelected: true));
    expect(
        tester.getSemantics(find.bySemanticsLabel('Genres')),
        matchesSemantics(
            label: 'Genres',
            isButton: true,
            hasSelectedState: true,
            hasTapAction: true));

    await tester.tap(find.byIcon(Icons.dashboard_rounded));
    await tester.tap(find.byIcon(Icons.trending_up)); // already selected
    expect(taps, [1]);
    semantics.dispose();
  });
}
