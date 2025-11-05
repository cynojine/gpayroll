# GPTPayroll Setup Guide

This guide will help you set up GPTPayroll on your local machine or deploy it to a web server.

## 🚀 Quick Start

### Prerequisites
- Node.js 18+ installed
- npm or yarn package manager
- Git for version control
- A modern web browser

### Step 1: Clone the Repository
```bash
git clone https://github.com/your-username/gptpayroll.git
cd gptpayroll
```

### Step 2: Install Dependencies
```bash
npm install
```

### Step 3: Set Up Supabase Database

1. **Create Supabase Account**
   - Go to [supabase.com](https://supabase.com)
   - Sign up for a free account
   - Create a new project

2. **Get Your Credentials**
   - In your Supabase dashboard, go to Settings > API
   - Copy your Project URL and anon/public key

3. **Set Up Database Schema**
   
   Run these SQL commands in your Supabase SQL Editor:

   ```sql
   -- Enable UUID extension
   CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

   -- Users table (extends Supabase auth.users)
   CREATE TABLE users (
     id UUID REFERENCES auth.users(id) PRIMARY KEY,
     email TEXT NOT NULL,
     role TEXT CHECK (role IN ('admin', 'hr', 'employee')) NOT NULL,
     employee_id UUID REFERENCES employees(id),
     created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
     updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
   );

   -- Employees table
   CREATE TABLE employees (
     id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
     employee_id TEXT UNIQUE NOT NULL,
     first_name TEXT NOT NULL,
     last_name TEXT NOT NULL,
     email TEXT UNIQUE NOT NULL,
     phone TEXT,
     tpin TEXT NOT NULL,
     nrc TEXT NOT NULL,
     department TEXT NOT NULL,
     designation TEXT NOT NULL,
     salary_type TEXT CHECK (salary_type IN ('hourly', 'monthly', 'contract')) NOT NULL,
     basic_salary DECIMAL(12,2) NOT NULL,
     hourly_rate DECIMAL(8,2),
     contract_amount DECIMAL(12,2),
     start_date DATE NOT NULL,
     end_date DATE,
     status TEXT CHECK (status IN ('active', 'inactive')) DEFAULT 'active',
     created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
     updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
   );

   -- Payroll records table
   CREATE TABLE payroll_records (
     id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
     employee_id UUID REFERENCES employees(id) NOT NULL,
     pay_period TEXT NOT NULL,
     basic_pay DECIMAL(12,2) NOT NULL,
     allowances DECIMAL(12,2) DEFAULT 0,
     bonuses DECIMAL(12,2) DEFAULT 0,
     gratuity DECIMAL(12,2) DEFAULT 0,
     gross_pay DECIMAL(12,2) NOT NULL,
     napsa DECIMAL(12,2) NOT NULL,
     nhis DECIMAL(12,2) NOT NULL,
     tax DECIMAL(12,2) NOT NULL,
     loans DECIMAL(12,2) DEFAULT 0,
     other_deductions DECIMAL(12,2) DEFAULT 0,
     total_deductions DECIMAL(12,2) NOT NULL,
     net_pay DECIMAL(12,2) NOT NULL,
     pay_date DATE NOT NULL,
     status TEXT CHECK (status IN ('draft', 'processed', 'paid')) DEFAULT 'draft',
     created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
     updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
   );

   -- Time records table
   CREATE TABLE time_records (
     id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
     employee_id UUID REFERENCES employees(id) NOT NULL,
     date DATE NOT NULL,
     clock_in TIME,
     clock_out TIME,
     break_start TIME,
     break_end TIME,
     hours_worked DECIMAL(5,2) DEFAULT 0,
     overtime_hours DECIMAL(5,2) DEFAULT 0,
     leave_type TEXT,
     status TEXT CHECK (status IN ('present', 'absent', 'leave', 'holiday', 'pending', 'approved', 'rejected')) DEFAULT 'present',
     approved_by UUID,
     approved_at TIMESTAMP WITH TIME ZONE,
     created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
     updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
   );

   -- Deductions and additions table
   CREATE TABLE deductions_additions (
     id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
     employee_id UUID REFERENCES employees(id) NOT NULL,
     name TEXT NOT NULL,
     type TEXT CHECK (type IN ('deduction', 'addition')) NOT NULL,
     amount DECIMAL(12,2) NOT NULL,
     percentage DECIMAL(5,2),
     is_percentage BOOLEAN DEFAULT FALSE,
     is_before_gross BOOLEAN DEFAULT FALSE,
     is_before_tax BOOLEAN DEFAULT FALSE,
     is_recurring BOOLEAN DEFAULT TRUE,
     start_date DATE NOT NULL,
     end_date DATE,
     status TEXT CHECK (status IN ('active', 'inactive')) DEFAULT 'active',
     created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
     updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
   );

   -- Leave requests table
   CREATE TABLE leave_requests (
     id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
     employee_id UUID REFERENCES employees(id) NOT NULL,
     leave_type TEXT NOT NULL,
     start_date DATE NOT NULL,
     end_date DATE NOT NULL,
     days INTEGER NOT NULL,
     reason TEXT,
     status TEXT CHECK (status IN ('pending', 'approved', 'rejected')) DEFAULT 'pending',
     approved_by UUID,
     approved_at TIMESTAMP WITH TIME ZONE,
     rejection_reason TEXT,
     created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
     updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
   );

   -- Company settings table
   CREATE TABLE company_settings (
     id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
     company_name TEXT NOT NULL,
     registration_number TEXT,
     address TEXT,
     logo_url TEXT,
     primary_color TEXT DEFAULT '#006A4E',
     secondary_color TEXT DEFAULT '#EF7D00',
     napsa_rate DECIMAL(4,3) DEFAULT 0.05,
     napsa_maximum DECIMAL(10,2) DEFAULT 1149.60,
     nhis_rate DECIMAL(4,3) DEFAULT 0.01,
     paye_bands JSONB DEFAULT '[]',
     nihma_rate DECIMAL(4,3) DEFAULT 0.01,
     working_days_per_month INTEGER DEFAULT 22,
     working_hours_per_day INTEGER DEFAULT 8,
     overtime_rate_multiplier DECIMAL(3,1) DEFAULT 1.5,
     payslip_template JSONB DEFAULT '{}',
     created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
     updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
   );

   -- Enable Row Level Security
   ALTER TABLE users ENABLE ROW LEVEL SECURITY;
   ALTER TABLE employees ENABLE ROW LEVEL SECURITY;
   ALTER TABLE payroll_records ENABLE ROW LEVEL SECURITY;
   ALTER TABLE time_records ENABLE ROW LEVEL SECURITY;
   ALTER TABLE deductions_additions ENABLE ROW LEVEL SECURITY;
   ALTER TABLE leave_requests ENABLE ROW LEVEL SECURITY;
   ALTER TABLE company_settings ENABLE ROW LEVEL SECURITY;

   -- Create RLS policies (basic - you may need to adjust based on your needs)
   
   -- Users can read their own profile
   CREATE POLICY "Users can view own profile" ON users FOR SELECT USING (auth.uid() = id);
   CREATE POLICY "Users can update own profile" ON users FOR UPDATE USING (auth.uid() = id);

   -- Employees policies
   CREATE POLICY "Admins and HR can view all employees" ON employees FOR ALL USING (
     EXISTS (SELECT 1 FROM users WHERE id = auth.uid() AND role IN ('admin', 'hr'))
   );
   CREATE POLICY "Employees can view own record" ON employees FOR SELECT USING (
     EXISTS (SELECT 1 FROM users WHERE id = auth.uid() AND employee_id = employees.id)
   );

   -- Similar policies for other tables...
   ```

4. **Configure Authentication**
   - In Supabase Dashboard > Authentication > Settings
   - Enable email authentication
   - Configure site URL (your domain or localhost for development)

### Step 4: Configure Environment Variables

1. **Copy the environment file:**
   ```bash
   cp .env.example .env
   ```

2. **Edit `.env` file:**
   ```env
   REACT_APP_SUPABASE_URL=https://your-project.supabase.co
   REACT_APP_SUPABASE_ANON_KEY=your_supabase_anon_key_here
   ```

### Step 5: Start Development Server

```bash
npm start
```

The application will be available at `http://localhost:3000`

### Step 6: Create Admin User

1. Go to the application
2. Register a new account
3. In Supabase, manually update your user role to 'admin':
   ```sql
   UPDATE users SET role = 'admin' WHERE email = 'your-email@company.com';
   ```

## 📱 First Time Setup

### 1. Company Configuration
- Log in as admin
- Go to Settings > Company Settings
- Configure your company information
- Set tax rates (they should match Zambian 2025 tax bands)

### 2. Add Employees
- Go to Employees > Add Employee
- Fill in employee details including TPIN and NRC
- Set salary information

### 3. Test Payroll
- Go to Payroll > Run Payroll
- Select employees and process a test payroll
- Generate and preview payslips

## 🔧 Configuration Options

### Company Settings
- **General**: Company info, logo, branding colors
- **Tax Settings**: NAPSA, NHIS, PAYE rates and bands
- **Payroll**: Working hours, overtime rates
- **Payslip Template**: Customizable payslip layout

### User Roles
- **Admin**: Full system access, company settings
- **HR**: Employee management, payroll processing
- **Employee**: Self-service, time tracking

## 🚀 Deployment

### Option 1: Vercel (Recommended)

1. **Install Vercel CLI:**
   ```bash
   npm i -g vercel
   ```

2. **Deploy:**
   ```bash
   vercel --prod
   ```

3. **Configure Environment Variables:**
   - In Vercel dashboard, add your environment variables
   - Update Supabase site URL if needed

### Option 2: Netlify

1. **Build the project:**
   ```bash
   npm run build
   ```

2. **Deploy to Netlify:**
   - Connect your GitHub repository
   - Set build command: `npm run build`
   - Set publish directory: `build`
   - Add environment variables

### Option 3: Traditional Web Hosting

1. **Build the project:**
   ```bash
   npm run build
   ```

2. **Upload `build` folder** to your web server

3. **Configure your web server** to serve the React app (add a fallback route to `index.html`)

## 🔒 Security Considerations

### Environment Variables
- Never commit `.env` files to version control
- Use different keys for development and production
- Rotate your Supabase keys regularly

### Database Security
- Review and test RLS policies thoroughly
- Regular database backups
- Monitor access logs

### Application Security
- Enable HTTPS in production
- Configure CSP headers
- Regular dependency updates

## 🐛 Troubleshooting

### Common Issues

1. **"Invalid API key" error**
   - Check your Supabase credentials in `.env`
   - Ensure you're using the correct environment

2. **Database connection errors**
   - Verify Supabase project is active
   - Check network connectivity
   - Review RLS policies

3. **Authentication not working**
   - Check Supabase auth settings
   - Verify site URL configuration
   - Ensure email confirmation is set up

4. **Build errors**
   - Clear node_modules and reinstall: `rm -rf node_modules && npm install`
   - Check Node.js version (should be 18+)

### Getting Help

- Check the [main README](README.md) for feature documentation
- Review the [API documentation](docs/api.md)
- Create an issue on GitHub for bugs
- Check Supabase documentation for database-related issues

## 📊 System Requirements

### Development
- Node.js 18+
- 4GB RAM minimum
- Modern web browser

### Production
- Web server (Apache, Nginx, etc.)
- HTTPS support
- Regular backups recommended

### Browser Support
- Chrome 90+
- Firefox 88+
- Safari 14+
- Edge 90+

## 🔄 Updates and Maintenance

### Regular Tasks
- Update dependencies: `npm update`
- Review and test RLS policies
- Monitor application performance
- Backup database regularly

### Version Updates
- Check release notes before updating
- Test in development environment first
- Create backups before major updates

---

**Need help?** Create an issue on GitHub or contact the development team.

**GPTPayroll** - Empowering Zambian businesses with modern payroll and HR management.