import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/database/app_database.dart';
import '../../../core/sync/sync_manager.dart';
import '../../admin/providers/products_provider.dart';
import '../providers/sales_providers.dart';

Future<void> showNewOrderFlow(BuildContext context) {
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => UncontrolledProviderScope(
      container: ProviderScope.containerOf(context),
      child: SizedBox(
        height: MediaQuery.of(context).size.height * 0.92,
        child: const NewOrderFlow(),
      ),
    ),
  );
}

class _CartLine {
  _CartLine(this.product, this.quantity);
  final Product product;
  int quantity;
  double get subtotal => product.unitPrice * quantity;
}

class NewOrderFlow extends ConsumerStatefulWidget {
  const NewOrderFlow({super.key});

  @override
  ConsumerState<NewOrderFlow> createState() => _NewOrderFlowState();
}

class _NewOrderFlowState extends ConsumerState<NewOrderFlow> {
  int _step = 0;
  Customer? _selectedCustomer;
  final Map<String, _CartLine> _cart = {}; // keyed by product.uuid
  String _paymentMethod = 'Cash';
  final _customerSearchCtrl = TextEditingController();
  final _productSearchCtrl = TextEditingController();
  bool _saving = false;

  @override
  void dispose() {
    _customerSearchCtrl.dispose();
    _productSearchCtrl.dispose();
    super.dispose();
  }

  double get _total => _cart.values.fold(0.0, (s, l) => s + l.subtotal);

  void _close() => Navigator.of(context).pop();

  Future<void> _submit({required bool asDraft}) async {
    if (_selectedCustomer == null || _cart.isEmpty || _saving) return;
    setState(() => _saving = true);
    final messenger = ScaffoldMessenger.of(context);
    final db = ref.read(salesDatabaseProvider);
    final rep = ref.read(currentSalesRepProvider);
    final route = ref.read(salesRepRouteProvider);

    try {
      final orderNumber = await db.generateOrderNumber();
      final orderUuid = 'ord-${DateTime.now().microsecondsSinceEpoch}';
      final storeName = salesDisplayStoreName(_selectedCustomer!);
      final now = DateTime.now();
      final paidUpfront = _paymentMethod != 'Credit';

      final orderId = await db.createOrder(OrdersCompanion(
        uuid: Value(orderUuid),
        orderNumber: Value(orderNumber),
        customerId: Value(_selectedCustomer!.uuid),
        storeName: Value(storeName),
        routeName: Value(route?.routeName),
        salesRepId: Value(rep?.id),
        salesRepName: Value(rep == null ? null : '${rep.firstName} ${rep.lastName}'.trim()),
        itemCount: Value(_cart.values.fold(0, (s, l) => s + l.quantity)),
        totalAmount: Value(_total),
        status: Value(asDraft ? 'draft' : 'pending'),
        syncStatus: const Value('pending'),
        deliveryAddress: Value(_selectedCustomer!.address ?? storeName),
        paymentStatus: Value(_paymentMethod == 'Credit' ? 'pending' : 'paid'),
        createdAt: Value(now),
        updatedAt: Value(now),
      ));

      var i = 0;
      for (final line in _cart.values) {
        await db.createOrderItem(OrderItemsCompanion(
          uuid: Value('item-${DateTime.now().microsecondsSinceEpoch}-${i++}'),
          orderId: Value(orderUuid),
          productId: Value(line.product.uuid),
          productSku: Value(line.product.sku),
          productName: Value(line.product.name),
          quantity: Value(line.quantity),
          unitPrice: Value(line.product.unitPrice),
          subtotal: Value(line.subtotal),
          totalAmount: Value(line.subtotal),
          availableStock: Value(line.product.currentStock),
          syncStatus: const Value('pending'),
        ));
      }

      final paymentId = await db.generatePaymentId();
      await db.createPayment(PaymentsCompanion(
        paymentId: Value(paymentId),
        orderId: Value(orderId),
        orderCode: Value(orderNumber),
        storeName: Value(storeName),
        salesRepId: Value(rep?.id ?? 0),
        salesRepName: Value(rep == null ? '' : '${rep.firstName} ${rep.lastName}'.trim()),
        orderAmount: Value(_total),
        amountPaid: Value(paidUpfront ? _total : 0),
        balance: Value(paidUpfront ? 0 : _total),
        paymentMethod: Value(paidUpfront ? _paymentMethod : null),
        paymentDate: Value(now),
        status: Value(paidUpfront ? 'paid' : 'unpaid'),
        syncStatus: const Value('pending'),
      ));

      if (!asDraft) {
        try {
          await SyncManager.instance.push();
        } catch (_) {}
      }

      if (mounted) {
        _close();
        messenger.showSnackBar(SnackBar(
          content: Text(asDraft ? 'Order saved as draft' : 'Order submitted'),
        ));
      }
    } catch (e) {
      if (mounted) {
        messenger.showSnackBar(SnackBar(content: Text('Failed to save order: $e')));
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      child: Column(
        children: [
          _Header(onClose: _close),
          _StepIndicator(step: _step),
          const Divider(height: 1),
          Expanded(
            child: switch (_step) {
              0 => _StoreStep(
                  searchCtrl: _customerSearchCtrl,
                  selected: _selectedCustomer,
                  onSelect: (c) => setState(() => _selectedCustomer = c),
                ),
              1 => _ItemsStep(
                  searchCtrl: _productSearchCtrl,
                  cart: _cart,
                  onChanged: () => setState(() {}),
                ),
              _ => _ReviewStep(
                  customer: _selectedCustomer!,
                  cart: _cart,
                  total: _total,
                  paymentMethod: _paymentMethod,
                  onPaymentMethodChanged: (m) => setState(() => _paymentMethod = m),
                ),
            },
          ),
          _BottomBar(
            step: _step,
            canProceed: _step == 0 ? _selectedCustomer != null : _cart.isNotEmpty,
            total: _total,
            saving: _saving,
            onNext: () => setState(() => _step++),
            onSubmit: () => _submit(asDraft: false),
            onSaveDraft: () => _submit(asDraft: true),
          ),
        ],
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.onClose});
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 12, 12),
      child: Row(children: [
        const Expanded(
          child: Text('New Order', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: Color(0xFF111827))),
        ),
        IconButton(onPressed: onClose, icon: const Icon(Icons.close)),
      ]),
    );
  }
}

