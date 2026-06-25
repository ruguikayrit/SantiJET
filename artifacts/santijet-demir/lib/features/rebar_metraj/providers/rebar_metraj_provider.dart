import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:santijet_demir/data/services/dxf_rebar_parser.dart';
import 'package:santijet_demir/domain/entities/rebar_metraj.dart';

final rebarMetrajSettingsProvider = StateProvider<RebarMetrajSettings>(
  (ref) => const RebarMetrajSettings(),
);

final dxfRebarParserProvider = Provider<DxfRebarParser>((ref) {
  final settings = ref.watch(rebarMetrajSettingsProvider);
  return DxfRebarParser(settings: settings);
});

final rebarMetrajResultProvider = StateProvider<RebarMetrajResult?>(
  (ref) => null,
);

final rebarMetrajLoadingProvider = StateProvider<bool>((ref) => false);

final rebarMetrajErrorProvider = StateProvider<String?>((ref) => null);
