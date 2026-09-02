import 'api_client.dart';

class VerificationSubmission {
  final String userId;
  final String name;
  final String mobile;
  final String role;
  final String status; // Pending | Approved | Rejected
  final String fullName;
  final String nic;
  final String phone;
  final String address;
  final String province;
  final String district;
  final String nicPhoto;
  final String nicBackPhoto;
  final String selfiePhoto;
  final String note;
  final DateTime submittedAt;

  VerificationSubmission({
    required this.userId,
    required this.name,
    required this.mobile,
    required this.role,
    required this.status,
    required this.fullName,
    required this.nic,
    required this.phone,
    required this.address,
    required this.province,
    required this.district,
    required this.nicPhoto,
    required this.nicBackPhoto,
    required this.selfiePhoto,
    required this.note,
    required this.submittedAt,
  });

  factory VerificationSubmission.fromJson(Map<String, dynamic> json) {
    final v = json['verification'] as Map<String, dynamic>? ?? {};
    return VerificationSubmission(
      userId: json['userId'] as String? ?? '',
      name: json['name'] as String? ?? '',
      mobile: json['mobile'] as String? ?? '',
      role: json['role'] as String? ?? 'customer',
      status: v['status'] as String? ?? 'Pending',
      fullName: v['fullName'] as String? ?? '',
      nic: v['nic'] as String? ?? '',
      phone: v['phone'] as String? ?? '',
      address: v['address'] as String? ?? '',
      province: v['province'] as String? ?? '',
      district: v['district'] as String? ?? '',
      nicPhoto: v['nicPhoto'] as String? ?? '',
      nicBackPhoto: v['nicBackPhoto'] as String? ?? '',
      selfiePhoto: v['selfiePhoto'] as String? ?? '',
      note: v['note'] as String? ?? '',
      submittedAt: DateTime.tryParse(v['submittedAt'] as String? ?? '') ?? DateTime.now(),
    );
  }
}

/// Confirmed against the real backend: GET /api/admin/verifications
/// (optionally filtered by ?status=), PUT /api/admin/verification/:userId
/// with {status, note} - approving/rejecting notifies the account by
/// both in-app notification and email automatically.
class AdminVerificationService {
  AdminVerificationService._internal();
  static final AdminVerificationService instance = AdminVerificationService._internal();

  final _api = ApiClient.instance;

  Future<List<VerificationSubmission>> list({String? status}) async {
    final data = await _api.get('/api/admin/verifications', query: {'status': status});
    final list = (data['submissions'] as List?) ?? [];
    return list.map((e) => VerificationSubmission.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<void> decide(String userId, {required String status, String note = ''}) async {
    await _api.put('/api/admin/verification/$userId', body: {'status': status, 'note': note});
  }
}
