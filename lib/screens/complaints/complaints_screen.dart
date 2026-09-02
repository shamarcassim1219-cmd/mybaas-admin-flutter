import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../services/admin_complaint_service.dart';
import 'complaint_detail_screen.dart';

class ComplaintsScreen extends StatefulWidget {
  const ComplaintsScreen({super.key});

  @override
  State<ComplaintsScreen> createState() => _ComplaintsScreenState();
}

class _ComplaintsScreenState extends State<ComplaintsScreen> with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  bool _loading = true;
  String? _error;
  List<AdminComplaint> _pending = [];
  List<AdminComplaint> _approved = [];
  List<AdminComplaint> _rejected = [];

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
        AdminComplaintService.instance.list(status: 'Pending'),
        AdminComplaintService.instance.list(status: 'Approved'),
        AdminComplaintService.instance.list(status: 'Rejected'),
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
        _error = 'Unable to load complaints. Pull down to try again.';
        _loading = false;
      });
    }
  }

  Future<void> _openDetail(AdminComplaint complaint) async {
    final changed = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => ComplaintDetailScreen(complaint: complaint)),
    );
    if (changed == true) _load();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Complaints'),
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

  Widget _buildList(List<AdminComplaint> items) {
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
                  Icon(Icons.flag_outlined, size: 48, color: AppColors.textMuted),
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
      children: items.map((c) => _buildRow(c)).toList(),
    );
  }

  Widget _buildRow(AdminComplaint c) {
    return InkWell(
      onTap: () => _openDetail(c),
      borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
      child: Container(
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
              children: [
                Expanded(child: Text(c.reason, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14.5))),
                const Icon(Icons.chevron_right, size: 20, color: AppColors.textMuted),
              ],
            ),
            const SizedBox(height: 6),
            Text('Order ${c.orderId}', style: const TextStyle(fontSize: 12, color: AppColors.textMuted)),
            const SizedBox(height: 4),
            Text('Customer: ${c.customerName}', style: const TextStyle(fontSize: 12.5, color: AppColors.textSecondary)),
            if (c.baasName.isNotEmpty)
              Text('Baas: ${c.baasName}', style: const TextStyle(fontSize: 12.5, color: AppColors.textSecondary)),
            if (c.photos.isNotEmpty) ...[
              const SizedBox(height: 6),
              Row(
                children: [
                  const Icon(Icons.photo_outlined, size: 14, color: AppColors.textMuted),
                  const SizedBox(width: 4),
                  Text('${c.photos.length} photo(s)', style: const TextStyle(fontSize: 11.5, color: AppColors.textMuted)),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}
