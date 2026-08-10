import 'package:equatable/equatable.dart';

class BudgetEntry extends Equatable {
  const BudgetEntry({
    required this.id,
    required this.projectId,
    required this.type,
    required this.category,
    required this.description,
    required this.amount,
    required this.date,
  });

  final String id;
  final String projectId;
  final String type; // income | expense
  final String category;
  final String description;
  final double amount;
  final String date;

  BudgetEntry copyWith({
    String? id,
    String? projectId,
    String? type,
    String? category,
    String? description,
    double? amount,
    String? date,
  }) {
    return BudgetEntry(
      id: id ?? this.id,
      projectId: projectId ?? this.projectId,
      type: type ?? this.type,
      category: category ?? this.category,
      description: description ?? this.description,
      amount: amount ?? this.amount,
      date: date ?? this.date,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'projectId': projectId,
        'type': type,
        'category': category,
        'description': description,
        'amount': amount,
        'date': date,
      };

  factory BudgetEntry.fromJson(Map<String, dynamic> json) {
    return BudgetEntry(
      id: json['id']?.toString() ?? '',
      projectId: json['projectId']?.toString() ?? '',
      type: json['type']?.toString() ?? 'expense',
      category: json['category']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      amount: (json['amount'] as num?)?.toDouble() ?? 0,
      date: json['date']?.toString() ?? '',
    );
  }

  @override
  List<Object?> get props =>
      [id, projectId, type, category, description, amount, date];
}
