-- Categories table for product categorization
-- Matches Drift Categories table structure

CREATE TABLE IF NOT EXISTS categories (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    local_id INTEGER UNIQUE, -- Local SQLite ID for sync
    uuid TEXT UNIQUE NOT NULL, -- Local UUID for this record
    name TEXT UNIQUE NOT NULL,
    description TEXT,
    remote_id TEXT, -- Will store local SQLite ID
    sync_status TEXT DEFAULT 'pending' CHECK (sync_status IN ('pending', 'synced', 'conflict')),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Indexes for performance
CREATE INDEX IF NOT EXISTS idx_categories_name ON categories(name);
CREATE INDEX IF NOT EXISTS idx_categories_sync_status ON categories(sync_status);
CREATE INDEX IF NOT EXISTS idx_categories_local_id ON categories(local_id);

-- RLS (Row Level Security)
ALTER TABLE categories ENABLE ROW LEVEL SECURITY;

-- Policies for category management
CREATE POLICY "All authenticated users can view categories" ON categories
    FOR SELECT USING (auth.role() IS NOT NULL);

CREATE POLICY "Admins and warehouse staff can manage categories" ON categories
    FOR ALL USING (
        EXISTS (
            SELECT 1 FROM users 
            WHERE id = auth.uid() 
            AND role IN ('admin', 'warehouse')
        )
    );

CREATE POLICY "Customers can view categories" ON categories
    FOR SELECT USING (
        EXISTS (
            SELECT 1 FROM users 
            WHERE id = auth.uid() 
            AND role = 'customer'
        )
    );

CREATE POLICY "Delivery personnel can view categories" ON categories
    FOR SELECT USING (
        EXISTS (
            SELECT 1 FROM users 
            WHERE id = auth.uid() 
            AND role = 'delivery'
        )
    );

CREATE POLICY "Admins can insert categories" ON categories
    FOR INSERT WITH CHECK (
        EXISTS (
            SELECT 1 FROM users 
            WHERE id = auth.uid() 
            AND role = 'admin'
        )
    );
