import React, { useState, useEffect } from 'react'
import { useAuth } from '../../context/AuthContext'
import { supabase } from '../../lib/supabase'
import { formatZMK } from '../../utils/payrollCalculations'
import { 
  User, 
  DollarSign, 
  Clock, 
  Calendar,
  FileText,
  TrendingUp,
  Download,
  Eye,
  AlertCircle
} from 'lucide-react'

interface EmployeeDashboardData {
  employee: any
  currentPayroll: any
  recentPayrolls: any[]
  timeRecords: any[]
  leaveBalance: {
    annual: number
    sick: number
    emergency: number
  }
  recentPayslips: any[]
}

const EmployeeDashboard: React.FC = () => {
  const { user } = useAuth()
  const [dashboardData, setDashboardData] = useState<EmployeeDashboardData>({
    employee: null,
    currentPayroll: null,
    recentPayrolls: [],
    timeRecords: [],
    leaveBalance: {
      annual: 21,
      sick: 10,
      emergency: 5
    },
    recentPayslips: []
  })
  const [loading, setLoading] = useState(true)
  const [currentTime, setCurrentTime] = useState(new Date())

  useEffect(() => {
    loadEmployeeDashboard()
    
    // Update time every minute
    const timer = setInterval(() => {
      setCurrentTime(new Date())
    }, 60000)

    return () => clearInterval(timer)
  }, [user])

  const loadEmployeeDashboard = async () => {
    if (!user?.employee_id) return

    try {
      // Load employee data
      const { data: employee } = await supabase
        .from('employees')
        .select('*')
        .eq('id', user.employee_id)
        .single()

      // Load current month's payroll
      const currentMonth = new Date().toISOString().slice(0, 7)
      const { data: currentPayroll } = await supabase
        .from('payroll_records')
        .select('*')
        .eq('employee_id', user.employee_id)
        .eq('pay_period', currentMonth)
        .single()

      // Load recent payrolls (last 3 months)
      const { data: recentPayrolls } = await supabase
        .from('payroll_records')
        .select('*')
        .eq('employee_id', user.employee_id)
        .order('pay_period', { ascending: false })
        .limit(3)

      // Load recent time records (last 30 days)
      const thirtyDaysAgo = new Date(Date.now() - 30 * 24 * 60 * 60 * 1000).toISOString().slice(0, 10)
      const { data: timeRecords } = await supabase
        .from('time_records')
        .select('*')
        .eq('employee_id', user.employee_id)
        .gte('date', thirtyDaysAgo)
        .order('date', { ascending: false })

      // Load recent payslips
      const { data: recentPayslips } = await supabase
        .from('payroll_records')
        .select('*')
        .eq('employee_id', user.employee_id)
        .eq('status', 'paid')
        .order('pay_period', { ascending: false })
        .limit(5)

      setDashboardData({
        employee,
        currentPayroll,
        recentPayrolls: recentPayrolls || [],
        timeRecords: timeRecords || [],
        leaveBalance: {
          annual: 21 - (timeRecords?.filter(r => r.leave_type === 'annual').length || 0),
          sick: 10 - (timeRecords?.filter(r => r.leave_type === 'sick').length || 0),
          emergency: 5 - (timeRecords?.filter(r => r.leave_type === 'emergency').length || 0)
        },
        recentPayslips: recentPayslips || []
      })

    } catch (error) {
      console.error('Error loading employee dashboard:', error)
    } finally {
      setLoading(false)
    }
  }

  const clockInOut = async (action: 'clock_in' | 'clock_out') => {
    if (!user?.employee_id) return

    const today = new Date().toISOString().slice(0, 10)
    const now = new Date().toTimeString().slice(0, 8)

    try {
      // Check if time record exists for today
      const { data: existingRecord } = await supabase
        .from('time_records')
        .select('*')
        .eq('employee_id', user.employee_id)
        .eq('date', today)
        .single()

      if (action === 'clock_in') {
        if (existingRecord?.clock_in) {
          alert('Already clocked in today')
          return
        }

        const { error } = await supabase
          .from('time_records')
          .insert({
            employee_id: user.employee_id,
            date: today,
            clock_in: now,
            status: 'present',
            hours_worked: 0,
            overtime_hours: 0
          })

        if (error) throw error
      } else {
        if (!existingRecord?.clock_in || existingRecord.clock_out) {
          alert('Must clock in first')
          return
        }

        const clockInTime = new Date(`${today}T${existingRecord.clock_in}`)
        const clockOutTime = new Date(`${today}T${now}`)
        const hoursWorked = (clockOutTime.getTime() - clockInTime.getTime()) / (1000 * 60 * 60)

        const { error } = await supabase
          .from('time_records')
          .update({
            clock_out: now,
            hours_worked: Math.round(hoursWorked * 100) / 100
          })
          .eq('id', existingRecord.id)

        if (error) throw error
      }

      await loadEmployeeDashboard()
      alert(`Successfully ${action.replace('_', 'ed ')}`)

    } catch (error) {
      console.error('Error with clock in/out:', error)
      alert('Error performing time action')
    }
  }

  const getStatusColor = (status: string) => {
    switch (status) {
      case 'present':
        return 'text-green-600 bg-green-100'
      case 'absent':
        return 'text-red-600 bg-red-100'
      case 'leave':
        return 'text-blue-600 bg-blue-100'
      case 'holiday':
        return 'text-purple-600 bg-purple-100'
      default:
        return 'text-gray-600 bg-gray-100'
    }
  }

  const formatPayPeriod = (period: string) => {
    const [year, month] = period.split('-')
    return new Date(parseInt(year), parseInt(month) - 1).toLocaleDateString('en-ZM', {
      year: 'numeric',
      month: 'long'
    })
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
            <h1 className="text-3xl font-bold text-gray-900">
              Welcome, {dashboardData.employee?.first_name}!
            </h1>
            <p className="text-gray-600 mt-1">
              {dashboardData.employee?.designation} - {dashboardData.employee?.department}
            </p>
            <p className="text-sm text-gray-500 mt-1">
              Current time: {currentTime.toLocaleString('en-ZM')}
            </p>
          </div>
          <div className="flex space-x-2">
            <button
              onClick={() => clockInOut('clock_in')}
              className="inline-flex items-center px-4 py-2 border border-transparent text-sm font-medium rounded-md text-white bg-green-600 hover:bg-green-700"
            >
              <Clock className="w-4 h-4 mr-2" />
              Clock In
            </button>
            <button
              onClick={() => clockInOut('clock_out')}
              className="inline-flex items-center px-4 py-2 border border-transparent text-sm font-medium rounded-md text-white bg-red-600 hover:bg-red-700"
            >
              <Clock className="w-4 h-4 mr-2" />
              Clock Out
            </button>
          </div>
        </div>
      </div>

      {/* Quick Stats */}
      <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-6">
        <div className="bg-white rounded-lg shadow-md p-6">
          <div className="flex items-center justify-between">
            <div>
              <p className="text-sm font-medium text-gray-600">Current Salary</p>
              <p className="text-2xl font-bold text-gray-900">
                {formatZMK(dashboardData.employee?.basic_salary || 0)}
              </p>
              <p className="text-sm text-gray-500 mt-1">
                {dashboardData.employee?.salary_type} basis
              </p>
            </div>
            <div className="w-12 h-12 bg-green-100 rounded-full flex items-center justify-center">
              <DollarSign className="w-6 h-6 text-green-600" />
            </div>
          </div>
        </div>

        <div className="bg-white rounded-lg shadow-md p-6">
          <div className="flex items-center justify-between">
            <div>
              <p className="text-sm font-medium text-gray-600">This Month's Pay</p>
              <p className="text-2xl font-bold text-gray-900">
                {formatZMK(dashboardData.currentPayroll?.net_pay || 0)}
              </p>
              <p className="text-sm text-gray-500 mt-1">
                Net pay
              </p>
            </div>
            <div className="w-12 h-12 bg-blue-100 rounded-full flex items-center justify-center">
              <TrendingUp className="w-6 h-6 text-blue-600" />
            </div>
          </div>
        </div>

        <div className="bg-white rounded-lg shadow-md p-6">
          <div className="flex items-center justify-between">
            <div>
              <p className="text-sm font-medium text-gray-600">Hours This Month</p>
              <p className="text-2xl font-bold text-gray-900">
                {dashboardData.timeRecords.reduce((sum, record) => sum + record.hours_worked, 0).toFixed(1)}
              </p>
              <p className="text-sm text-gray-500 mt-1">
                Total hours
              </p>
            </div>
            <div className="w-12 h-12 bg-yellow-100 rounded-full flex items-center justify-center">
              <Clock className="w-6 h-6 text-yellow-600" />
            </div>
          </div>
        </div>

        <div className="bg-white rounded-lg shadow-md p-6">
          <div className="flex items-center justify-between">
            <div>
              <p className="text-sm font-medium text-gray-600">Leave Balance</p>
              <p className="text-2xl font-bold text-gray-900">
                {dashboardData.leaveBalance.annual}
              </p>
              <p className="text-sm text-gray-500 mt-1">
                Annual leave days
              </p>
            </div>
            <div className="w-12 h-12 bg-purple-100 rounded-full flex items-center justify-center">
              <Calendar className="w-6 h-6 text-purple-600" />
            </div>
          </div>
        </div>
      </div>

      {/* Recent Time Records */}
      <div className="bg-white rounded-lg shadow-md p-6">
        <h3 className="text-lg font-semibold text-gray-900 mb-4">Recent Time Records</h3>
        {dashboardData.timeRecords.length === 0 ? (
          <p className="text-gray-500 text-center py-8">No time records found</p>
        ) : (
          <div className="overflow-x-auto">
            <table className="min-w-full divide-y divide-gray-200">
              <thead className="bg-gray-50">
                <tr>
                  <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                    Date
                  </th>
                  <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                    Clock In
                  </th>
                  <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                    Clock Out
                  </th>
                  <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                    Hours
                  </th>
                  <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                    Status
                  </th>
                </tr>
              </thead>
              <tbody className="bg-white divide-y divide-gray-200">
                {dashboardData.timeRecords.slice(0, 10).map((record) => (
                  <tr key={record.id}>
                    <td className="px-6 py-4 whitespace-nowrap text-sm text-gray-900">
                      {new Date(record.date).toLocaleDateString('en-ZM')}
                    </td>
                    <td className="px-6 py-4 whitespace-nowrap text-sm text-gray-900">
                      {record.clock_in || '-'}
                    </td>
                    <td className="px-6 py-4 whitespace-nowrap text-sm text-gray-900">
                      {record.clock_out || '-'}
                    </td>
                    <td className="px-6 py-4 whitespace-nowrap text-sm text-gray-900">
                      {record.hours_worked?.toFixed(1) || '0.0'}
                    </td>
                    <td className="px-6 py-4 whitespace-nowrap">
                      <span className={`inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium ${getStatusColor(record.status)}`}>
                        {record.status}
                      </span>
                    </td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
        )}
      </div>

      {/* Recent Payslips */}
      <div className="bg-white rounded-lg shadow-md p-6">
        <div className="flex items-center justify-between mb-4">
          <h3 className="text-lg font-semibold text-gray-900">Recent Payslips</h3>
          <FileText className="w-5 h-5 text-gray-400" />
        </div>
        {dashboardData.recentPayslips.length === 0 ? (
          <p className="text-gray-500 text-center py-8">No payslips available</p>
        ) : (
          <div className="space-y-4">
            {dashboardData.recentPayslips.map((payslip) => (
              <div key={payslip.id} className="flex items-center justify-between p-4 border border-gray-200 rounded-lg">
                <div>
                  <h4 className="font-medium text-gray-900">
                    {formatPayPeriod(payslip.pay_period)}
                  </h4>
                  <p className="text-sm text-gray-500">
                    Net Pay: {formatZMK(payslip.net_pay)}
                  </p>
                </div>
                <div className="flex space-x-2">
                  <button className="inline-flex items-center px-3 py-1 border border-gray-300 text-xs font-medium rounded text-gray-700 bg-white hover:bg-gray-50">
                    <Eye className="w-3 h-3 mr-1" />
                    View
                  </button>
                  <button className="inline-flex items-center px-3 py-1 border border-gray-300 text-xs font-medium rounded text-gray-700 bg-white hover:bg-gray-50">
                    <Download className="w-3 h-3 mr-1" />
                    Download
                  </button>
                </div>
              </div>
            ))}
          </div>
        )}
      </div>
    </div>
  )
}

export default EmployeeDashboard