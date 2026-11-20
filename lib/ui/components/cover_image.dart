import 'package:flutter/material.dart';

import 'package:openlib/features/eink/eink_palette.dart' show EinkColors;

/// Decode sizes are rounded up to this step so covers shown at nearly
/// the same size share one cache entry.
const int coverDecodeStep = 50;

/// Pixel width to decode a cover at, for a box [logicalWidth] wide on a
/// screen with [devicePixelRatio]. Rounded up to a multiple of
/// [coverDecodeStep]. Only the width is capped so the aspect ratio of
/// the decoded image is kept.
int coverDecodeWidth(double logicalWidth, double devicePixelRatio) {
  final px = (logicalWidth * devicePixelRatio).ceil();
  if (px <= 0) return coverDecodeStep;
  return ((px + coverDecodeStep - 1) ~/ coverDecodeStep) * coverDecodeStep;
}

/// [coverDecodeWidth] using the device pixel ratio of [context].
int coverCacheWidth(BuildContext context, double logicalWidth) =>
    coverDecodeWidth(logicalWidth, MediaQuery.devicePixelRatioOf(context));

/// Fill for a cover's loading and error tile.
///
/// [light] in the light theme, a neutral theme surface in the dark theme
/// (a light tile flashes bright on black), and the page background in
/// E-ink mode, where the e-ink theme maps every surface to it.
Color coverPlaceholderColor(BuildContext context, Color light) {
  final eink = EinkColors.of(context);
  if (eink.monochrome) return eink.background;
  final theme = Theme.of(context);
  if (theme.brightness == Brightness.light) return light;
  return theme.colorScheme.surfaceContainerHighest;
}
