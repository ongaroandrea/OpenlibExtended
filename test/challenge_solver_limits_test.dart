// Battery/CPU limits of the DDoS challenge solver: the hard time limit on the
// invisible (headless) solve, disposal of the headless engine on every path,
// and the slower poll cadence in E-ink mode.

// Dart imports:
import 'dart:async';

// Flutter imports:
import 'package:flutter_test/flutter_test.dart';

// Project imports:
import 'package:openlib/features/eink/progress_throttle.dart';
import 'package:openlib/services/challenge_html_cache.dart';
import 'package:openlib/services/webview_challenge_solver.dart';

final String _usableHtml = '<html><body>${'x' * 1200}</body></html>';

/// Fake headless session that records disposal and cancellation.
class _FakeSession {
  _FakeSession(this._solve);

  final Future<String?> Function(bool Function() cancelled) _solve;
  int disposeCalls = 0;
  bool Function()? cancelled;

  HeadlessSolveSession get session => (
        solve: (c) {
          cancelled = c;
          return _solve(c);
        },
        dispose: () async => disposeCalls++,
      );
}

void main() {
  group('headless hard time limit', () {
    test('the limit caps whatever timeout the caller asks for', () {
      const limit = WebviewChallengeSolver.headlessSolveLimit;
      expect(limit, greaterThanOrEqualTo(const Duration(seconds: 30)));
      expect(limit, lessThanOrEqualTo(const Duration(seconds: 45)));
      expect(
          WebviewChallengeSolver.headlessTimeoutFor(
              const Duration(seconds: 60)),
          limit);
      expect(
          WebviewChallengeSolver.headlessTimeoutFor(
              const Duration(seconds: 5)),
          const Duration(seconds: 5));
    });

    test('a solve that never finishes times out and is disposed', () async {
      final fake = _FakeSession((_) => Completer<String?>().future);

      final result = await WebviewChallengeSolver.runHeadlessSession(
          fake.session, const Duration(milliseconds: 50));

      expect(result, isNull);
      expect(fake.disposeCalls, 1);
      expect(fake.cancelled!(), isTrue,
          reason: 'the poll loop must stop once the limit fires');
    });

    test('success disposes the engine', () async {
      final fake = _FakeSession((_) async => _usableHtml);

      final result = await WebviewChallengeSolver.runHeadlessSession(
          fake.session, const Duration(seconds: 5));

      expect(result, _usableHtml);
      expect(fake.disposeCalls, 1);
    });

    test('a failed (null) solve disposes the engine', () async {
      final fake = _FakeSession((_) async => null);

      final result = await WebviewChallengeSolver.runHeadlessSession(
          fake.session, const Duration(seconds: 5));

      expect(result, isNull);
      expect(fake.disposeCalls, 1);
    });

    test('an exception disposes the engine and returns null', () async {
      final fake = _FakeSession((_) async => throw StateError('boom'));

      final result = await WebviewChallengeSolver.runHeadlessSession(
          fake.session, const Duration(seconds: 5));

      expect(result, isNull);
      expect(fake.disposeCalls, 1);
    });

    test('a dispose that hangs does not block the caller', () async {
      final HeadlessSolveSession session = (
        solve: (_) async => null,
        dispose: () => Completer<void>().future,
      );

      final result = await WebviewChallengeSolver.runHeadlessSession(
          session, const Duration(seconds: 5),
          disposeWait: const Duration(milliseconds: 50));

      expect(result, isNull);
    });

    test('a timed-out headless solve falls back to the visible solver',
        () async {
      ChallengeHtmlCache.clear();
      final fake = _FakeSession((_) => Completer<String?>().future);
      Duration? limitSeen;
      var fallbackCalls = 0;
      WebviewChallengeSolver.overrideIsMobile = true;
      WebviewChallengeSolver.headlessSessionFactory = (url, limit) {
        limitSeen = limit;
        return fake.session;
      };
      WebviewChallengeSolver.visibleSolverFallback = (url) async {
        fallbackCalls++;
        expect(fake.disposeCalls, 1,
            reason: 'the hidden webview is gone before the visible one');
        return _usableHtml;
      };
      addTearDown(() {
        WebviewChallengeSolver.overrideIsMobile = null;
        WebviewChallengeSolver.headlessSessionFactory = null;
        WebviewChallengeSolver.visibleSolverFallback = null;
      });

      const url = 'https://annas-archive.pk/limit';
      final html = await WebviewChallengeSolver.fetchHtmlAfterChallenge(url,
          timeout: const Duration(milliseconds: 50));

      expect(limitSeen, const Duration(milliseconds: 50));
      expect(fallbackCalls, 1);
      expect(html, _usableHtml);
      expect(ChallengeHtmlCache.get(url), _usableHtml);
    });

    test('the default mobile solve uses the hard limit, not 60 s', () async {
      Duration? limitSeen;
      WebviewChallengeSolver.overrideIsMobile = true;
      WebviewChallengeSolver.headlessSessionFactory = (url, limit) {
        limitSeen = limit;
        return (solve: (_) async => _usableHtml, dispose: () async {});
      };
      addTearDown(() {
        WebviewChallengeSolver.overrideIsMobile = null;
        WebviewChallengeSolver.headlessSessionFactory = null;
      });

      await WebviewChallengeSolver.fetchHtmlAfterChallenge(
          'https://annas-archive.pk/default-limit');

      expect(limitSeen, WebviewChallengeSolver.headlessSolveLimit);
    });
  });

  group('E-ink poll interval', () {
    tearDown(() => EinkProgress.enabled = false);

    test('keeps the normal cadence when E-ink mode is off', () {
      expect(
          WebviewChallengeSolver.pollIntervalFor(const Duration(seconds: 2),
              eink: false),
          const Duration(seconds: 2));
      expect(
          WebviewChallengeSolver.pollIntervalFor(const Duration(seconds: 3),
              eink: false),
          const Duration(seconds: 3));
    });

    test('slows down to the E-ink interval when E-ink mode is on', () {
      expect(
          WebviewChallengeSolver.pollIntervalFor(const Duration(seconds: 2),
              eink: true),
          WebviewChallengeSolver.einkPollInterval);
      expect(WebviewChallengeSolver.einkPollInterval,
          const Duration(seconds: 5));
    });

    test('never speeds up an interval that is already slower', () {
      expect(
          WebviewChallengeSolver.pollIntervalFor(const Duration(seconds: 10),
              eink: true),
          const Duration(seconds: 10));
    });

    test('defaults to the EinkProgress mirror of the setting', () {
      EinkProgress.enabled = false;
      expect(WebviewChallengeSolver.pollIntervalFor(const Duration(seconds: 3)),
          const Duration(seconds: 3));
      EinkProgress.enabled = true;
      expect(WebviewChallengeSolver.pollIntervalFor(const Duration(seconds: 3)),
          WebviewChallengeSolver.einkPollInterval);
    });
  });
}
