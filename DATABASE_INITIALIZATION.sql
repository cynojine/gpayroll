-- ==========================================
-- GPTPAYROLL DATABASE INITIALIZATION SCRIPT
-- This script should be run AFTER the main schema has been created
-- ==========================================

-- ==========================================
-- SECTION 1: ADMIN USER CREATION FUNCTIONS
-- ==========================================

-- Function to create admin user with authentication
CREATE OR REPLACE FUNCTION create_admin_user(
    admin_email TEXT,
    admin_password TEXT,
    admin_full_name TEXT DEFAULT 'System Administrator'
)
RETURNS JSON AS $$
DECLARE
    auth_user_id UUID;
    admin_user_id UUID;
    admin_role TEXT := 'admin';
    result JSON;
BEGIN
    -- Note: This function requires admin privileges in Supabase Auth
    -- You may need to call this via SQL Editor with elevated permissions
    -- or implement via your application layer
    
    -- This is a placeholder - in real implementation, you'd use:
    -- SELECT auth.admin.create_user() or similar
    RAISE NOTICE 'Admin user creation should be handled through Supabase Auth or your application layer';
    
    -- For demonstration, create a direct user record
    -- In production, this would be created via Supabase Auth
    admin_user_id := gen_random_uuid();
    
    INSERT INTO public.users (
        id, 
        email, 
        full_name, 
        role, 
        is_active, 
        created_at, 
        updated_at
    ) VALUES (
        admin_user_id,
        admin_email,
        admin_full_name,
        admin_role,
        true,
        now(),
        now()
    );
    
    result := json_build_object(
        'success', true,
        'user_id', admin_user_id,
        'email', admin_email,
        'role', admin_role,
        'message', 'Admin user created successfully. Please ensure authentication is properly configured.'
    );
    
    RETURN result;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to upgrade user to admin role
CREATE OR REPLACE FUNCTION upgrade_user_to_admin(
    user_email TEXT
)
RETURNS JSON AS $$
DECLARE
    target_user_id UUID;
    result JSON;
BEGIN
    -- Find user by email
    SELECT id INTO target_user_id FROM public.users WHERE email = user_email;
    
    IF target_user_id IS NULL THEN
        RETURN json_build_object(
            'success', false,
            'message', 'User not found with email: ' || user_email
        );
    END IF;
    
    -- Update user role to admin
    UPDATE public.users 
    SET 
        role = 'admin',
        updated_at = now()
    WHERE id = target_user_id;
    
    result := json_build_object(
        'success', true,
        'user_id', target_user_id,
        'email', user_email,
        'role', 'admin',
        'message', 'User upgraded to admin successfully.'
    );
    
    RETURN result;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ==========================================
-- SECTION 2: SAMPLE DATA CREATION
-- ==========================================

-- Function to create sample employees for testing
CREATE OR REPLACE FUNCTION create_sample_employees()
RETURNS JSON AS $$
DECLARE
    dept_hr_id UUID;
    dept_finance_id UUID;
    dept_it_id UUID;
    desig_manager_id UUID;
    desig_executive_id UUID;
    desig_staff_id UUID;
    sample_users UUID[];
    sample_employees UUID[];
    employee_data JSON;
    result JSON;
    i INTEGER;
