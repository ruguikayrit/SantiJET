import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../domain/models/workspace_info.dart';

enum SyncStatus {
  idle,
  syncing,
  success,
  error,
  conflict,
  authError,
}

/// Çalışma alanı HTTP API — RN workspace uçları ile aynı.
class WorkspaceApi {
  WorkspaceApi({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;

  /// Varsayılan API kökü (gelişmiş ayarda değiştirilebilir).
  static const defaultApiUrl = 'https://santijet-api.example.com';

  static final WorkspaceApi _shared = WorkspaceApi();

  /// POST /api/workspaces
  static Future<WorkspaceInfo> create({
    required String companyName,
    required String password,
    required String apiUrl,
  }) {
    return _shared.createWorkspace(
      apiUrl: apiUrl,
      companyName: companyName,
      password: password,
    );
  }

  /// POST /api/workspaces/:code/join
  static Future<WorkspaceInfo> join({
    required String inviteCode,
    required String password,
    required String apiUrl,
  }) {
    return _shared.joinWorkspace(
      apiUrl: apiUrl,
      inviteCode: inviteCode,
      password: password,
    );
  }

  Map<String, String> _headers(WorkspaceInfo? ws) {
    final h = <String, String>{'Content-Type': 'application/json'};
    final token = ws?.authToken;
    if (token != null && token.isNotEmpty) {
      h['Authorization'] = 'Bearer $token';
    }
    return h;
  }

  String _base(String apiUrl) => apiUrl.replaceAll(RegExp(r'/$'), '');

  /// POST /api/workspaces
  Future<WorkspaceInfo> createWorkspace({
    required String apiUrl,
    required String companyName,
    required String password,
  }) async {
    final base = _base(apiUrl);
    final res = await _client
        .post(
          Uri.parse('$base/api/workspaces'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'company_name': companyName,
            'password': password,
          }),
        )
        .timeout(const Duration(seconds: 15));
    if (res.statusCode < 200 || res.statusCode >= 300) {
      final err = _tryError(res.body);
      throw WorkspaceApiException(err ?? 'Çalışma alanı oluşturulamadı (HTTP ${res.statusCode}).');
    }
    final data = jsonDecode(res.body) as Map<String, dynamic>;
    return WorkspaceInfo(
      id: data['id']?.toString() ?? '',
      inviteCode: data['invite_code']?.toString() ?? '',
      companyName: data['company_name']?.toString() ?? companyName,
      apiUrl: base,
      revision: data['revision'] is int
          ? data['revision'] as int
          : int.tryParse('${data['revision']}'),
      authToken: data['auth_token']?.toString(),
    );
  }

  /// POST /api/workspaces/:code/join
  Future<WorkspaceInfo> joinWorkspace({
    required String apiUrl,
    required String inviteCode,
    required String password,
  }) async {
    final base = _base(apiUrl);
    final code = inviteCode.trim().toUpperCase();
    final res = await _client
        .post(
          Uri.parse('$base/api/workspaces/$code/join'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({'password': password}),
        )
        .timeout(const Duration(seconds: 15));
    if (res.statusCode < 200 || res.statusCode >= 300) {
      final err = _tryError(res.body);
      throw WorkspaceApiException(err ?? 'Davet kodu veya şifre hatalı.');
    }
    final data = jsonDecode(res.body) as Map<String, dynamic>;
    return WorkspaceInfo(
      id: data['id']?.toString() ?? '',
      inviteCode: data['invite_code']?.toString() ?? code,
      companyName: data['company_name']?.toString() ?? '',
      apiUrl: base,
      revision: data['revision'] is int
          ? data['revision'] as int
          : int.tryParse('${data['revision']}'),
      authToken: data['auth_token']?.toString(),
    );
  }

  /// POST .../push
  Future<PushResult> push({
    required WorkspaceInfo workspace,
    required Map<String, dynamic> statePayload,
  }) async {
    if (workspace.isLocal) {
      return const PushResult(status: SyncStatus.idle);
    }
    final base = _base(workspace.apiUrl);
    final payload = {
      'data': {
        'version': 3,
        'exportedAt': DateTime.now().toIso8601String(),
        'data': statePayload,
      },
      'base_revision': workspace.revision ?? 0,
    };
    final res = await _client.post(
      Uri.parse('$base/api/workspaces/${workspace.inviteCode}/push'),
      headers: _headers(workspace),
      body: jsonEncode(payload),
    );
    if (res.statusCode == 409) {
      return const PushResult(status: SyncStatus.conflict);
    }
    if (res.statusCode == 401) {
      return const PushResult(status: SyncStatus.authError);
    }
    if (res.statusCode < 200 || res.statusCode >= 300) {
      return const PushResult(status: SyncStatus.error);
    }
    final json = jsonDecode(res.body) as Map<String, dynamic>;
    final rev = json['revision'] is int
        ? json['revision'] as int
        : int.tryParse('${json['revision']}');
    return PushResult(status: SyncStatus.success, revision: rev);
  }

  /// GET .../pull
  Future<PullResult> pull({required WorkspaceInfo workspace}) async {
    if (workspace.isLocal) {
      return const PullResult(status: SyncStatus.idle);
    }
    final base = _base(workspace.apiUrl);
    final res = await _client.get(
      Uri.parse('$base/api/workspaces/${workspace.inviteCode}/pull'),
      headers: _headers(workspace),
    );
    if (res.statusCode == 401) {
      return const PullResult(status: SyncStatus.authError);
    }
    if (res.statusCode < 200 || res.statusCode >= 300) {
      return const PullResult(status: SyncStatus.error);
    }
    final json = jsonDecode(res.body) as Map<String, dynamic>;
    final rev = json['revision'] is int
        ? json['revision'] as int
        : int.tryParse('${json['revision']}');
    final data = json['data'];
    Map<String, dynamic>? incoming;
    if (data is Map) {
      final inner = data['data'];
      if (inner is Map) {
        incoming = Map<String, dynamic>.from(inner);
      } else {
        incoming = Map<String, dynamic>.from(data);
      }
    }
    return PullResult(
      status: SyncStatus.success,
      revision: rev,
      data: incoming,
    );
  }

  /// POST .../ask
  Future<Map<String, dynamic>> ask({
    required WorkspaceInfo workspace,
    required Map<String, dynamic> body,
  }) async {
    final base = _base(workspace.apiUrl);
    final res = await _client.post(
      Uri.parse('$base/api/workspaces/${workspace.inviteCode}/ask'),
      headers: _headers(workspace),
      body: jsonEncode(body),
    );
    if (res.statusCode < 200 || res.statusCode >= 300) {
      final err = _tryError(res.body);
      throw WorkspaceApiException(err ?? 'Asistan isteği başarısız (HTTP ${res.statusCode}).');
    }
    final decoded = jsonDecode(res.body);
    if (decoded is Map<String, dynamic>) return decoded;
    return {'data': decoded};
  }

  String? _tryError(String body) {
    try {
      final j = jsonDecode(body);
      if (j is Map && j['error'] != null) return j['error'].toString();
    } catch (_) {}
    return null;
  }
}

class WorkspaceApiException implements Exception {
  WorkspaceApiException(this.message);
  final String message;
  @override
  String toString() => message;
}

class PushResult {
  const PushResult({required this.status, this.revision});
  final SyncStatus status;
  final int? revision;
}

class PullResult {
  const PullResult({required this.status, this.revision, this.data});
  final SyncStatus status;
  final int? revision;
  final Map<String, dynamic>? data;
}
