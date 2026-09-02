import 'api_client.dart';

class DashboardStats {
  final int totalUsers;
  final int totalCustomers;
  final int totalBaas;
  final int totalOrders;
  final int ordersToday;
  final double profitToday;
  final double orderValueToday;
  final int pendingVerifications;
  final int pendingWithdrawals;
  final int openComplaints;
  final int openSupportRequests;

  DashboardStats({
    required this.totalUsers,
    required this.totalCustomers,
    required this.totalBaas,
    required this.totalOrders,
    required this.ordersToday,
    required this.profitToday,
    required this.orderValueToday,
    required this.pendingVerifications,
    required this.pendingWithdrawals,
    required this.openComplaints,
    required this.openSupportRequests,
  });

  factory DashboardStats.fromJson(Map<String, dynamic> json) {
    return DashboardStats(
      totalUsers: (json['totalUsers'] as num?)?.toInt() ?? 0,
      totalCustomers: (json['totalCustomers'] as num?)?.toInt() ?? 0,
      totalBaas: (json['totalBaas'] as num?)?.toInt() ?? 0,
      totalOrders: (json['totalOrders'] as num?)?.toInt() ?? 0,
      ordersToday: (json['ordersToday'] as num?)?.toInt() ?? 0,
      profitToday: (json['profitToday'] as num?)?.toDouble() ?? 0,
      orderValueToday: (json['orderValueToday'] as num?)?.toDouble() ?? 0,
      pendingVerifications: (json['pendingVerifications'] as num?)?.toInt() ?? 0,
      pendingWithdrawals: (json['pendingWithdrawals'] as num?)?.toInt() ?? 0,
      openComplaints: (json['openComplaints'] as num?)?.toInt() ?? 0,
      openSupportRequests: (json['openSupportRequests'] as num?)?.toInt() ?? 0,
    );
  }
}

/// Confirmed against the real backend: GET /api/admin/dashboard-stats
/// returns real-activity counts (Accepted/Completed orders only) and
/// today's actual platform profit (2.5% fee + pay_now commission),
/// not gross order value.
class DashboardService {
  DashboardService._internal();
  static final DashboardService instance = DashboardService._internal();

  final _api = ApiClient.instance;

  Future<DashboardStats> load() async {
    final data = await _api.get('/api/admin/dashboard-stats');
    return DashboardStats.fromJson(data['stats'] as Map<String, dynamic>);
  }
}
