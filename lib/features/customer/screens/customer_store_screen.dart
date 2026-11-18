import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../admin/providers/customers_provider.dart' show kCustomerChannels;
import '../../admin/providers/delivery_routes_provider.dart' show deliveryRoutesStreamProvider;
import '../providers/customer_providers.dart';
import '../widgets/customer_common.dart';

/// "Set up your store" (no customers row yet) and "Edit store" (there is one).
///
/// This is the form that makes a customer ROUTABLE: store → town → the route that
/// serves it → delivery days and sales rep → the rep on their orders and
/// payments. The town is a picker over what routes actually serve; the route
/// itself is derived and shown read-only, never chosen.
class CustomerStoreScreen extends ConsumerStatefulWidget {
  const CustomerStoreScreen({super.key});

  @override
  ConsumerState<CustomerStoreScreen> createState() => _CustomerStoreScreenState();
}

class _CustomerStoreScreenState extends ConsumerState<CustomerStoreScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _store;
  late final TextEditingController _phone;
  late final TextEditingController _barangay;
  late final TextEditingController _address;
  String? _town;
  String? _channel;
  bool _saving = false;
  late final bool _setup;

  @override
  void initState() {
    super.initState();
    final p = ref.read(customerProfileProvider);
    _setup = !p.hasCustomerRecord;
    // The provider's 'My Store' placeholder is not a real name: don't pre-fill it.
    _store = TextEditingController(text: _setup ? '' : p.storeName);
    _phone = TextEditingController(text: p.phone);
    _barangay = TextEditingController(text: p.barangay);
    _address = TextEditingController(text: p.address);
    _town = p.town.isEmpty ? null : p.town;
    _channel = p.channel.isEmpty ? null : p.channel;
  }

  @override
  void dispose() {
    _store.dispose();
    _phone.dispose();
    _barangay.dispose();
    _address.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    final details = StoreDetails(
      storeName: _store.text.trim(),
      town: _town ?? '',
      phone: _phone.text.trim(),
      barangay: _barangay.text.trim(),
      channel: _channel ?? '',
      address: _address.text.trim(),
    );
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    try {
      final profile = ref.read(customerProfileProvider);
      if (profile.hasCustomerRecord) {
        await updateStoreDetails(ref, profile.customerUuid!, details);
      } else {
        await createStoreForCurrentUser(ref, details);
      }
      navigator.pop(true);
      messenger.showSnackBar(SnackBar(content: Text(_setup ? 'Your store is set up' : 'Store details updated')));
    } catch (e) {
      if (mounted) setState(() => _saving = false);
      messenger.showSnackBar(SnackBar(content: Text('Could not save: $e')));
    }
  }

  InputDecoration _decoration(String label, {String? hint}) => InputDecoration(labelText: label, hintText: hint, filled: true, fillColor: Colors.white);

  @override
  Widget build(BuildContext context) {
    final routes = ref.watch(deliveryRoutesStreamProvider).valueOrNull ?? [];
    final options = townOptions(routes, current: _town ?? '');
    final match = matchRouteForTown(_town ?? '', routes);
    final channels = {...kCustomerChannels, if (_channel != null) _channel!}.toList();

    return Scaffold(
      backgroundColor: CcColors.page,
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: CcColors.text,
        elevation: 0,
        title: Text(_setup ? 'Set up your store' : 'Edit store', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560),
            child: Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  if (_setup) ...[
                    const Text(
                      'Tell us about your store so we can schedule your deliveries and assign your sales rep. You need this before you can place orders.',
                      style: TextStyle(fontSize: 14, color: CcColors.muted),
                    ),
                    const SizedBox(height: 16),
                  ],
                  TextFormField(
                    controller: _store,
                    textCapitalization: TextCapitalization.words,
                    decoration: _decoration('Store name'),
                    validator: (v) => (v ?? '').trim().isEmpty ? 'Enter your store name' : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _phone,
                    keyboardType: TextInputType.phone,
                    decoration: _decoration('Contact number', hint: '0917 555 0142'),
                    validator: (v) => (v ?? '').trim().isEmpty ? 'Enter a contact number' : null,
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    key: const Key('town-picker'),
                    initialValue: _town,
                    isExpanded: true,
                    decoration: _decoration('Town'),
                    items: [
                      for (final o in options)
                        DropdownMenuItem(value: o.town, child: Text(o.served ? o.town : '${o.town} — not served yet')),
                    ],
                    onChanged: (v) => setState(() => _town = v),
                    validator: (v) => v == null ? 'Choose your town' : null,
                  ),
                  const SizedBox(height: 10),
                  _RoutePreview(town: _town, match: match),
                  const SizedBox(height: 12),
                  TextFormField(controller: _barangay, textCapitalization: TextCapitalization.words, decoration: _decoration('Barangay')),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    initialValue: _channel,
                    isExpanded: true,
                    decoration: _decoration('Channel'),
                    items: [for (final c in channels) DropdownMenuItem(value: c, child: Text(c))],
                    onChanged: (v) => setState(() => _channel = v),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _address,
                    textCapitalization: TextCapitalization.sentences,
                    minLines: 1,
                    maxLines: 3,
                    decoration: _decoration('Delivery address'),
                  ),
                  const SizedBox(height: 20),
                  CcPrimaryButton(label: _saving ? 'Saving...' : (_setup ? 'Save and continue' : 'Save'), onPressed: _saving ? null : _save),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// The consequence of the chosen town, read-only: the derived route, delivery
/// days and sales rep — or an explicit "we don't deliver there yet".
class _RoutePreview extends StatelessWidget {
  const _RoutePreview({required this.town, required this.match});
  final String? town;
  final RouteMatch match;

  @override
  Widget build(BuildContext context) {
    final t = town;
    if (t == null || t.isEmpty) {
      return const Text('Pick your town to see your delivery route.', style: TextStyle(fontSize: 13, color: CcColors.muted));
    }
    final route = match.route;
    if (route == null) {
      return Container(
        key: const Key('route-preview-unserved'),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(color: const Color(0xFFFEF2F2), borderRadius: BorderRadius.circular(10), border: Border.all(color: CcColors.red)),
        child: Text(
          "We don't deliver to $t yet. You can still save your store, but we can't schedule deliveries or assign a sales rep until a route covers $t.",
          style: const TextStyle(fontSize: 13, color: Color(0xFFB91C1C)),
        ),
      );
    }
    final days = route.deliveryDays.split(',').map((d) => d.trim()).where((d) => d.isNotEmpty).join(' & ');
    final rep = (route.assignedRepName ?? '').trim();
    return Container(
      key: const Key('route-preview'),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(10), border: Border.all(color: CcColors.border)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        _line('Route', route.routeName),
        _line('Delivery days', days.isEmpty ? '—' : days),
        _line('Sales rep', rep.isEmpty ? 'Not assigned yet' : rep),
      ]),
    );
  }

  Widget _line(String label, String value) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 2),
        child: Row(children: [
          SizedBox(width: 110, child: Text(label, style: const TextStyle(fontSize: 13, color: CcColors.muted))),
          Expanded(child: Text(value, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: CcColors.text))),
        ]),
      );
}

