// E-ink module: the setting itself - provider, persistence and device
// detection. See README.md in this folder.

// Dart imports:
import 'dart:io' show Platform;

// Flutter imports:
import 'package:flutter/widgets.dart';

// Package imports:
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// Project imports:
import 'package:openlib/features/eink/progress_throttle.dart';
import 'package:openlib/services/database.dart' show MyLibraryDb;

/// Preference key; stored as 1 (on) or 0 (off). Missing = never chosen.
const einkModePreferenceKey = 'einkMode';

/// Whether E-ink mode is on. The app overrides it at startup with the
/// value from [loadEinkMode].
final einkModeProvider = StateProvider<bool>((ref) => false);

/// Lowercased manufacturer/brand substrings of Android devices that ship
/// with an e-ink panel. Used only to pick the default for the toggle;
/// the user's own choice always wins once saved.
const einkManufacturerHints = <String>[
  'onyx',
  'boox',
  'bigme',
  'meebook',
  'boyue',
  'likebook',
  'pocketbook',
  'mudita',
  'hyread',
];

/// True when [manufacturer] or [brand] names a known e-ink device maker.
bool looksLikeEinkDevice({String? manufacturer, String? brand}) {
  final values = [manufacturer, brand]
      .whereType<String>()
      .map((v) => v.toLowerCase());
  return values.any((v) => einkManufacturerHints.any(v.contains));
}

/// Startup value: the saved choice if there is one, otherwise on for
/// known e-ink Android devices. Also primes the non-widget side
/// ([EinkProgress.enabled]).
Future<bool> loadEinkMode(MyLibraryDb dataBase) async {
  final saved = await dataBase
      .getPreference(einkModePreferenceKey)
      .catchError((e) => null);
  final enabled = saved is num ? saved != 0 : await _detectEinkDevice();
  EinkProgress.enabled = enabled;
  return enabled;
}

/// Turns E-ink mode on or off from the UI and saves the choice.
void setEinkMode(WidgetRef ref, MyLibraryDb dataBase, bool enabled) {
  ref.read(einkModeProvider.notifier).state = enabled;
  EinkProgress.enabled = enabled;
  dataBase.savePreference(einkModePreferenceKey, enabled ? 1 : 0);
}

/// Reports "animations off" while E-ink mode is on, so every widget that
/// honours the system setting (BusyIndicator, the nav bar) goes still.
MediaQueryData applyEinkMediaQuery(MediaQueryData data, bool eink) =>
    eink ? data.copyWith(disableAnimations: true) : data;

Future<bool> _detectEinkDevice() async {
  if (!Platform.isAndroid) return false;
  try {
    final info = await DeviceInfoPlugin().androidInfo;
    return looksLikeEinkDevice(
        manufacturer: info.manufacturer, brand: info.brand);
  } catch (_) {
    return false;
  }
}
