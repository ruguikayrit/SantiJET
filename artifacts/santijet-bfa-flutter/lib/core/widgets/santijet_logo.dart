import 'package:flutter/material.dart';

/// ŞantiJET S/yıldırım marka ikonu — React Native `SantijetLogo` kırpma sabitleriyle hizalı.
class SantijetLogo extends StatelessWidget {
  const SantijetLogo({
    super.key,
    this.iconHeight = 44,
  });

  final double iconHeight;

  static const _asset = 'assets/images/santijet-icon.png';

  static const _boltXStart = 0.24;
  static const _boltXEnd = 0.76;
  static const _boltYStart = 0.06;
  static const _boltYEnd = 0.635;

  @override
  Widget build(BuildContext context) {
    final boltImgH = iconHeight / (_boltYEnd - _boltYStart);
    final boltImgW = boltImgH;
    final boltLeft = _boltXStart * boltImgW;
    final boltTop = _boltYStart * boltImgH;
    final boltDispW = (_boltXEnd - _boltXStart) * boltImgW;

    return SizedBox(
      width: boltDispW,
      height: iconHeight,
      child: ClipRect(
        child: OverflowBox(
          alignment: Alignment.topLeft,
          minWidth: boltImgW,
          maxWidth: boltImgW,
          minHeight: boltImgH,
          maxHeight: boltImgH,
          child: Transform.translate(
            offset: Offset(-boltLeft, -boltTop),
            child: Image.asset(
              _asset,
              width: boltImgW,
              height: boltImgH,
              fit: BoxFit.fill,
              filterQuality: FilterQuality.high,
            ),
          ),
        ),
      ),
    );
  }
}
