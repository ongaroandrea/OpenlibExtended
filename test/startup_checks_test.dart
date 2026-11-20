// Tests for the battery throttle on startup network work: the mirror
// refresh and the update check run at most once per 24 h automatically,
// record a timestamp only on success, and manual actions always run.

// Dart imports:
import 'dart:io';

// Flutter imports:
import 'package:flutter_test/flutter_test.dart';

// Project imports:
import 'package:openlib/services/instance_manager.dart';
import 'package:openlib/services/preference_store.dart';
import 'package:openlib/services/slum_catalogue.dart';
import 'package:openlib/services/startup_checks.dart';

/// Serves the captured open-slum.org pages; counts requests and can be
/// switched to fail every request (offline).
class _Slum {
  late HttpServer server;
  int requests = 0;
  bool fail = false;

  String get base => 'http://127.0.0.1:${server.port}';

  Future<void> start() async {
    const files = {
      '/annas.html': 'slum_annas.html',
      '/libgen.html': 'slum_libgen.html',
      '/zlibrary.html': 'slum_zlibrary.html',
      '/other.html': 'slum_other.html',
    };
    server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    server.listen((request) async {
      requests++;
      final name = files[request.uri.path];
      final file = name == null ? null : File('test/fixtures/$name');
      if (!fail && file != null && await file.exists()) {
        request.response
          ..statusCode = HttpStatus.ok
          ..headers.contentType = ContentType.html
          ..write(await file.readAsString());
      } else {
        request.response.statusCode = HttpStatus.serviceUnavailable;
      }
      await request.response.close();
    });
  }
}

