import 'api_client.dart';

class AdminChatSummary {
  final String id;
  final String status; // open | closed
  final String userId;
  final String userName;
  final String userMobile;
  final String lastMessage;
  final DateTime updatedAt;

  AdminChatSummary({
    required this.id,
    required this.status,
    required this.userId,
    required this.userName,
    required this.userMobile,
    required this.lastMessage,
    required this.updatedAt,
  });

  bool get isOpen => status == 'open';

  factory AdminChatSummary.fromJson(Map<String, dynamic> json) {
    return AdminChatSummary(
      id: json['id'] as String? ?? '',
      status: json['status'] as String? ?? 'open',
      userId: json['userId'] as String? ?? '',
      userName: json['userName'] as String? ?? 'Unknown',
      userMobile: json['userMobile'] as String? ?? '',
      lastMessage: json['lastMessage'] as String? ?? '',
      updatedAt: DateTime.tryParse(json['updatedAt'] as String? ?? '') ?? DateTime.now(),
    );
  }
}

class AdminChatMessage {
  final String id;
  final String senderType; // customer | admin
  final String message;
  final DateTime createdAt;

  AdminChatMessage({required this.id, required this.senderType, required this.message, required this.createdAt});

  bool get isFromAdmin => senderType == 'admin';

  factory AdminChatMessage.fromJson(Map<String, dynamic> json) {
    return AdminChatMessage(
      id: json['id'] as String? ?? '',
      senderType: json['senderType'] as String? ?? 'customer',
      message: json['message'] as String? ?? '',
      createdAt: DateTime.tryParse(json['createdAt'] as String? ?? '') ?? DateTime.now(),
    );
  }
}

/// Confirmed against the real backend:
/// - GET /api/admin/support-chats - every chat, newest first, with
///   requester name/mobile and a last-message preview
/// - GET /api/support/chats/:id - same role-agnostic endpoint the
///   customer/Baas apps use, works for admin too
/// - POST /api/support/chats/:id/messages - same endpoint; the
///   backend auto-detects an admin sender and tags the message
///   senderType accordingly
/// - PUT /api/admin/support-chats/:id/close - admin-only, can close
///   any chat (not just one it owns)
class AdminChatService {
  AdminChatService._internal();
  static final AdminChatService instance = AdminChatService._internal();

  final _api = ApiClient.instance;

  Future<List<AdminChatSummary>> list() async {
    final data = await _api.get('/api/admin/support-chats');
    final list = (data['chats'] as List?) ?? [];
    return list.map((e) => AdminChatSummary.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<(String status, List<AdminChatMessage> messages)> getMessages(String chatId) async {
    final data = await _api.get('/api/support/chats/$chatId');
    final chat = data['chat'] as Map<String, dynamic>? ?? {};
    final messagesRaw = (data['messages'] as List?) ?? [];
    return (
      chat['status'] as String? ?? 'open',
      messagesRaw.map((e) => AdminChatMessage.fromJson(e as Map<String, dynamic>)).toList(),
    );
  }

  Future<void> sendMessage(String chatId, String message) async {
    await _api.post('/api/support/chats/$chatId/messages', body: {'message': message});
  }

  Future<void> closeChat(String chatId) async {
    await _api.put('/api/admin/support-chats/$chatId/close');
  }
}
