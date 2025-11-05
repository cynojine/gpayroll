-- ==========================================
-- GPTPAYROLL COMPLETE MIGRATION SCRIPT
-- This script handles all common database setup issues
-- Run this to ensure your database is fully set up
-- ==========================================

-- ==========================================
-- SECTION 1: CHECK AND ADD MISSING COLUMNS
-- ==========================================

-- Check if company_settings table has all required columns
DO $$
DECLARE
    table_exists BOOLEAN;
    col_nhima_rate_exists BOOLEAN;
BEGIN
    -- Check if company_settings table exists
    SELECT EXISTS (
        SELECT 1 FROM information_schema.tables 
        WHERE table_name = 'company_settings' 
        AND table_schema = 'public'
    ) INTO table_exists;
    
    IF table_exists THEN
        -- Check for nhima_rate column
        SELECT EXISTS (
            SELECT 1 FROM information_schema.columns 
            WHERE table_name = 'company_settings' 
            AND column_name = 'nhima_rate'
        ) INTO col_nhima_rate_exists;
        
        -- Add nhima_rate column if missing
        IF NOT col_nhima_rate_exists THEN
            ALTER TABLE public.company_settings 
            ADD COLUMN nhima_rate DECIMAL(5,4) DEFAULT 0.01;
            RAISE NOTICE 'Added nhima_rate column to company_settings';
        END IF;
        
        RAISE NOTICE 'company_settings table structure verified';
    END IF;
END $$;

-- ==========================================
-- SECTION 2: ENSURE REQUIRED TABLES EXIST
-- ==========================================

