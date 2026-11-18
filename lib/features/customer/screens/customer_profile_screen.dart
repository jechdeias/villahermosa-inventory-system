import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:package_info_plus/package_info_plus.dart';
import '../../../core/auth/auth_service.dart';
import '../../auth/set_password_dialog.dart';
import '../providers/customer_providers.dart';
import '../widgets/customer_common.dart';
import '../widgets/customer_shell.dart';
import 'customer_store_screen.dart';
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
              if (!p.hasCustomerRecord) ...[const SizedBox(height: 8), const SetUpStoreBanner()],
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const CcSectionLabel('Store details'),
                  if (p.hasCustomerRecord)
                    InkWell(
                      key: const Key('edit-store'),
                      onTap: () => openCustomerStore(context),
                      child: const Padding(
                        padding: EdgeInsets.symmetric(vertical: 4, horizontal: 2),
                        child: Text('Edit', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: CcColors.blue)),
                      ),
                    ),
                ],
              ),
              CcInfoRows(rows: [
                (label: 'Store name', value: ccValueText(p.hasCustomerRecord ? p.storeName : '—')),
                (label: 'Address', value: ccValueText(p.address.isEmpty ? '—' : p.address)),
                (label: 'Barangay', value: ccValueText(p.barangay.isEmpty ? '—' : p.barangay)),
                (label: 'Town', value: ccValueText(p.town.isEmpty ? '—' : p.town)),
                // Derived from the town, read-only: the consequence of the choice above.
                (
                  label: 'Route',
                  value: p.townNotServed
                      ? ccValueText('Not served yet', color: CcColors.red)
                      : ccValueText(p.routeName.isEmpty ? '—' : p.routeName),
                ),
                (
                  label: 'Delivery days',
                  value: ccValueText(p.deliveryDays.isEmpty ? '—' : p.deliveryDays.split(',').map((d) => d.trim()).join(' & ')),
                ),
                (label: 'Sales rep', value: ccValueText(p.repName.isEmpty ? '—' : p.repName)),
                (label: 'Contact', value: ccValueText(p.phone.isEmpty ? '—' : p.phone)),
                (label: 'Email', value: ccValueText(p.email.isEmpty ? '—' : p.email)),
              ]),
              if (p.townNotServed) ...[
                const SizedBox(height: 8),
                Text(
                  "We don't deliver to ${p.town} yet, so there is no route, delivery day or sales rep for your store. Change your town if it is wrong.",
                  key: const Key('profile-unserved-note'),
                  style: const TextStyle(fontSize: 13, color: CcColors.red),
                ),
              ],
              const SizedBox(height: 8),
              const CcSectionLabel('Account'),
              CcInfoRows(rows: [
                // Accounts created through Google sign-in have no password; this is
                // the permanent way to add one (the post-sign-in prompt is once only).
                if (AuthService.instance.currentUserNeedsPassword)
                  (
                    label: 'Password',
                    value: Wrap(crossAxisAlignment: WrapCrossAlignment.center, alignment: WrapAlignment.end, spacing: 12, children: [
                      ccValueText('Not set'),
                      InkWell(
                        onTap: () async {
                          await showSetPasswordDialog(context);
                          if (mounted) setState(() {});
                        },
                        child: const Text('Set', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: CcColors.blue)),
                      ),
                    ]),
                  ),
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
