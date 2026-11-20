import 'package:flutter/material.dart';
import 'package:google_nav_bar/google_nav_bar.dart';
import 'package:openlib/l10n/app_localizations.dart';
import 'package:openlib/features/eink/eink.dart' show EinkColorX;

class AppNavigationBar extends StatelessWidget {
  const AppNavigationBar(
      {super.key, required this.selectedIndex, required this.onSelected});

  final int selectedIndex;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final l10n = AppLocalizations.of(context);
    final duration = MediaQuery.disableAnimationsOf(context)
        ? Duration.zero
        : const Duration(milliseconds: 180);
    final icons = [
      Icons.trending_up,
      Icons.search,
      Icons.collections_bookmark,
      Icons.settings,
    ];
    final labels = [
      l10n.navHome,
      l10n.navSearch,
      l10n.navMyLibrary,
      l10n.navSettings,
    ];

    return SafeArea(
      child: RepaintBoundary(
        child: ColoredBox(
          color: isDark ? const Color(0xFF141414) : Colors.white,
          // GNav-style pills, icon only. GNav's container blocks every tap
          // until an animation ends; direct GButtons stay responsive. The row
          // keeps its natural size when it fits and scales down as a whole
          // on narrow screens.
          child: Center(
            heightFactor: 1,
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  for (var i = 0; i < icons.length; i++)
                    GButton(
                      active: selectedIndex == i,
                      icon: icons[i],
                      // Icon only: no text label appears on the active
                      // tab. Screen readers still get the name.
                      semanticLabel: labels[i],
                      haptic: true,
                      debug: false,
                      borderRadius: BorderRadius.circular(50),
                      activeBorder:
                          Border.all(color: theme.colorScheme.secondary),
                      margin: const EdgeInsets.fromLTRB(6, 12, 6, 12),
                      // A symmetric curve keeps expand/collapse motion
                      // consistent when GButton flips its curve, including
                      // mid-animation taps.
                      curve: Curves.easeInOutCubic,
                      duration: duration,
                      gap: 0,
                      iconColor: isDark ? Colors.white : Colors.black,
                      // White on the accent; black on white in dark E-ink.
                      iconActiveColor: Colors.white.einkBg(context),
                      iconSize: 20,
                      backgroundColor: theme.colorScheme.secondary,
                      rippleColor: Colors.transparent,
                      hoverColor: Colors.transparent,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 12),
                      onPressed: () => onSelected(i),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