-- Create tables only if they don't exist
-- Users table
CREATE TABLE IF NOT EXISTS public.users (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  email TEXT UNIQUE NOT NULL,
  full_name TEXT,
  role TEXT NOT NULL CHECK (role IN ('admin', 'hr', 'employee')) DEFAULT 'employee',
  is_active BOOLEAN DEFAULT TRUE,
  last_login TIMESTAMP WITH TIME ZONE,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Employees table
CREATE TABLE IF NOT EXISTS public.employees (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES public.users(id) ON DELETE CASCADE,
  employee_number TEXT UNIQUE NOT NULL,
  first_name TEXT NOT NULL,
  last_name TEXT NOT NULL,
  middle_name TEXT,
  email TEXT NOT NULL,
  phone_number TEXT,
  date_of_birth DATE,
  gender TEXT CHECK (gender IN ('Male', 'Female', 'Other')),
  nationality TEXT DEFAULT 'Zambian',
  nrc TEXT,
  tpin TEXT,
  passport_number TEXT,
  marital_status TEXT CHECK (marital_status IN ('Single', 'Married', 'Divorced', 'Widowed')),
  physical_address TEXT,
  postal_address TEXT,
  city TEXT,
  province TEXT,
  country TEXT DEFAULT 'Zambia',
  department_id UUID,
  designation_id UUID,
  employment_type TEXT CHECK (employment_type IN ('Full-time', 'Part-time', 'Contract', 'Intern')) DEFAULT 'Full-time',
  employee_status TEXT CHECK (employee_status IN ('Active', 'Inactive', 'Terminated', 'Suspended')) DEFAULT 'Active',
  hire_date DATE NOT NULL,
  termination_date DATE,
  bank_name TEXT,
  bank_branch TEXT,
  account_number TEXT,
  account_name TEXT,
  emergency_contact_name TEXT,
  emergency_contact_phone TEXT,
  emergency_contact_relationship TEXT,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Company settings table (with all columns)
CREATE TABLE IF NOT EXISTS public.company_settings (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  company_name TEXT NOT NULL,
  company_logo_url TEXT,
  registration_number TEXT,
  tax_id TEXT,
  address TEXT,
  phone TEXT,
  email TEXT,
  website TEXT,
  pay_frequency TEXT CHECK (pay_frequency IN ('weekly', 'bi-weekly', 'monthly')) DEFAULT 'monthly',
  payroll_cutoff_day INTEGER DEFAULT 25,
  overtime_rate_multiplier DECIMAL(3,2) DEFAULT 1.50,
  working_hours_per_day DECIMAL(3,1) DEFAULT 8.0,
  working_days_per_week INTEGER DEFAULT 5,
  paye_tax_bands JSONB NOT NULL,
  paye_threshold DECIMAL(10,2) DEFAULT 5100.00,
  napsa_rate DECIMAL(5,4) DEFAULT 0.05,
  napsa_cap DECIMAL(10,2) DEFAULT 1149.60,
  nhis_rate DECIMAL(5,4) DEFAULT 0.01,
  nhima_rate DECIMAL(5,4) DEFAULT 0.01,
  company_bank_name TEXT,
  company_bank_branch TEXT,
  company_account_number TEXT,
  company_account_name TEXT,
  smtp_host TEXT,
  smtp_port INTEGER,
  smtp_username TEXT,
  smtp_password TEXT,
  from_email TEXT,
  from_name TEXT,
  email_notifications BOOLEAN DEFAULT TRUE,
  sms_notifications BOOLEAN DEFAULT FALSE,
  leave_reminder_days INTEGER DEFAULT 7,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Create other essential tables (simplified version)
CREATE TABLE IF NOT EXISTS public.departments (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name TEXT UNIQUE NOT NULL,
  description TEXT,
  manager_id UUID REFERENCES public.users(id),
  is_active BOOLEAN DEFAULT TRUE,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS public.designations (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name TEXT UNIQUE NOT NULL,
  description TEXT,
  department_id UUID REFERENCES public.departments(id),
  is_active BOOLEAN DEFAULT TRUE,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS public.payroll_records (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  employee_id UUID NOT NULL REFERENCES public.employees(id) ON DELETE CASCADE,
  payroll_month INTEGER NOT NULL CHECK (payroll_month BETWEEN 1 AND 12),
  payroll_year INTEGER NOT NULL,
  basic_salary DECIMAL(15,2) NOT NULL,
  overtime_hours DECIMAL(8,2) DEFAULT 0,
  overtime_rate DECIMAL(8,2) DEFAULT 0,
  overtime_amount DECIMAL(15,2) DEFAULT 0,
  bonus DECIMAL(15,2) DEFAULT 0,
  allowances DECIMAL(15,2) DEFAULT 0,
  commission DECIMAL(15,2) DEFAULT 0,
  gross_pay DECIMAL(15,2) NOT NULL,
  paye_tax DECIMAL(15,2) NOT NULL,
  napsa_contribution DECIMAL(15,2) NOT NULL,
  nhis_contribution DECIMAL(15,2) NOT NULL,
  nhima_contribution DECIMAL(15,2) DEFAULT 0,
  other_deductions DECIMAL(15,2) DEFAULT 0,
  total_deductions DECIMAL(15,2) NOT NULL,
  net_pay DECIMAL(15,2) NOT NULL,
  payment_status TEXT CHECK (payment_status IN ('Pending', 'Processed', 'Paid', 'Failed')) DEFAULT 'Pending',
  payment_date DATE,
  payment_method TEXT DEFAULT 'Bank Transfer',
  reference_number TEXT,
  pay_period_start DATE NOT NULL,
  pay_period_end DATE NOT NULL,
  processed_by UUID REFERENCES public.users(id),
  processed_at TIMESTAMP WITH TIME ZONE,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  UNIQUE(employee_id, payroll_month, payroll_year)
);

-- ==========================================
-- SECTION 3: CREATE ESSENTIAL FUNCTIONS
-- ==========================================

-- Function to update the updated_at column
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ language 'plpgsql';

-- Helper function to get user role
CREATE OR REPLACE FUNCTION get_user_role(user_uuid UUID)
RETURNS TEXT AS $$
DECLARE
    user_role TEXT;
BEGIN
    SELECT role INTO user_role FROM public.users WHERE id = user_uuid;
    RETURN COALESCE(user_role, 'employee');
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ==========================================
-- SECTION 4: CREATE TRIGGERS
-- ==========================================

-- Drop existing triggers if they exist and recreate
DROP TRIGGER IF EXISTS update_users_updated_at ON public.users;
DROP TRIGGER IF EXISTS update_employees_updated_at ON public.employees;
DROP TRIGGER IF EXISTS update_company_settings_updated_at ON public.company_settings;

-- Create updated_at triggers
CREATE TRIGGER update_users_updated_at BEFORE UPDATE ON public.users FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_employees_updated_at BEFORE UPDATE ON public.employees FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_company_settings_updated_at BEFORE UPDATE ON public.company_settings FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- ==========================================
-- SECTION 5: ENABLE RLS
-- ==========================================

-- Enable RLS on all tables
ALTER TABLE public.users ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.employees ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.company_settings ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.departments ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.designations ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.payroll_records ENABLE ROW LEVEL SECURITY;

-- ==========================================
-- SECTION 6: CREATE RLS POLICIES
-- ==========================================

-- Drop existing policies and recreate clean ones
DROP POLICY IF EXISTS "Users can view their own profile" ON public.users;
DROP POLICY IF EXISTS "Users can update their own profile" ON public.users;
DROP POLICY IF EXISTS "Company settings view policy" ON public.company_settings;

-- Users policies
CREATE POLICY "Users can view their own profile" ON public.users FOR SELECT USING (auth.uid() = id);
CREATE POLICY "Users can update their own profile" ON public.users FOR UPDATE USING (auth.uid() = id);

-- Company settings policies
CREATE POLICY "Company settings view policy" ON public.company_settings FOR SELECT USING (true);

-- ==========================================
-- SECTION 7: INSERT DEFAULT DATA
-- ==========================================

-- Insert default company settings
INSERT INTO public.company_settings (
  company_name,
  registration_number,
  tax_id,
  address,
  phone,
  email,
  website,
  paye_tax_bands,
  napsa_cap,
  nhima_rate
) VALUES (
  'GPTPayroll Demo Company Ltd',
  '2019001234',
  '1234567890',
  'Plot 123, Business District, Lusaka, Zambia',
  '+260 211 123456',
  'info@gptpayrolldemo.com',
  'www.gptpayrolldemo.com',
  '{
    "bands": [
      {"min": 0, "max": 5100, "rate": 0.00},
      {"min": 5100, "max": 7100, "rate": 0.20},
      {"min": 7100, "max": 9200, "rate": 0.30},
      {"min": 9200, "max": null, "rate": 0.37}
    ]
  }',
  1149.60,
  0.01
) ON CONFLICT (company_name) DO NOTHING;

-- Insert default departments
INSERT INTO public.departments (name, description) VALUES
('Human Resources', 'Manages employee relations, recruitment, and development'),
('Finance', 'Handles accounting, financial planning, and payroll'),
('Information Technology', 'Manages technology infrastructure and software development'),
('Operations', 'Handles daily business operations and processes')
ON CONFLICT (name) DO NOTHING;

-- Insert Zambian public holidays for 2025
INSERT INTO public.public_holidays (name, date, year, description) VALUES
('New Year''s Day', '2025-01-01', 2025, 'Celebration of the New Year'),
('Women''s Day', '2025-03-08', 2025, 'International Women''s Day'),
('Good Friday', '2025-04-18', 2025, 'Christian holiday commemorating Jesus'' crucifixion'),
('Easter Monday', '2025-04-21', 2025, 'Christian holiday following Easter Sunday'),
('Labour Day', '2025-05-01', 2025, 'International Workers'' Day'),
('African Freedom Day', '2025-05-25', 2025, 'African Union Day'),
('Independence Day', '2025-10-24', 2025, 'Zambia Independence Day'),
('Christmas Day', '2025-12-25', 2025, 'Christmas Day'),
('Boxing Day', '2025-12-26', 2025, 'Day after Christmas')
ON CONFLICT (name, date) DO NOTHING;

-- ==========================================
-- SECTION 8: VERIFICATION
-- ==========================================

-- Check table creation
SELECT 
    table_name,
    CASE WHEN table_name IN (
        'users', 'employees', 'company_settings', 
        'departments', 'designations', 'payroll_records'
    ) THEN 'CREATED' ELSE 'MISSING' END as status
FROM information_schema.tables 
WHERE table_schema = 'public' 
AND table_type = 'BASE TABLE'
ORDER BY table_name;

-- Verify RLS is enabled
SELECT 
    tablename as table_name,
    rowsecurity as rls_enabled
FROM pg_tables 
WHERE schemaname = 'public' 
AND tablename IN (
    'users', 'employees', 'company_settings', 
    'departments', 'designations', 'payroll_records'
)
ORDER BY tablename;

-- Verify default data exists
SELECT 
    'company_settings' as table_name, 
    COUNT(*) as record_count 
FROM public.company_settings
UNION ALL
SELECT 
    'departments' as table_name, 
    COUNT(*) as record_count 
FROM public.departments;

-- Final status message
SELECT 
    'GPTPayroll Migration Completed Successfully!' as status,
    'Database structure and default data are now ready.' as message,
    now() as completed_at;