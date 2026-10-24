-- ==============================================================================
-- SETOKE.SU - Supabase Database Schema
-- Run this in your Supabase Project: SQL Editor -> New Query -> Run
-- ==============================================================================

-- 1. STORES TABLE
CREATE TABLE IF NOT EXISTS public.stores (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name TEXT NOT NULL,
    owner_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- 2. USER PROFILES TABLE (Linked with Supabase Auth)
CREATE TABLE IF NOT EXISTS public.profiles (
    id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
    store_id UUID REFERENCES public.stores(id) ON DELETE CASCADE,
    full_name TEXT NOT NULL,
    email TEXT NOT NULL,
    role TEXT NOT NULL CHECK (role IN ('admin', 'crew')),
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- 3. SUPPLIERS TABLE
CREATE TABLE IF NOT EXISTS public.suppliers (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    store_id UUID REFERENCES public.stores(id) ON DELETE CASCADE,
    name TEXT NOT NULL,
    phone TEXT,
    address TEXT,
    contact_person TEXT,
    notes TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- 4. ITEMS TABLE (Inventory Ingredients)
CREATE TABLE IF NOT EXISTS public.items (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    store_id UUID REFERENCES public.stores(id) ON DELETE CASCADE,
    name TEXT NOT NULL,
    category TEXT NOT NULL,
    unit TEXT NOT NULL, -- 'g', 'ml', 'pcs'
    min_stock NUMERIC NOT NULL DEFAULT 0,
    buy_price NUMERIC,
    supplier_id UUID REFERENCES public.suppliers(id) ON DELETE SET NULL,
    created_by UUID REFERENCES auth.users(id),
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- 5. BATCHES TABLE (FIFO Tracking)
CREATE TABLE IF NOT EXISTS public.batches (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    item_id UUID REFERENCES public.items(id) ON DELETE CASCADE,
    batch_code TEXT NOT NULL,
    initial_quantity NUMERIC NOT NULL,
    remaining_quantity NUMERIC NOT NULL,
    buy_price NUMERIC,
    supplier_id UUID REFERENCES public.suppliers(id) ON DELETE SET NULL,
    received_date TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    expiry_date TIMESTAMPTZ,
    created_by UUID REFERENCES auth.users(id),
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- 6. RECIPES TABLE
CREATE TABLE IF NOT EXISTS public.recipes (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    store_id UUID REFERENCES public.stores(id) ON DELETE CASCADE,
    name TEXT NOT NULL,
    sell_price NUMERIC NOT NULL,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- 7. RECIPE INGREDIENTS TABLE
CREATE TABLE IF NOT EXISTS public.recipe_ingredients (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    recipe_id UUID REFERENCES public.recipes(id) ON DELETE CASCADE,
    item_id UUID REFERENCES public.items(id) ON DELETE CASCADE,
    quantity NUMERIC NOT NULL,
    unit TEXT NOT NULL
);

-- 8. SALES TABLE
CREATE TABLE IF NOT EXISTS public.sales (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    store_id UUID REFERENCES public.stores(id) ON DELETE CASCADE,
    recipe_id UUID REFERENCES public.recipes(id) ON DELETE SET NULL,
    product_name TEXT NOT NULL,
    quantity INT NOT NULL,
    total_price NUMERIC NOT NULL,
    performed_by UUID REFERENCES auth.users(id),
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- 9. SALE DEDUCTIONS TABLE (Ingredient Cuts per Batch)
CREATE TABLE IF NOT EXISTS public.sale_deductions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    sale_id UUID REFERENCES public.sales(id) ON DELETE CASCADE,
    item_id UUID REFERENCES public.items(id) ON DELETE CASCADE,
    batch_id UUID REFERENCES public.batches(id) ON DELETE SET NULL,
    quantity_deducted NUMERIC NOT NULL,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- 10. STOCK TRANSACTIONS TABLE (Audit Trail: Restock, Usage, Sale, Adjustment)
CREATE TABLE IF NOT EXISTS public.stock_transactions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    store_id UUID REFERENCES public.stores(id) ON DELETE CASCADE,
    item_id UUID REFERENCES public.items(id) ON DELETE CASCADE,
    batch_id UUID REFERENCES public.batches(id) ON DELETE SET NULL,
    type TEXT NOT NULL, -- 'restock', 'usage', 'sale', 'adjustment'
    quantity NUMERIC NOT NULL,
    reason TEXT,
    notes TEXT,
    performed_by UUID REFERENCES auth.users(id),
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- 11. NOTIFICATIONS TABLE
CREATE TABLE IF NOT EXISTS public.notifications (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    store_id UUID REFERENCES public.stores(id) ON DELETE CASCADE,
    type TEXT NOT NULL, -- 'low_stock', 'expiry', 'general'
    title TEXT NOT NULL,
    message TEXT NOT NULL,
    item_id UUID REFERENCES public.items(id) ON DELETE SET NULL,
    is_read BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- RPC Helper: Get items with calculated current stock
CREATE OR REPLACE FUNCTION get_items_with_stock(p_store_id UUID)
RETURNS TABLE (
    id UUID,
    store_id UUID,
    name TEXT,
    category TEXT,
    unit TEXT,
    min_stock NUMERIC,
    buy_price NUMERIC,
    supplier_id UUID,
    created_by UUID,
    created_at TIMESTAMPTZ,
    updated_at TIMESTAMPTZ,
    current_stock NUMERIC
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        i.id,
        i.store_id,
        i.name,
        i.category,
        i.unit,
        i.min_stock,
        i.buy_price,
        i.supplier_id,
        i.created_by,
        i.created_at,
        i.updated_at,
        COALESCE(SUM(b.remaining_quantity), 0) AS current_stock
    FROM public.items i
    LEFT JOIN public.batches b ON b.item_id = i.id
    WHERE i.store_id = p_store_id
    GROUP BY i.id
    ORDER BY i.name ASC;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Enable Row Level Security (RLS) on all tables
ALTER TABLE public.stores ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.suppliers ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.items ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.batches ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.recipes ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.recipe_ingredients ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.sales ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.sale_deductions ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.stock_transactions ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.notifications ENABLE ROW LEVEL SECURITY;

-- Allow authenticated users to select & modify records matching their store
CREATE POLICY "Users can access store records" ON public.stores
    FOR ALL TO authenticated USING (true);

CREATE POLICY "Users can access profiles" ON public.profiles
    FOR ALL TO authenticated USING (true);

CREATE POLICY "Users can access suppliers" ON public.suppliers
    FOR ALL TO authenticated USING (true);

CREATE POLICY "Users can access items" ON public.items
    FOR ALL TO authenticated USING (true);

CREATE POLICY "Users can access batches" ON public.batches
    FOR ALL TO authenticated USING (true);

CREATE POLICY "Users can access recipes" ON public.recipes
    FOR ALL TO authenticated USING (true);

CREATE POLICY "Users can access recipe_ingredients" ON public.recipe_ingredients
    FOR ALL TO authenticated USING (true);

CREATE POLICY "Users can access sales" ON public.sales
    FOR ALL TO authenticated USING (true);

CREATE POLICY "Users can access sale_deductions" ON public.sale_deductions
    FOR ALL TO authenticated USING (true);

CREATE POLICY "Users can access stock_transactions" ON public.stock_transactions
    FOR ALL TO authenticated USING (true);

CREATE POLICY "Users can access notifications" ON public.notifications
    FOR ALL TO authenticated USING (true);
