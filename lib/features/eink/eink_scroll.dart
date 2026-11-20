// E-ink module: scroll physics. See README.md in this folder.

// Flutter imports:
import 'package:flutter/widgets.dart';

/// Scroll physics for e-ink: the content follows the finger and stops
/// the moment it lifts. No fling momentum (every in-between frame is a
/// ghosting partial refresh) and no bounce past the edges.
class EinkScrollPhysics extends ClampingScrollPhysics {
  const EinkScrollPhysics({super.parent});

  @override
  EinkScrollPhysics applyTo(ScrollPhysics? ancestor) =>
      EinkScrollPhysics(parent: buildParent(ancestor));

  @override
  Simulation? createBallisticSimulation(
    ScrollMetrics position,
    double velocity,
  ) {
    // Still settle back inside the bounds if something left the
    // position out of range; otherwise stop dead.
    if (position.outOfRange) {
      return super.createBallisticSimulation(position, 0);
    }
    return null;
  }
}

