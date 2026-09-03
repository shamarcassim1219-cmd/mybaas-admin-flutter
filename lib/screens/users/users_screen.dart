import 'dart:async';
import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../services/admin_user_service.dart';
import 'user_detail_screen.dart';

class UsersScreen extends StatefulWidget {
  const UsersScreen({super.key});

  @override
  State<UsersScreen> createState() => _UsersScreenState();
}

class _UsersScreenState extends State<UsersScreen> {
  final _searchController = TextEditingController();
  Timer? _debounce;

  bool _loading = true;
  String? _error;
  List<AdminUserSummary> _users = [];
  String? _roleFilter; // null | 'customer' | 'baas'

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final users = await AdminUserService.instance.list(
        role: _roleFilter,
        query: _searchController.text.trim().isEmpty ? null : _searchController.text.trim(),
      );
      if (!mounted) return;
      setState(() {
        _users = users;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'Unable to load users. Pull down to try again.';
        _loading = false;
      });
    }
  }

  void _onSearchChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), _load);
  }

  Future<void> _openDetail(AdminUserSummary user) async {
    final changed = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => UserDetailScreen(userId: user.id)),
    );
    if (changed == true) _load();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Users')),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
              child: TextField(
                controller: _searchController,
                onChanged: _onSearchChanged,
                decoration: const InputDecoration(
                  hintText: 'Search name, mobile, email, id',
                  prefixIcon: Icon(Icons.search, size: 20),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  Expanded(child: _roleChip('All', null)),
                  const SizedBox(width: 8),
                  Expanded(child: _roleChip('Customers', 'customer')),
                  const SizedBox(width: 8),
                  Expanded(child: _roleChip('Baas', 'baas')),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator())
                  : RefreshIndicator(
                      color: AppColors.primary,
                      onRefresh: _load,
                      child: _users.isEmpty
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
                                  child: Center(child: Text('No users found.', style: TextStyle(color: AppColors.textMuted))),
                                ),
                              ],
                            )
                          : ListView(
                              physics: const AlwaysScrollableScrollPhysics(),
                              padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                              children: _users.map(_buildRow).toList(),
                            ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _roleChip(String label, String? value) {
    final selected = _roleFilter == value;
    return ChoiceChip(
      label: Text(label, textAlign: TextAlign.center),
      selected: selected,
      onSelected: (_) {
        setState(() => _roleFilter = value);
        _load();
      },
      selectedColor: AppColors.accentSoft,
      labelStyle: TextStyle(
        color: selected ? AppColors.accent : AppColors.textSecondary,
        fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
      ),
      side: BorderSide(color: selected ? AppColors.accent : AppColors.border),
      backgroundColor: AppColors.surface,
    );
  }

  Widget _buildRow(AdminUserSummary u) {
    return InkWell(
      onTap: () => _openDetail(u),
      borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: u.isDisabled ? AppColors.dangerSoft : AppColors.surface,
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          border: Border.all(color: u.isDisabled ? AppColors.danger.withValues(alpha: 0.3) : AppColors.border),
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 20,
              backgroundColor: AppColors.primarySoft,
              child: Text(
                u.name.isNotEmpty && u.name != '(no name)' ? u.name[0].toUpperCase() : '?',
                style: const TextStyle(fontWeight: FontWeight.w800, color: AppColors.primary),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(child: Text(u.name, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14))),
                      if (u.isDisabled) ...[
                        const SizedBox(width: 6),
                        const Icon(Icons.block, size: 14, color: AppColors.danger),
                      ],
                    ],
                  ),
                  const SizedBox(height: 3),
                  Text(
                    '${u.role.isNotEmpty ? u.role[0].toUpperCase() + u.role.substring(1) : 'Unknown'} - ${u.mobile.isNotEmpty ? u.mobile : u.email}',
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
