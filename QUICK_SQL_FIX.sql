-- ==========================================
-- QUICK FIX FOR SQL SYNTAX ERROR
-- Run this to fix the "syntax error at or near DEFAULT" issue
-- ==========================================

-- Fix for line 407 syntax error in original schema
-- The error was: UNIQUE(id) DEFAULT gen_random_uuid()
-- This should be removed as it's redundant with the PRIMARY KEY definition

-- If the company_settings table already exists with the error, run this:
-- DROP AND RECREATE the table with correct syntax

DROP TABLE IF EXISTS public.company_settings CASCADE;

-- Recreate the table with correct syntax
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
  paye_tax_bands JSONB NOT NULL,
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

-- Create trigger for updated_at
CREATE TRIGGER update_company_settings_updated_at 
BEFORE UPDATE ON public.company_settings 
FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- Enable RLS
ALTER TABLE public.company_settings ENABLE ROW LEVEL SECURITY;

-- Create RLS policies for company_settings
CREATE POLICY "Everyone can view company settings" ON public.company_settings FOR SELECT USING (true);
CREATE POLICY "Admins can modify company settings" ON public.company_settings FOR ALL USING (EXISTS (SELECT 1 FROM public.users WHERE id = auth.uid() AND role = 'admin'));

-- Insert default settings
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

-- Verify the fix
SELECT 'company_settings table created successfully' as status;