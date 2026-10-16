import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:santijet_demir/core/routing/app_routes.dart';
import 'package:santijet_demir/core/theme/app_colors.dart';
import 'package:santijet_demir/core/theme/app_typography.dart';

class SantijetHeader extends StatelessWidget {
  const SantijetHeader({
    super.key,
    this.subtitle,
    this.showWordmark = false,
    this.showNotification = false,
    this.showAvatar = true,
    this.avatarInitial,
    this.onCreateReport,
    this.onImport,
    this.showBack = false,
  });

  /// Ana sayfa DEMİR — wordmark altı ürün adı (%50 büyütülmüş).
  static const homeDemirScale = 1.875; // 1.25 × 1.5
  static const homeDemirLetterSpacing = 0.75;
  static const _homeWordmarkToDemirGap = 6.0;

  /// Sağ aksiyon — diğer uygulamalarla aynı çark ikonu.
  static const actionSize = 40.0;
  static const actionIconSize = 22.0;

  /// İç sayfa başlık bandının alt laciverti.
  static const pageHeaderBandColor = AppColors.headerNavyBottom;

  final String? subtitle;
  final bool showWordmark;
  /// Kullanılmıyor — API uyumu için tutuluyor; bildirim zili kaldırıldı.
  final bool showNotification;
  final bool showAvatar;
  /// Kullanılmıyor — API uyumu için tutuluyor (çark ikonu avatar yerine).
  final String? avatarInitial;
  /// Verilirse dişlinin solunda rapor oluşturma butonu gösterilir.
  final VoidCallback? onCreateReport;
  /// Verilirse dişlinin solunda içe aktar butonu gösterilir.
  final VoidCallback? onImport;
  /// Ayarlardan açılan sayfalarda geri oku.
  final bool showBack;

  @override
  Widget build(BuildContext context) {
    return DemirBrandHeader(
      title: showWordmark ? null : subtitle,
      showBack: showBack,
      showSettings: showAvatar,
      onCreateReport: onCreateReport,
      onImport: onImport,
    );
  }
}

/// Tüm sayfa başlıklarında kullanılan Proje ritmi zemini.
abstract final class DemirHeaderChrome {
  static const decoration = BoxDecoration(
    gradient: LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [Color(0xFF0F2744), Color(0xFF071526)],
    ),
  );
}

/// AppBar’ın arkasında lacivert geçişi doldurur.
class DemirHeaderBackdrop extends StatelessWidget {
  const DemirHeaderBackdrop({super.key});

  @override
  Widget build(BuildContext context) {
    return const DecoratedBox(
      decoration: DemirHeaderChrome.decoration,
      child: SizedBox.expand(),
    );
  }
}

/// Lacivert geçişli sayfa başlığı.
class DemirAppBar extends AppBar {
  DemirAppBar({
    super.key,
    super.leading,
    super.automaticallyImplyLeading,
    super.title,
    super.actions,
    super.bottom,
    super.toolbarHeight,
  }) : super(
          backgroundColor: Colors.transparent,
          surfaceTintColor: Colors.transparent,
          elevation: 0,
          scrolledUnderElevation: 0,
          systemOverlayStyle: SystemUiOverlayStyle.light,
          flexibleSpace: const DemirHeaderBackdrop(),
        );
}

/// Wordmark veya sayfa adı. Arka plan lacivert geçiştir.
class DemirBrandHeader extends StatelessWidget {
  const DemirBrandHeader({
    super.key,
    this.title,
    this.caption,
    this.showWordmark = false,
    this.showBack = false,
    this.showSettings = true,
    this.onCreateReport,
    this.onImport,
  });

  final String? title;
  final String? caption;
  final bool showWordmark;
  final bool showBack;
  final bool showSettings;
  final VoidCallback? onCreateReport;
  final VoidCallback? onImport;

