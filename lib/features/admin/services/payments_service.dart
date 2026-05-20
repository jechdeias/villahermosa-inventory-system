import 'package:drift/drift.dart' show Value;
import '../../../core/auth/auth_service.dart';
import '../../../core/database/app_database.dart';
import '../../../core/sync/sync_manager.dart';

class PaymentsService {
  PaymentsService._();
  static final instance = PaymentsService._();

  AppDatabase get _db => AuthService.instance.database;

  Future<void> recordPayment({
    required int paymentId,
    required double amount,
    required String method,
  }) async {
    final existing = await _db.getPaymentById(paymentId);
    if (existing == null) return;

    final newPaid = existing.amountPaid + amount;
    final newBalance = existing.orderAmount - newPaid;
    final newStatus = newBalance <= 0 ? 'paid' : 'partial';

    await _db.updatePayment(
      paymentId,
      PaymentsCompanion(
        amountPaid:    Value(newPaid),
        balance:       Value(newBalance < 0 ? 0 : newBalance),
        paymentMethod: Value(method),
        status:        Value(newStatus),
        paymentDate:   Value(DateTime.now()),
        syncStatus:    const Value('pending'),
      ),
    );

    try {
      await SyncManager.instance.syncPendingData();
    } catch (_) {}
  }

  Future<void> markAsCredit(int paymentId) async {
    await _db.updatePayment(
      paymentId,
      const PaymentsCompanion(
        status:     Value('credit'),
        syncStatus: Value('pending'),
      ),
    );
    try {
      await SyncManager.instance.syncPendingData();
    } catch (_) {}
  }
}
