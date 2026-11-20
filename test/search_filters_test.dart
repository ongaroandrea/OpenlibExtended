// Search filters across sources: filters a source's backend cannot take
// are applied to its parsed results (file type, language, year, sort),
// filters that cannot be applied at all are reported instead of silently
// dropped, and a source emptied by the filters hands over to the next one.

// Dart imports:
import 'dart:io';

// Flutter imports:
import 'package:flutter_test/flutter_test.dart';

// Package imports:
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

// Project imports:
import 'package:openlib/services/annas_archieve.dart';
import 'package:openlib/services/database.dart';
import 'package:openlib/services/search_manager.dart';

class _FakePathProvider extends PathProviderPlatform {
  Future<String> _dir(String name) async {
    final dir = Directory('/tmp/openlib_searchfilters_test/$name');
    await dir.create(recursive: true);
    return dir.path;
  }

  @override
  Future<String?> getApplicationSupportPath() => _dir('support');

  @override
  Future<String?> getApplicationDocumentsPath() => _dir('documents');

  @override
  Future<String?> getTemporaryPath() => _dir('temp');

  @override
  Future<String?> getLibraryPath() => _dir('library');
}

class _FakeProvider implements SearchProvider {
  _FakeProvider(this.id, this.results);

  @override
  final SearchProviderId id;
  final List<BookData> results;
  int calls = 0;

  @override
  String get displayName => id.name;

  @override
  Future<List<BookData>> search(SearchQuery query) async {
    calls++;
    return results;
  }
}

BookData _book(String title, String info) =>
    BookData(title: title, link: 'https://x/$title', md5: title, info: info);

// Shapes match LibgenProvider's info: language, EXT, size, year.
final _libgenRows = [
  _book('Hobbit', 'English, PDF, 1.4MB, 1937'),
  _book('Earthsea', 'English, EPUB, 2.1MB, 1968'),
  _book('Zauberberg', 'German, EPUB, 707 kB, 1924'),
  _book('Dune', 'English, EPUB, 12 MB, 2019'),
  _book('Unknown', 'English, EPUB'),
];

List<String> _titles(SearchManagerResult result) =>
    [for (final book in result.books) book.title];

Future<SearchManagerResult> _searchOnly(
    SearchProviderId id, List<BookData> rows, SearchQuery Function() build) {
  final provider = _FakeProvider(id, rows);
  return SearchManager(providers: [provider]).search(build());
}