class _StepIndicator extends StatelessWidget {
  const _StepIndicator({required this.step});
  final int step;

  static const _labels = ['1 · Store', '2 · Items', '3 · Review'];

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
      child: Row(
        children: List.generate(3, (i) {
          final active = i == step;
          final completed = i < step;
          final color = active
              ? const Color(0xFF1E1E1E)
              : (completed ? const Color(0xFF059669) : const Color(0xFF9CA3AF));
          return Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 10),
              decoration: BoxDecoration(
                border: Border(bottom: BorderSide(color: active ? const Color(0xFF1E1E1E) : Colors.transparent, width: 2)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (completed) ...[
                    const Icon(Icons.check_circle, size: 14, color: Color(0xFF059669)),
                    const SizedBox(width: 4),
                  ],
                  Text(_labels[i],
                      style: TextStyle(fontSize: 12, fontWeight: active ? FontWeight.w600 : FontWeight.w400, color: color)),
                ],
              ),
            ),
          );
        }),
      ),
    );
  }
}

class _SearchField extends StatelessWidget {
  const _SearchField({required this.controller, required this.hint, required this.onChanged});
  final TextEditingController controller;
  final String hint;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 48,
      child: TextField(
        controller: controller,
        onChanged: onChanged,
        style: const TextStyle(fontSize: 14),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: const TextStyle(fontSize: 14, color: Color(0xFF9CA3AF)),
          prefixIcon: const Icon(Icons.search, size: 18, color: Color(0xFF9CA3AF)),
          filled: true,
          fillColor: const Color(0xFFF9FAFB),
          contentPadding: const EdgeInsets.symmetric(vertical: 0),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFFE5E7EB))),
          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFFE5E7EB))),
          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFF1E1E1E))),
        ),
      ),
    );
  }
}

