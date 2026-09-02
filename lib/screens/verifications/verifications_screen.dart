import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../services/admin_verification_service.dart';
import 'verification_detail_screen.dart';

class VerificationsScreen extends StatefulWidget {
  const VerificationsScreen({super.key});

  @override
  State<VerificationsScreen> createState() => _VerificationsScreenState();
}

class _VerificationsScreenState extends State<VerificationsScreen> with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  bool _loading = true;
  String? _error;
  List<VerificationSubmission> _pending = [];
  List<VerificationSubmission> _approved = [];
  List<VerificationSubmission> _rejected = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _load();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final results = await Future.wait([
        AdminVerificationService.instance.list(status: 'Pending'),
        AdminVerificationService.instance.list(status: 'Approved'),
        AdminVerificationService.instance.list(status: 'Rejected'),
      ]);

      if (!mounted) return;
      setState(() {
        _pending = results[0];
        _approved = results[1];
        _rejected = results[2];
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'Unable to load verifications. Pull down to try again.';
        _loading = false;
      });
    }
  }

  Future<void> _openDetail(VerificationSubmission submission) async {
    final changed = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => VerificationDetailScreen(submission: submission)),
    );
    if (changed == true) _load();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Verifications'),
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppColors.primary,
          unselectedLabelColor: AppColors.textMuted,
          indicatorColor: AppColors.accent,
          tabs: [
            Tab(text: 'Pending (${_pending.length})'),
            Tab(text: 'Approved'),
            Tab(text: 'Rejected'),
          ],
        ),
      ),
      body: SafeArea(
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : RefreshIndicator(
                color: AppColors.primary,
                onRefresh: _load,
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _buildList(_pending),
                    _buildList(_approved),
                    _buildList(_rejected),
                  ],
                ),
              ),
      ),
    );
  }

  Widget _buildList(List<VerificationSubmission> items) {
    if (items.isEmpty) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          if (_error != null)
            Padding(
              padding: const EdgeInsets.all(20),
              child: Text(_error!, style: const TextStyle(color: AppColors.danger)),
            ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 80),
            child: Center(
              child: Column(
                children: const [
                  Icon(Icons.verified_user_outlined, size: 48, color: AppColors.textMuted),
                  SizedBox(height: 12),
                  Text('Nothing here.', style: TextStyle(color: AppColors.textMuted)),
                ],
              ),
            ),
          ),
        ],
      );
    }

    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(20),
      children: items.map((s) => _buildRow(s)).toList(),
    );
  }

  Widget _buildRow(VerificationSubmission s) {
    return InkWell(
      onTap: () => _openDetail(s),
      borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 22,
              backgroundColor: AppColors.primarySoft,
              child: Text(
                s.fullName.isNotEmpty ? s.fullName[0].toUpperCase() : '?',
                style: const TextStyle(fontWeight: FontWeight.w800, color: AppColors.primary),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(s.fullName.isNotEmpty ? s.fullName : s.name, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14.5)),
                  const SizedBox(height: 3),
                  Text(
                    '${s.role[0].toUpperCase()}${s.role.substring(1)} - ${s.mobile}',
                    style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, size: 20, color: AppColors.textMuted),
          ],
        ),
      ),
    );
  }
}
