import 'api_client.dart';

class AdminComplaint {
  final String id;
  final String complaintId;
  final String orderId;
  final String reason;
  final String details;
  final List<String> photos;
  final String status; // Pending | Approved | Rejected
  final String adminNote;
  final bool refunded;
  final double? refundAmount;
  final String customerName;
  final String customerMobile;
  final String baasName;
  final String baasMobile;
  final double? orderTotal;
  final String? orderPaymentMethod; // pay_now | pay_direct
  final String? orderPaymentStatus;
  final DateTime createdAt;

  AdminComplaint({
    required this.id,
    required this.complaintId,
    required this.orderId,
    required this.reason,
    required this.details,
    required this.photos,
    required this.status,
    required this.adminNote,
    required this.refunded,
    this.refundAmount,
    required this.customerName,
    required this.customerMobile,
    required this.baasName,
    required this.baasMobile,
    this.orderTotal,
    this.orderPaymentMethod,
    this.orderPaymentStatus,
    required this.createdAt,
  });

  /// Whether approving this complaint would trigger the backend's
  /// automatic refund - only pay_now orders that were actually paid
  /// have money held by the platform to return.
  bool get wouldRefundOnApprove => orderPaymentMethod == 'pay_now' && orderPaymentStatus == 'PAID';

  factory AdminComplaint.fromJson(Map<String, dynamic> json) {
    return AdminComplaint(
      id: json['id'] as String? ?? '',
      complaintId: json['complaintId'] as String? ?? '',
      orderId: json['orderId'] as String? ?? '',
      reason: json['reason'] as String? ?? '',
      details: json['details'] as String? ?? '',
      photos: (json['photos'] as List?)?.map((e) => e.toString()).toList() ?? [],
      status: json['status'] as String? ?? 'Pending',
      adminNote: json['adminNote'] as String? ?? '',
      refunded: json['refunded'] == true,
      refundAmount: (json['refundAmount'] as num?)?.toDouble(),
      customerName: json['customerName'] as String? ?? 'Unknown',
      customerMobile: json['customerMobile'] as String? ?? '',
      baasName: json['baasName'] as String? ?? '',
      baasMobile: json['baasMobile'] as String? ?? '',
      orderTotal: (json['orderTotal'] as num?)?.toDouble(),
      orderPaymentMethod: json['orderPaymentMethod'] as String?,
      orderPaymentStatus: json['orderPaymentStatus'] as String?,
      createdAt: DateTime.tryParse(json['createdAt'] as String? ?? '') ?? DateTime.now(),
    );
  }
}

/// Confirmed against the real backend: GET /api/admin/complaints
/// (optionally ?status=), PUT /api/complaints/:id/decision with
/// {decision, adminNote} - approving a pay_now order's complaint
/// automatically refunds the customer's wallet (see the decision
/// endpoint's own refund logic), no separate action needed here.
class AdminComplaintService {
  AdminComplaintService._internal();
  static final AdminComplaintService instance = AdminComplaintService._internal();

  final _api = ApiClient.instance;

  Future<List<AdminComplaint>> list({String? status}) async {
    final data = await _api.get('/api/admin/complaints', query: {'status': status});
    final list = (data['complaints'] as List?) ?? [];
    return list.map((e) => AdminComplaint.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<void> decide(String complaintId, {required String decision, String adminNote = ''}) async {
    await _api.put('/api/complaints/$complaintId/decision', body: {'decision': decision, 'adminNote': adminNote});
  }
}
