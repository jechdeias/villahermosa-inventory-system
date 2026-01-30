-- Deliveries table for Villahermosa Marketing
-- Matches Drift Deliveries table structure

CREATE TABLE IF NOT EXISTS deliveries (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    local_id INTEGER UNIQUE, -- Local SQLite ID for sync
    uuid TEXT UNIQUE NOT NULL, -- Local UUID for this record
    
    -- Order reference
    order_id UUID NOT NULL REFERENCES orders(id),
    
    -- Delivery personnel
    delivery_personnel_id UUID NOT NULL REFERENCES users(id),
    delivery_personnel_name TEXT NOT NULL,
    delivery_personnel_phone TEXT NOT NULL,
    
    -- Delivery details
    delivery_number TEXT UNIQUE NOT NULL,
    scheduled_date TIMESTAMP WITH TIME ZONE NOT NULL,
    actual_start_time TIMESTAMP WITH TIME ZONE,
    actual_completion_time TIMESTAMP WITH TIME ZONE,
    
    -- Status tracking
    status TEXT DEFAULT 'pending' CHECK (status IN ('pending', 'assigned', 'in_progress', 'completed', 'failed', 'cancelled')),
    sub_status TEXT,
    
    -- Route information
    route TEXT,
    route_order INTEGER,
    vehicle_number TEXT,
    
    -- Location tracking
    start_location TEXT NOT NULL,
    end_location TEXT NOT NULL,
    start_latitude DECIMAL(10,8),
    start_longitude DECIMAL(11,8),
    end_latitude DECIMAL(10,8),
    end_longitude DECIMAL(11,8),
    
    -- Proof of delivery
    proof_of_delivery_type TEXT CHECK (proof_of_delivery_type IN ('photo', 'signature', 'none')),
    proof_of_delivery_url TEXT,
    recipient_name TEXT,
    recipient_relation TEXT,
    delivery_notes TEXT,
    
    -- Financial
    collected_amount DECIMAL(12,2) DEFAULT 0.00,
    payment_method TEXT CHECK (payment_method IN ('cash', 'check', 'digital')),
    check_number TEXT,
    
    -- Issues and exceptions
    issue_type TEXT CHECK (issue_type IN ('late_delivery', 'damaged_goods', 'wrong_items', 'customer_refused')),
    issue_description TEXT,
    resolution TEXT,
    
    -- Metadata
    priority TEXT DEFAULT 'normal' CHECK (priority IN ('low', 'normal', 'high', 'urgent')),
    attempt_count INTEGER DEFAULT 0 CHECK (attempt_count >= 0),
    next_attempt_date TIMESTAMP WITH TIME ZONE,
    
    -- Soft delete for sync safety
    is_deleted BOOLEAN DEFAULT FALSE,
    
    -- Sync tracking
    remote_id TEXT, -- Will store local SQLite ID
    sync_status TEXT DEFAULT 'pending' CHECK (sync_status IN ('pending', 'synced', 'conflict')),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Indexes for performance
CREATE INDEX IF NOT EXISTS idx_deliveries_order_id ON deliveries(order_id);
CREATE INDEX IF NOT EXISTS idx_deliveries_delivery_personnel_id ON deliveries(delivery_personnel_id);
CREATE INDEX IF NOT EXISTS idx_deliveries_delivery_number ON deliveries(delivery_number);
CREATE INDEX IF NOT EXISTS idx_deliveries_status ON deliveries(status);
CREATE INDEX IF NOT EXISTS idx_deliveries_scheduled_date ON deliveries(scheduled_date);
CREATE INDEX IF NOT EXISTS idx_deliveries_route ON deliveries(route);
CREATE INDEX IF NOT EXISTS idx_deliveries_sync_status ON deliveries(sync_status);
CREATE INDEX IF NOT EXISTS idx_deliveries_local_id ON deliveries(local_id);

-- RLS (Row Level Security)
ALTER TABLE deliveries ENABLE ROW LEVEL SECURITY;

-- Policies for delivery management
CREATE POLICY "Admins and warehouse staff can view all deliveries" ON deliveries
    FOR SELECT USING (
        is_deleted = FALSE
        AND EXISTS (
            SELECT 1 FROM users 
            WHERE id = auth.uid() 
            AND role IN ('admin', 'warehouse')
        )
    );

CREATE POLICY "Delivery personnel can view assigned deliveries" ON deliveries
    FOR SELECT USING (
        is_deleted = FALSE
        AND delivery_personnel_id = auth.uid()
        AND EXISTS (
            SELECT 1 FROM users 
            WHERE id = auth.uid() 
            AND role = 'delivery'
        )
    );

CREATE POLICY "Customers can view own deliveries" ON deliveries
    FOR SELECT USING (
        is_deleted = FALSE
        AND EXISTS (
            SELECT 1 FROM orders 
            WHERE orders.id = deliveries.order_id
            AND EXISTS (
                SELECT 1 FROM users 
                WHERE id = auth.uid() 
                AND role = 'customer'
                AND users.email = (SELECT email FROM customers WHERE customers.id = orders.customer_id)
            )
        )
    );

CREATE POLICY "Admins and warehouse staff can manage deliveries" ON deliveries
    FOR ALL USING (
        is_deleted = FALSE
        AND EXISTS (
            SELECT 1 FROM users 
            WHERE id = auth.uid() 
            AND role IN ('admin', 'warehouse')
        )
    );

CREATE POLICY "Delivery personnel can update assigned deliveries" ON deliveries
    FOR UPDATE USING (
        is_deleted = FALSE
        AND delivery_personnel_id = auth.uid()
        AND EXISTS (
            SELECT 1 FROM users 
            WHERE id = auth.uid() 
            AND role = 'delivery'
        )
    );
