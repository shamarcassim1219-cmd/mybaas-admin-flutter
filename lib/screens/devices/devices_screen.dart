import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../services/admin_device_service.dart';
import '../../services/api_exception.dart';

class DevicesScreen extends StatefulWidget {
  const DevicesScreen({super.key});

  @override
  State<DevicesScreen> createState() => _DevicesScreenState();
}

class _DevicesScreenState extends State<DevicesScreen> {
  bool _loading = true;
  String? _error;
  List<BannedDevice> _devices = [];
  final Set<String> _acting = {};

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
      final devices = await AdminDeviceService.instance.list();
      if (!mounted) return;
      setState(() {
        _devices = devices;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'Unable to load banned devices. Pull down to try again.';
        _loading = false;
      });
    }
  }

  Future<void> _unban(BannedDevice device) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Unban Device'),
        content: const Text('Allow this device to log in and register again?'),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.of(context).pop(true), child: const Text('Unban')),
        ],
      ),
    );
    if (confirmed != true) return;

    setState(() => _acting.add(device.deviceId));
    try {
      await AdminDeviceService.instance.unban(device.deviceId);
      await _load();
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _acting.remove(device.deviceId));
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    } catch (e) {
      if (!mounted) return;
      setState(() => _acting.remove(device.deviceId));
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Unable to unban this device. Please try again.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Banned Devices')),
      body: SafeArea(
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : RefreshIndicator(
                color: AppColors.primary,
                onRefresh: _load,
                child: _devices.isEmpty
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
                            child: Center(
                              child: Column(
                                children: [
                                  Icon(Icons.phonelink_erase_outlined, size: 48, color: AppColors.textMuted),
                                  SizedBox(height: 12),
                                  Text('No banned devices.', style: TextStyle(color: AppColors.textMuted)),
                                ],
                              ),
                            ),
                          ),
                        ],
                      )
                    : ListView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: const EdgeInsets.all(20),
                        children: _devices.map(_buildRow).toList(),
                      ),
              ),
      ),
    );
  }

  Widget _buildRow(BannedDevice d) {
    final busy = _acting.contains(d.deviceId);

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
          Text(d.deviceId, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13, fontFamily: 'monospace')),
          if (d.reason.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(d.reason, style: const TextStyle(fontSize: 12.5, color: AppColors.textSecondary)),
          ],
          const SizedBox(height: 6),
          Text(
            '${d.bannedAt.day}/${d.bannedAt.month}/${d.bannedAt.year}',
            style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: busy ? null : () => _unban(d),
              child: busy
                  ? const SizedBox(height: 16, width: 16, child: CircularProgressIndicator(strokeWidth: 2))
                  : const Text('Unban'),
            ),
          ),
        ],
      ),
    );
  }
}
