import 'package:equatable/equatable.dart';

class WorkspaceInfo extends Equatable {
  const WorkspaceInfo({
    required this.id,
    required this.inviteCode,
    required this.companyName,
    required this.apiUrl,
    this.authToken,
    this.revision,
  });

  final String id;
  final String inviteCode;
  final String companyName;
  final String apiUrl;
  final String? authToken;
  final int? revision;

  bool get isLocal => id == 'local';

  WorkspaceInfo copyWith({
    String? id,
    String? inviteCode,
    String? companyName,
    String? apiUrl,
    String? authToken,
    int? revision,
  }) {
    return WorkspaceInfo(
      id: id ?? this.id,
      inviteCode: inviteCode ?? this.inviteCode,
      companyName: companyName ?? this.companyName,
      apiUrl: apiUrl ?? this.apiUrl,
      authToken: authToken ?? this.authToken,
      revision: revision ?? this.revision,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'invite_code': inviteCode,
        'company_name': companyName,
        'api_url': apiUrl,
        if (authToken != null) 'auth_token': authToken,
        if (revision != null) 'revision': revision,
      };

  factory WorkspaceInfo.fromJson(Map<String, dynamic> json) {
    return WorkspaceInfo(
      id: json['id']?.toString() ?? '',
      inviteCode: json['invite_code']?.toString() ?? '',
      companyName: json['company_name']?.toString() ?? '',
      apiUrl: json['api_url']?.toString() ?? '',
      authToken: json['auth_token']?.toString(),
      revision: json['revision'] is int
          ? json['revision'] as int
          : int.tryParse('${json['revision']}'),
    );
  }

  @override
  List<Object?> get props =>
      [id, inviteCode, companyName, apiUrl, authToken, revision];
}