  @override
  Widget build(BuildContext context) {
    final top = MediaQuery.paddingOf(context).top;
    final canBack = showBack && context.canPop();

    if (showWordmark) {
      return Container(
        color: SantijetHomeBrand.homeBandColor,
        padding: EdgeInsets.fromLTRB(16, top + 8, 12, 12),
        child: Row(
          children: [
            const Expanded(child: _WordmarkLockup()),
            if (showSettings) const _HeaderSettingsButton(onDarkBand: true),
          ],
        ),
      );
    }

    return DecoratedBox(
      decoration: DemirHeaderChrome.decoration,
      child: Padding(
        padding: EdgeInsets.fromLTRB(canBack ? 4 : 14, top + 8, 6, 11),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            if (canBack)
              IconButton(
                tooltip: 'Geri',
                onPressed: () => context.pop(),
                padding: EdgeInsets.zero,
                visualDensity: VisualDensity.compact,
                constraints: const BoxConstraints.tightFor(width: 40, height: 40),
                icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 18),
              ),
            Expanded(
              child: _PageTitleLockup(title: title, caption: caption),
            ),
            if (onCreateReport != null)
              _HeaderReportButton(onDarkBand: true, onPressed: onCreateReport!),
            if (onImport != null) ...[
              const SizedBox(width: 4),
              _HeaderTextButton(
                onDarkBand: true,
                onPressed: onImport!,
                label: 'İçe Aktar',
                icon: Icons.download_outlined,
                semanticsLabel: 'İçe aktar',
              ),
            ],
            if (showSettings) const _HeaderSettingsButton(onDarkBand: true),
          ],
        ),
      ),
    );
  }
}

class _WordmarkLockup extends StatelessWidget {
  const _WordmarkLockup();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Flexible(
          child: Image.asset(
            SantijetHomeBrand.darkWordmarkAsset,
            height: 28,
            fit: BoxFit.contain,
            alignment: Alignment.centerLeft,
            errorBuilder: (_, __, ___) => Text(
              'ŞantiJET',
              style: GoogleFonts.rajdhani(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          'DEMİR',
          style: GoogleFonts.inter(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.75,
          ),
        ),
      ],
    );
  }
}

class _PageTitleLockup extends StatelessWidget {
  const _PageTitleLockup({required this.title, required this.caption});

  final String? title;
  final String? caption;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Image.asset(
          'assets/images/splash_bolt.png',
          width: 42.5,
          height: 40,
          fit: BoxFit.contain,
          filterQuality: FilterQuality.high,
        ),
        const SizedBox(width: 7.5),
        Expanded(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title?.trim().isNotEmpty == true ? title! : 'ŞantiJET',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.inter(
                  color: Colors.white,
                  fontSize: 21,
                  fontWeight: FontWeight.w800,
                  height: 1.1,
                ),
              ),
              if (caption != null && caption!.trim().isNotEmpty) ...[
                const SizedBox(height: 3),
                Text(
                  caption!,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.inter(
                    color: Colors.white.withValues(alpha: 0.66),
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

/// Puantaj / Beton / BFA ile aynı — sağ üst ayarlar çarkı.
class _HeaderSettingsButton extends StatelessWidget {
  const _HeaderSettingsButton({this.onDarkBand = false});

  final bool onDarkBand;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Ayarlar',
      button: true,
      child: SizedBox(
        width: SantijetHeader.actionSize,
        height: SantijetHeader.actionSize,
        child: IconButton(
          onPressed: () => GoRouter.of(context).push(AppRoutes.settings),
          padding: EdgeInsets.zero,
          visualDensity: VisualDensity.compact,
          constraints: const BoxConstraints.tightFor(
            width: SantijetHeader.actionSize,
            height: SantijetHeader.actionSize,
          ),
          iconSize: SantijetHeader.actionIconSize,
          icon: Icon(
            Icons.settings_outlined,
            color: onDarkBand
                ? Colors.white.withValues(alpha: 0.88)
                : AppColors.textSecondary,
          ),
        ),
      ),
    );
  }
}

class _HeaderReportButton extends StatelessWidget {
  const _HeaderReportButton({
    required this.onDarkBand,
    required this.onPressed,
  });

  final bool onDarkBand;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return _HeaderTextButton(
      onDarkBand: onDarkBand,
      onPressed: onPressed,
      label: 'Rapor',
      icon: Icons.description_outlined,
      semanticsLabel: 'Rapor oluştur',
    );
  }
}

class _HeaderTextButton extends StatelessWidget {
  const _HeaderTextButton({
    required this.onDarkBand,
    required this.onPressed,
    required this.label,
    required this.icon,
    required this.semanticsLabel,
  });

  final bool onDarkBand;
  final VoidCallback onPressed;
  final String label;
  final IconData icon;
  final String semanticsLabel;