/// Opens the setup / edit form. Returns true if something was saved.
Future<bool?> openCustomerStore(BuildContext context) =>
    Navigator.of(context).push<bool>(MaterialPageRoute(builder: (_) => const CustomerStoreScreen()));

/// The prominent prompt shown to a customer with no store record yet. Without a
/// record there is no town, so no route, no rep and no delivery day — and their
/// orders can't sync. [compact] is the shorter wording for the cart.
class SetUpStoreBanner extends StatelessWidget {
  const SetUpStoreBanner({super.key});

  @override
  Widget build(BuildContext context) => Container(
        key: const Key('setup-store-banner'),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(color: const Color(0xFFFFFBEB), borderRadius: BorderRadius.circular(12), border: Border.all(color: const Color(0xFFD97706))),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Row(children: [
            Icon(Icons.storefront_outlined, color: Color(0xFF92400E)),
            SizedBox(width: 8),
            Expanded(child: Text('Set up your store', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Color(0xFF92400E)))),
          ]),
          const SizedBox(height: 6),
          const Text(
            'Add your store name, town and contact number so we can schedule your deliveries and assign your sales rep. You need this before you can place orders.',
            style: TextStyle(fontSize: 13, color: Color(0xFF92400E)),
          ),
          const SizedBox(height: 10),
          CcPrimaryButton(label: 'Set up now', height: 44, onPressed: () => openCustomerStore(context)),
        ]),
      );
}
