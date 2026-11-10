import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:package_info_plus/package_info_plus.dart';
import '../../../core/auth/auth_service.dart';
import '../../../core/database/app_database.dart';
import '../../admin/providers/customers_provider.dart' show customersProvider, kCustomerTowns, kCustomerChannels;
import '../providers/customer_providers.dart';
import '../widgets/customer_common.dart';
import '../widgets/customer_shell.dart';
import '../../../core/theme/app_theme.dart';


class CustomerProfileScreen extends ConsumerStatefulWidget {
  const CustomerProfileScreen({super.key});

  @override
  ConsumerState<CustomerProfileScreen> createState() => _CustomerProfileScreenState();
}

class _CustomerProfileScreenState extends ConsumerState<CustomerProfileScreen> {
  late final Future<String> _version = _loadVersion();

  Future<String> _loadVersion() async {
    try {
      final info = await PackageInfo.fromPlatform();
      return info.version;
    } catch (_) {
      return '—';
    }
  }

  String _initials(CustomerProfile p) {
    final parts = p.ownerName.split(' ').where((s) => s.isNotEmpty).toList();
    if (parts.isEmpty) return p.storeName.isEmpty ? '?' : p.storeName[0].toUpperCase();
    if (parts.length == 1) return parts.first[0].toUpperCase();
    return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
  }

