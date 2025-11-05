# GPTPayroll Authentication & Profile Setup Guide

This guide will walk you through setting up the complete authentication system for GPTPayroll with user profiles and role management.

## 🔐 Authentication Features

- **Secure Login/Registration** with Supabase Auth
- **Role-Based Access Control** (Admin, HR, Employee)
- **User Profile Management** with employee data linkage
- **Automatic Profile Creation** on signup
- **Password Reset** functionality
- **Email Verification** support
- **Session Management** with automatic token refresh

## 📋 Prerequisites

1. **Supabase Project Setup**
   - Create a project at [supabase.com](https://supabase.com)
   - Note down your Project URL and anon key

2. **Database Schema**
   - Run the complete schema from `COMPLETE_DATABASE_SCHEMA.sql`
   - This includes all RLS policies and authentication triggers

## 🔧 Authentication Configuration

### 1. Supabase Auth Settings

Go to your Supabase Dashboard > Authentication > Settings and configure:

#### **Site URL Configuration**
```
Development: http://localhost:3000
Production: https://your-domain.com
```

#### **Email Templates** (Optional - Customize as needed)
- Confirmation email
- Invitation email
- Reset password email
- Magic Link email

#### **Email Authentication Settings**
- **Enable email confirmations**: ✅ Recommended
- **Enable email change confirmations**: ✅
- **Enable email confirmations on signup**: ✅

### 2. Environment Configuration

Create/update your `.env` file:

```env
# Supabase Configuration
REACT_APP_SUPABASE_URL=https://your-project.supabase.co
REACT_APP_SUPABASE_ANON_KEY=your_supabase_anon_key_here

# Authentication Settings
REACT_APP_ENABLE_EMAIL_CONFIRMATION=true
REACT_APP_ENABLE_PASSWORD_RESET=true
REACT_APP_SESSION_TIMEOUT=3600

# Company Settings
REACT_APP_COMPANY_NAME="Your Company Name"
REACT_APP_DEFAULT_USER_ROLE=employee
```

### 3. Database Authentication Setup

Run this additional SQL in your Supabase SQL Editor:

```sql
-- ==========================================
-- AUTHENTICATION HELPER FUNCTIONS
-- ==========================================

-- Function to handle new user signup
CREATE OR REPLACE FUNCTION handle_new_user()
RETURNS TRIGGER AS $$
BEGIN
  -- Create user profile in our users table
  INSERT INTO public.users (
    id,
    email,
    role,
    first_name,
    last_name,
    email_verified,
    is_active
  )
  VALUES (
    NEW.id,
    NEW.email,
    'employee', -- Default role
    COALESCE(NEW.raw_user_meta_data->>'first_name', ''),
    COALESCE(NEW.raw_user_meta_data->>'last_name', ''),
    CASE 
      WHEN NEW.email_confirmed_at IS NOT NULL THEN TRUE 
      ELSE FALSE 
    END,
    TRUE
  );
  
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to update user last login
CREATE OR REPLACE FUNCTION update_user_last_login()
RETURNS TRIGGER AS $$
BEGIN
  UPDATE public.users 
  SET 
    last_login_at = NOW(),
    updated_at = NOW()
  WHERE id = NEW.id;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to get user with employee data
CREATE OR REPLACE FUNCTION get_user_with_employee(user_id UUID)
RETURNS TABLE (
  user_id UUID,
  email TEXT,
  role TEXT,
  employee_id UUID,
  first_name TEXT,
  last_name TEXT,
  phone TEXT,
  avatar_url TEXT,
  last_login_at TIMESTAMP WITH TIME ZONE,
  email_verified BOOLEAN,
  is_active BOOLEAN,
  created_at TIMESTAMP WITH TIME ZONE,
  updated_at TIMESTAMP WITH TIME ZONE,
  -- Employee data
  employee_employee_id TEXT,
  employee_department TEXT,
  employee_designation TEXT,
  employee_status TEXT,
  employee_tpin TEXT,
  employee_nrc TEXT
) AS $$
BEGIN
  RETURN QUERY
  SELECT 
    u.id,
    u.email,
    u.role,
    u.employee_id,
    u.first_name,
    u.last_name,
    u.phone,
    u.avatar_url,
    u.last_login_at,
    u.email_verified,
    u.is_active,
    u.created_at,
    u.updated_at,
    -- Employee data
    e.employee_id as employee_employee_id,
    e.department as employee_department,
    e.designation as employee_designation,
    e.employment_status as employee_status,
    e.tpin as employee_tpin,
    e.nrc as employee_nrc
  FROM public.users u
  LEFT JOIN public.employees e ON u.employee_id = e.id
  WHERE u.id = user_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ==========================================
-- TRIGGERS FOR AUTHENTICATION
-- ==========================================

-- Trigger for new user signup
DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE FUNCTION handle_new_user();

-- Trigger for updating last login
DROP TRIGGER IF EXISTS on_auth_user_login ON auth.sessions;
CREATE TRIGGER on_auth_user_login
  AFTER INSERT ON auth.sessions
  FOR EACH ROW EXECUTE FUNCTION update_user_last_login();

-- ==========================================
-- SECURITY FUNCTIONS
-- ==========================================

-- Function to check if user can perform action
CREATE OR REPLACE FUNCTION can_perform_action(
  user_role TEXT,
  required_roles TEXT[]
)
RETURNS BOOLEAN AS $$
BEGIN
  RETURN user_role = ANY(required_roles);
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to get user's accessible employee IDs
CREATE OR REPLACE FUNCTION get_accessible_employee_ids(current_user_id UUID)
RETURNS UUID[] AS $$
DECLARE
  user_role TEXT;
  employee_ids UUID[];
BEGIN
  -- Get user role
  SELECT role INTO user_role
  FROM public.users
  WHERE id = current_user_id;
  
  CASE user_role
    WHEN 'admin' THEN
      -- Admins can access all employees
      SELECT ARRAY_AGG(id) INTO employee_ids
      FROM public.employees;
      
    WHEN 'hr' THEN
      -- HR can access all employees
      SELECT ARRAY_AGG(id) INTO employee_ids
      FROM public.employees;
      
    WHEN 'employee' THEN
      -- Employees can only access their own record
      SELECT ARRAY_AGG(employee_id) INTO employee_ids
      FROM public.users
      WHERE id = current_user_id AND employee_id IS NOT NULL;
      
    ELSE
      employee_ids := ARRAY[]::UUID[];
  END CASE;
  
  RETURN COALESCE(employee_ids, ARRAY[]::UUID[]);
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ==========================================
-- VIEWS FOR EASY DATA ACCESS
-- ==========================================

-- User profile view with employee data
CREATE OR REPLACE VIEW user_profiles AS
SELECT 
  u.id,
  u.email,
  u.role,
  u.employee_id,
  u.first_name,
  u.last_name,
  u.phone,
  u.avatar_url,
  u.last_login_at,
  u.email_verified,
  u.is_active,
  u.created_at,
  u.updated_at,
  -- Employee data
  e.employee_id as employee_code,
  e.department,
  e.designation,
  e.employment_status,
  e.tpin,
  e.nrc,
  e.date_of_birth,
  e.gender,
  e.marital_status,
  e.address,
  e.city,
  e.province,
  e.bank_name,
  e.bank_branch,
  e.account_number,
  e.basic_salary,
  e.salary_type
FROM public.users u
LEFT JOIN public.employees e ON u.employee_id = e.id;

-- ==========================================
-- INITIAL ADMIN USER SETUP
-- ==========================================

-- Function to create admin user
CREATE OR REPLACE FUNCTION create_admin_user(
  email TEXT,
  password TEXT,
  first_name TEXT,
  last_name TEXT
)
RETURNS UUID AS $$
DECLARE
  admin_user_id UUID;
BEGIN
  -- Note: This should be called from application logic
  -- Supabase Admin API should be used to create auth users
  -- This function is for reference
  
  RAISE NOTICE 'Use Supabase Admin API to create auth user with email: %', email;
  RAISE NOTICE 'Then call create_user_profile() with the auth user ID';
  
  RETURN admin_user_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ==========================================
-- COMPLETION
-- ==========================================

SELECT 'Authentication setup complete!' as message;
```

## 👤 User Profile Management

### User Profile Structure

Each user has:
- **Basic Info**: Email, role, name, phone, avatar
- **Authentication**: Email verification status, last login
- **Employee Link**: Connection to employee record (for employees)
- **Activity**: Account status, creation/update timestamps

### Role Permissions

#### **Admin Role**
- Full system access
- User management (create, update, delete users)
- Employee management (all records)
- Payroll management (all records)
- System settings configuration
- Audit log access
- Company settings management

#### **HR Role**
- Employee management (view, create, update)
- Payroll processing (all employees)
- Leave approval/rejection
- Time record approval
- Deduction/addition management
- Reports and analytics
- User profile viewing

#### **Employee Role**
- Self-service access
- View own employee record
- View own payroll records
- Clock in/out functionality
- Leave request submission
- View own time records
- Update personal information (limited fields)

## 🔐 Authentication Flow

### 1. User Registration

```typescript
// Registration creates both auth user and profile
const register = async (email: string, password: string, userData: any) => {
  // 1. Create auth user with Supabase
  const { data: authUser, error: authError } = await supabase.auth.signUp({
    email,
    password,
    options: {
      data: {
        first_name: userData.first_name,
        last_name: userData.last_name
      }
    }
  })

  // 2. Trigger automatically creates user profile
  // 3. Optionally create employee record
}
```

### 2. User Login

```typescript
// Login with email/password
const login = async (email: string, password: string) => {
  const { data, error } = await supabase.auth.signInWithPassword({
    email,
    password
  })

  // 1. Authenticate user
  // 2. Fetch user profile with employee data
  // 3. Update last login timestamp
  // 4. Set user context
}
```

### 3. Profile Management

```typescript
// Update user profile
const updateProfile = async (updates: Partial<UserProfile>) => {
  const { data, error } = await supabase
    .from('user_profiles')
    .update(updates)
    .eq('id', userId)
    .select()
    .single()
}
```

## 🛡️ Security Features

### Row Level Security (RLS)

All tables have RLS enabled with policies for:
- **Users**: Can only access own profile (except admins)
- **Employees**: Role-based access (admin/hr see all, employees see own)
- **Payroll**: Confidential - only authorized roles
- **Personal Data**: Strict access controls

### Session Management

- **Automatic token refresh**
- **Session timeout handling**
- **Concurrent session management**
- **Secure logout with cleanup**

### Data Protection

- **PII encryption** at rest
- **Secure API endpoints** with authentication
- **Audit logging** for all user actions
- **Input validation** and sanitization

## 🔧 Implementation Details

### Enhanced AuthContext Features

```typescript
interface AuthContextType {
  user: UserProfile | null
  loading: boolean
  login: (email: string, password: string) => Promise<boolean>
  logout: () => Promise<void>
  register: (data: RegisterData) => Promise<boolean>
  updateProfile: (updates: Partial<UserProfile>) => Promise<boolean>
  changePassword: (oldPassword: string, newPassword: string) => Promise<boolean>
  resetPassword: (email: string) => Promise<boolean>
  hasRole: (roles: string[]) => boolean
  canAccess: (resource: string, action: string) => boolean
}
```

### Profile Components

- **UserProfileForm**: Edit personal information
- **PasswordChangeForm**: Secure password update
- **AvatarUpload**: Profile picture management
- **SecuritySettings**: Account security preferences

## 🚀 Getting Started

1. **Set up Supabase project** and configure authentication
2. **Run database schema** with RLS policies
3. **Configure environment variables**
4. **Create first admin user** through Supabase dashboard
5. **Test authentication flow**
6. **Deploy with secure environment variables**

## 📚 Additional Resources

- [Supabase Auth Documentation](https://supabase.com/docs/guides/auth)
- [Row Level Security Guide](https://supabase.com/docs/guides/auth/row-level-security)
- [User Management Best Practices](https://supabase.com/docs/guides/auth/managing-users)
- [JWT Token Management](https://supabase.com/docs/guides/auth/jwt)

---

**Need help?** Check the troubleshooting section in the main setup guide or create an issue on GitHub.

**GPTPayroll** - Secure, role-based authentication for Zambian businesses.
