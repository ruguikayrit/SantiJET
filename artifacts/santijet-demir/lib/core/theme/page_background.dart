import 'package:flutter/material.dart';
import 'package:santijet_demir/core/theme/page_background_web.dart'
    if (dart.library.io) 'package:santijet_demir/core/theme/page_background_io.dart'
    as page_bg;

/// HTML/body arka planını Flutter canvas rengine eşitler (web safe-area boşlukları).
void syncPageBackground(Color color) {
  // ignore: deprecated_member_use
  page_bg.syncPageBackgroundColor(color.value);
}
