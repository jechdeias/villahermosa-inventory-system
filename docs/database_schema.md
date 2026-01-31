# Database Schema Reference

## ID Type Convention

This document defines the ID type conventions used throughout the application to prevent type mismatches.

### Primary Key Types

| Table | Primary Key Type | UUID Field | Notes |
|-------|------------------|------------|-------|
| Users | Integer (`id`) | String (`uuid`) | Use integer for local operations, UUID for sync |
| Products | Integer (`id`) | String (`uuid`) | Use integer for local operations, UUID for sync |
| Customers | Integer (`id`) | String (`uuid`) | Use integer for local operations, UUID for sync |
| Orders | String (`id`) - UUID | N/A | UUID only, no integer ID |
| Deliveries | String (`id`) - UUID | N/A | UUID only, no integer ID |
| OrderItems | Integer (`id`) | String (`uuid`) | Use integer for local operations, UUID for sync |
| StockMovements | String (`id`) - UUID | N/A | UUID only, no integer ID |
| Categories | Integer (`id`) | String (`uuid`) | Use integer for local operations, UUID for sync |

### Foreign Key Relationships

| Table | Foreign Key | References | Type |
|-------|-------------|------------|------|
| Orders | `customerId` | Customers.uuid | String |
| OrderItems | `orderId` | Orders.id | String |
| OrderItems | `productId` | Products.id | Integer |
| Deliveries | `orderId` | Orders.id | String |
| Deliveries | `deliveryPersonnelId` | Users.id | Integer (stored as string) |
| StockMovements | `productId` | Products.id | Integer (stored as string) |

### Method Naming Convention

```dart
// For tables with both ID types
Future<Customer?> getCustomerById(String uuid)     // UUID lookup
Future<Customer?> getCustomerByIntId(int id)      // Integer lookup

// For UUID-only tables
Future<Order?> getOrderById(String id)             // UUID only
Future<Delivery?> getDeliveryById(String id)       // UUID only

// For integer-only tables
Future<Product?> getProductByIntId(int id)         // Integer only
```

### Common Patterns

1. **Always use UUID for cross-table references** (customerId, orderId, etc.)
2. **Use integer IDs for direct record access** when available
3. **Convert types explicitly** using TypeValidator utilities
4. **Validate foreign key existence** before creating relationships

### Type Conversion Examples

```dart
// Correct: Converting integer product ID to string for foreign key
productId: Value(item.productId.toString())

// Correct: Using UUID for order references
orderId: orderId,  // orderId is already a string

// Correct: Validating types before database operations
final productId = TypeValidator.ensureIntId(item.productId);
final customerId = TypeValidator.ensureUuid(customerId);
```

## Sync Status Fields

All tables include these sync tracking fields:
- `syncStatus`: 'pending', 'synced', 'conflict'
- `remoteId`: Remote UUID from Supabase (nullable)
- `createdAt`: DateTime
- `updatedAt`: DateTime
- `isDeleted`: Boolean for soft delete
