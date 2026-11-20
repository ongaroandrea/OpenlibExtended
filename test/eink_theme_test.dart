// E-ink mode: high-contrast monochrome theme and the EinkColors helpers.

// Flutter imports:
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

// Package imports:
import 'package:flutter_riverpod/flutter_riverpod.dart';

// Project imports:
import 'package:openlib/features/eink/eink.dart';
import 'package:openlib/main.dart' show MyApp;
import 'package:openlib/ui/onboarding/onboarding_page.dart';
import 'package:openlib/ui/themes.dart';

bool _isOpaque(Color c) => c.a == 1.0;

void _expectMonochrome(ThemeData theme, Color fg, Color bg) {
  final s = theme.colorScheme;
  final foregrounds = {
    'secondary': s.secondary,
    'tertiary': s.tertiary,
    'onSurface': s.onSurface,
    'onSurfaceVariant': s.onSurfaceVariant,
    'outline': s.outline,
    'outlineVariant': s.outlineVariant,
    'error': s.error,
    'inverseSurface': s.inverseSurface,
  };
  final backgrounds = {
    'onSecondary': s.onSecondary,
    'tertiaryContainer': s.tertiaryContainer,
    'secondaryContainer': s.secondaryContainer,
    'surface': s.surface,
    'surfaceContainerHighest': s.surfaceContainerHighest,
    'scaffold': theme.scaffoldBackgroundColor,
    'canvas': theme.canvasColor,
  };
  foregrounds.forEach((name, c) => expect(c, fg, reason: name));
  backgrounds.forEach((name, c) => expect(c, bg, reason: name));
  expect(s.shadow.a, 0, reason: 'no shadows');

  for (final style in [
    theme.textTheme.displayLarge,
    theme.textTheme.displayMedium,
    theme.textTheme.headlineMedium,
    theme.textTheme.headlineSmall,
    theme.textTheme.bodyMedium,
  ]) {
    expect(style?.color, fg);
  }

  final input = theme.inputDecorationTheme;
  expect(input.fillColor, bg);
  final enabled = input.enabledBorder as OutlineInputBorder;
  expect(enabled.borderSide.color, fg);
  expect(enabled.borderSide.width, greaterThanOrEqualTo(1));
  expect(theme.cardTheme.elevation, 0);
  expect((theme.cardTheme.shape as RoundedRectangleBorder).side.color, fg);
  expect(theme.dividerTheme.color, fg);
  expect(theme.navigationBarTheme.elevation, 0);
  expect(theme.chipTheme.backgroundColor, bg);

  final button = theme.elevatedButtonTheme.style!;
  expect(button.backgroundColor?.resolve({}), fg);
  expect(button.foregroundColor?.resolve({}), bg);
  expect(button.elevation?.resolve({}), 0);

  final colors = theme.extension<EinkColors>()!;
  expect(colors.monochrome, isTrue);
  expect(colors.foreground, fg);
  expect(colors.background, bg);
  for (final c in [colors.foreground, colors.background, colors.muted]) {
    expect(_isOpaque(c), isTrue);
  }
}

