import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:openlib/l10n/app_localizations.dart';
import 'package:openlib/services/download_manager.dart';
import 'package:openlib/state/state.dart';
import 'package:openlib/ui/components/active_downloads_widget.dart';

class _Downloads implements DownloadManager {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

DownloadTask _task(String title, double progress) => DownloadTask(
    id: 'book',
    md5: 'book',
    title: title,
    mirrors: [],
    format: 'epub',
    link: 'https://example.com/book',
    status: DownloadStatus.downloading,
    progress: progress);

void main() {
  testWidgets(
      'hidden downloads panel ignores progress events and shows the latest '
      'snapshot when its tab is selected again', (tester) async {
    final changes = StreamController<Map<String, DownloadTask>>.broadcast();
    addTearDown(changes.close);
    final selected = ValueNotifier<int>(0);
    addTearDown(selected.dispose);

    // Same shape as MainScreen: tabs kept in an IndexedStack, hidden ones
    // under TickerMode(enabled: false).
    await tester.pumpWidget(ProviderScope(
      overrides: [
        downloadManagerProvider.overrideWithValue(_Downloads()),
        activeDownloadsProvider.overrideWith((ref) => changes.stream),
      ],
      child: MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: ValueListenableBuilder<int>(
            valueListenable: selected,
            builder: (context, index, _) => IndexedStack(
              index: index,
              children: [
                for (var i = 0; i < 2; i++)
                  TickerMode(
                    enabled: i == index,
                    child: i == 0
                        ? const SingleChildScrollView(
                            child: ActiveDownloadsWidget())
                        : const Text('Other tab'),
                  ),
              ],
            ),
          ),
        ),
      ),
    ));

    changes.add({'book': _task('Book v1', 0.1)});
    await tester.pump();
    await tester.pump();
    expect(find.text('Book v1'), findsOneWidget);
    expect(find.text('10%'), findsOneWidget);

    // Hide the tab, then stream several progress snapshots.
    selected.value = 1;
    await tester.pump();
    for (final p in [0.2, 0.3, 0.4]) {
      changes.add({'book': _task('Book v2', p)});
      await tester.pump();
    }
    // The hidden panel did not rebuild: it still holds the old frame.
    expect(find.text('Book v1', skipOffstage: false), findsOneWidget);
    expect(find.text('Book v2', skipOffstage: false), findsNothing);
    expect(find.text('40%', skipOffstage: false), findsNothing);

    // Show it again: the latest snapshot appears at once, no new event.
    selected.value = 0;
    await tester.pump();
    expect(find.text('Book v1'), findsNothing);
    expect(find.text('Book v2'), findsOneWidget);
    expect(find.text('40%'), findsOneWidget);

    // And it is live again.
    changes.add({'book': _task('Book v2', 0.5)});
    await tester.pump();
    expect(find.text('50%'), findsOneWidget);
  });
}
