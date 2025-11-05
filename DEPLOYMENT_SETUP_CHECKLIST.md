# GPTPayroll Deployment Setup Checklist

## Complete Step-by-Step Guide for Setting up GPTPayroll in Production

This comprehensive checklist will guide you through the entire process of deploying GPTPayroll, from database setup to application testing.

---

## 📋 Pre-Deployment Checklist

### ✅ Required Information
- [ ] Supabase account created (https://supabase.com)
- [ ] Company details ready (name, address, tax information)
- [ ] First admin user email and password decided
- [ ] Company logo prepared (optional, for branding)
- [ ] SMTP settings for email notifications (optional)

---

## 🚀 Phase 1: Supabase Project Setup

### Step 1: Create Supabase Project
1. **Go to Supabase Dashboard**
   - Visit: https://supabase.com/dashboard
   - Sign in or create a new account

2. **Create New Project**
   - Click "New Project"
   - Choose organization
   - Project name: `gptpayroll-[your-company-name]`
   - Database password: `YourSecurePassword123!` (save this!)
   - Region: Choose closest to your location
   - Pricing plan: Start with Free tier (can upgrade later)

3. **Wait for Project Setup**
   - Project initialization takes 1-2 minutes
   - You'll see a loading screen

### Step 2: Get Project Credentials
1. **Go to Project Settings**
   - Click "Settings" in left sidebar
   - Click "API" tab

2. **Copy Important URLs and Keys**
   ```
   Project URL: https://xxxxxxxxxxxx.supabase.co
   API Key (anon public): eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...
   Service Role Key (secret): eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...
   ```

3. **Save Credentials Securely**
   - Create a text file: `supabase-credentials.txt`
   - Store both keys and URL safely

---

## 🗄️ Phase 2: Database Setup

### Step 1: Run Database Schema
1. **Open Supabase SQL Editor**
   - In your project dashboard
   - Click "SQL Editor" in left sidebar

2. **Execute Main Schema**
   - Create new query
   - Copy and paste entire contents of `CORRECTED_DATABASE_SCHEMA.sql`
   - Click "RUN" button
   - Wait for execution (should complete in 10-30 seconds)

3. **Verify Schema Creation**
   - Check left sidebar for new tables under "Table Editor"
   - You should see: users, employees, departments, etc.
   - Total of 14 tables should be created

### Step 2: Run Initialization Script
1. **Create New Query for Initialization**
   - Copy contents of `DATABASE_INITIALIZATION.sql`
   - Paste into SQL Editor

2. **Execute Setup Functions** (Run these manually, not full script)
   ```sql
   -- First, verify RLS policies are enabled
   SELECT verify_rls_policies();
   
   -- Create sample data for testing
   SELECT create_sample_employees();
   ```

3. **Verify Data Creation**
   - Check tables for sample data:
     - `departments`: Should have 7 departments
     - `public_holidays`: Should have 9 holidays for 2025
     - `company_settings`: Should have 1 default record

---

## 🔐 Phase 3: Authentication Setup

### Step 1: Enable Email Authentication
1. **Go to Authentication Settings**
   - Click "Authentication" in left sidebar
   - Go to "Settings" tab
   - Click "User signups" sub-tab

2. **Configure Authentication**
   - Enable "Enable email confirmations"
   - Enable "Enable email change confirmations"
   - Set redirect URLs (if using custom domain)

### Step 2: Create First Admin User
1. **Method A: Via Supabase Dashboard**
   - Go to "Authentication" > "Users"
   - Click "Add User"
   - Enter admin email and temporary password
   - Click "Create user"

2. **Method B: Via Application Registration**
   - Start the React application
   - Register a new account
   - Then upgrade to admin using SQL:

   ```sql
   -- After user is created, upgrade to admin
   SELECT upgrade_user_to_admin('your-admin-email@domain.com');
   ```

### Step 3: Verify User Creation
1. **Check in Database**
   ```sql
   SELECT id, email, role, is_active, created_at 
   FROM public.users 
   ORDER BY created_at DESC;
   ```

2. **Expected Result**
   - Should see your admin user
   - Role should be 'admin'
   - is_active should be true

---

## ⚙️ Phase 4: Environment Configuration

### Step 1: Update Environment Variables
1. **Edit `.env` File**
   ```env
   # Supabase Configuration
   REACT_APP_SUPABASE_URL=https://xxxxxxxxxxxx.supabase.co
   REACT_APP_SUPABASE_ANON_KEY=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...
   
   # Development Settings
   REACT_APP_ENVIRONMENT=production
   REACT_APP_COMPANY_NAME=Your Company Name
   ```

2. **Create Production `.env.production`** (for deployment)
   ```env
   REACT_APP_SUPABASE_URL=https://xxxxxxxxxxxx.supabase.co
   REACT_APP_SUPABASE_ANON_KEY=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...
   REACT_APP_ENVIRONMENT=production
   ```

---

## 🖥️ Phase 5: Application Setup

### Step 1: Install Dependencies
1. **Navigate to Project Directory**
   ```bash
   cd /path/to/gptpayroll
   ```

2. **Install npm packages**
   ```bash
   npm install
   ```

3. **Verify Installation**
   - Check that `node_modules` folder is created
   - Check `package-lock.json` is updated

### Step 2: Build Application
1. **Development Build**
   ```bash
   npm start
   ```

2. **Production Build**
   ```bash
   npm run build
   ```

3. **Verify Build Success**
   - Check for any error messages
   - `build` folder should be created
   - No TypeScript compilation errors

---

## 🧪 Phase 6: Testing & Verification

### Step 1: Test Authentication Flow
1. **Start Development Server**
   ```bash
   npm start
   ```

2. **Test User Registration**
   - Open browser to `http://localhost:3000`
   - Try registering a new employee account
   - Verify email confirmation process

3. **Test Admin Login**
   - Login with admin credentials
   - Verify admin dashboard loads
   - Check that admin can see all features

### Step 2: Test Role-Based Access
1. **Create Test Users**
   ```sql
   -- Create HR user
   INSERT INTO public.users (id, email, full_name, role, is_active)
   VALUES (gen_random_uuid(), 'hr@test.com', 'HR User', 'hr', true);
   
   -- Create employee user
   INSERT INTO public.users (id, email, full_name, role, is_active)
   VALUES (gen_random_uuid(), 'employee@test.com', 'Employee User', 'employee', true);
   ```

2. **Verify Permissions**
   - Admin should see all data
   - HR should see employee data
   - Employee should see only their data

### Step 3: Test Core Features
- [ ] **Employee Management**
  - Create new employee
  - Edit employee details
  - View employee list

- [ ] **Payroll Management**
  - Process payroll for current month
  - Verify tax calculations (PAYE, NAPSA, NHIS)
  - Generate payslip

- [ ] **Time Tracking**
  - Clock in/out functionality
  - View time records
  - Overtime calculations

- [ ] **Leave Management**
  - Submit leave request
  - Approve/reject leave
  - View leave balances

- [ ] **Reports**
  - Generate payroll reports
  - Export employee data
  - View audit logs

---

## 🔍 Phase 7: Data Verification

### Step 1: Verify Tax Calculations
1. **Check PAYE Calculations**
   ```sql
   -- Example salary verification
   SELECT 
       basic_salary,
       paye_tax,
       (paye_tax / basic_salary * 100) as tax_percentage
   FROM payroll_records 
   WHERE basic_salary > 0 
   LIMIT 5;
   ```

2. **Expected Results (2025 Zambian Rates)**
   - Salary ≤ K5,100: 0% tax
   - Salary K5,100-K7,100: ~20% tax
   - Salary K7,100-K9,200: ~30% tax
   - Salary >K9,200: ~37% tax

### Step 2: Verify Leave Balances
```sql
-- Check leave balances
SELECT 
    e.first_name || ' ' || e.last_name as employee,
    lb.leave_type,
    lb.year,
    lb.allocated_days,
    lb.used_days,
    lb.total_available_days
FROM leave_balances lb
JOIN employees e ON lb.employee_id = e.id;
```

### Step 3: Verify RLS Policies
```sql
-- Test RLS is working
SELECT verify_rls_policies();
```

---

## 🌐 Phase 8: Production Deployment

### Option A: Vercel Deployment
1. **Prepare for Vercel**
   - Ensure `.env.production` is configured
   - Build project: `npm run build`

2. **Deploy to Vercel**
   - Connect GitHub repository to Vercel
   - Set environment variables in Vercel dashboard
   - Deploy

### Option B: Netlify Deployment
1. **Prepare for Netlify**
   - Build project: `npm run build`
   - Create `_redirects` file in `build` folder: `/* /index.html 200`

2. **Deploy to Netlify**
   - Drag and drop `build` folder to Netlify
   - Set environment variables in Netlify dashboard

### Option C: Traditional Hosting
1. **Static Hosting**
   - Upload `build` folder contents to web server
   - Configure web server for SPA (Single Page Application)
   - Set environment variables on server

---

## 🔧 Phase 9: Post-Deployment Configuration

### Step 1: Company Settings Configuration
1. **Update Company Information**
   ```sql
   UPDATE company_settings SET
       company_name = 'Your Company Name',
       registration_number = 'Your Company Registration',
       address = 'Your Company Address',
       phone = 'Your Phone Number',
       email = 'your.email@company.com',
       website = 'https://your-company.com'
   WHERE id = (SELECT id FROM company_settings LIMIT 1);
   ```

2. **Configure Tax Settings**
   ```sql
   -- Update NAPSA cap if needed (2025 rate)
   UPDATE company_settings SET
       napsa_cap = 1149.60,
       nhima_rate = 0.01  -- 1% NHIMA rate
   WHERE id = (SELECT id FROM company_settings LIMIT 1);
   ```

### Step 2: SMTP Configuration (Optional)
1. **Enable Email Notifications**
   - Configure SMTP settings in company settings
   - Test email functionality
   - Set up email templates if needed

### Step 3: Create Production Users
1. **Bulk User Creation**
   ```sql
   -- Create multiple employees (example)
   INSERT INTO public.users (id, email, full_name, role, is_active)
   VALUES 
       (gen_random_uuid(), 'john@company.com', 'John Doe', 'employee', true),
       (gen_random_uuid(), 'jane@company.com', 'Jane Smith', 'employee', true),
       (gen_random_uuid(), 'bob@company.com', 'Bob Johnson', 'hr', true);
   ```

---

## 📊 Phase 10: Monitoring & Maintenance

### Step 1: Database Monitoring
1. **Set up Monitoring**
   - Monitor Supabase dashboard for:
     - Database usage
     - Authentication metrics
     - API usage

2. **Regular Backups**
   - Supabase provides automatic backups
   - Consider additional backup strategies for critical data

### Step 2: Security Checklist
- [ ] **Password Policies**
  - Enable strong password requirements
  - Set up password reset functionality
  - Configure session timeouts

- [ ] **API Security**
  - Use environment variables for sensitive data
  - Regularly rotate API keys
  - Monitor API usage

- [ ] **Database Security**
  - RLS policies are enabled
  - Regular security updates
  - Audit log monitoring

### Step 3: Performance Optimization
- [ ] **Database Performance**
  - Monitor query performance
  - Add indexes if needed
  - Optimize slow queries

- [ ] **Application Performance**
  - Monitor page load times
  - Optimize bundle size
  - Use CDN for static assets

---

## 🚨 Troubleshooting Common Issues

### Issue 1: "RLS policy violation" errors
**Solution:**
- Verify RLS is enabled: `SELECT tablename FROM pg_tables WHERE schemaname = 'public' AND rowsecurity = true;`
- Check user authentication status
- Verify user role assignments

### Issue 2: Payroll calculations incorrect
**Solution:**
- Verify tax bands in `company_settings.paye_tax_bands`
- Check NAPSA cap setting
- Ensure tax calculation trigger is active

### Issue 3: Authentication not working
**Solution:**
- Verify Supabase URL and API key in environment variables
- Check authentication settings in Supabase dashboard
- Ensure user exists in `auth.users` table

### Issue 4: React app won't start
**Solution:**
- Clear node_modules: `rm -rf node_modules && npm install`
- Check Node.js version (should be 18+)
- Verify environment variables are correct

---

## 📞 Support & Next Steps

### Getting Help
- **Documentation**: Refer to individual component documentation
- **Supabase Support**: https://supabase.com/support
- **GitHub Issues**: Report bugs and feature requests

### Customization Options
- **Branding**: Update company logo and colors
- **Workflows**: Customize approval processes
- **Reports**: Add custom report templates
- **Integrations**: Connect with existing systems

### Feature Roadmap
- [ ] Advanced reporting dashboard
- [ ] Mobile application
- [ ] API for third-party integrations
- [ ] Advanced tax compliance features
- [ ] Multi-company support

---

## ✅ Final Deployment Checklist

### Before Going Live
- [ ] All core features tested
- [ ] Data integrity verified
- [ ] Security measures in place
- [ ] User training completed
- [ ] Backup strategy implemented
- [ ] Monitoring setup complete

### Success Metrics
- [ ] Users can successfully register and login
- [ ] Payroll calculations are accurate
- [ ] Role-based access is working correctly
- [ ] All CRUD operations function properly
- [ ] Performance meets acceptable standards
- [ ] Data backup and recovery tested

---

**🎉 Congratulations!** 

You have successfully deployed GPTPayroll. Your HR and payroll management system is now ready for production use.

**Last Updated:** November 5, 2025  
**Version:** 1.0.0  
**Author:** MiniMax Agent