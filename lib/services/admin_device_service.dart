import 'api_client.dart';

class BannedDevice {
  final String deviceId;
  final String reason;
  final DateTime bannedAt;

  BannedDevice({required this.deviceId, required this.reason, required this.bannedAt});

  factory BannedDevice.fromJson(Map<String, dynamic> json) {
    return BannedDevice(
      deviceId: json['deviceId'] as String? ?? '',
      reason: json['reason'] as String? ?? '',
      bannedAt: DateTime.tryParse(json['bannedAt'] as String? ?? '') ?? DateTime.now(),
    );
  }
}

/// Confirmed against the real backend:
/// - GET /api/admin/devices - every banned device, newest first
/// - POST /api/admin/devices/ban {deviceId, reason}
/// - PUT /api/admin/devices/:deviceId/unban
/// A banned device is blocked from logging in, registering, or
/// continuing an existing session on any account - checked in
/// getAuthenticatedUser() and at every login/register token issue.
class AdminDeviceService {
  AdminDeviceService._internal();
  static final AdminDeviceService instance = AdminDeviceService._internal();

  final _api = ApiClient.instance;

  Future<List<BannedDevice>> list() async {
    final data = await _api.get('/api/admin/devices');
    final list = (data['devices'] as List?) ?? [];
    return list.map((e) => BannedDevice.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<void> ban(String deviceId, {String reason = ''}) async {
    await _api.post('/api/admin/devices/ban', body: {'deviceId': deviceId, 'reason': reason});
  }

  Future<void> unban(String deviceId) async {
    await _api.put('/api/admin/devices/$deviceId/unban');
  }
}
