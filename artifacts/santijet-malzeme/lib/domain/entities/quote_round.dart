import 'package:equatable/equatable.dart';

import 'supplier_quote.dart';

/// Hive typeId plan: 6
/// Aynı talep için N firma teklif turu.
class QuoteRound extends Equatable {
  const QuoteRound({
    required this.id,
    required this.projectId,
    required this.requestId,
    this.title = 'Teklif turu',
    this.createdAt,
    this.quotes = const [],
  });

  final String id;
  final String projectId;
  final String requestId;
  final String title;
  final DateTime? createdAt;
  final List<SupplierQuote> quotes;

  QuoteRound copyWith({
    String? id,
    String? projectId,
    String? requestId,
    String? title,
    DateTime? createdAt,
    List<SupplierQuote>? quotes,
  }) {
    return QuoteRound(
      id: id ?? this.id,
      projectId: projectId ?? this.projectId,
      requestId: requestId ?? this.requestId,
      title: title ?? this.title,
      createdAt: createdAt ?? this.createdAt,
      quotes: quotes ?? this.quotes,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'projectId': projectId,
        'requestId': requestId,
        'title': title,
        'createdAt': createdAt?.toIso8601String(),
        'quotes': quotes.map((e) => e.toJson()).toList(),
      };

  factory QuoteRound.fromJson(Map<String, dynamic> json) => QuoteRound(
        id: json['id'] as String,
        projectId: json['projectId'] as String? ?? '',
        requestId: json['requestId'] as String? ?? '',
        title: json['title'] as String? ?? 'Teklif turu',
        createdAt: json['createdAt'] != null
            ? DateTime.tryParse(json['createdAt'] as String)
            : null,
        quotes: (json['quotes'] as List? ?? const [])
            .map(
              (e) =>
                  SupplierQuote.fromJson(Map<String, dynamic>.from(e as Map)),
            )
            .toList(),
      );

  @override
  List<Object?> get props =>
      [id, projectId, requestId, title, createdAt, quotes];
}
