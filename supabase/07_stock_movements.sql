-- StockMovements table for Villahermosa Marketing
-- Matches Drift StockMovements table structure

CREATE TABLE IF NOT EXISTS stock_movements (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    local_id INTEGER UNIQUE, -- Local SQLite ID for sync
    uuid TEXT UNIQUE NOT NULL, -- Local UUID for this record
    
    -- Product reference
    product_id UUID NOT NULL REFERENCES products(id),
    
    -- Movement details
    movement_type TEXT NOT NULL CHECK (movement_type IN ('stock_in', 'stock_out', 'adjustment', 'transfer')),
    quantity INTEGER NOT NULL, -- Positive for stock in, negative for stock out
    reference_type TEXT CHECK (reference_type IN ('order', 'delivery', 'manual_adjustment', 'return')),
    reference_id TEXT, -- Reference to related record ID
    
    -- Reason and notes
    reason TEXT NOT NULL,
    notes TEXT,
    
    -- User who performed the action
    user_id UUID NOT NULL REFERENCES users(id),
    user_name TEXT NOT NULL, -- Denormalized for audit trail
    
    -- Location tracking
    from_location TEXT,
    to_location TEXT,
    
    -- Financial impact
    unit_cost DECIMAL(10,2),
    total_cost DECIMAL(12,2),
    
    -- Status and approval
    status TEXT DEFAULT 'completed' CHECK (status IN ('pending', 'completed', 'cancelled')),
    approved_by UUID REFERENCES users(id),
    approved_at TIMESTAMP WITH TIME ZONE,
    
    -- Soft delete for sync safety
    is_deleted BOOLEAN DEFAULT FALSE,
    
    -- Sync tracking
    remote_id TEXT, -- Will store local SQLite ID
    sync_status TEXT DEFAULT 'pending' CHECK (sync_status IN ('pending', 'synced', 'conflict')),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Indexes for performance
CREATE INDEX IF NOT EXISTS idx_stock_movements_product_id ON stock_movements(product_id);
CREATE INDEX IF NOT EXISTS idx_stock_movements_user_id ON stock_movements(user_id);
CREATE INDEX IF NOT EXISTS idx_stock_movements_movement_type ON stock_movements(movement_type);
CREATE INDEX IF NOT EXISTS idx_stock_movements_status ON stock_movements(status);
CREATE INDEX IF NOT EXISTS idx_stock_movements_created_at ON stock_movements(created_at);
CREATE INDEX IF NOT EXISTS idx_stock_movements_sync_status ON stock_movements(sync_status);
CREATE INDEX IF NOT EXISTS idx_stock_movements_local_id ON stock_movements(local_id);

-- RLS (Row Level Security)
ALTER TABLE stock_movements ENABLE ROW LEVEL SECURITY;

-- Policies for stock movement management
CREATE POLICY "Admins and warehouse staff can view all stock movements" ON stock_movements
    FOR SELECT USING (
        is_deleted = FALSE
        AND EXISTS (
            SELECT 1 FROM users 
            WHERE id = auth.uid() 
            AND role IN ('admin', 'warehouse')
        )
    );

CREATE POLICY "Delivery personnel can view stock movements" ON stock_movements
    FOR SELECT USING (
        is_deleted = FALSE
        AND EXISTS (
            SELECT 1 FROM users 
            WHERE id = auth.uid() 
            AND role = 'delivery'
        )
        AND movement_type IN ('stock_out')
        AND reference_type IN ('delivery', 'return')
    );

CREATE POLICY "Admins and warehouse staff can manage stock movements" ON stock_movements
    FOR ALL USING (
        is_deleted = FALSE
        AND EXISTS (
            SELECT 1 FROM users 
            WHERE id = auth.uid() 
            AND role IN ('admin', 'warehouse')
        )
    );

CREATE POLICY "Delivery personnel can create delivery stock movements" ON stock_movements
    FOR INSERT WITH CHECK (
        is_deleted = FALSE
        AND EXISTS (
            SELECT 1 FROM users 
            WHERE id = auth.uid() 
            AND role = 'delivery'
        )
        AND movement_type IN ('stock_out')
        AND reference_type IN ('delivery', 'return')
    );
