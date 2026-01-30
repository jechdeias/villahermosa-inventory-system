-- Customers table for Villahermosa Marketing
-- Matches Drift Customers table structure

CREATE TABLE IF NOT EXISTS customers (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    local_id INTEGER UNIQUE, -- Local SQLite ID for sync
    uuid TEXT UNIQUE NOT NULL, -- Local UUID for this record
    name TEXT NOT NULL,
    email TEXT UNIQUE,
    phone TEXT,
    address TEXT,
    
    -- Business information
    business_name TEXT,
    tax_id TEXT,
    customer_type TEXT DEFAULT 'individual' CHECK (customer_type IN ('individual', 'business')),
    
    -- Credit and payment terms
    credit_limit DECIMAL(10,2),
    payment_terms TEXT,
    
    -- Status and preferences
    status TEXT DEFAULT 'active' CHECK (status IN ('active', 'inactive', 'suspended')),
    preferred_contact_method TEXT DEFAULT 'email' CHECK (preferred_contact_method IN ('email', 'phone', 'sms')),
    
    -- Soft delete for sync safety
    is_deleted BOOLEAN DEFAULT FALSE,
    
    -- Sync tracking
    remote_id TEXT, -- Will store local SQLite ID
    sync_status TEXT DEFAULT 'pending' CHECK (sync_status IN ('pending', 'synced', 'conflict')),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Indexes for performance
CREATE INDEX IF NOT EXISTS idx_customers_email ON customers(email);
CREATE INDEX IF NOT EXISTS idx_customers_name ON customers(name);
CREATE INDEX IF NOT EXISTS idx_customers_business_name ON customers(business_name);
CREATE INDEX IF NOT EXISTS idx_customers_customer_type ON customers(customer_type);
CREATE INDEX IF NOT EXISTS idx_customers_status ON customers(status);
CREATE INDEX IF NOT EXISTS idx_customers_sync_status ON customers(sync_status);
CREATE INDEX IF NOT EXISTS idx_customers_local_id ON customers(local_id);

-- RLS (Row Level Security)
ALTER TABLE customers ENABLE ROW LEVEL SECURITY;

-- Policies for customer management
CREATE POLICY "Admins and warehouse staff can view all customers" ON customers
    FOR SELECT USING (
        is_deleted = FALSE
        AND EXISTS (
            SELECT 1 FROM users 
            WHERE id = auth.uid() 
            AND role IN ('admin', 'warehouse')
        )
    );

CREATE POLICY "Customers can view own profile" ON customers
    FOR SELECT USING (
        is_deleted = FALSE
        AND EXISTS (
            SELECT 1 FROM users 
            WHERE id = auth.uid() 
            AND role = 'customer'
            AND users.email = customers.email
        )
    );

CREATE POLICY "Delivery personnel can view customers" ON customers
    FOR SELECT USING (
        is_deleted = FALSE
        AND EXISTS (
            SELECT 1 FROM users 
            WHERE id = auth.uid() 
            AND role = 'delivery'
        )
    );

CREATE POLICY "Admins can insert customers" ON customers
    FOR INSERT WITH CHECK (
        is_deleted = FALSE
        AND EXISTS (
            SELECT 1 FROM users 
            WHERE id = auth.uid() 
            AND role = 'admin'
        )
    );

CREATE POLICY "Admins and warehouse staff can update customers" ON customers
    FOR UPDATE USING (
        is_deleted = FALSE
        AND EXISTS (
            SELECT 1 FROM users 
            WHERE id = auth.uid() 
            AND role IN ('admin', 'warehouse')
        )
    );

CREATE POLICY "Customers can update own profile" ON customers
    FOR UPDATE USING (
        is_deleted = FALSE
        AND EXISTS (
            SELECT 1 FROM users 
            WHERE id = auth.uid() 
            AND role = 'customer'
            AND users.email = customers.email
        )
        AND (
            phone = COALESCE(NEW.phone, old.phone) OR
            address = COALESCE(NEW.address, old.address) OR
            preferred_contact_method = COALESCE(NEW.preferred_contact_method, old.preferred_contact_method)
        )
    );

CREATE POLICY "Admins and warehouse staff can delete customers" ON customers
    FOR DELETE USING (
        EXISTS (
            SELECT 1 FROM users 
            WHERE id = auth.uid() 
            AND role IN ('admin', 'warehouse')
        )
    );
