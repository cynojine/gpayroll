-- ==========================================
-- QUICK FIX FOR ON CONFLICT ERROR
-- This fixes the unique constraint issue
-- ==========================================

-- Remove all ON CONFLICT clauses and use simple INSERTs
-- Company settings - only insert if doesn't exist
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

-- Departments - use INSERT IGNORE approach
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

-- Designations - use INSERT IGNORE approach
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

-- Public holidays - use INSERT IGNORE approach for 2025
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

-- Verify insertion
SELECT 
  'Company Settings' as table_name, 
  COUNT(*) as records_inserted 
FROM public.company_settings
UNION ALL
SELECT 
  'Departments' as table_name, 
  COUNT(*) as records_inserted 
FROM public.departments
UNION ALL
SELECT 
  'Designations' as table_name, 
  COUNT(*) as records_inserted 
FROM public.designations
UNION ALL
SELECT 
  'Public Holidays' as table_name, 
  COUNT(*) as records_inserted 
FROM public.public_holidays;

SELECT 'ON CONFLICT fix completed successfully!' as status;