# GPTPayroll - Zambian Payroll & HR Management System

A comprehensive payroll and HR management system built specifically for Zambian businesses, featuring complete tax compliance, payslip generation, and employee management.

![GPTPayroll Logo](https://via.placeholder.com/800x200/006A4E/FFFFFF?text=GPTPayroll+Zambia)

## 🌟 Features

### Core Payroll Features
- **Zambian Tax Compliance**: Complete implementation of 2025 tax bands and deductions
  - PAYE Tax calculations based on official Zambian tax bands
  - NAPSA deductions (5% capped at K1,149.60)
  - NHIS contributions (1% of basic pay)
  - Custom deductions and additions support
- **Multi-Salary Types**: Support for hourly, monthly, and contract employees
- **Payslip Generation**: Customizable payslip templates with Zambian branding
- **Bulk Export**: Export multiple payslips as PDFs or Excel files
- **Payroll Processing**: Automated payroll calculations with preview

### Employee Management
- **Complete Employee Records**: TPIN, NRC, contact information, and employment details
- **Department and Designation Management**: Organize employees by departments
- **Employee Status Tracking**: Active/inactive status management
- **Employee Self-Service**: Dashboard for employees to view their information

### Time & Attendance
- **Clock In/Out System**: Web-based time tracking
- **Overtime Calculations**: Automatic overtime calculation and reporting
- **Leave Management**: Request and approval system for leave
- **Holiday Calendar**: Zambian public holidays integration
- **Attendance Reports**: Comprehensive attendance analytics

### HR Management
- **Role-Based Access Control**: Admin, HR, and Employee roles
- **Leave Management**: Comprehensive leave request and approval system
- **Employee Onboarding**: Streamlined employee addition process
- **Document Management**: Store and manage employee documents

### Reporting & Analytics
- **Payroll Reports**: Detailed payroll summaries and breakdowns
- **Tax Reports**: ZRA-compliant tax reports
- **Employee Reports**: Comprehensive employee analytics
- **Attendance Reports**: Time and attendance summaries
- **Export Capabilities**: PDF, Excel, and CSV export options

### Company Settings
- **Company Branding**: Custom logos, colors, and payslip templates
- **Tax Configuration**: Adjustable tax rates and bands
- **Working Hours**: Configurable working days and hours
- **Leave Policies**: Customizable leave balances and policies

## 🏛️ Zambian Compliance Features

### Tax Bands (2025)
- **Tax-Free**: First K5,100 @ 0%
- **Band 1**: K5,100.01 - K7,100 @ 20%
- **Band 2**: K7,100.01 - K9,200 @ 30%
- **Band 3**: Above K9,200 @ 37%

### Mandatory Deductions
- **NAPSA**: 5% of gross pay (maximum K1,149.60)
- **NHIS**: 1% of basic pay
- **PAYE**: Based on official Zambian tax bands

### Employee Information Requirements
- **TPIN**: Tax Payer Identification Number
- **NRC**: National Registration Card number
- **Contact Information**: Phone and address details

## 🚀 Technology Stack

### Frontend
- **React 18** with TypeScript
- **React Router** for navigation
- **React Hook Form** for form management
- **Lucide React** for icons
- **Tailwind CSS** for styling
- **Recharts** for data visualization

### Backend & Database
- **Supabase** for backend services
- **PostgreSQL** database
- **Row Level Security (RLS)** for data protection
- **Real-time subscriptions** for live updates

### Additional Libraries
- **jsPDF** for PDF generation
- **html2canvas** for web-to-image conversion
- **XLSX** for Excel export
- **Date-fns** for date manipulation
- **React Toastify** for notifications

## 📦 Installation

### Prerequisites
- Node.js 18+ and npm
- Supabase account
- Git

### Quick Start

1. **Clone the repository**
   ```bash
   git clone https://github.com/your-username/gptpayroll.git
   cd gptpayroll
   ```

2. **Install dependencies**
   ```bash
   npm install
   ```

3. **Configure environment variables**
   Create a `.env` file in the root directory:
   ```env
   REACT_APP_SUPABASE_URL=your_supabase_url
   REACT_APP_SUPABASE_ANON_KEY=your_supabase_anon_key
   ```

4. **Set up Supabase database**
   - Create a new Supabase project
   - Run the SQL scripts provided in `database/` folder
   - Configure Row Level Security policies

5. **Start the development server**
   ```bash
   npm start
   ```

6. **Access the application**
   Open [http://localhost:3000](http://localhost:3000) in your browser

## 🗄️ Database Setup

### Required Tables
The system requires the following database tables:

```sql
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
```

### Row Level Security (RLS)
Enable RLS and create appropriate policies to secure data access based on user roles.

## 👥 User Roles & Permissions

### Admin
- Full system access
- Company settings configuration
- User management
- All payroll operations
- Complete reporting access

### HR
- Employee management
- Payroll processing
- Leave approval
- Time record approval
- HR reporting

### Employee
- View own information
- Clock in/out
- Leave requests
- View own payslips
- Personal time records

## 📊 Payroll Calculation Example

Here's how the system calculates payroll for a Zambian employee:

```typescript
// Example: Monthly employee earning K8,000 basic salary
const payroll = calculatePayroll(
  basicPay: 8000,        // Basic monthly salary
  allowances: 500,       // Transport allowance
  bonuses: 0,            // No bonuses this month
  gratuity: 0,           // No gratuity
  loans: 200,            // Loan repayment
  otherDeductions: 0
)

// Result:
// Gross Pay: K8,500
// NAPSA: K425 (5% of gross, capped at K1,149.60)
// NHIS: K80 (1% of basic pay)
// PAYE Tax: K1,230 (based on tax bands)
// Total Deductions: K1,935
// Net Pay: K6,565
```

## 🎨 Customization

### Company Branding
- Upload company logo
- Customize primary and secondary colors
- Configure payslip layout and content
- Set company information

### Tax Configuration
- Adjust NAPSA rates and caps
- Modify PAYE tax bands
- Configure NHIS rates
- Set custom deduction templates

### Payslip Templates
- Standard, Compact, and Detailed layouts
- Show/hide employee photos
- Include/exclude TPIN and NRC
- Custom color schemes

## 🔧 Configuration

### Environment Variables
```env
# Supabase Configuration
REACT_APP_SUPABASE_URL=your_project_url
REACT_APP_SUPABASE_ANON_KEY=your_anon_key

# Optional: Analytics
REACT_APP_GA_TRACKING_ID=your_google_analytics_id

# Optional: Error Tracking
REACT_APP_SENTRY_DSN=your_sentry_dsn
```

### Company Settings
Access the company settings panel to configure:
- Company information and branding
- Tax rates and calculations
- Working hours and schedules
- Leave policies and balances
- Payslip template preferences

## 📱 Mobile Support

The application is fully responsive and works on:
- Desktop computers
- Tablets
- Mobile phones
- All modern web browsers

## 🔒 Security Features

- Row Level Security (RLS) in database
- Role-based access control
- Secure authentication via Supabase
- Data encryption in transit and at rest
- Audit trails for all operations
- GDPR-compliant data handling

## 🧪 Testing

### Running Tests
```bash
npm test
```

### Test Coverage
```bash
npm run test:coverage
```

## 🚀 Deployment

### Production Build
```bash
npm run build
```

### Deployment Options
- **Vercel** (Recommended for React apps)
- **Netlify**
- **AWS Amplify**
- **Supabase Hosting**
- Traditional web hosting

### Environment Setup
Ensure all environment variables are properly configured in your deployment environment.

## 📈 Performance

### Optimization Features
- Code splitting
- Lazy loading
- Image optimization
- Caching strategies
- Bundle optimization

### Monitoring
- Web vitals tracking
- Error monitoring
- Performance metrics
- User analytics

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## 📝 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🆘 Support

### Documentation
- [User Guide](docs/user-guide.md)
- [API Documentation](docs/api.md)
- [Deployment Guide](docs/deployment.md)

### Getting Help
- Create an issue for bugs
- Start a discussion for questions
- Contact support for urgent issues

## 🏆 Acknowledgments

- Zambia Revenue Authority (ZRA) for tax guidelines
- National Pension Scheme Authority (NAPSA) for contribution rules
- Ministry of Health for NHIS information
- The Zambian business community for requirements feedback

## 📊 Project Status

### Completed Features ✅
- [x] User authentication and authorization
- [x] Employee management
- [x] Payroll calculations (2025 tax bands)
- [x] Payslip generation and customization
- [x] Time and attendance tracking
- [x] Leave management
- [x] Reporting system
- [x] Company settings
- [x] Bulk export functionality
- [x] Mobile-responsive design

### Planned Features 🚧
- [ ] Advanced reporting dashboard
- [ ] Mobile app (React Native)
- [ ] Integration with ZRA systems
- [ ] Advanced leave policies
- [ ] Performance management
- [ ] Training management
- [ ] Document management system
- [ ] Email notifications
- [ ] Multi-branch support

---

**GPTPayroll** - Empowering Zambian businesses with modern payroll and HR management.

Built with ❤️ for Zambia by MiniMax Agent