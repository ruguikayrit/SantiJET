import 'package:flutter/material.dart';
import 'package:santijet_demir/core/theme/app_colors.dart';
import 'package:santijet_demir/core/widgets/santijet_header.dart';
import 'package:santijet_demir/features/rebar_metraj/widgets/rebar_metraj_panel.dart';

class MetrajScreen extends StatelessWidget {
  const MetrajScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.canvas,
      body: const SafeArea(
        bottom: false,
        child: Column(
          children: [
            SantijetHeader(subtitle: 'Otomatik Metraj', showBack: true),
            Expanded(child: RebarMetrajPanel()),
          ],
        ),
      ),
    );
  }
}