void main() {
  _stockWidgetsVisible();
  group('einkTheme', () {
    test('light theme is black on white', () {
      _expectMonochrome(einkTheme(lightTheme), Colors.black, Colors.white);
      // Secondary text stays at least as dark as #333.
      expect(
        einkTheme(lightTheme).extension<EinkColors>()!.muted,
        const Color(0xFF333333),
      );
    });

    test('dark theme is white on black', () {
      _expectMonochrome(einkTheme(darkTheme), Colors.white, Colors.black);
    });

    test('base themes carry no EinkColors and keep their colours', () {
      expect(lightTheme.extension<EinkColors>(), isNull);
      expect(darkTheme.extension<EinkColors>(), isNull);
      expect(lightTheme.colorScheme.secondary, secondaryColor);
      expect(lightTheme.colorScheme.tertiaryContainer, const Color(0xFFF2F2F2));
      expect(darkTheme.colorScheme.secondary, secondaryColor);
    });

    test('primary is a real contrast pair, not white on white', () {
      for (final (base, fg, bg) in [
        (lightTheme, Colors.black, Colors.white),
        (darkTheme, Colors.white, Colors.black),
      ]) {
        final s = einkTheme(base).colorScheme;
        expect(s.primary, isNot(s.surface));
        expect(s.primary, fg);
        expect(s.onPrimary, bg);
        expect(s.primaryContainer, bg);
        expect(s.onPrimaryContainer, fg);
      }
    });

    test('normal themes: primary contrasts with the surface', () {
      // Stock M3 widgets (FilledButton, dialog TextButtons, Switch,
      // Slider, spinners) paint with primary; white on white hid them.
      for (final (base, fg, bg) in [
        (lightTheme, Colors.black, Colors.white),
        (darkTheme, Colors.white, Colors.black),
      ]) {
        final s = base.colorScheme;
        expect(s.primary, fg);
        expect(s.onPrimary, bg);
        expect(s.surface, bg);
        // Pure black/white pair: readable on 16-grey e-ink as well.
        expect(_contrast(s.primary, s.surface), greaterThan(20));
      }
      // Elevated surfaces stay white instead of being tinted grey.
      expect(lightTheme.colorScheme.surfaceTint, Colors.white);
    });

    test('keeps fonts and the base button shape', () {
      final theme = einkTheme(lightTheme);
      expect(theme.textTheme.displayLarge?.fontSize, 21);
      expect(
        theme.elevatedButtonTheme.style!.shape?.resolve({}),
        lightTheme.elevatedButtonTheme.style!.shape?.resolve({}),
      );
    });
  });

  group('EinkColorX', () {
    Future<BuildContext> pumpWith(WidgetTester tester, ThemeData theme) async {
      late BuildContext captured;
      await tester.pumpWidget(MaterialApp(
        theme: theme,
        home: Builder(builder: (context) {
          captured = context;
          return const SizedBox();
        }),
      ));
      return captured;
    }

    testWidgets('is a no-op with the normal theme', (tester) async {
      final context = await pumpWith(tester, lightTheme);
      const grey = Color(0xFF595E60);
      expect(EinkColors.of(context), same(EinkColors.standard));
      expect(EinkColors.of(context).border, isNull);
      expect(grey.einkText(context, 170 / 255), grey.withAlpha(170));
      expect(grey.einkTint(context, 0.1), grey.withValues(alpha: 0.1));
      expect(Colors.green.einkFg(context), Colors.green);
      expect(Colors.white.einkBg(context), Colors.white);
      expect(EinkColors.of(context).muted, Colors.grey);
    });

    testWidgets('goes opaque black and white with the e-ink theme', (
      tester,
    ) async {
      final context = await pumpWith(tester, einkTheme(lightTheme));
      final colors = EinkColors.of(context);
      expect(colors.border, isNotNull);
      expect(Colors.black.einkText(context, 0.3), Colors.black);
      expect(Colors.red.einkTint(context, 0.1), Colors.transparent);
      expect(
        Colors.black.einkTint(context, 0.1, mono: colors.track),
        colors.track,
      );
      for (final status in [
        Colors.green,
        Colors.red,
        Colors.orange,
        Colors.amber,
        Colors.blue,
        Colors.grey,
      ]) {
        expect(status.einkFg(context), Colors.black);
      }
      expect(Colors.white.einkBg(context), Colors.white);
    });

    testWidgets('dark e-ink puts black text on white accents', (
      tester,
    ) async {
      final context = await pumpWith(tester, einkTheme(darkTheme));
      expect(Colors.green.einkFg(context), Colors.white);
      expect(Colors.white.einkBg(context), Colors.black);
    });
  });

  Future<ThemeData> appTheme(WidgetTester tester, bool eink) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [einkModeProvider.overrideWith((ref) => eink)],
        child: const MyApp(onboardingCompleted: false),
      ),
    );
    await tester.pump();
    return Theme.of(tester.element(find.byType(OnboardingPage).first));
  }

  testWidgets('MyApp with E-ink mode on uses the monochrome theme', (
    tester,
  ) async {
    final theme = await appTheme(tester, true);
    expect(theme.colorScheme.secondary, isIn([Colors.black, Colors.white]));
    expect(theme.extension<EinkColors>()?.monochrome, isTrue);
  });

  testWidgets('MyApp with E-ink mode off keeps the red accent', (
    tester,
  ) async {
    final theme = await appTheme(tester, false);
    expect(theme.colorScheme.secondary, secondaryColor);
    expect(theme.extension<EinkColors>(), isNull);
    expect(theme.splashFactory, isNot(NoSplash.splashFactory));
  });
}

void _stockWidgetsVisible() {
  for (final (name, theme) in [
    ('light', lightTheme),
    ('light e-ink', einkTheme(lightTheme)),
    ('dark', darkTheme),
    ('dark e-ink', einkTheme(darkTheme)),
  ]) {
    testWidgets('stock widgets are visible in $name theme', (tester) async {
      await tester.pumpWidget(MaterialApp(
        theme: theme,
        home: Scaffold(
          body: Column(children: [
            FilledButton(onPressed: () {}, child: const Text('Continue')),
            TextButton(onPressed: () {}, child: const Text('Cancel')),
            Switch(value: true, onChanged: (_) {}),
          ]),
        ),
      ));
      final surface = theme.colorScheme.surface;

      final filled = tester.widget<Material>(find.descendant(
          of: find.byType(FilledButton), matching: find.byType(Material)));
      expect(_contrast(filled.color!, surface), greaterThan(3),
          reason: 'FilledButton fill vs surface');
      final label = tester.widget<RichText>(find.descendant(
          of: find.byType(FilledButton), matching: find.byType(RichText)));
      expect(_contrast(label.text.style!.color!, filled.color!),
          greaterThan(4.5),
          reason: 'FilledButton label vs fill');

      final cancel = tester.widget<RichText>(find.descendant(
          of: find.byType(TextButton), matching: find.byType(RichText)));
      expect(_contrast(cancel.text.style!.color!, surface), greaterThan(4.5),
          reason: 'TextButton label vs surface');
    });
  }
}

/// WCAG contrast ratio between two colours.
double _contrast(Color a, Color b) {
  final la = a.computeLuminance(), lb = b.computeLuminance();
  final hi = la > lb ? la : lb, lo = la > lb ? lb : la;
  return (hi + 0.05) / (lo + 0.05);
}