void main() {
  final t0 = DateTime(2026, 1, 1, 12);

  group('isDue', () {
    const day = Duration(hours: 24);

    test('due when never run', () {
      expect(isDue(null, t0, day), isTrue);
    });

    test('not due within the interval', () {
      expect(isDue(t0, t0, day), isFalse);
      expect(isDue(t0, t0.add(const Duration(hours: 23, minutes: 59)), day),
          isFalse);
    });

    test('due once the interval has passed', () {
      expect(isDue(t0, t0.add(day), day), isTrue);
      expect(isDue(t0, t0.add(const Duration(days: 3)), day), isTrue);
    });

    test('due when the last run is in the future (clock moved back)', () {
      expect(isDue(t0.add(const Duration(hours: 1)), t0, day), isTrue);
    });
  });

  group('shouldRefreshMirrors', () {
    test('empty cache forces a refresh even when not due', () {
      expect(
          shouldRefreshMirrors(hasCachedMirrors: false, last: t0, now: t0),
          isTrue);
    });

    test('cached and recent: skip', () {
      expect(
          shouldRefreshMirrors(
              hasCachedMirrors: true,
              last: t0,
              now: t0.add(const Duration(hours: 1))),
          isFalse);
    });

    test('cached but stale: refresh', () {
      expect(
          shouldRefreshMirrors(
              hasCachedMirrors: true,
              last: t0,
              now: t0.add(const Duration(hours: 25))),
          isTrue);
    });
  });

  group('ThrottledCheck', () {
    late MemoryPreferenceStore store;
    late DateTime now;
    late ThrottledCheck check;

    setUp(() {
      store = MemoryPreferenceStore();
      now = t0;
      check = ThrottledCheck(
          key: 'k',
          every: const Duration(hours: 24),
          store: store,
          clock: () => now);
    });

    test('success records ms since epoch and blocks the next run', () async {
      var runs = 0;
      expect(await check.runIfDue(() async => ++runs > 0), isTrue);
      expect(store.snapshot['k'], t0.millisecondsSinceEpoch);

      now = t0.add(const Duration(hours: 2));
      expect(await check.runIfDue(() async => ++runs > 0), isFalse);
      expect(runs, 1);

      now = t0.add(const Duration(hours: 24));
      expect(await check.runIfDue(() async => ++runs > 0), isTrue);
      expect(runs, 2);
    });

    test('failure does not record, so the next launch retries', () async {
      expect(await check.runIfDue(() async => false), isFalse);
      expect(store.snapshot.containsKey('k'), isFalse);
      expect(await check.runIfDue(() async => throw Exception('offline')),
          isFalse);
      expect(store.snapshot.containsKey('k'), isFalse);
      expect(await check.isDueNow(), isTrue);
    });

    test('force bypasses the throttle and updates the timestamp', () async {
      await check.recordSuccess();
      now = t0.add(const Duration(minutes: 5));
      var runs = 0;
      expect(await check.runIfDue(() async => ++runs > 0, force: true),
          isTrue);
      expect(runs, 1);
      expect(store.snapshot['k'], now.millisecondsSinceEpoch);
    });

    test('reads timestamps stored as strings', () async {
      await store.write('k', '${t0.millisecondsSinceEpoch}');
      expect(await check.lastSuccess(), t0);
    });
  });

  group('InstanceManager startup refresh', () {
    late _Slum slum;
    late MemoryPreferenceStore store;
    late DateTime now;

    InstanceManager manager() => InstanceManager.forTest(
          catalogue: SlumCatalogue(store: store, baseUrl: slum.base),
          store: store,
          clock: () => now,
        );

    setUp(() async {
      slum = _Slum();
      await slum.start();
      store = MemoryPreferenceStore();
      now = t0;
    });

    tearDown(() async => slum.server.close());

    test('first run (no cache) refreshes and records the timestamp',
        () async {
      expect(await manager().refreshOnStartup(), isTrue);
      expect(slum.requests, greaterThan(0));
      expect(store.snapshot[lastMirrorRefreshKey], t0.millisecondsSinceEpoch);
    });

    test('next launch within 24 h does not touch the network', () async {
      await manager().refreshOnStartup();
      final before = slum.requests;

      now = t0.add(const Duration(hours: 3));
      expect(await manager().refreshOnStartup(), isFalse);
      expect(slum.requests, before);
    });

    test('launch after 24 h refreshes again', () async {
      await manager().refreshOnStartup();
      final before = slum.requests;

      now = t0.add(const Duration(hours: 25));
      expect(await manager().refreshOnStartup(), isTrue);
      expect(slum.requests, greaterThan(before));
      expect(store.snapshot[lastMirrorRefreshKey],
          now.millisecondsSinceEpoch);
    });

    test('empty cache forces a refresh even with a recent timestamp',
        () async {
      await store.write(lastMirrorRefreshKey, t0.millisecondsSinceEpoch);
      now = t0.add(const Duration(minutes: 10));
      expect(await manager().refreshOnStartup(), isTrue);
      expect(slum.requests, greaterThan(0));
    });

    test('offline refresh with a cached list records nothing', () async {
      await manager().refreshOnStartup();

      // A day later SLUM is unreachable: the cached list carries over,
      // but the timestamp must stay put so the next launch retries.
      now = t0.add(const Duration(hours: 25));
      slum.fail = true;
      expect(await manager().refreshOnStartup(), isTrue);
      expect(store.snapshot[lastMirrorRefreshKey], t0.millisecondsSinceEpoch);

      now = t0.add(const Duration(hours: 26));
      final before = slum.requests;
      expect(await manager().refreshOnStartup(), isTrue);
      expect(slum.requests, greaterThan(before));
    });

    test('offline first run records nothing', () async {
      slum.fail = true;
      await manager().refreshOnStartup();
      expect(store.snapshot.containsKey(lastMirrorRefreshKey), isFalse);
    });

    test('manual refresh always runs and resets the throttle', () async {
      await manager().refreshOnStartup();
      final before = slum.requests;

      now = t0.add(const Duration(minutes: 30));
      final result = await manager().refresh();
      expect(result.hasMirrorList, isTrue);
      expect(slum.requests, greaterThan(before));
      expect(store.snapshot[lastMirrorRefreshKey],
          now.millisecondsSinceEpoch);
    });

    test('failed manual refresh does not record', () async {
      slum.fail = true;
      await manager().refresh();
      expect(store.snapshot.containsKey(lastMirrorRefreshKey), isFalse);
    });
  });
}
