-- ==========================================
-- GPTPayroll Complete Database Schema
-- Zambian Payroll & HR Management System
-- ==========================================

-- Enable required extensions
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "pg_trgm";

-- ==========================================
-- ENUMS AND TYPES
-- ==========================================

CREATE TYPE user_role AS ENUM ('admin', 'hr', 'employee');
CREATE TYPE employment_status AS ENUM ('active', 'inactive', 'terminated', 'on_leave');
CREATE TYPE salary_type AS ENUM ('hourly', 'monthly', 'contract');
CREATE TYPE payroll_status AS ENUM ('draft', 'processed', 'paid', 'cancelled');
CREATE TYPE attendance_status AS ENUM ('present', 'absent', 'leave', 'holiday', 'sick', 'pending', 'approved', 'rejected');
CREATE TYPE leave_type_enum AS ENUM ('annual', 'sick', 'maternity', 'paternity', 'emergency', 'study', 'unpaid');
CREATE TYPE deduction_type AS ENUM ('deduction', 'addition');
CREATE TYPE approval_status AS ENUM ('pending', 'approved', 'rejected');

-- ==========================================
-- CORE TABLES
-- ==========================================

-- Users table (extends Supabase auth.users)
CREATE TABLE users (
  id UUID REFERENCES auth.users(id) PRIMARY KEY,
  email TEXT NOT NULL UNIQUE,
  role user_role NOT NULL DEFAULT 'employee',
  employee_id UUID REFERENCES employees(id),
  first_name TEXT,
  last_name TEXT,
  phone TEXT,
  avatar_url TEXT,
  last_login_at TIMESTAMP WITH TIME ZONE,
  email_verified BOOLEAN DEFAULT FALSE,
  is_active BOOLEAN DEFAULT TRUE,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Employees table (main employee records)
CREATE TABLE employees (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  employee_id TEXT UNIQUE NOT NULL,
  first_name TEXT NOT NULL,
  last_name TEXT NOT NULL,
  middle_name TEXT,
  email TEXT UNIQUE NOT NULL,
  phone TEXT,
  alternate_phone TEXT,
  tpin TEXT NOT NULL, -- Tax Personal Identification Number
  nrc TEXT NOT NULL,  -- National Registration Card
  address TEXT,
  city TEXT,
  province TEXT,
  country TEXT DEFAULT 'Zambia',
  date_of_birth DATE,
  gender TEXT CHECK (gender IN ('male', 'female', 'other')),
  marital_status TEXT CHECK (marital_status IN ('single', 'married', 'divorced', 'widowed')),
  emergency_contact_name TEXT,
  emergency_contact_phone TEXT,
  emergency_contact_relationship TEXT,
  
  -- Employment details
  department TEXT NOT NULL,
  designation TEXT NOT NULL,
  salary_type salary_type NOT NULL,
  basic_salary DECIMAL(12,2) NOT NULL,
  hourly_rate DECIMAL(8,2),
  contract_amount DECIMAL(12,2),
  start_date DATE NOT NULL,
  end_date DATE,
  probation_end_date DATE,
  employment_status employment_status DEFAULT 'active',
  
  -- Banking details for salary payments
  bank_name TEXT,
  bank_branch TEXT,
  account_number TEXT,
  account_holder_name TEXT,
  
  -- Benefits
  medical_aid_provider TEXT,
  medical_aid_number TEXT,
  pension_fund TEXT,
  pension_fund_number TEXT,
  
  -- Additional fields
  profile_photo_url TEXT,
  notes TEXT,
  is_tax_exempt BOOLEAN DEFAULT FALSE,
  
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Departments table
CREATE TABLE departments (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name TEXT NOT NULL UNIQUE,
  code TEXT UNIQUE NOT NULL,
  description TEXT,
  manager_id UUID REFERENCES employees(id),
  budget DECIMAL(15,2),
  is_active BOOLEAN DEFAULT TRUE,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Designations table
CREATE TABLE designations (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name TEXT NOT NULL UNIQUE,
  code TEXT UNIQUE NOT NULL,
  department_id UUID REFERENCES departments(id),
  level TEXT, -- Junior, Mid, Senior, Lead, Manager, etc.
  description TEXT,
  min_salary DECIMAL(12,2),
  max_salary DECIMAL(12,2),
  is_active BOOLEAN DEFAULT TRUE,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- ==========================================
-- PAYROLL TABLES
-- ==========================================

-- Payroll records table
CREATE TABLE payroll_records (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  employee_id UUID REFERENCES employees(id) NOT NULL,
  pay_period TEXT NOT NULL, -- Format: YYYY-MM
  pay_month INTEGER NOT NULL,
  pay_year INTEGER NOT NULL,
  
  -- Earnings
  basic_pay DECIMAL(12,2) NOT NULL,
  allowances DECIMAL(12,2) DEFAULT 0,
  bonuses DECIMAL(12,2) DEFAULT 0,
  overtime_pay DECIMAL(12,2) DEFAULT 0,
  commissions DECIMAL(12,2) DEFAULT 0,
  gratuity DECIMAL(12,2) DEFAULT 0,
  other_earnings DECIMAL(12,2) DEFAULT 0,
  
  -- Deductions
  napsa DECIMAL(12,2) NOT NULL,
  nhis DECIMAL(12,2) NOT NULL,
  tax DECIMAL(12,2) NOT NULL,
  loans DECIMAL(12,2) DEFAULT 0,
  advances DECIMAL(12,2) DEFAULT 0,
  other_deductions DECIMAL(12,2) DEFAULT 0,
  
  -- Calculated totals
  gross_pay DECIMAL(12,2) NOT NULL,
  total_deductions DECIMAL(12,2) NOT NULL,
  net_pay DECIMAL(12,2) NOT NULL,
  
  -- Additional details
  pay_date DATE NOT NULL,
  status payroll_status DEFAULT 'draft',
  processed_by UUID REFERENCES users(id),
  approved_by UUID REFERENCES users(id),
  approved_at TIMESTAMP WITH TIME ZONE,
  
  -- Tax breakdown
  tax_breakdown JSONB DEFAULT '{}',
  napsa_breakdown JSONB DEFAULT '{}',
  
  -- Notes
  notes TEXT,
  
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Custom deductions and additions
CREATE TABLE deductions_additions (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  employee_id UUID REFERENCES employees(id) NOT NULL,
  name TEXT NOT NULL,
  type deduction_type NOT NULL,
  
  -- Amount configuration
  amount DECIMAL(12,2),
  percentage DECIMAL(5,2),
  is_percentage BOOLEAN DEFAULT FALSE,
  
  -- Application timing
  is_before_gross BOOLEAN DEFAULT FALSE,
  is_before_tax BOOLEAN DEFAULT FALSE,
  calculation_basis TEXT CHECK (calculation_basis IN ('gross', 'basic_pay', 'net')) DEFAULT 'gross',
  
  -- Recurrence
  is_recurring BOOLEAN DEFAULT TRUE,
  start_date DATE NOT NULL,
  end_date DATE,
  
  -- Status and approval
  status TEXT CHECK (status IN ('active', 'inactive')) DEFAULT 'active',
  requires_approval BOOLEAN DEFAULT FALSE,
  approved_by UUID REFERENCES users(id),
  approved_at TIMESTAMP WITH TIME ZONE,
  
  -- Additional details
  description TEXT,
  reference_number TEXT,
  
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- ==========================================
-- TIME & ATTENDANCE TABLES
-- ==========================================

-- Time records table
CREATE TABLE time_records (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  employee_id UUID REFERENCES employees(id) NOT NULL,
  date DATE NOT NULL,
  
  -- Time tracking
  clock_in TIME,
  clock_out TIME,
  break_start TIME,
  break_end TIME,
  total_break_time INTERVAL DEFAULT '0 minutes',
  hours_worked DECIMAL(5,2) DEFAULT 0,
  overtime_hours DECIMAL(5,2) DEFAULT 0,
  
  -- Status
  status attendance_status DEFAULT 'present',
  leave_type leave_type_enum,
  
  -- Approval
  approved_by UUID REFERENCES users(id),
  approved_at TIMESTAMP WITH TIME ZONE,
  rejection_reason TEXT,
  
  -- Additional details
  notes TEXT,
  
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  
  -- Ensure one record per employee per date
  UNIQUE(employee_id, date)
);

-- Shift schedules
CREATE TABLE shift_schedules (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  employee_id UUID REFERENCES employees(id) NOT NULL,
  date DATE NOT NULL,
  start_time TIME NOT NULL,
  end_time TIME NOT NULL,
  break_duration INTEGER DEFAULT 60, -- minutes
  is_overtime BOOLEAN DEFAULT FALSE,
  status TEXT CHECK (status IN ('scheduled', 'completed', 'cancelled')) DEFAULT 'scheduled',
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- ==========================================
-- LEAVE MANAGEMENT TABLES
-- ==========================================

-- Leave requests table
CREATE TABLE leave_requests (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  employee_id UUID REFERENCES employees(id) NOT NULL,
  leave_type leave_type_enum NOT NULL,
  start_date DATE NOT NULL,
  end_date DATE NOT NULL,
  days INTEGER NOT NULL,
  
  -- Request details
  reason TEXT NOT NULL,
  urgent BOOLEAN DEFAULT FALSE,
  medical_certificate_required BOOLEAN DEFAULT FALSE,
  medical_certificate_url TEXT,
  
  -- Approval
  status approval_status DEFAULT 'pending',
  approved_by UUID REFERENCES users(id),
  approved_at TIMESTAMP WITH TIME ZONE,
  rejection_reason TEXT,
  
  -- Additional details
  supervisor_comments TEXT,
  hr_comments TEXT,
  
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Leave balances
CREATE TABLE leave_balances (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  employee_id UUID REFERENCES employees(id) NOT NULL,
  leave_type leave_type_enum NOT NULL,
  year INTEGER NOT NULL,
  allocated_days DECIMAL(4,1) NOT NULL,
  used_days DECIMAL(4,1) DEFAULT 0,
  pending_days DECIMAL(4,1) DEFAULT 0,
  available_days DECIMAL(4,1) GENERATED ALWAYS AS (allocated_days - used_days - pending_days) STORED,
  
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  
  UNIQUE(employee_id, leave_type, year)
);

-- Public holidays
CREATE TABLE public_holidays (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name TEXT NOT NULL,
  date DATE NOT NULL,
  description TEXT,
  is_recurring BOOLEAN DEFAULT FALSE,
  month INTEGER,
  day INTEGER,
  is_active BOOLEAN DEFAULT TRUE,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  
  UNIQUE(date)
);

-- ==========================================
-- COMPANY SETTINGS & CONFIGURATION
-- ==========================================

-- Company settings
CREATE TABLE company_settings (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  
  -- Company information
  company_name TEXT NOT NULL,
  registration_number TEXT,
  tax_number TEXT,
  address TEXT,
  city TEXT,
  province TEXT,
  country TEXT DEFAULT 'Zambia',
  phone TEXT,
  email TEXT,
  website TEXT,
  logo_url TEXT,
  
  -- Branding
  primary_color TEXT DEFAULT '#006A4E',
  secondary_color TEXT DEFAULT '#EF7D00',
  accent_color TEXT DEFAULT '#DE2C17',
  
  -- Tax settings
  napsa_rate DECIMAL(4,3) DEFAULT 0.05,
  napsa_maximum DECIMAL(10,2) DEFAULT 1149.60,
  nhis_rate DECIMAL(4,3) DEFAULT 0.01,
  paye_bands JSONB DEFAULT '[]',
  nihma_rate DECIMAL(4,3) DEFAULT 0.01,
  
  -- Working conditions
  working_days_per_month INTEGER DEFAULT 22,
  working_hours_per_day INTEGER DEFAULT 8,
  overtime_rate_multiplier DECIMAL(3,1) DEFAULT 1.5,
  late_arrival_threshold INTEGER DEFAULT 15, -- minutes
  
  -- Leave policies
  annual_leave_days INTEGER DEFAULT 21,
  sick_leave_days INTEGER DEFAULT 10,
  maternity_leave_days INTEGER DEFAULT 84,
  paternity_leave_days INTEGER DEFAULT 3,
  
  -- Payslip template
  payslip_template JSONB DEFAULT '{}',
  payslip_footer TEXT,
  include_qr_code BOOLEAN DEFAULT FALSE,
  
  -- System settings
  currency_symbol TEXT DEFAULT 'ZMW',
  date_format TEXT DEFAULT 'DD/MM/YYYY',
  time_format TEXT DEFAULT '24H',
  timezone TEXT DEFAULT 'Africa/Lusaka',
  
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
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  
  -- Ensure only one settings record
  UNIQUE(id) DEFAULT gen_random_uuid()
);

-- ==========================================
-- AUDIT & LOGGING TABLES
-- ==========================================

-- Audit log
CREATE TABLE audit_log (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  table_name TEXT NOT NULL,
  record_id UUID NOT NULL,
  action TEXT NOT NULL, -- INSERT, UPDATE, DELETE
  old_values JSONB,
  new_values JSONB,
  user_id UUID REFERENCES users(id),
  user_role user_role,
  ip_address INET,
  user_agent TEXT,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- System notifications
CREATE TABLE notifications (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES users(id) NOT NULL,
  title TEXT NOT NULL,
  message TEXT NOT NULL,
  type TEXT CHECK (type IN ('info', 'warning', 'error', 'success')) DEFAULT 'info',
  is_read BOOLEAN DEFAULT FALSE,
  action_url TEXT,
  metadata JSONB DEFAULT '{}',
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  read_at TIMESTAMP WITH TIME ZONE
);

-- ==========================================
-- INDEXES FOR PERFORMANCE
-- ==========================================

-- Users indexes
CREATE INDEX idx_users_email ON users(email);
CREATE INDEX idx_users_role ON users(role);
CREATE INDEX idx_users_employee_id ON users(employee_id);

-- Employees indexes
CREATE INDEX idx_employees_employee_id ON employees(employee_id);
CREATE INDEX idx_employees_email ON employees(email);
CREATE INDEX idx_employees_department ON employees(department);
CREATE INDEX idx_employees_status ON employees(employment_status);
CREATE INDEX idx_employees_tpin ON employees(tpin);
CREATE INDEX idx_employees_nrc ON employees(nrc);

-- Payroll indexes
CREATE INDEX idx_payroll_employee_id ON payroll_records(employee_id);
CREATE INDEX idx_payroll_period ON payroll_records(pay_period);
CREATE INDEX idx_payroll_year_month ON payroll_records(pay_year, pay_month);
CREATE INDEX idx_payroll_status ON payroll_records(status);

-- Time records indexes
CREATE INDEX idx_time_records_employee_id ON time_records(employee_id);
CREATE INDEX idx_time_records_date ON time_records(date);
CREATE INDEX idx_time_records_status ON time_records(status);

-- Leave indexes
CREATE INDEX idx_leave_requests_employee_id ON leave_requests(employee_id);
CREATE INDEX idx_leave_requests_status ON leave_requests(status);
CREATE INDEX idx_leave_requests_dates ON leave_requests(start_date, end_date);

-- ==========================================
-- TRIGGERS FOR AUTO-UPDATING TIMESTAMPS
-- ==========================================

CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ language 'plpgsql';

-- Apply triggers to all tables with updated_at column
CREATE TRIGGER update_users_updated_at BEFORE UPDATE ON users
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_employees_updated_at BEFORE UPDATE ON employees
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_departments_updated_at BEFORE UPDATE ON departments
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_designations_updated_at BEFORE UPDATE ON designations
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_payroll_records_updated_at BEFORE UPDATE ON payroll_records
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_deductions_additions_updated_at BEFORE UPDATE ON deductions_additions
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_time_records_updated_at BEFORE UPDATE ON time_records
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_shift_schedules_updated_at BEFORE UPDATE ON shift_schedules
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_leave_requests_updated_at BEFORE UPDATE ON leave_requests
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_leave_balances_updated_at BEFORE UPDATE ON leave_balances
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_public_holidays_updated_at BEFORE UPDATE ON public_holidays
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_company_settings_updated_at BEFORE UPDATE ON company_settings
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- ==========================================
-- ROW LEVEL SECURITY (RLS) POLICIES
-- ==========================================

-- Enable RLS on all tables
ALTER TABLE users ENABLE ROW LEVEL SECURITY;
ALTER TABLE employees ENABLE ROW LEVEL SECURITY;
ALTER TABLE departments ENABLE ROW LEVEL SECURITY;
ALTER TABLE designations ENABLE ROW LEVEL SECURITY;
ALTER TABLE payroll_records ENABLE ROW LEVEL SECURITY;
ALTER TABLE deductions_additions ENABLE ROW LEVEL SECURITY;
ALTER TABLE time_records ENABLE ROW LEVEL SECURITY;
ALTER TABLE shift_schedules ENABLE ROW LEVEL SECURITY;
ALTER TABLE leave_requests ENABLE ROW LEVEL SECURITY;
ALTER TABLE leave_balances ENABLE ROW LEVEL SECURITY;
ALTER TABLE public_holidays ENABLE ROW LEVEL SECURITY;
ALTER TABLE company_settings ENABLE ROW LEVEL SECURITY;
ALTER TABLE audit_log ENABLE ROW LEVEL SECURITY;
ALTER TABLE notifications ENABLE ROW LEVEL SECURITY;

-- ==========================================
-- USERS TABLE POLICIES
-- ==========================================

-- Users can view their own profile
CREATE POLICY "Users can view own profile" ON users FOR SELECT
USING (auth.uid() = id);

-- Users can update their own profile
CREATE POLICY "Users can update own profile" ON users FOR UPDATE
USING (auth.uid() = id);

-- Admins and HR can view all users
CREATE POLICY "Admins and HR can view all users" ON users FOR SELECT
USING (
  EXISTS (
    SELECT 1 FROM users u 
    WHERE u.id = auth.uid() 
    AND u.role IN ('admin', 'hr')
  )
);

-- Only admins can update user roles
CREATE POLICY "Admins can update user roles" ON users FOR UPDATE
USING (
  EXISTS (
    SELECT 1 FROM users u 
    WHERE u.id = auth.uid() 
    AND u.role = 'admin'
  )
);

-- Admins can insert new users
CREATE POLICY "Admins can insert users" ON users FOR INSERT
WITH CHECK (
  EXISTS (
    SELECT 1 FROM users u 
    WHERE u.id = auth.uid() 
    AND u.role = 'admin'
  )
);

-- ==========================================
-- EMPLOYEES TABLE POLICIES
-- ==========================================

-- Admins and HR can view all employees
CREATE POLICY "Admins and HR can view all employees" ON employees FOR SELECT
USING (
  EXISTS (
    SELECT 1 FROM users u 
    WHERE u.id = auth.uid() 
    AND u.role IN ('admin', 'hr')
  )
);

-- Employees can view their own record
CREATE POLICY "Employees can view own record" ON employees FOR SELECT
USING (
  EXISTS (
    SELECT 1 FROM users u 
    WHERE u.id = auth.uid() 
    AND u.employee_id = employees.id
  )
);

-- Admins and HR can manage employees
CREATE POLICY "Admins and HR can manage employees" ON employees FOR ALL
USING (
  EXISTS (
    SELECT 1 FROM users u 
    WHERE u.id = auth.uid() 
    AND u.role IN ('admin', 'hr')
  )
);

-- Employees can update their own personal info (limited fields)
CREATE POLICY "Employees can update own personal info" ON employees FOR UPDATE
USING (
  EXISTS (
    SELECT 1 FROM users u 
    WHERE u.id = auth.uid() 
    AND u.employee_id = employees.id
  )
)
WITH CHECK (
  -- Only allow updating personal fields, not employment details
  OLD.department = NEW.department AND
  OLD.designation = NEW.designation AND
  OLD.salary_type = NEW.salary_type AND
  OLD.basic_salary = NEW.basic_salary AND
  OLD.employment_status = NEW.employment_status
);

-- ==========================================
-- DEPARTMENTS TABLE POLICIES
-- ==========================================

-- All authenticated users can view departments
CREATE POLICY "All users can view departments" ON departments FOR SELECT
USING (auth.uid() IS NOT NULL);

-- Only admins can modify departments
CREATE POLICY "Admins can manage departments" ON departments FOR ALL
USING (
  EXISTS (
    SELECT 1 FROM users u 
    WHERE u.id = auth.uid() 
    AND u.role = 'admin'
  )
);

-- ==========================================
-- DESIGNATIONS TABLE POLICIES
-- ==========================================

-- All authenticated users can view designations
CREATE POLICY "All users can view designations" ON designations FOR SELECT
USING (auth.uid() IS NOT NULL);

-- Only admins can modify designations
CREATE POLICY "Admins can manage designations" ON designations FOR ALL
USING (
  EXISTS (
    SELECT 1 FROM users u 
    WHERE u.id = auth.uid() 
    AND u.role = 'admin'
  )
);

-- ==========================================
-- PAYROLL RECORDS POLICIES
-- ==========================================

-- Admins and HR can view all payroll records
CREATE POLICY "Admins and HR can view all payroll" ON payroll_records FOR SELECT
USING (
  EXISTS (
    SELECT 1 FROM users u 
    WHERE u.id = auth.uid() 
    AND u.role IN ('admin', 'hr')
  )
);

-- Employees can view their own payroll records
CREATE POLICY "Employees can view own payroll" ON payroll_records FOR SELECT
USING (
  EXISTS (
    SELECT 1 FROM users u 
    WHERE u.id = auth.uid() 
    AND u.employee_id = payroll_records.employee_id
  )
);

-- Only HR can create and update payroll records
CREATE POLICY "HR can manage payroll" ON payroll_records FOR ALL
USING (
  EXISTS (
    SELECT 1 FROM users u 
    WHERE u.id = auth.uid() 
    AND u.role = 'hr'
  )
);

-- Admins can also manage payroll
CREATE POLICY "Admins can manage payroll" ON payroll_records FOR ALL
USING (
  EXISTS (
    SELECT 1 FROM users u 
    WHERE u.id = auth.uid() 
    AND u.role = 'admin'
  )
);

-- ==========================================
-- DEDUCTIONS & ADDITIONS POLICIES
-- ==========================================

-- Admins and HR can view all deductions/additions
CREATE POLICY "Admins and HR can view all deductions" ON deductions_additions FOR SELECT
USING (
  EXISTS (
    SELECT 1 FROM users u 
    WHERE u.id = auth.uid() 
    AND u.role IN ('admin', 'hr')
  )
);

-- Employees can view their own deductions/additions
CREATE POLICY "Employees can view own deductions" ON deductions_additions FOR SELECT
USING (
  EXISTS (
    SELECT 1 FROM users u 
    WHERE u.id = auth.uid() 
    AND u.employee_id = deductions_additions.employee_id
  )
);

-- Admins and HR can manage deductions/additions
CREATE POLICY "Admins and HR can manage deductions" ON deductions_additions FOR ALL
USING (
  EXISTS (
    SELECT 1 FROM users u 
    WHERE u.id = auth.uid() 
    AND u.role IN ('admin', 'hr')
  )
);

-- ==========================================
-- TIME RECORDS POLICIES
-- ==========================================

-- Admins and HR can view all time records
CREATE POLICY "Admins and HR can view all time records" ON time_records FOR SELECT
USING (
  EXISTS (
    SELECT 1 FROM users u 
    WHERE u.id = auth.uid() 
    AND u.role IN ('admin', 'hr')
  )
);

-- Employees can view and create their own time records
CREATE POLICY "Employees can manage own time records" ON time_records FOR ALL
USING (
  EXISTS (
    SELECT 1 FROM users u 
    WHERE u.id = auth.uid() 
    AND u.employee_id = time_records.employee_id
  )
);

-- Admins and HR can approve time records
CREATE POLICY "Admins and HR can approve time records" ON time_records FOR UPDATE
USING (
  EXISTS (
    SELECT 1 FROM users u 
    WHERE u.id = auth.uid() 
    AND u.role IN ('admin', 'hr')
  )
);

-- ==========================================
-- SHIFT SCHEDULES POLICIES
-- ==========================================

-- All users can view shift schedules for their department/company
CREATE POLICY "Users can view shift schedules" ON shift_schedules FOR SELECT
USING (auth.uid() IS NOT NULL);

-- Admins and HR can manage shift schedules
CREATE POLICY "Admins and HR can manage shift schedules" ON shift_schedules FOR ALL
USING (
  EXISTS (
    SELECT 1 FROM users u 
    WHERE u.id = auth.uid() 
    AND u.role IN ('admin', 'hr')
  )
);

-- ==========================================
-- LEAVE REQUESTS POLICIES
-- ==========================================

-- Admins and HR can view all leave requests
CREATE POLICY "Admins and HR can view all leave requests" ON leave_requests FOR SELECT
USING (
  EXISTS (
    SELECT 1 FROM users u 
    WHERE u.id = auth.uid() 
    AND u.role IN ('admin', 'hr')
  )
);

-- Employees can view and create their own leave requests
CREATE POLICY "Employees can manage own leave requests" ON leave_requests FOR ALL
USING (
  EXISTS (
    SELECT 1 FROM users u 
    WHERE u.id = auth.uid() 
    AND u.employee_id = leave_requests.employee_id
  )
);

-- Admins and HR can approve/reject leave requests
CREATE POLICY "Admins and HR can approve leave requests" ON leave_requests FOR UPDATE
USING (
  EXISTS (
    SELECT 1 FROM users u 
    WHERE u.id = auth.uid() 
    AND u.role IN ('admin', 'hr')
  )
);

-- ==========================================
-- LEAVE BALANCES POLICIES
-- ==========================================

-- Admins and HR can view all leave balances
CREATE POLICY "Admins and HR can view all leave balances" ON leave_balances FOR SELECT
USING (
  EXISTS (
    SELECT 1 FROM users u 
    WHERE u.id = auth.uid() 
    AND u.role IN ('admin', 'hr')
  )
);

-- Employees can view their own leave balances
CREATE POLICY "Employees can view own leave balances" ON leave_balances FOR SELECT
USING (
  EXISTS (
    SELECT 1 FROM users u 
    WHERE u.id = auth.uid() 
    AND u.employee_id = leave_balances.employee_id
  )
);

-- Admins and HR can manage leave balances
CREATE POLICY "Admins and HR can manage leave balances" ON leave_balances FOR ALL
USING (
  EXISTS (
    SELECT 1 FROM users u 
    WHERE u.id = auth.uid() 
    AND u.role IN ('admin', 'hr')
  )
);

-- ==========================================
-- PUBLIC HOLIDAYS POLICIES
-- ==========================================

-- All authenticated users can view public holidays
CREATE POLICY "All users can view public holidays" ON public_holidays FOR SELECT
USING (auth.uid() IS NOT NULL);

-- Only admins can manage public holidays
CREATE POLICY "Admins can manage public holidays" ON public_holidays FOR ALL
USING (
  EXISTS (
    SELECT 1 FROM users u 
    WHERE u.id = auth.uid() 
    AND u.role = 'admin'
  )
);

-- ==========================================
-- COMPANY SETTINGS POLICIES
-- ==========================================

-- All authenticated users can view company settings (read-only)
CREATE POLICY "All users can view company settings" ON company_settings FOR SELECT
USING (auth.uid() IS NOT NULL);

-- Only admins can modify company settings
CREATE POLICY "Admins can manage company settings" ON company_settings FOR ALL
USING (
  EXISTS (
    SELECT 1 FROM users u 
    WHERE u.id = auth.uid() 
    AND u.role = 'admin'
  )
);

-- ==========================================
-- AUDIT LOG POLICIES
-- ==========================================

-- Only admins can view audit log
CREATE POLICY "Admins can view audit log" ON audit_log FOR SELECT
USING (
  EXISTS (
    SELECT 1 FROM users u 
    WHERE u.id = auth.uid() 
    AND u.role = 'admin'
  )
);

-- System can insert audit logs (handled by triggers)
CREATE POLICY "System can insert audit log" ON audit_log FOR INSERT
WITH CHECK (TRUE);

-- ==========================================
-- NOTIFICATIONS POLICIES
-- ==========================================

-- Users can view their own notifications
CREATE POLICY "Users can view own notifications" ON notifications FOR SELECT
USING (auth.uid() = user_id);

-- Users can update their own notifications
CREATE POLICY "Users can update own notifications" ON notifications FOR UPDATE
USING (auth.uid() = user_id);

-- System can insert notifications (handled by application logic)
CREATE POLICY "System can insert notifications" ON notifications FOR INSERT
WITH CHECK (TRUE);

-- ==========================================
-- HELPER FUNCTIONS
-- ==========================================

-- Function to get user role
CREATE OR REPLACE FUNCTION get_user_role(user_id UUID)
RETURNS user_role AS $$
DECLARE
  user_role_result user_role;
BEGIN
  SELECT role INTO user_role_result
  FROM users
  WHERE id = user_id;
  
  RETURN user_role_result;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to check if user can access employee record
CREATE OR REPLACE FUNCTION can_access_employee(emp_id UUID)
RETURNS BOOLEAN AS $$
DECLARE
  current_user_role user_role;
  user_emp_id UUID;
BEGIN
  -- Get current user's role and employee ID
  SELECT role, employee_id INTO current_user_role, user_emp_id
  FROM users
  WHERE id = auth.uid();
  
  -- Admins and HR can access all employee records
  IF current_user_role IN ('admin', 'hr') THEN
    RETURN TRUE;
  END IF;
  
  -- Employees can only access their own record
  RETURN user_emp_id = emp_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to automatically create user profile on signup
CREATE OR REPLACE FUNCTION handle_new_user()
RETURNS TRIGGER AS $$
BEGIN
  INSERT INTO public.users (id, email, role, first_name, last_name)
  VALUES (
    NEW.id,
    NEW.email,
    'employee', -- Default role
    NEW.raw_user_meta_data->>'first_name',
    NEW.raw_user_meta_data->>'last_name'
  );
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Create trigger for new user signup
CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE FUNCTION handle_new_user();

-- ==========================================
-- INITIAL DATA SEEDING
-- ==========================================

-- Insert default company settings
INSERT INTO company_settings (
  id,
  company_name,
  primary_color,
  secondary_color,
  paye_bands
) VALUES (
  gen_random_uuid(),
  'Your Company Name',
  '#006A4E',
  '#EF7D00',
  '[
    {"name": "Tax Free", "min": 0, "max": 5100, "rate": 0},
    {"name": "Band 1", "min": 5100.01, "max": 7100, "rate": 0.20},
    {"name": "Band 2", "min": 7100.01, "max": 9200, "rate": 0.30},
    {"name": "Band 3", "min": 9200.01, "max": null, "rate": 0.37}
  ]'::jsonb
);

-- Insert default departments
INSERT INTO departments (name, code, description) VALUES
('Human Resources', 'HR', 'Human Resources Department'),
('Finance', 'FIN', 'Finance and Accounting'),
('Information Technology', 'IT', 'Information Technology Department'),
('Marketing', 'MKT', 'Marketing and Communications'),
('Operations', 'OPS', 'Operations Department'),
('Sales', 'SAL', 'Sales Department');

-- Insert default designations
INSERT INTO designations (name, code, department_id, level) 
SELECT 
  'Employee',
  'EMP',
  d.id,
  'Junior'
FROM departments d WHERE d.code = 'HR';

INSERT INTO designations (name, code, department_id, level) 
SELECT 
  'Manager',
  'MGR',
  d.id,
  'Manager'
FROM departments d WHERE d.code = 'HR';

-- Insert some public holidays for 2025
INSERT INTO public_holidays (name, date, description, is_recurring, month, day) VALUES
('New Year''s Day', '2025-01-01', 'New Year''s Day', true, 1, 1),
('Independence Day', '2025-03-24', 'Independence Day', true, 3, 24),
('Labour Day', '2025-05-01', 'Labour Day', true, 5, 1),
('African Freedom Day', '2025-05-25', 'African Freedom Day', true, 5, 25),
('Heroes'' Day', '2025-07-07', 'Heroes'' Day', true, 7, 7),
('Unity Day', '2025-07-08', 'Unity Day', true, 7, 8),
('Farmers'' Day', '2025-08-01', 'Farmers'' Day', true, 8, 1),
('Independence Day', '2025-10-24', 'Independence Day', true, 10, 24),
('Christmas Day', '2025-12-25', 'Christmas Day', true, 12, 25),
('Boxing Day', '2025-12-26', 'Boxing Day', true, 12, 26);

-- ==========================================
-- COMPLETION MESSAGE
-- ==========================================

-- Grant necessary permissions
GRANT USAGE ON SCHEMA public TO authenticated;
GRANT ALL ON ALL TABLES IN SCHEMA public TO authenticated;
GRANT ALL ON ALL SEQUENCES IN SCHEMA public TO authenticated;
GRANT ALL ON ALL FUNCTIONS IN SCHEMA public TO authenticated;

-- Enable Row Level Security
ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT ALL ON TABLES TO authenticated;
ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT ALL ON SEQUENCES TO authenticated;
ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT ALL ON FUNCTIONS TO authenticated;

-- Update sequence ownership
ALTER SEQUENCE IF EXISTS users_id_seq OWNED BY users.id;
ALTER SEQUENCE IF EXISTS employees_id_seq OWNED BY employees.id;
ALTER SEQUENCE IF EXISTS departments_id_seq OWNED BY departments.id;
ALTER SEQUENCE IF EXISTS designations_id_seq OWNED BY designations.id;
ALTER SEQUENCE IF EXISTS payroll_records_id_seq OWNED BY payroll_records.id;
ALTER SEQUENCE IF EXISTS deductions_additions_id_seq OWNED BY deductions_additions.id;
ALTER SEQUENCE IF EXISTS time_records_id_seq OWNED BY time_records.id;
ALTER SEQUENCE IF EXISTS shift_schedules_id_seq OWNED BY shift_schedules.id;
ALTER SEQUENCE IF EXISTS leave_requests_id_seq OWNED BY leave_requests.id;
ALTER SEQUENCE IF EXISTS leave_balances_id_seq OWNED BY leave_balances.id;
ALTER SEQUENCE IF EXISTS public_holidays_id_seq OWNED BY public_holidays.id;
ALTER SEQUENCE IF EXISTS company_settings_id_seq OWNED BY company_settings.id;
ALTER SEQUENCE IF EXISTS audit_log_id_seq OWNED BY audit_log.id;
ALTER SEQUENCE IF EXISTS notifications_id_seq OWNED BY notifications.id;

-- ==========================================
-- SCHEMA SETUP COMPLETE
-- ==========================================

SELECT 'GPTPayroll Database Schema Setup Complete!' as message;
