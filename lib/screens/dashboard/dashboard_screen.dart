import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../services/dashboard_service.dart';
import '../verifications/verifications_screen.dart';
import '../complaints/complaints_screen.dart';
import '../withdrawals/withdrawals_screen.dart';
import '../chats/chats_screen.dart';
import '../users/users_screen.dart';

/// Formats a plain LKR amount - the admin app has no international
/// accounts of its own to worry about, so this stays simpler than
/// the customer/Baas apps' formatMoney (which branch on account
/// type).
String _money(double amount) {
  final rounded = amount.toStringAsFixed(2);
  return 'Rs. $rounded';
}

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  bool _loading = true;
  String? _error;
  DashboardStats? _stats;

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
      final stats = await DashboardService.instance.load();
      if (!mounted) return;
      setState(() {
        _stats = stats;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'Unable to load dashboard. Pull down to try again.';
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Dashboard')),
      body: SafeArea(
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : RefreshIndicator(
                color: AppColors.primary,
                onRefresh: _load,
                child: ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.all(20),
                  children: [
                    if (_error != null) ...[
                      Text(_error!, style: const TextStyle(color: AppColors.danger)),
                      const SizedBox(height: 16),
                    ],

                    _buildProfitCard(),
                    const SizedBox(height: 16),

                    Row(
                      children: [
                        Expanded(child: _statCard('Total Users', '${_stats?.totalUsers ?? 0}', Icons.people_outline)),
                        const SizedBox(width: 10),
                        Expanded(child: _statCard('Customers', '${_stats?.totalCustomers ?? 0}', Icons.person_outline)),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(child: _statCard('Baas', '${_stats?.totalBaas ?? 0}', Icons.engineering_outlined)),
                        Expanded(child: _statCard('Orders Today', '${_stats?.ordersToday ?? 0}', Icons.receipt_long_outlined)),
                      ],
                    ),
                    const SizedBox(height: 20),

                    Text('Needs Attention', style: Theme.of(context).textTheme.titleLarge),
                    const SizedBox(height: 10),
                    _actionCard(
                      icon: Icons.verified_user_outlined,
                      label: 'Pending Verifications',
                      count: _stats?.pendingVerifications ?? 0,
                      onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const VerificationsScreen())),
                    ),
                    const SizedBox(height: 10),
                    _actionCard(
                      icon: Icons.flag_outlined,
                      label: 'Open Complaints',
                      count: _stats?.openComplaints ?? 0,
                      onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const ComplaintsScreen())),
                    ),
                    const SizedBox(height: 10),
                    _actionCard(
                      icon: Icons.account_balance_wallet_outlined,
                      label: 'Pending Withdrawals',
                      count: _stats?.pendingWithdrawals ?? 0,
                      onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const WithdrawalsScreen())),
                    ),
                    const SizedBox(height: 10),
                    _actionCard(
                      icon: Icons.support_agent_outlined,
                      label: 'Open Support Requests',
                      count: _stats?.openSupportRequests ?? 0,
                      onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const ChatsScreen())),
                    ),

                    const SizedBox(height: 24),
                    Text('Manage', style: Theme.of(context).textTheme.titleLarge),
                    const SizedBox(height: 10),
                    InkWell(
                      onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const UsersScreen())),
                      borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                      child: Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: const Row(
                          children: [
                            Icon(Icons.people_outline, color: AppColors.primary, size: 22),
                            SizedBox(width: 12),
                            Expanded(child: Text('All Users', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600))),
                            Icon(Icons.chevron_right, size: 18, color: AppColors.textMuted),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
      ),
    );
  }

  Widget _buildProfitCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.primary, AppColors.primaryDark],
        ),
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "TODAY'S PLATFORM PROFIT",
            style: TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 0.5),
          ),
          const SizedBox(height: 8),
          Text(
            _money(_stats?.profitToday ?? 0),
            style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 6),
          Text(
            'From ${_money(_stats?.orderValueToday ?? 0)} in order value',
            style: const TextStyle(color: Colors.white70, fontSize: 12),
          ),
          const SizedBox(height: 10),
          Text(
            '${_stats?.totalOrders ?? 0} total completed/accepted orders all-time',
            style: const TextStyle(color: Colors.white54, fontSize: 11.5),
          ),
        ],
      ),
    );
  }

  Widget _statCard(String label, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: AppColors.primary, size: 20),
          const SizedBox(height: 8),
          Text(value, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
          const SizedBox(height: 2),
          Text(label, style: const TextStyle(fontSize: 11.5, color: AppColors.textMuted)),
        ],
      ),
    );
  }

  Widget _actionCard({required IconData icon, required String label, required int count, required VoidCallback? onTap}) {
    final hasItems = count > 0;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: hasItems ? AppColors.warningSoft : AppColors.surface,
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          border: Border.all(color: hasItems ? AppColors.warning.withValues(alpha: 0.3) : AppColors.border),
        ),
        child: Row(
          children: [
            Icon(icon, color: hasItems ? AppColors.warning : AppColors.textMuted, size: 22),
            const SizedBox(width: 12),
            Expanded(child: Text(label, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600))),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: hasItems ? AppColors.warning : AppColors.border,
                borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
              ),
              child: Text(
                '$count',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: hasItems ? Colors.white : AppColors.textMuted),
              ),
            ),
            if (onTap != null) ...[
              const SizedBox(width: 6),
              const Icon(Icons.chevron_right, size: 18, color: AppColors.textMuted),
            ],
          ],
        ),
      ),
    );
  }
}
