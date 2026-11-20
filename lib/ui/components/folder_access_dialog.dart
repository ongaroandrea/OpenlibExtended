// Flutter imports:
import 'package:flutter/material.dart';

// Project imports:
import 'package:openlib/l10n/app_localizations.dart';
import 'package:openlib/services/storage_access.dart';
import 'package:openlib/ui/components/snack_bar_widget.dart';

/// Checks that books can be saved in [dir], asking for storage access only
/// if the folder needs it and the user agrees after reading why.
///
/// Returns true when the folder can be used. On false the caller should
/// keep the current folder; the user has already been told.
Future<bool> ensureBookFolderAccess(
  BuildContext context,
  String dir, {
  StorageAccess access = const StorageAccess(),
}) async {
  final result = await access.ensureFolderAccess(
    dir,
    explain: () => _explain(context),
  );
  switch (result) {
    case FolderAccess.writable:
    case FolderAccess.granted:
      return true;
    case FolderAccess.declined:
    case FolderAccess.denied:
      if (context.mounted) {
        showSnackBar(
          context: context,
          message: AppLocalizations.of(context).folderAccessKeptCurrent,
        );
      }
      return false;
  }
}

Future<bool> _explain(BuildContext context) async {
  if (!context.mounted) return false;
  final l10n = AppLocalizations.of(context);
  final allow = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(l10n.folderAccessTitle),
      content: SingleChildScrollView(child: Text(l10n.folderAccessBody)),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: Text(l10n.folderAccessKeep),
        ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(true),
          child: Text(l10n.folderAccessAllow),
        ),
      ],
    ),
  );
  return allow ?? false;
}