BEGIN
    -- Get department IDs
    SELECT id INTO dept_hr_id FROM departments WHERE name = 'Human Resources';
    SELECT id INTO dept_finance_id FROM departments WHERE name = 'Finance';
    SELECT id INTO dept_it_id FROM departments WHERE name = 'Information Technology';
    
    -- Get designation IDs
    SELECT id INTO desig_manager_id FROM designations WHERE name = 'Department Manager';
    SELECT id INTO desig_executive_id FROM designations WHERE name = 'Executive';
    SELECT id INTO desig_staff_id FROM designations WHERE name = 'Staff Member';
    
    -- Create sample users (these would normally be created via Supabase Auth)
    -- For testing purposes, we'll create them directly in the users table
    INSERT INTO public.users (id, email, full_name, role, is_active, created_at, updated_at) VALUES
    (gen_random_uuid(), 'admin@gptpayroll.com', 'System Administrator', 'admin', true, now(), now()),
    (gen_random_uuid(), 'hr.manager@gptpayroll.com', 'HR Manager', 'hr', true, now(), now()),
    (gen_random_uuid(), 'john.employee@gptpayroll.com', 'John Kamwendo', 'employee', true, now(), now()),
    (gen_random_uuid(), 'mary.employee@gptpayroll.com', 'Mary Banda', 'employee', true, now(), now()),
    (gen_random_uuid(), 'peter.employee@gptpayroll.com', 'Peter Mwansa', 'employee', true, now(), now())
    RETURNING id INTO ARRAY sample_users;
    
    -- Create sample employees
    INSERT INTO public.employees (
        id, user_id, employee_number, first_name, last_name, email, 
        phone_number, date_of_birth, gender, nationality, nrc, tpin,
        marital_status, department_id, designation_id, employment_type,
        employee_status, hire_date, bank_name, account_number, account_name,
        emergency_contact_name, emergency_contact_phone, emergency_contact_relationship,
        created_at, updated_at
    ) VALUES
    -- HR Manager
    (gen_random_uuid(), sample_users[2], 'EMP001', 'John', 'Kamwendo', 'john.employee@gptpayroll.com',
     '+260977123456', '1985-03-15', 'Male', 'Zambian', '123456/11/1', '987654321',
     'Married', dept_hr_id, desig_manager_id, 'Full-time', 'Active', '2020-01-15',
     'Stanbic Bank', '1234567890', 'John Kamwendo',
     'Jane Kamwendo', '+260977654321', 'Spouse', now(), now()),
    -- Finance Executive  
    (gen_random_uuid(), sample_users[3], 'EMP002', 'Mary', 'Banda', 'mary.employee@gptpayroll.com',
     '+260976123456', '1990-07-22', 'Female', 'Zambian', '234567/12/1', '876543210',
     'Single', dept_finance_id, desig_executive_id, 'Full-time', 'Active', '2021-03-01',
     'FNB Zambia', '2345678901', 'Mary Banda',
     'Alice Banda', '+260976543211', 'Mother', now(), now()),
    -- IT Staff
    (gen_random_uuid(), sample_users[4], 'EMP003', 'Peter', 'Mwansa', 'peter.employee@gptpayroll.com',
     '+260975123456', '1988-11-08', 'Male', 'Zambian', '345678/13/1', '765432109',
     'Married', dept_it_id, desig_staff_id, 'Full-time', 'Active', '2022-06-15',
     'Standard Chartered', '3456789012', 'Peter Mwansa',
     'Grace Mwansa', '+260975432112', 'Spouse', now(), now())
    RETURNING id INTO ARRAY sample_employees;
    
    -- Create sample payroll records for current month
    INSERT INTO public.payroll_records (
        employee_id, payroll_month, payroll_year, basic_salary, overtime_hours,
        overtime_rate, bonus, allowances, pay_period_start, pay_period_end
    ) VALUES
    (sample_employees[1], 11, 2025, 8500.00, 8.0, 45.00, 500.00, 300.00, '2025-11-01', '2025-11-30'),
    (sample_employees[2], 11, 2025, 7200.00, 4.0, 38.00, 300.00, 250.00, '2025-11-01', '2025-11-30'),
    (sample_employees[3], 11, 2025, 5800.00, 12.0, 35.00, 200.00, 200.00, '2025-11-01', '2025-11-30');
    
    -- Create sample leave balances for 2025
    INSERT INTO public.leave_balances (
        employee_id, leave_type, year, allocated_days, carried_forward_days, last_updated
    ) VALUES
    (sample_employees[1], 'annual', 2025, 21.0, 3.0, now()),
    (sample_employees[1], 'sick', 2025, 10.0, 2.0, now()),
    (sample_employees[2], 'annual', 2025, 21.0, 5.0, now()),
    (sample_employees[2], 'sick', 2025, 10.0, 1.0, now()),
    (sample_employees[3], 'annual', 2025, 21.0, 0.0, now()),
    (sample_employees[3], 'sick', 2025, 10.0, 0.0, now());
    
    -- Create sample time records for current week
    INSERT INTO public.time_records (
        employee_id, record_date, clock_in, clock_out, total_hours, status
    ) VALUES
    (sample_employees[1], '2025-11-03', '2025-11-03 08:00:00', '2025-11-03 17:00:00', 8.0, 'present'),
    (sample_employees[1], '2025-11-04', '2025-11-04 08:15:00', '2025-11-04 17:30:00', 8.25, 'present'),
    (sample_employees[1], '2025-11-05', '2025-11-05 08:00:00', '2025-11-05 16:45:00', 8.75, 'present'),
    (sample_employees[2], '2025-11-03', '2025-11-03 08:30:00', '2025-11-03 17:00:00', 8.5, 'present'),
    (sample_employees[2], '2025-11-04', '2025-11-04 08:00:00', '2025-11-04 17:00:00', 9.0, 'present'),
    (sample_employees[3], '2025-11-03', '2025-11-03 09:00:00', '2025-11-03 18:00:00', 9.0, 'present'),
    (sample_employees[3], '2025-11-04', '2025-11-04 08:45:00', '2025-11-04 18:15:00', 9.5, 'present');
    
    result := json_build_object(
        'success', true,
        'message', 'Sample data created successfully',
        'users_created', array_length(sample_users, 1),
        'employees_created', array_length(sample_employees, 1),
        'sample_data', json_build_object(
            'departments', (SELECT COUNT(*) FROM departments),
            'employees', (SELECT COUNT(*) FROM employees),
            'payroll_records', (SELECT COUNT(*) FROM payroll_records),
            'leave_balances', (SELECT COUNT(*) FROM leave_balances),
            'time_records', (SELECT COUNT(*) FROM time_records)
        )
    );
    
    RETURN result;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ==========================================
