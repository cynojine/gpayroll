import React, { useState, useEffect } from 'react'
import { useForm } from 'react-hook-form'
import { toast } from 'react-toastify'
import { 
  Building2, 
  Settings as SettingsIcon,
  Save,
  Upload,
  Palette,
  FileText,
  DollarSign,
  Clock,
  Users,
  Info
} from 'lucide-react'
import { useCompany } from '../../context/CompanyContext'
import { supabase } from '../../lib/supabase'

interface CompanyFormData {
  company_name: string
  registration_number: string
  address: string
  primary_color: string
  secondary_color: string
  napsa_rate: number
  napsa_maximum: number
  nhis_rate: number
  nihma_rate: number
  working_days_per_month: number
  working_hours_per_day: number
  overtime_rate_multiplier: number
}

const CompanySettings: React.FC = () => {
  const { company, loading, updateCompany } = useCompany()
  const [activeTab, setActiveTab] = useState('general')
  const [uploading, setUploading] = useState(false)

  const {
    register,
    handleSubmit,
    reset,
    watch,
    setValue,
    formState: { errors, isDirty }
  } = useForm<CompanyFormData>()

  const primaryColor = watch('primary_color')
  const secondaryColor = watch('secondary_color')

  useEffect(() => {
    if (company) {
      reset({
        company_name: company.company_name || '',
        registration_number: company.registration_number || '',
        address: company.address || '',
        primary_color: company.primary_color || '#006A4E',
        secondary_color: company.secondary_color || '#EF7D00',
        napsa_rate: company.napsa_rate || 0.05,
        napsa_maximum: company.napsa_maximum || 1149.60,
        nhis_rate: company.nhis_rate || 0.01,
        nihma_rate: company.nihma_rate || 0.01,
        working_days_per_month: company.working_days_per_month || 22,
        working_hours_per_day: company.working_hours_per_day || 8,
        overtime_rate_multiplier: company.overtime_rate_multiplier || 1.5
      })
    }
  }, [company, reset])

  const onSubmit = async (data: CompanyFormData) => {
    try {
      await updateCompany(data)
    } catch (error) {
      console.error('Error updating company settings:', error)
    }
  }

  const uploadLogo = async (event: React.ChangeEvent<HTMLInputElement>) => {
    const file = event.target.files?.[0]
    if (!file) return

    // Validate file type
    if (!file.type.startsWith('image/')) {
      toast.error('Please select an image file')
      return
    }

    // Validate file size (max 2MB)
    if (file.size > 2 * 1024 * 1024) {
      toast.error('File size must be less than 2MB')
      return
    }

    setUploading(true)
    try {
      // In a real app, you would upload to Supabase Storage
      // For now, we'll simulate the upload
      await new Promise(resolve => setTimeout(resolve, 1000))
      toast.success('Logo uploaded successfully')
    } catch (error) {
      console.error('Error uploading logo:', error)
      toast.error('Failed to upload logo')
    } finally {
      setUploading(false)
    }
  }

  const tabs = [
    {
      id: 'general',
      name: 'General',
      icon: Building2,
      description: 'Company information and branding'
    },
    {
      id: 'tax',
      name: 'Tax Settings',
      icon: DollarSign,
      description: 'Tax rates and calculations'
    },
    {
      id: 'payroll',
      name: 'Payroll',
      icon: FileText,
      description: 'Payroll settings and rules'
    },
    {
      id: 'working',
      name: 'Working Hours',
      icon: Clock,
      description: 'Working hours and schedules'
    },
    {
      id: 'payslip',
      name: 'Payslip Template',
      icon: SettingsIcon,
      description: 'Customize payslip appearance'
    }
  ]

  const predefinedColors = [
    { name: 'Zambia Green', primary: '#006A4E', secondary: '#EF7D00' },
    { name: 'Corporate Blue', primary: '#1E40AF', secondary: '#3B82F6' },
    { name: 'Purple Elegance', primary: '#7C3AED', secondary: '#A855F7' },
    { name: 'Orange Energy', primary: '#EA580C', secondary: '#F97316' },
    { name: 'Teal Professional', primary: '#0F766E', secondary: '#14B8A6' },
    { name: 'Rose Modern', primary: '#BE185D', secondary: '#EC4899' }
  ]

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
          <h1 className="text-2xl font-bold text-gray-900">Company Settings</h1>
          <p className="text-gray-600 mt-1">Configure your company information and system settings</p>
        </div>
        <div className="mt-4 sm:mt-0 flex space-x-2">
          <button
            onClick={handleSubmit(onSubmit)}
            disabled={!isDirty}
            className="inline-flex items-center px-4 py-2 border border-transparent text-sm font-medium rounded-md text-white bg-green-600 hover:bg-green-700 disabled:opacity-50 disabled:cursor-not-allowed"
          >
            <Save className="w-4 h-4 mr-2" />
            Save Changes
          </button>
        </div>
      </div>

      <div className="grid grid-cols-1 lg:grid-cols-4 gap-6">
        {/* Tabs */}
        <div className="lg:col-span-1">
          <nav className="space-y-1">
            {tabs.map((tab) => {
              const Icon = tab.icon
              return (
                <button
                  key={tab.id}
                  onClick={() => setActiveTab(tab.id)}
                  className={`w-full flex items-start px-3 py-2 text-sm font-medium rounded-lg transition-colors ${
                    activeTab === tab.id
                      ? 'bg-green-100 text-green-700 border-green-200'
                      : 'text-gray-600 hover:bg-gray-50 hover:text-gray-900'
                  }`}
                >
                  <Icon className="w-5 h-5 mr-3 mt-0.5" />
                  <div className="text-left">
                    <div>{tab.name}</div>
                    <div className="text-xs text-gray-500">{tab.description}</div>
                  </div>
                </button>
              )
            })}
          </nav>
        </div>

        {/* Content */}
        <div className="lg:col-span-3">
          <form onSubmit={handleSubmit(onSubmit)}>
            {/* General Settings */}
            {activeTab === 'general' && (
              <div className="bg-white rounded-lg shadow-md p-6 space-y-6">
                <div>
                  <h3 className="text-lg font-semibold text-gray-900 mb-4">Company Information</h3>
                  
                  <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
                    <div>
                      <label className="block text-sm font-medium text-gray-700 mb-2">
                        Company Name *
                      </label>
                      <input
                        {...register('company_name', { required: 'Company name is required' })}
                        className="w-full border border-gray-300 rounded-lg px-3 py-2 focus:ring-green-500 focus:border-green-500"
                        placeholder="Your Company Ltd"
                      />
                      {errors.company_name && (
                        <p className="text-red-500 text-sm mt-1">{errors.company_name.message}</p>
                      )}
                    </div>

                    <div>
                      <label className="block text-sm font-medium text-gray-700 mb-2">
                        Registration Number
                      </label>
                      <input
                        {...register('registration_number')}
                        className="w-full border border-gray-300 rounded-lg px-3 py-2 focus:ring-green-500 focus:border-green-500"
                        placeholder="Company registration number"
                      />
                    </div>

                    <div className="md:col-span-2">
                      <label className="block text-sm font-medium text-gray-700 mb-2">
                        Address
                      </label>
                      <textarea
                        {...register('address')}
                        rows={3}
                        className="w-full border border-gray-300 rounded-lg px-3 py-2 focus:ring-green-500 focus:border-green-500"
                        placeholder="Company physical address"
                      />
                    </div>
                  </div>
                </div>

                {/* Company Logo */}
                <div>
                  <h3 className="text-lg font-semibold text-gray-900 mb-4">Branding</h3>
                  
                  <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
                    <div>
                      <label className="block text-sm font-medium text-gray-700 mb-2">
                        Company Logo
                      </label>
                      <div className="border-2 border-dashed border-gray-300 rounded-lg p-6 text-center">
                        <Upload className="w-12 h-12 text-gray-400 mx-auto mb-4" />
                        <div className="space-y-2">
                          <label className="cursor-pointer">
                            <span className="text-green-600 hover:text-green-700 font-medium">
                              Click to upload
                            </span>
                            <input
                              type="file"
                              accept="image/*"
                              onChange={uploadLogo}
                              className="hidden"
                              disabled={uploading}
                            />
                          </label>
                          <p className="text-xs text-gray-500">PNG, JPG, or SVG up to 2MB</p>
                        </div>
                      </div>
                    </div>

                    <div>
                      <label className="block text-sm font-medium text-gray-700 mb-2">
                        Color Scheme
                      </label>
                      <div className="grid grid-cols-2 gap-3">
                        <div>
                          <label className="block text-xs text-gray-500 mb-1">Primary Color</label>
                          <input
                            type="color"
                            {...register('primary_color')}
                            className="w-full h-10 border border-gray-300 rounded-lg"
                          />
                        </div>
                        <div>
                          <label className="block text-xs text-gray-500 mb-1">Secondary Color</label>
                          <input
                            type="color"
                            {...register('secondary_color')}
                            className="w-full h-10 border border-gray-300 rounded-lg"
                          />
                        </div>
                      </div>
                      
                      {/* Color Previews */}
                      <div className="mt-4 space-y-2">
                        {predefinedColors.map((color) => (
                          <button
                            key={color.name}
                            type="button"
                            onClick={() => {
                              setValue('primary_color', color.primary)
                              setValue('secondary_color', color.secondary)
                            }}
                            className="w-full flex items-center justify-between p-2 border border-gray-200 rounded-lg hover:bg-gray-50"
                          >
                            <span className="text-sm font-medium text-gray-700">{color.name}</span>
                            <div className="flex space-x-1">
                              <div 
                                className="w-4 h-4 rounded-full border"
                                style={{ backgroundColor: color.primary }}
                              />
                              <div 
                                className="w-4 h-4 rounded-full border"
                                style={{ backgroundColor: color.secondary }}
                              />
                            </div>
                          </button>
                        ))}
                      </div>
                    </div>
                  </div>
                </div>
              </div>
            )}

            {/* Tax Settings */}
            {activeTab === 'tax' && (
              <div className="bg-white rounded-lg shadow-md p-6 space-y-6">
                <div>
                  <h3 className="text-lg font-semibold text-gray-900 mb-4">Tax Configuration</h3>
                  <div className="bg-yellow-50 border border-yellow-200 rounded-lg p-4 mb-6">
                    <div className="flex">
                      <Info className="w-5 h-5 text-yellow-400 mr-3 mt-0.5" />
                      <div className="text-sm text-yellow-800">
                        <p className="font-medium mb-1">Important Tax Information</p>
                        <p>These settings should match the current Zambian tax regulations. Please consult with your tax advisor before making changes.</p>
                      </div>
                    </div>
                  </div>

                  <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
                    <div>
                      <label className="block text-sm font-medium text-gray-700 mb-2">
                        NAPSA Rate (%)
                      </label>
                      <div className="relative">
                        <input
                          type="number"
                          step="0.001"
                          min="0"
                          max="1"
                          {...register('napsa_rate', { 
                            required: 'NAPSA rate is required',
                            min: { value: 0, message: 'Rate must be positive' },
                            max: { value: 1, message: 'Rate cannot exceed 100%' }
                          })}
                          className="w-full border border-gray-300 rounded-lg px-3 py-2 pr-8 focus:ring-green-500 focus:border-green-500"
                          placeholder="0.05"
                        />
                        <span className="absolute right-3 top-2 text-gray-500 text-sm">%</span>
                      </div>
                      {errors.napsa_rate && (
                        <p className="text-red-500 text-sm mt-1">{errors.napsa_rate.message}</p>
                      )}
                      <p className="text-xs text-gray-500 mt-1">Current Zambian rate: 5% (0.05)</p>
                    </div>

                    <div>
                      <label className="block text-sm font-medium text-gray-700 mb-2">
                        NAPSA Maximum (ZMW)
                      </label>
                      <input
                        type="number"
                        step="0.01"
                        min="0"
                        {...register('napsa_maximum', { 
                          required: 'NAPSA maximum is required',
                          min: { value: 0, message: 'Maximum must be positive' }
                        })}
                        className="w-full border border-gray-300 rounded-lg px-3 py-2 focus:ring-green-500 focus:border-green-500"
                        placeholder="1149.60"
                      />
                      {errors.napsa_maximum && (
                        <p className="text-red-500 text-sm mt-1">{errors.napsa_maximum.message}</p>
                      )}
                      <p className="text-xs text-gray-500 mt-1">Current Zambian cap: K1,149.60</p>
                    </div>

                    <div>
                      <label className="block text-sm font-medium text-gray-700 mb-2">
                        NHIS Rate (%)
                      </label>
                      <div className="relative">
                        <input
                          type="number"
                          step="0.001"
                          min="0"
                          max="1"
                          {...register('nhis_rate', { 
                            required: 'NHIS rate is required',
                            min: { value: 0, message: 'Rate must be positive' },
                            max: { value: 1, message: 'Rate cannot exceed 100%' }
                          })}
                          className="w-full border border-gray-300 rounded-lg px-3 py-2 pr-8 focus:ring-green-500 focus:border-green-500"
                          placeholder="0.01"
                        />
                        <span className="absolute right-3 top-2 text-gray-500 text-sm">%</span>
                      </div>
                      {errors.nhis_rate && (
                        <p className="text-red-500 text-sm mt-1">{errors.nhis_rate.message}</p>
                      )}
                      <p className="text-xs text-gray-500 mt-1">Current Zambian rate: 1% (0.01)</p>
                    </div>

                    <div>
                      <label className="block text-sm font-medium text-gray-700 mb-2">
                        NIHMA Rate (%)
                      </label>
                      <div className="relative">
                        <input
                          type="number"
                          step="0.001"
                          min="0"
                          max="1"
                          {...register('nihma_rate', { 
                            required: 'NIHMA rate is required',
                            min: { value: 0, message: 'Rate must be positive' },
                            max: { value: 1, message: 'Rate cannot exceed 100%' }
                          })}
                          className="w-full border border-gray-300 rounded-lg px-3 py-2 pr-8 focus:ring-green-500 focus:border-green-500"
                          placeholder="0.01"
                        />
                        <span className="absolute right-3 top-2 text-gray-500 text-sm">%</span>
                      </div>
                      {errors.nihma_rate && (
                        <p className="text-red-500 text-sm mt-1">{errors.nihma_rate.message}</p>
                      )}
                      <p className="text-xs text-gray-500 mt-1">Current rate: 1% (0.01)</p>
                    </div>
                  </div>
                </div>

                {/* Tax Band Information */}
                <div>
                  <h4 className="text-md font-semibold text-gray-900 mb-3">Current PAYE Tax Bands (2025)</h4>
                  <div className="bg-gray-50 rounded-lg p-4">
                    <div className="grid grid-cols-1 md:grid-cols-2 gap-4 text-sm">
                      <div>
                        <p><strong>Tax-Free:</strong> First K5,100 @ 0%</p>
                        <p><strong>Band 1:</strong> K5,100.01 - K7,100 @ 20%</p>
                      </div>
                      <div>
                        <p><strong>Band 2:</strong> K7,100.01 - K9,200 @ 30%</p>
                        <p><strong>Band 3:</strong> Above K9,200 @ 37%</p>
                      </div>
                    </div>
                  </div>
                </div>
              </div>
            )}

            {/* Working Hours */}
            {activeTab === 'working' && (
              <div className="bg-white rounded-lg shadow-md p-6 space-y-6">
                <div>
                  <h3 className="text-lg font-semibold text-gray-900 mb-4">Working Schedule</h3>
                  
                  <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
                    <div>
                      <label className="block text-sm font-medium text-gray-700 mb-2">
                        Working Days per Month
                      </label>
                      <input
                        type="number"
                        min="15"
                        max="31"
                        {...register('working_days_per_month', { 
                          required: 'Working days is required',
                          min: { value: 15, message: 'Minimum 15 days' },
                          max: { value: 31, message: 'Maximum 31 days' }
                        })}
                        className="w-full border border-gray-300 rounded-lg px-3 py-2 focus:ring-green-500 focus:border-green-500"
                        placeholder="22"
                      />
                      {errors.working_days_per_month && (
                        <p className="text-red-500 text-sm mt-1">{errors.working_days_per_month.message}</p>
                      )}
                      <p className="text-xs text-gray-500 mt-1">Typical: 22 days per month</p>
                    </div>

                    <div>
                      <label className="block text-sm font-medium text-gray-700 mb-2">
                        Working Hours per Day
                      </label>
                      <input
                        type="number"
                        step="0.5"
                        min="1"
                        max="24"
                        {...register('working_hours_per_day', { 
                          required: 'Working hours is required',
                          min: { value: 1, message: 'Minimum 1 hour' },
                          max: { value: 24, message: 'Maximum 24 hours' }
                        })}
                        className="w-full border border-gray-300 rounded-lg px-3 py-2 focus:ring-green-500 focus:border-green-500"
                        placeholder="8"
                      />
                      {errors.working_hours_per_day && (
                        <p className="text-red-500 text-sm mt-1">{errors.working_hours_per_day.message}</p>
                      )}
                      <p className="text-xs text-gray-500 mt-1">Standard: 8 hours per day</p>
                    </div>

                    <div className="md:col-span-2">
                      <label className="block text-sm font-medium text-gray-700 mb-2">
                        Overtime Rate Multiplier
                      </label>
                      <input
                        type="number"
                        step="0.1"
                        min="1"
                        max="3"
                        {...register('overtime_rate_multiplier', { 
                          required: 'Overtime multiplier is required',
                          min: { value: 1, message: 'Minimum 1x rate' },
                          max: { value: 3, message: 'Maximum 3x rate' }
                        })}
                        className="w-full border border-gray-300 rounded-lg px-3 py-2 focus:ring-green-500 focus:border-green-500"
                        placeholder="1.5"
                      />
                      {errors.overtime_rate_multiplier && (
                        <p className="text-red-500 text-sm mt-1">{errors.overtime_rate_multiplier.message}</p>
                      )}
                      <p className="text-xs text-gray-500 mt-1">Standard: 1.5x regular hourly rate</p>
                    </div>
                  </div>
                </div>
              </div>
            )}

            {/* Save Button for non-General tabs */}
            {activeTab !== 'general' && (
              <div className="mt-6 flex justify-end">
                <button
                  type="submit"
                  disabled={!isDirty}
                  className="inline-flex items-center px-6 py-3 border border-transparent text-base font-medium rounded-md text-white bg-green-600 hover:bg-green-700 disabled:opacity-50 disabled:cursor-not-allowed"
                >
                  <Save className="w-5 h-5 mr-2" />
                  Save {tabs.find(t => t.id === activeTab)?.name} Settings
                </button>
              </div>
            )}
          </form>
        </div>
      </div>
    </div>
  )
}

export default CompanySettings