  Future<void> _editStoreDetails(CustomerProfile p) async {
    if (p.customerUuid == null) return;
    final barangayCtrl = TextEditingController(text: p.barangay);
    String? town = p.town.isEmpty ? null : p.town;
    String? channel = p.channel.isEmpty ? null : p.channel;

    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          backgroundColor: Colors.white,
          surfaceTintColor: Colors.transparent,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text('Edit Store Details', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
          content: SingleChildScrollView(
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              TextField(
                controller: barangayCtrl,
                decoration: const InputDecoration(labelText: 'Barangay'),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: town,
                decoration: const InputDecoration(labelText: 'Town'),
                items: kCustomerTowns.map((t) => DropdownMenuItem(value: t, child: Text(t))).toList(),
                onChanged: (v) => setDialogState(() => town = v),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: channel,
                decoration: const InputDecoration(labelText: 'Channel'),
                items: kCustomerChannels.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                onChanged: (v) => setDialogState(() => channel = v),
              ),
            ]),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel', style: TextStyle(color: CcColors.muted))),
            CcPrimaryButton(label: 'Save', expand: false, height: 44, onPressed: () => Navigator.pop(ctx, true)),
          ],
        ),
      ),
    );
    final barangay = barangayCtrl.text.trim();
    barangayCtrl.dispose();
    if (ok != true || p.customerUuid == null) return;
    try {
      final db = AuthService.instance.database;
      await db.updateCustomer(
        p.customerUuid!,
        CustomersCompanion(
          barangay: Value(barangay.isEmpty ? null : barangay),
          town: Value(town),
          municipality: Value(town ?? ''),
          channel: Value(channel),
          storeType: Value(channel ?? ''),
          syncStatus: const Value('pending'),
          updatedAt: Value(DateTime.now()),
        ),
      );
      ref.invalidate(customersProvider);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Store details updated')));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  Future<void> _editPhone(CustomerProfile p) async {
    final ctrl = TextEditingController(text: p.phone);
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Contact number', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
        content: TextField(controller: ctrl, keyboardType: TextInputType.phone, autofocus: true, decoration: const InputDecoration(hintText: '0917 555 0142')),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel', style: TextStyle(color: CcColors.muted))),
          CcPrimaryButton(label: 'Save', expand: false, height: 44, onPressed: () => Navigator.pop(ctx, true)),
        ],
      ),
    );
    final phone = ctrl.text.trim();
    ctrl.dispose();
    if (ok != true || phone.isEmpty || p.customerUuid == null) return;
    await updateCustomerPhone(ref, p.customerUuid!, phone);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Contact number updated')));
  }

  Future<void> _logout() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Log out?', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
        content: const Text('You will need to sign in again to place orders.', style: TextStyle(fontSize: 14, color: CcColors.muted)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel', style: TextStyle(color: CcColors.muted))),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: CcColors.red, foregroundColor: Colors.white, elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
            child: const Text('Log Out'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    await AuthService.instance.logout();
    ref.read(cartProvider.notifier).clear();
    if (!mounted) return;
    Navigator.of(context).pushNamedAndRemoveUntil('/login', (_) => false);
  }

  @override
  Widget build(BuildContext context) {
    final p = ref.watch(customerProfileProvider);
    final townLine = p.town.isEmpty ? '—' : '${p.town}, Marinduque';
    final routeLine = p.routeName.isEmpty ? '—' : [p.routeName, if (p.deliveryDays.isNotEmpty) p.deliveryDays.split(',').map((d) => d.trim()).join(' & ')].join(' · ');

    return CustomerShell(
      currentRoute: CustomerRoutes.profile,
      child: Column(children: [
        const CcTitleBar(title: 'My Store'),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              CcCard(
                child: Row(children: [
                  CircleAvatar(
                    radius: 30,
                    backgroundColor: CcColors.primary,
                    child: Text(_initials(p), style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: Colors.white)),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(p.storeName, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: CcColors.text)),
                      const SizedBox(height: 6),
                      Wrap(crossAxisAlignment: WrapCrossAlignment.center, spacing: 10, runSpacing: 4, children: [
                        if (p.ownerName.isNotEmpty) Text(p.ownerName, style: const TextStyle(fontSize: 16, color: CcColors.muted)),
                        if (p.channel.isNotEmpty) CcBadge(p.channel, bg: AppTheme.infoLight, fg: CcColors.blue),
                      ]),
                    ]),
                  ),
                ]),
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const CcSectionLabel('Store details'),
                  if (p.hasCustomerRecord)
                    InkWell(
                      onTap: () => _editStoreDetails(p),
                      child: const Padding(
                        padding: EdgeInsets.symmetric(vertical: 4, horizontal: 2),
                        child: Text('Edit', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: CcColors.blue)),
                      ),
                    ),
                ],
              ),
              CcInfoRows(rows: [
                (label: 'Barangay', value: ccValueText(p.barangay.isEmpty ? '—' : p.barangay)),
                (label: 'Town', value: ccValueText(townLine)),
                (label: 'Route', value: ccValueText(routeLine)),
                (
                  label: 'Contact',
                  value: Wrap(crossAxisAlignment: WrapCrossAlignment.center, alignment: WrapAlignment.end, spacing: 12, children: [
                    ccValueText(p.phone.isEmpty ? '—' : p.phone),
                    if (p.hasCustomerRecord)
                      InkWell(onTap: () => _editPhone(p), child: const Text('Edit', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: CcColors.blue))),
                  ]),
                ),
                (label: 'Email', value: ccValueText(p.email.isEmpty ? '—' : p.email)),
              ]),
              const SizedBox(height: 8),
              const CcSectionLabel('Account'),
              CcInfoRows(rows: [
                (label: 'Member since', value: ccValueText(p.memberSince == null ? '—' : ccMonthYear(p.memberSince!))),
                (
                  label: 'App version',
                  value: FutureBuilder<String>(future: _version, builder: (_, s) => ccValueText(s.data ?? '…')),
                ),
              ]),
              const SizedBox(height: 18),
              OutlinedButton.icon(
                onPressed: _logout,
                icon: const Icon(Icons.logout, size: 20),
                label: const Text('Log Out'),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 52),
                  foregroundColor: const Color(0xFFB91C1C),
                  backgroundColor: Colors.white,
                  side: const BorderSide(color: CcColors.red),
                  textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
              ),
            ],
          ),
        ),
      ]),
    );
  }
}
