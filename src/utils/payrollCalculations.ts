// Zambia Payroll Calculator - 2025 Tax Bands
export interface PayrollCalculation {
  basic_pay: number
  allowances: number
  bonuses: number
  gratuity: number
  gross_pay: number
  napsa: number
  nhis: number
  tax: number
  loans: number
  other_deductions: number
  total_deductions: number
  net_pay: number
  breakdown: {
    napsa_details: { amount: number; rate: number; capped: boolean }
    nhis_details: { amount: number; rate: number }
    tax_details: {
      band1: { amount: number; rate: number; value: number }
      band2?: { amount: number; rate: number; value: number }
      band3?: { amount: number; rate: number; value: number }
      band4?: { amount: number; rate: number; value: number }
    }
  }
}

export interface TaxBand {
  name: string
  min: number
  max: number | null // null for "above"
  rate: number
}

// 2025 Zambia Tax Bands
export const ZAMBIA_TAX_BANDS: TaxBand[] = [
  {
    name: "Tax Free",
    min: 0,
    max: 5100,
    rate: 0
  },
  {
    name: "Band 1",
    min: 5100.01,
    max: 7100,
    rate: 0.20
  },
  {
    name: "Band 2", 
    min: 7100.01,
    max: 9200,
    rate: 0.30
  },
  {
    name: "Band 3",
    min: 9200.01,
    max: null,
    rate: 0.37
  }
]

// Default tax rates for Zambia 2025
export const DEFAULT_TAX_RATES = {
  NAPSA: {
    rate: 0.05, // 5%
    maximum: 1149.60 // K1,149.60
  },
  NHIS: {
    rate: 0.01 // 1%
  },
  NIHMA: {
    rate: 0.01 // 1%
  }
}

/**
 * Calculate payroll for an employee based on Zambian tax laws
 */
export function calculatePayroll(
  basicPay: number,
  allowances: number = 0,
  bonuses: number = 0,
  gratuity: number = 0,
  loans: number = 0,
  otherDeductions: number = 0,
  customDeductions: Array<{
    amount: number
    percentage?: number
    isPercentage: boolean
    isBeforeGross: boolean
    isBeforeTax: boolean
  }> = [],
  customAdditions: Array<{
    amount: number
    percentage?: number
    isPercentage: boolean
  }> = []
): PayrollCalculation {
  // Step 1: Calculate gross pay (basic + allowances + bonuses + gratuity)
  let grossPay = basicPay + allowances + bonuses + gratuity

  // Step 2: Apply custom additions
  let totalAdditions = 0
  customAdditions.forEach(addition => {
    if (addition.isPercentage) {
      totalAdditions += grossPay * (addition.percentage || 0) / 100
    } else {
      totalAdditions += addition.amount
    }
  })
  grossPay += totalAdditions

  // Step 3: Apply custom deductions that come before gross
  let deductionsBeforeGross = 0
  customDeductions.forEach(deduction => {
    if (deduction.isBeforeGross) {
      if (deduction.isPercentage) {
        deductionsBeforeGross += grossPay * (deduction.percentage || 0) / 100
      } else {
        deductionsBeforeGross += deduction.amount
      }
    }
  })

  // Step 4: Calculate taxable income
  const taxableIncome = grossPay - deductionsBeforeGross

  // Step 5: Calculate NAPSA (5% of gross, capped at K1,149.60)
  const napsaAmount = Math.min(grossPay * DEFAULT_TAX_RATES.NAPSA.rate, DEFAULT_TAX_RATES.NAPSA.maximum)
  
  // Step 6: Calculate NHIS (1% of basic pay)
  const nhisAmount = basicPay * DEFAULT_TAX_RATES.NHIS.rate

  // Step 7: Calculate PAYE Tax using 2025 bands
  const taxDetails = calculatePAYETax(taxableIncome)
  const taxAmount = taxDetails.totalTax

  // Step 8: Apply custom deductions that come before tax
  let deductionsBeforeTax = napsaAmount + nhisAmount
  customDeductions.forEach(deduction => {
    if (deduction.isBeforeTax && !deduction.isBeforeGross) {
      if (deduction.isPercentage) {
        deductionsBeforeTax += grossPay * (deduction.percentage || 0) / 100
      } else {
        deductionsBeforeTax += deduction.amount
      }
    }
  })

  // Step 9: Calculate net pay
  const totalDeductions = deductionsBeforeTax + taxAmount + loans + otherDeductions
  const netPay = taxableIncome - totalDeductions + totalAdditions

  // Step 10: Apply custom deductions that come after tax
  let otherDeductionsAfterTax = otherDeductions
  customDeductions.forEach(deduction => {
    if (!deduction.isBeforeGross && !deduction.isBeforeTax) {
      if (deduction.isPercentage) {
        otherDeductionsAfterTax += grossPay * (deduction.percentage || 0) / 100
      } else {
        otherDeductionsAfterTax += deduction.amount
      }
    }
  })

  return {
    basic_pay: basicPay,
    allowances,
    bonuses,
    gratuity,
    gross_pay: grossPay,
    napsa: napsaAmount,
    nhis: nhisAmount,
    tax: taxAmount,
    loans,
    other_deductions: otherDeductionsAfterTax,
    total_deductions: totalDeductions,
    net_pay: netPay,
    breakdown: {
      napsa_details: {
        amount: napsaAmount,
        rate: DEFAULT_TAX_RATES.NAPSA.rate,
        capped: napsaAmount === DEFAULT_TAX_RATES.NAPSA.maximum
      },
      nhis_details: {
        amount: nhisAmount,
        rate: DEFAULT_TAX_RATES.NHIS.rate
      },
      tax_details: taxDetails
    }
  }
}