void main() {
  setUpAll(() {
    if (Platform.isLinux || Platform.isWindows || Platform.isMacOS) {
      sqfliteFfiInit();
      databaseFactory = databaseFactoryFfi;
      PathProviderPlatform.instance = _FakePathProvider();
    }
  });

  group('defaults', () {
    test('filters off: every source returns its rows unchanged', () async {
      for (final id in SearchProviderId.values) {
        final result = await _searchOnly(
            id,
            _libgenRows,
            () => SearchQuery(
                  text: 'x',
                  source: id,
                  // Set but disabled: must not apply.
                  sort: 'newest',
                  fileType: 'pdf',
                  year: '2019',
                  content: 'book_fiction',
                ));
        expect(_titles(result), [for (final b in _libgenRows) b.title]);
        expect(result.ignoredFilters, isEmpty);
        expect(result.clientSideFilters, isEmpty);
      }
    });

    test('filters on with default values: order unchanged', () async {
      for (final id in SearchProviderId.values) {
        final result = await _searchOnly(id, _libgenRows,
            () => SearchQuery(text: 'x', source: id, filtersEnabled: true));
        expect(_titles(result), [for (final b in _libgenRows) b.title]);
        expect(result.ignoredFilters, isEmpty);
      }
    });
  });

  group('LibGen client-side filters', () {
    SearchQuery q(
            {String fileType = '',
            String language = '',
            String year = '',
            String sort = '',
            String content = ''}) =>
        SearchQuery(
            text: 'x',
            source: SearchProviderId.libgen,
            filtersEnabled: true,
            fileType: fileType,
            language: language,
            year: year,
            sort: sort,
            content: content);

    test('file type', () async {
      final result = await _searchOnly(
          SearchProviderId.libgen, _libgenRows, () => q(fileType: 'pdf'));
      expect(_titles(result), ['Hobbit']);
      expect(result.ignoredFilters, isEmpty);
      // Extension is a libgen URL parameter, so not client-side.
      expect(result.clientSideFilters, isEmpty);
    });

    test('language', () async {
      final result = await _searchOnly(
          SearchProviderId.libgen, _libgenRows, () => q(language: 'de'));
      expect(_titles(result), ['Zauberberg']);
    });

    test('year range and "Before" are applied to parsed years', () async {
      final range = await _searchOnly(
          SearchProviderId.libgen, _libgenRows, () => q(year: '1930-1970'));
      expect(_titles(range), ['Hobbit', 'Earthsea']);
      expect(range.clientSideFilters, contains(SearchFilter.year));

      final before = await _searchOnly(
          SearchProviderId.libgen, _libgenRows, () => q(year: 'Before 1980'));
      expect(_titles(before), ['Hobbit', 'Earthsea', 'Zauberberg']);

      final single = await _searchOnly(
          SearchProviderId.libgen, _libgenRows, () => q(year: '2019'));
      expect(_titles(single), ['Dune']);
      expect(single.clientSideFilters, isNot(contains(SearchFilter.year)));
    });

    test('combined filters', () async {
      final result = await _searchOnly(SearchProviderId.libgen, _libgenRows,
          () => q(fileType: 'epub', language: 'en', year: '1960-2020'));
      expect(_titles(result), ['Earthsea', 'Dune']);
    });

    test('sort newest / oldest by year, rows without a year last', () async {
      final newest = await _searchOnly(
          SearchProviderId.libgen, _libgenRows, () => q(sort: 'newest'));
      expect(_titles(newest),
          ['Dune', 'Earthsea', 'Hobbit', 'Zauberberg', 'Unknown']);
      expect(newest.clientSideFilters, contains(SearchFilter.sort));

      final oldest = await _searchOnly(
          SearchProviderId.libgen, _libgenRows, () => q(sort: 'oldest'));
      expect(_titles(oldest),
          ['Zauberberg', 'Hobbit', 'Earthsea', 'Dune', 'Unknown']);
    });

    test('sort largest / smallest by parsed size', () async {
      final largest = await _searchOnly(
          SearchProviderId.libgen, _libgenRows, () => q(sort: 'largest'));
      expect(_titles(largest),
          ['Dune', 'Earthsea', 'Hobbit', 'Zauberberg', 'Unknown']);
      final smallest = await _searchOnly(
          SearchProviderId.libgen, _libgenRows, () => q(sort: 'smallest'));
      expect(_titles(smallest),
          ['Zauberberg', 'Hobbit', 'Earthsea', 'Dune', 'Unknown']);
    });

    test('Type cannot be applied and is reported', () async {
      final result = await _searchOnly(SearchProviderId.libgen, _libgenRows,
          () => q(content: 'book_fiction'));
      expect(result.books, hasLength(_libgenRows.length));
      expect(result.ignoredFilters, {SearchFilter.type});
    });
  });

  group('ignored-filter reporting', () {
    test('sort with no data in the rows is reported, order kept', () async {
      final rows = [_book('A', 'EPUB'), _book('B', 'PDF')];
      final result = await _searchOnly(
          SearchProviderId.welib,
          rows,
          () => const SearchQuery(
              text: 'x',
              source: SearchProviderId.welib,
              filtersEnabled: true,
              sort: 'newest'));
      expect(_titles(result), ['A', 'B']);
      expect(result.ignoredFilters, {SearchFilter.sort});
    });

    test('year with no years in the rows is reported, not emptied', () async {
      final rows = [_book('A', 'English, EPUB'), _book('B', 'English, PDF')];
      final result = await _searchOnly(
          SearchProviderId.zlibrary,
          rows,
          () => const SearchQuery(
              text: 'x',
              source: SearchProviderId.zlibrary,
              filtersEnabled: true,
              year: '2020'));
      expect(_titles(result), ['A', 'B']);
      expect(result.ignoredFilters, {SearchFilter.year});
    });

    test('WeLib reports author/publisher/type it never sends', () async {
      final result = await _searchOnly(
          SearchProviderId.welib,
          _libgenRows,
          () => const SearchQuery(
              text: 'x',
              source: SearchProviderId.welib,
              filtersEnabled: true,
              author: 'Tolkien',
              publisher: 'Allen',
              content: 'book_fiction'));
      expect(result.ignoredFilters, {
        SearchFilter.author,
        SearchFilter.publisher,
        SearchFilter.type,
      });
    });

    test("Anna's Archive applies everything server-side", () async {
      final result = await _searchOnly(
          SearchProviderId.annasArchive,
          _libgenRows,
          () => const SearchQuery(
              text: 'x',
              source: SearchProviderId.annasArchive,
              filtersEnabled: true,
              sort: 'newest',
              content: 'book_fiction',
              year: '1990-1999'));
      // Server order and server filtering are trusted.
      expect(_titles(result), [for (final b in _libgenRows) b.title]);
      expect(result.ignoredFilters, isEmpty);
      expect(result.clientSideFilters, isEmpty);
    });
  });

  group('fall-through', () {
    setUp(() async {
      await MyLibraryDb.instance.savePreference(
          'searchProviders',
          SearchProviderId.values.map((p) => p.name).join(','));
    });

    test('a source emptied by the filters hands over to the next', () async {
      final libgen = _FakeProvider(SearchProviderId.libgen, [
        _book('Old', 'English, EPUB, 1 MB, 1950'),
      ]);
      final zlib = _FakeProvider(SearchProviderId.zlibrary, [
        _book('New', 'English, EPUB, 1 MB, 2021'),
        _book('Older', 'English, EPUB, 1 MB, 1999'),
      ]);
      final anna = _FakeProvider(SearchProviderId.annasArchive, [
        _book('Never', 'English, EPUB, 1 MB, 2021'),
      ]);
      final manager = SearchManager(
          database: MyLibraryDb.instance, providers: [libgen, zlib, anna]);

      final result = await manager.search(const SearchQuery(
          text: 'x', filtersEnabled: true, year: '2020-2024'));

      expect(libgen.calls, 1);
      expect(zlib.calls, 1);
      expect(anna.calls, 0);
      expect(_titles(result), ['New']);
      expect(result.resultSource, 'zlibrary');
      expect(result.clientSideFilters, {SearchFilter.year});
    });

    test('ignored filters describe the source that answered', () async {
      final libgen = _FakeProvider(SearchProviderId.libgen, [
        _book('L', 'English, EPUB, 1 MB, 2001'),
      ]);
      final manager =
          SearchManager(database: MyLibraryDb.instance, providers: [libgen]);
      final result = await manager.search(const SearchQuery(
          text: 'x', filtersEnabled: true, content: 'magazine'));
      expect(result.resultSource, 'libgen');
      expect(result.ignoredFilters, {SearchFilter.type});
    });

    test('nothing found anywhere: no ignored filters reported', () async {
      final libgen = _FakeProvider(SearchProviderId.libgen, [
        _book('L', 'English, EPUB, 1 MB, 2001'),
      ]);
      final manager =
          SearchManager(database: MyLibraryDb.instance, providers: [libgen]);
      final result = await manager.search(const SearchQuery(
          text: 'x',
          filtersEnabled: true,
          content: 'magazine',
          fileType: 'pdf'));
      expect(result.books, isEmpty);
      expect(result.ignoredFilters, isEmpty);
    });
  });

  group('info parsing', () {
    test('year and size tokens', () {
      expect(infoYear('English, EPUB, 2.1MB, 1968'), 1968);
      expect(infoYear('English, EPUB, 2.1MB'), isNull);
      expect(infoSizeBytes('English, EPUB, 2.1MB, 1968'),
          closeTo(2.1 * 1024 * 1024, 1));
      expect(infoSizeBytes('German, EPUB, 707 kB'), closeTo(707 * 1024, 1));
      expect(infoSizeBytes('English, EPUB, 1968'), isNull);
    });
  });
}
