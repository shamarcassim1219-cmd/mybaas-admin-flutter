import 'api_client.dart';

class WithdrawalRequest {
  final String id;
  final String userId;
  final String requesterName;
  final String requesterMobile;
  final String requesterEmail;
  final String requesterRole;
  final double amount;
  final String status; // Pending | Approved | Paid | Rejected
  final String bankName;
  final String accountName;
  final String accountNumber;
  final String branch;
  final DateTime createdAt;

  WithdrawalRequest({
    required this.id,
    required this.userId,
    required this.requesterName,
    required this.requesterMobile,
    required this.requesterEmail,
    required this.requesterRole,
    required this.amount,
    required this.status,
    required this.bankName,
    required this.accountName,
    required this.accountNumber,
    required this.branch,
    required this.createdAt,
  });

  factory WithdrawalRequest.fromJson(Map<String, dynamic> json) {
    return WithdrawalRequest(
      id: json['id'] as String? ?? '',
      userId: json['userId'] as String? ?? '',
      requesterName: json['requesterName'] as String? ?? 'Unknown',
      requesterMobile: json['requesterMobile'] as String? ?? '',
      requesterEmail: json['requesterEmail'] as String? ?? '',
      requesterRole: (json['requesterRole'] as String?)?.isNotEmpty == true ? json['requesterRole'] as String : 'customer',
      amount: (json['amount'] as num?)?.toDouble() ?? 0,
      status: json['status'] as String? ?? 'Pending',
      bankName: json['bankName'] as String? ?? '',
      accountName: json['accountName'] as String? ?? '',
      accountNumber: json['accountNumber'] as String? ?? '',
      branch: json['branch'] as String? ?? '',
      createdAt: DateTime.tryParse(json['createdAt'] as String? ?? '') ?? DateTime.now(),
    );
  }
}

/// Confirmed against the real backend:
/// - GET /api/wallet/withdrawals?all=true - every user's requests
///   (admin only), each enriched with requester details
/// - PUT /api/wallet/withdrawals/:id {status: Approved|Paid|Rejected,
///   reference?, adminNote?} - Paid clears the held amount, Rejected
///   returns it to the user's available balance automatically.
class AdminWithdrawalService {
  AdminWithdrawalService._internal();
  static final AdminWithdrawalService instance = AdminWithdrawalService._internal();

  final _api = ApiClient.instance;

  Future<List<WithdrawalRequest>> list() async {
    final data = await _api.get('/api/wallet/withdrawals', query: {'all': 'true'});
    final list = (data['requests'] as List?) ?? [];
    return list.map((e) => WithdrawalRequest.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<void> decide(String requestId, {required String status, String reference = '', String adminNote = ''}) async {
    await _api.put('/api/wallet/withdrawals/$requestId', body: {
      'status': status,
      'reference': reference,
      'adminNote': adminNote,
    });
  }
}