/**
 * Calculate PAYE tax based on 2025 Zambian tax bands
 */
function calculatePAYETax(taxableIncome: number) {
  let remainingIncome = taxableIncome
  let totalTax = 0
  const details: any = {}

  ZAMBIA_TAX_BANDS.forEach((band, index) => {
    const bandNumber = index + 1
    const bandName = `band${bandNumber}`
    
    if (remainingIncome <= 0) return

    const bandSize = band.max ? (band.max - band.min) : Infinity
    const taxableInThisBand = Math.min(remainingIncome, bandSize)
    
    if (taxableInThisBand > 0) {
      const taxInThisBand = taxableInThisBand * band.rate
      totalTax += taxInThisBand
      
      details[bandName] = {
        amount: taxInThisBand,
        rate: band.rate,
        value: taxableInThisBand
      }
      
      remainingIncome -= taxableInThisBand
    }
  })

  return {
    totalTax,
    ...details
  }
}

/**
 * Format currency for Zambian Kwacha
 */
export function formatZMK(amount: number): string {
  return new Intl.NumberFormat('en-ZM', {
    style: 'currency',
    currency: 'ZMW',
    minimumFractionDigits: 2
  }).format(amount)
}

/**
 * Calculate overtime pay
 */
export function calculateOvertime(
  regularHours: number,
  regularRate: number,
  overtimeHours: number,
  overtimeMultiplier: number = 1.5
): number {
  return (regularHours * regularRate) + (overtimeHours * regularRate * overtimeMultiplier)
}

/**
 * Generate pay period string
 */
export function generatePayPeriod(date: Date = new Date()): string {
  const year = date.getFullYear()
  const month = date.getMonth() + 1
  return `${year}-${month.toString().padStart(2, '0')}`
}

/**
 * Validate employee salary
 */
export function validateSalary(
  salary: number,
  salaryType: 'hourly' | 'monthly' | 'contract'
): { isValid: boolean; errors: string[] } {
  const errors: string[] = []

  if (salary <= 0) {
    errors.push('Salary must be greater than 0')
  }

  switch (salaryType) {
    case 'hourly':
      if (salary > 50) {
        errors.push('Hourly rate seems too high')
      }
      break
    case 'monthly':
      if (salary > 50000) {
        errors.push('Monthly salary seems too high')
      }
      break
    case 'contract':
      if (salary > 100000) {
        errors.push('Contract amount seems too high')
      }
      break
  }

  return {
    isValid: errors.length === 0,
    errors
  }
}