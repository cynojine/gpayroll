import React, { createContext, useContext, useEffect, useState } from 'react'
import { supabase, CompanySettings } from '../lib/supabase'
import { toast } from 'react-toastify'

interface CompanyContextType {
  company: CompanySettings | null
  loading: boolean
  updateCompany: (updates: Partial<CompanySettings>) => Promise<boolean>
  getTaxRates: () => {
    napsa_rate: number
    napsa_maximum: number
    nhis_rate: number
    nihma_rate: number
  }
  getPAYE_Bands: () => any[]
  getWorkingHours: () => {
    working_days_per_month: number
    working_hours_per_day: number
    overtime_rate_multiplier: number
  }
}

const CompanyContext = createContext<CompanyContextType | undefined>(undefined)

export const useCompany = () => {
  const context = useContext(CompanyContext)
  if (context === undefined) {
    throw new Error('useCompany must be used within a CompanyProvider')
  }
  return context
}

export const CompanyProvider: React.FC<{ children: React.ReactNode }> = ({ children }) => {
  const [company, setCompany] = useState<CompanySettings | null>(null)
  const [loading, setLoading] = useState(true)

  useEffect(() => {
    loadCompanySettings()
  }, [])

  const loadCompanySettings = async () => {
    try {
      const { data, error } = await supabase
        .from('company_settings')
        .select('*')
        .limit(1)
        .single()

      if (error && error.code !== 'PGRST116') {
        console.error('Error loading company settings:', error)
        return
      }

      if (data) {
        setCompany(data)
      } else {
        // Create default company settings if none exist
        const defaultSettings = {
          company_name: 'Your Company',
          registration_number: '',
          address: '',
          primary_color: '#006A4E', // Zambian green
          secondary_color: '#EF7D00', // Zambian copper
          napsa_rate: 0.05, // 5%
          napsa_maximum: 1149.60, // K1,149.60
          nhis_rate: 0.01, // 1%
          paye_bands: [
            { min: 0, max: 5100, rate: 0 },
            { min: 5100.01, max: 7100, rate: 0.20 },
            { min: 7100.01, max: 9200, rate: 0.30 },
            { min: 9200.01, max: null, rate: 0.37 }
          ],
          nihma_rate: 0.01, // 1%
          working_days_per_month: 22,
          working_hours_per_day: 8,
          overtime_rate_multiplier: 1.5,
          payslip_template: {
            show_company_logo: true,
            show_employee_photo: false,
            include_nrc: true,
            include_tpin: true,
            layout: 'standard'
          },
          created_at: new Date().toISOString(),
          updated_at: new Date().toISOString()
        }

        const { data: newCompany, error: createError } = await supabase
          .from('company_settings')
          .insert([defaultSettings])
          .select()
          .single()

        if (createError) {
          console.error('Error creating default company settings:', createError)
        } else {
          setCompany(newCompany)
        }
      }
    } catch (error) {
      console.error('Error in loadCompanySettings:', error)
    } finally {
      setLoading(false)
    }
  }

  const updateCompany = async (updates: Partial<CompanySettings>): Promise<boolean> => {
    if (!company) return false

    try {
      const { data, error } = await supabase
        .from('company_settings')
        .update({
          ...updates,
          updated_at: new Date().toISOString()
        })
        .eq('id', company.id)
        .select()
        .single()

      if (error) {
        toast.error('Failed to update company settings')
        return false
      }

      setCompany(data)
      toast.success('Company settings updated successfully!')
      return true
    } catch (error) {
      console.error('Error updating company settings:', error)
      toast.error('An error occurred while updating company settings')
      return false
    }
  }

  const getTaxRates = () => {
    if (!company) {
      return {
        napsa_rate: 0.05,
        napsa_maximum: 1149.60,
        nhis_rate: 0.01,
        nihma_rate: 0.01
      }
    }

    return {
      napsa_rate: company.napsa_rate,
      napsa_maximum: company.napsa_maximum,
      nhis_rate: company.nhis_rate,
      nihma_rate: company.nihma_rate
    }
  }

  const getPAYE_Bands = () => {
    return company?.paye_bands || [
      { min: 0, max: 5100, rate: 0 },
      { min: 5100.01, max: 7100, rate: 0.20 },
      { min: 7100.01, max: 9200, rate: 0.30 },
      { min: 9200.01, max: null, rate: 0.37 }
    ]
  }

  const getWorkingHours = () => {
    if (!company) {
      return {
        working_days_per_month: 22,
        working_hours_per_day: 8,
        overtime_rate_multiplier: 1.5
      }
    }

    return {
      working_days_per_month: company.working_days_per_month,
      working_hours_per_day: company.working_hours_per_day,
      overtime_rate_multiplier: company.overtime_rate_multiplier
    }
  }

  const value: CompanyContextType = {
    company,
    loading,
    updateCompany,
    getTaxRates,
    getPAYE_Bands,
    getWorkingHours
  }

  return <CompanyContext.Provider value={value}>{children}</CompanyContext.Provider>
}