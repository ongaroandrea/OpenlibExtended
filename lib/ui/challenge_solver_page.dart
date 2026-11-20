// Full-screen fallback page shown when the automatic headless challenge
// solver could not clear DDoS-Guard on its own (e.g. a real human CAPTCHA).
// The page loads the blocked URL in a visible InAppWebView, waits until the
// challenge is gone and the page has fully rendered, stores the captured HTML
// in ChallengeHtmlCache (keyed by request URL) and pops itself. The caller then
// simply retries - the cached HTML is used instead of a doomed Dio request.

// Flutter imports:
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:openlib/l10n/app_localizations.dart';

// Package imports:
import 'package:flutter_inappwebview/flutter_inappwebview.dart';

// Project imports:
import 'package:openlib/services/challenge_html_cache.dart';
import 'package:openlib/services/logger.dart';
import 'package:openlib/services/webview_challenge_solver.dart';

class ChallengeSolverPage extends StatefulWidget {
  const ChallengeSolverPage({super.key, required this.url});

  final String url;

  /// Poll cadence normally; E-ink mode slows it down (see
  /// WebviewChallengeSolver.pollIntervalFor).
  static const Duration pollInterval = Duration(seconds: 2);

  /// Overall cap: after this long without a solved page the polling stops
  /// and the page pops with `false`, so callers show their existing error
  /// and retry UI instead of a visible webview polling forever.
  static const Duration giveUpAfter = Duration(minutes: 5);

  @override
  State<ChallengeSolverPage> createState() => _ChallengeSolverPageState();
}

class _ChallengeSolverPageState extends State<ChallengeSolverPage> {
  final AppLogger _logger = AppLogger();
  InAppWebViewController? _controller;
  Timer? _pollTimer;
  Timer? _giveUpTimer;
  bool _done = false;
  // A tick can outlast the interval (JS calls + 2 s settle); never run two
  // at once - that doubled the webview work and could pop twice.
  bool _polling = false;

  @override
  void dispose() {
    _pollTimer?.cancel();
    _giveUpTimer?.cancel();
    super.dispose();
  }

  void _giveUp() {
    if (_done || !mounted) return;
    _done = true;
    _pollTimer?.cancel();
    _logger.warning('Solver page gave up without a solved page',
        tag: 'ChallengeSolver', metadata: {'url': widget.url});
    Navigator.pop(context, false);
  }

  void _startPolling() {
    _pollTimer?.cancel();
    _giveUpTimer ??= Timer(ChallengeSolverPage.giveUpAfter, _giveUp);
    _pollTimer = Timer.periodic(
        WebviewChallengeSolver.pollIntervalFor(
            ChallengeSolverPage.pollInterval), (timer) async {
      if (_done || !mounted) {
        timer.cancel();
        return;
      }
      final controller = _controller;
      if (controller == null || _polling) return;

      _polling = true;
      try {
        final title = (await controller.getTitle()) ?? '';
        final bodySnippet = (await controller.evaluateJavascript(
                source:
                    "document.body ? document.body.innerHTML.slice(0, 3000) : ''"))
            ?.toString() ?? '';

        if (title.isEmpty && bodySnippet.isEmpty) return;

        if (WebviewChallengeSolver.isChallengePage(
            title: title, bodySnippet: bodySnippet)) {
          _logger.debug('Challenge still active (solver page)',
              tag: 'ChallengeSolver', metadata: {'title': title});
          return;
        }

        final ready =
            (await controller.evaluateJavascript(source: "document.readyState"))
                ?.toString() ?? '';
        if (ready != 'complete') return;

        // Settle so late XHR content lands in the DOM.
        await Future.delayed(const Duration(milliseconds: 2000));
        if (_done || !mounted) return;

        final html = (await controller.evaluateJavascript(
                source: "document.documentElement.outerHTML"))
            ?.toString() ?? '';
        if (_done || !mounted) return;
        if (html.isNotEmpty) {
          _done = true;
          ChallengeHtmlCache.store(widget.url, html);
          _logger.info('Solver page captured HTML',
              tag: 'ChallengeSolver',
              metadata: {'url': widget.url, 'length': html.length});
          _pollTimer?.cancel();
          _giveUpTimer?.cancel();
          if (mounted) Navigator.pop(context, true);
        }
      } catch (_) {
        // webview might be mid-navigation; keep polling
      } finally {
        _polling = false;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context).verifyingAccess)),
      body: SafeArea(
        child: InAppWebView(
          initialUrlRequest: URLRequest(url: WebUri(widget.url)),
          initialSettings: InAppWebViewSettings(
            javaScriptEnabled: true,
            supportZoom: false,
          ),
          onWebViewCreated: (controller) {
            _controller = controller;
            _startPolling();
          },
        ),
      ),
    );
  }
}
