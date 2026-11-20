// Storage access is optional: the app asks for "All files access" only
// when the chosen book folder isn't writable, only after the user agrees,
// and only once.

// Dart imports:
import 'dart:io';

// Package imports:
import 'package:flutter_test/flutter_test.dart';
import 'package:permission_handler/permission_handler.dart';

// Project imports:
import 'package:openlib/services/storage_access.dart';

void main() {
  group('ensureFolderAccess', () {
    late List<Permission> requested;
    late int explained;

    StorageAccess access({
      required List<bool> writable,
      int? sdk = 34,
      bool grant = true,
    }) {
      var probe = 0;
      return StorageAccess(
        canWrite: (_) async {
          final i = probe < writable.length ? probe : writable.length - 1;
          probe++;
          return writable[i];
        },
        sdkInt: () async => sdk,
        request: (p) async {
          requested.add(p);
          return grant;
        },
      );
    }

    setUp(() {
      requested = [];
      explained = 0;
    });

    Future<bool> agree() async {
      explained++;
      return true;
    }

    Future<bool> refuse() async {
      explained++;
      return false;
    }

    test('writable folder: no dialog, no permission request', () async {
      final result = await access(writable: [true])
          .ensureFolderAccess('/x', explain: agree);
      expect(result, FolderAccess.writable);
      expect(explained, 0);
      expect(requested, isEmpty);
    });

    test('user keeps the current folder: nothing is requested', () async {
      final result = await access(writable: [false])
          .ensureFolderAccess('/x', explain: refuse);
      expect(result, FolderAccess.declined);
      expect(explained, 1);
      expect(requested, isEmpty);
    });

    test('Android 11+ asks for All files access exactly once', () async {
      final result = await access(writable: [false, true])
          .ensureFolderAccess('/x', explain: agree);
      expect(result, FolderAccess.granted);
      expect(requested, [Permission.manageExternalStorage]);
    });

    test('Android 10 and older ask for normal storage access', () async {
      await access(writable: [false, true], sdk: 29)
          .ensureFolderAccess('/x', explain: agree);
      expect(requested, [Permission.storage]);
    });

    test('denied, or granted but still unwritable, is reported', () async {
      expect(
          await access(writable: [false], grant: false)
              .ensureFolderAccess('/x', explain: agree),
          FolderAccess.denied);
      expect(
          await access(writable: [false, false])
              .ensureFolderAccess('/x', explain: agree),
          FolderAccess.denied);
    });

    test('off Android an unwritable folder is denied without asking',
        () async {
      final result = await access(writable: [false], sdk: null)
          .ensureFolderAccess('/x', explain: agree);
      expect(result, FolderAccess.denied);
      expect(explained, 0);
      expect(requested, isEmpty);
    });
  });

  group('canWriteToFolder', () {
    test('true for a writable folder and leaves no probe file', () async {
      final dir = await Directory.systemTemp.createTemp('openlib_probe');
      addTearDown(() => dir.delete(recursive: true));
      expect(await canWriteToFolder(dir.path), isTrue);
      expect(dir.listSync(), isEmpty);
    });

    test('false when the folder cannot be created', () async {
      final file = File(
          '${(await Directory.systemTemp.createTemp('openlib_probe')).path}/f');
      await file.writeAsString('x');
      addTearDown(() => file.parent.delete(recursive: true));
      // A path below a regular file can never be a folder.
      expect(await canWriteToFolder('${file.path}/books'), isFalse);
    });
  });
}
