import 'package:flutter/material.dart';

import '../../../core/design_system/sj_card.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radii.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../domain/entities/daily_report.dart';

/// Kompakt hava durumu satırı — şehir + özet + aksiyonlar.
class WeatherCompactCard extends StatelessWidget {
  const WeatherCompactCard({
    required this.weather,
    required this.date,
    required this.loading,
    required this.cityName,
    required this.onPickCity,
    required this.onEdit,
    required this.onRefresh,
    super.key,
  });

  final DailyReportWeather? weather;
  final String date;
  final bool loading;
  final String? cityName;
  final VoidCallback onPickCity;
  final VoidCallback onEdit;
  final VoidCallback onRefresh;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final locked = weather?.isAutoLocked(date) == true;
    final city = weather?.locationLabel.isNotEmpty == true
        ? weather!.locationLabel
        : (cityName ?? 'Şehir');

    String summary;
    if (loading) {
      summary = 'Hava çekiliyor…';
    } else if (weather == null) {
      summary = 'Şehir seçin veya manuel girin';
    } else {
      final parts = <String>[
        if (weather!.temperatureC != null)
          '${weather!.temperatureC!.toStringAsFixed(0)}°',
        if (weather!.nightTemperatureC != null)
          'gece ${weather!.nightTemperatureC!.toStringAsFixed(0)}°',
        if (weather!.humidityPercent != null)
          '%${weather!.humidityPercent!.toStringAsFixed(0)}',
        if (weather!.description.isNotEmpty) weather!.description,
      ];
      summary = parts.isEmpty ? 'Veri yok' : parts.join(' · ');
      if (!weather!.synced) {
        summary = '$summary · senkron yok';
      } else if (weather!.isManual) {
        summary = '$summary · manuel';
      }
    }

    return SJCard(
      child: Row(
        children: [
          Icon(
            locked ? Icons.lock_outline : Icons.wb_sunny_outlined,
            size: 20,
            color: theme.colorScheme.primary,
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: InkWell(
              onTap: loading ? null : onPickCity,
              borderRadius: AppRadii.sm,
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 2),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            city,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.labelLarge?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        Icon(
                          Icons.expand_more,
                          size: 16,
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                        if (locked) ...[
                          const SizedBox(width: 4),
                          Text(
                            'kilitli',
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: AppColors.info,
                            ),
                          ),
                        ],
                      ],
                    ),
                    Text(
                      summary,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
            ),
          ),
          IconButton(
            tooltip: locked ? 'Manuel müdahale' : 'Manuel gir',
            visualDensity: VisualDensity.compact,
            onPressed: loading ? null : onEdit,
            icon: const Icon(Icons.edit_outlined, size: 18),
          ),
          IconButton(
            tooltip: 'Yenile',
            visualDensity: VisualDensity.compact,
            onPressed: loading ? null : onRefresh,
            icon: loading
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.refresh, size: 18),
          ),
        ],
      ),
    );
  }
}
