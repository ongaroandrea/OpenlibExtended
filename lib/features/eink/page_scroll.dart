// E-ink module: page turns for content that scrolls continuously (the
// EPUB reader), and the edge tap zones that trigger them. See README.md in
// this folder.

// Dart imports:
import 'dart:async';

// Flutter imports:
import 'package:flutter/gestures.dart';
import 'package:flutter/widgets.dart';

// Project imports:
import 'package:openlib/features/eink/page_keys.dart' show PageTurn;

/// Share of the viewport that stays on screen after a page turn, so the
/// last lines of the old page are the first of the new one.
const pageTurnOverlap = 0.1;

/// Animation of a page turn when animations are allowed.
const pageTurnDuration = Duration(milliseconds: 250);

/// The first vertical [ScrollPosition] below [context] (depth first, so
/// the outermost one). Used for widgets that keep their scroll controller
/// private, like epub_view's ScrollablePositionedList, whose active list
/// is always built first.
ScrollPosition? findVerticalScrollPosition(BuildContext context) {
  ScrollPosition? found;
  void visit(Element element) {
    if (found != null) return;
    if (element is StatefulElement && element.state is ScrollableState) {
      final state = element.state as ScrollableState;
      if (state.position.hasContentDimensions &&
          state.position.axis == Axis.vertical) {
        found = state.position;
        return;
      }
    }
    element.visitChildElements(visit);
  }

  context.visitChildElements(visit);
  return found;
}

/// Scrolls [position] by one viewport minus [pageTurnOverlap]. Jumps when
/// [animate] is false (E-ink mode / "Remove animations"), so the panel
/// redraws once.
Future<void> scrollByPage(ScrollPosition position, PageTurn turn,
    {required bool animate}) async {
  final step = position.viewportDimension * (1 - pageTurnOverlap);
  final delta = turn == PageTurn.next ? step : -step;
  final target = (position.pixels + delta)
      .clamp(position.minScrollExtent, position.maxScrollExtent);
  if (target == position.pixels) return;
  if (!animate) {
    position.jumpTo(target);
    return;
  }
  await position.animateTo(target,
      duration: pageTurnDuration, curve: Curves.easeInOut);
}

/// Left and right edge tap zones: a tap on the right [edgeFraction] of the
/// width turns to the next page, on the left one to the previous page. The
/// middle is left alone.
///
/// Uses a raw [Listener] rather than a gesture recognizer so it never
/// competes with text selection, links or scrolling underneath: only a
/// short press that barely moves counts, drags and long presses don't.
class PageTapZones extends StatefulWidget {
  const PageTapZones({
    super.key,
    required this.onTurn,
    required this.child,
    this.edgeFraction = 0.3,
  });

  final ValueChanged<PageTurn> onTurn;
  final double edgeFraction;
  final Widget child;

  @override
  State<PageTapZones> createState() => _PageTapZonesState();
}

class _PageTapZonesState extends State<PageTapZones> {
  static const _maxTapDuration = Duration(milliseconds: 400);

  int? _pointer;
  Offset _downPosition = Offset.zero;
  bool _moved = false;
  // Fires when the press has lasted too long to be a tap. A timer rather
  // than event time stamps, which some input sources leave at zero.
  Timer? _tapTimeout;

  @override
  void dispose() {
    _tapTimeout?.cancel();
    super.dispose();
  }

  void _onDown(PointerDownEvent event) {
    // Only the primary button / a single finger; a second finger cancels.
    _tapTimeout?.cancel();
    if (_pointer != null || event.buttons & kPrimaryButton == 0) {
      _pointer = null;
      return;
    }
    _pointer = event.pointer;
    _downPosition = event.localPosition;
    _moved = false;
    _tapTimeout = Timer(_maxTapDuration, () => _pointer = null);
  }

  void _onMove(PointerMoveEvent event) {
    if (event.pointer != _pointer) return;
    if ((event.localPosition - _downPosition).distance > kTouchSlop) {
      _moved = true;
    }
  }

  void _onUp(PointerUpEvent event) {
    if (event.pointer != _pointer) return;
    _pointer = null;
    _tapTimeout?.cancel();
    if (_moved) return;
    final width = (context.findRenderObject() as RenderBox?)?.size.width;
    if (width == null || width <= 0) return;
    final x = event.localPosition.dx;
    if (x >= width * (1 - widget.edgeFraction)) {
      widget.onTurn(PageTurn.next);
    } else if (x <= width * widget.edgeFraction) {
      widget.onTurn(PageTurn.previous);
    }
  }

  void _onCancel(PointerCancelEvent event) {
    if (event.pointer != _pointer) return;
    _pointer = null;
    _tapTimeout?.cancel();
  }

  @override
  Widget build(BuildContext context) {
    return Listener(
      behavior: HitTestBehavior.translucent,
      onPointerDown: _onDown,
      onPointerMove: _onMove,
      onPointerUp: _onUp,
      onPointerCancel: _onCancel,
      child: widget.child,
    );
  }
}
