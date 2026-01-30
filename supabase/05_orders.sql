-- Orders table for Villahermosa Marketing
-- Matches Drift Orders table structure

CREATE TABLE IF NOT EXISTS orders (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    local_id INTEGER UNIQUE, -- Local SQLite ID for sync
    uuid TEXT UNIQUE NOT NULL, -- Local UUID for this record
    
    -- Customer and sales rep
    customer_id UUID NOT NULL REFERENCES customers(id),
    sales_rep_id UUID REFERENCES users(id),
    
    -- Order details
    order_date TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    status TEXT DEFAULT 'draft' CHECK (status IN ('draft', 'confirmed', 'dispatched', 'delivered', 'cancelled')),
    order_number TEXT UNIQUE NOT NULL,
    
    -- Financial
    subtotal DECIMAL(12,2) DEFAULT 0.00,
    tax_amount DECIMAL(12,2) DEFAULT 0.00,
    discount_amount DECIMAL(12,2) DEFAULT 0.00,
    total_amount DECIMAL(12,2) DEFAULT 0.00,
    payment_status TEXT DEFAULT 'pending' CHECK (payment_status IN ('pending', 'paid', 'partial', 'overdue')),
    
    -- Delivery information
    delivery_address TEXT NOT NULL,
    delivery_contact TEXT,
    delivery_phone TEXT,
    requested_delivery_date TIMESTAMP WITH TIME ZONE,
    actual_delivery_date TIMESTAMP WITH TIME ZONE,
    
    -- Warehouse processing
    warehouse_status TEXT DEFAULT 'pending' CHECK (warehouse_status IN ('pending', 'picking', 'packed', 'ready', 'shipped')),
    picker_id UUID REFERENCES users(id),
    picked_at TIMESTAMP WITH TIME ZONE,
    packer_id UUID REFERENCES users(id),
    packed_at TIMESTAMP WITH TIME ZONE,
    
    -- Notes and metadata
    customer_notes TEXT,
    internal_notes TEXT,
    priority TEXT DEFAULT 'normal' CHECK (priority IN ('low', 'normal', 'high', 'urgent')),
    
    -- Soft delete for sync safety
    is_deleted BOOLEAN DEFAULT FALSE,
    
    -- Sync tracking
    remote_id TEXT, -- Will store local SQLite ID
    sync_status TEXT DEFAULT 'pending' CHECK (sync_status IN ('pending', 'synced', 'conflict')),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Indexes for performance
CREATE INDEX IF NOT EXISTS idx_orders_customer_id ON orders(customer_id);
CREATE INDEX IF NOT EXISTS idx_orders_sales_rep_id ON orders(sales_rep_id);
CREATE INDEX IF NOT EXISTS idx_orders_order_number ON orders(order_number);
CREATE INDEX IF NOT EXISTS idx_orders_status ON orders(status);
CREATE INDEX IF NOT EXISTS idx_orders_warehouse_status ON orders(warehouse_status);
CREATE INDEX IF NOT EXISTS idx_orders_payment_status ON orders(payment_status);
CREATE INDEX IF NOT EXISTS idx_orders_order_date ON orders(order_date);
CREATE INDEX IF NOT EXISTS idx_orders_sync_status ON orders(sync_status);
CREATE INDEX IF NOT EXISTS idx_orders_local_id ON orders(local_id);

-- RLS (Row Level Security)
ALTER TABLE orders ENABLE ROW LEVEL SECURITY;

-- Policies for order management
CREATE POLICY "Admins and warehouse staff can view all orders" ON orders
    FOR SELECT USING (
        is_deleted = FALSE
        AND EXISTS (
            SELECT 1 FROM users 
            WHERE id = auth.uid() 
            AND role IN ('admin', 'warehouse')
        )
    );

CREATE POLICY "Customers can view own orders" ON orders
    FOR SELECT USING (
        is_deleted = FALSE
        AND EXISTS (
            SELECT 1 FROM users 
            WHERE id = auth.uid() 
            AND role = 'customer'
            AND users.email = (SELECT email FROM customers WHERE customers.id = orders.customer_id)
        )
    );

CREATE POLICY "Delivery personnel can view assigned orders" ON orders
    FOR SELECT USING (
        is_deleted = FALSE
        AND EXISTS (
            SELECT 1 FROM users 
            WHERE id = auth.uid() 
            AND role = 'delivery'
        )
        AND status IN ('dispatched', 'delivered')
    );

CREATE POLICY "Customers can create orders" ON orders
    FOR INSERT WITH CHECK (
        is_deleted = FALSE
        AND EXISTS (
            SELECT 1 FROM users 
            WHERE id = auth.uid() 
            AND role = 'customer'
            AND users.email = (SELECT email FROM customers WHERE customers.id = customer_id)
        )
    );

CREATE POLICY "Admins and warehouse staff can update orders" ON orders
    FOR UPDATE USING (
        is_deleted = FALSE
        AND EXISTS (
            SELECT 1 FROM users 
            WHERE id = auth.uid() 
            AND role IN ('admin', 'warehouse')
        )
    );

CREATE POLICY "Customers can update own pending orders" ON orders
    FOR UPDATE USING (
        is_deleted = FALSE
        AND status IN ('draft', 'confirmed')
        AND EXISTS (
            SELECT 1 FROM users 
            WHERE id = auth.uid() 
            AND role = 'customer'
            AND users.email = (SELECT email FROM customers WHERE customers.id = customer_id)
        )
    );

CREATE POLICY "Delivery personnel can update delivery status" ON orders
    FOR UPDATE USING (
        is_deleted = FALSE
        AND EXISTS (
            SELECT 1 FROM users 
            WHERE id = auth.uid() 
            AND role = 'delivery'
        )
        AND (
            status IN ('dispatched', 'delivered') OR
            actual_delivery_date IS NOT NULL
        )
    );
