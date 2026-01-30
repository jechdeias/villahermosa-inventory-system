-- Users table for Villahermosa Marketing
-- Matches Drift Users table structure

CREATE TABLE IF NOT EXISTS users (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    local_id INTEGER UNIQUE, -- Local SQLite ID for sync
    uuid TEXT UNIQUE NOT NULL, -- Local UUID for this record
    name TEXT NOT NULL,
    email TEXT UNIQUE NOT NULL,
    role TEXT NOT NULL CHECK (role IN ('admin', 'warehouse', 'delivery', 'customer')),
    phone TEXT,
    address TEXT,
    is_deleted BOOLEAN DEFAULT FALSE,
    remote_id TEXT, -- Will store local SQLite ID
    sync_status TEXT DEFAULT 'pending' CHECK (sync_status IN ('pending', 'synced', 'conflict')),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Indexes for performance
CREATE INDEX IF NOT EXISTS idx_users_email ON users(email);
CREATE INDEX IF NOT EXISTS idx_users_role ON users(role);
CREATE INDEX IF NOT EXISTS idx_users_sync_status ON users(sync_status);
CREATE INDEX IF NOT EXISTS idx_users_local_id ON users(local_id);

-- RLS (Row Level Security)
ALTER TABLE users ENABLE ROW LEVEL SECURITY;

-- Policies for different user roles
CREATE POLICY "Users can view own profile" ON users
    FOR SELECT USING (auth.uid() = id);

CREATE POLICY "Users can update own profile" ON users
    FOR UPDATE USING (auth.uid() = id);

CREATE POLICY "Admins can view all users" ON users
    FOR SELECT USING (
        EXISTS (
            SELECT 1 FROM users 
            WHERE id = auth.uid() 
            AND role = 'admin'
        )
    );

CREATE POLICY "Admins can update all users" ON users
    FOR UPDATE USING (
        EXISTS (
            SELECT 1 FROM users 
            WHERE id = auth.uid() 
            AND role = 'admin'
        )
    );

CREATE POLICY "Warehouse staff can view all users" ON users
    FOR SELECT USING (
        EXISTS (
            SELECT 1 FROM users 
            WHERE id = auth.uid() 
            AND role IN ('admin', 'warehouse')
        )
    );

CREATE POLICY "Warehouse staff can update non-admin users" ON users
    FOR UPDATE USING (
        EXISTS (
            SELECT 1 FROM users 
            WHERE id = auth.uid() 
            AND role IN ('admin', 'warehouse')
        )
        AND (
            EXISTS (
                SELECT 1 FROM users AS old 
                WHERE old.id = users.id 
                AND old.role = 'admin'
            ) IS FALSE
        )
    );

CREATE POLICY "Delivery personnel can view all users" ON users
    FOR SELECT USING (
        EXISTS (
            SELECT 1 FROM users 
            WHERE id = auth.uid() 
            AND role IN ('admin', 'delivery')
        )
    );

CREATE POLICY "Customers can view own profile" ON users
    FOR SELECT USING (
        EXISTS (
            SELECT 1 FROM users 
            WHERE id = auth.uid() 
            AND role = 'customer'
        )
    );

CREATE POLICY "Customers can update own profile" ON users
    FOR UPDATE USING (
        EXISTS (
            SELECT 1 FROM users 
            WHERE id = auth.uid() 
            AND role = 'customer'
        )
        AND (
            name = COALESCE(NEW.name, old.name) OR
            phone = COALESCE(NEW.phone, old.phone) OR
            address = COALESCE(NEW.address, old.address)
        )
    );

-- Insert policy for new users (admin only)
CREATE POLICY "Admins can insert users" ON users
    FOR INSERT WITH CHECK (role = 'admin')
    USING (
        EXISTS (
            SELECT 1 FROM users 
            WHERE id = auth.uid() 
            AND role = 'admin'
        )
    );
