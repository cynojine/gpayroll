import React, { useState, useEffect } from 'react'
import { useForm } from 'react-hook-form'
import { toast } from 'react-toastify'
import { 
  Clock, 
  Calendar, 
  CheckCircle, 
  AlertCircle,
  XCircle,
  Play,
  Pause,
  Settings as SettingsIcon,
  Download,
  Filter,
  Search,
  Users
} from 'lucide-react'
import { supabase } from '../../lib/supabase'
import { formatZMK } from '../../utils/payrollCalculations'

interface TimeRecord {
  id: string
  employee_id: string
  date: string
  clock_in?: string
  clock_out?: string
  break_start?: string
  break_end?: string
  hours_worked: number
  overtime_hours: number
  leave_type?: string
  status: 'present' | 'absent' | 'leave' | 'holiday'
  created_at: string
  employee?: any
}

interface ClockAction {
  type: 'clock_in' | 'clock_out' | 'break_start' | 'break_end'
  timestamp: string
}

const TimeAttendance: React.FC = () => {
  const [timeRecords, setTimeRecords] = useState<TimeRecord[]>([])
  const [selectedDate, setSelectedDate] = useState(new Date().toISOString().slice(0, 10))
  const [filterStatus, setFilterStatus] = useState('')
  const [searchTerm, setSearchTerm] = useState('')
  const [loading, setLoading] = useState(true)
  const [employees, setEmployees] = useState<any[]>([])
  const [showManualEntry, setShowManualEntry] = useState(false)

  useEffect(() => {
    loadTimeRecords()
    loadEmployees()
  }, [selectedDate])

  const loadTimeRecords = async () => {
    try {
      const { data, error } = await supabase
        .from('time_records')
        .select(`
          *,
          employees!inner(*)
        `)
        .eq('date', selectedDate)
        .order('created_at', { ascending: false })

      if (error) throw error
      setTimeRecords(data || [])
    } catch (error) {
      console.error('Error loading time records:', error)
      toast.error('Failed to load time records')
    } finally {
      setLoading(false)
    }
  }

  const loadEmployees = async () => {
    try {
      const { data, error } = await supabase
        .from('employees')
        .select('*')
        .eq('status', 'active')
        .order('first_name')

      if (error) throw error
      setEmployees(data || [])
    } catch (error) {
      console.error('Error loading employees:', error)
    }
  }

  const clockInOut = async (employeeId: string, action: 'clock_in' | 'clock_out') => {
    try {
      const now = new Date()
      const timeString = now.toTimeString().slice(0, 8)
      const dateString = now.toISOString().slice(0, 10)

      // Check if time record exists for today
      const { data: existingRecord } = await supabase
        .from('time_records')
        .select('*')
        .eq('employee_id', employeeId)
        .eq('date', dateString)
        .single()

      if (action === 'clock_in') {
        if (existingRecord?.clock_in) {
          toast.error('Already clocked in today')
          return
        }

        const { error } = await supabase
          .from('time_records')
          .insert({
            employee_id: employeeId,
            date: dateString,
            clock_in: timeString,
            status: 'present',
            hours_worked: 0,
            overtime_hours: 0
          })

        if (error) throw error
        toast.success('Clocked in successfully')
      } else {
        if (!existingRecord?.clock_in || existingRecord.clock_out) {
          toast.error('Must clock in first')
          return
        }

        const clockInTime = new Date(`${dateString}T${existingRecord.clock_in}`)
        const clockOutTime = new Date(`${dateString}T${timeString}`)
        const hoursWorked = (clockOutTime.getTime() - clockInTime.getTime()) / (1000 * 60 * 60)

        const { error } = await supabase
          .from('time_records')
          .update({
            clock_out: timeString,
            hours_worked: Math.round(hoursWorked * 100) / 100
          })
          .eq('id', existingRecord.id)

        if (error) throw error
        toast.success('Clocked out successfully')
      }

      loadTimeRecords()
    } catch (error) {
      console.error('Error with clock in/out:', error)
      toast.error('Failed to perform time action')
    }
  }

  const approveTimeRecord = async (recordId: string, approved: boolean) => {
    try {
      const { error } = await supabase
        .from('time_records')
        .update({ 
          status: approved ? 'approved' : 'rejected',
          approved_by: 'current_user_id', // You would get this from auth
          approved_at: new Date().toISOString()
        })
        .eq('id', recordId)

      if (error) throw error
      toast.success(`Time record ${approved ? 'approved' : 'rejected'}`)
      loadTimeRecords()
    } catch (error) {
      console.error('Error approving time record:', error)
      toast.error('Failed to update time record')
    }
  }

  const filteredRecords = timeRecords.filter(record => {
    const matchesSearch = 
      record.employees?.first_name.toLowerCase().includes(searchTerm.toLowerCase()) ||
      record.employees?.last_name.toLowerCase().includes(searchTerm.toLowerCase()) ||
      record.employees?.employee_id.toLowerCase().includes(searchTerm.toLowerCase())

    const matchesStatus = !filterStatus || record.status === filterStatus

    return matchesSearch && matchesStatus
  })

  const getStatusIcon = (status: string) => {
    switch (status) {
      case 'present':
        return <CheckCircle className="w-4 h-4 text-green-500" />
      case 'absent':
        return <XCircle className="w-4 h-4 text-red-500" />
      case 'leave':
        return <Calendar className="w-4 h-4 text-blue-500" />
      case 'holiday':
        return <AlertCircle className="w-4 h-4 text-purple-500" />
      default:
        return <Clock className="w-4 h-4 text-gray-500" />
    }
  }

  const getStatusColor = (status: string) => {
    switch (status) {
      case 'present':
        return 'bg-green-100 text-green-800'
      case 'absent':
        return 'bg-red-100 text-red-800'
      case 'leave':
        return 'bg-blue-100 text-blue-800'
      case 'holiday':
        return 'bg-purple-100 text-purple-800'
      default:
        return 'bg-gray-100 text-gray-800'
    }
  }

  const exportTimeRecords = () => {
    const csvContent = [
      ['Employee', 'Employee ID', 'Date', 'Clock In', 'Clock Out', 'Hours Worked', 'Status'].join(','),
      ...filteredRecords.map(record => [
        `${record.employees?.first_name} ${record.employees?.last_name}`,
        record.employees?.employee_id,
        record.date,
        record.clock_in || '',
        record.clock_out || '',
        record.hours_worked.toString(),
        record.status
      ].join(','))
    ].join('\n')

    const blob = new Blob([csvContent], { type: 'text/csv' })
    const url = window.URL.createObjectURL(blob)
    const link = document.createElement('a')
    link.href = url
    link.download = `time-records-${selectedDate}.csv`
    link.click()
    window.URL.revokeObjectURL(url)
    toast.success('Time records exported successfully')
  }

  if (loading) {
    return (
      <div className="flex items-center justify-center min-h-64">
        <div className="animate-spin rounded-full h-32 w-32 border-b-2 border-green-600"></div>
      </div>
    )
  }

  return (
    <div className="space-y-6">
      {/* Header */}
      <div className="flex flex-col sm:flex-row sm:items-center sm:justify-between">
        <div>
          <h1 className="text-2xl font-bold text-gray-900">Time & Attendance</h1>
          <p className="text-gray-600 mt-1">Track employee time, approve records, and manage attendance</p>
        </div>
        <div className="mt-4 sm:mt-0 flex space-x-2">
          <button
            onClick={() => setShowManualEntry(!showManualEntry)}
            className="inline-flex items-center px-4 py-2 border border-gray-300 text-sm font-medium rounded-md text-gray-700 bg-white hover:bg-gray-50"
          >
            <SettingsIcon className="w-4 h-4 mr-2" />
            Manual Entry
          </button>
          <button
            onClick={exportTimeRecords}
            className="inline-flex items-center px-4 py-2 border border-transparent text-sm font-medium rounded-md text-white bg-green-600 hover:bg-green-700"
          >
            <Download className="w-4 h-4 mr-2" />
            Export
          </button>
        </div>
      </div>

      {/* Controls */}
      <div className="bg-white rounded-lg shadow-md p-6">
        <div className="grid grid-cols-1 md:grid-cols-4 gap-4">
          <div>
            <label className="block text-sm font-medium text-gray-700 mb-2">
              Date
            </label>
            <input
              type="date"
              value={selectedDate}
              onChange={(e) => setSelectedDate(e.target.value)}
              className="w-full border border-gray-300 rounded-lg px-3 py-2 focus:ring-green-500 focus:border-green-500"
            />
          </div>

          <div className="relative">
            <Search className="absolute left-3 top-3 h-4 w-4 text-gray-400" />
            <input
              type="text"
              placeholder="Search employees..."
              value={searchTerm}
              onChange={(e) => setSearchTerm(e.target.value)}
              className="pl-10 w-full border border-gray-300 rounded-lg px-3 py-2 focus:ring-green-500 focus:border-green-500"
            />
          </div>

          <div>
            <select
              value={filterStatus}
              onChange={(e) => setFilterStatus(e.target.value)}
              className="w-full border border-gray-300 rounded-lg px-3 py-2 focus:ring-green-500 focus:border-green-500"
            >
              <option value="">All Status</option>
              <option value="present">Present</option>
              <option value="absent">Absent</option>
              <option value="leave">On Leave</option>
              <option value="holiday">Holiday</option>
            </select>
          </div>

          <div className="flex items-center space-x-2 pt-6">
            <span className="text-sm text-gray-600">
              {filteredRecords.length} records
            </span>
          </div>
        </div>
      </div>

      {/* Quick Clock In/Out */}
      <div className="bg-white rounded-lg shadow-md p-6">
        <h3 className="text-lg font-semibold text-gray-900 mb-4">Quick Actions</h3>
        <div className="grid grid-cols-2 md:grid-cols-4 lg:grid-cols-6 gap-4">
          {employees.slice(0, 12).map(employee => {
            const todayRecord = timeRecords.find(r => 
              r.employee_id === employee.id && r.date === selectedDate
            )
            const isClockedIn = todayRecord?.clock_in && !todayRecord?.clock_out

            return (
              <div key={employee.id} className="text-center">
                <div className="w-16 h-16 bg-green-100 rounded-full flex items-center justify-center mx-auto mb-2">
                  <Users className="w-6 h-6 text-green-600" />
                </div>
                <p className="text-sm font-medium text-gray-900 truncate">
                  {employee.first_name}
                </p>
                <button
                  onClick={() => clockInOut(employee.id, isClockedIn ? 'clock_out' : 'clock_in')}
                  className={`mt-2 px-3 py-1 text-xs font-medium rounded ${
                    isClockedIn
                      ? 'bg-red-100 text-red-700 hover:bg-red-200'
                      : 'bg-green-100 text-green-700 hover:bg-green-200'
                  }`}
                >
                  {isClockedIn ? 'Clock Out' : 'Clock In'}
                </button>
              </div>
            )
          })}
        </div>
      </div>

      {/* Time Records Table */}
      <div className="bg-white rounded-lg shadow-md overflow-hidden">
        <div className="overflow-x-auto">
          <table className="min-w-full divide-y divide-gray-200">
            <thead className="bg-gray-50">
              <tr>
                <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                  Employee
                </th>
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
                  Hours Worked
                </th>
                <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                  Status
                </th>
                <th className="px-6 py-3 text-right text-xs font-medium text-gray-500 uppercase tracking-wider">
                  Actions
                </th>
              </tr>
            </thead>
            <tbody className="bg-white divide-y divide-gray-200">
              {filteredRecords.map((record) => (
                <tr key={record.id} className="hover:bg-gray-50">
                  <td className="px-6 py-4 whitespace-nowrap">
                    <div className="flex items-center">
                      <div className="w-10 h-10 bg-green-100 rounded-full flex items-center justify-center">
                        <Users className="w-5 h-5 text-green-600" />
                      </div>
                      <div className="ml-4">
                        <div className="text-sm font-medium text-gray-900">
                          {record.employees?.first_name} {record.employees?.last_name}
                        </div>
                        <div className="text-sm text-gray-500">
                          {record.employees?.employee_id}
                        </div>
                      </div>
                    </div>
                  </td>
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
                    {record.hours_worked.toFixed(1)}h
                  </td>
                  <td className="px-6 py-4 whitespace-nowrap">
                    <div className="flex items-center">
                      {getStatusIcon(record.status)}
                      <span className={`ml-2 inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium ${getStatusColor(record.status)}`}>
                        {record.status}
                      </span>
                    </div>
                  </td>
                  <td className="px-6 py-4 whitespace-nowrap text-right text-sm font-medium">
                    <div className="flex justify-end space-x-2">
                      {record.status !== 'approved' && record.status !== 'rejected' && (
                        <>
                          <button
                            onClick={() => approveTimeRecord(record.id, true)}
                            className="text-green-600 hover:text-green-900"
                            title="Approve"
                          >
                            <CheckCircle className="w-4 h-4" />
                          </button>
                          <button
                            onClick={() => approveTimeRecord(record.id, false)}
                            className="text-red-600 hover:text-red-900"
                            title="Reject"
                          >
                            <XCircle className="w-4 h-4" />
                          </button>
                        </>
                      )}
                    </div>
                  </td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>

        {filteredRecords.length === 0 && (
          <div className="text-center py-12">
            <Clock className="mx-auto h-12 w-12 text-gray-400" />
            <h3 className="mt-2 text-sm font-medium text-gray-900">No time records found</h3>
            <p className="mt-1 text-sm text-gray-500">
              {searchTerm || filterStatus
                ? 'Try adjusting your filters'
                : `No time records for ${new Date(selectedDate).toLocaleDateString('en-ZM')}`}
            </p>
          </div>
        )}
      </div>

      {/* Attendance Summary */}
      <div className="grid grid-cols-1 md:grid-cols-4 gap-6">
        <div className="bg-white rounded-lg shadow-md p-6">
          <div className="flex items-center">
            <div className="w-12 h-12 bg-green-100 rounded-full flex items-center justify-center">
              <CheckCircle className="w-6 h-6 text-green-600" />
            </div>
            <div className="ml-4">
              <p className="text-sm font-medium text-gray-600">Present</p>
              <p className="text-2xl font-bold text-gray-900">
                {timeRecords.filter(r => r.status === 'present').length}
              </p>
            </div>
          </div>
        </div>

        <div className="bg-white rounded-lg shadow-md p-6">
          <div className="flex items-center">
            <div className="w-12 h-12 bg-red-100 rounded-full flex items-center justify-center">
              <XCircle className="w-6 h-6 text-red-600" />
            </div>
            <div className="ml-4">
              <p className="text-sm font-medium text-gray-600">Absent</p>
              <p className="text-2xl font-bold text-gray-900">
                {timeRecords.filter(r => r.status === 'absent').length}
              </p>
            </div>
          </div>
        </div>

        <div className="bg-white rounded-lg shadow-md p-6">
          <div className="flex items-center">
            <div className="w-12 h-12 bg-blue-100 rounded-full flex items-center justify-center">
              <Calendar className="w-6 h-6 text-blue-600" />
            </div>
            <div className="ml-4">
              <p className="text-sm font-medium text-gray-600">On Leave</p>
              <p className="text-2xl font-bold text-gray-900">
                {timeRecords.filter(r => r.status === 'leave').length}
              </p>
            </div>
          </div>
        </div>

        <div className="bg-white rounded-lg shadow-md p-6">
          <div className="flex items-center">
            <div className="w-12 h-12 bg-yellow-100 rounded-full flex items-center justify-center">
              <Clock className="w-6 h-6 text-yellow-600" />
            </div>
            <div className="ml-4">
              <p className="text-sm font-medium text-gray-600">Total Hours</p>
              <p className="text-2xl font-bold text-gray-900">
                {timeRecords.reduce((sum, r) => sum + r.hours_worked, 0).toFixed(1)}h
              </p>
            </div>
          </div>
        </div>
      </div>
    </div>
  )
}

export default TimeAttendance