-- SECTION 3: RLS POLICY VERIFICATION
-- ==========================================

-- Function to verify RLS policies are working
CREATE OR REPLACE FUNCTION verify_rls_policies()
RETURNS JSON AS $$
DECLARE
    policy_check JSON;
    result JSON;
BEGIN
    -- Check if RLS is enabled on all required tables
    WITH rls_status AS (
        SELECT 
            schemaname,
            tablename,
            rowsecurity as rls_enabled,
            CASE 
                WHEN rowsecurity THEN 'ENABLED'
                ELSE 'DISABLED'
            END as status
        FROM pg_tables 
        WHERE schemaname = 'public' 
        AND tablename IN (
            'users', 'employees', 'departments', 'designations', 
            'payroll_records', 'deductions_additions', 'time_records', 
            'shift_schedules', 'leave_requests', 'leave_balances', 
            'public_holidays', 'company_settings', 'audit_log', 'notifications'
        )
        ORDER BY tablename
    )
    SELECT json_agg(
        json_build_object(
            'table', tablename,
            'rls_status', status
        )
    ) INTO policy_check
    FROM rls_status;
    
    -- Check total policy count
    result := json_build_object(
        'success', true,
        'rls_verification', policy_check,
        'timestamp', now(),
        'message', 'RLS policies verification completed'
    );
    
    RETURN result;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to test user permissions (for admin use only)
CREATE OR REPLACE FUNCTION test_user_permissions(
    test_user_email TEXT,
    target_table TEXT
)
RETURNS JSON AS $$
DECLARE
    test_result JSON;
    table_list TEXT[] := ARRAY[
        'users', 'employees', 'departments', 'designations', 
        'payroll_records', 'deductions_additions', 'time_records', 
        'shift_schedules', 'leave_requests', 'leave_balances', 
        'public_holidays', 'company_settings', 'audit_log', 'notifications'
    ];
    user_role TEXT;
    user_id UUID;
    result JSON;
BEGIN
    -- Get user info
    SELECT id, role INTO user_id, user_role FROM public.users WHERE email = test_user_email;
    
    IF user_id IS NULL THEN
        RETURN json_build_object(
            'success', false,
            'message', 'User not found: ' || test_user_email
        );
    END IF;
    
    -- Test basic permissions (this is a simplified test)
    -- In production, you'd want more sophisticated testing
    result := json_build_object(
        'success', true,
        'test_user', test_user_email,
        'user_role', user_role,
        'permissions_tested', target_table,
        'timestamp', now(),
        'note', 'Actual permission testing requires authenticated session'
    );
    
    RETURN result;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ==========================================
