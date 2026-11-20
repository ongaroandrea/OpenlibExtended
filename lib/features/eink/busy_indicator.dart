// E-ink module: loading indicators that hold still. See README.md in
// this folder.

// Flutter imports:
import 'package:flutter/material.dart';

/// Loading indicator that turns into a static hourglass when animations
/// are disabled - by E-ink mode or the system "Remove animations"
/// setting - so it never forces a stream of partial refreshes.
///
/// Use only for indeterminate progress; a determinate indicator with a
/// `value` is already static between updates.
class BusyIndicator extends StatelessWidget {
  final double? size;
  final double strokeWidth;
  final Color? color;
  final StrokeCap? strokeCap;

  const BusyIndicator({
    super.key,
    this.size,
    this.strokeWidth = 4.0,
    this.color,
    this.strokeCap,
  });

  @override
  Widget build(BuildContext context) {
    if (MediaQuery.maybeDisableAnimationsOf(context) ?? false) {
      final iconColor = color ?? Theme.of(context).colorScheme.tertiary;
      if (size != null) {
        return Icon(Icons.hourglass_empty, size: size, color: iconColor);
      }
      // Callers usually wrap the spinner in a fixed SizedBox; fill it.
      return LayoutBuilder(
        builder: (context, constraints) {
          final bounded =
              constraints.hasBoundedWidth && constraints.hasBoundedHeight;
          final fit = bounded
              ? constraints.biggest.shortestSide
              : constraints.hasBoundedWidth
              ? constraints.maxWidth
              : constraints.hasBoundedHeight
              ? constraints.maxHeight
              : 24.0;
          return Icon(
            Icons.hourglass_empty,
            size: fit.clamp(12.0, 40.0),
            color: iconColor,
          );
        },
      );
    }
    final spinner = CircularProgressIndicator(
      strokeWidth: strokeWidth,
      color: color,
      strokeCap: strokeCap,
    );
    return size == null
        ? spinner
        : SizedBox(width: size, height: size, child: spinner);
  }
}

/// Indeterminate linear bar that shows only its static track when
/// animations are disabled.
class BusyBar extends StatelessWidget {
  final double? minHeight;
  final Color? backgroundColor;
  final Color? color;

  const BusyBar({super.key, this.minHeight, this.backgroundColor, this.color});

  @override
  Widget build(BuildContext context) {
    final still = MediaQuery.maybeDisableAnimationsOf(context) ?? false;
    return LinearProgressIndicator(
      value: still ? 0 : null,
      minHeight: minHeight,
      backgroundColor: backgroundColor,
      color: color,
    );
  }
}