// ── Step 1: Store ────────────────────────────────────────────────────────────

class _StoreStep extends ConsumerStatefulWidget {
  const _StoreStep({required this.searchCtrl, required this.selected, required this.onSelect});
  final TextEditingController searchCtrl;
  final Customer? selected;
  final ValueChanged<Customer> onSelect;

  @override
  ConsumerState<_StoreStep> createState() => _StoreStepState();
}

class _StoreStepState extends ConsumerState<_StoreStep> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final customers = ref.watch(allCustomersProvider).value ?? [];
    final q = _query.toLowerCase();
    final filtered = q.isEmpty
        ? customers
        : customers.where((c) =>
            salesDisplayStoreName(c).toLowerCase().contains(q) ||
            (c.barangay ?? '').toLowerCase().contains(q)).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
          child: _SearchField(
            controller: widget.searchCtrl,
            hint: "Search your route's stores...",
            onChanged: (v) => setState(() => _query = v),
          ),
        ),
        Expanded(
          child: filtered.isEmpty
              ? const Center(child: Text('No stores found', style: TextStyle(color: Color(0xFF9CA3AF))))
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  itemCount: filtered.length,
                  itemBuilder: (context, i) {
                    final c = filtered[i];
                    final isSelected = widget.selected?.uuid == c.uuid;
                    return InkWell(
                      onTap: () => widget.onSelect(c),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        child: Row(children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(salesDisplayStoreName(c),
                                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF111827))),
                                const SizedBox(height: 2),
                                Text(c.barangay ?? c.town ?? '', style: const TextStyle(fontSize: 12, color: Color(0xFF6B7280))),
                              ],
                            ),
                          ),
                          if (isSelected) const Icon(Icons.check_circle, color: Color(0xFF059669)),
                        ]),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }
}

// ── Step 2: Items ────────────────────────────────────────────────────────────

class _ItemsStep extends ConsumerStatefulWidget {
  const _ItemsStep({required this.searchCtrl, required this.cart, required this.onChanged});
  final TextEditingController searchCtrl;
  final Map<String, _CartLine> cart;
  final VoidCallback onChanged;

  @override
  ConsumerState<_ItemsStep> createState() => _ItemsStepState();
}

class _ItemsStepState extends ConsumerState<_ItemsStep> {
  String _query = '';

  void _setQty(Product p, int qty) {
    setState(() {
      if (qty <= 0) {
        widget.cart.remove(p.uuid);
      } else {
        widget.cart.putIfAbsent(p.uuid, () => _CartLine(p, 0)).quantity = qty;
      }
    });
    widget.onChanged();
  }

  @override
  Widget build(BuildContext context) {
    final products = ref.watch(productsStreamProvider).value ?? [];
    final q = _query.toLowerCase();
    final filtered = q.isEmpty
        ? products
        : products.where((p) => p.name.toLowerCase().contains(q) || p.sku.toLowerCase().contains(q)).toList();

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _SearchField(controller: widget.searchCtrl, hint: 'Search products...', onChanged: (v) => setState(() => _query = v)),
          const SizedBox(height: 8),
          Expanded(
            child: ListView.builder(
              itemCount: filtered.length,
              itemBuilder: (context, i) {
                final p = filtered[i];
                final qty = widget.cart[p.uuid]?.quantity ?? 0;
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  child: Row(children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(p.sku, style: const TextStyle(fontSize: 11, fontFamily: 'monospace', color: Color(0xFF9CA3AF))),
                          Text(p.name, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: Color(0xFF111827))),
                          Text('₱${p.unitPrice.toStringAsFixed(0)}', style: const TextStyle(fontSize: 13, color: Color(0xFF6B7280))),
                        ],
                      ),
                    ),
                    if (qty > 0) ...[
                      _QtyButton(icon: Icons.remove, filled: false, onTap: () => _setQty(p, qty - 1)),
                      SizedBox(width: 28, child: Text('$qty', textAlign: TextAlign.center, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600))),
                    ],
                    _QtyButton(icon: Icons.add, filled: true, onTap: () => _setQty(p, qty + 1)),
                  ]),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _QtyButton extends StatelessWidget {
  const _QtyButton({required this.icon, required this.filled, required this.onTap});
  final IconData icon;
  final bool filled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(6),
      child: Container(
        width: 28,
        height: 28,
        decoration: BoxDecoration(
          color: filled ? const Color(0xFF1E1E1E) : Colors.white,
          border: filled ? null : Border.all(color: const Color(0xFFE5E7EB)),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Icon(icon, size: 16, color: filled ? Colors.white : const Color(0xFF6B7280)),
      ),
    );
  }
}

