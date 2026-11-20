// Flutter imports:
import 'package:flutter/material.dart';
import 'package:openlib/l10n/app_localizations.dart';
import 'package:openlib/features/eink/eink.dart'
    show BusyIndicator, einkModeProvider;

// Package imports:
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';

// Project imports:
import 'package:openlib/services/annas_archieve.dart' show BookData;
import 'package:openlib/services/database.dart' show MyLibraryDb;
import 'package:openlib/services/search_manager.dart';
import 'package:openlib/state/state.dart' as app_state;
import 'package:openlib/ui/book_info_page.dart';
import 'package:openlib/ui/components/book_card_widget.dart';
import 'package:openlib/ui/components/error_widget.dart';

/// Writes one search-filter preference. Overridable in tests; the app
/// persists to the same `filter*` keys main.dart restores at launch.
final resultsPreferenceWriterProvider =
    Provider<Future<void> Function(String key, String value)>(
        (ref) => (key, value) => MyLibraryDb.instance.savePreference(key, value));

/// The sources the user can pick on the results page, in menu order.
const List<(SearchProviderId, String)> _sources = [
  (SearchProviderId.annasArchive, "Anna's Archive"),
  (SearchProviderId.libgen, 'Library Genesis'),
  (SearchProviderId.zlibrary, 'Z-Library'),
  (SearchProviderId.welib, 'WeLib'),
];

/// Window widths (dp) where the results layout changes.
const double _kMediumWidth = 600;
const double _kExpandedWidth = 840;

/// One active (non-default) search filter, as shown on the results page.
class _ActiveFilter {
  const _ActiveFilter(this.filter, this.name, this.value);
  final SearchFilter filter;
  final String name;
  final String value;
}

/// The localized name of a search filter (reuses the search page keys).
String _filterName(SearchFilter filter, AppLocalizations l10n) {
  switch (filter) {
    case SearchFilter.type:
      return l10n.searchFilterType;
    case SearchFilter.sort:
      return l10n.searchFilterSort;
    case SearchFilter.fileType:
      return l10n.searchFilterFileType;
    case SearchFilter.language:
      return l10n.searchFilterLanguage;
    case SearchFilter.year:
      return l10n.searchFilterYear;
    case SearchFilter.author:
      return l10n.author;
    case SearchFilter.publisher:
      return l10n.publisher;
  }
}

/// The localized label of a stored filter value; values without a
/// translation (file formats, years, language names) show as stored.
String _filterValueLabel(String value, AppLocalizations l10n) {
  switch (value) {
    case 'All':
      return l10n.searchFilterAll;
    case app_state.supportedFileTypeValue:
      return l10n.searchFileTypeSupported;
    case 'Any Books':
      return l10n.searchTypeAnyBooks;
    case 'Unknown Books':
      return l10n.searchTypeUnknownBooks;
    case 'Fiction Books':
      return l10n.searchTypeFiction;
    case 'Non-fiction Books':
      return l10n.searchTypeNonFiction;
    case 'Comic Books':
      return l10n.searchTypeComic;
    case 'Magazine':
      return l10n.searchTypeMagazine;
    case 'Standards Document':
      return l10n.searchTypeStandardsDocument;
    case 'Journal Article':
      return l10n.searchTypeJournalArticle;
    case 'Newest':
      return l10n.searchSortNewest;
    case 'Oldest':
      return l10n.searchSortOldest;
    case 'Largest':
      return l10n.searchSortLargest;
    case 'Smallest':
      return l10n.searchSortSmallest;
    case 'Before 1980':
      return l10n.searchYearBefore1980;
    default:
      return value;
  }
}

