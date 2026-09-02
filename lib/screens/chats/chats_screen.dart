import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../services/admin_chat_service.dart';
import 'chat_detail_screen.dart';

class ChatsScreen extends StatefulWidget {
  const ChatsScreen({super.key});

  @override
  State<ChatsScreen> createState() => _ChatsScreenState();
}

class _ChatsScreenState extends State<ChatsScreen> {
  bool _loading = true;
  String? _error;
  List<AdminChatSummary> _chats = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final chats = await AdminChatService.instance.list();
      if (!mounted) return;
      setState(() {
        _chats = chats;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'Unable to load chats. Pull down to try again.';
        _loading = false;
      });
    }
  }

  Future<void> _openChat(AdminChatSummary chat) async {
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => ChatDetailScreen(chat: chat)),
    );
    _load();
  }

  @override
  Widget build(BuildContext context) {
    // Open chats first, so anything still needing a reply surfaces
    // at the top rather than mixed in with resolved ones.
    final sorted = [..._chats]..sort((a, b) {
        if (a.isOpen != b.isOpen) return a.isOpen ? -1 : 1;
        return b.updatedAt.compareTo(a.updatedAt);
      });

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Support Chats')),
      body: SafeArea(
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : RefreshIndicator(
                color: AppColors.primary,
                onRefresh: _load,
                child: sorted.isEmpty
                    ? ListView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        children: [
                          if (_error != null)
                            Padding(
                              padding: const EdgeInsets.all(20),
                              child: Text(_error!, style: const TextStyle(color: AppColors.danger)),
                            ),
                          const Padding(
                            padding: EdgeInsets.symmetric(vertical: 80),
                            child: Center(child: Text('No chats yet.', style: TextStyle(color: AppColors.textMuted))),
                          ),
                        ],
                      )
                    : ListView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: const EdgeInsets.all(20),
                        children: sorted.map(_buildRow).toList(),
                      ),
              ),
      ),
    );
  }

  Widget _buildRow(AdminChatSummary c) {
    return InkWell(
      onTap: () => _openChat(c),
      borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: c.isOpen ? AppColors.surface : AppColors.background,
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          border: Border.all(color: c.isOpen ? AppColors.accent.withValues(alpha: 0.3) : AppColors.border),
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 20,
              backgroundColor: AppColors.primarySoft,
              child: Text(
                c.userName.isNotEmpty ? c.userName[0].toUpperCase() : '?',
                style: const TextStyle(fontWeight: FontWeight.w800, color: AppColors.primary),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(c.userName, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
                  const SizedBox(height: 3),
                  Text(
                    c.lastMessage.isNotEmpty ? c.lastMessage : '(no messages)',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 12.5, color: AppColors.textSecondary),
                  ),
                ],
              ),
            ),
            if (c.isOpen)
              Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(color: AppColors.accent, shape: BoxShape.circle),
              ),
          ],
        ),
      ),
    );
  }
}
