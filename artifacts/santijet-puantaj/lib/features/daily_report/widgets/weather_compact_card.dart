import 'package:flutter/material.dart';

import '../../../core/design_system/sj_card.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radii.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../domain/entities/daily_report.dart';

/// Kompakt hava durumu — açılır/kapanır başlık.
class WeatherCompactCard extends StatefulWidget {
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
  State<WeatherCompactCard> createState() => _WeatherCompactCardState();
}

class _WeatherCompactCardState extends State<WeatherCompactCard> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final weather = widget.weather;
    final locked = weather?.isAutoLocked(widget.date) == true;
    final city = weather?.locationLabel.isNotEmpty == true
        ? weather!.locationLabel
        : (widget.cityName ?? 'Şehir');

    String summary;
    if (widget.loading) {
      summary = 'Hava çekiliyor…';
    } else if (weather == null) {
      summary = 'Şehir seçin veya manuel girin';
    } else {
      final parts = <String>[
        if (weather.temperatureC != null)
          '${weather.temperatureC!.toStringAsFixed(0)}°',
        if (weather.nightTemperatureC != null)
          'gece ${weather.nightTemperatureC!.toStringAsFixed(0)}°',
        if (weather.maxHumidityPercent != null)
          'max nem %${weather.maxHumidityPercent!.toStringAsFixed(0)}'
        else if (weather.humidityPercent != null)
          'nem %${weather.humidityPercent!.toStringAsFixed(0)}',
        if (weather.windGustKmh != null)
          'ani ${weather.windGustKmh!.toStringAsFixed(0)} km/s'
        else if (weather.windKmh != null)
          'rüzgar ${weather.windKmh!.toStringAsFixed(0)} km/s',
        if (weather.description.isNotEmpty) weather.description,
      ];
      summary = parts.isEmpty ? 'Veri yok' : parts.join(' · ');
      if (!weather.synced) {
        summary = '$summary · senkron yok';
      } else if (weather.isManual) {
        summary = '$summary · manuel';
      }
    }

    final ink = AppColors.cardTextPrimary;
    final inkMuted = AppColors.cardTextMuted;
    final inkSecondary = AppColors.cardTextSecondary;

    return SJCard(
      child: Builder(
        builder: (context) {
          final theme = Theme.of(context);
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              InkWell(
                onTap: () => setState(() => _expanded = !_expanded),
                borderRadius: AppRadii.sm,
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2),
                  child: Row(
                    children: [
                      Icon(
                        locked ? Icons.lock_outline : Icons.wb_sunny_outlined,
                        size: 20,
                        color: theme.colorScheme.primary,
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Hava durumu',
                              style: theme.textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.w700,
                                color: ink,
                              ),
                            ),
                            if (!_expanded)
                              Text(
                                summary,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: inkMuted,
                                ),
                              ),
                          ],
                        ),
                      ),
                      Icon(
                        _expanded ? Icons.expand_less : Icons.expand_more,
                        size: 20,
                        color: inkSecondary,
                      ),
                    ],
                  ),
                ),
              ),
              if (_expanded) ...[
                const SizedBox(height: AppSpacing.sm),
                Row(
                  children: [
                    Expanded(
                      child: InkWell(
                        onTap: widget.loading ? null : widget.onPickCity,
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
                                      style:
                                          theme.textTheme.labelLarge?.copyWith(
                                        fontWeight: FontWeight.w700,
                                        color: ink,
                                      ),
                                    ),
                                  ),
                                  Icon(
                                    Icons.expand_more,
                                    size: 16,
                                    color: inkSecondary,
                                  ),
                                  if (locked) ...[
                                    const SizedBox(width: 4),
                                    Text(
                                      'kilitli',
                                      style:
                                          theme.textTheme.labelSmall?.copyWith(
                                        color: AppColors.statusInkOnCard(
                                          AppColors.info,
                                        ),
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                              Text(
                                summary,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: inkMuted,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    IconButton(
                      tooltip: locked ? 'Manuel müdahale' : 'Manuel gir',
                      visualDensity: VisualDensity.compact,
                      onPressed: widget.loading ? null : widget.onEdit,
                      icon: Icon(
                        Icons.edit_outlined,
                        size: 18,
                        color: inkSecondary,
                      ),
                    ),
                    IconButton(
                      tooltip: 'Yenile',
                      visualDensity: VisualDensity.compact,
                      onPressed: widget.loading ? null : widget.onRefresh,
                      icon: widget.loading
                          ? SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: inkSecondary,
                              ),
                            )
                          : Icon(
                              Icons.refresh,
                              size: 18,
                              color: inkSecondary,
                            ),
                    ),
                  ],
                ),
              ],
            ],
          );
        },
      ),
    );
  }
}
