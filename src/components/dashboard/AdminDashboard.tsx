import React, { useState, useEffect } from 'react'
import { useAuth } from '../../context/AuthContext'
import { supabase } from '../../lib/supabase'
import { formatZMK } from '../../utils/payrollCalculations'
import { 
  Users, 
  DollarSign, 
  Clock, 
  FileText, 
  TrendingUp, 
  Building2,
  AlertCircle,
  CheckCircle
} from 'lucide-react'

interface DashboardStats {
  totalEmployees: number
  activeEmployees: number
  totalPayroll: number
  pendingPayrolls: number
  averageSalary: number
  totalOvertime: number
  pendingApprovals: number
}

interface RecentActivity {
  id: string
  type: 'employee_added' | 'payroll_processed' | 'time_approved' | 'leave_approved'
  description: string
  timestamp: string
  user: string
}

const AdminDashboard: React.FC = () => {
  const { user } = useAuth()
  const [stats, setStats] = useState<DashboardStats>({
    totalEmployees: 0,
    activeEmployees: 0,
    totalPayroll: 0,
    pendingPayrolls: 0,
    averageSalary: 0,
    totalOvertime: 0,
    pendingApprovals: 0
  })
  const [recentActivity, setRecentActivity] = useState<RecentActivity[]>([])
  const [loading, setLoading] = useState(true)

  useEffect(() => {
    loadDashboardData()
  }, [])

  const loadDashboardData = async () => {
    try {
      // Load employee stats
      const { data: employees } = await supabase
        .from('employees')
        .select('*')

      const activeEmployees = employees?.filter(emp => emp.status === 'active') || []
      const totalSalary = activeEmployees.reduce((sum, emp) => sum + emp.basic_salary, 0)

      // Load payroll stats for current month
      const currentMonth = new Date().toISOString().slice(0, 7)
      const { data: payrollRecords } = await supabase
        .from('payroll_records')
        .select('*')
        .gte('pay_period', `${currentMonth}-01`)
        .lt('pay_period', `${currentMonth}-32`)

      const totalPayroll = payrollRecords?.reduce((sum, record) => sum + record.net_pay, 0) || 0
      const pendingPayrolls = payrollRecords?.filter(record => record.status === 'draft').length || 0

      // Load pending approvals
      const { data: pendingTime } = await supabase
        .from('time_records')
        .select('*')
        .eq('status', 'pending')

      const { data: pendingLeave } = await supabase
        .from('leave_requests')
        .select('*')
        .eq('status', 'pending')

      setStats({
        totalEmployees: employees?.length || 0,
        activeEmployees: activeEmployees.length,
        totalPayroll,
        pendingPayrolls,
        averageSalary: activeEmployees.length > 0 ? totalSalary / activeEmployees.length : 0,
        totalOvertime: 0, // Calculate from time records
        pendingApprovals: (pendingTime?.length || 0) + (pendingLeave?.length || 0)
      })

      // Load recent activity (mock data for now)
      setRecentActivity([
        {
          id: '1',
          type: 'employee_added',
          description: 'New employee John Doe added to IT department',
          timestamp: new Date(Date.now() - 2 * 60 * 60 * 1000).toISOString(),
          user: 'HR Admin'
        },
        {
          id: '2',
          type: 'payroll_processed',
          description: 'November payroll processed for 25 employees',
          timestamp: new Date(Date.now() - 4 * 60 * 60 * 1000).toISOString(),
          user: 'Payroll System'
        },
        {
          id: '3',
          type: 'time_approved',
          description: 'Time sheets approved for October 2025',
          timestamp: new Date(Date.now() - 6 * 60 * 60 * 1000).toISOString(),
          user: 'HR Manager'
        }
      ])

    } catch (error) {
      console.error('Error loading dashboard data:', error)
    } finally {
      setLoading(false)
    }
  }

  const getActivityIcon = (type: string) => {
    switch (type) {
      case 'employee_added':
        return <Users className="w-4 h-4" />
      case 'payroll_processed':
        return <DollarSign className="w-4 h-4" />
      case 'time_approved':
        return <Clock className="w-4 h-4" />
      case 'leave_approved':
        return <CheckCircle className="w-4 h-4" />
      default:
        return <AlertCircle className="w-4 h-4" />
    }
  }

  const formatTimestamp = (timestamp: string) => {
    const date = new Date(timestamp)
    const now = new Date()
    const diffInHours = Math.floor((now.getTime() - date.getTime()) / (1000 * 60 * 60))
    
    if (diffInHours < 1) {
      return 'Just now'
    } else if (diffInHours < 24) {
      return `${diffInHours} hours ago`
    } else {
      const diffInDays = Math.floor(diffInHours / 24)
      return `${diffInDays} days ago`
    }
  }

  if (loading) {
    return (
      <div className="flex items-center justify-center min-h-screen">
        <div className="animate-spin rounded-full h-32 w-32 border-b-2 border-green-600"></div>
      </div>
    )
  }

  return (
    <div className="space-y-6">
      {/* Header */}
      <div className="bg-white rounded-lg shadow-md p-6">
        <div className="flex items-center justify-between">
          <div>
            <h1 className="text-3xl font-bold text-gray-900">Admin Dashboard</h1>
            <p className="text-gray-600 mt-1">
              Welcome back, {user?.email}! Here's your company overview.
            </p>
          </div>
          <div className="flex items-center space-x-2">
            <Building2 className="w-8 h-8 text-green-600" />
            <span className="text-lg font-semibold text-gray-900">GPTPayroll</span>
          </div>
        </div>
      </div>

      {/* Stats Cards */}
      <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-6">
        <div className="bg-white rounded-lg shadow-md p-6 hover:shadow-lg transition-shadow">
          <div className="flex items-center justify-between">
            <div>
              <p className="text-sm font-medium text-gray-600">Total Employees</p>
              <p className="text-3xl font-bold text-gray-900">{stats.totalEmployees}</p>
              <p className="text-sm text-green-600 mt-1">
                {stats.activeEmployees} active
              </p>
            </div>
            <div className="w-12 h-12 bg-blue-100 rounded-full flex items-center justify-center">
              <Users className="w-6 h-6 text-blue-600" />
            </div>
          </div>
        </div>

        <div className="bg-white rounded-lg shadow-md p-6 hover:shadow-lg transition-shadow">
          <div className="flex items-center justify-between">
            <div>
              <p className="text-sm font-medium text-gray-600">Total Payroll</p>
              <p className="text-2xl font-bold text-gray-900">{formatZMK(stats.totalPayroll)}</p>
              <p className="text-sm text-gray-500 mt-1">
                This month
              </p>
            </div>
            <div className="w-12 h-12 bg-green-100 rounded-full flex items-center justify-center">
              <DollarSign className="w-6 h-6 text-green-600" />
            </div>
          </div>
        </div>

        <div className="bg-white rounded-lg shadow-md p-6 hover:shadow-lg transition-shadow">
          <div className="flex items-center justify-between">
            <div>
              <p className="text-sm font-medium text-gray-600">Average Salary</p>
              <p className="text-2xl font-bold text-gray-900">{formatZMK(stats.averageSalary)}</p>
              <p className="text-sm text-gray-500 mt-1">
                Per employee
              </p>
            </div>
            <div className="w-12 h-12 bg-yellow-100 rounded-full flex items-center justify-center">
              <TrendingUp className="w-6 h-6 text-yellow-600" />
            </div>
          </div>
        </div>

        <div className="bg-white rounded-lg shadow-md p-6 hover:shadow-lg transition-shadow">
          <div className="flex items-center justify-between">
            <div>
              <p className="text-sm font-medium text-gray-600">Pending Actions</p>
              <p className="text-3xl font-bold text-gray-900">{stats.pendingApprovals}</p>
              <p className="text-sm text-orange-600 mt-1">
                {stats.pendingPayrolls} payrolls
              </p>
            </div>
            <div className="w-12 h-12 bg-red-100 rounded-full flex items-center justify-center">
              <AlertCircle className="w-6 h-6 text-red-600" />
            </div>
          </div>
        </div>
      </div>

      {/* Recent Activity */}
      <div className="grid grid-cols-1 lg:grid-cols-2 gap-6">
        <div className="bg-white rounded-lg shadow-md p-6">
          <h3 className="text-lg font-semibold text-gray-900 mb-4">Recent Activity</h3>
          <div className="space-y-4">
            {recentActivity.map((activity) => (
              <div key={activity.id} className="flex items-start space-x-3">
                <div className="w-8 h-8 bg-gray-100 rounded-full flex items-center justify-center">
                  {getActivityIcon(activity.type)}
                </div>
                <div className="flex-1 min-w-0">
                  <p className="text-sm text-gray-900">{activity.description}</p>
                  <p className="text-xs text-gray-500 mt-1">
                    {formatTimestamp(activity.timestamp)} by {activity.user}
                  </p>
                </div>
              </div>
            ))}
          </div>
        </div>

        {/* Quick Actions */}
        <div className="bg-white rounded-lg shadow-md p-6">
          <h3 className="text-lg font-semibold text-gray-900 mb-4">Quick Actions</h3>
          <div className="space-y-3">
            <button className="w-full flex items-center space-x-3 p-3 text-left rounded-lg border border-gray-200 hover:bg-gray-50 transition-colors">
              <Users className="w-5 h-5 text-blue-600" />
              <span className="text-sm font-medium text-gray-900">Add New Employee</span>
            </button>
            <button className="w-full flex items-center space-x-3 p-3 text-left rounded-lg border border-gray-200 hover:bg-gray-50 transition-colors">
              <DollarSign className="w-5 h-5 text-green-600" />
              <span className="text-sm font-medium text-gray-900">Process Payroll</span>
            </button>
            <button className="w-full flex items-center space-x-3 p-3 text-left rounded-lg border border-gray-200 hover:bg-gray-50 transition-colors">
              <FileText className="w-5 h-5 text-purple-600" />
              <span className="text-sm font-medium text-gray-900">Generate Reports</span>
            </button>
            <button className="w-full flex items-center space-x-3 p-3 text-left rounded-lg border border-gray-200 hover:bg-gray-50 transition-colors">
              <Clock className="w-5 h-5 text-orange-600" />
              <span className="text-sm font-medium text-gray-900">Review Time Sheets</span>
            </button>
          </div>
        </div>
      </div>
    </div>
  )
}

export default AdminDashboard