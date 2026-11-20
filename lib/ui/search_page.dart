// Flutter imports:
import 'package:flutter/material.dart';
import 'package:openlib/l10n/app_localizations.dart';
import 'package:openlib/features/eink/eink.dart'
    show EinkColors, EinkColorX;

// Package imports:
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:math' as math;

// Project imports:
import 'package:openlib/services/database.dart';
import 'package:openlib/ui/components/active_downloads_widget.dart';
import 'package:openlib/ui/components/page_title_widget.dart';
import 'package:openlib/ui/results_page.dart';
import 'components/snack_bar_widget.dart';
// Import the new API Service (adjust path as necessary)

import 'package:openlib/state/state.dart'
    show
        searchAuthorProvider,
        searchPublisherProvider,
        searchQueryProvider,
        selectedTypeState,
        selectedSortState,
        selectedFileTypeState,
        selectedLanguageState,
        selectedYearState,
        typeValues,
        fileType,
        supportedFileTypeValue,
        sortValues,
        languageValues,
        yearValues,
        enableFiltersState;

// ====================================================================
// SearchPage Implementation
// ====================================================================

class SearchPage extends ConsumerStatefulWidget {
  const SearchPage({super.key, this.onSearch});

  /// Called with a non-empty query on submit. Defaults to opening
  /// [ResultPage]; tests replace it to avoid network searches.
  final void Function(BuildContext context, String query)? onSearch;

