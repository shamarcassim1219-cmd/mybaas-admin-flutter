import 'dart:async';
import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../services/admin_order_service.dart';
import '../../services/api_exception.dart';

class OrdersScreen extends StatefulWidget {
  const OrdersScreen({super.key});

  @override
  State<OrdersScreen> createState() => _OrdersScreenState();
}

class _OrdersScreenState extends State<OrdersScreen> {
  final _searchController = TextEditingController();
  Timer? _debounce;

  bool _loading = true;
  String? _error;
  List<AdminOrder> _orders = [];
  final Set<String> _acting = {};

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
      final orders = await AdminOrderService.instance.list(
        query: _searchController.text.trim().isEmpty ? null : _searchController.text.trim(),
      );
      if (!mounted) return;
      setState(() {
        _orders = orders;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'Unable to load orders. Pull down to try again.';
        _loading = false;
      });
    }
  }

  void _onSearchChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), _load);
  }

  Future<void> _applyDiscount(AdminOrder order) async {
    final amountController = TextEditingController();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Apply Discount'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Current total: Rs. ${order.total.toStringAsFixed(2)}'),
            const SizedBox(height: 12),
            TextField(
              controller: amountController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(hintText: 'Discount amount', prefixText: 'Rs. '),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.of(context).pop(true), child: const Text('Apply')),
        ],
      ),
    );
    if (confirmed != true) return;

    final amount = double.tryParse(amountController.text.trim());
    if (amount == null || amount <= 0) return;

    setState(() => _acting.add(order.id));
    try {
      await AdminOrderService.instance.applyDiscount(order.id, amount);
      await _load();
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _acting.remove(order.id));
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    } catch (e) {
      if (!mounted) return;
      setState(() => _acting.remove(order.id));
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Unable to apply discount. Please try again.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Orders')),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
              child: TextField(
                controller: _searchController,
                onChanged: _onSearchChanged,
                decoration: const InputDecoration(
                  hintText: 'Search order ID, service, Baas',
                  prefixIcon: Icon(Icons.search, size: 20),
                ),
              ),
            ),
            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator())
                  : RefreshIndicator(
                      color: AppColors.primary,
                      onRefresh: _load,
                      child: _orders.isEmpty
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
                                  child: Center(child: Text('No orders found.', style: TextStyle(color: AppColors.textMuted))),
                                ),
                              ],
                            )
                          : ListView(
                              physics: const AlwaysScrollableScrollPhysics(),
                              padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                              children: _orders.map(_buildRow).toList(),
                            ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRow(AdminOrder o) {
    final busy = _acting.contains(o.id);

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
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
              Expanded(child: Text(o.service, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14.5))),
              Text('Rs. ${o.total.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15, color: AppColors.primary)),
            ],
          ),
          const SizedBox(height: 4),
          Text(o.orderId, style: const TextStyle(fontSize: 12, color: AppColors.textMuted)),
          const SizedBox(height: 4),
          Text(
            '${o.status} - ${o.paymentMethod == 'pay_now' ? 'Pay Now' : 'Pay Direct'}${o.paymentStatus == 'PAID' ? ', Paid' : ''}',
            style: const TextStyle(fontSize: 12.5, color: AppColors.textSecondary),
          ),
          if (o.professional != null) Text('Baas: ${o.professional}', style: const TextStyle(fontSize: 12.5, color: AppColors.textSecondary)),

          if (o.canDiscount) ...[
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: busy ? null : () => _applyDiscount(o),
                child: busy
                    ? const SizedBox(height: 16, width: 16, child: CircularProgressIndicator(strokeWidth: 2))
                    : const Text('Apply Discount'),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
