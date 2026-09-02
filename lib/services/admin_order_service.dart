import 'api_client.dart';

class AdminOrder {
  final String id;
  final String orderId;
  final String service;
  final String location;
  final String status;
  final String paymentMethod; // pay_now | pay_direct
  final String paymentStatus;
  final double total;
  final String? professional;
  final DateTime createdAt;

  AdminOrder({
    required this.id,
    required this.orderId,
    required this.service,
    required this.location,
    required this.status,
    required this.paymentMethod,
    required this.paymentStatus,
    required this.total,
    this.professional,
    required this.createdAt,
  });

  /// A discount only makes sense before a pay_now order is actually
  /// paid - matches the backend's own validation.
  bool get canDiscount => paymentMethod == 'pay_now' && paymentStatus != 'PAID';

  factory AdminOrder.fromJson(Map<String, dynamic> json) {
    return AdminOrder(
      id: json['id'] as String? ?? '',
      orderId: json['orderId'] as String? ?? '',
      service: json['service'] as String? ?? '',
      location: json['location'] as String? ?? '',
      status: json['status'] as String? ?? '',
      paymentMethod: json['paymentMethod'] as String? ?? 'pay_direct',
      paymentStatus: json['paymentStatus'] as String? ?? '',
      total: (json['total'] as num?)?.toDouble() ?? 0,
      professional: json['professional'] as String?,
      createdAt: DateTime.tryParse(json['createdAt'] as String? ?? '') ?? DateTime.now(),
    );
  }
}

/// Confirmed against the real backend:
/// - GET /api/admin/orders (optional ?q=, ?status=)
/// - PUT /api/admin/orders/:id/discount {discountAmount} - only
///   valid for a pay_now order that hasn't been paid yet; already
///   validates the amount server-side (must be > 0 and less than
///   the current total).
class AdminOrderService {
  AdminOrderService._internal();
  static final AdminOrderService instance = AdminOrderService._internal();

  final _api = ApiClient.instance;

  Future<List<AdminOrder>> list({String? query}) async {
    final data = await _api.get('/api/admin/orders', query: {'q': query});
    final list = (data['orders'] as List?) ?? [];
    return list.map((e) => AdminOrder.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<void> applyDiscount(String orderId, double discountAmount) async {
    await _api.put('/api/admin/orders/$orderId/discount', body: {'discountAmount': discountAmount});
  }
}
