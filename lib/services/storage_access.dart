// Storage access for the book folder.
//
// The app's default book folder (its own external files directory) and
// Android's shared Download/ and Documents/ folders are writable without
// any permission. Only other shared folders (for example /Books, which
// e-reader libraries scan) need Android's "All files access". So instead
// of asking for that up front, the app first tries writing to the folder
// the user picked and asks only if that fails - after explaining why.

// Dart imports:
import 'dart:io';

// Package imports:
import 'package:device_info_plus/device_info_plus.dart';
import 'package:permission_handler/permission_handler.dart';

/// Android 11 (API 30) is where scoped storage makes "All files access"
/// (MANAGE_EXTERNAL_STORAGE) the only way to write outside the app's own
/// and the Download/Documents folders.
const allFilesAccessMinSdk = 30;

/// Result of [StorageAccess.ensureFolderAccess].
enum FolderAccess {
  /// Already writable; nothing was requested.
  writable,

  /// Writable after the user granted the storage permission.
  granted,

  /// The user declined in the explanation dialog; nothing was requested.
  declined,

  /// The permission was requested but the folder still isn't writable.
  denied,
}

class StorageAccess {
  /// Whether the app can create files in the folder right now.
  final Future<bool> Function(String dir) canWrite;

  /// Android SDK level; null off Android.
  final Future<int?> Function() sdkInt;

  /// Requests [permission] once and reports whether it was granted.
  final Future<bool> Function(Permission permission) request;

  const StorageAccess({
    this.canWrite = canWriteToFolder,
    this.sdkInt = _androidSdkInt,
    this.request = _requestOnce,
  });

  /// Makes sure books can be saved in [dir].
  ///
  /// Asks for a storage permission only when the folder isn't writable
  /// already, and only after [explain] returns true (the user agreed in a
  /// dialog that says why). Each permission is requested at most once.
  Future<FolderAccess> ensureFolderAccess(
    String dir, {
    required Future<bool> Function() explain,
  }) async {
    if (await canWrite(dir)) return FolderAccess.writable;

    final sdk = await sdkInt();
    // Not Android (desktop/iOS): permissions don't apply, so a folder we
    // can't write to stays unwritable.
    if (sdk == null) return FolderAccess.denied;

    if (!await explain()) return FolderAccess.declined;

    final permission = sdk >= allFilesAccessMinSdk
        ? Permission.manageExternalStorage
        : Permission.storage;
    final granted = await request(permission);
    if (granted && await canWrite(dir)) return FolderAccess.granted;
    return FolderAccess.denied;
  }
}

/// Tries to create and delete a hidden probe file in [dir].
Future<bool> canWriteToFolder(String dir) async {
  try {
    final folder = Directory(dir);
    if (!await folder.exists()) await folder.create(recursive: true);
    final probe = File(
        '${folder.path}${Platform.pathSeparator}.openlib_write_test_'
        '${DateTime.now().microsecondsSinceEpoch}');
    await probe.writeAsString('');
    await probe.delete();
    return true;
  } catch (_) {
    return false;
  }
}

Future<int?> _androidSdkInt() async {
  if (!Platform.isAndroid) return null;
  final info = await DeviceInfoPlugin().androidInfo;
  return info.version.sdkInt;
}

Future<bool> _requestOnce(Permission permission) async {
  final status = await permission.request();
  return status.isGranted;
}
