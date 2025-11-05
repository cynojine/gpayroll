import React, { createContext, useContext, useEffect, useState } from 'react'
import { User as SupabaseUser } from '@supabase/supabase-js'
import { supabase } from '../lib/supabase'
import { toast } from 'react-toastify'

export interface UserProfile {
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
  
  // Employee data (if linked)
  employee_code?: string
  department?: string
  designation?: string
  employment_status?: string
  tpin?: string
  nrc?: string
  date_of_birth?: string
  gender?: string
  marital_status?: string
  address?: string
  city?: string
  province?: string
  bank_name?: string
  bank_branch?: string
  account_number?: string
  basic_salary?: number
  salary_type?: 'hourly' | 'monthly' | 'contract'
}

export interface RegisterData {
  email: string
  password: string
  first_name: string
  last_name: string
  phone?: string
  role: 'admin' | 'hr' | 'employee'
  employeeData?: {
    employee_id: string
    department: string
    designation: string
    salary_type: 'hourly' | 'monthly' | 'contract'
    basic_salary: number
    tpin: string
    nrc: string
    start_date: string
  }
}

interface AuthContextType {
  user: UserProfile | null
  loading: boolean
  login: (email: string, password: string) => Promise<boolean>
  logout: () => Promise<void>
  register: (data: RegisterData) => Promise<boolean>
  updateProfile: (updates: Partial<UserProfile>) => Promise<boolean>
  changePassword: (oldPassword: string, newPassword: string) => Promise<boolean>
  resetPassword: (email: string) => Promise<boolean>
  hasRole: (roles: string[]) => boolean
  canAccess: (resource: string, action: string) => boolean
  refreshUser: () => Promise<void>
}

const AuthContext = createContext<AuthContextType | undefined>(undefined)

export const useAuth = () => {
  const context = useContext(AuthContext)
  if (context === undefined) {
    throw new Error('useAuth must be used within an AuthProvider')
  }
  return context
}

