import 'package:drift/drift.dart' hide isNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:villahermosa_inventory_system/core/database/app_database.dart';
import 'package:villahermosa_inventory_system/features/customer/providers/customer_providers.dart'
    show paymentMethodFromNotes, paymentMethodNote;
import 'package:villahermosa_inventory_system/features/sales/widgets/new_order_flow.dart' show newRepOrderPayment;

/// A rep-entered order used to create its payment `paid` / balance 0 whenever the
/// method was left on its default 'Cash': "settled" the moment it was typed in,
/// before anything was delivered or collected, so nothing was ever outstanding.
void main() {
  late AppDatabase db;
  setUp(() => db = AppDatabase.forTesting(DatabaseConnection(NativeDatabase.memory())));
  tearDown(() => db.close());

  PaymentsCompanion payment({double total = 314}) => newRepOrderPayment(
        paymentId: 'PAY-001', orderId: 1, orderCode: 'ORD-1', storeName: 'Deiahs', repId: 5, repName: 'jed par',
        total: total, now: DateTime(2026, 11, 19, 9));

  test('a rep-entered order\'s payment is unpaid, owes the full total, and records no method', () {
    final p = payment(total: 314);
    expect(p.status.value, 'unpaid');
    expect(p.amountPaid.value, 0);
    expect(p.balance.value, 314);
    expect(p.orderAmount.value, 314);
    expect(p.paymentMethod.value, isNull, reason: 'a payment method belongs to an actual payment');
    expect(p.syncStatus.value, 'pending');
  });

  test('it shows up as outstanding for the rep (Record Payment lists balance > 0 by rep name)', () async {
    await db.customStatement(
        "INSERT INTO orders (uuid, customer_id, order_number, delivery_address) VALUES ('o1','c','ORD-1','x')");
    await db.createPayment(payment());
    final mine = await db.watchPaymentsBySalesRep('jed par').first;
    expect(mine.where((p) => p.balance > 0).map((p) => p.orderCode), ['ORD-1']);
  });

  test('the intended method is kept on the order notes, where the delivery card reads it', () {
    for (final m in ['Cash', 'Credit', 'GCash']) {
      expect(paymentMethodFromNotes(paymentMethodNote(m)), m);
    }
  });
}
