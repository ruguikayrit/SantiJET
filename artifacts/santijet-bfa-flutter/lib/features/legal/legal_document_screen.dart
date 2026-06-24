import 'package:flutter/material.dart';

import '../../core/constants/legal_documents.dart';
import '../../core/design_system/design_system.dart';
import '../../core/theme/app_spacing.dart';

/// Gizlilik Politikası / Kullanım Koşulları ekranı.
class LegalDocumentScreen extends StatelessWidget {
  const LegalDocumentScreen({required this.documentId, super.key});

  final String documentId;

  @override
  Widget build(BuildContext context) {
    final doc = legalDocumentById(documentId);
    if (doc == null) {
      return const Scaffold(
        body: SafeArea(
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
      appBar: AppBar(title: Text(doc.title)),
      body: SafeArea(
        top: false,
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.md),
          children: [
            Text(doc.title, style: theme.textTheme.headlineLarge),
            const SizedBox(height: AppSpacing.xxs),
            Text('Güncelleme: ${doc.updatedAt}',
                style: theme.textTheme.labelMedium),
            const SizedBox(height: AppSpacing.lg),
            for (final section in doc.sections) ...[
              SJCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(section.heading, style: theme.textTheme.titleMedium),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      section.body,
                      style: theme.textTheme.bodyMedium?.copyWith(height: 1.5),
                    ),
                  ],
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
