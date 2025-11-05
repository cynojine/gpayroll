import React, { useState, useEffect } from 'react'
import { useAuth } from '../../context/AuthContext'
import { supabase } from '../../lib/supabase'
import { formatZMK } from '../../utils/payrollCalculations'
import { 
  Users, 
  FileText, 
  Clock, 
  Calendar,
  UserPlus,
  DollarSign,
  AlertTriangle,
  CheckCircle2,
  TrendingUp,
  Settings
} from 'lucide-react'

interface HRStats {
  totalEmployees: number
  pendingTimeRecords: number
  pendingLeaveRequests: number
  newHiresThisMonth: number
  attendanceRate: number
  overdueTimeRecords: number
}

interface PendingRequest {
  id: string
  type: 'time_record' | 'leave_request' | 'expense_claim'
  employee_name: string
  description: string
  amount?: number
  days?: number
  submitted_date: string
  status: string
}

const HRDashboard: React.FC = () => {
  const { user } = useAuth()
  const [stats, setStats] = useState<HRStats>({
    totalEmployees: 0,
    pendingTimeRecords: 0,
    pendingLeaveRequests: 0,
    newHiresThisMonth: 0,
    attendanceRate: 0,
    overdueTimeRecords: 0
  })
  const [pendingRequests, setPendingRequests] = useState<PendingRequest[]>([])
  const [loading, setLoading] = useState(true)

  useEffect(() => {
    loadHRDashboardData()
  }, [])

  const loadHRDashboardData = async () => {
    try {
      // Load employee stats
      const { data: employees } = await supabase
        .from('employees')
        .select('*')

      const activeEmployees = employees?.filter(emp => emp.status === 'active') || []

      // Load new hires this month
      const currentMonth = new Date().toISOString().slice(0, 7)
      const newHiresThisMonth = employees?.filter(emp => 
        emp.start_date.startsWith(currentMonth)
      ).length || 0

      // Load pending time records
      const { data: timeRecords } = await supabase
        .from('time_records')
        .select(`
          *,
          employees!inner(first_name, last_name)
        `)
        .eq('status', 'pending')

      // Load pending leave requests
      const { data: leaveRequests } = await supabase
        .from('leave_requests')
        .select(`
          *,
          employees!inner(first_name, last_name)
        `)
        .eq('status', 'pending')

      // Load overdue time records
      const lastWeek = new Date(Date.now() - 7 * 24 * 60 * 60 * 1000).toISOString()
      const overdueTimeRecords = timeRecords?.filter(record => 
        record.date < lastWeek
      ).length || 0

      // Calculate attendance rate (simplified)
      const currentMonthStart = new Date()
      currentMonthStart.setDate(1)
      const { data: monthTimeRecords } = await supabase
        .from('time_records')
        .select('*')
        .gte('date', currentMonthStart.toISOString().slice(0, 10))

      const totalWorkDays = activeEmployees.length * 22 // Assuming 22 work days per month
      const actualAttendances = monthTimeRecords?.filter(record => 
        record.status === 'present'
      ).length || 0
      const attendanceRate = totalWorkDays > 0 ? (actualAttendances / totalWorkDays) * 100 : 0

      setStats({
        totalEmployees: activeEmployees.length,
        pendingTimeRecords: timeRecords?.length || 0,
        pendingLeaveRequests: leaveRequests?.length || 0,
        newHiresThisMonth,
        attendanceRate,
        overdueTimeRecords
      })

      // Combine pending requests
      const combinedRequests: PendingRequest[] = [
        ...(timeRecords?.map(record => ({
          id: record.id,
          type: 'time_record' as const,
          employee_name: `${record.employees.first_name} ${record.employees.last_name}`,
          description: `Time record for ${record.date}`,
          submitted_date: record.created_at,
          status: record.status
        })) || []),
        ...(leaveRequests?.map(request => ({
          id: request.id,
          type: 'leave_request' as const,
          employee_name: `${request.employees.first_name} ${request.employees.last_name}`,
          description: `${request.leave_type} leave request`,
          days: request.days,
          submitted_date: request.created_at,
          status: request.status
        })) || [])
      ]

      setPendingRequests(combinedRequests.sort((a, b) => 
        new Date(b.submitted_date).getTime() - new Date(a.submitted_date).getTime()
      ))

    } catch (error) {
      console.error('Error loading HR dashboard data:', error)
    } finally {
      setLoading(false)
    }
  }

  const approveRequest = async (id: string, type: string) => {
    try {
      const table = type === 'time_record' ? 'time_records' : 'leave_requests'
      const { error } = await supabase
        .from(table)
        .update({ 
          status: 'approved',
          approved_by: user?.id,
          approved_at: new Date().toISOString()
        })
        .eq('id', id)

      if (error) throw error

      await loadHRDashboardData()
      // You might want to show a toast notification here
    } catch (error) {
      console.error('Error approving request:', error)
    }
  }

  const rejectRequest = async (id: string, type: string, reason?: string) => {
    try {
      const table = type === 'time_record' ? 'time_records' : 'leave_requests'
      const { error } = await supabase
        .from(table)
        .update({ 
          status: 'rejected',
          rejection_reason: reason,
          approved_by: user?.id,
          approved_at: new Date().toISOString()
        })
        .eq('id', id)

      if (error) throw error

      await loadHRDashboardData()
      // You might want to show a toast notification here
    } catch (error) {
      console.error('Error rejecting request:', error)
    }
  }

  const getRequestIcon = (type: string) => {
    switch (type) {
      case 'time_record':
        return <Clock className="w-5 h-5 text-blue-600" />
      case 'leave_request':
        return <Calendar className="w-5 h-5 text-green-600" />
      case 'expense_claim':
        return <FileText className="w-5 h-5 text-purple-600" />
      default:
        return <AlertTriangle className="w-5 h-5 text-orange-600" />
    }
  }

  const formatDate = (dateString: string) => {
    return new Date(dateString).toLocaleDateString('en-ZM', {
      year: 'numeric',
      month: 'short',
      day: 'numeric'
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
            <h1 className="text-3xl font-bold text-gray-900">HR Dashboard</h1>
            <p className="text-gray-600 mt-1">
              Manage employees, approve requests, and oversee HR operations.
            </p>
          </div>
          <div className="flex space-x-2">
            <button className="inline-flex items-center px-4 py-2 border border-transparent text-sm font-medium rounded-md text-white bg-green-600 hover:bg-green-700">
              <UserPlus className="w-4 h-4 mr-2" />
              Add Employee
            </button>
          </div>
        </div>
      </div>

      {/* Stats Cards */}
      <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
        <div className="bg-white rounded-lg shadow-md p-6 hover:shadow-lg transition-shadow">
          <div className="flex items-center justify-between">
            <div>
              <p className="text-sm font-medium text-gray-600">Total Employees</p>
              <p className="text-3xl font-bold text-gray-900">{stats.totalEmployees}</p>
              <p className="text-sm text-green-600 mt-1">
                {stats.newHiresThisMonth} new this month
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
              <p className="text-sm font-medium text-gray-600">Pending Approvals</p>
              <p className="text-3xl font-bold text-gray-900">
                {stats.pendingTimeRecords + stats.pendingLeaveRequests}
              </p>
              <p className="text-sm text-orange-600 mt-1">
                {stats.overdueTimeRecords} overdue
              </p>
            </div>
            <div className="w-12 h-12 bg-yellow-100 rounded-full flex items-center justify-center">
              <AlertTriangle className="w-6 h-6 text-yellow-600" />
            </div>
          </div>
        </div>

        <div className="bg-white rounded-lg shadow-md p-6 hover:shadow-lg transition-shadow">
          <div className="flex items-center justify-between">
            <div>
              <p className="text-sm font-medium text-gray-600">Attendance Rate</p>
              <p className="text-3xl font-bold text-gray-900">
                {stats.attendanceRate.toFixed(1)}%
              </p>
              <p className="text-sm text-gray-500 mt-1">
                This month
              </p>
            </div>
            <div className="w-12 h-12 bg-green-100 rounded-full flex items-center justify-center">
              <TrendingUp className="w-6 h-6 text-green-600" />
            </div>
          </div>
        </div>
      </div>

      {/* Pending Requests */}
      <div className="bg-white rounded-lg shadow-md p-6">
        <div className="flex items-center justify-between mb-6">
          <h3 className="text-lg font-semibold text-gray-900">Pending Requests</h3>
          <span className="text-sm text-gray-500">
            {pendingRequests.length} requests pending approval
          </span>
        </div>

        {pendingRequests.length === 0 ? (
          <div className="text-center py-12">
            <CheckCircle2 className="w-12 h-12 text-green-500 mx-auto mb-4" />
            <p className="text-gray-500">No pending requests</p>
          </div>
        ) : (
          <div className="space-y-4">
            {pendingRequests.map((request) => (
              <div key={request.id} className="border border-gray-200 rounded-lg p-4">
                <div className="flex items-center justify-between">
                  <div className="flex items-center space-x-4">
                    <div className="w-10 h-10 bg-gray-100 rounded-full flex items-center justify-center">
                      {getRequestIcon(request.type)}
                    </div>
                    <div>
                      <h4 className="font-medium text-gray-900">{request.employee_name}</h4>
                      <p className="text-sm text-gray-600">{request.description}</p>
                      {request.amount && (
                        <p className="text-sm text-gray-500">{formatZMK(request.amount)}</p>
                      )}
                      {request.days && (
                        <p className="text-sm text-gray-500">{request.days} days</p>
                      )}
                      <p className="text-xs text-gray-400">
                        Submitted: {formatDate(request.submitted_date)}
                      </p>
                    </div>
                  </div>
                  <div className="flex space-x-2">
                    <button
                      onClick={() => approveRequest(request.id, request.type)}
                      className="inline-flex items-center px-3 py-1 border border-transparent text-xs font-medium rounded text-green-700 bg-green-100 hover:bg-green-200"
                    >
                      <CheckCircle2 className="w-3 h-3 mr-1" />
                      Approve
                    </button>
                    <button
                      onClick={() => rejectRequest(request.id, request.type)}
                      className="inline-flex items-center px-3 py-1 border border-transparent text-xs font-medium rounded text-red-700 bg-red-100 hover:bg-red-200"
                    >
                      <AlertTriangle className="w-3 h-3 mr-1" />
                      Reject
                    </button>
                  </div>
                </div>
              </div>
            ))}
          </div>
        )}
      </div>

      {/* Quick Actions */}
      <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-4">
        <button className="flex items-center justify-center space-x-2 p-4 bg-white rounded-lg shadow-md hover:shadow-lg transition-shadow">
          <UserPlus className="w-5 h-5 text-blue-600" />
          <span className="text-sm font-medium text-gray-900">Add Employee</span>
        </button>
        <button className="flex items-center justify-center space-x-2 p-4 bg-white rounded-lg shadow-md hover:shadow-lg transition-shadow">
          <Calendar className="w-5 h-5 text-green-600" />
          <span className="text-sm font-medium text-gray-900">Manage Leave</span>
        </button>
        <button className="flex items-center justify-center space-x-2 p-4 bg-white rounded-lg shadow-md hover:shadow-lg transition-shadow">
          <Clock className="w-5 h-5 text-purple-600" />
          <span className="text-sm font-medium text-gray-900">Review Time</span>
        </button>
        <button className="flex items-center justify-center space-x-2 p-4 bg-white rounded-lg shadow-md hover:shadow-lg transition-shadow">
          <Settings className="w-5 h-5 text-orange-600" />
          <span className="text-sm font-medium text-gray-900">HR Settings</span>
        </button>
      </div>
    </div>
  )
}

export default HRDashboard