/// Persisted filters: state provider, default value, preference key.
/// Defaults and keys match what main.dart restores at launch.
final Map<SearchFilter, (StateProvider<String>, String, String?)>
    _filterStates = {
  SearchFilter.type: (app_state.selectedTypeState, 'All', 'filterType'),
  SearchFilter.sort:
      (app_state.selectedSortState, 'Most Relevant', 'filterSort'),
  SearchFilter.fileType: (
    app_state.selectedFileTypeState,
    app_state.supportedFileTypeValue,
    'filterFileType'
  ),
  SearchFilter.language:
      (app_state.selectedLanguageState, 'All', 'filterLanguage'),
  SearchFilter.year: (app_state.selectedYearState, 'All', 'filterYear'),
  // The advanced fields are not persisted.
  SearchFilter.author: (app_state.searchAuthorProvider, '', null),
  SearchFilter.publisher: (app_state.searchPublisherProvider, '', null),
};

/// Search results with pagination: the first page loads with the page,
/// and scrolling near the bottom quietly fetches the next one and
/// appends it (in E-ink mode a "Load more" button at the end does it
/// instead). Anna's Archive serves 50 results per page.
class ResultPage extends StatefulWidget {
  const ResultPage({super.key, required this.searchQuery});
  final String searchQuery;

  @override
  State<ResultPage> createState() => _SourceSelectionState();
}

class _SourceSelectionState extends State<ResultPage> {
  SearchProviderId? _source;

  @override
  Widget build(BuildContext context) => _SourceResultPage(
    key: ValueKey((widget.searchQuery, _source)),
    searchQuery: widget.searchQuery,
    source: _source,
    onSourceChanged: (source) => setState(() => _source = source),
  );
}

class _SourceResultPage extends ConsumerStatefulWidget {
  const _SourceResultPage({super.key, required this.searchQuery,
    required this.source, required this.onSourceChanged});
  final String searchQuery;
  final SearchProviderId? source;
  final ValueChanged<SearchProviderId?> onSourceChanged;

  @override
  ConsumerState<_SourceResultPage> createState() => _ResultPageState();
}

class _ResultPageState extends ConsumerState<_SourceResultPage> {
  final _scrollController = ScrollController();

  /// Results accumulated across all loaded pages.
  final List<BookData> _books = [];

  /// Pages fully merged into [_books]; the next fetch starts at +1.
  int _loadedPages = 0;
  bool _fetchingNextPage = false;
  Object? _paginationError;
  bool _paginationErrorDismissed = false;

  /// A page that returned nothing stops the pager - there is no page
  /// after the last one, and endless empty fetches would spin forever.
  bool _reachedEnd = false;

