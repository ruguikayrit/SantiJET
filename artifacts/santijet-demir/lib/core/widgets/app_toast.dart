import 'package:flutter/material.dart';

/// Alt kenardan gelen toast / snackbar — 2 sn sonra kaybolur.
abstract final class AppToast {
  static const duration = Duration(seconds: 2);

  static const _margin = EdgeInsets.fromLTRB(16, 0, 16, 24);

  static void show(
    BuildContext context,
    String message, {
    Color? backgroundColor,
  }) {
    showSnackBar(
      context,
      SnackBar(
        content: Text(message),
        backgroundColor: backgroundColor,
      ),
    );
  }

  /// Mevcut SnackBar çağrılarına alt + 2 sn varsayılanlarını uygular.
  static void showSnackBar(BuildContext context, SnackBar snackBar) {
    final messenger = ScaffoldMessenger.of(context);
    messenger.clearSnackBars();
    messenger.showSnackBar(
      SnackBar(
        content: snackBar.content,
        backgroundColor: snackBar.backgroundColor,
        action: snackBar.action,
        duration: duration,
        behavior: SnackBarBehavior.floating,
        margin: snackBar.margin ?? _margin,
        shape: snackBar.shape ??
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        elevation: snackBar.elevation ?? 6,
        dismissDirection: DismissDirection.down,
        showCloseIcon: snackBar.showCloseIcon,
        closeIconColor: snackBar.closeIconColor,
        width: snackBar.width,
        padding: snackBar.padding,
      ),
    );
  }
}

/// ScaffoldMessenger kısayolu — tüm toast'lar alttan, 2 sn.
extension AppSnackBarMessenger on ScaffoldMessengerState {
  ScaffoldFeatureController<SnackBar, SnackBarClosedReason> showAppSnackBar(
    SnackBar snackBar,
  ) {
    clearSnackBars();
    return showSnackBar(
      SnackBar(
        content: snackBar.content,
        backgroundColor: snackBar.backgroundColor,
        action: snackBar.action,
        duration: AppToast.duration,
        behavior: SnackBarBehavior.floating,
        margin: snackBar.margin ?? const EdgeInsets.fromLTRB(16, 0, 16, 24),
        shape: snackBar.shape ??
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        elevation: snackBar.elevation ?? 6,
        dismissDirection: DismissDirection.down,
        showCloseIcon: snackBar.showCloseIcon,
        closeIconColor: snackBar.closeIconColor,
        width: snackBar.width,
        padding: snackBar.padding,
      ),
    );
  }
}
