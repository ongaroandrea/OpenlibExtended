// E-ink module: hardware page-turn keys for the built-in readers -
// keyboard / page-turner keys, and (Android) the volume keys forwarded by
// MainActivity. See README.md in this folder.

// Flutter imports:
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

// Package imports:
import 'package:flutter_riverpod/flutter_riverpod.dart';

// Project imports:
import 'package:openlib/features/eink/eink_mode.dart';
import 'package:openlib/services/database.dart' show MyLibraryDb;

/// Which way a page turn goes.
enum PageTurn { next, previous }

/// The page turn a key press means, or null for any other key.
///
/// PageDown / ArrowRight / ArrowDown / Space go forward; PageUp /
/// ArrowLeft / ArrowUp / Shift+Space go back. E-readers send PAGE_UP and
/// PAGE_DOWN for their page buttons, Bluetooth page turners send arrows or
/// PageUp/PageDown.
PageTurn? pageTurnForKey(LogicalKeyboardKey key, {bool shift = false}) {
  if (key == LogicalKeyboardKey.pageDown ||
      key == LogicalKeyboardKey.arrowRight ||
      key == LogicalKeyboardKey.arrowDown) {
    return PageTurn.next;
  }
  if (key == LogicalKeyboardKey.pageUp ||
      key == LogicalKeyboardKey.arrowLeft ||
      key == LogicalKeyboardKey.arrowUp) {
    return PageTurn.previous;
  }
  if (key == LogicalKeyboardKey.space) {
    return shift ? PageTurn.previous : PageTurn.next;
  }
  return null;
}

/// Turns pages from the keyboard, and from the volume keys while
/// [volumeKeys] is true. Wrap a reader's body in it; it takes focus so the
/// keys work without tapping first.
class PageTurnKeys extends StatefulWidget {
  const PageTurnKeys({
    super.key,
    required this.onTurn,
    required this.child,
    this.volumeKeys = false,
    this.focusNode,
    this.autofocus = true,
  });

  final ValueChanged<PageTurn> onTurn;
  final bool volumeKeys;
  final FocusNode? focusNode;
  final bool autofocus;
  final Widget child;

  @override
  State<PageTurnKeys> createState() => _PageTurnKeysState();
}

class _PageTurnKeysState extends State<PageTurnKeys> {
  @override
  void initState() {
    super.initState();
    if (widget.volumeKeys) VolumeKeyPaging.attach(_onVolumeTurn);
  }

  @override
  void didUpdateWidget(PageTurnKeys oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.volumeKeys != oldWidget.volumeKeys) {
      widget.volumeKeys
          ? VolumeKeyPaging.attach(_onVolumeTurn)
          : VolumeKeyPaging.detach(_onVolumeTurn);
    }
  }

  @override
  void dispose() {
    VolumeKeyPaging.detach(_onVolumeTurn);
    super.dispose();
  }

  void _onVolumeTurn(PageTurn turn) => widget.onTurn(turn);

  KeyEventResult _onKeyEvent(FocusNode node, KeyEvent event) {
    if (event is KeyUpEvent) return KeyEventResult.ignored;
    final turn = pageTurnForKey(event.logicalKey,
        shift: HardwareKeyboard.instance.isShiftPressed);
    if (turn == null) return KeyEventResult.ignored;
    widget.onTurn(turn);
    return KeyEventResult.handled;
  }

  @override
  Widget build(BuildContext context) {
    return Focus(
      focusNode: widget.focusNode,
      autofocus: widget.autofocus,
      onKeyEvent: _onKeyEvent,
      child: widget.child,
    );
  }
}

/// Volume keys as page keys (Android only). While at least one handler is
/// attached, MainActivity swallows VOLUME_UP / VOLUME_DOWN and sends them
/// here instead of changing the volume; with none attached, the volume keys
/// work as usual. Volume down = next page, volume up = previous page.
class VolumeKeyPaging {
  VolumeKeyPaging._();

  static const channel = MethodChannel('openlib/page_keys');

  static final List<ValueChanged<PageTurn>> _handlers = [];
  static bool _listening = false;

  /// Starts sending volume key presses to [handler]. The most recently
  /// attached handler gets them.
  static void attach(ValueChanged<PageTurn> handler) {
    if (!_listening) {
      channel.setMethodCallHandler(_onCall);
      _listening = true;
    }
    _handlers.remove(handler);
    _handlers.add(handler);
    _sync();
  }

  /// Stops sending volume keys to [handler]; with no handlers left the
  /// volume keys change the volume again.
  static void detach(ValueChanged<PageTurn> handler) {
    if (!_handlers.remove(handler)) return;
    _sync();
  }

  @visibleForTesting
  static bool get active => _handlers.isNotEmpty;

  static Future<void> _onCall(MethodCall call) async {
    if (call.method != 'pageKey' || _handlers.isEmpty) return;
    final turn = call.arguments == 'previous' ? PageTurn.previous : PageTurn.next;
    _handlers.last(turn);
  }

  static Future<void> _sync() async {
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) return;
    try {
      await channel.invokeMethod('setVolumeKeyPaging', _handlers.isNotEmpty);
    } catch (_) {
      // No activity handler (tests, other embedders): keys stay normal.
    }
  }
}

/// Preference key for "Volume keys turn pages"; 1 on, 0 off, missing =
/// never chosen (then it follows E-ink mode).
const volumeKeyPagingPreferenceKey = 'volumeKeyPaging';

/// The user's saved choice for volume key paging, or null if never chosen.
final volumeKeyPagingChoiceProvider =
    StateNotifierProvider<VolumeKeyPagingChoice, bool?>(
        (ref) => VolumeKeyPagingChoice(MyLibraryDb.instance));

/// Whether the volume keys turn pages: the user's choice, else on exactly
/// when E-ink mode is on.
final volumeKeyPagingProvider = Provider<bool>((ref) =>
    ref.watch(volumeKeyPagingChoiceProvider) ?? ref.watch(einkModeProvider));

class VolumeKeyPagingChoice extends StateNotifier<bool?> {
  VolumeKeyPagingChoice(this._db) : super(null) {
    _load();
  }

  final MyLibraryDb _db;
  bool _chosen = false;

  Future<void> _load() async {
    Object? saved;
    try {
      saved = await _db.getPreference(volumeKeyPagingPreferenceKey);
    } catch (_) {
      return;
    }
    // A choice made while loading wins over the stored value.
    if (!mounted || _chosen || saved is! num) return;
    state = saved != 0;
  }

  /// Saves the user's choice.
  Future<void> set(bool enabled) async {
    _chosen = true;
    state = enabled;
    try {
      await _db.savePreference(volumeKeyPagingPreferenceKey, enabled ? 1 : 0);
    } catch (_) {
      // The switch still applies for this session.
    }
  }
}