  app_state.SearchPageKey _pageKey(int page) =>
      app_state.SearchPageKey(widget.searchQuery, page, source: widget.source);

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    // Page 1 may resolve before the first build; merge it the moment it
    // does. Once loaded, the pager owns accumulation from there.
    ref.listenManual(
      app_state.searchProvider(_pageKey(1)),
      (previous, next) {
        // While reloading (filters reset, retry) the previous page is
        // still attached to the loading state; wait for the new one.
        if (next.isLoading) return;
        final books = next.valueOrNull;
        if (books != null && _loadedPages == 0) {
          setState(() {
            _books.addAll(books);
            _loadedPages = 1;
            if (books.isEmpty) _reachedEnd = true;
          });
          _fillViewportAfterFrame();
        }
      },
      fireImmediately: true,
    );
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    // E-ink mode pages explicitly with the "Load more" button: a list
    // that grows under the finger means extra full-screen redraws.
    if (ref.read(einkModeProvider)) return;
    if (_scrollController.position.pixels >=
            _scrollController.position.maxScrollExtent - 200 &&
        !_fetchingNextPage &&
        !_reachedEnd &&
        _paginationError == null) {
      _loadNextPage();
    }
  }

  /// A page too short to scroll never triggers [_onScroll], so the
  /// pager would neither load more nor learn it reached the end. Check
  /// once the page is laid out (normal mode only; E-ink has its button).
  void _fillViewportAfterFrame() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_scrollController.hasClients) return;
      if (_scrollController.position.maxScrollExtent <= 0) _onScroll();
    });
  }

  Future<void> _loadNextPage() async {
    if (!mounted) return;
    if (_fetchingNextPage) return;
    setState(() {
      _fetchingNextPage = true;
      _paginationError = null;
      _paginationErrorDismissed = false;
    });

    final page = _loadedPages + 1;
    try {
      final nextPage =
          await ref.read(app_state.searchProvider(_pageKey(page)).future);

      if (!mounted) return;
      setState(() {
        if (nextPage.isEmpty) {
          _reachedEnd = true;
        } else {
          _books.addAll(nextPage);
          _loadedPages = page;
        }
      });
      _fillViewportAfterFrame();
    } catch (error) {
      if (mounted) setState(() => _paginationError = error);
    } finally {
      if (mounted) setState(() => _fetchingNextPage = false);
    }
  }

  void _retryNextPage() {
    ref.invalidate(app_state.searchProvider(_pageKey(_loadedPages + 1)));
    _loadNextPage();
  }

  /// Forgets every loaded page so the next page-1 result starts over.
  void _resetPages() {
    setState(() {
      _books.clear();
      _loadedPages = 0;
      _reachedEnd = false;
      _paginationError = null;
      _paginationErrorDismissed = false;
    });
  }

  /// Runs the whole search again from page 1.
  void _refreshFirstPage() {
    _resetPages();
    // ignore: unused_result
    ref.refresh(app_state.searchProvider(_pageKey(1)));
  }

  List<_ActiveFilter> _activeFilters(AppLocalizations l10n) {
    if (!ref.watch(app_state.enableFiltersState)) return const [];
    final active = <_ActiveFilter>[];
    _filterStates.forEach((filter, entry) {
      final value = ref.watch(entry.$1).trim();
      if (value.isEmpty || value == entry.$2) return;
      active.add(_ActiveFilter(filter, _filterName(filter, l10n),
          _filterValueLabel(value, l10n)));
    });
    return active;
  }

  /// Resets [only] (or every filter) to its default, persists the
  /// default, and searches again: page 1 watches the filters, so it
  /// re-runs on its own once they change.
  void _resetFilters({SearchFilter? only}) {
    final save = ref.read(resultsPreferenceWriterProvider);
    _resetPages();
    _filterStates.forEach((filter, entry) {
      if (only != null && filter != only) return;
      final (provider, defaultValue, prefKey) = entry;
      ref.read(provider.notifier).state = defaultValue;
      if (prefKey != null) save(prefKey, defaultValue);
    });
  }

  @override
  Widget build(BuildContext context) {
    // Page 1 is watched so a fresh query rebuilds everything; deeper
    // pages are read on demand by the pager.
    final firstPage = ref.watch(app_state.searchProvider(_pageKey(1)));
    final l10n = AppLocalizations.of(context);
    final activeFilters = _activeFilters(l10n);

    return Scaffold(
      appBar: AppBar(
        // The query as the user typed it.
        title: Text(l10n.resultsFor(widget.searchQuery)),
        titleTextStyle: Theme.of(context)
            .textTheme
            .titleLarge
            ?.copyWith(fontWeight: FontWeight.bold),
        backgroundColor: Theme.of(context).colorScheme.surface,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(68),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
            child: DropdownButtonFormField<SearchProviderId>(
              key: const Key('search-source-selector'),
              initialValue: widget.source,
              isExpanded: true,
              decoration: InputDecoration(
                labelText: l10n.searchSource,
                border: const OutlineInputBorder(),
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              ),
              hint: Text(l10n.automaticSource),
              items: [
                DropdownMenuItem(value: null,
                  child: Text(l10n.automaticSource)),
                for (final (id, name) in _sources)
                  DropdownMenuItem(value: id, child: Text(name)),
              ],
              onChanged: widget.onSourceChanged,
            ),
          ),
        ),
      ),
      body: firstPage.when(
        data: (pageOne) {
          final meta =
              pageOne is app_state.SearchResultPage ? pageOne : null;
          if (_books.isNotEmpty) {
            return _buildResults(context, l10n, meta, activeFilters);
          }
          return _buildNoResults(context, l10n, meta, activeFilters);
        },
        error: (error, stackTrace) {
          return CustomErrorWidget(
            error: error,
            stackTrace: stackTrace,
            onRefresh: _refreshFirstPage,
          );
        },
        loading: () {
          return Column(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.all(10),
                // The chain tries LibGen, then Z-Library, then
                // Anna's Archive - an empty page is not the end.
                child: Text(
                  l10n.tryingNextSource,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
              Expanded(
                child: Center(
                  child: SizedBox(
                    width: 25,
                    height: 25,
                    child: BusyIndicator(
                      color: Theme.of(context).colorScheme.secondary,
                      strokeWidth: 3.0,
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _bookCard(BuildContext context, AppLocalizations l10n, BookData i) {
    return BookInfoCard(
      title: i.title,
      author: i.author ?? l10n.unknown,
      publisher: i.publisher ?? l10n.unknown,
      thumbnail: i.thumbnail ?? '',
      info: i.info ?? '',
      link: i.link,
      md5: i.md5,
      source: i.source,
      onClick: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (BuildContext context) {
              return BookInfoPage(url: i.link);
            },
          ),
        );
      },
    );
  }

  Widget _buildResults(BuildContext context, AppLocalizations l10n,
      app_state.SearchResultPage? meta, List<_ActiveFilter> activeFilters) {
    final scheme = Theme.of(context).colorScheme;
    final source = (meta != null && meta.resultSource.isNotEmpty)
        ? meta.resultSource
        : _books.first.source;
    final ignored = meta?.ignoredFilters ?? const <SearchFilter>{};
    final failed = meta?.failedSources ?? const <String>[];
    final sortedPerPage =
        meta?.clientSideFilters.contains(SearchFilter.sort) ?? false;

    return LayoutBuilder(builder: (context, constraints) {
      // Wide windows: no stretched phone list. Medium widths keep one
      // column at a readable width; expanded widths use two columns.
      final width = constraints.maxWidth;
      final columns = width >= _kExpandedWidth ? 2 : 1;
      final double maxContent = width >= _kExpandedWidth
          ? 1200
          : (width >= _kMediumWidth ? 720 : width);
      final double side = width >= _kMediumWidth
          ? ((width - maxContent) / 2).clamp(16.0, double.infinity)
          : 10.0;
      final padding = EdgeInsets.symmetric(horizontal: side);
      final rowCount = (_books.length + columns - 1) ~/ columns;

      return CustomScrollView(
        controller: _scrollController,
        slivers: <Widget>[
          SliverPadding(
            padding: padding.copyWith(top: 8, bottom: 10),
            sliver: SliverToBoxAdapter(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (source != null)
                    Text(
                      l10n.searchingOn(source),
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  if (activeFilters.isNotEmpty)
                    _ActiveFilterChips(
                      filters: activeFilters,
                      onRemove: (filter) => _resetFilters(only: filter),
                      onClearAll: _resetFilters,
                    ),
                  if (failed.isNotEmpty)
                    _Notice(
                      key: const Key('results-failed-sources'),
                      icon: Icons.cloud_off_rounded,
                      text: l10n.resultsSourcesDidNotRespond(failed.join(', ')),
                      actionLabel: l10n.retry,
                      onAction: _refreshFirstPage,
                    ),
                  if (ignored.isNotEmpty && source != null)
                    _Notice(
                      key: const Key('results-ignored-filters'),
                      icon: Icons.filter_alt_off_outlined,
                      text: l10n.resultsFiltersIgnored(
                          ignored.length,
                          [
                            for (final f in SearchFilter.values)
                              if (ignored.contains(f)) _filterName(f, l10n)
                          ].join(', '),
                          source),
                    ),
                  if (sortedPerPage)
                    Padding(
                      key: const Key('results-sorted-per-page'),
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        l10n.resultsSortedWithinPage,
                        style: TextStyle(
                            fontSize: 12, color: scheme.onSurfaceVariant),
                      ),
                    ),
                ],
              ),
            ),
          ),
          SliverPadding(
            padding: padding,
            sliver: SliverList.builder(
              itemCount: rowCount,
              itemBuilder: (context, row) {
                if (columns == 1) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 10.0),
                    child: _bookCard(context, l10n, _books[row]),
                  );
                }
                final start = row * columns;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 10.0),
                  child: Row(
                    key: const Key('results-grid-row'),
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      for (var c = 0; c < columns; c++) ...[
                        if (c > 0) const SizedBox(width: 12),
                        Expanded(
                          child: start + c < _books.length
                              ? _bookCard(context, l10n, _books[start + c])
                              : const SizedBox.shrink(),
                        ),
                      ],
                    ],
                  ),
                );
              },
            ),
          ),
          if (_paginationError != null)
            SliverPadding(
              padding: padding,
              sliver: SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Column(
                    children: [
                      if (!_paginationErrorDismissed)
                        Row(
                          key: const Key('pagination-error'),
                          children: [
                            Expanded(
                              child: Text(
                                  toNetworkError(_paginationError!).title(l10n)),
                            ),
                            IconButton(
                              tooltip: l10n.close,
                              icon: const Icon(Icons.close_rounded),
                              onPressed: () => setState(
                                  () => _paginationErrorDismissed = true),
                            ),
                          ],
                        ),
                      TextButton(
                        onPressed: _retryNextPage,
                        child: Text(l10n.retry),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          if (_fetchingNextPage)
            const SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 16),
                child: Center(
                  child: SizedBox(
                    width: 22,
                    height: 22,
                    child: BusyIndicator(strokeWidth: 2.5),
                  ),
                ),
              ),
            ),
          if (!_fetchingNextPage && !_reachedEnd && _paginationError == null)
            ref.watch(einkModeProvider)
                ? SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Center(
                        child: OutlinedButton(
                          key: const Key('load-more-results'),
                          onPressed: _loadNextPage,
                          child: Text(l10n.loadMoreResults),
                        ),
                      ),
                    ),
                  )
                : const SliverToBoxAdapter(child: SizedBox(height: 54)),
          if (_reachedEnd && !_fetchingNextPage && _paginationError == null)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
                child: Center(
                  child: Text(
                    l10n.resultsEndOfList(_books.length),
                    key: const Key('end-of-results'),
                    textAlign: TextAlign.center,
                    style: TextStyle(color: scheme.onSurfaceVariant),
                  ),
                ),
              ),
            ),
        ],
      );
    });
  }

  Widget _buildNoResults(BuildContext context, AppLocalizations l10n,
      app_state.SearchResultPage? meta, List<_ActiveFilter> activeFilters) {
    final theme = Theme.of(context);
    final failed = meta?.failedSources ?? const <String>[];
    // Only the search page enables filters; pages opened from trending
    // or categories have no search field to go back to.
    final fromSearch = ref.watch(app_state.enableFiltersState);
    final otherSources = [
      if (widget.source != null) (null, l10n.automaticSource),
      for (final s in _sources)
        if (s.$1 != widget.source) s,
    ];

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(32.0),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SvgPicture.asset(
                'assets/no_results.svg',
                width: 160,
                height: 160,
                fit: BoxFit.contain,
              ),
              const SizedBox(height: 24),
              Text(
                l10n.noResultsFound,
                textAlign: TextAlign.center,
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                failed.isNotEmpty
                    ? l10n.resultsNoMatchesSourcesDown(failed.join(', '))
                    : l10n.resultsNoMatchesHint,
                key: const Key('no-results-explanation'),
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium
                    ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
              ),
              if (activeFilters.isNotEmpty) ...[
                const SizedBox(height: 16),
                _ActiveFilterChips(
                  filters: activeFilters,
                  onRemove: (filter) => _resetFilters(only: filter),
                  center: true,
                ),
              ],
              const SizedBox(height: 20),
              Wrap(
                alignment: WrapAlignment.center,
                spacing: 8,
                runSpacing: 8,
                children: [
                  if (failed.isNotEmpty)
                    FilledButton.icon(
                      key: const Key('no-results-retry'),
                      onPressed: _refreshFirstPage,
                      icon: const Icon(Icons.refresh_rounded),
                      label: Text(l10n.retry),
                    ),
                  if (activeFilters.isNotEmpty)
                    FilledButton.tonalIcon(
                      key: const Key('clear-filters'),
                      onPressed: _resetFilters,
                      icon: const Icon(Icons.filter_alt_off_outlined),
                      label: Text(l10n.resultsClearFilters),
                    ),
                  MenuAnchor(
                    menuChildren: [
                      for (final (id, name) in otherSources)
                        MenuItemButton(
                          onPressed: () => widget.onSourceChanged(id),
                          child: Text(name),
                        ),
                    ],
                    builder: (context, controller, _) => OutlinedButton.icon(
                      key: const Key('try-another-source'),
                      onPressed: () => controller.isOpen
                          ? controller.close()
                          : controller.open(),
                      icon: const Icon(Icons.swap_horiz_rounded),
                      label: Text(l10n.resultsTryAnotherSource),
                    ),
                  ),
                  if (fromSearch && Navigator.of(context).canPop())
                    OutlinedButton.icon(
                      key: const Key('edit-search'),
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.edit_outlined),
                      label: Text(l10n.resultsEditSearch),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Removable chips for the active search filters, plus "Clear filters".
class _ActiveFilterChips extends StatelessWidget {
  const _ActiveFilterChips({
    required this.filters,
    required this.onRemove,
    this.onClearAll,
    this.center = false,
  });

  final List<_ActiveFilter> filters;
  final ValueChanged<SearchFilter> onRemove;
  final VoidCallback? onClearAll;
  final bool center;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Semantics(
      container: true,
      label: l10n.resultsActiveFilters,
      child: Padding(
        padding: const EdgeInsets.only(top: 8),
        child: Wrap(
          key: const Key('active-filter-chips'),
          alignment: center ? WrapAlignment.center : WrapAlignment.start,
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: 6,
          runSpacing: 6,
          children: [
            for (final f in filters)
              InputChip(
                key: Key('active-filter-${f.filter.name}'),
                label: Text(l10n.resultsFilterChip(f.name, f.value)),
                onDeleted: () => onRemove(f.filter),
                deleteButtonTooltipMessage: l10n.resultsRemoveFilter,
                visualDensity: VisualDensity.compact,
              ),
            if (onClearAll != null)
              TextButton(
                key: const Key('clear-filters'),
                onPressed: onClearAll,
                child: Text(l10n.resultsClearFilters),
              ),
          ],
        ),
      ),
    );
  }
}

/// A slim, non-blocking note above the results.
class _Notice extends StatelessWidget {
  const _Notice({
    super.key,
    required this.icon,
    required this.text,
    this.actionLabel,
    this.onAction,
  });

  final IconData icon;
  final String text;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: scheme.surfaceContainerHighest,
          border: Border.all(color: scheme.outlineVariant),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 4, 4, 4),
          child: Row(
            children: [
              Icon(icon, size: 18, color: scheme.onSurfaceVariant),
              const SizedBox(width: 8),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Text(text,
                      style: TextStyle(
                          fontSize: 13, color: scheme.onSurface)),
                ),
              ),
              if (actionLabel != null && onAction != null)
                TextButton(onPressed: onAction, child: Text(actionLabel!)),
            ],
          ),
        ),
      ),
    );
  }
}
