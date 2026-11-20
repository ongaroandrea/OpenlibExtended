// The "Volume keys turn pages" switch in Settings › Reader: shown only on
// Android, follows E-ink mode until the user flips it, and the flip
// sticks over E-ink mode.

// Dart imports:
import 'dart:io';

// Flutter imports:
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

// Package imports:
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

// Project imports:
import 'package:openlib/features/eink/eink.dart';
import 'package:openlib/l10n/app_localizations.dart';
import 'package:openlib/state/state.dart';
import 'package:openlib/ui/settings_page.dart';

class _FakePathProvider extends PathProviderPlatform {
  static const base = '/tmp/openlib_settings_volume_test';

  @override
  Future<String?> getApplicationSupportPath() async => base;

  @override
  Future<String?> getApplicationDocumentsPath() async => base;

  @override
  Future<String?> getTemporaryPath() async => base;

  @override
  Future<String?> getLibraryPath() async => base;
}

void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
    PathProviderPlatform.instance = _FakePathProvider();
    Directory(_FakePathProvider.base).createSync(recursive: true);
  });

  Future<ProviderContainer> pumpPage(WidgetTester tester,
      {required bool eink}) async {
    final container = ProviderContainer(overrides: [
      readerPreferenceProvider.overrideWith((ref, format) async => 'internal'),
      installedReadersProvider.overrideWith((ref, format) async => []),
      einkModeProvider.overrideWith((ref) => eink),
    ]);
    addTearDown(container.dispose);
    await tester.pumpWidget(UncontrolledProviderScope(
      container: container,
      child: MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: const Scaffold(body: SettingsPage()),
      ),
    ));
    await tester.pump(const Duration(milliseconds: 100));
    await tester.pump(const Duration(milliseconds: 400));
    return container;
  }

  Finder volumeSwitch() => find.widgetWithText(
      SwitchListTile, 'Volume keys turn pages');

  testWidgets('hidden off Android', (tester) async {
    debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
    try {
      await pumpPage(tester, eink: true);
      expect(volumeSwitch(), findsNothing);
    } finally {
      debugDefaultTargetPlatformOverride = null;
    }
  });

  testWidgets('on Android it follows E-ink mode and saves a flip',
      (tester) async {
    debugDefaultTargetPlatformOverride = TargetPlatform.android;
    try {
      final container = await pumpPage(tester, eink: true);
      await tester.scrollUntilVisible(volumeSwitch(), 200,
          scrollable: find.byType(Scrollable).first);
      expect(tester.widget<SwitchListTile>(volumeSwitch()).value, isTrue);

      await tester.tap(volumeSwitch());
      await tester.pump();
      expect(tester.widget<SwitchListTile>(volumeSwitch()).value, isFalse);
      expect(container.read(volumeKeyPagingChoiceProvider), isFalse);
      expect(container.read(volumeKeyPagingProvider), isFalse);
    } finally {
      debugDefaultTargetPlatformOverride = null;
    }
  });
}
