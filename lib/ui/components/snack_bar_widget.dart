// Flutter imports:
import 'package:flutter/material.dart';

// Project imports:
import 'package:openlib/features/eink/eink.dart' show EinkColorX;

void showSnackBar({required BuildContext context, required String message}) {
  final messenger = ScaffoldMessenger.of(context);
  messenger.clearSnackBars();
  messenger.showSnackBar(SnackBar(
    showCloseIcon: true,
    closeIconColor: Colors.white.einkBg(context),
    content: Text(
      message,
      style: TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.bold,
        color: Colors.white.einkBg(context),
      ),
      textAlign: TextAlign.center,
    ),
    // ignore: use_build_context_synchronously
    backgroundColor: Theme.of(context).colorScheme.secondary,
    width: 300,
    shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(50))),
    behavior: SnackBarBehavior.floating,
  ));
}
