import 'api_client.dart';

class AdminUserSummary {
  final String id;
  final String name;
  final String mobile;
  final String email;
  final String role;
  final bool isDisabled;
  final DateTime createdAt;

  AdminUserSummary({
    required this.id,
    required this.name,
    required this.mobile,
    required this.email,
    required this.role,
    required this.isDisabled,
    required this.createdAt,
  });

  factory AdminUserSummary.fromJson(Map<String, dynamic> json) {
    return AdminUserSummary(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '(no name)',
      mobile: json['mobile'] as String? ?? '',
      email: json['email'] as String? ?? '',
      role: json['role'] as String? ?? 'customer',
      isDisabled: json['isDisabled'] == true,
      createdAt: DateTime.tryParse(json['createdAt'] as String? ?? '') ?? DateTime.now(),
    );
  }
}

class AdminUserDetail {
  final String id;
  final String name;
  final String mobile;
  final String email;
  final String role;
  final bool isDisabled;
  final bool walletHeld;
  final double walletBalance;
  final String verificationStatus;
  final String lastDeviceId;
  final bool deviceBanned;
  final DateTime createdAt;

  AdminUserDetail({
    required this.id,
    required this.name,
    required this.mobile,
    required this.email,
    required this.role,
    required this.isDisabled,
    required this.walletHeld,
    required this.walletBalance,
    required this.verificationStatus,
    required this.lastDeviceId,
    required this.deviceBanned,
    required this.createdAt,
  });

  factory AdminUserDetail.fromJson(Map<String, dynamic> json) {
    final verification = json['verification'] as Map<String, dynamic>?;
    return AdminUserDetail(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '(no name)',
      mobile: json['mobile'] as String? ?? '',
      email: json['email'] as String? ?? '',
      role: json['role'] as String? ?? 'customer',
      isDisabled: json['isDisabled'] == true,
      walletHeld: json['walletHeld'] == true,
      walletBalance: ((json['walletBalance'] as Map<String, dynamic>?)?['available'] as num?)?.toDouble() ?? 0,
      verificationStatus: verification?['status'] as String? ?? 'None',
      lastDeviceId: json['lastDeviceId'] as String? ?? '',
      deviceBanned: json['deviceBanned'] == true,
      createdAt: DateTime.tryParse(json['createdAt'] as String? ?? '') ?? DateTime.now(),
    );
  }
}

/// Confirmed against the real backend:
/// - GET /api/admin/users - list
/// - GET /api/admin/users/:id - full detail (includes lastDeviceId
///   and whether that device is currently banned)
/// - PUT /api/admin/users/:id/status {disabled} - ban/unban account
/// - DELETE /api/admin/users/:id - permanent delete
/// - POST /api/admin/users/:id/wallet-topup {amount, note}
/// - POST /api/admin/users/:id/wallet-deduct {amount, note} - "reverse" money
/// - PUT /api/admin/users/:id/clear-field {field: email|mobile|verification}
class AdminUserService {
  AdminUserService._internal();
  static final AdminUserService instance = AdminUserService._internal();

  final _api = ApiClient.instance;

  Future<List<AdminUserSummary>> list({String? role, String? query}) async {
    final data = await _api.get('/api/admin/users', query: {'role': role, 'q': query});
    final list = (data['users'] as List?) ?? [];
    return list.map((e) => AdminUserSummary.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<AdminUserDetail> detail(String userId) async {
    final data = await _api.get('/api/admin/users/$userId');
    return AdminUserDetail.fromJson(data['user'] as Map<String, dynamic>);
  }

  Future<void> setDisabled(String userId, bool disabled) async {
    await _api.put('/api/admin/users/$userId/status', body: {'disabled': disabled});
  }

  Future<void> delete(String userId) async {
    await _api.delete('/api/admin/users/$userId');
  }

  Future<void> walletTopUp(String userId, {required double amount, String note = ''}) async {
    await _api.post('/api/admin/users/$userId/wallet-topup', body: {'amount': amount, 'note': note});
  }

  Future<void> walletDeduct(String userId, {required double amount, String note = ''}) async {
    await _api.post('/api/admin/users/$userId/wallet-deduct', body: {'amount': amount, 'note': note});
  }

  Future<void> clearField(String userId, String field) async {
    await _api.put('/api/admin/users/$userId/clear-field', body: {'field': field});
  }
}
