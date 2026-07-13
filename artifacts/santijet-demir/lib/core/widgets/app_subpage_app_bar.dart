import 'package:flutter/material.dart';
import 'package:santijet_demir/core/responsive/app_safe_area.dart';
import 'package:santijet_demir/core/theme/app_colors.dart';
import 'package:santijet_demir/core/theme/app_typography.dart';

/// Alt sayfa üst çubuğu: güvenli alan + tek satır başlık.
/// Scaffold'ta `primary: false` kullanın (çift safe-area önlenir).
PreferredSizeWidget appSubpageAppBar(
  BuildContext context, {
  required Widget title,
  List<Widget>? actions,
  VoidCallback? onBack,
  Color? backgroundColor,
}) {
  final topInset = AppSafeAreaInsets.topOf(context);
  const rowHeight = kToolbarHeight;

  return PreferredSize(
    preferredSize: Size.fromHeight(topInset + rowHeight),
    child: Material(
      color: backgroundColor ?? AppColors.canvas,
      child: SizedBox(
        height: topInset + rowHeight,
        child: Padding(
          padding: EdgeInsets.only(top: topInset),
          child: NavigationToolbar(
            leading: BackButton(
              onPressed: onBack ?? () => Navigator.maybePop(context),
            ),
            middle: title,
            trailing: actions == null
                ? null
                : Row(mainAxisSize: MainAxisSize.min, children: actions),
            centerMiddle: false,
          ),
        ),
      ),
    ),
  );
}

PreferredSizeWidget appSubpageTitleAppBar(
  BuildContext context, {
  required String title,
  String? subtitle,
  List<Widget>? actions,
  VoidCallback? onBack,
  Color? backgroundColor,
}) {
  return appSubpageAppBar(
    context,
    onBack: onBack,
    actions: actions,
    backgroundColor: backgroundColor,
    title: subtitle == null
        ? Text(title, style: AppTypography.titleLarge)
        : Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(title, style: AppTypography.titleLarge),
              Text(subtitle, style: AppTypography.labelMedium),
            ],
          ),
  );
}

/// Sekmeli alt sayfa: güvenli alan + geri ok sekmelerle aynı hizada.
/// Scaffold'ta `primary: false` kullanın (çift safe-area önlenir).
PreferredSizeWidget appTabbedSubpageAppBar(
  BuildContext context, {
  required Widget tabBar,
  List<Widget>? actions,
  VoidCallback? onBack,
  Color? backgroundColor,
  double tabBarHeight = 48,
}) {
  final topInset = AppSafeAreaInsets.topOf(context);

  return PreferredSize(
    preferredSize: Size.fromHeight(topInset + tabBarHeight),
    child: Material(
      color: backgroundColor ?? AppColors.canvas,
      child: SizedBox(
        height: topInset + tabBarHeight,
        child: Column(
          children: [
            SizedBox(height: topInset),
            SizedBox(
              height: tabBarHeight,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  SizedBox(
                    width: 48,
                    child: IconButton(
                      icon: const Icon(Icons.arrow_back),
                      tooltip: 'Geri',
                      onPressed: onBack ?? () => Navigator.maybePop(context),
                    ),
                  ),
                  Expanded(child: tabBar),
                  if (actions != null) ...actions,
                ],
              ),
            ),
          ],
        ),
      ),
    ),
  );
}
