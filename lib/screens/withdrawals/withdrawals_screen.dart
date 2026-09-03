import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../services/admin_withdrawal_service.dart';
import '../../services/api_exception.dart';

class WithdrawalsScreen extends StatefulWidget {
  const WithdrawalsScreen({super.key});

  @override
  State<WithdrawalsScreen> createState() => _WithdrawalsScreenState();
}

class _WithdrawalsScreenState extends State<WithdrawalsScreen> with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  bool _loading = true;
  String? _error;
  List<WithdrawalRequest> _all = [];
  final Set<String> _acting = {};

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
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
      final requests = await AdminWithdrawalService.instance.list();
      if (!mounted) return;
      setState(() {
        _all = requests;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'Unable to load withdrawals. Pull down to try again.';
        _loading = false;
      });
    }
  }

  List<WithdrawalRequest> _filtered(String status) => _all.where((r) => r.status == status).toList();

  Future<void> _decide(WithdrawalRequest request, String status) async {
    String reference = '';

    if (status == 'Paid') {
      final refController = TextEditingController();
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Mark as Paid'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Rs. ${request.amount.toStringAsFixed(2)} to ${request.accountName} (${request.bankName})'),
              const SizedBox(height: 12),
              TextField(
                controller: refController,
                decoration: const InputDecoration(hintText: 'Bank transfer reference (optional)'),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Cancel')),
            TextButton(onPressed: () => Navigator.of(context).pop(true), child: const Text('Mark Paid')),
          ],
        ),
      );
      if (confirmed != true) return;
      reference = refController.text.trim();
    } else {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('$status Withdrawal'),
          content: Text(
            status == 'Rejected'
                ? 'Reject this request? Rs. ${request.amount.toStringAsFixed(2)} will be returned to their available balance.'
                : 'Approve this withdrawal request?',
          ),
          actions: [
            TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Cancel')),
            TextButton(onPressed: () => Navigator.of(context).pop(true), child: Text(status)),
          ],
        ),
      );
      if (confirmed != true) return;
    }

    setState(() => _acting.add(request.id));
    try {
      await AdminWithdrawalService.instance.decide(request.id, status: status, reference: reference);
      await _load();
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _acting.remove(request.id));
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    } catch (e) {
      if (!mounted) return;
      setState(() => _acting.remove(request.id));
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Unable to update this withdrawal. Please try again.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Withdrawals'),
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          labelColor: AppColors.primary,
          unselectedLabelColor: AppColors.textMuted,
          indicatorColor: AppColors.accent,
          tabs: [
            Tab(text: 'Requested (${_filtered('Requested').length})'),
            const Tab(text: 'Approved'),
            const Tab(text: 'Paid'),
            const Tab(text: 'Rejected'),
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
                    _buildList(_filtered('Requested')),
                    _buildList(_filtered('Approved')),
                    _buildList(_filtered('Paid')),
                    _buildList(_filtered('Rejected')),
                  ],
                ),
              ),
      ),
    );
  }

  Widget _buildList(List<WithdrawalRequest> items) {
    if (items.isEmpty) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          if (_error != null)
            Padding(
              padding: const EdgeInsets.all(20),
              child: Text(_error!, style: const TextStyle(color: AppColors.danger)),
            ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 80),
            child: Center(child: Text('Nothing here.', style: TextStyle(color: AppColors.textMuted))),
          ),
        ],
      );
    }

    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(20),
      children: items.map(_buildRow).toList(),
    );
  }

  Widget _buildRow(WithdrawalRequest r) {
    final busy = _acting.contains(r.id);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(child: Text(r.requesterName, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14.5))),
              Text('Rs. ${r.amount.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15, color: AppColors.primary)),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            '${r.requesterRole.isNotEmpty ? r.requesterRole[0].toUpperCase() + r.requesterRole.substring(1) : 'Unknown'} - ${r.requesterMobile}',
            style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
          ),
          const SizedBox(height: 8),
          Text('${r.bankName} - ${r.accountName}', style: const TextStyle(fontSize: 12.5, color: AppColors.textSecondary)),
          Text(r.accountNumber, style: const TextStyle(fontSize: 12.5, color: AppColors.textSecondary)),
          if (r.branch.isNotEmpty) Text(r.branch, style: const TextStyle(fontSize: 12, color: AppColors.textMuted)),

          if (r.status == 'Requested' || r.status == 'Approved') ...[
            const SizedBox(height: 12),
            Row(
              children: [
                if (r.status == 'Requested') ...[
                  Expanded(
                    child: OutlinedButton(
                      onPressed: busy ? null : () => _decide(r, 'Rejected'),
                      style: OutlinedButton.styleFrom(foregroundColor: AppColors.danger, minimumSize: const Size.fromHeight(40)),
                      child: const Text('Reject'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: busy ? null : () => _decide(r, 'Approved'),
                      style: ElevatedButton.styleFrom(minimumSize: const Size.fromHeight(40)),
                      child: const Text('Approve'),
                    ),
                  ),
                ] else
                  Expanded(
                    child: ElevatedButton(
                      onPressed: busy ? null : () => _decide(r, 'Paid'),
                      style: ElevatedButton.styleFrom(minimumSize: const Size.fromHeight(40)),
                      child: busy
                          ? const SizedBox(height: 16, width: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                          : const Text('Mark as Paid'),
                    ),
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
