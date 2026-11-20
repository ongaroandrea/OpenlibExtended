// "Supported formats" file type filter (the default) and the library sync
// that now keeps any file that still exists.

// Dart imports:
import 'dart:io';

// Flutter imports:
import 'package:flutter_test/flutter_test.dart';

// Package imports:
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

// Project imports:
import 'package:openlib/core/annas_archive.dart';
import 'package:openlib/services/annas_archieve.dart' show BookData;
import 'package:openlib/services/database.dart';
import 'package:openlib/services/files.dart' show syncLibraryWithDisk;
import 'package:openlib/services/search_manager.dart';
import 'package:openlib/state/state.dart'
    show
        fileType,
        getFileTypeValue,
        selectedFileTypeState,
        supportedFileTypeValue;

class _FakePathProvider extends PathProviderPlatform {
  _FakePathProvider(this.root);
  final String root;

  Future<String> _dir(String name) async {
    final dir = Directory('$root/$name');
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

BookData _book(String title, String info) =>
    BookData(title: title, link: 'https://x/$title', md5: title, info: info);

final dataBase = MyLibraryDb.instance;

void main() {
  group('Supported formats filter', () {
    test('is the default and asks for the formats the app opens', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      expect(container.read(selectedFileTypeState), supportedFileTypeValue);
      expect(container.read(getFileTypeValue), 'epub,pdf,cbr,cbz');
      expect(fileType.first, supportedFileTypeValue,
          reason: 'offered first in the existing File type dropdown');
      expect(fileType, contains('All'));
    });

    test("Anna's Archive gets one ext= per format", () {
      final url = ArchiveParsing.buildSearchUrl(
        baseUrl: 'https://aa.example',
        query: 'dune',
        fileType: 'epub,pdf,cbr,cbz',
      );
      expect(url, contains('&ext=epub&ext=pdf&ext=cbr&ext=cbz'));
      expect(url, isNot(contains('epub,pdf')));
    });

    test('client-side filtering keeps any of the listed formats', () {
      const query = SearchQuery(
          text: 'dune', fileType: 'epub,pdf,cbr,cbz', filtersEnabled: true);
      expect(query.fileTypes, ['epub', 'pdf', 'cbr', 'cbz']);
      final outcome = applyClientFilters(SearchProviderId.welib, [
        _book('a', 'English, EPUB, 2MB'),
        _book('b', 'English, MOBI, 1MB'),
        _book('c', 'English, PDF, 5MB'),
        _book('d', 'English, CBZ, 30MB'),
      ], query);
      expect([for (final b in outcome.books) b.title], ['a', 'c', 'd']);
    });

    test('LibGen gets no single extension for a list; the app filters', () {
      const list = SearchQuery(
          text: 'x', fileType: 'epub,pdf', filtersEnabled: true);
      const single =
          SearchQuery(text: 'x', fileType: 'epub', filtersEnabled: true);
      expect(serverSideFilters(SearchProviderId.libgen, list),
          isNot(contains(SearchFilter.fileType)));
      expect(serverSideFilters(SearchProviderId.libgen, single),
          contains(SearchFilter.fileType));
    });
  });

  group('library sync', () {
    late Directory root;
    late Directory books;

    setUpAll(() async {
      sqfliteFfiInit();
      databaseFactory = databaseFactoryFfi;
      root = await Directory.systemTemp.createTemp('openlib_sync_test');
      PathProviderPlatform.instance = _FakePathProvider(root.path);
    });

    tearDownAll(() => root.delete(recursive: true));

    setUp(() async {
      books = await Directory('${root.path}/books').create(recursive: true);
      final db = await dataBase.database;
      await db.delete('mybooks');
      await db.delete('preferences');
      await dataBase.savePreference('bookStorageDirectory', books.path);
    });

    tearDown(() => books.delete(recursive: true));

    MyBook entry(String fileName, String format) => MyBook(
          id: fileName,
          title: fileName,
          author: 'A',
          thumbnail: '',
          link: '',
          publisher: '',
          info: '',
          description: '',
          format: format,
          fileName: fileName,
        );

    test('keeps any file that exists, removes missing ones, adds openable',
        () async {
      File('${books.path}/kept.mobi').writeAsStringSync('x');
      File('${books.path}/kept.azw3').writeAsStringSync('x');
      File('${books.path}/new.cbz').writeAsStringSync('x');
      File('${books.path}/notes.txt').writeAsStringSync('x');
      await dataBase.insert(entry('kept.mobi', 'mobi'));
      await dataBase.insert(entry('kept.azw3', 'azw3'));
      await dataBase.insert(entry('gone.epub', 'epub'));

      await syncLibraryWithDisk();

      final names = {for (final b in await dataBase.getAll()) b.getFileName()};
      expect(names, containsAll(['kept.mobi', 'kept.azw3']),
          reason: 'a MOBI or AZW3 that is still there stays in the library');
      expect(names, isNot(contains('gone.epub')),
          reason: 'an entry whose file is gone is removed');
      expect(names, contains('new.cbz'),
          reason: 'new files the app can open are added');
      expect(names, isNot(contains('notes.txt')),
          reason: 'other files are not added');
    });
  });
}
