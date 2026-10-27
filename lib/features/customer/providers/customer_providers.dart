import 'package:drift/drift.dart' show Value;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/auth/auth_service.dart';
import '../../../core/database/app_database.dart';
import '../../../core/sync/sync_manager.dart';
import '../../admin/providers/delivery_routes_provider.dart' show deliveryRoutesStreamProvider;
import '../../admin/providers/orders_provider.dart' show customersProvider, databaseProvider;
import '../../admin/providers/products_provider.dart' show productsStreamProvider, suppliersStreamProvider;

export '../../admin/providers/products_provider.dart' show productsStreamProvider, suppliersStreamProvider;

// ── Cart ──────────────────────────────────────────────────────────────────────

class CartItem {
  CartItem({required this.product, required this.quantity});
  final Product product;
  int quantity;

  double get subtotal => product.unitPrice * quantity;
}

/// In-memory cart (no Drift table). Items are keyed by product uuid.
class CartNotifier extends StateNotifier<List<CartItem>> {
  CartNotifier() : super([]);

  void addItem(Product product, int qty) {
    if (qty <= 0) return;
    final i = state.indexWhere((c) => c.product.uuid == product.uuid);
    if (i == -1) {
      state = [...state, CartItem(product: product, quantity: qty)];
    } else {
      state = [
        for (final (j, c) in state.indexed)
          if (j == i) CartItem(product: product, quantity: c.quantity + qty) else c,
      ];
    }
  }

  void removeItem(String productId) => state = state.where((c) => c.product.uuid != productId).toList();

  void updateQty(String productId, int qty) {
    if (qty <= 0) {
      removeItem(productId);
      return;
    }
    state = [
      for (final c in state)
        if (c.product.uuid == productId) CartItem(product: c.product, quantity: qty) else c,
    ];
  }

  void clear() => state = [];

  double get total => state.fold(0, (sum, item) => sum + item.subtotal);
  int get itemCount => state.fold(0, (sum, item) => sum + item.quantity);
}

final cartProvider = StateNotifierProvider<CartNotifier, List<CartItem>>((ref) => CartNotifier());

final cartCountProvider = Provider<int>((ref) => ref.watch(cartProvider).fold(0, (s, i) => s + i.quantity));

final cartTotalProvider = Provider<double>((ref) => ref.watch(cartProvider).fold(0.0, (s, i) => s + i.subtotal));

/// Quantity of a product currently in the cart (0 if absent).
final cartQtyProvider = Provider.family<int, String>((ref, productUuid) {
  for (final c in ref.watch(cartProvider)) {
    if (c.product.uuid == productUuid) return c.quantity;
  }
  return 0;
});

// ── Who is logged in ──────────────────────────────────────────────────────────

/// Plain description of the logged-in store owner, built from the users /
/// customers / delivery_routes tables. Plain fields (no Drift rows) so screens
/// and tests don't depend on table shapes.
class CustomerProfile {
  const CustomerProfile({
    required this.firstName,
    required this.ownerName,
    required this.storeName,
    this.customerUuid,
    this.routeName = '',
    this.deliveryDays = '',
    this.repName = '',
    this.barangay = '',
    this.town = '',
    this.channel = '',
    this.phone = '',
    this.email = '',
    this.memberSince,
    this.address = '',
  });

  final String firstName;
  final String ownerName;
  final String storeName;
  final String? customerUuid;
  final String routeName;
  final String deliveryDays;
  final String repName;
  final String barangay;
  final String town;
  final String channel;
  final String phone;
  final String email;
  final DateTime? memberSince;
  final String address;

  /// Only a linked customer record can be edited / have orders pushed.
  bool get hasCustomerRecord => customerUuid != null;
}

