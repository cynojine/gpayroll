import React, { useState, useEffect, useRef } from 'react'
import { toast } from 'react-toastify'
import jsPDF from 'jspdf'
import html2canvas from 'html2canvas'
import * as XLSX from 'xlsx'
import { 
  Download, 
  Eye, 
  Edit, 
  FileText, 
  Printer,
  Mail,
  Settings,
  Calendar,
  User,
  Building2,
  DollarSign
} from 'lucide-react'
import { supabase } from '../../lib/supabase'
import { formatZMK, calculatePayroll } from '../../utils/payrollCalculations'
import { useCompany } from '../../context/CompanyContext'

interface PayslipData {
  id: string
  employee_id: string
  pay_period: string
  employee: any
  payroll: any
  created_at: string
}

interface PayslipSettings {
  company_logo?: string
  show_company_logo: boolean
  show_employee_photo: boolean
  include_nrc: boolean
  include_tpin: boolean
  layout: 'standard' | 'compact' | 'detailed'
  colors: {
    primary: string
    secondary: string
    accent: string
  }
}

const PayslipGenerator: React.FC = () => {
  const { company } = useCompany()
  const [payslips, setPayslips] = useState<PayslipData[]>([])
  const [selectedPayslips, setSelectedPayslips] = useState<string[]>([])
  const [loading, setLoading] = useState(true)
  const [showPreview, setShowPreview] = useState(false)
  const [selectedPayslip, setSelectedPayslip] = useState<PayslipData | null>(null)
  const [showSettings, setShowSettings] = useState(false)
  const [settings, setSettings] = useState<PayslipSettings>({
    show_company_logo: true,
    show_employee_photo: false,
    include_nrc: true,
    include_tpin: true,
    layout: 'standard',
    colors: {
      primary: '#006A4E',
      secondary: '#EF7D00',
      accent: '#DE2C17'
    }
  })
  
  const payslipRef = useRef<HTMLDivElement>(null)

  useEffect(() => {
    loadPayslips()
  }, [])

  const loadPayslips = async () => {
    try {
      const { data, error } = await supabase
        .from('payroll_records')
        .select(`
          *,
          employees!inner(*)
        `)
        .eq('status', 'paid')
        .order('pay_period', { ascending: false })

      if (error) throw error

      const formattedPayslips = data?.map(record => ({
        id: record.id,
        employee_id: record.employee_id,
        pay_period: record.pay_period,
        employee: record.employees,
        payroll: record,
        created_at: record.created_at
      })) || []

      setPayslips(formattedPayslips)
    } catch (error) {
      console.error('Error loading payslips:', error)
      toast.error('Failed to load payslips')
    } finally {
      setLoading(false)
    }
  }

  const generatePayslip = async (payslip: PayslipData) => {
    setSelectedPayslip(payslip)
    setShowPreview(true)
  }

  const downloadSinglePayslip = async (payslip: PayslipData) => {
    try {
      const element = payslipRef.current
      if (!element) return

      // Temporarily show the payslip
      setSelectedPayslip(payslip)
      setShowPreview(true)

      // Wait for render
      setTimeout(async () => {
        if (element) {
          const canvas = await html2canvas(element, {
            scale: 2,
            useCORS: true,
            allowTaint: true
          })

          const imgData = canvas.toDataURL('image/png')
          const pdf = new jsPDF('p', 'mm', 'a4')
          const imgWidth = 210
          const pageHeight = 295
          const imgHeight = (canvas.height * imgWidth) / canvas.width
          let heightLeft = imgHeight

          let position = 0

          pdf.addImage(imgData, 'PNG', 0, position, imgWidth, imgHeight)
          heightLeft -= pageHeight

          while (heightLeft >= 0) {
            position = heightLeft - imgHeight
            pdf.addPage()
            pdf.addImage(imgData, 'PNG', 0, position, imgWidth, imgHeight)
            heightLeft -= pageHeight
          }

          pdf.save(`Payslip_${payslip.employee.first_name}_${payslip.employee.last_name}_${payslip.pay_period}.pdf`)
          toast.success('Payslip downloaded successfully')
        }

        setShowPreview(false)
      }, 500)
    } catch (error) {
      console.error('Error downloading payslip:', error)
      toast.error('Failed to download payslip')
      setShowPreview(false)
    }
  }

  const downloadBulkPayslips = async () => {
    if (selectedPayslips.length === 0) {
      toast.error('Please select payslips to export')
      return
    }

    try {
      toast.info('Generating PDFs... This may take a moment')

      // Create a zip file or individual downloads
      const selectedPayslipData = payslips.filter(p => selectedPayslips.includes(p.id))

      for (const payslip of selectedPayslipData) {
        await downloadSinglePayslip(payslip)
        // Small delay between downloads to prevent overwhelming the browser
        await new Promise(resolve => setTimeout(resolve, 1000))
      }

      toast.success(`Downloaded ${selectedPayslips.length} payslips successfully`)
      setSelectedPayslips([])
    } catch (error) {
      console.error('Error bulk downloading payslips:', error)
      toast.error('Failed to download payslips')
    }
  }

  const exportToExcel = async () => {
    try {
      const ws = XLSX.utils.json_to_sheet(
        payslips.map(payslip => ({
          'Employee ID': payslip.employee.employee_id,
          'Name': `${payslip.employee.first_name} ${payslip.employee.last_name}`,
          'Department': payslip.employee.department,
          'Designation': payslip.employee.designation,
          'Pay Period': payslip.pay_period,
          'Basic Pay': payslip.payroll.basic_pay,
          'Allowances': payslip.payroll.allowances,
          'Bonuses': payslip.payroll.bonuses,
          'Gross Pay': payslip.payroll.gross_pay,
          'NAPSA': payslip.payroll.napsa,
          'NHIS': payslip.payroll.nhis,
          'Tax': payslip.payroll.tax,
          'Other Deductions': payslip.payroll.other_deductions,
          'Total Deductions': payslip.payroll.total_deductions,
          'Net Pay': payslip.payroll.net_pay,
          'Pay Date': new Date(payslip.payroll.pay_date).toLocaleDateString()
        }))
      )

      const wb = XLSX.utils.book_new()
      XLSX.utils.book_append_sheet(wb, ws, 'Payslips')

      XLSX.writeFile(wb, `Payslips_${new Date().toISOString().slice(0, 7)}.xlsx`)
      toast.success('Payslips exported to Excel successfully')
    } catch (error) {
      console.error('Error exporting to Excel:', error)
      toast.error('Failed to export to Excel')
    }
  }

  const formatPayPeriod = (period: string) => {
    const [year, month] = period.split('-')
    return new Date(parseInt(year), parseInt(month) - 1).toLocaleDateString('en-ZM', {
      year: 'numeric',
      month: 'long'
    })
  }

  const PayslipPreview = ({ payslip }: { payslip: PayslipData }) => (
    <div 
      ref={payslipRef}
      className={`bg-white p-8 mx-auto ${settings.layout === 'standard' ? 'max-w-4xl' : 'max-w-6xl'}`}
      style={{ 
        fontFamily: 'Arial, sans-serif',
        border: '1px solid #e5e7eb',
        borderRadius: '8px'
      }}
    >
      {/* Header */}
      <div className="text-center mb-8">
        {settings.show_company_logo && (
          <div className="mb-4">
            <Building2 className="w-16 h-16 mx-auto text-gray-600" />
          </div>
        )}
        <h1 className="text-2xl font-bold" style={{ color: settings.colors.primary }}>
          {company?.company_name || 'Your Company'}
        </h1>
        <p className="text-gray-600">
          {company?.registration_number && `Registration: ${company.registration_number}`}
        </p>
        <p className="text-gray-600">
          {company?.address}
        </p>
        <div 
          className="h-2 mx-auto mt-4 rounded"
          style={{ 
            background: `linear-gradient(90deg, ${settings.colors.primary}, ${settings.colors.secondary}, ${settings.colors.accent}, #111827)` 
          }}
        />
      </div>

      <div className="grid grid-cols-1 lg:grid-cols-2 gap-8 mb-8">
        {/* Employee Information */}
        <div>
          <h3 className="text-lg font-semibold mb-4 text-gray-900">Employee Information</h3>
          <div className="space-y-2">
            <div className="flex justify-between">
              <span className="text-gray-600">Name:</span>
              <span className="font-medium">{payslip.employee.first_name} {payslip.employee.last_name}</span>
            </div>
            <div className="flex justify-between">
              <span className="text-gray-600">Employee ID:</span>
              <span className="font-medium">{payslip.employee.employee_id}</span>
            </div>
            <div className="flex justify-between">
              <span className="text-gray-600">Department:</span>
              <span className="font-medium">{payslip.employee.department}</span>
            </div>
            <div className="flex justify-between">
              <span className="text-gray-600">Designation:</span>
              <span className="font-medium">{payslip.employee.designation}</span>
            </div>
            {settings.include_tpin && (
              <div className="flex justify-between">
                <span className="text-gray-600">TPIN:</span>
                <span className="font-medium">{payslip.employee.tpin}</span>
              </div>
            )}
            {settings.include_nrc && (
              <div className="flex justify-between">
                <span className="text-gray-600">NRC:</span>
                <span className="font-medium">{payslip.employee.nrc}</span>
              </div>
            )}
          </div>
        </div>

        {/* Pay Information */}
        <div>
          <h3 className="text-lg font-semibold mb-4 text-gray-900">Pay Information</h3>
          <div className="space-y-2">
            <div className="flex justify-between">
              <span className="text-gray-600">Pay Period:</span>
              <span className="font-medium">{formatPayPeriod(payslip.pay_period)}</span>
            </div>
            <div className="flex justify-between">
              <span className="text-gray-600">Pay Date:</span>
              <span className="font-medium">
                {new Date(payslip.payroll.pay_date).toLocaleDateString('en-ZM')}
              </span>
            </div>
            <div className="flex justify-between">
              <span className="text-gray-600">Payroll ID:</span>
              <span className="font-medium">{payslip.payroll.id.slice(0, 8)}</span>
            </div>
          </div>
        </div>
      </div>

      {/* Earnings and Deductions */}
      <div className="grid grid-cols-1 lg:grid-cols-2 gap-8 mb-8">
        {/* Earnings */}
        <div>
          <h3 className="text-lg font-semibold mb-4 text-gray-900 border-b pb-2">Earnings</h3>
          <div className="space-y-3">
            <div className="flex justify-between">
              <span className="text-gray-700">Basic Pay</span>
              <span className="font-medium">{formatZMK(payslip.payroll.basic_pay)}</span>
            </div>
            {payslip.payroll.allowances > 0 && (
              <div className="flex justify-between">
                <span className="text-gray-700">Allowances</span>
                <span className="font-medium">{formatZMK(payslip.payroll.allowances)}</span>
              </div>
            )}
            {payslip.payroll.bonuses > 0 && (
              <div className="flex justify-between">
                <span className="text-gray-700">Bonuses</span>
                <span className="font-medium">{formatZMK(payslip.payroll.bonuses)}</span>
              </div>
            )}
            {payslip.payroll.gratuity > 0 && (
              <div className="flex justify-between">
                <span className="text-gray-700">Gratuity</span>
                <span className="font-medium">{formatZMK(payslip.payroll.gratuity)}</span>
              </div>
            )}
            <div className="flex justify-between border-t pt-2 font-semibold">
              <span>Gross Pay</span>
              <span>{formatZMK(payslip.payroll.gross_pay)}</span>
            </div>
          </div>
        </div>

        {/* Deductions */}
        <div>
          <h3 className="text-lg font-semibold mb-4 text-gray-900 border-b pb-2">Deductions</h3>
          <div className="space-y-3">
            <div className="flex justify-between">
              <span className="text-gray-700">NAPSA</span>
              <span className="font-medium">{formatZMK(payslip.payroll.napsa)}</span>
            </div>
            <div className="flex justify-between">
              <span className="text-gray-700">NHIS</span>
              <span className="font-medium">{formatZMK(payslip.payroll.nhis)}</span>
            </div>
            <div className="flex justify-between">
              <span className="text-gray-700">PAYE Tax</span>
              <span className="font-medium">{formatZMK(payslip.payroll.tax)}</span>
            </div>
            {payslip.payroll.loans > 0 && (
              <div className="flex justify-between">
                <span className="text-gray-700">Loans</span>
                <span className="font-medium">{formatZMK(payslip.payroll.loans)}</span>
              </div>
            )}
            {payslip.payroll.other_deductions > 0 && (
              <div className="flex justify-between">
                <span className="text-gray-700">Other Deductions</span>
                <span className="font-medium">{formatZMK(payslip.payroll.other_deductions)}</span>
              </div>
            )}
            <div className="flex justify-between border-t pt-2 font-semibold">
              <span>Total Deductions</span>
              <span>{formatZMK(payslip.payroll.total_deductions)}</span>
            </div>
          </div>
        </div>
      </div>

      {/* Net Pay */}
      <div className="text-center bg-gray-50 p-6 rounded-lg">
        <h2 className="text-2xl font-bold mb-2" style={{ color: settings.colors.primary }}>
          NET PAY
        </h2>
        <p className="text-4xl font-bold" style={{ color: settings.colors.secondary }}>
          {formatZMK(payslip.payroll.net_pay)}
        </p>
        <p className="text-gray-600 mt-2">
          ({Number(payslip.payroll.net_pay).toFixed(2)} Zambian Kwacha)
        </p>
      </div>

      {/* Footer */}
      <div className="mt-8 pt-4 border-t border-gray-200 text-center text-sm text-gray-500">
        <p>This is a computer-generated payslip and does not require a signature.</p>
        <p className="mt-1">Generated on {new Date().toLocaleDateString('en-ZM')} by GPTPayroll</p>
      </div>
    </div>
  )

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
          <h1 className="text-2xl font-bold text-gray-900">Payslip Management</h1>
          <p className="text-gray-600 mt-1">Generate, view, and export employee payslips</p>
        </div>
        <div className="mt-4 sm:mt-0 flex space-x-2">
          <button
            onClick={() => setShowSettings(true)}
            className="inline-flex items-center px-4 py-2 border border-gray-300 text-sm font-medium rounded-md text-gray-700 bg-white hover:bg-gray-50"
          >
            <Settings className="w-4 h-4 mr-2" />
            Settings
          </button>
          <button
            onClick={exportToExcel}
            className="inline-flex items-center px-4 py-2 border border-transparent text-sm font-medium rounded-md text-white bg-green-600 hover:bg-green-700"
          >
            <Download className="w-4 h-4 mr-2" />
            Export Excel
          </button>
        </div>
      </div>

      {/* Actions Bar */}
      <div className="bg-white rounded-lg shadow-md p-4">
        <div className="flex flex-col sm:flex-row sm:items-center sm:justify-between space-y-2 sm:space-y-0">
          <div className="flex items-center space-x-4">
            <label className="flex items-center">
              <input
                type="checkbox"
                checked={selectedPayslips.length === payslips.length && payslips.length > 0}
                onChange={(e) => {
                  if (e.target.checked) {
                    setSelectedPayslips(payslips.map(p => p.id))
                  } else {
                    setSelectedPayslips([])
                  }
                }}
                className="h-4 w-4 text-green-600 focus:ring-green-500 border-gray-300 rounded"
              />
              <span className="ml-2 text-sm text-gray-700">
                Select All ({selectedPayslips.length}/{payslips.length})
              </span>
            </label>
          </div>
          
          {selectedPayslips.length > 0 && (
            <button
              onClick={downloadBulkPayslips}
              className="inline-flex items-center px-4 py-2 border border-transparent text-sm font-medium rounded-md text-white bg-blue-600 hover:bg-blue-700"
            >
              <Download className="w-4 h-4 mr-2" />
              Download Selected ({selectedPayslips.length})
            </button>
          )}
        </div>
      </div>

      {/* Payslip List */}
      <div className="bg-white rounded-lg shadow-md overflow-hidden">
        <div className="overflow-x-auto">
          <table className="min-w-full divide-y divide-gray-200">
            <thead className="bg-gray-50">
              <tr>
                <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                  <span className="sr-only">Select</span>
                </th>
                <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                  Employee
                </th>
                <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                  Pay Period
                </th>
                <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                  Gross Pay
                </th>
                <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                  Net Pay
                </th>
                <th className="px-6 py-3 text-right text-xs font-medium text-gray-500 uppercase tracking-wider">
                  Actions
                </th>
              </tr>
            </thead>
            <tbody className="bg-white divide-y divide-gray-200">
              {payslips.map((payslip) => (
                <tr key={payslip.id} className="hover:bg-gray-50">
                  <td className="px-6 py-4 whitespace-nowrap">
                    <input
                      type="checkbox"
                      checked={selectedPayslips.includes(payslip.id)}
                      onChange={(e) => {
                        if (e.target.checked) {
                          setSelectedPayslips([...selectedPayslips, payslip.id])
                        } else {
                          setSelectedPayslips(selectedPayslips.filter(id => id !== payslip.id))
                        }
                      }}
                      className="h-4 w-4 text-green-600 focus:ring-green-500 border-gray-300 rounded"
                    />
                  </td>
                  <td className="px-6 py-4 whitespace-nowrap">
                    <div className="flex items-center">
                      <div className="w-10 h-10 bg-green-100 rounded-full flex items-center justify-center">
                        <User className="w-5 h-5 text-green-600" />
                      </div>
                      <div className="ml-4">
                        <div className="text-sm font-medium text-gray-900">
                          {payslip.employee.first_name} {payslip.employee.last_name}
                        </div>
                        <div className="text-sm text-gray-500">
                          {payslip.employee.employee_id} - {payslip.employee.designation}
                        </div>
                      </div>
                    </div>
                  </td>
                  <td className="px-6 py-4 whitespace-nowrap">
                    <div className="text-sm text-gray-900">{formatPayPeriod(payslip.pay_period)}</div>
                    <div className="text-sm text-gray-500">
                      {new Date(payslip.payroll.pay_date).toLocaleDateString('en-ZM')}
                    </div>
                  </td>
                  <td className="px-6 py-4 whitespace-nowrap text-sm text-gray-900">
                    {formatZMK(payslip.payroll.gross_pay)}
                  </td>
                  <td className="px-6 py-4 whitespace-nowrap text-sm font-medium" style={{ color: settings.colors.primary }}>
                    {formatZMK(payslip.payroll.net_pay)}
                  </td>
                  <td className="px-6 py-4 whitespace-nowrap text-right text-sm font-medium">
                    <div className="flex justify-end space-x-2">
                      <button
                        onClick={() => generatePayslip(payslip)}
                        className="text-blue-600 hover:text-blue-900"
                        title="Preview Payslip"
                      >
                        <Eye className="w-4 h-4" />
                      </button>
                      <button
                        onClick={() => downloadSinglePayslip(payslip)}
                        className="text-green-600 hover:text-green-900"
                        title="Download PDF"
                      >
                        <Download className="w-4 h-4" />
                      </button>
                    </div>
                  </td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>

        {payslips.length === 0 && (
          <div className="text-center py-12">
            <FileText className="mx-auto h-12 w-12 text-gray-400" />
            <h3 className="mt-2 text-sm font-medium text-gray-900">No payslips available</h3>
            <p className="mt-1 text-sm text-gray-500">
              Payslips will appear here after processing payroll
            </p>
          </div>
        )}
      </div>

      {/* Preview Modal */}
      {showPreview && selectedPayslip && (
        <div className="fixed inset-0 bg-gray-600 bg-opacity-50 overflow-y-auto h-full w-full z-50">
          <div className="relative top-10 mx-auto p-5 border w-11/12 max-w-5xl shadow-lg rounded-md bg-white">
            <div className="flex items-center justify-between mb-6">
              <h3 className="text-lg font-bold text-gray-900">
                Payslip Preview - {selectedPayslip.employee.first_name} {selectedPayslip.employee.last_name}
              </h3>
              <div className="flex space-x-2">
                <button
                  onClick={() => downloadSinglePayslip(selectedPayslip)}
                  className="inline-flex items-center px-4 py-2 border border-transparent text-sm font-medium rounded-md text-white bg-green-600 hover:bg-green-700"
                >
                  <Download className="w-4 h-4 mr-2" />
                  Download PDF
                </button>
                <button
                  onClick={() => setShowPreview(false)}
                  className="text-gray-400 hover:text-gray-600"
                >
                  ✕
                </button>
              </div>
            </div>
            
            <div className="max-h-96 overflow-y-auto border border-gray-200 rounded">
              <PayslipPreview payslip={selectedPayslip} />
            </div>
          </div>
        </div>
      )}

      {/* Settings Modal */}
      {showSettings && (
        <div className="fixed inset-0 bg-gray-600 bg-opacity-50 overflow-y-auto h-full w-full z-50">
          <div className="relative top-20 mx-auto p-5 border w-11/12 max-w-2xl shadow-lg rounded-md bg-white">
            <div className="flex items-center justify-between mb-6">
              <h3 className="text-lg font-bold text-gray-900">Payslip Settings</h3>
              <button
                onClick={() => setShowSettings(false)}
                className="text-gray-400 hover:text-gray-600"
              >
                ✕
              </button>
            </div>

            <div className="space-y-6">
              <div className="grid grid-cols-2 gap-4">
                <label className="flex items-center">
                  <input
                    type="checkbox"
                    checked={settings.show_company_logo}
                    onChange={(e) => setSettings({...settings, show_company_logo: e.target.checked})}
                    className="h-4 w-4 text-green-600 focus:ring-green-500 border-gray-300 rounded"
                  />
                  <span className="ml-2 text-sm text-gray-700">Show Company Logo</span>
                </label>

                <label className="flex items-center">
                  <input
                    type="checkbox"
                    checked={settings.show_employee_photo}
                    onChange={(e) => setSettings({...settings, show_employee_photo: e.target.checked})}
                    className="h-4 w-4 text-green-600 focus:ring-green-500 border-gray-300 rounded"
                  />
                  <span className="ml-2 text-sm text-gray-700">Show Employee Photo</span>
                </label>

                <label className="flex items-center">
                  <input
                    type="checkbox"
                    checked={settings.include_nrc}
                    onChange={(e) => setSettings({...settings, include_nrc: e.target.checked})}
                    className="h-4 w-4 text-green-600 focus:ring-green-500 border-gray-300 rounded"
                  />
                  <span className="ml-2 text-sm text-gray-700">Include NRC</span>
                </label>

                <label className="flex items-center">
                  <input
                    type="checkbox"
                    checked={settings.include_tpin}
                    onChange={(e) => setSettings({...settings, include_tpin: e.target.checked})}
                    className="h-4 w-4 text-green-600 focus:ring-green-500 border-gray-300 rounded"
                  />
                  <span className="ml-2 text-sm text-gray-700">Include TPIN</span>
                </label>
              </div>

              <div>
                <label className="block text-sm font-medium text-gray-700 mb-2">
                  Layout Style
                </label>
                <select
                  value={settings.layout}
                  onChange={(e) => setSettings({...settings, layout: e.target.value as any})}
                  className="w-full border border-gray-300 rounded-lg px-3 py-2 focus:ring-green-500 focus:border-green-500"
                >
                  <option value="standard">Standard</option>
                  <option value="compact">Compact</option>
                  <option value="detailed">Detailed</option>
                </select>
              </div>

              <div>
                <label className="block text-sm font-medium text-gray-700 mb-2">
                  Primary Color
                </label>
                <input
                  type="color"
                  value={settings.colors.primary}
                  onChange={(e) => setSettings({
                    ...settings, 
                    colors: {...settings.colors, primary: e.target.value}
                  })}
                  className="w-full h-10 border border-gray-300 rounded-lg"
                />
              </div>
            </div>

            <div className="flex justify-end space-x-4 mt-6 pt-6 border-t border-gray-200">
              <button
                onClick={() => setShowSettings(false)}
                className="px-4 py-2 border border-gray-300 rounded-lg text-gray-700 hover:bg-gray-50"
              >
                Cancel
              </button>
              <button
                onClick={() => {
                  toast.success('Payslip settings updated')
                  setShowSettings(false)
                }}
                className="px-4 py-2 bg-green-600 text-white rounded-lg hover:bg-green-700"
              >
                Save Settings
              </button>
            </div>
          </div>
        </div>
      )}
    </div>
  )
}

export default PayslipGenerator