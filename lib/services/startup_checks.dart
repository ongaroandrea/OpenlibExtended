// Project imports:
import 'package:openlib/services/preference_store.dart';

/// How often the app may refresh the open-slum.org mirror list on its own.
const Duration mirrorRefreshInterval = Duration(hours: 24);

/// How often the app may check GitHub for an update on its own.
const Duration updateCheckInterval = Duration(hours: 24);

/// Preference key: last successful mirror refresh, ms since epoch.
const String lastMirrorRefreshKey = 'last_mirror_refresh_ms';

/// Preference key: last successful update check, ms since epoch.
const String lastUpdateCheckKey = 'last_update_check_ms';

/// Whether a periodic background check is due.
///
/// Due when it never succeeded ([last] is null), when [every] has passed
/// since [last], or when [last] lies in the future (the clock moved back;
/// running once is better than staying silent until the clock catches up).
bool isDue(DateTime? last, DateTime now, Duration every) {
  if (last == null) return true;
  if (last.isAfter(now)) return true;
  return now.difference(last) >= every;
}

/// Startup rule for the mirror list: refresh when it is due, and always
/// when there is no cached list at all (first run, wiped cache) - the app
/// cannot search without one.
bool shouldRefreshMirrors({
  required bool hasCachedMirrors,
  required DateTime? last,
  required DateTime now,
  Duration every = mirrorRefreshInterval,
}) =>
    !hasCachedMirrors || isDue(last, now, every);

/// A last-success timestamp kept in a [PreferenceStore].
///
/// Automatic (startup) work asks [isDueNow] before touching the network;
/// both automatic and manual paths call [recordSuccess] only after the
/// work actually succeeded, so an offline launch retries on the next one.
class ThrottledCheck {
  ThrottledCheck({
    required this.key,
    required this.every,
    PreferenceStore? store,
    DateTime Function()? clock,
  })  : _store = store,
        _clock = clock ?? DateTime.now;

  final String key;
  final Duration every;
  final PreferenceStore? _store;
  final DateTime Function() _clock;

  /// The current time on this check's clock.
  DateTime now() => _clock();

  Future<DateTime?> lastSuccess() async {
    try {
      final raw = await _store?.read(key);
      final ms = raw is int ? raw : int.tryParse('${raw ?? ''}');
      if (ms == null || ms <= 0) return null;
      return DateTime.fromMillisecondsSinceEpoch(ms);
    } catch (_) {
      return null;
    }
  }

  Future<bool> isDueNow() async => isDue(await lastSuccess(), _clock(), every);

  Future<void> recordSuccess() async {
    try {
      await _store?.write(key, _clock().millisecondsSinceEpoch);
    } catch (_) {
      // Best-effort: a lost timestamp only means one extra check.
    }
  }

  /// Runs [action] when due (or when [force] is set) and records the
  /// timestamp when it reports success. Returns true only when [action]
  /// ran and succeeded; a throwing action counts as a failure.
  Future<bool> runIfDue(Future<bool> Function() action,
      {bool force = false}) async {
    if (!force && !await isDueNow()) return false;
    bool ok;
    try {
      ok = await action();
    } catch (_) {
      ok = false;
    }
    if (ok) await recordSuccess();
    return ok;
  }
}