  @override
  ConsumerState<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends ConsumerState<SearchPage> {
  late final TextEditingController _searchController;
  final TextEditingController _advancedController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Initialize controller with current state value
    _searchController =
        TextEditingController(text: ref.read(searchQueryProvider));

    // Keep the field in sync when the query is set elsewhere.
    ref.listenManual(searchQueryProvider, (previous, next) {
      if (_searchController.text != next) {
        _searchController.text = next;
        // Move cursor to the end
        _searchController.selection =
            TextSelection.fromPosition(TextPosition(offset: next.length));
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _advancedController.dispose();
    super.dispose();
  }

  /// Search runs only on submit: typing sends nothing anywhere (no
  /// suggestion lookups), which also keeps the screen still on e-ink.
  void _onSearchQueryChanged(String value) {
    ref.read(searchQueryProvider.notifier).state = value;
  }

  void _clearQuery() {
    _searchController.clear();
    ref.read(searchQueryProvider.notifier).state = '';
  }

  void onSubmit(BuildContext context) {
    final searchQuery = ref.read(searchQueryProvider).trim();
    if (searchQuery.isNotEmpty) {
      ref.read(enableFiltersState.notifier).state = true;
      final onSearch = widget.onSearch;
      if (onSearch != null) {
        onSearch(context, searchQuery);
        return;
      }
      Navigator.push(context,
          MaterialPageRoute(builder: (BuildContext context) {
        return ResultPage(searchQuery: searchQuery);
      }));
    } else {
      showSnackBar(
          context: context,
          message: AppLocalizations.of(context).searchFieldEmpty);
    }
  }

  // *** FILTER LABELS ***
  // The option strings are also the persisted preference values, so they
  // stay English; only what is shown is localized.

  String _typeLabel(AppLocalizations l10n, String value) => switch (value) {
        'All' => l10n.searchFilterAll,
        'Any Books' => l10n.searchTypeAnyBooks,
        'Unknown Books' => l10n.searchTypeUnknownBooks,
        'Fiction Books' => l10n.searchTypeFiction,
        'Non-fiction Books' => l10n.searchTypeNonFiction,
        'Comic Books' => l10n.searchTypeComic,
        'Magazine' => l10n.searchTypeMagazine,
        'Standards Document' => l10n.searchTypeStandardsDocument,
        'Journal Article' => l10n.searchTypeJournalArticle,
        _ => value,
      };

  String _sortLabel(AppLocalizations l10n, String value) => switch (value) {
        'Most Relevant' => l10n.searchSortMostRelevant,
        'Newest' => l10n.searchSortNewest,
        'Oldest' => l10n.searchSortOldest,
        'Largest' => l10n.searchSortLargest,
        'Smallest' => l10n.searchSortSmallest,
        _ => value,
      };

  String _plainLabel(AppLocalizations l10n, String value) => switch (value) {
        'All' => l10n.searchFilterAll,
        supportedFileTypeValue => l10n.searchFileTypeSupported,
        'Before 1980' => l10n.searchYearBefore1980,
        _ => value,
      };

  /// One filter dropdown. [width] is the preferred width at 1x text; it
  /// grows with the text scale but never past [maxWidth], and long labels
  /// ellipsize instead of overflowing.
  Widget _filterDropdown({
    required String label,
    required double width,
    required double maxWidth,
    required String value,
    required List<String> options,
    required String Function(String) display,
    required ValueChanged<String?> onChanged,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    final scaled = MediaQuery.textScalerOf(context).scale(width);
    return SizedBox(
      width: math.min(scaled, maxWidth),
      child: DropdownButtonFormField<String>(
        isExpanded: true,
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.bold,
            color: colorScheme.secondary,
          ),
          enabledBorder: OutlineInputBorder(
            borderSide: BorderSide(
              color: Colors.grey.einkFg(context),
              width: 2,
            ),
            borderRadius: const BorderRadius.all(Radius.circular(50)),
          ),
          focusedBorder: OutlineInputBorder(
            borderSide: BorderSide(color: colorScheme.tertiary, width: 2),
            borderRadius: const BorderRadius.all(Radius.circular(50)),
          ),
        ),
        icon: const Icon(Icons.arrow_drop_down),
        // A stale persisted value (e.g. an option that no longer exists)
        // would trip the dropdown's assertion; fall back to the default.
        initialValue: options.contains(value) ? value : options.first,
        items: options
            .map<DropdownMenuItem<String>>((String option) =>
                DropdownMenuItem<String>(
                  value: option,
                  child: Text(
                    display(option),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        fontSize: 12, fontWeight: FontWeight.bold),
                  ),
                ))
            .toList(),
        onChanged: onChanged,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colorScheme = Theme.of(context).colorScheme;
    final eink = EinkColors.of(context);

    // WidgetRef is available via ConsumerState
    final dropdownTypeValue = ref.watch(selectedTypeState);
    final dropdownSortValue = ref.watch(selectedSortState);
    final dropDownFileTypeValue = ref.watch(selectedFileTypeState);
    final dropdownLanguageValue = ref.watch(selectedLanguageState);
    final dropdownYearValue = ref.watch(selectedYearState);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 5, right: 5, top: 8),
          child: TitleText(l10n.navSearch),
        ),
        Expanded(
          child: SingleChildScrollView(
            scrollDirection: Axis.vertical,
            child: Padding(
              padding: const EdgeInsets.only(left: 5, right: 5),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const ActiveDownloadsWidget(),
                  // Search Input Field
                  Padding(
                    padding: const EdgeInsets.only(left: 7, right: 7, top: 10),
                    child: TextField(
                      controller: _searchController, // <--- Added controller
                      showCursor: true,
                      cursorColor: colorScheme.secondary,
                      // Show a search key on the keyboard and keep titles,
                      // author names and ISBNs as typed.
                      textInputAction: TextInputAction.search,
                      autocorrect: false,
                      decoration: InputDecoration(
                        enabledBorder: OutlineInputBorder(
                          borderSide: BorderSide(
                              color: Colors.grey.einkFg(context), width: 2),
                          borderRadius:
                              const BorderRadius.all(Radius.circular(50)),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderSide:
                              BorderSide(color: colorScheme.tertiary, width: 2),
                          borderRadius:
                              const BorderRadius.all(Radius.circular(50)),
                        ),
                        suffixIcon: Padding(
                          padding: const EdgeInsets.only(right: 5),
                          child: ValueListenableBuilder<TextEditingValue>(
                            valueListenable: _searchController,
                            builder: (context, value, _) => Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                if (value.text.isNotEmpty)
                                  IconButton(
                                    tooltip: l10n.searchClear,
                                    icon: const Icon(Icons.close),
                                    onPressed: _clearQuery,
                                  ),
                                IconButton(
                                  tooltip: l10n.searchSubmitTooltip,
                                  color: colorScheme.secondary,
                                  icon: const Icon(Icons.search, size: 23),
                                  onPressed: () => onSubmit(context),
                                ),
                              ],
                            ),
                          ),
                        ),
                        filled: true,
                        // onSurfaceVariant is ~9:1 on the light field and
                        // well above 4.5:1 on the dark one; E-ink uses its
                        // own muted ink.
                        hintStyle: TextStyle(
                            color: eink.monochrome
                                ? eink.muted
                                : colorScheme.onSurfaceVariant,
                            fontWeight: FontWeight.bold),
                        hintText: l10n.searchFieldHint,
                        // Remove explicit fillColor to use the theme default (Dark Grey in Dark Mode)
                      ),
                      onSubmitted: (String value) => onSubmit(context),
                      style: (Theme.of(context).textTheme.bodyLarge ??
                              const TextStyle(fontSize: 16))
                          .copyWith(
                        color: colorScheme.tertiary,
                        fontWeight: FontWeight.bold,
                      ),
                      onChanged: _onSearchQueryChanged,
                    ),
                  ),

                  // --- Advanced Search Panel ---
                  _AdvancedSearchPanel(
                    controller: _advancedController,
                    onSubmitted: () => onSubmit(context),
                  ),

                  // Dropdown Filters: flow onto as many rows as the width
                  // and text size need.
                  Padding(
                    padding: const EdgeInsets.only(left: 7, right: 7, top: 19),
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        final maxWidth = constraints.maxWidth;
                        return Wrap(
                          spacing: 10,
                          runSpacing: 19,
                          children: [
                            _filterDropdown(
                              label: l10n.searchFilterType,
                              width: 250,
                              maxWidth: maxWidth,
                              value: dropdownTypeValue,
                              options: typeValues.keys.toList(),
                              display: (v) => _typeLabel(l10n, v),
                              onChanged: (String? val) {
                                ref.read(selectedTypeState.notifier).state =
                                    val ?? '';
                                MyLibraryDb.instance
                                    .savePreference('filterType', val ?? 'All');
                              },
                            ),
                            _filterDropdown(
                              label: l10n.searchFilterSort,
                              width: 210,
                              maxWidth: maxWidth,
                              value: dropdownSortValue,
                              options: sortValues.keys.toList(),
                              display: (v) => _sortLabel(l10n, v),
                              onChanged: (String? val) {
                                ref.read(selectedSortState.notifier).state =
                                    val ?? '';
                                MyLibraryDb.instance.savePreference(
                                    'filterSort', val ?? 'Most Relevant');
                              },
                            ),
                            _filterDropdown(
                              label: l10n.searchFilterFileType,
                              width: 165,
                              maxWidth: maxWidth,
                              value: dropDownFileTypeValue,
                              options: fileType,
                              display: (v) => _plainLabel(l10n, v),
                              onChanged: (String? val) {
                                final picked = val ?? supportedFileTypeValue;
                                ref.read(selectedFileTypeState.notifier).state =
                                    picked;
                                MyLibraryDb.instance
                                    .savePreference('filterFileType', picked);
                              },
                            ),
                            // Language filter dropdown
                            _filterDropdown(
                              label: l10n.searchFilterLanguage,
                              width: 200,
                              maxWidth: maxWidth,
                              value: dropdownLanguageValue,
                              options: languageValues.keys.toList(),
                              display: (v) => _plainLabel(l10n, v),
                              onChanged: (String? val) {
                                ref.read(selectedLanguageState.notifier).state =
                                    val ?? 'All';
                                MyLibraryDb.instance.savePreference(
                                    'filterLanguage', val ?? 'All');
                              },
                            ),
                            // Year filter dropdown
                            _filterDropdown(
                              label: l10n.searchFilterYear,
                              width: 180,
                              maxWidth: maxWidth,
                              value: dropdownYearValue,
                              options: yearValues,
                              display: (v) => _plainLabel(l10n, v),
                              onChanged: (String? val) {
                                ref.read(selectedYearState.notifier).state =
                                    val ?? 'All';
                                MyLibraryDb.instance
                                    .savePreference('filterYear', val ?? 'All');
                              },
                            ),
                          ],
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// ====================================================================
// ADVANCED SEARCH PANEL
// Expandable metadata filters: author and publisher refine the plain
// text query into field-specific terms every provider understands.
// ====================================================================

class _AdvancedSearchPanel extends ConsumerStatefulWidget {
  const _AdvancedSearchPanel(
      {required this.controller, required this.onSubmitted});

  /// The main search field's controller, kept for future synergy
  /// between the plain query and the metadata fields.
  final TextEditingController controller;

  /// Runs the search when Enter / the keyboard search key is pressed in
  /// the author or publisher field.
  final VoidCallback onSubmitted;

  @override
  ConsumerState<_AdvancedSearchPanel> createState() =>
      _AdvancedSearchPanelState();
}

class _AdvancedSearchPanelState extends ConsumerState<_AdvancedSearchPanel> {
  bool _expanded = false;
  late final TextEditingController _authorController;
  late final TextEditingController _publisherController;

  @override
  void initState() {
    super.initState();
    _authorController =
        TextEditingController(text: ref.read(searchAuthorProvider));
    _publisherController =
        TextEditingController(text: ref.read(searchPublisherProvider));
  }

  @override
  void dispose() {
    _authorController.dispose();
    _publisherController.dispose();
    super.dispose();
  }

  InputDecoration _decoration(String label) {
    return InputDecoration(
      labelText: label,
      labelStyle: TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.bold,
        color: Theme.of(context).colorScheme.secondary,
      ),
      enabledBorder: OutlineInputBorder(
        borderSide: BorderSide(
            color: Colors.grey.einkFg(context), width: 2),
        borderRadius: const BorderRadius.all(Radius.circular(50)),
      ),
      focusedBorder: OutlineInputBorder(
        borderSide:
            BorderSide(color: Theme.of(context).colorScheme.tertiary, width: 2),
        borderRadius: const BorderRadius.all(Radius.circular(50)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final hasActiveFields = ref.watch(searchAuthorProvider).isNotEmpty ||
        ref.watch(searchPublisherProvider).isNotEmpty;

    return Padding(
      padding: const EdgeInsets.only(left: 7, right: 7, top: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Toggle row
          Row(
            children: [
              // Flexible so the label wraps instead of overflowing at
              // large text sizes on narrow screens.
              Flexible(
                child: TextButton.icon(
                onPressed: () => setState(() => _expanded = !_expanded),
                icon: Icon(
                  _expanded ? Icons.expand_less : Icons.expand_more,
                  size: 18,
                  color: Theme.of(context).colorScheme.secondary,
                ),
                label: Text(
                  AppLocalizations.of(context).advancedSearch,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.secondary,
                  ),
                ),
              ),
              ),
              if (hasActiveFields)
                Padding(
                  padding: const EdgeInsets.only(left: 8),
                  child: Icon(
                    Icons.filter_alt,
                    size: 14,
                    color: Theme.of(context).colorScheme.tertiary,
                  ),
                ),
            ],
          ),
          if (_expanded)
            Padding(
              padding: const EdgeInsets.only(top: 6, bottom: 4),
              child: Column(
                children: [
                  TextField(
                    controller: _authorController,
                    decoration:
                        _decoration(AppLocalizations.of(context).author),
                    style: const TextStyle(
                        fontSize: 12, fontWeight: FontWeight.bold),
                    onChanged: (value) => ref
                        .read(searchAuthorProvider.notifier)
                        .state = value.trim(),
                    textInputAction: TextInputAction.search,
                    autocorrect: false,
                    onSubmitted: (_) => widget.onSubmitted(),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: _publisherController,
                    decoration:
                        _decoration(AppLocalizations.of(context).publisher),
                    style: const TextStyle(
                        fontSize: 12, fontWeight: FontWeight.bold),
                    onChanged: (value) => ref
                        .read(searchPublisherProvider.notifier)
                        .state = value.trim(),
                    textInputAction: TextInputAction.search,
                    autocorrect: false,
                    onSubmitted: (_) => widget.onSubmitted(),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