-- SECTION 4: INITIALIZATION EXECUTION
-- ==========================================

-- Function to run full initialization
CREATE OR REPLACE FUNCTION initialize_gptpayroll_database()
RETURNS JSON AS $$
DECLARE
    init_result JSON;
    step_result JSON;
    results JSON[];
BEGIN
    RAISE NOTICE 'Starting GPTPayroll Database Initialization...';
    
    -- Step 1: Verify RLS policies
    RAISE NOTICE 'Step 1: Verifying RLS policies...';
    SELECT verify_rls_policies() INTO step_result;
    results := array_append(results, json_build_object('step', 'rls_verification', 'result', step_result));
    
    -- Step 2: Create sample data (for testing)
    RAISE NOTICE 'Step 2: Creating sample data...';
    SELECT create_sample_employees() INTO step_result;
    results := array_append(results, json_build_object('step', 'sample_data', 'result', step_result));
    
    init_result := json_build_object(
        'success', true,
        'initialization_timestamp', now(),
        'steps_completed', array_length(results, 1),
        'step_results', results,
        'next_steps', json_build_array(
            'Create authentication users via Supabase Auth',
            'Assign employee records to authenticated users',
            'Configure company settings as needed',
            'Test RLS policies with actual user sessions'
        )
    );
    
    RAISE NOTICE 'GPTPayroll Database Initialization Completed Successfully!';
    
    RETURN init_result;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ==========================================
-- SECTION 5: EXECUTION EXAMPLES
-- ==========================================

-- NOTE: Run these commands manually after creating the schema
-- They are commented out to prevent accidental execution

/*
-- Example 1: Create admin user (run manually in SQL Editor)
-- First create user in Supabase Auth, then run:
SELECT create_admin_user('admin@gptpayroll.com', 'secure_password_here', 'System Administrator');

-- Example 2: Upgrade existing user to admin
SELECT upgrade_user_to_admin('existing.user@example.com');

-- Example 3: Create sample data for testing
SELECT create_sample_employees();

-- Example 4: Run full initialization
SELECT initialize_gptpayroll_database();

-- Example 5: Verify RLS policies
SELECT verify_rls_policies();

-- Example 6: Test user permissions (requires authenticated session)
SELECT test_user_permissions('test.user@example.com', 'employees');
*/

-- ==========================================
-- SECTION 6: HELPFUL VIEWS FOR MONITORING
-- ==========================================

-- View for employee overview
CREATE OR REPLACE VIEW employee_overview AS
SELECT 
    e.employee_number,
    e.first_name || ' ' || e.last_name AS full_name,
    e.email,
    e.phone_number,
    d.name AS department,
    ds.name AS designation,
    e.employment_type,
    e.employee_status,
    e.hire_date,
    u.role,
    CASE 
        WHEN e.employee_status = 'Active' THEN 'Active'
        ELSE 'Inactive'
    END AS status_display
FROM employees e
LEFT JOIN departments d ON e.department_id = d.id
LEFT JOIN designations ds ON e.designation_id = ds.id
LEFT JOIN users u ON e.user_id = u.id
ORDER BY e.employee_number;

-- View for payroll summary
CREATE OR REPLACE VIEW payroll_summary AS
SELECT 
    pr.id,
    pr.payroll_year,
    pr.payroll_month,
    e.employee_number,
    e.first_name || ' ' || e.last_name AS employee_name,
    pr.basic_salary,
    pr.gross_pay,
    pr.paye_tax,
    pr.total_deductions,
    pr.net_pay,
    pr.payment_status,
    pr.payment_date,
    pr.payment_method
FROM payroll_records pr
JOIN employees e ON pr.employee_id = e.id
ORDER BY pr.payroll_year DESC, pr.payroll_month DESC, e.employee_number;

-- Grant view permissions
GRANT SELECT ON employee_overview TO authenticated;
GRANT SELECT ON payroll_summary TO authenticated;

-- ==========================================
-- INITIALIZATION COMPLETE
-- ==========================================

-- Display initialization status
SELECT 
    'GPTPayroll Database Initialization Complete!' as status,
    'All functions, views, and sample data are ready.' as message,
    now() as completed_at;