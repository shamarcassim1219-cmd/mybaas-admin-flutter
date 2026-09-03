import 'dart:convert';
import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../services/admin_complaint_service.dart';
import '../../services/api_exception.dart';

/// Full detail for one complaint - reason, details, the customer's
/// photos, and who's involved, with Approve/Reject actions.
/// Confirmed against the real backend: approving a complaint on a
/// pay_now order refunds the customer's wallet from the Baas's own
/// wallet balance, capped to what's actually available there.
class ComplaintDetailScreen extends StatefulWidget {
  final AdminComplaint complaint;

  const ComplaintDetailScreen({super.key, required this.complaint});

  @override
  State<ComplaintDetailScreen> createState() => _ComplaintDetailScreenState();
}

class _ComplaintDetailScreenState extends State<ComplaintDetailScreen> {
  bool _submitting = false;
  String? _error;

  Widget? _decodedImage(String dataUrl, BoxFit fit) {
    try {
      final commaIndex = dataUrl.indexOf(',');
      final bytes = base64Decode(commaIndex != -1 ? dataUrl.substring(commaIndex + 1) : dataUrl);
      return Image.memory(bytes, fit: fit);
    } catch (_) {
      return null;
    }
  }

  void _viewPhoto(String dataUrl) {
    final image = _decodedImage(dataUrl, BoxFit.contain);
    if (image == null) return;

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => Scaffold(
          backgroundColor: Colors.black,
          appBar: AppBar(backgroundColor: Colors.black, iconTheme: const IconThemeData(color: Colors.white)),
          body: Center(child: InteractiveViewer(child: image)),
        ),
      ),
    );
  }

  Future<void> _decide(String decision) async {
    final noteController = TextEditingController();
    final isApprove = decision == 'Approved';
    final c = widget.complaint;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(isApprove ? 'Approve Complaint' : 'Reject Complaint'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (isApprove && c.wouldRefundOnApprove && c.orderTotal != null)
              Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(color: AppColors.successSoft, borderRadius: BorderRadius.circular(AppSpacing.radiusMd)),
                child: Text(
                  'This is a Pay Now order that was paid. Approving will refund up to Rs. ${c.orderTotal!.toStringAsFixed(2)} to ${c.customerName}\'s wallet, capped to what\'s currently in the Baas\'s own wallet - if their balance is lower than the order total, the customer only gets back what\'s actually available.',
                  style: const TextStyle(fontSize: 12.5, color: AppColors.success, fontWeight: FontWeight.w600),
                ),
              )
            else if (isApprove)
              const Padding(
                padding: EdgeInsets.only(bottom: 10),
                child: Text(
                  'This order was Pay Direct (or unpaid), so no automatic refund applies.',
                  style: TextStyle(fontSize: 12.5, color: AppColors.textSecondary),
                ),
              ),
            TextField(
              controller: noteController,
              maxLines: 3,
              decoration: const InputDecoration(hintText: 'Admin note (optional)'),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.of(context).pop(true), child: Text(isApprove ? 'Approve' : 'Reject')),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() {
      _submitting = true;
      _error = null;
    });

    try {
      await AdminComplaintService.instance.decide(
        widget.complaint.complaintId.isNotEmpty ? widget.complaint.complaintId : widget.complaint.id,
        decision: decision,
        adminNote: noteController.text.trim(),
      );
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } on ApiException catch (e) {
      setState(() => _error = e.message);
    } catch (e) {
      setState(() => _error = 'Unable to submit decision. Please try again.');
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = widget.complaint;
    final isPending = c.status == 'Pending';

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Complaint Detail')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            _statusBadge(c.status),
            const SizedBox(height: 20),

            Text(c.reason, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
            const SizedBox(height: 6),
            Text('Order ${c.orderId}', style: const TextStyle(fontSize: 12.5, color: AppColors.textMuted)),
            if (c.orderTotal != null) ...[
              const SizedBox(height: 4),
              Text(
                'Order total: Rs. ${c.orderTotal!.toStringAsFixed(2)} (${c.orderPaymentMethod == 'pay_now' ? 'Pay Now' : 'Pay Direct'}${c.orderPaymentStatus == 'PAID' ? ', Paid' : ''})',
                style: const TextStyle(fontSize: 12.5, color: AppColors.textSecondary, fontWeight: FontWeight.w600),
              ),
            ],
            const SizedBox(height: 16),

            Text('Details', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 6),
            Text(c.details, style: const TextStyle(fontSize: 13.5, color: AppColors.textSecondary, height: 1.5)),
            const SizedBox(height: 20),

            _fieldRow('Customer', c.customerName),
            _fieldRow('Customer Mobile', c.customerMobile),
            _fieldRow('Baas', c.baasName.isNotEmpty ? c.baasName : '-'),
            _fieldRow('Baas Mobile', c.baasMobile.isNotEmpty ? c.baasMobile : '-'),

            if (c.adminNote.isNotEmpty) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: AppColors.warningSoft, borderRadius: BorderRadius.circular(AppSpacing.radiusMd)),
                child: Text('Note: ${c.adminNote}', style: const TextStyle(fontSize: 12.5, color: AppColors.textSecondary)),
              ),
            ],

            if (c.refunded && c.refundAmount != null) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: AppColors.successSoft, borderRadius: BorderRadius.circular(AppSpacing.radiusMd)),
                child: Text(
                  'Refunded Rs. ${c.refundAmount!.toStringAsFixed(2)} to customer wallet.',
                  style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: AppColors.success),
                ),
              ),
            ],

            if (c.photos.isNotEmpty) ...[
              const SizedBox(height: 24),
              Text('Photos', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 10),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: c.photos.map((p) {
                  final img = _decodedImage(p, BoxFit.cover);
                  return InkWell(
                    onTap: img != null ? () => _viewPhoto(p) : null,
                    borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                      child: SizedBox(
                        width: 90,
                        height: 90,
                        child: img ?? Container(color: AppColors.border),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],

            if (_error != null) ...[
              const SizedBox(height: 16),
              Text(_error!, style: const TextStyle(color: AppColors.danger, fontSize: 13)),
            ],

            if (isPending) ...[
              const SizedBox(height: 28),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _submitting ? null : () => _decide('Rejected'),
                      style: OutlinedButton.styleFrom(foregroundColor: AppColors.danger, minimumSize: const Size.fromHeight(48)),
                      child: const Text('Reject'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _submitting ? null : () => _decide('Approved'),
                      style: ElevatedButton.styleFrom(minimumSize: const Size.fromHeight(48)),
                      child: _submitting
                          ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2.2, color: Colors.white))
                          : const Text('Approve'),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _statusBadge(String status) {
    final (color, bg) = switch (status) {
      'Approved' => (AppColors.success, AppColors.successSoft),
      'Rejected' => (AppColors.danger, AppColors.dangerSoft),
      _ => (AppColors.warning, AppColors.warningSoft),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(AppSpacing.radiusPill)),
      child: Text(status, style: TextStyle(color: color, fontWeight: FontWeight.w800, fontSize: 13)),
    );
  }

  Widget _fieldRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: 130, child: Text(label, style: const TextStyle(fontSize: 12.5, color: AppColors.textMuted))),
          Expanded(child: Text(value, style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600))),
        ],
      ),
    );
  }
}