export const AuthProvider: React.FC<{ children: React.ReactNode }> = ({ children }) => {
  const [user, setUser] = useState<UserProfile | null>(null)
  const [loading, setLoading] = useState(true)

  useEffect(() => {
    // Get initial session
    supabase.auth.getSession().then(({ data: { session } }) => {
      if (session?.user) {
        fetchUserProfile(session.user.id)
      } else {
        setLoading(false)
      }
    })

    // Listen for auth changes
    const {
      data: { subscription },
    } = supabase.auth.onAuthStateChange(async (event, session) => {
      console.log('Auth state changed:', event, session?.user?.id)
      
      if (session?.user) {
        await fetchUserProfile(session.user.id)
      } else {
        setUser(null)
        setLoading(false)
      }
    })

    return () => subscription.unsubscribe()
  }, [])

  const refreshUser = async () => {
    const { data: { session } } = await supabase.auth.getSession()
    if (session?.user) {
      await fetchUserProfile(session.user.id)
    }
  }

  const fetchUserProfile = async (userId: string) => {
    try {
      // Use the view we created for comprehensive user data
      const { data, error } = await supabase
        .from('user_profiles')
        .select('*')
        .eq('id', userId)
        .single()

      if (error) {
        console.error('Error fetching user profile:', error)
        
        // Try to get basic user info and create profile if needed
        const { data: authUser } = await supabase.auth.getUser()
        if (authUser.user) {
          const newUser = {
            id: userId,
            email: authUser.user.email || '',
            role: 'employee' as const,
            email_verified: !!authUser.user.email_confirmed_at,
            is_active: true,
            created_at: new Date().toISOString(),
            updated_at: new Date().toISOString()
          }
          
          const { data: createdUser, error: createError } = await supabase
            .from('users')
            .insert([newUser])
            .select()
            .single()

          if (createError) {
            console.error('Error creating user profile:', createError)
            toast.error('Failed to create user profile')
          } else {
            setUser(createdUser)
          }
        }
      } else {
        setUser(data)
      }
    } catch (error) {
      console.error('Error in fetchUserProfile:', error)
      toast.error('Failed to load user profile')
    } finally {
      setLoading(false)
    }
  }

  const login = async (email: string, password: string): Promise<boolean> => {
    try {
      setLoading(true)
      const { data, error } = await supabase.auth.signInWithPassword({
        email,
        password,
      })

      if (error) {
        console.error('Login error:', error)
        
        // Provide user-friendly error messages
        switch (error.message) {
          case 'Invalid login credentials':
            toast.error('Invalid email or password')
            break
          case 'Email not confirmed':
            toast.error('Please confirm your email address before logging in')
            break
          case 'Too many requests':
            toast.error('Too many login attempts. Please try again later')
            break
          default:
            toast.error(error.message || 'Login failed')
        }
        return false
      }

      if (data.user) {
        await fetchUserProfile(data.user.id)
        toast.success(`Welcome back, ${user?.first_name || 'User'}!`)
        return true
      }
      return false
    } catch (error) {
      console.error('Login error:', error)
      toast.error('An unexpected error occurred during login')
      return false
    } finally {
      setLoading(false)
    }
  }

  const logout = async (): Promise<void> => {
    try {
      const { error } = await supabase.auth.signOut()
      if (error) {
        console.error('Logout error:', error)
        toast.error('Error logging out')
      } else {
        setUser(null)
        toast.success('Logged out successfully')
      }
    } catch (error) {
      console.error('Logout error:', error)
      toast.error('An error occurred during logout')
    }
  }

  const register = async (data: RegisterData): Promise<boolean> => {
    try {
      setLoading(true)
      const { data: authData, error: authError } = await supabase.auth.signUp({
        email: data.email,
        password: data.password,
        options: {
          data: {
            first_name: data.first_name,
            last_name: data.last_name,
            role: data.role
          }
        }
      })

      if (authError) {
        console.error('Registration error:', authError)
        
        // Provide user-friendly error messages
        switch (authError.message) {
          case 'User already registered':
            toast.error('An account with this email already exists')
            break
          case 'Password should be at least 6 characters':
            toast.error('Password must be at least 6 characters long')
            break
          case 'Unable to validate email address: invalid format':
            toast.error('Please enter a valid email address')
            break
          default:
            toast.error(authError.message || 'Registration failed')
        }
        return false
      }

      if (authData.user) {
        // The trigger will automatically create the user profile
        // Update profile with additional data
        const { error: profileError } = await supabase
          .from('users')
          .update({
            first_name: data.first_name,
            last_name: data.last_name,
            phone: data.phone,
            role: data.role,
            updated_at: new Date().toISOString()
          })
          .eq('id', authData.user.id)

        if (profileError) {
          console.error('Error updating user profile:', profileError)
        }

        // Create employee record if provided
        if (data.employeeData && data.role === 'employee') {
          const employee = {
            ...data.employeeData,
            first_name: data.first_name,
            last_name: data.last_name,
            email: data.email,
            phone: data.phone,
            created_at: new Date().toISOString(),
            updated_at: new Date().toISOString()
          }

          const { data: newEmployee, error: employeeError } = await supabase
            .from('employees')
            .insert([employee])
            .select()
            .single()

          if (employeeError) {
            console.error('Error creating employee record:', employeeError)
            toast.error('Failed to create employee record')
          } else {
            // Link user to employee
            await supabase
              .from('users')
              .update({ employee_id: newEmployee.id })
              .eq('id', authData.user.id)
          }
        }

        toast.success('Registration successful! Please check your email to verify your account.')
        return true
      }
      return false
    } catch (error) {
      console.error('Registration error:', error)
      toast.error('An unexpected error occurred during registration')
      return false
    } finally {
      setLoading(false)
    }
  }

  const updateProfile = async (updates: Partial<UserProfile>): Promise<boolean> => {
    if (!user) return false

    try {
      // Separate user profile updates from employee updates
      const { 
        employeeData, 
        ...userUpdates 
      } = updates as any

      let success = true

      // Update user profile
      if (Object.keys(userUpdates).length > 0) {
        const { data, error } = await supabase
          .from('users')
          .update({
            ...userUpdates,
            updated_at: new Date().toISOString()
          })
          .eq('id', user.id)
          .select()
          .single()

        if (error) {
          console.error('Error updating user profile:', error)
          toast.error('Failed to update profile')
          success = false
        } else {
          // Refresh user data to get updated info
          await fetchUserProfile(user.id)
        }
      }

      // Update employee data if provided
      if (employeeData && user.employee_id) {
        const { error: employeeError } = await supabase
          .from('employees')
          .update({
            ...employeeData,
            updated_at: new Date().toISOString()
          })
          .eq('id', user.employee_id)

        if (employeeError) {
          console.error('Error updating employee data:', employeeError)
          toast.error('Failed to update employee information')
          success = false
        } else {
          await fetchUserProfile(user.id)
        }
      }

      if (success) {
        toast.success('Profile updated successfully!')
      }
      
      return success
    } catch (error) {
      console.error('Profile update error:', error)
      toast.error('An error occurred while updating profile')
      return false
    }
  }

  const changePassword = async (oldPassword: string, newPassword: string): Promise<boolean> => {
    try {
      const { error } = await supabase.auth.updateUser({
        password: newPassword
      })

      if (error) {
        console.error('Password change error:', error)
        toast.error(error.message || 'Failed to change password')
        return false
      }

      toast.success('Password changed successfully!')
      return true
    } catch (error) {
      console.error('Password change error:', error)
      toast.error('An error occurred while changing password')
      return false
    }
  }

  const resetPassword = async (email: string): Promise<boolean> => {
    try {
      const { error } = await supabase.auth.resetPasswordForEmail(email, {
        redirectTo: `${window.location.origin}/reset-password`
      })

      if (error) {
        console.error('Password reset error:', error)
        toast.error(error.message || 'Failed to send password reset email')
        return false
      }

      toast.success('Password reset email sent! Please check your inbox.')
      return true
    } catch (error) {
      console.error('Password reset error:', error)
      toast.error('An error occurred while sending password reset email')
      return false
    }
  }

  const hasRole = (roles: string[]): boolean => {
    return user ? roles.includes(user.role) : false
  }

  const canAccess = (resource: string, action: string): boolean => {
    if (!user) return false

    // Define role-based permissions
    const permissions = {
      admin: {
        users: ['create', 'read', 'update', 'delete'],
        employees: ['create', 'read', 'update', 'delete'],
        payroll: ['create', 'read', 'update', 'delete'],
        settings: ['read', 'update'],
        reports: ['read'],
        audit: ['read']
      },
      hr: {
        employees: ['create', 'read', 'update'],
        payroll: ['create', 'read', 'update'],
        leave: ['read', 'update'],
        time: ['read', 'update'],
        reports: ['read']
      },
      employee: {
        profile: ['read', 'update'],
        payroll: ['read'],
        leave: ['create', 'read'],
        time: ['create', 'read']
      }
    }

    const userPermissions = permissions[user.role as keyof typeof permissions]
    return userPermissions?.[resource as keyof typeof userPermissions]?.includes(action as any) || false
  }

  const value: AuthContextType = {
    user,
    loading,
    login,
    logout,
    register,
    updateProfile,
    changePassword,
    resetPassword,
    hasRole,
    canAccess,
    refreshUser
  }

  return <AuthContext.Provider value={value}>{children}</AuthContext.Provider>
}

export { AuthContext }
export default AuthProvider