final customerProfileProvider = Provider<CustomerProfile>((ref) {
  final user = AuthService.instance.getCurrentUser();
  final customers = ref.watch(customersProvider).value ?? [];
  final routes = ref.watch(deliveryRoutesStreamProvider).value ?? [];

  final email = (user?.email ?? '').toLowerCase();
  Customer? customer;
  if (email.isNotEmpty) {
    for (final c in customers) {
      if ((c.email ?? '').toLowerCase() == email) customer = c;
    }
  }

  final first = (user?.firstName ?? '').trim();
  final last = (user?.lastName ?? '').trim();
  final owner = customer?.name.isNotEmpty == true ? customer!.name : '$first $last'.trim();
  final business = (customer?.businessName ?? '').trim();
  final store = business.isNotEmpty ? business : (owner.isNotEmpty ? owner : 'My Store');

  final town = (customer?.town ?? '').isNotEmpty ? customer!.town! : (customer?.municipality ?? '');
  DeliveryRoute? route;
  if (town.isNotEmpty) {
    for (final r in routes) {
      if (r.municipality.toLowerCase() == town.toLowerCase()) route = r;
    }
  }

  return CustomerProfile(
    firstName: first.isNotEmpty ? first : (owner.split(' ').first),
    ownerName: owner,
    storeName: store,
    customerUuid: customer?.uuid,
    routeName: route?.routeName ?? '',
    deliveryDays: route?.deliveryDays ?? '',
    repName: route?.assignedRepName ?? '',
    barangay: customer?.barangay ?? '',
    town: town,
    channel: customer?.channel ?? customer?.storeType ?? '',
    phone: (customer?.phone ?? '').isNotEmpty ? customer!.phone! : (customer?.contactNumber ?? ''),
    email: user?.email ?? customer?.email ?? '',
    memberSince: customer?.createdAt ?? user?.createdAt,
    address: customer?.address ?? '',
  );
});

// ── Orders & payments ─────────────────────────────────────────────────────────

final customerOrdersProvider = StreamProvider<List<Order>>((ref) {
  final profile = ref.watch(customerProfileProvider);
  return ref.watch(databaseProvider).watchOrdersForCustomer(profile.customerUuid, profile.storeName);
});

final customerPaymentsProvider = StreamProvider<List<Payment>>((ref) {
  final store = ref.watch(customerProfileProvider).storeName;
  return ref.watch(databaseProvider).watchAllPayments().map((all) => all.where((p) => p.storeName == store).toList());
});

/// Unpaid balance across this store's payments.
final customerBalanceProvider = Provider<double>((ref) {
  final payments = ref.watch(customerPaymentsProvider).value ?? [];
  return payments.where((p) => p.status != 'paid').fold(0.0, (s, p) => s + p.balance);
});

final orderLinesProvider = StreamProvider.family<List<OrderItem>, String>(
  (ref, orderUuid) => ref.watch(databaseProvider).watchAllOrderItems().map((all) => all.where((i) => i.orderId == orderUuid).toList()),
);

// ── Status helpers (pure) ─────────────────────────────────────────────────────

enum CustomerOrderStatus { processing, outForDelivery, delivered, cancelled }

/// What the store owner sees. The warehouse tracks finer states
/// (pending/processing/ready); to the customer all of those are "Processing".
CustomerOrderStatus customerStatusOf(Order o) {
  if (o.status == 'cancelled') return CustomerOrderStatus.cancelled;
  if (o.status == 'completed') return CustomerOrderStatus.delivered;
  if (o.warehouseStatus == 'dispatched') return CustomerOrderStatus.outForDelivery;
  return CustomerOrderStatus.processing;
}

String customerStatusLabel(CustomerOrderStatus s) => switch (s) {
      CustomerOrderStatus.processing => 'Processing',
      CustomerOrderStatus.outForDelivery => 'Out for Delivery',
      CustomerOrderStatus.delivered => 'Delivered',
      CustomerOrderStatus.cancelled => 'Cancelled',
    };

/// Index of the current step in Placed → Processing → Out for Delivery →
/// Delivered (0-based). Cancelled orders have no stepper.
int customerStepOf(CustomerOrderStatus s) => switch (s) {
      CustomerOrderStatus.processing => 1,
      CustomerOrderStatus.outForDelivery => 2,
      CustomerOrderStatus.delivered => 3,
      CustomerOrderStatus.cancelled => -1,
    };

bool isActiveCustomerOrder(CustomerOrderStatus s) => s == CustomerOrderStatus.processing || s == CustomerOrderStatus.outForDelivery;

/// 'Collected' | 'Partial' | 'Pending' for a payment row.
String paymentBadgeOf(Payment p) => switch (p.status) {
      'paid' => 'Collected',
      'partial' => 'Partial',
      _ => 'Pending',
    };

/// Payment method recorded at checkout lives in the order's notes.
const _methodPrefix = 'Payment method: ';
String? paymentMethodFromNotes(String? notes) {
  if (notes == null) return null;
  final i = notes.indexOf(_methodPrefix);
  if (i == -1) return null;
  final rest = notes.substring(i + _methodPrefix.length);
  final end = rest.indexOf('\n');
  return (end == -1 ? rest : rest.substring(0, end)).trim();
}

