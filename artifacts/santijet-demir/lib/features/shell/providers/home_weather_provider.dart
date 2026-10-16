import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:santijet_demir/data/services/home_weather_service.dart';
import 'package:santijet_demir/features/projects/providers/project_provider.dart';

final homeWeatherProvider = FutureProvider<HomeWeatherSnapshot?>((ref) async {
  final project = ref.watch(activeProjectProvider);
  final location = project?.location ?? 'İstanbul';
  try {
    return await HomeWeatherService.fetchForLocation(location);
  } catch (_) {
    return null;
  }
});
