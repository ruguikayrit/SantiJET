import 'package:flutter/material.dart';

import '../../core/constants/legal_documents.dart';
import '../../core/design_system/design_system.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';

/// Gizlilik Politikası / Kullanım Koşulları ekranı.
class LegalDocumentScreen extends StatelessWidget {
  const LegalDocumentScreen({required this.documentId, super.key});

  final String documentId;

  @override
  Widget build(BuildContext context) {
    final doc = legalDocumentById(documentId);
    if (doc == null) {
      return Scaffold(
        backgroundColor: AppColors.canvas,
        body: const SafeArea(
          child: SJEmptyState(
            title: 'Belge bulunamadı',
            message: 'İstenen hukuki belge mevcut değil.',
            icon: Icons.error_outline,
          ),
        ),
      );
    }

    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: AppColors.canvas,
      appBar: AppBar(title: Text(doc.title)),
      body: SafeArea(
        top: false,
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.md),
          children: [
            Text(doc.title, style: theme.textTheme.headlineLarge),
            const SizedBox(height: AppSpacing.xxs),
            Text(
              'Güncelleme: ${doc.updatedAt}',
              style: theme.textTheme.labelMedium,
            ),
            const SizedBox(height: AppSpacing.lg),
            for (final section in doc.sections) ...[
              SJCard(
                child: Builder(
                  builder: (context) {
                    final cardTheme = Theme.of(context);
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          section.heading,
                          style: cardTheme.textTheme.titleMedium?.copyWith(
                            color: AppColors.cardTextPrimary,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.xs),
                        Text(
                          section.body,
                          style: cardTheme.textTheme.bodyMedium?.copyWith(
                            height: 1.5,
                            color: AppColors.cardTextSecondary,
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
            ],
          ],
        ),
      ),
    );
  }
}