const _dayNames = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

/// Next delivery day after [from], from a route's "Mon,Thu" style days string.
/// With no usable days it falls back to tomorrow.
DateTime nextDeliveryDate(String deliveryDays, DateTime from) {
  final days = deliveryDays.split(',').map((d) => d.trim().toLowerCase()).where((d) => d.isNotEmpty).toSet();
  final start = DateTime(from.year, from.month, from.day);
  if (days.isNotEmpty) {
    for (var i = 1; i <= 7; i++) {
      final d = start.add(Duration(days: i));
      if (days.contains(_dayNames[d.weekday - 1].toLowerCase())) return d;
    }
  }
  return start.add(const Duration(days: 1));
}

// ── Placing an order ──────────────────────────────────────────────────────────

/// Writes the Order + its lines to Drift as pending, clears the cart and kicks
/// off a background sync. Returns the new order number.
Future<String> placeCustomerOrder(
  WidgetRef ref, {
  required List<CartItem> items,
  required String paymentMethod,
  required CustomerProfile profile,
}) async {
  final db = ref.read(databaseProvider);
  final user = AuthService.instance.getCurrentUser();
  final orderNumber = await db.generateOrderNumber();
  final orderUuid = 'ord-${DateTime.now().microsecondsSinceEpoch}';
  final total = items.fold<double>(0, (s, i) => s + i.subtotal);
  final units = items.fold<int>(0, (s, i) => s + i.quantity);
  final delivery = nextDeliveryDate(profile.deliveryDays, DateTime.now());

  await db.transaction(() async {
    await db.createOrder(OrdersCompanion.insert(
      uuid: orderUuid,
      // Orders push resolves this uuid to the customer's numeric id; a login
      // with no linked customer record falls back to the user's own uuid and
      // simply stays local (the push skips orders it can't resolve).
      customerId: profile.customerUuid ?? user?.uuid ?? '',
      orderNumber: orderNumber,
      deliveryAddress: profile.address,
      status: const Value('pending'),
      subtotal: Value(total),
      totalAmount: Value(total),
      customerNotes: Value('$_methodPrefix$paymentMethod'),
      storeName: Value(profile.storeName),
      routeName: Value(profile.routeName.isEmpty ? null : profile.routeName),
      salesRepName: Value(profile.repName.isEmpty ? null : profile.repName),
      itemCount: Value(units),
      expectedDeliveryDate: Value(delivery),
      syncStatus: const Value('pending'),
    ));
    for (final i in items) {
      await db.createOrderItem(OrderItemsCompanion.insert(
        uuid: '$orderUuid-${i.product.uuid}',
        orderId: orderUuid,
        productId: i.product.uuid,
        productSku: i.product.sku,
        productName: i.product.name,
        quantity: i.quantity,
        unitPrice: i.product.unitPrice,
        subtotal: i.subtotal,
        totalAmount: i.subtotal,
        availableStock: i.product.currentStock,
      ));
    }
  });

  ref.read(cartProvider.notifier).clear();
  // Best effort: the order is already safe locally; offline just means it
  // goes up on the next sync.
  try {
    SyncManager.instance.syncPendingData().catchError((_) {});
  } catch (_) {
    // SyncManager not initialised (e.g. in tests) — nothing to push.
  }
  return orderNumber;
}

/// Updates the linked customer's phone number (both phone columns).
Future<void> updateCustomerPhone(WidgetRef ref, String customerUuid, String phone) async {
  await ref.read(databaseProvider).updateCustomer(
        customerUuid,
        CustomersCompanion(
          phone: Value(phone),
          contactNumber: Value(phone),
          syncStatus: const Value('pending'),
        ),
      );
  ref.invalidate(customersProvider);
}

/// Name of a product's supplier, '' if unknown.
final supplierNamesProvider = Provider<Map<int, String>>((ref) {
  final suppliers = ref.watch(suppliersStreamProvider).value ?? [];
  return {for (final s in suppliers) s.id: s.tradeName};
});

/// Live product catalogue for the shop (inactive products hidden).
final shopProductsProvider = Provider<List<Product>>((ref) {
  final all = ref.watch(productsStreamProvider).value ?? [];
  return all.where((p) => p.isActive).toList();
});
