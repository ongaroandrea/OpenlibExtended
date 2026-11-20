// E-ink module: monochrome palette and colour helpers. See README.md in
// this folder.

// Flutter imports:
import 'package:flutter/material.dart';

/// Colours the e-ink theme needs beyond [ColorScheme], attached to the
/// theme by `einkTheme()`.
///
/// Widgets read it with [EinkColors.of]. Without E-ink mode the theme has
/// no extension and [EinkColors.of] returns [EinkColors.standard], whose
/// helpers hand every colour back unchanged, so the normal look is kept.
@immutable
class EinkColors extends ThemeExtension<EinkColors> {
  const EinkColors({
    required this.monochrome,
    required this.foreground,
    required this.background,
    required this.muted,
    required this.track,
    required this.outline,
  });

  /// Pure black on white (light) or white on black (dark).
  factory EinkColors.monochrome(Brightness brightness) {
    final light = brightness == Brightness.light;
    final fg = light ? Colors.black : Colors.white;
    return EinkColors(
      monochrome: true,
      foreground: fg,
      background: light ? Colors.white : Colors.black,
      muted: light ? const Color(0xFF333333) : const Color(0xFFCCCCCC),
      track: light ? const Color(0xFFA0A0A0) : const Color(0xFF606060),
      outline: BorderSide(color: fg, width: 1.5),
    );
  }

  /// Used when E-ink mode is off: no borders, nothing replaced.
  static const standard = EinkColors(
    monochrome: false,
    foreground: Colors.black,
    background: Colors.white,
    muted: Colors.grey,
    track: Colors.transparent,
    outline: BorderSide.none,
  );

  /// True while the e-ink theme is active.
  final bool monochrome;

  /// Text, icons, borders and status colours.
  final Color foreground;

  /// Page and card background.
  final Color background;

  /// Secondary text such as hints; still dark enough for e-paper.
  final Color muted;

  /// Unfilled part of a determinate progress bar.
  final Color track;

  /// Border that replaces a fill as the edge of a card, input or badge.
  /// [BorderSide.none] when E-ink mode is off.
  final BorderSide outline;

  /// [outline] as a box border, or null when there is none.
  Border? get border =>
      outline == BorderSide.none ? null : Border.fromBorderSide(outline);

  static EinkColors of(BuildContext context) =>
      Theme.of(context).extension<EinkColors>() ?? standard;

  @override
  EinkColors copyWith({
    bool? monochrome,
    Color? foreground,
    Color? background,
    Color? muted,
    Color? track,
    BorderSide? outline,
  }) =>
      EinkColors(
        monochrome: monochrome ?? this.monochrome,
        foreground: foreground ?? this.foreground,
        background: background ?? this.background,
        muted: muted ?? this.muted,
        track: track ?? this.track,
        outline: outline ?? this.outline,
      );

  // Theme switches are instant in E-ink mode, so no interpolation.
  @override
  EinkColors lerp(covariant EinkColors? other, double t) =>
      t < 0.5 || other == null ? this : other;
}

/// Colour helpers that are a no-op unless the e-ink theme is active.
extension EinkColorX on Color {
  /// For text and meaningful fills: [opacity] normally, fully opaque in
  /// E-ink mode (half-transparent colours turn into faint greys there).
  Color einkText(BuildContext context, double opacity) =>
      EinkColors.of(context).monochrome ? this : withValues(alpha: opacity);

  /// For decorative tints behind content: [opacity] normally, [mono]
  /// (transparent by default) in E-ink mode.
  Color einkTint(BuildContext context, double opacity, {Color? mono}) =>
      EinkColors.of(context).monochrome
          ? (mono ?? Colors.transparent)
          : withValues(alpha: opacity);

  /// For status and accent colours (green, red, orange...): unchanged
  /// normally, the theme's foreground in E-ink mode. Pair it with an icon
  /// or label so the state survives greyscale.
  Color einkFg(BuildContext context) {
    final colors = EinkColors.of(context);
    return colors.monochrome ? colors.foreground : this;
  }

  /// For decorative fills and text drawn on top of an accent (white on
  /// red): unchanged normally, the theme's background in E-ink mode.
  Color einkBg(BuildContext context) {
    final colors = EinkColors.of(context);
    return colors.monochrome ? colors.background : this;
  }
}
