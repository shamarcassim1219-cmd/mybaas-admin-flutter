import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../services/admin_user_service.dart';
import '../../services/api_exception.dart';

/// Full account management for one user - ban/unban, permanently
/// delete, adjust their wallet (credit or reverse/deduct), and clear
/// individual fields (email, mobile, or their verified badge).
class UserDetailScreen extends StatefulWidget {
  final String userId;

  const UserDetailScreen({super.key, required this.userId});

  @override
  State<UserDetailScreen> createState() => _UserDetailScreenState();
}

class _UserDetailScreenState extends State<UserDetailScreen> {
  bool _loading = true;
  String? _error;
  AdminUserDetail? _user;
  bool _acting = false;
  bool _changed = false;

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
      final user = await AdminUserService.instance.detail(widget.userId);
      if (!mounted) return;
      setState(() {
        _user = user;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'Unable to load this account. Pull down to try again.';
        _loading = false;
      });
    }
  }

  Future<void> _toggleDisabled() async {
    final user = _user!;
    final willDisable = !user.isDisabled;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(willDisable ? 'Ban Account' : 'Unban Account'),
        content: Text(
          willDisable
              ? '${user.name} will not be able to log in or use the app until unbanned.'
              : '${user.name} will be able to log in again.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.of(context).pop(true), child: Text(willDisable ? 'Ban' : 'Unban')),
        ],
      ),
    );
    if (confirmed != true) return;

    setState(() => _acting = true);
    try {
      await AdminUserService.instance.setDisabled(user.id, willDisable);
      _changed = true;
      await _load();
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    } finally {
      if (mounted) setState(() => _acting = false);
    }
  }

  Future<void> _delete() async {
    final user = _user!;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Account'),
        content: Text('Permanently delete ${user.name}\'s account? This cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Delete', style: TextStyle(color: AppColors.danger)),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    setState(() => _acting = true);
    try {
      await AdminUserService.instance.delete(user.id);
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _acting = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    }
  }

  Future<void> _adjustWallet({required bool credit}) async {
    final amountController = TextEditingController();
    final noteController = TextEditingController();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(credit ? 'Credit Wallet' : 'Deduct / Reverse Money'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: amountController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(hintText: 'Amount', prefixText: 'Rs. '),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: noteController,
              decoration: const InputDecoration(hintText: 'Note (optional)'),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.of(context).pop(true), child: Text(credit ? 'Credit' : 'Deduct')),
        ],
      ),
    );
    if (confirmed != true) return;

    final amount = double.tryParse(amountController.text.trim());
    if (amount == null || amount <= 0) return;

    setState(() => _acting = true);
    try {
      if (credit) {
        await AdminUserService.instance.walletTopUp(_user!.id, amount: amount, note: noteController.text.trim());
      } else {
        await AdminUserService.instance.walletDeduct(_user!.id, amount: amount, note: noteController.text.trim());
      }
      _changed = true;
      await _load();
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    } finally {
      if (mounted) setState(() => _acting = false);
    }
  }

  Future<void> _clearField(String field, String label) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Remove $label'),
        content: Text('Remove the $label from this account?'),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.of(context).pop(true), child: const Text('Remove')),
        ],
      ),
    );
    if (confirmed != true) return;

    setState(() => _acting = true);
    try {
      await AdminUserService.instance.clearField(_user!.id, field);
      _changed = true;
      await _load();
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    } finally {
      if (mounted) setState(() => _acting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: true,
      onPopInvokedWithResult: (didPop, result) {},
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          title: const Text('Account Detail'),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => Navigator.of(context).pop(_changed),
          ),
        ),
        body: SafeArea(
          child: _loading
              ? const Center(child: CircularProgressIndicator())
              : _user == null
                  ? Center(child: Text(_error ?? 'Not found', style: const TextStyle(color: AppColors.danger)))
                  : ListView(
                      padding: const EdgeInsets.all(20),
                      children: [
                        if (_user!.isDisabled) _statusBanner(),
                        Text(_user!.name, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
                        const SizedBox(height: 4),
                        Text('${_user!.role[0].toUpperCase()}${_user!.role.substring(1)} account', style: const TextStyle(fontSize: 12.5, color: AppColors.textMuted)),
                        const SizedBox(height: 20),

                        _fieldRow('Mobile', _user!.mobile.isNotEmpty ? _user!.mobile : 'Not set', trailing: _user!.mobile.isNotEmpty
                            ? TextButton(onPressed: _acting ? null : () => _clearField('mobile', 'Mobile'), child: const Text('Remove'))
                            : null),
                        _fieldRow('Email', _user!.email.isNotEmpty ? _user!.email : 'Not set', trailing: _user!.email.isNotEmpty
                            ? TextButton(onPressed: _acting ? null : () => _clearField('email', 'Email'), child: const Text('Remove'))
                            : null),
                        _fieldRow('Verification', _user!.verificationStatus, trailing: _user!.verificationStatus == 'Approved'
                            ? TextButton(onPressed: _acting ? null : () => _clearField('verification', 'Verified Badge'), child: const Text('Remove'))
                            : null),
                        _fieldRow('Wallet Balance', 'Rs. ${_user!.walletBalance.toStringAsFixed(2)}'),
                        _fieldRow('Joined', '${_user!.createdAt.day}/${_user!.createdAt.month}/${_user!.createdAt.year}'),

                        const SizedBox(height: 24),
                        Text('Wallet', style: Theme.of(context).textTheme.titleMedium),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton(
                                onPressed: _acting ? null : () => _adjustWallet(credit: true),
                                child: const Text('Credit'),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: OutlinedButton(
                                onPressed: _acting ? null : () => _adjustWallet(credit: false),
                                style: OutlinedButton.styleFrom(foregroundColor: AppColors.danger),
                                child: const Text('Deduct / Reverse'),
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 24),
                        Text('Account', style: Theme.of(context).textTheme.titleMedium),
                        const SizedBox(height: 10),
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton(
                            onPressed: _acting ? null : _toggleDisabled,
                            style: OutlinedButton.styleFrom(foregroundColor: _user!.isDisabled ? AppColors.success : AppColors.warning),
                            child: Text(_user!.isDisabled ? 'Unban Account' : 'Ban Account'),
                          ),
                        ),
                        const SizedBox(height: 10),
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton(
                            onPressed: _acting ? null : _delete,
                            style: OutlinedButton.styleFrom(foregroundColor: AppColors.danger, side: const BorderSide(color: AppColors.danger)),
                            child: _acting
                                ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2))
                                : const Text('Delete Account Permanently'),
                          ),
                        ),
                      ],
                    ),
        ),
      ),
    );
  }

  Widget _statusBanner() {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: AppColors.dangerSoft, borderRadius: BorderRadius.circular(AppSpacing.radiusMd)),
      child: const Row(
        children: [
          Icon(Icons.block, color: AppColors.danger, size: 18),
          SizedBox(width: 8),
          Text('This account is banned.', style: TextStyle(color: AppColors.danger, fontWeight: FontWeight.w700, fontSize: 13)),
        ],
      ),
    );
  }

  Widget _fieldRow(String label, String value, {Widget? trailing}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          SizedBox(width: 110, child: Text(label, style: const TextStyle(fontSize: 12.5, color: AppColors.textMuted))),
          Expanded(child: Text(value, style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600))),
          if (trailing != null) trailing,
        ],
      ),
    );
  }
}
