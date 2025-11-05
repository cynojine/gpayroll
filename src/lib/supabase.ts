import { createClient } from '@supabase/supabase-js'

const supabaseUrl = process.env.REACT_APP_SUPABASE_URL || 'https://your-project.supabase.co'
const supabaseAnonKey = process.env.REACT_APP_SUPABASE_ANON_KEY || 'your-anon-key'

export const supabase = createClient(supabaseUrl, supabaseAnonKey, {
  auth: {
    autoRefreshToken: true,
    persistSession: true,
    detectSessionInUrl: true
  }
})

// Database types matching the complete schema
export interface User {
  id: string
  email: string
  role: 'admin' | 'hr' | 'employee'
  employee_id?: string
  first_name?: string
  last_name?: string
  phone?: string
  avatar_url?: string
  last_login_at?: string
  email_verified: boolean
  is_active: boolean
  created_at: string
  updated_at: string
}

export interface Employee {
  id: string
  employee_id: string
  first_name: string
  last_name: string
  middle_name?: string
  email: string
  phone?: string
  alternate_phone?: string
  tpin: string
  nrc: string
  address?: string
  city?: string
  province?: string
  country?: string
  date_of_birth?: string
  gender?: 'male' | 'female' | 'other'
  marital_status?: 'single' | 'married' | 'divorced' | 'widowed'
  emergency_contact_name?: string
  emergency_contact_phone?: string
  emergency_contact_relationship?: string
  
  department: string
  designation: string
  salary_type: 'hourly' | 'monthly' | 'contract'
  basic_salary: number
  hourly_rate?: number
  contract_amount?: number
  start_date: string
  end_date?: string
  probation_end_date?: string
  employment_status: 'active' | 'inactive' | 'terminated' | 'on_leave'
  
  bank_name?: string
  bank_branch?: string
  account_number?: string
  account_holder_name?: string
  
  medical_aid_provider?: string
  medical_aid_number?: string
  pension_fund?: string
  pension_fund_number?: string
  
  profile_photo_url?: string
  notes?: string
  is_tax_exempt: boolean
  
  created_at: string
  updated_at: string
}

export interface PayrollRecord {
  id: string
  employee_id: string
  pay_period: string
  pay_month: number
  pay_year: number
  
  basic_pay: number
  allowances: number
  bonuses: number
  overtime_pay: number
  commissions: number
  gratuity: number
  other_earnings: number
  
  napsa: number
  nhis: number
  tax: number
  loans: number
  advances: number
  other_deductions: number
  
  gross_pay: number
  total_deductions: number
  net_pay: number
  
  pay_date: string
  status: 'draft' | 'processed' | 'paid' | 'cancelled'
  processed_by?: string
  approved_by?: string
  approved_at?: string
  
  tax_breakdown?: any
  napsa_breakdown?: any
  
  notes?: string
  created_at: string
  updated_at: string
}

export interface DeductionAddition {
  id: string
  employee_id: string
  name: string
  type: 'deduction' | 'addition'
  amount?: number
  percentage?: number
  is_percentage: boolean
  is_before_gross: boolean
  is_before_tax: boolean
  calculation_basis: 'gross' | 'basic_pay' | 'net'
  is_recurring: boolean
  start_date: string
  end_date?: string
  status: 'active' | 'inactive'
  requires_approval: boolean
  approved_by?: string
  approved_at?: string
  description?: string
  reference_number?: string
  created_at: string
  updated_at: string
}

export interface TimeRecord {
  id: string
  employee_id: string
  date: string
  clock_in?: string
  clock_out?: string
  break_start?: string
  break_end?: string
  total_break_time?: string
  hours_worked: number
  overtime_hours: number
  status: 'present' | 'absent' | 'leave' | 'holiday' | 'sick' | 'pending' | 'approved' | 'rejected'
  leave_type?: 'annual' | 'sick' | 'maternity' | 'paternity' | 'emergency' | 'study' | 'unpaid'
  approved_by?: string
  approved_at?: string
  rejection_reason?: string
  notes?: string
  created_at: string
  updated_at: string
}

export interface LeaveRequest {
  id: string
  employee_id: string
  leave_type: 'annual' | 'sick' | 'maternity' | 'paternity' | 'emergency' | 'study' | 'unpaid'
  start_date: string
  end_date: string
  days: number
  reason: string
  urgent: boolean
  medical_certificate_required: boolean
  medical_certificate_url?: string
  status: 'pending' | 'approved' | 'rejected'
  approved_by?: string
  approved_at?: string
  rejection_reason?: string
  supervisor_comments?: string
  hr_comments?: string
  created_at: string
  updated_at: string
}

export interface CompanySettings {
  id: string
  company_name: string
  registration_number?: string
  tax_number?: string
  address?: string
  city?: string
  province?: string
  country?: string
  phone?: string
  email?: string
  website?: string
  logo_url?: string
  
  primary_color: string
  secondary_color: string
  accent_color: string
  
  napsa_rate: number
  napsa_maximum: number
  nhis_rate: number
  paye_bands: any[]
  nihma_rate: number
  
  working_days_per_month: number
  working_hours_per_day: number
  overtime_rate_multiplier: number
  late_arrival_threshold: number
  
  annual_leave_days: number
  sick_leave_days: number
  maternity_leave_days: number
  paternity_leave_days: number
  
  payslip_template: any
  payslip_footer?: string
  include_qr_code: boolean
  
  currency_symbol: string
  date_format: string
  time_format: string
  timezone: string
  
  smtp_host?: string
  smtp_port?: number
  smtp_username?: string
  smtp_password?: string
  from_email?: string
  from_name?: string
  
  email_notifications: boolean
  sms_notifications: boolean
  leave_reminder_days: number
  
  created_at: string
  updated_at: string
}

// Utility functions for authentication
export const getCurrentUser = async (): Promise<User | null> => {
  const { data: { user } } = await supabase.auth.getUser()
  if (!user) return null

  const { data, error } = await supabase
    .from('user_profiles')
    .select('*')
    .eq('id', user.id)
    .single()

  if (error) {
    console.error('Error fetching current user:', error)
    return null
  }

  return data
}

export const checkUserRole = (user: User | null, roles: string[]): boolean => {
  return user ? roles.includes(user.role) : false
}

export const requireAuth = (user: User | null): void => {
  if (!user) {
    throw new Error('Authentication required')
  }
}

export const requireRole = (user: User | null, roles: string[]): void => {
  requireAuth(user)
  if (!checkUserRole(user, roles)) {
    throw new Error('Insufficient permissions')
  }
}