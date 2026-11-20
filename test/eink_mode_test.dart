// E-ink mode: device detection, still widgets, no-fling scrolling and
// throttled download progress.

// Flutter imports:
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

// Package imports:
import 'package:flutter_riverpod/flutter_riverpod.dart';

// Project imports:
import 'package:openlib/main.dart' show MyApp;
import 'package:openlib/features/eink/eink.dart';
import 'package:openlib/ui/onboarding/onboarding_page.dart';

void main() {
  group('looksLikeEinkDevice', () {
    test('matches known e-ink makers case-insensitively', () {
      expect(looksLikeEinkDevice(manufacturer: 'ONYX', brand: 'MAX3'), isTrue);
      expect(looksLikeEinkDevice(manufacturer: 'x', brand: 'Bigme'), isTrue);
      expect(looksLikeEinkDevice(manufacturer: 'PocketBook'), isTrue);
    });

    test('ignores ordinary phones and missing values', () {
      expect(
        looksLikeEinkDevice(manufacturer: 'Google', brand: 'google'),
        isFalse,
      );
      expect(looksLikeEinkDevice(), isFalse);
    });
  });

  group('shouldEmitProgressUi', () {
    final t0 = DateTime(2026, 1, 1);

    test('first update and completion always go through', () {
      expect(
        shouldEmitProgressUi(
          lastEmit: null,
          now: t0,
          progress: 0.1,
          eink: true,
        ),
        isTrue,
      );
      expect(
        shouldEmitProgressUi(lastEmit: t0, now: t0, progress: 1.0, eink: true),
        isTrue,
      );
    });

    test('normal mode repaints at most every 250 ms', () {
      bool at(int ms) => shouldEmitProgressUi(
        lastEmit: t0,
        now: t0.add(Duration(milliseconds: ms)),
        progress: 0.5,
        eink: false,
      );
      expect(at(100), isFalse);
      expect(at(250), isTrue);
    });

    test('e-ink mode repaints at most every 2 s', () {
      bool at(int ms) => shouldEmitProgressUi(
        lastEmit: t0,
        now: t0.add(Duration(milliseconds: ms)),
        progress: 0.5,
        eink: true,
      );
      expect(at(1000), isFalse);
      expect(at(2000), isTrue);
    });
  });

  testWidgets('BusyIndicator is a static icon when animations are off', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: MediaQuery(
          data: MediaQueryData(disableAnimations: true),
          child: Center(
            child: SizedBox(width: 20, height: 20, child: BusyIndicator()),
          ),
        ),
      ),
    );
    expect(find.byType(CircularProgressIndicator), findsNothing);
    expect(find.byIcon(Icons.hourglass_empty), findsOneWidget);
    expect(tester.hasRunningAnimations, isFalse);
  });

  testWidgets('BusyIndicator spins normally', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: Center(child: BusyIndicator())),
    );
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });

  testWidgets('E-ink mode: no fling, no transitions, no splashes', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [einkModeProvider.overrideWith((ref) => true)],
        child: const MyApp(onboardingCompleted: false),
      ),
    );
    await tester.pump();

    final context = tester.element(find.byType(OnboardingPage).first);
    final physics = ScrollConfiguration.of(context).getScrollPhysics(context);
    expect(physics, isA<EinkScrollPhysics>());
    expect(MediaQuery.disableAnimationsOf(context), isTrue);

    final theme = Theme.of(context);
    expect(theme.splashFactory, NoSplash.splashFactory);
    expect(
      theme.pageTransitionsTheme.builders[TargetPlatform.android].runtimeType
          .toString(),
      '_NoTransitionsBuilder',
    );
  });

  test('EinkScrollPhysics creates no fling simulation', () {
    const physics = EinkScrollPhysics();
    final metrics = FixedScrollMetrics(
      minScrollExtent: 0,
      maxScrollExtent: 1000,
      pixels: 500,
      viewportDimension: 600,
      axisDirection: AxisDirection.down,
      devicePixelRatio: 1,
    );
    expect(physics.createBallisticSimulation(metrics, 3000), isNull);
  });
}
