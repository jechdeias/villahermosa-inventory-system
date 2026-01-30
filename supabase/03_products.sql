-- Products table for Villahermosa Marketing
-- Matches Drift Products table structure

CREATE TABLE IF NOT EXISTS products (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    local_id INTEGER UNIQUE, -- Local SQLite ID for sync
    uuid TEXT UNIQUE NOT NULL, -- Local UUID for this record
    sku TEXT UNIQUE NOT NULL,
    name TEXT NOT NULL,
    description TEXT,
    category TEXT,
    brand TEXT,
    
    -- Inventory tracking
    current_stock INTEGER DEFAULT 0,
    min_stock INTEGER DEFAULT 0,
    max_stock INTEGER,
    unit TEXT DEFAULT 'pcs',
    unit_price DECIMAL(10,2) DEFAULT 0.00,
    cost_price DECIMAL(10,2),
    
    -- Status and metadata
    status TEXT DEFAULT 'active' CHECK (status IN ('active', 'inactive', 'discontinued')),
    barcode TEXT,
    location TEXT DEFAULT 'Warehouse A',
    supplier TEXT,
    
    -- Soft delete for sync safety
    is_deleted BOOLEAN DEFAULT FALSE,
    
    -- Sync tracking
    remote_id TEXT, -- Will store local SQLite ID
    sync_status TEXT DEFAULT 'pending' CHECK (sync_status IN ('pending', 'synced', 'conflict')),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Indexes for performance
CREATE INDEX IF NOT EXISTS idx_products_sku ON products(sku);
CREATE INDEX IF NOT EXISTS idx_products_name ON products(name);
CREATE INDEX IF NOT EXISTS idx_products_category ON products(category);
CREATE INDEX idx_products_status ON products(status);
CREATE INDEX IF NOT EXISTS idx_products_sync_status ON products(sync_status);
CREATE INDEX IF NOT EXISTS idx_products_local_id ON products(local_id);
CREATE INDEX IF NOT EXISTS idx_products_current_stock ON products(current_stock);

-- RLS (Row Level Security)
ALTER TABLE products ENABLE ROW LEVEL SECURITY;

-- Policies for product management
CREATE POLICY "All authenticated users can view products" ON products
    FOR SELECT USING (
        is_deleted = FALSE
        AND auth.role() IS NOT NULL
    );

CREATE POLICY "Admins and warehouse staff can manage products" ON products
    FOR ALL USING (
        is_deleted = FALSE
        AND EXISTS (
            SELECT 1 FROM users 
            WHERE id = auth.uid() 
            AND role IN ('admin', 'warehouse')
        )
    );

CREATE POLICY "Customers can view products" ON products
    FOR SELECT USING (
        is_deleted = FALSE
        AND EXISTS (
            SELECT 1 FROM users 
            WHERE id = auth.uid() 
            AND role = 'customer'
        )
    );

CREATE POLICY "Delivery personnel can view products" ON products
    FOR SELECT USING (
        is_deleted = FALSE
        AND EXISTS (
            SELECT 1 FROM users 
            WHERE id = auth.uid() 
            AND role = 'delivery'
        )
    );

CREATE POLICY "Admins can insert products" ON products
    FOR INSERT WITH CHECK (
        is_deleted = FALSE
        AND EXISTS (
            SELECT 1 FROM users 
            WHERE id = auth.uid() 
            AND role = 'admin'
        )
    );

CREATE POLICY "Admins and warehouse staff can update products" ON products
    FOR UPDATE USING (
        is_deleted = FALSE
        AND EXISTS (
            SELECT 1 FROM users 
            WHERE id = auth.uid() 
            AND role IN ('admin', 'warehouse')
        )
    );

CREATE POLICY "Admins and warehouse staff can delete products" ON products
    FOR DELETE USING (
        EXISTS (
            SELECT 1 FROM users 
            WHERE id = auth.uid() 
            AND role IN ('admin', 'warehouse')
        )
    );
