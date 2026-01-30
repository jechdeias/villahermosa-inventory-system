-- OrderItems table for Villahermosa Marketing
-- Matches Drift OrderItems table structure

CREATE TABLE IF NOT EXISTS order_items (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    local_id INTEGER UNIQUE, -- Local SQLite ID for sync
    uuid TEXT UNIQUE NOT NULL, -- Local UUID for this record
    
    -- Order and product references
    order_id UUID NOT NULL REFERENCES orders(id) ON DELETE CASCADE,
    product_id UUID NOT NULL REFERENCES products(id),
    
    -- Item details at time of order
    product_sku TEXT NOT NULL,
    product_name TEXT NOT NULL,
    product_category TEXT,
    
    -- Quantities and pricing
    quantity INTEGER NOT NULL CHECK (quantity > 0),
    delivered_quantity INTEGER DEFAULT 0 CHECK (delivered_quantity >= 0),
    unit_price DECIMAL(10,2) NOT NULL CHECK (unit_price >= 0),
    subtotal DECIMAL(12,2) NOT NULL CHECK (subtotal >= 0),
    discount_amount DECIMAL(10,2) DEFAULT 0.00 CHECK (discount_amount >= 0),
    total_amount DECIMAL(12,2) NOT NULL CHECK (total_amount >= 0),
    
    -- Stock information
    available_stock INTEGER NOT NULL CHECK (available_stock >= 0),
    stock_status TEXT DEFAULT 'available' CHECK (stock_status IN ('available', 'backorder', 'discontinued')),
    
    -- Status tracking
    status TEXT DEFAULT 'pending' CHECK (status IN ('pending', 'picked', 'packed', 'delivered', 'cancelled')),
    picker_id UUID REFERENCES users(id),
    picked_at TIMESTAMP WITH TIME ZONE,
    
    -- Notes
    notes TEXT,
    cancellation_reason TEXT,
    
    -- Soft delete for sync safety
    is_deleted BOOLEAN DEFAULT FALSE,
    
    -- Sync tracking
    remote_id TEXT, -- Will store local SQLite ID
    sync_status TEXT DEFAULT 'pending' CHECK (sync_status IN ('pending', 'synced', 'conflict')),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Indexes for performance
CREATE INDEX IF NOT EXISTS idx_order_items_order_id ON order_items(order_id);
CREATE INDEX IF NOT EXISTS idx_order_items_product_id ON order_items(product_id);
CREATE INDEX IF NOT EXISTS idx_order_items_status ON order_items(status);
CREATE INDEX IF NOT EXISTS idx_order_items_stock_status ON order_items(stock_status);
CREATE INDEX IF NOT EXISTS idx_order_items_sync_status ON order_items(sync_status);
CREATE INDEX IF NOT EXISTS idx_order_items_local_id ON order_items(local_id);

-- RLS (Row Level Security)
ALTER TABLE order_items ENABLE ROW LEVEL SECURITY;

-- Policies for order item management
CREATE POLICY "Admins and warehouse staff can view all order items" ON order_items
    FOR SELECT USING (
        is_deleted = FALSE
        AND EXISTS (
            SELECT 1 FROM users 
            WHERE id = auth.uid() 
            AND role IN ('admin', 'warehouse')
        )
    );

CREATE POLICY "Customers can view own order items" ON order_items
    FOR SELECT USING (
        is_deleted = FALSE
        AND EXISTS (
            SELECT 1 FROM orders 
            WHERE orders.id = order_items.order_id
            AND EXISTS (
                SELECT 1 FROM users 
                WHERE id = auth.uid() 
                AND role = 'customer'
                AND users.email = (SELECT email FROM customers WHERE customers.id = orders.customer_id)
            )
        )
    );

CREATE POLICY "Delivery personnel can view order items for assigned orders" ON order_items
    FOR SELECT USING (
        is_deleted = FALSE
        AND EXISTS (
            SELECT 1 FROM orders 
            WHERE orders.id = order_items.order_id
            AND orders.status IN ('dispatched', 'delivered')
            AND EXISTS (
                SELECT 1 FROM users 
                WHERE id = auth.uid() 
                AND role = 'delivery'
            )
        )
    );

CREATE POLICY "Admins and warehouse staff can manage order items" ON order_items
    FOR ALL USING (
        is_deleted = FALSE
        AND EXISTS (
            SELECT 1 FROM users 
            WHERE id = auth.uid() 
            AND role IN ('admin', 'warehouse')
        )
    );

CREATE POLICY "Customers can cancel own order items" ON order_items
    FOR UPDATE USING (
        is_deleted = FALSE
        AND status IN ('pending', 'picked')
        AND EXISTS (
            SELECT 1 FROM orders 
            WHERE orders.id = order_items.order_id
            AND orders.status IN ('draft', 'confirmed')
            AND EXISTS (
                SELECT 1 FROM users 
                WHERE id = auth.uid() 
                AND role = 'customer'
                AND users.email = (SELECT email FROM customers WHERE customers.id = orders.customer_id)
            )
        )
    );
