import 'package:equatable/equatable.dart';

/// 3’lü onay zinciri — Pro RN `approvals`.
class RequestApprovals extends Equatable {
  const RequestApprovals({
    this.sef = false,
    this.mudur = false,
    this.satinAlma = false,
  });

  final bool sef;
  final bool mudur;
  final bool satinAlma;

  bool get allApproved => sef && mudur && satinAlma;

  RequestApprovals copyWith({bool? sef, bool? mudur, bool? satinAlma}) {
    return RequestApprovals(
      sef: sef ?? this.sef,
      mudur: mudur ?? this.mudur,
      satinAlma: satinAlma ?? this.satinAlma,
    );
  }

  Map<String, dynamic> toJson() => {
        'sef': sef,
        'mudur': mudur,
        'satinAlma': satinAlma,
      };

  factory RequestApprovals.fromJson(Map<String, dynamic>? json) {
    if (json == null) return const RequestApprovals();
    return RequestApprovals(
      sef: json['sef'] as bool? ?? false,
      mudur: json['mudur'] as bool? ?? false,
      satinAlma: json['satinAlma'] as bool? ?? false,
    );
  }

  @override
  List<Object?> get props => [sef, mudur, satinAlma];
}
