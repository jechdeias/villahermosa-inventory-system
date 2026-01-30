# Supabase Setup Instructions for Villahermosa Marketing

## 🚀 Quick Setup Guide

### **Step 1: Create Supabase Project**
1. Go to [supabase.com](https://supabase.com)
2. Create new project: `villahermosa-marketing`
3. Note your project URL and anon key

### **Step 2: Run SQL Scripts in Order**
Execute these SQL files in the Supabase SQL Editor:

1. **01_users.sql** - User management with RLS
2. **02_categories.sql** - Product categories
3. **03_products.sql** - Product catalog
4. **04_customers.sql** - Customer database
5. **05_orders.sql** - Order management
6. **06_order_items.sql** - Order line items
7. **07_stock_movements.sql** - Inventory audit trail
8. **08_deliveries.sql** - Delivery tracking

### **Step 3: Configure Authentication**
1. Go to **Authentication** → **Settings**
2. Enable email/password authentication
3. Add your domain to allowed URLs
4. Configure JWT settings (default is fine)

### **Step 4: Test RLS Policies**
```sql
-- Test as admin
SELECT * FROM users WHERE role = 'admin';

-- Test as customer
SELECT * FROM products WHERE is_deleted = FALSE;
```

### **Step 5: Configure Flutter**
Add your Supabase credentials to your Flutter app:

```dart
// lib/core/config/supabase_config.dart
class SupabaseConfig {
  static const String url = 'YOUR_SUPABASE_URL';
  static const String anonKey = 'YOUR_SUPABASE_ANON_KEY';
}
```

## 🔐 Role-Based Access Control

### **User Roles:**
- **admin**: Full access to all data
- **warehouse**: Manage products, orders, stock movements
- **delivery**: View assigned deliveries, update status
- **customer**: View own data, create orders

### **RLS Policies Applied:**
✅ **Row Level Security** enabled on all tables
✅ **Role-based access** for each user type
✅ **Data isolation** between customers
✅ **Audit trail** for all operations

## 📊 Schema Summary

| Table | Purpose | Key Features |
|-------|---------|--------------|
| **users** | User management | Role-based access, sync tracking |
| **categories** | Product organization | Simple reference data |
| **products** | Product catalog | Stock tracking, pricing |
| **customers** | Customer database | Business info, credit limits |
| **orders** | Order management | Full order lifecycle |
| **order_items** | Order details | Price snapshots, quantities |
| **stock_movements** | Inventory audit | Complete movement history |
| **deliveries** | Delivery tracking | GPS, proof of delivery |

## 🔄 Sync Architecture

### **Sync Fields in Every Table:**
- `local_id` - SQLite primary key
- `uuid` - Local unique identifier
- `remote_id` - Supabase UUID reference
- `sync_status` - pending/synced/conflict
- `created_at` / `updated_at` - Timestamps

### **Conflict Resolution:**
- **Users**: Admin wins
- **Products**: Warehouse wins
- **Customers**: Customer wins (own data)
- **Orders**: Customer wins (pending orders)
- **StockMovements**: Last-write-wins
- **Deliveries**: Delivery wins

## 🚨 Important Notes

### **Security:**
- All tables have RLS enabled
- No direct table access without authentication
- Role-based policies enforced
- Soft delete for data integrity

### **Performance:**
- Indexes on all foreign keys
- Indexes on frequently queried fields
- Optimized for mobile/tablet usage

### **Compliance:**
- Complete audit trail
- Data isolation between customers
- GDPR-ready with soft delete
- Production-ready error handling

## 📱 Ready for Flutter Integration

Your Supabase backend is now ready for:
- ✅ **Authentication** with role-based access
- ✅ **Real-time sync** with conflict resolution
- ✅ **Offline-first** architecture support
- ✅ **Production-grade** security

Next step: Connect Flutter app to Supabase and implement sync service!
