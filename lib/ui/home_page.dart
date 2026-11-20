import 'package:flutter/material.dart';
import 'package:openlib/l10n/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:openlib/state/state.dart';
import 'package:openlib/ui/categories_page.dart';
import 'package:openlib/ui/components/active_downloads_widget.dart';
import 'package:openlib/ui/components/page_title_widget.dart';
import 'package:openlib/ui/trending_page.dart';
import 'package:openlib/features/eink/eink.dart' show EinkColorX;

class HomePage extends ConsumerStatefulWidget {
  const HomePage({super.key});

  @override
  ConsumerState<ConsumerStatefulWidget> createState() => _HomePageState();
}

class _HomePageState extends ConsumerState<HomePage> {
  final List<Widget> _pages = const [
    TrendingPage(),
    GenresPage(),
  ];

  @override
  Widget build(BuildContext context) {
    final selectedIndex = ref.watch(homePageSelectedIndexProvider);
    return Scaffold(
      body: Column(
        children: [
          Padding(
            padding:
                const EdgeInsets.only(left: 5, right: 5, top: 8, bottom: 5),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                TitleText(selectedIndex == 0
                    ? AppLocalizations.of(context).trending
                    : AppLocalizations.of(context).genres),
                PelletContainer(
                  selectedIndex: selectedIndex,
                  onTrendingSelected: () => {
                    ref.read(homePageSelectedIndexProvider.notifier).state = 0
                  },
                  onCategoriesSelected: () => {
                    ref.read(homePageSelectedIndexProvider.notifier).state = 1
                  },
                ),
              ],
            ),
          ),
          const ActiveDownloadsWidget(),
          Expanded(child: _pages[selectedIndex]), // Display the selected page
        ],
      ),
    );
  }
}

/// Trending / Genres switch in the home header: two icon segments in one
/// pill. The selected segment is filled with the accent and shows a white
/// icon; the other shows the normal text colour on the page background, so
/// the icon is always visible (it used to sit on `primary`, which is black
/// in the light theme, giving black on black).
class PelletContainer extends StatelessWidget {
  final int selectedIndex;
  final VoidCallback onTrendingSelected;
  final VoidCallback onCategoriesSelected;

  const PelletContainer({
    super.key,
    required this.selectedIndex,
    required this.onTrendingSelected,
    required this.onCategoriesSelected,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final accent = Theme.of(context).colorScheme.secondary;
    return Container(
      height: 30,
      width: 105,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: accent),
      ),
      clipBehavior: Clip.antiAlias,
      child: Row(
        children: [
          _PelletSegment(
            icon: Icons.trending_up,
            label: l10n.trending,
            selected: selectedIndex == 0,
            onTap: onTrendingSelected,
          ),
          Container(width: 1, color: accent),
          _PelletSegment(
            icon: Icons.dashboard_rounded,
            label: l10n.genres,
            selected: selectedIndex == 1,
            onTap: onCategoriesSelected,
          ),
        ],
      ),
    );
  }
}

class _PelletSegment extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _PelletSegment({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final dark = theme.brightness == Brightness.dark;
    final idleFill = dark ? const Color(0xFF1E1E1E) : scheme.surface;
    final still = MediaQuery.disableAnimationsOf(context);
    return Expanded(
      child: Semantics(
        button: true,
        selected: selected,
        label: label,
        onTap: selected ? null : onTap,
        excludeSemantics: true,
        child: Tooltip(
          message: label,
          child: InkWell(
            onTap: selected ? null : onTap,
            child: AnimatedContainer(
              duration:
                  still ? Duration.zero : const Duration(milliseconds: 300),
              color: selected ? scheme.secondary : idleFill,
              alignment: Alignment.center,
              child: Icon(
                icon,
                size: 20,
                // White on the accent (black on white in dark E-ink);
                // the normal text colour when not selected.
                color: selected
                    ? Colors.white.einkBg(context)
                    : scheme.tertiary.einkFg(context),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
