import 'package:flutter/material.dart';
import '../../../core/database/app_database.dart';
import '../../../core/sync/sync_manager.dart';
import '../../../core/widgets/responsive_shell.dart';
import '../../inventory/product_form_screen.dart';
import '../../customers/customer_form_screen.dart';

// ── Inventory ─────────────────────────────────────────────────────────────────

class AdminInventoryScreen extends StatefulWidget {
  const AdminInventoryScreen({super.key, required this.database, required this.syncManager});
  final AppDatabase database;
  final SyncManager syncManager;

  @override
  State<AdminInventoryScreen> createState() => _AdminInventoryScreenState();
}

class _AdminInventoryScreenState extends State<AdminInventoryScreen> {
  late Future<List<Product>> _productsFuture;

  @override
  void initState() {
    super.initState();
    _productsFuture = widget.database.getAllProducts();
  }

  @override
  Widget build(BuildContext context) {
    return ResponsiveShell(
      database: widget.database,
      selectedRoute: '/admin/inventory',
      child: Scaffold(
        backgroundColor: const Color(0xFFF4F4F4),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: () async {
            await Navigator.push<bool>(
              context,
              MaterialPageRoute(builder: (_) => const ProductFormScreen()),
            );
            setState(() => _productsFuture = widget.database.getAllProducts());
          },
          icon: const Icon(Icons.add),
          label: const Text('Add Product'),
          backgroundColor: const Color(0xFF1E1E1E),
        ),
        body: FutureBuilder<List<Product>>(
          future: _productsFuture,
          builder: (context, snap) {
            if (snap.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            final products = snap.data ?? [];
            if (products.isEmpty) {
              return const _EmptyState(icon: Icons.inventory_2_outlined, label: 'No products yet');
            }
            return ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: products.length,
              separatorBuilder: (_, _) => const SizedBox(height: 8),
              itemBuilder: (context, i) {
                final p = products[i];
                return Card(
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: p.currentStock <= p.minStock
                          ? Colors.red.shade100
                          : Colors.green.shade100,
                      child: Icon(
                        Icons.inventory_2,
                        color: p.currentStock <= p.minStock ? Colors.red : Colors.green,
                        size: 20,
                      ),
                    ),
                    title: Text(p.name, style: const TextStyle(fontWeight: FontWeight.w600)),
                    subtitle: Text('SKU: ${p.sku}  •  Stock: ${p.currentStock}  •  ₱${p.unitPrice.toStringAsFixed(2)}'),
                    trailing: p.currentStock <= p.minStock
                        ? const Chip(
                            label: Text('Low Stock', style: TextStyle(fontSize: 11)),
                            backgroundColor: Color(0xFFFFEBEE),
                          )
                        : null,
                    onTap: () async {
                      await Navigator.push<bool>(
                        context,
                        MaterialPageRoute(
                          builder: (_) => ProductFormScreen(productId: p.id.toString()),
                        ),
                      );
                      setState(() => _productsFuture = widget.database.getAllProducts());
                    },
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}

// ── Customers ─────────────────────────────────────────────────────────────────

class AdminCustomersScreen extends StatefulWidget {
  const AdminCustomersScreen({super.key, required this.database, required this.syncManager});
  final AppDatabase database;
  final SyncManager syncManager;

  @override
  State<AdminCustomersScreen> createState() => _AdminCustomersScreenState();
}

class _AdminCustomersScreenState extends State<AdminCustomersScreen> {
  late Future<List<Customer>> _customersFuture;

  @override
  void initState() {
    super.initState();
    _customersFuture = widget.database.getAllCustomers();
  }

  @override
  Widget build(BuildContext context) {
    return ResponsiveShell(
      database: widget.database,
      selectedRoute: '/admin/customers',
      child: Scaffold(
        backgroundColor: const Color(0xFFF4F4F4),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: () async {
            await Navigator.push<bool>(
              context,
              MaterialPageRoute(builder: (_) => const CustomerFormScreen()),
            );
            setState(() => _customersFuture = widget.database.getAllCustomers());
          },
          icon: const Icon(Icons.person_add),
          label: const Text('Add Customer'),
          backgroundColor: const Color(0xFF1E1E1E),
        ),
        body: FutureBuilder<List<Customer>>(
          future: _customersFuture,
          builder: (context, snap) {
            if (snap.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            final customers = snap.data ?? [];
            if (customers.isEmpty) {
              return const _EmptyState(icon: Icons.storefront_outlined, label: 'No customers yet');
            }
            return ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: customers.length,
              separatorBuilder: (_, _) => const SizedBox(height: 8),
              itemBuilder: (context, i) {
                final c = customers[i];
                return Card(
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: const Color(0xFFE8EAF6),
                      child: Text(
                        c.name.isNotEmpty ? c.name[0].toUpperCase() : '?',
                        style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF3949AB)),
                      ),
                    ),
                    title: Text(c.name, style: const TextStyle(fontWeight: FontWeight.w600)),
                    subtitle: Text('${c.storeType}  •  ${c.municipality}  •  ${c.contactNumber}'),
                    trailing: Chip(
                      label: Text(c.status, style: const TextStyle(fontSize: 11)),
                      backgroundColor: c.status == 'active'
                          ? const Color(0xFFE8F5E9)
                          : const Color(0xFFFFF3E0),
                    ),
                    onTap: () async {
                      await Navigator.push<bool>(
                        context,
                        MaterialPageRoute(
                          builder: (_) => CustomerFormScreen(customerId: c.uuid),
                        ),
                      );
                      setState(() => _customersFuture = widget.database.getAllCustomers());
                    },
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}

// ── Orders ────────────────────────────────────────────────────────────────────

class AdminOrdersScreen extends StatefulWidget {
  const AdminOrdersScreen({super.key, required this.database, required this.syncManager});
  final AppDatabase database;
  final SyncManager syncManager;

  @override
  State<AdminOrdersScreen> createState() => _AdminOrdersScreenState();
}

class _AdminOrdersScreenState extends State<AdminOrdersScreen> {
  late Future<List<Order>> _ordersFuture;

  @override
  void initState() {
    super.initState();
    _ordersFuture = widget.database.getPendingOrders();
  }

  @override
  Widget build(BuildContext context) {
    return ResponsiveShell(
      database: widget.database,
      selectedRoute: '/admin/orders',
      child: Scaffold(
        backgroundColor: const Color(0xFFF4F4F4),
        body: FutureBuilder<List<Order>>(
          future: _ordersFuture,
          builder: (context, snap) {
            if (snap.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            final orders = snap.data ?? [];
            if (orders.isEmpty) {
              return const _EmptyState(icon: Icons.shopping_cart_outlined, label: 'No pending orders');
            }
            return ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: orders.length,
              separatorBuilder: (_, _) => const SizedBox(height: 8),
              itemBuilder: (context, i) {
                final o = orders[i];
                return Card(
                  child: ListTile(
                    leading: const CircleAvatar(
                      backgroundColor: Color(0xFFFFF3E0),
                      child: Icon(Icons.receipt_long, color: Color(0xFFE65100), size: 20),
                    ),
                    title: Text('Order #${o.uuid.substring(0, 8).toUpperCase()}',
                        style: const TextStyle(fontWeight: FontWeight.w600)),
                    subtitle: Text(
                        'Status: ${o.status}  •  Warehouse: ${o.warehouseStatus}\n'
                        'Created: ${o.createdAt.toLocal().toString().substring(0, 16)}'),
                    isThreeLine: true,
                    trailing: _statusChip(o.status),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }

  Widget _statusChip(String status) {
    final colors = {
      'pending': const Color(0xFFFFF9C4),
      'confirmed': const Color(0xFFE3F2FD),
      'ready': const Color(0xFFE8F5E9),
      'delivered': const Color(0xFFEDE7F6),
    };
    return Chip(
      label: Text(status, style: const TextStyle(fontSize: 11)),
      backgroundColor: colors[status] ?? const Color(0xFFF5F5F5),
    );
  }
}

// ── Stock Movements ───────────────────────────────────────────────────────────

class AdminStockScreen extends StatefulWidget {
  const AdminStockScreen({super.key, required this.database, required this.syncManager});
  final AppDatabase database;
  final SyncManager syncManager;

  @override
  State<AdminStockScreen> createState() => _AdminStockScreenState();
}

class _AdminStockScreenState extends State<AdminStockScreen> {
  late Future<List<StockMovement>> _movementsFuture;

  @override
  void initState() {
    super.initState();
    _movementsFuture = widget.database.getPendingSyncStockMovements();
  }

  @override
  Widget build(BuildContext context) {
    return ResponsiveShell(
      database: widget.database,
      selectedRoute: '/admin/stock',
      child: Scaffold(
        backgroundColor: const Color(0xFFF4F4F4),
        body: FutureBuilder<List<StockMovement>>(
          future: _movementsFuture,
          builder: (context, snap) {
            if (snap.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            final movements = snap.data ?? [];
            if (movements.isEmpty) {
              return const _EmptyState(icon: Icons.trending_up, label: 'No stock movements');
            }
            return ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: movements.length,
              separatorBuilder: (_, _) => const SizedBox(height: 8),
              itemBuilder: (context, i) {
                final m = movements[i];
                final isIn = m.movementType == 'in';
                return Card(
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: isIn ? const Color(0xFFE8F5E9) : const Color(0xFFFFEBEE),
                      child: Icon(
                        isIn ? Icons.arrow_downward : Icons.arrow_upward,
                        color: isIn ? Colors.green : Colors.red,
                        size: 20,
                      ),
                    ),
                    title: Text('${m.movementType.toUpperCase()}  •  Qty: ${m.quantity}',
                        style: const TextStyle(fontWeight: FontWeight.w600)),
                    subtitle: Text(
                        'Ref: ${m.referenceId ?? '-'}\n'
                        '${m.createdAt.toLocal().toString().substring(0, 16)}'),
                    isThreeLine: true,
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}

// ── Deliveries ────────────────────────────────────────────────────────────────

class AdminDeliveriesScreen extends StatefulWidget {
  const AdminDeliveriesScreen({super.key, required this.database, required this.syncManager});
  final AppDatabase database;
  final SyncManager syncManager;

  @override
  State<AdminDeliveriesScreen> createState() => _AdminDeliveriesScreenState();
}

class _AdminDeliveriesScreenState extends State<AdminDeliveriesScreen> {
  late Future<List<Delivery>> _deliveriesFuture;

  @override
  void initState() {
    super.initState();
    _deliveriesFuture = widget.database.getActiveDeliveries();
  }

  @override
  Widget build(BuildContext context) {
    return ResponsiveShell(
      database: widget.database,
      selectedRoute: '/admin/deliveries',
      child: Scaffold(
        backgroundColor: const Color(0xFFF4F4F4),
        body: FutureBuilder<List<Delivery>>(
          future: _deliveriesFuture,
          builder: (context, snap) {
            if (snap.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            final deliveries = snap.data ?? [];
            if (deliveries.isEmpty) {
              return const _EmptyState(icon: Icons.local_shipping_outlined, label: 'No active deliveries');
            }
            return ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: deliveries.length,
              separatorBuilder: (_, _) => const SizedBox(height: 8),
              itemBuilder: (context, i) {
                final d = deliveries[i];
                return Card(
                  child: ListTile(
                    leading: const CircleAvatar(
                      backgroundColor: Color(0xFFE3F2FD),
                      child: Icon(Icons.local_shipping, color: Color(0xFF1565C0), size: 20),
                    ),
                    title: Text('Delivery #${d.uuid.substring(0, 8).toUpperCase()}',
                        style: const TextStyle(fontWeight: FontWeight.w600)),
                    subtitle: Text(
                        'Status: ${d.status}\n'
                        'Expected: ${d.expectedStartTime.toLocal().toString().substring(0, 16)}'),
                    isThreeLine: true,
                    trailing: Chip(
                      label: Text(d.status, style: const TextStyle(fontSize: 11)),
                      backgroundColor: const Color(0xFFE3F2FD),
                    ),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}

// ── Reports (placeholder) ─────────────────────────────────────────────────────

class AdminReportsScreen extends StatelessWidget {
  const AdminReportsScreen({super.key, required this.database, required this.syncManager});
  final AppDatabase database;
  final SyncManager syncManager;

  @override
  Widget build(BuildContext context) {
    return ResponsiveShell(
      database: database,
      selectedRoute: '/admin/reports',
      child: const _EmptyState(icon: Icons.bar_chart_outlined, label: 'Reports coming soon'),
    );
  }
}

// ── Settings (placeholder) ────────────────────────────────────────────────────

class AdminSettingsScreen extends StatelessWidget {
  const AdminSettingsScreen({super.key, required this.database, required this.syncManager});
  final AppDatabase database;
  final SyncManager syncManager;

  @override
  Widget build(BuildContext context) {
    return ResponsiveShell(
      database: database,
      selectedRoute: '/admin/settings',
      child: const _EmptyState(icon: Icons.settings_outlined, label: 'Settings coming soon'),
    );
  }
}

// ── Shared empty-state widget ─────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.icon, required this.label});
  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.08),
                  blurRadius: 16,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Icon(icon, size: 36, color: const Color(0xFF1E1E1E)),
          ),
          const SizedBox(height: 24),
          Text(
            label,
            style: const TextStyle(fontSize: 16, color: Color(0xFF6B6B6B)),
          ),
        ],
      ),
    );
  }
}