  @override
  Widget build(BuildContext context) {
    final foreground = onDarkBand
        ? Colors.white.withValues(alpha: 0.92)
        : AppColors.textSecondary;
    final border = onDarkBand
        ? Colors.white.withValues(alpha: 0.28)
        : AppColors.border;

    return Semantics(
      label: semanticsLabel,
      button: true,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(8),
          child: Container(
            height: 32,
            padding: const EdgeInsets.symmetric(horizontal: 10),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: border),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, size: 16, color: foreground),
                const SizedBox(width: 6),
                Text(
                  label,
                  style: AppTypography.labelMedium.copyWith(
                    color: foreground,
                    fontWeight: FontWeight.w700,
                    height: 1,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}


TextStyle get _demirTitleStyle => AppTypography.titleMedium.copyWith(
      letterSpacing: 1.2,
      fontWeight: FontWeight.w700,
      height: 1.0,
      color: AppColors.textPrimary,
    );

/// Wordmark metrikleri için kilitli marka ölçeği (global scale’ten bağımsız).
TextStyle get _brandMetricStyle => _demirTitleStyle.copyWith(
      fontSize: AppTypography.brandScale * 14,
    );

/// Wordmark altındaki DEMİR — marka ölçeğinde, homeDemirScale ile büyütülür.
TextStyle get _homeDemirTitleStyle => _demirTitleStyle.copyWith(
      fontSize: AppTypography.brandScale *
          14 *
          SantijetHeader.homeDemirScale,
      letterSpacing: SantijetHeader.homeDemirLetterSpacing,
    );

/// Ana sayfa wordmark + DEMİR — güncelleme öncesi kilitli ölçek.
abstract final class SantijetHomeBrand {
  static const darkWordmarkAsset = 'assets/images/splash_wordmark.png';

  /// Ana sayfa marka bandı — PRO klasik tema `secondary` ile aynı.
  static const homeBandColor = Color(0xFF16213E);
  static const wordmarkToDemirGap = SantijetHeader._homeWordmarkToDemirGap;

  static double wordmarkHeightOf(BuildContext context) =>
      _BrandTitleMetrics.wordmarkHeightOf(context);

  static double demirIndentOf(BuildContext context) =>
      _BrandTitleMetrics.demirIndentOf(context);

  /// Lacivert banttaki koyu wordmark — açık temada da aynı girinti.
  static double darkDemirIndentOf(BuildContext context) {
    return wordmarkHeightOf(context) *
        (_BrandTitleMetrics._darkWordmarkLeftInkPx /
            _BrandTitleMetrics._darkWordmarkPixelHeight);
  }

  static TextStyle demirStyle({Color? color}) {
    final style = _homeDemirTitleStyle;
    return color == null ? style : style.copyWith(color: color);
  }
}

abstract final class _BrandTitleMetrics {
  /// Wordmark harf doluluk oranı — açık/koyu aynı görsel ölçek.
  static const wordmarkLetterFillRatio = 0.55;
  static const _wordmarkHeightScale = 2.5;

  /// Açık wordmark asset (splash_wordmark_light.png).
  static const _lightWordmarkPixelHeight = 157.0;
  static const _lightWordmarkLeftInkPx = 12.0;

  /// Koyu wordmark — kullanıcının referans tipografisinden kesilmiş
  /// (splash_wordmark.png, OPERASYON YÖNETİMİ yok).
  static const _darkWordmarkPixelHeight = 150.0;
  static const _darkWordmarkLeftInkPx = 12.0;

  static double wordmarkHeightOf(BuildContext context) {
    final textPainter = TextPainter(
      text: TextSpan(text: 'DEMİR', style: _brandMetricStyle),
      textDirection: Directionality.of(context),
      maxLines: 1,
    )..layout();
    final demirCapHeight = textPainter.computeLineMetrics().first.ascent;
    // Marka ölçeğine kilitli — global tipografi değişince wordmark büyümez.
    // Açık/koyu asset farklı piksel boyutunda olsa da aynı görsel yükseklik.
    return demirCapHeight / wordmarkLetterFillRatio * _wordmarkHeightScale;
  }

  static double demirIndentOf(BuildContext context) {
    final isLight = Theme.of(context).brightness == Brightness.light;
    final leftInk =
        isLight ? _lightWordmarkLeftInkPx : _darkWordmarkLeftInkPx;
    final pixelHeight =
        isLight ? _lightWordmarkPixelHeight : _darkWordmarkPixelHeight;
    return wordmarkHeightOf(context) * (leftInk / pixelHeight);
  }
}
