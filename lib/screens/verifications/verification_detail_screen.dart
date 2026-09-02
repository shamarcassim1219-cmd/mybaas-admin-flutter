import 'dart:convert';
import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../services/admin_verification_service.dart';
import '../../services/api_exception.dart';

/// Full detail for one verification submission - all the fields
/// entered plus the three photos, with Approve/Reject actions at
/// the bottom. Confirmed against the real backend: approving or
/// rejecting fires both an in-app notification and an email to the
/// account automatically - nothing extra to do here beyond calling
/// the decision endpoint.
class VerificationDetailScreen extends StatefulWidget {
  final VerificationSubmission submission;

  const VerificationDetailScreen({super.key, required this.submission});

  @override
  State<VerificationDetailScreen> createState() => _VerificationDetailScreenState();
}

class _VerificationDetailScreenState extends State<VerificationDetailScreen> {
  bool _submitting = false;
  String? _error;

  Widget? _decodedImage(String dataUrl, BoxFit fit) {
    if (dataUrl.isEmpty) return null;
    try {
      final commaIndex = dataUrl.indexOf(',');
      final bytes = base64Decode(commaIndex != -1 ? dataUrl.substring(commaIndex + 1) : dataUrl);
      return Image.memory(bytes, fit: fit);
    } catch (_) {
      return null;
    }
  }

  void _viewPhoto(String dataUrl, String title) {
    final image = _decodedImage(dataUrl, BoxFit.contain);
    if (image == null) return;

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => Scaffold(
          backgroundColor: Colors.black,
          appBar: AppBar(
            backgroundColor: Colors.black,
            iconTheme: const IconThemeData(color: Colors.white),
            title: Text(title, style: const TextStyle(color: Colors.white)),
          ),
          body: Center(child: InteractiveViewer(child: image)),
        ),
      ),
    );
  }

  Future<void> _decide(String status) async {
    String note = '';

    if (status == 'Rejected') {
      final noteController = TextEditingController();
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Reject Verification'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Add a note explaining why (shown to the account).'),
              const SizedBox(height: 12),
              TextField(
                controller: noteController,
                maxLines: 3,
                decoration: const InputDecoration(hintText: 'e.g. NIC photo is blurry'),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Cancel')),
            TextButton(onPressed: () => Navigator.of(context).pop(true), child: const Text('Reject')),
          ],
        ),
      );
      if (confirmed != true) return;
      note = noteController.text.trim();
    } else {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Approve Verification'),
          content: Text('Approve verification for "${widget.submission.fullName}"? This gives them a verified badge.'),
          actions: [
            TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Cancel')),
            TextButton(onPressed: () => Navigator.of(context).pop(true), child: const Text('Approve')),
          ],
        ),
      );
      if (confirmed != true) return;
    }

    setState(() {
      _submitting = true;
      _error = null;
    });

    try {
      await AdminVerificationService.instance.decide(widget.submission.userId, status: status, note: note);
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
    final s = widget.submission;
    final isPending = s.status == 'Pending';

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Verification Detail')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            _statusBadge(s.status),
            const SizedBox(height: 20),

            _fieldRow('Full Name', s.fullName),
            _fieldRow('NIC Number', s.nic),
            _fieldRow('Phone', s.phone),
            _fieldRow('Address', s.address),
            _fieldRow('Province', s.province),
            _fieldRow('District', s.district),
            _fieldRow('Role', s.role),
            _fieldRow('Account Mobile', s.mobile),

            if (s.note.isNotEmpty) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: AppColors.warningSoft, borderRadius: BorderRadius.circular(AppSpacing.radiusMd)),
                child: Text('Note: ${s.note}', style: const TextStyle(fontSize: 12.5, color: AppColors.textSecondary)),
              ),
            ],

            const SizedBox(height: 24),
            Text('Photos', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(child: _photoThumb('NIC Front', s.nicPhoto)),
                const SizedBox(width: 10),
                Expanded(child: _photoThumb('NIC Back', s.nicBackPhoto)),
                const SizedBox(width: 10),
                Expanded(child: _photoThumb('Selfie', s.selfiePhoto)),
              ],
            ),

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
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: 110, child: Text(label, style: const TextStyle(fontSize: 12.5, color: AppColors.textMuted))),
          Expanded(child: Text(value.isNotEmpty ? value : '-', style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600))),
        ],
      ),
    );
  }

  Widget _photoThumb(String label, String dataUrl) {
    final img = _decodedImage(dataUrl, BoxFit.cover);

    return Column(
      children: [
        InkWell(
          onTap: img != null ? () => _viewPhoto(dataUrl, label) : null,
          borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
            child: AspectRatio(
              aspectRatio: 1,
              child: img ?? Container(color: AppColors.border, child: const Icon(Icons.image_not_supported_outlined, color: AppColors.textMuted)),
            ),
          ),
        ),
        const SizedBox(height: 4),
        Text(label, style: const TextStyle(fontSize: 10.5, color: AppColors.textMuted)),
      ],
    );
  }
}
