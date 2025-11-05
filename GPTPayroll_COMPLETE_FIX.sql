-- ==========================================
-- GPTPAYROLL COMPLETE DATABASE FIX
-- Run this entire script - it fixes everything
-- ==========================================

-- Enable extensions
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- Create users table (matches Supabase auth)
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

-- Create departments
CREATE TABLE IF NOT EXISTS public.departments (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name TEXT UNIQUE NOT NULL,
  description TEXT,
  manager_id UUID REFERENCES public.users(id),
  is_active BOOLEAN DEFAULT TRUE,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Create designations
CREATE TABLE IF NOT EXISTS public.designations (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name TEXT UNIQUE NOT NULL,
  description TEXT,
  department_id UUID REFERENCES public.departments(id),
  is_active BOOLEAN DEFAULT TRUE,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Create employees table
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
  department_id UUID REFERENCES public.departments(id),
  designation_id UUID REFERENCES public.designations(id),
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

-- Create company settings (FIXED - no syntax errors)
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

-- Create payroll records
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

-- Create time records
CREATE TABLE IF NOT EXISTS public.time_records (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  employee_id UUID NOT NULL REFERENCES public.employees(id) ON DELETE CASCADE,
  record_date DATE NOT NULL,
  clock_in TIMESTAMP WITH TIME ZONE,
  clock_out TIMESTAMP WITH TIME ZONE,
  break_start TIMESTAMP WITH TIME ZONE,
  break_end TIMESTAMP WITH TIME ZONE,
  total_hours DECIMAL(4,2) DEFAULT 0,
  overtime_hours DECIMAL(4,2) DEFAULT 0,
  status TEXT CHECK (status IN ('present', 'absent', 'late', 'early_departure')) DEFAULT 'present',
  notes TEXT,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  UNIQUE(employee_id, record_date)
);

-- Create leave requests
CREATE TABLE IF NOT EXISTS public.leave_requests (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  employee_id UUID NOT NULL REFERENCES public.employees(id) ON DELETE CASCADE,
  leave_type TEXT NOT NULL CHECK (leave_type IN ('annual', 'sick', 'maternity', 'paternity', 'compassionate', 'emergency', 'study', 'unpaid')),
  start_date DATE NOT NULL,
  end_date DATE NOT NULL,
  days_requested INTEGER NOT NULL,
  reason TEXT NOT NULL,
  status TEXT CHECK (status IN ('pending', 'approved', 'rejected', 'cancelled')) DEFAULT 'pending',
  approved_by UUID REFERENCES public.users(id),
  approved_at TIMESTAMP WITH TIME ZONE,
  rejection_reason TEXT,
  emergency_contact TEXT,
  medical_certificate_required BOOLEAN DEFAULT FALSE,
  medical_certificate_submitted BOOLEAN DEFAULT FALSE,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Create leave balances
CREATE TABLE IF NOT EXISTS public.leave_balances (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  employee_id UUID NOT NULL REFERENCES public.employees(id) ON DELETE CASCADE,
  leave_type TEXT NOT NULL CHECK (leave_type IN ('annual', 'sick', 'maternity', 'paternity', 'compassionate', 'emergency', 'study')),
  year INTEGER NOT NULL,
  allocated_days DECIMAL(4,1) NOT NULL DEFAULT 0,
  used_days DECIMAL(4,1) DEFAULT 0,
  carried_forward_days DECIMAL(4,1) DEFAULT 0,
  total_available_days DECIMAL(4,1) GENERATED ALWAYS AS (allocated_days + carried_forward_days - used_days) STORED,
  last_updated TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  UNIQUE(employee_id, leave_type, year)
);

-- Create public holidays
CREATE TABLE IF NOT EXISTS public.public_holidays (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name TEXT NOT NULL,
  date DATE NOT NULL,
  is_recurring BOOLEAN DEFAULT TRUE,
  year INTEGER,
  description TEXT,
  is_active BOOLEAN DEFAULT TRUE,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  UNIQUE(name, date)
);

-- Create audit log
CREATE TABLE IF NOT EXISTS public.audit_log (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  table_name TEXT NOT NULL,
  record_id UUID NOT NULL,
  action TEXT NOT NULL,
  old_values JSONB,
  new_values JSONB,
  changed_by UUID REFERENCES public.users(id),
  changed_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Create notifications
CREATE TABLE IF NOT EXISTS public.notifications (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  recipient_id UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
  title TEXT NOT NULL,
  message TEXT NOT NULL,
  type TEXT CHECK (type IN ('info', 'warning', 'success', 'error')) DEFAULT 'info',
  is_read BOOLEAN DEFAULT FALSE,
  related_table TEXT,
  related_id UUID,
  expires_at TIMESTAMP WITH TIME ZONE,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- ==========================================
-- FUNCTIONS AND TRIGGERS
-- ==========================================

-- Function to update updated_at column
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ language 'plpgsql';

-- Function to handle new user creation
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER AS $$
BEGIN
  INSERT INTO public.users (id, email, role, created_at, updated_at)
  VALUES (new.id, new.email, 'employee', now(), now());
  RETURN new;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to calculate payroll
CREATE OR REPLACE FUNCTION calculate_payroll_amounts()
RETURNS TRIGGER AS $$
DECLARE
    emp_record RECORD;
    settings_record RECORD;
    tax_amount DECIMAL(15,2) := 0;
BEGIN
    -- Get employee record
    SELECT * INTO emp_record FROM employees WHERE id = NEW.employee_id;
    
    -- Get company settings
    SELECT * INTO settings_record FROM company_settings LIMIT 1;
    
    -- Calculate overtime amount
    NEW.overtime_amount := NEW.overtime_hours * NEW.overtime_rate;
    
    -- Calculate gross pay
    NEW.gross_pay := NEW.basic_salary + NEW.overtime_amount + NEW.bonus + NEW.allowances + NEW.commission;
    
    -- Calculate PAYE tax (Zambian 2025 rates)
    IF NEW.basic_salary > 0 THEN
        IF NEW.basic_salary <= 5100 THEN
            tax_amount := 0;
        ELSIF NEW.basic_salary <= 7100 THEN
            tax_amount := (NEW.basic_salary - 5100) * 0.20;
        ELSIF NEW.basic_salary <= 9200 THEN
            tax_amount := 2000 * 0.20 + (NEW.basic_salary - 7100) * 0.30;
        ELSE
            tax_amount := 2000 * 0.20 + 2100 * 0.30 + (NEW.basic_salary - 9200) * 0.37;
        END IF;
    END IF;
    
    NEW.paye_tax := tax_amount;
    
    -- Calculate NAPSA (5% capped)
    NEW.napsa_contribution := LEAST(NEW.basic_salary * 0.05, 1149.60);
    
    -- Calculate NHIS (1% of basic salary)
    NEW.nhis_contribution := NEW.basic_salary * 0.01;
    
    -- Calculate NHIMA (1% of basic salary)
    NEW.nhima_contribution := NEW.basic_salary * 0.01;
    
    -- Calculate total deductions
    NEW.total_deductions := NEW.paye_tax + NEW.napsa_contribution + NEW.nhis_contribution + NEW.nhima_contribution + NEW.other_deductions;
    
    -- Calculate net pay
    NEW.net_pay := NEW.gross_pay - NEW.total_deductions;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Create triggers
DROP TRIGGER IF EXISTS update_users_updated_at ON public.users;
DROP TRIGGER IF EXISTS update_employees_updated_at ON public.employees;
DROP TRIGGER IF EXISTS update_company_settings_updated_at ON public.company_settings;
DROP TRIGGER IF EXISTS calculate_payroll_before_insert ON public.payroll_records;
DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;

CREATE TRIGGER update_users_updated_at BEFORE UPDATE ON public.users FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_employees_updated_at BEFORE UPDATE ON public.employees FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_company_settings_updated_at BEFORE UPDATE ON public.company_settings FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER calculate_payroll_before_insert BEFORE INSERT OR UPDATE ON public.payroll_records FOR EACH ROW EXECUTE FUNCTION calculate_payroll_amounts();
CREATE TRIGGER on_auth_user_created AFTER INSERT ON auth.users FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();

-- ==========================================
-- ROW LEVEL SECURITY
-- ==========================================

-- Enable RLS
ALTER TABLE public.users ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.employees ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.company_settings ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.departments ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.designations ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.payroll_records ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.time_records ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.leave_requests ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.leave_balances ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.public_holidays ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.audit_log ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.notifications ENABLE ROW LEVEL SECURITY;

-- Drop existing policies
DROP POLICY IF EXISTS "Users can view their own profile" ON public.users;
DROP POLICY IF EXISTS "Users can update their own profile" ON public.users;
DROP POLICY IF EXISTS "Employees can view their own profile" ON public.employees;
DROP POLICY IF EXISTS "Employees can update their own profile" ON public.employees;
DROP POLICY IF EXISTS "HR can view all employees" ON public.employees;
DROP POLICY IF EXISTS "HR can manage employees" ON public.employees;
DROP POLICY IF EXISTS "Company settings view policy" ON public.company_settings;
DROP POLICY IF EXISTS "Everyone can view active departments" ON public.departments;
DROP POLICY IF EXISTS "HR can manage departments" ON public.departments;
DROP POLICY IF EXISTS "Everyone can view active designations" ON public.designations;
DROP POLICY IF EXISTS "HR can manage designations" ON public.designations;
DROP POLICY IF EXISTS "Employees can view their own payroll" ON public.payroll_records;
DROP POLICY IF EXISTS "HR can manage all payroll" ON public.payroll_records;

-- Create policies
CREATE POLICY "Users can view their own profile" ON public.users FOR SELECT USING (auth.uid() = id);
CREATE POLICY "Users can update their own profile" ON public.users FOR UPDATE USING (auth.uid() = id);
CREATE POLICY "HR can view all users" ON public.users FOR SELECT USING (EXISTS (SELECT 1 FROM public.users WHERE id = auth.uid() AND role IN ('hr', 'admin')));

CREATE POLICY "Employees can view their own profile" ON public.employees FOR SELECT USING (auth.uid() = user_id);
CREATE POLICY "Employees can update their own profile" ON public.employees FOR UPDATE USING (auth.uid() = user_id);
CREATE POLICY "HR can manage employees" ON public.employees FOR ALL USING (EXISTS (SELECT 1 FROM public.users WHERE id = auth.uid() AND role IN ('hr', 'admin')));

CREATE POLICY "Company settings view policy" ON public.company_settings FOR SELECT USING (true);
CREATE POLICY "Admins can modify company settings" ON public.company_settings FOR ALL USING (EXISTS (SELECT 1 FROM public.users WHERE id = auth.uid() AND role = 'admin'));

CREATE POLICY "Everyone can view active departments" ON public.departments FOR SELECT USING (is_active = true);
CREATE POLICY "HR can manage departments" ON public.departments FOR ALL USING (EXISTS (SELECT 1 FROM public.users WHERE id = auth.uid() AND role IN ('hr', 'admin')));

CREATE POLICY "Everyone can view active designations" ON public.designations FOR SELECT USING (is_active = true);
CREATE POLICY "HR can manage designations" ON public.designations FOR ALL USING (EXISTS (SELECT 1 FROM public.users WHERE id = auth.uid() AND role IN ('hr', 'admin')));

CREATE POLICY "Employees can view their own payroll" ON public.payroll_records FOR SELECT USING (EXISTS (SELECT 1 FROM public.employees WHERE id = employee_id AND user_id = auth.uid()));
CREATE POLICY "HR can manage all payroll" ON public.payroll_records FOR ALL USING (EXISTS (SELECT 1 FROM public.users WHERE id = auth.uid() AND role IN ('hr', 'admin')));

-- ==========================================
-- INDEXES
-- ==========================================

CREATE INDEX IF NOT EXISTS idx_employees_user_id ON public.employees(user_id);
CREATE INDEX IF NOT EXISTS idx_employees_department_id ON public.employees(department_id);
CREATE INDEX IF NOT EXISTS idx_payroll_records_employee_id ON public.payroll_records(employee_id);
CREATE INDEX IF NOT EXISTS idx_time_records_employee_id ON public.time_records(employee_id);
CREATE INDEX IF NOT EXISTS idx_leave_requests_employee_id ON public.leave_requests(employee_id);
CREATE INDEX IF NOT EXISTS idx_leave_balances_employee_id ON public.leave_balances(employee_id);
CREATE INDEX IF NOT EXISTS idx_users_email ON public.users(email);
CREATE INDEX IF NOT EXISTS idx_employees_employee_number ON public.employees(employee_number);

-- ==========================================
-- DEFAULT DATA
-- ==========================================

-- Insert company settings with Zambian tax rates (only if not exists)
DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM public.company_settings LIMIT 1) THEN
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
        );
    END IF;
END $$;

-- Insert default departments (only if not exists)
INSERT INTO public.departments (name, description) 
SELECT 'Human Resources', 'Manages employee relations, recruitment, and development'
WHERE NOT EXISTS (SELECT 1 FROM public.departments WHERE name = 'Human Resources');

INSERT INTO public.departments (name, description) 
SELECT 'Finance', 'Handles accounting, financial planning, and payroll'
WHERE NOT EXISTS (SELECT 1 FROM public.departments WHERE name = 'Finance');

INSERT INTO public.departments (name, description) 
SELECT 'Information Technology', 'Manages technology infrastructure and software development'
WHERE NOT EXISTS (SELECT 1 FROM public.departments WHERE name = 'Information Technology');

INSERT INTO public.departments (name, description) 
SELECT 'Operations', 'Handles daily business operations and processes'
WHERE NOT EXISTS (SELECT 1 FROM public.departments WHERE name = 'Operations');

INSERT INTO public.departments (name, description) 
SELECT 'Marketing', 'Manages brand, advertising, and customer acquisition'
WHERE NOT EXISTS (SELECT 1 FROM public.departments WHERE name = 'Marketing');

INSERT INTO public.departments (name, description) 
SELECT 'Sales', 'Manages sales processes and customer relationships'
WHERE NOT EXISTS (SELECT 1 FROM public.departments WHERE name = 'Sales');

INSERT INTO public.departments (name, description) 
SELECT 'Administration', 'Handles office administration and general support services'
WHERE NOT EXISTS (SELECT 1 FROM public.departments WHERE name = 'Administration');

-- Insert default designations (only if not exists)
INSERT INTO public.designations (name, description) 
SELECT 'Department Manager', 'Manages departmental operations and staff'
WHERE NOT EXISTS (SELECT 1 FROM public.designations WHERE name = 'Department Manager');

INSERT INTO public.designations (name, description) 
SELECT 'Executive', 'Senior management position'
WHERE NOT EXISTS (SELECT 1 FROM public.designations WHERE name = 'Executive');

INSERT INTO public.designations (name, description) 
SELECT 'Team Lead', 'Leads specific teams or projects'
WHERE NOT EXISTS (SELECT 1 FROM public.designations WHERE name = 'Team Lead');

INSERT INTO public.designations (name, description) 
SELECT 'Specialist', 'Subject matter expert'
WHERE NOT EXISTS (SELECT 1 FROM public.designations WHERE name = 'Specialist');

INSERT INTO public.designations (name, description) 
SELECT 'Staff Member', 'General staff position'
WHERE NOT EXISTS (SELECT 1 FROM public.designations WHERE name = 'Staff Member');

INSERT INTO public.designations (name, description) 
SELECT 'Assistant', 'Support role'
WHERE NOT EXISTS (SELECT 1 FROM public.designations WHERE name = 'Assistant');

INSERT INTO public.designations (name, description) 
SELECT 'Intern', 'Trainee position'
WHERE NOT EXISTS (SELECT 1 FROM public.designations WHERE name = 'Intern');

-- Insert Zambian public holidays for 2025 (only if not exists)
INSERT INTO public.public_holidays (name, date, year, description) 
SELECT 'New Year''s Day', '2025-01-01', 2025, 'Celebration of the New Year'
WHERE NOT EXISTS (SELECT 1 FROM public.public_holidays WHERE name = 'New Year''s Day' AND date = '2025-01-01');

INSERT INTO public.public_holidays (name, date, year, description) 
SELECT 'Women''s Day', '2025-03-08', 2025, 'International Women''s Day'
WHERE NOT EXISTS (SELECT 1 FROM public.public_holidays WHERE name = 'Women''s Day' AND date = '2025-03-08');

INSERT INTO public.public_holidays (name, date, year, description) 
SELECT 'Good Friday', '2025-04-18', 2025, 'Christian holiday commemorating Jesus'' crucifixion'
WHERE NOT EXISTS (SELECT 1 FROM public.public_holidays WHERE name = 'Good Friday' AND date = '2025-04-18');

INSERT INTO public.public_holidays (name, date, year, description) 
SELECT 'Easter Monday', '2025-04-21', 2025, 'Christian holiday following Easter Sunday'
WHERE NOT EXISTS (SELECT 1 FROM public.public_holidays WHERE name = 'Easter Monday' AND date = '2025-04-21');

INSERT INTO public.public_holidays (name, date, year, description) 
SELECT 'Labour Day', '2025-05-01', 2025, 'International Workers'' Day'
WHERE NOT EXISTS (SELECT 1 FROM public.public_holidays WHERE name = 'Labour Day' AND date = '2025-05-01');

INSERT INTO public.public_holidays (name, date, year, description) 
SELECT 'African Freedom Day', '2025-05-25', 2025, 'African Union Day'
WHERE NOT EXISTS (SELECT 1 FROM public.public_holidays WHERE name = 'African Freedom Day' AND date = '2025-05-25');

INSERT INTO public.public_holidays (name, date, year, description) 
SELECT 'Independence Day', '2025-10-24', 2025, 'Zambia Independence Day'
WHERE NOT EXISTS (SELECT 1 FROM public.public_holidays WHERE name = 'Independence Day' AND date = '2025-10-24');

INSERT INTO public.public_holidays (name, date, year, description) 
SELECT 'Christmas Day', '2025-12-25', 2025, 'Christmas Day'
WHERE NOT EXISTS (SELECT 1 FROM public.public_holidays WHERE name = 'Christmas Day' AND date = '2025-12-25');

INSERT INTO public.public_holidays (name, date, year, description) 
SELECT 'Boxing Day', '2025-12-26', 2025, 'Day after Christmas'
WHERE NOT EXISTS (SELECT 1 FROM public.public_holidays WHERE name = 'Boxing Day' AND date = '2025-12-26');

-- ==========================================
-- VERIFICATION
-- ==========================================

-- Check tables created
SELECT 'Database setup complete!' as status, now() as completed_at;

-- Verify tables exist
SELECT table_name FROM information_schema.tables 
WHERE table_schema = 'public' 
AND table_type = 'BASE TABLE'
ORDER BY table_name;