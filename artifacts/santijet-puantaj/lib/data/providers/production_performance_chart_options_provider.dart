import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';

import '../../core/theme/theme_mode_provider.dart';
import '../services/production_performance_chart_options.dart';

class ProductionPerformanceChartOptionsNotifier
    extends StateNotifier<ProductionPerformanceChartOptions> {
  ProductionPerformanceChartOptionsNotifier(this._box) : super(_load(_box));

  final Box _box;
  static const _key = 'production_performance_chart_options';

  static ProductionPerformanceChartOptions _load(Box box) {
    final raw = box.get(_key);
    if (raw is String && raw.isNotEmpty) {
      try {
        final decoded = jsonDecode(raw);
        if (decoded is Map) {
          return ProductionPerformanceChartOptions.fromJson(
            Map<String, dynamic>.from(decoded),
          );
        }
      } catch (_) {}
    }
    return const ProductionPerformanceChartOptions();
  }

  void save(ProductionPerformanceChartOptions options) {
    state = options;
    _box.put(_key, jsonEncode(options.toJson()));
  }
}

final productionPerformanceChartOptionsProvider = StateNotifierProvider<
    ProductionPerformanceChartOptionsNotifier,
    ProductionPerformanceChartOptions>((ref) {
  return ProductionPerformanceChartOptionsNotifier(
    ref.watch(settingsBoxProvider),
  );
});
