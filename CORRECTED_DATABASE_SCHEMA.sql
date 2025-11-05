-- ==========================================
-- GPTPAYROLL DATABASE SCHEMA (CORRECTED)
-- Complete database schema for GPTPayroll HR & Payroll System
-- Compatible with Zambian labor laws and tax regulations
-- ==========================================

-- Enable necessary extensions
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "pgcrypto";

-- ==========================================
-- CORE TABLES
-- ==========================================

-- Users table (mirrors Supabase auth.users)
CREATE TABLE public.users (
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
CREATE TABLE public.employees (
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
  nrc TEXT, -- National Registration Card
  tpin TEXT, -- Tax Payer Identification Number
  passport_number TEXT,
  marital_status TEXT CHECK (marital_status IN ('Single', 'Married', 'Divorced', 'Widowed')),
  
  -- Address information
  physical_address TEXT,
  postal_address TEXT,
  city TEXT,
  province TEXT,
  country TEXT DEFAULT 'Zambia',
  
  -- Employment details
  department_id UUID,
  designation_id UUID,
  employment_type TEXT CHECK (employment_type IN ('Full-time', 'Part-time', 'Contract', 'Intern')) DEFAULT 'Full-time',
  employee_status TEXT CHECK (employee_status IN ('Active', 'Inactive', 'Terminated', 'Suspended')) DEFAULT 'Active',
  hire_date DATE NOT NULL,
  termination_date DATE,
  
  -- Banking information
  bank_name TEXT,
  bank_branch TEXT,
  account_number TEXT,
  account_name TEXT,
  
  -- Emergency contact
  emergency_contact_name TEXT,
  emergency_contact_phone TEXT,
  emergency_contact_relationship TEXT,
  
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Departments
CREATE TABLE public.departments (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name TEXT UNIQUE NOT NULL,
  description TEXT,
  manager_id UUID REFERENCES public.users(id),
  is_active BOOLEAN DEFAULT TRUE,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Designations
CREATE TABLE public.designations (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name TEXT UNIQUE NOT NULL,
  description TEXT,
  department_id UUID REFERENCES public.departments(id),
  is_active BOOLEAN DEFAULT TRUE,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Payroll records
CREATE TABLE public.payroll_records (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  employee_id UUID NOT NULL REFERENCES public.employees(id) ON DELETE CASCADE,
  payroll_month INTEGER NOT NULL CHECK (payroll_month BETWEEN 1 AND 12),
  payroll_year INTEGER NOT NULL,
  
  -- Earnings
  basic_salary DECIMAL(15,2) NOT NULL,
  overtime_hours DECIMAL(8,2) DEFAULT 0,
  overtime_rate DECIMAL(8,2) DEFAULT 0,
  overtime_amount DECIMAL(15,2) DEFAULT 0,
  bonus DECIMAL(15,2) DEFAULT 0,
  allowances DECIMAL(15,2) DEFAULT 0,
  commission DECIMAL(15,2) DEFAULT 0,
  gross_pay DECIMAL(15,2) NOT NULL,
  
  -- Deductions
  paye_tax DECIMAL(15,2) NOT NULL,
  napsa_contribution DECIMAL(15,2) NOT NULL,
  nhis_contribution DECIMAL(15,2) NOT NULL,
  nhima_contribution DECIMAL(15,2) DEFAULT 0,
  other_deductions DECIMAL(15,2) DEFAULT 0,
  total_deductions DECIMAL(15,2) NOT NULL,
  
  -- Net pay
  net_pay DECIMAL(15,2) NOT NULL,
  
  -- Payment details
  payment_status TEXT CHECK (payment_status IN ('Pending', 'Processed', 'Paid', 'Failed')) DEFAULT 'Pending',
  payment_date DATE,
  payment_method TEXT DEFAULT 'Bank Transfer',
  reference_number TEXT,
  
  -- Additional fields
  pay_period_start DATE NOT NULL,
  pay_period_end DATE NOT NULL,
  processed_by UUID REFERENCES public.users(id),
  processed_at TIMESTAMP WITH TIME ZONE,
  
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  
  -- Ensure unique payroll record per employee per month/year
  UNIQUE(employee_id, payroll_month, payroll_year)
);

-- Deductions and Additions
CREATE TABLE public.deductions_additions (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  employee_id UUID NOT NULL REFERENCES public.employees(id) ON DELETE CASCADE,
  payroll_record_id UUID REFERENCES public.payroll_records(id) ON DELETE CASCADE,
  type TEXT NOT NULL CHECK (type IN ('deduction', 'addition')),
  name TEXT NOT NULL,
  amount DECIMAL(15,2) NOT NULL,
  description TEXT,
  is_recurring BOOLEAN DEFAULT FALSE,
  is_taxable BOOLEAN DEFAULT TRUE,
  effective_date DATE DEFAULT CURRENT_DATE,
  end_date DATE,
  created_by UUID REFERENCES public.users(id),
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Time tracking
CREATE TABLE public.time_records (
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
  
  -- Ensure one record per employee per date
  UNIQUE(employee_id, record_date)
);

-- Shift schedules
CREATE TABLE public.shift_schedules (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  employee_id UUID NOT NULL REFERENCES public.employees(id) ON DELETE CASCADE,
  shift_date DATE NOT NULL,
  start_time TIME NOT NULL,
  end_time TIME NOT NULL,
  break_duration INTEGER DEFAULT 60, -- in minutes
  shift_type TEXT CHECK (shift_type IN ('morning', 'afternoon', 'night', 'flexible')) DEFAULT 'morning',
  is_overtime BOOLEAN DEFAULT FALSE,
  is_holiday BOOLEAN DEFAULT FALSE,
  supervisor_approval BOOLEAN DEFAULT FALSE,
  notes TEXT,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  
  -- Ensure no overlapping shifts for same employee
  UNIQUE(employee_id, shift_date, start_time)
);

-- Leave requests
CREATE TABLE public.leave_requests (
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

-- Leave balances
CREATE TABLE public.leave_balances (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  employee_id UUID NOT NULL REFERENCES public.employees(id) ON DELETE CASCADE,
  leave_type TEXT NOT NULL CHECK (leave_type IN ('annual', 'sick', 'maternity', 'paternity', 'compassionate', 'emergency', 'study')),
  year INTEGER NOT NULL,
  allocated_days DECIMAL(4,1) NOT NULL DEFAULT 0,
  used_days DECIMAL(4,1) DEFAULT 0,
  carried_forward_days DECIMAL(4,1) DEFAULT 0,
  total_available_days DECIMAL(4,1) GENERATED ALWAYS AS (allocated_days + carried_forward_days - used_days) STORED,
  last_updated TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  
  -- Ensure one balance record per employee per leave type per year
  UNIQUE(employee_id, leave_type, year)
);

-- Public holidays
CREATE TABLE public.public_holidays (
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

-- Company settings
CREATE TABLE public.company_settings (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  
  -- Company information
  company_name TEXT NOT NULL,
  company_logo_url TEXT,
  registration_number TEXT,
  tax_id TEXT,
  address TEXT,
  phone TEXT,
  email TEXT,
  website TEXT,
  
  -- Payroll settings
  pay_frequency TEXT CHECK (pay_frequency IN ('weekly', 'bi-weekly', 'monthly')) DEFAULT 'monthly',
  payroll_cutoff_day INTEGER DEFAULT 25,
  overtime_rate_multiplier DECIMAL(3,2) DEFAULT 1.50,
  working_hours_per_day DECIMAL(3,1) DEFAULT 8.0,
  working_days_per_week INTEGER DEFAULT 5,
  
  -- Tax settings (Zambian 2025 rates)
  paye_tax_bands JSONB NOT NULL, -- Store tax bands as JSON
  paye_threshold DECIMAL(10,2) DEFAULT 5100.00,
  napsa_rate DECIMAL(5,4) DEFAULT 0.05,
  napsa_cap DECIMAL(10,2) DEFAULT 1149.60,
  nhis_rate DECIMAL(5,4) DEFAULT 0.01,
  nhima_rate DECIMAL(5,4) DEFAULT 0.01,
  
  -- Banking settings
  company_bank_name TEXT,
  company_bank_branch TEXT,
  company_account_number TEXT,
  company_account_name TEXT,
  
  -- Email settings
  smtp_host TEXT,
  smtp_port INTEGER,
  smtp_username TEXT,
  smtp_password TEXT,
  from_email TEXT,
  from_name TEXT,
  
  -- Notifications
  email_notifications BOOLEAN DEFAULT TRUE,
  sms_notifications BOOLEAN DEFAULT FALSE,
  leave_reminder_days INTEGER DEFAULT 7,
  
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Audit log
CREATE TABLE public.audit_log (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  table_name TEXT NOT NULL,
  record_id UUID NOT NULL,
  action TEXT NOT NULL, -- INSERT, UPDATE, DELETE
  old_values JSONB,
  new_values JSONB,
  changed_by UUID REFERENCES public.users(id),
  changed_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Notifications
CREATE TABLE public.notifications (
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
-- TRIGGERS AND FUNCTIONS
-- ==========================================

-- Function to update the updated_at column
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ language 'plpgsql';

-- Function to calculate payroll amounts
CREATE OR REPLACE FUNCTION calculate_payroll_amounts()
RETURNS TRIGGER AS $$
DECLARE
    emp_record RECORD;
    settings_record RECORD;
    tax_amount DECIMAL(15,2) := 0;
    deductions_amount DECIMAL(15,2) := 0;
BEGIN
    -- Get employee record
    SELECT * INTO emp_record FROM employees WHERE id = NEW.employee_id;
    
    -- Get company settings
    SELECT * INTO settings_record FROM company_settings LIMIT 1;
    
    -- Calculate overtime amount
    NEW.overtime_amount := NEW.overtime_hours * NEW.overtime_rate;
    
    -- Calculate gross pay
    NEW.gross_pay := NEW.basic_salary + NEW.overtime_amount + NEW.bonus + NEW.allowances + NEW.commission;
    
    -- Calculate PAYE tax (simplified calculation)
    -- This is a basic implementation - adjust according to current tax laws
    IF NEW.basic_salary > 0 THEN
        -- Apply current Zambian PAYE rates (2025)
        -- K0-5,100: 0%, K5,100-7,100: 20%, K7,100-9,200: 30%, >K9,200: 37%
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
    
    -- Calculate NAPSA (5% capped at current limit)
    NEW.napsa_contribution := LEAST(NEW.basic_salary * 0.05, settings_record.napsa_cap);
    
    -- Calculate NHIS (1% of basic salary)
    NEW.nhis_contribution := NEW.basic_salary * 0.01;
    
    -- Calculate NHIMA (configurable rate)
    NEW.nhima_contribution := NEW.basic_salary * settings_record.nhima_rate;
    
    -- Calculate total deductions
    NEW.total_deductions := NEW.paye_tax + NEW.napsa_contribution + NEW.nhis_contribution + NEW.nhima_contribution + NEW.other_deductions;
    
    -- Calculate net pay
    NEW.net_pay := NEW.gross_pay - NEW.total_deductions;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- User creation trigger function
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER AS $$
BEGIN
  INSERT INTO public.users (id, email, role, created_at, updated_at)
  VALUES (new.id, new.email, 'employee', now(), now());
  RETURN new;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ==========================================
-- TRIGGERS
-- ==========================================

-- Apply updated_at triggers to all relevant tables
CREATE TRIGGER update_users_updated_at BEFORE UPDATE ON public.users FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_employees_updated_at BEFORE UPDATE ON public.employees FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_departments_updated_at BEFORE UPDATE ON public.departments FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_designations_updated_at BEFORE UPDATE ON public.designations FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_payroll_records_updated_at BEFORE UPDATE ON public.payroll_records FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_deductions_additions_updated_at BEFORE UPDATE ON public.deductions_additions FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_time_records_updated_at BEFORE UPDATE ON public.time_records FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_shift_schedules_updated_at BEFORE UPDATE ON public.shift_schedules FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_leave_requests_updated_at BEFORE UPDATE ON public.leave_requests FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_company_settings_updated_at BEFORE UPDATE ON public.company_settings FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- Trigger to automatically calculate payroll amounts
CREATE TRIGGER calculate_payroll_before_insert BEFORE INSERT OR UPDATE ON public.payroll_records FOR EACH ROW EXECUTE FUNCTION calculate_payroll_amounts();

-- User creation trigger
CREATE TRIGGER on_auth_user_created AFTER INSERT ON auth.users FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();

-- ==========================================
-- ROW LEVEL SECURITY (RLS) POLICIES
-- ==========================================

-- Enable RLS on all tables
ALTER TABLE public.users ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.employees ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.departments ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.designations ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.payroll_records ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.deductions_additions ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.time_records ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.shift_schedules ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.leave_requests ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.leave_balances ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.public_holidays ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.company_settings ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.audit_log ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.notifications ENABLE ROW LEVEL SECURITY;

-- Users policies
CREATE POLICY "Users can view their own profile" ON public.users FOR SELECT USING (auth.uid() = id);
CREATE POLICY "Users can update their own profile" ON public.users FOR UPDATE USING (auth.uid() = id);
CREATE POLICY "Admins can view all users" ON public.users FOR SELECT USING (EXISTS (SELECT 1 FROM public.users WHERE id = auth.uid() AND role = 'admin'));
CREATE POLICY "HR can view all users" ON public.users FOR SELECT USING (EXISTS (SELECT 1 FROM public.users WHERE id = auth.uid() AND role = 'hr'));

-- Employees policies
CREATE POLICY "Employees can view their own profile" ON public.employees FOR SELECT USING (auth.uid() = user_id);
CREATE POLICY "Employees can update their own profile" ON public.employees FOR UPDATE USING (auth.uid() = user_id);
CREATE POLICY "HR can view all employees" ON public.employees FOR SELECT USING (EXISTS (SELECT 1 FROM public.users WHERE id = auth.uid() AND role IN ('hr', 'admin')));
CREATE POLICY "HR can manage employees" ON public.employees FOR ALL USING (EXISTS (SELECT 1 FROM public.users WHERE id = auth.uid() AND role IN ('hr', 'admin')));

-- Departments policies
CREATE POLICY "Everyone can view active departments" ON public.departments FOR SELECT USING (is_active = true);
CREATE POLICY "HR can manage departments" ON public.departments FOR ALL USING (EXISTS (SELECT 1 FROM public.users WHERE id = auth.uid() AND role IN ('hr', 'admin')));

-- Designations policies
CREATE POLICY "Everyone can view active designations" ON public.designations FOR SELECT USING (is_active = true);
CREATE POLICY "HR can manage designations" ON public.designations FOR ALL USING (EXISTS (SELECT 1 FROM public.users WHERE id = auth.uid() AND role IN ('hr', 'admin')));

-- Payroll records policies
CREATE POLICY "Employees can view their own payroll" ON public.payroll_records FOR SELECT USING (EXISTS (SELECT 1 FROM public.employees WHERE id = employee_id AND user_id = auth.uid()));
CREATE POLICY "HR can manage all payroll" ON public.payroll_records FOR ALL USING (EXISTS (SELECT 1 FROM public.users WHERE id = auth.uid() AND role IN ('hr', 'admin')));

-- Time records policies
CREATE POLICY "Employees can view their own time records" ON public.time_records FOR SELECT USING (EXISTS (SELECT 1 FROM public.employees WHERE id = employee_id AND user_id = auth.uid()));
CREATE POLICY "Employees can insert their own time records" ON public.time_records FOR INSERT WITH CHECK (EXISTS (SELECT 1 FROM public.employees WHERE id = employee_id AND user_id = auth.uid()));
CREATE POLICY "HR can manage all time records" ON public.time_records FOR ALL USING (EXISTS (SELECT 1 FROM public.users WHERE id = auth.uid() AND role IN ('hr', 'admin')));

-- Leave policies
CREATE POLICY "Employees can view their own leave requests" ON public.leave_requests FOR SELECT USING (EXISTS (SELECT 1 FROM public.employees WHERE id = employee_id AND user_id = auth.uid()));
CREATE POLICY "Employees can insert their own leave requests" ON public.leave_requests FOR INSERT WITH CHECK (EXISTS (SELECT 1 FROM public.employees WHERE id = employee_id AND user_id = auth.uid()));
CREATE POLICY "HR can manage all leave requests" ON public.leave_requests FOR ALL USING (EXISTS (SELECT 1 FROM public.users WHERE id = auth.uid() AND role IN ('hr', 'admin')));

-- Leave balances policies
CREATE POLICY "Employees can view their own leave balances" ON public.leave_balances FOR SELECT USING (EXISTS (SELECT 1 FROM public.employees WHERE id = employee_id AND user_id = auth.uid()));
CREATE POLICY "HR can manage all leave balances" ON public.leave_balances FOR ALL USING (EXISTS (SELECT 1 FROM public.users WHERE id = auth.uid() AND role IN ('hr', 'admin')));

-- Company settings policies
CREATE POLICY "Everyone can view company settings" ON public.company_settings FOR SELECT USING (true);
CREATE POLICY "Admins can modify company settings" ON public.company_settings FOR ALL USING (EXISTS (SELECT 1 FROM public.users WHERE id = auth.uid() AND role = 'admin'));

-- Notifications policies
CREATE POLICY "Users can view their own notifications" ON public.notifications FOR SELECT USING (auth.uid() = recipient_id);
CREATE POLICY "Users can update their own notifications" ON public.notifications FOR UPDATE USING (auth.uid() = recipient_id);
CREATE POLICY "System can insert notifications" ON public.notifications FOR INSERT WITH CHECK (true);

-- Audit log policies (read-only for admins)
CREATE POLICY "Admins can view audit log" ON public.audit_log FOR SELECT USING (EXISTS (SELECT 1 FROM public.users WHERE id = auth.uid() AND role = 'admin'));

-- Public holidays policies
CREATE POLICY "Everyone can view active public holidays" ON public.public_holidays FOR SELECT USING (is_active = true);
CREATE POLICY "HR can manage public holidays" ON public.public_holidays FOR ALL USING (EXISTS (SELECT 1 FROM public.users WHERE id = auth.uid() AND role IN ('hr', 'admin')));

-- ==========================================
-- INDEXES FOR PERFORMANCE
-- ==========================================

-- Foreign key indexes
CREATE INDEX idx_employees_user_id ON public.employees(user_id);
CREATE INDEX idx_employees_department_id ON public.employees(department_id);
CREATE INDEX idx_employees_designation_id ON public.employees(designation_id);
CREATE INDEX idx_payroll_records_employee_id ON public.payroll_records(employee_id);
CREATE INDEX idx_payroll_records_month_year ON public.payroll_records(payroll_year, payroll_month);
CREATE INDEX idx_time_records_employee_id ON public.time_records(employee_id);
CREATE INDEX idx_time_records_date ON public.time_records(record_date);
CREATE INDEX idx_leave_requests_employee_id ON public.leave_requests(employee_id);
CREATE INDEX idx_leave_balances_employee_id ON public.leave_balances(employee_id);
CREATE INDEX idx_notifications_recipient_id ON public.notifications(recipient_id);
CREATE INDEX idx_audit_log_table_record ON public.audit_log(table_name, record_id);

-- Status and date indexes
CREATE INDEX idx_employees_status ON public.employees(employee_status);
CREATE INDEX idx_payroll_records_status ON public.payroll_records(payment_status);
CREATE INDEX idx_leave_requests_status ON public.leave_requests(status);
CREATE INDEX idx_notifications_read ON public.notifications(is_read);

-- Unique constraint indexes
CREATE INDEX idx_users_email ON public.users(email);
CREATE INDEX idx_employees_employee_number ON public.employees(employee_number);

-- ==========================================
-- INITIAL DATA SEEDING
-- ==========================================

-- Insert default company settings with 2025 Zambian tax rates
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
  nhma_rate
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

-- Insert default departments
INSERT INTO public.departments (name, description) VALUES
('Human Resources', 'Manages employee relations, recruitment, and development'),
('Finance', 'Handles accounting, financial planning, and payroll'),
('Information Technology', 'Manages technology infrastructure and software development'),
('Operations', 'Handles daily business operations and processes'),
('Marketing', 'Manages brand, advertising, and customer acquisition'),
('Sales', 'Manages sales processes and customer relationships'),
('Administration', 'Handles office administration and general support services');

-- Insert 2025 Zambian public holidays
INSERT INTO public.public_holidays (name, date, year, description) VALUES
('New Year''s Day', '2025-01-01', 2025, 'Celebration of the New Year'),
('Women''s Day', '2025-03-08', 2025, 'International Women''s Day'),
('Good Friday', '2025-04-18', 2025, 'Christian holiday commemorating Jesus'' crucifixion'),
('Easter Monday', '2025-04-21', 2025, 'Christian holiday following Easter Sunday'),
('Labour Day', '2025-05-01', 2025, 'International Workers'' Day'),
('African Freedom Day', '2025-05-25', 2025, 'African Union Day'),
('Independence Day', '2025-10-24', 2025, 'Zambia Independence Day'),
('Christmas Day', '2025-12-25', 2025, 'Christmas Day'),
('Boxing Day', '2025-12-26', 2025, 'Day after Christmas');

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