import 'package:flutter/material.dart';
import 'package:santijet_demir/features/survey/imalat_flow_screen.dart';

class SurveyDetailScreen extends StatelessWidget {
  const SurveyDetailScreen({super.key, required this.imalatId});

  final String imalatId;

  @override
  Widget build(BuildContext context) {
    return ImalatFlowScreen(imalatId: imalatId);
  }
}