// ── Step 3: Review ───────────────────────────────────────────────────────────

class _ReviewStep extends StatelessWidget {
  const _ReviewStep({
    required this.customer,
    required this.cart,
    required this.total,
    required this.paymentMethod,
    required this.onPaymentMethodChanged,
  });
  final Customer customer;
  final Map<String, _CartLine> cart;
  final double total;
  final String paymentMethod;
  final ValueChanged<String> onPaymentMethodChanged;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
      children: [
        Text(salesDisplayStoreName(customer),
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Color(0xFF111827))),
        const SizedBox(height: 12),
        for (final line in cart.values)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(children: [
              Expanded(child: Text('${line.product.name} × ${line.quantity}', style: const TextStyle(fontSize: 13, color: Color(0xFF374151)))),
              Text('₱${line.subtotal.toStringAsFixed(0)}', style: const TextStyle(fontSize: 13, color: Color(0xFF111827))),
            ]),
          ),
        const Padding(padding: EdgeInsets.symmetric(vertical: 10), child: Divider(height: 1)),
        Row(children: [
          const Expanded(child: Text('Total', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Color(0xFF111827)))),
          Text('₱${total.toStringAsFixed(0)}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: Color(0xFF111827))),
        ]),
        const SizedBox(height: 20),
        const Text('Payment Method', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF111827))),
        const SizedBox(height: 8),
        Row(
          children: ['Cash', 'Credit', 'GCash'].map((m) {
            final selected = paymentMethod == m;
            return Expanded(
              child: Padding(
                padding: EdgeInsets.only(right: m == 'GCash' ? 0 : 8),
                child: InkWell(
                  onTap: () => onPaymentMethodChanged(m),
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: selected ? const Color(0xFF1E1E1E) : Colors.white,
                      border: Border.all(color: selected ? const Color(0xFF1E1E1E) : const Color(0xFFE5E7EB)),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(m,
                        style: TextStyle(
                            fontSize: 13, fontWeight: FontWeight.w500, color: selected ? Colors.white : const Color(0xFF374151))),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}

// ── Bottom bar ───────────────────────────────────────────────────────────────

class _BottomBar extends StatelessWidget {
  const _BottomBar({
    required this.step,
    required this.canProceed,
    required this.total,
    required this.saving,
    required this.onNext,
    required this.onSubmit,
    required this.onSaveDraft,
  });
  final int step;
  final bool canProceed;
  final double total;
  final bool saving;
  final VoidCallback onNext;
  final VoidCallback onSubmit;
  final VoidCallback onSaveDraft;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(20, 12, 20, 12 + MediaQuery.of(context).padding.bottom),
      decoration: const BoxDecoration(border: Border(top: BorderSide(color: Color(0xFFE5E7EB)))),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (step == 1)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(children: [
                const Text('Total: ', style: TextStyle(fontSize: 14, color: Color(0xFF6B7280))),
                Text('₱${total.toStringAsFixed(0)}', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Color(0xFF111827))),
              ]),
            ),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton(
              onPressed: !canProceed || saving ? null : (step < 2 ? onNext : onSubmit),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1E1E1E),
                foregroundColor: Colors.white,
                disabledBackgroundColor: const Color(0xFFD1D5DB),
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              child: saving
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : Text(step < 2 ? 'Next' : 'Submit Order', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
            ),
          ),
          if (step == 2)
            TextButton(
              onPressed: saving ? null : onSaveDraft,
              child: const Text('Save Draft', style: TextStyle(color: Color(0xFF6B7280))),
            ),
        ],
      ),
    );
  }
}
