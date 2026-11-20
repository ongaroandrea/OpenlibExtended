// E-ink module: download progress repaint throttle. Pure Dart so the
// download service can use it without pulling in Flutter widgets. See
// README.md in this folder.

/// Minimum gap between two in-app progress repaints for one download.
/// A repaint per network chunk keeps the downloads panel redrawing many
/// times a second: wasted work everywhere, constant flicker on e-ink.
const progressUiInterval = Duration(milliseconds: 250);

/// E-ink panels need ~0.5 s per clean redraw and ghost on fast updates.
const progressUiIntervalEink = Duration(seconds: 2);

/// Non-widget mirror of the E-ink mode setting, for services.
class EinkProgress {
  EinkProgress._();

  /// Set by loadEinkMode / setEinkMode.
  static bool enabled = false;

  /// Tests that react to individual chunks switch the throttle off.
  static bool throttle = true;
}

/// Whether a download's progress should be pushed to the UI now.
/// Always true for the first update ([lastEmit] null) and on completion.
bool shouldEmitProgressUi({
  required DateTime? lastEmit,
  required DateTime now,
  required double progress,
  bool? eink,
}) {
  if (!EinkProgress.throttle) return true;
  if (lastEmit == null || progress >= 1) return true;
  final interval = (eink ?? EinkProgress.enabled)
      ? progressUiIntervalEink
      : progressUiInterval;
  return now.difference(lastEmit) >= interval;
}
