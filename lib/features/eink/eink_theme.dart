// E-ink module: theme overrides. See README.md in this folder.

// Flutter imports:
import 'package:flutter/material.dart';

// Project imports:
import 'package:openlib/features/eink/eink_palette.dart';

/// Returns [base] with every route transition and ink splash removed, and
/// every colour turned into pure black and white: black on white for a
/// light [base], white on black for a dark one. Fills that used to mark the
/// edge of a card, input or chip become borders; shadows and elevation go.
/// Attaches [EinkColors] for the widgets that need more than [ColorScheme].
ThemeData einkTheme(ThemeData base) {
  const noTransitions = _NoTransitionsBuilder();
  final palette = EinkColors.monochrome(base.brightness);
  final fg = palette.foreground;
  final bg = palette.background;
  final side = palette.outline;
  final thick = side.copyWith(width: 2.5);
  final radius8 = BorderRadius.circular(8);
  final radius12 = BorderRadius.circular(12);

  final scheme = base.colorScheme.copyWith(
    // The light base theme has a white `primary` on a white surface, so
    // stock widgets that default to it (Switch, Slider, spinners, dialog
    // TextButtons, RefreshIndicator) would vanish. Make it a real pair.
    primary: fg,
    onPrimary: bg,
    inversePrimary: bg,
    secondary: fg,
    onSecondary: bg,
    secondaryContainer: bg,
    onSecondaryContainer: fg,
    primaryContainer: bg,
    onPrimaryContainer: fg,
    tertiary: fg,
    onTertiary: bg,
    tertiaryContainer: bg,
    onTertiaryContainer: fg,
    error: fg,
    onError: bg,
    errorContainer: bg,
    onErrorContainer: fg,
    surface: bg,
    onSurface: fg,
    onSurfaceVariant: fg,
    surfaceDim: bg,
    surfaceBright: bg,
    surfaceContainerLowest: bg,
    surfaceContainerLow: bg,
    surfaceContainer: bg,
    surfaceContainerHigh: bg,
    surfaceContainerHighest: bg,
    surfaceTint: Colors.transparent,
    outline: fg,
    outlineVariant: fg,
    shadow: Colors.transparent,
    inverseSurface: fg,
    onInverseSurface: bg,
  );

  final textTheme = base.textTheme.apply(bodyColor: fg, displayColor: fg);
  final selected = WidgetStateProperty.resolveWith<Color>(
    (states) => states.contains(WidgetState.selected) ? fg : bg,
  );
  final selectedInverse = WidgetStateProperty.resolveWith<Color>(
    (states) => states.contains(WidgetState.selected) ? bg : fg,
  );
  final inputBorder = OutlineInputBorder(borderSide: side, borderRadius: radius8);

  return base.copyWith(
    pageTransitionsTheme: const PageTransitionsTheme(
      builders: {
        TargetPlatform.android: noTransitions,
        TargetPlatform.iOS: noTransitions,
        TargetPlatform.macOS: noTransitions,
        TargetPlatform.windows: noTransitions,
        TargetPlatform.linux: noTransitions,
        TargetPlatform.fuchsia: noTransitions,
      },
    ),
    splashFactory: NoSplash.splashFactory,
    colorScheme: scheme,
    scaffoldBackgroundColor: bg,
    canvasColor: bg,
    cardColor: bg,
    dividerColor: fg,
    shadowColor: Colors.transparent,
    hintColor: palette.muted,
    disabledColor: palette.muted,
    unselectedWidgetColor: fg,
    highlightColor: Colors.transparent,
    splashColor: Colors.transparent,
    hoverColor: Colors.transparent,
    textTheme: textTheme,
    primaryTextTheme:
        base.primaryTextTheme.apply(bodyColor: fg, displayColor: fg),
    iconTheme: base.iconTheme.copyWith(color: fg),
    textSelectionTheme: TextSelectionThemeData(
      cursorColor: fg,
      selectionColor: palette.track,
      selectionHandleColor: fg,
    ),
    appBarTheme: base.appBarTheme.copyWith(
      backgroundColor: bg,
      foregroundColor: fg,
      elevation: 0,
      scrolledUnderElevation: 0,
      shadowColor: Colors.transparent,
      surfaceTintColor: Colors.transparent,
    ),
    cardTheme: CardThemeData(
      color: bg,
      elevation: 0,
      shadowColor: Colors.transparent,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: radius12, side: side),
    ),
    inputDecorationTheme: base.inputDecorationTheme.copyWith(
      filled: true,
      fillColor: bg,
      labelStyle: TextStyle(color: fg),
      floatingLabelStyle: TextStyle(color: fg),
      hintStyle: TextStyle(color: palette.muted),
      prefixIconColor: fg,
      suffixIconColor: fg,
      border: inputBorder,
      enabledBorder: inputBorder,
      focusedBorder: inputBorder.copyWith(borderSide: thick),
      errorBorder: inputBorder.copyWith(borderSide: thick),
      focusedErrorBorder: inputBorder.copyWith(borderSide: thick),
    ),
    chipTheme: ChipThemeData(
      backgroundColor: bg,
      selectedColor: bg,
      disabledColor: bg,
      checkmarkColor: fg,
      deleteIconColor: fg,
      labelStyle: TextStyle(color: fg),
      secondaryLabelStyle: TextStyle(color: fg),
      iconTheme: IconThemeData(color: fg),
      side: WidgetStateBorderSide.resolveWith(
        (states) => states.contains(WidgetState.selected) ? thick : side,
      ),
      elevation: 0,
      pressElevation: 0,
      shadowColor: Colors.transparent,
      selectedShadowColor: Colors.transparent,
      surfaceTintColor: Colors.transparent,
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: fg,
        foregroundColor: bg,
        iconColor: bg,
        elevation: 0,
        shadowColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
      ).merge(base.elevatedButtonTheme.style),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: fg,
        foregroundColor: bg,
        iconColor: bg,
        elevation: 0,
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: fg,
        iconColor: fg,
        side: side,
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(foregroundColor: fg, iconColor: fg),
    ),
    floatingActionButtonTheme: FloatingActionButtonThemeData(
      backgroundColor: fg,
      foregroundColor: bg,
      elevation: 0,
      focusElevation: 0,
      hoverElevation: 0,
      highlightElevation: 0,
      disabledElevation: 0,
    ),
    dividerTheme: DividerThemeData(color: fg, thickness: 1),
    listTileTheme: base.listTileTheme.copyWith(textColor: fg, iconColor: fg),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: bg,
      elevation: 0,
      shadowColor: Colors.transparent,
      surfaceTintColor: Colors.transparent,
      indicatorColor: bg,
      indicatorShape: StadiumBorder(side: thick),
      iconTheme: WidgetStatePropertyAll(IconThemeData(color: fg)),
      labelTextStyle: WidgetStatePropertyAll(TextStyle(color: fg)),
    ),
    bottomNavigationBarTheme: BottomNavigationBarThemeData(
      backgroundColor: bg,
      elevation: 0,
      selectedItemColor: fg,
      unselectedItemColor: fg,
    ),
    tabBarTheme: TabBarThemeData(
      labelColor: fg,
      unselectedLabelColor: fg,
      indicatorColor: fg,
      dividerColor: fg,
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: bg,
      surfaceTintColor: Colors.transparent,
      shadowColor: Colors.transparent,
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: radius12, side: thick),
    ),
    bottomSheetTheme: BottomSheetThemeData(
      backgroundColor: bg,
      modalBackgroundColor: bg,
      surfaceTintColor: Colors.transparent,
      shadowColor: Colors.transparent,
      elevation: 0,
      modalElevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
        side: thick,
      ),
    ),
    popupMenuTheme: PopupMenuThemeData(
      color: bg,
      surfaceTintColor: Colors.transparent,
      shadowColor: Colors.transparent,
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: radius8, side: side),
      textStyle: TextStyle(color: fg),
    ),
    snackBarTheme: SnackBarThemeData(
      backgroundColor: fg,
      contentTextStyle: TextStyle(color: bg),
      actionTextColor: bg,
      closeIconColor: bg,
      elevation: 0,
    ),
    tooltipTheme: TooltipThemeData(
      decoration: BoxDecoration(color: fg, borderRadius: radius8),
      textStyle: TextStyle(color: bg),
    ),
    switchTheme: SwitchThemeData(
      thumbColor: selectedInverse,
      trackColor: selected,
      trackOutlineColor: WidgetStatePropertyAll(fg),
    ),
    checkboxTheme: CheckboxThemeData(
      fillColor: WidgetStateProperty.resolveWith(
        (states) => states.contains(WidgetState.selected)
            ? fg
            : Colors.transparent,
      ),
      checkColor: WidgetStatePropertyAll(bg),
      side: side.copyWith(width: 2),
    ),
    radioTheme: RadioThemeData(fillColor: WidgetStatePropertyAll(fg)),
    sliderTheme: base.sliderTheme.copyWith(
      activeTrackColor: fg,
      inactiveTrackColor: palette.track,
      thumbColor: fg,
      overlayColor: Colors.transparent,
      valueIndicatorColor: fg,
    ),
    progressIndicatorTheme: ProgressIndicatorThemeData(
      color: fg,
      linearTrackColor: palette.track,
      circularTrackColor: Colors.transparent,
    ),
    extensions: [
      ...base.extensions.values.where((e) => e is! EinkColors),
      palette,
    ],
  );
}

class _NoTransitionsBuilder extends PageTransitionsBuilder {
  const _NoTransitionsBuilder();

  @override
  Widget buildTransitions<T>(
    PageRoute<T> route,
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) => child;
}
