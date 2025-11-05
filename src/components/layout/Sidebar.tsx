import React from 'react'
import { Link, useLocation } from 'react-router-dom'
import { useAuth } from '../../context/AuthContext'
import { 
  Home,
  Users,
  DollarSign,
  Clock,
  FileText,
  Calendar,
  Settings,
  Building2,
  TrendingUp,
  UserCheck,
  LogOut,
  X,
  ChevronDown
} from 'lucide-react'

interface SidebarProps {
  isOpen: boolean
  onClose: () => void
}

interface MenuItem {
  name: string
  icon: React.ElementType
  path?: string
  submenu?: MenuItem[]
  allowedRoles?: string[]
}

const Sidebar: React.FC<SidebarProps> = ({ isOpen, onClose }) => {
  const { user, logout } = useAuth()
  const location = useLocation()
  const [expandedMenus, setExpandedMenus] = React.useState<string[]>([])

  const menuItems: MenuItem[] = [
    {
      name: 'Dashboard',
      icon: Home,
      path: '/',
      allowedRoles: ['admin', 'hr', 'employee']
    },
    {
      name: 'Employees',
      icon: Users,
      allowedRoles: ['admin', 'hr'],
      submenu: [
        { name: 'All Employees', icon: Users, path: '/employees', allowedRoles: ['admin', 'hr'] },
        { name: 'Add Employee', icon: UserCheck, path: '/employees/add', allowedRoles: ['admin', 'hr'] },
        { name: 'Departments', icon: Building2, path: '/employees/departments', allowedRoles: ['admin'] }
      ]
    },
    {
      name: 'Payroll',
      icon: DollarSign,
      allowedRoles: ['admin', 'hr'],
      submenu: [
        { name: 'Run Payroll', icon: DollarSign, path: '/payroll/run', allowedRoles: ['admin', 'hr'] },
        { name: 'Payroll Records', icon: FileText, path: '/payroll/records', allowedRoles: ['admin', 'hr'] },
        { name: 'Payslips', icon: FileText, path: '/payroll/payslips', allowedRoles: ['admin', 'hr', 'employee'] },
        { name: 'Reports', icon: TrendingUp, path: '/payroll/reports', allowedRoles: ['admin', 'hr'] }
      ]
    },
    {
      name: 'Time & Attendance',
      icon: Clock,
      allowedRoles: ['admin', 'hr', 'employee'],
      submenu: [
        { name: 'Time Records', icon: Clock, path: '/time/records', allowedRoles: ['admin', 'hr', 'employee'] },
        { name: 'Clock In/Out', icon: Clock, path: '/time/clock', allowedRoles: ['admin', 'hr', 'employee'] },
        { name: 'Attendance Reports', icon: TrendingUp, path: '/time/reports', allowedRoles: ['admin', 'hr'] },
        { name: 'Overtime', icon: Clock, path: '/time/overtime', allowedRoles: ['admin', 'hr'] }
      ]
    },
    {
      name: 'Leave Management',
      icon: Calendar,
      allowedRoles: ['admin', 'hr', 'employee'],
      submenu: [
        { name: 'Leave Requests', icon: Calendar, path: '/leave/requests', allowedRoles: ['admin', 'hr', 'employee'] },
        { name: 'Leave Balance', icon: Calendar, path: '/leave/balance', allowedRoles: ['admin', 'hr', 'employee'] },
        { name: 'Holiday Calendar', icon: Calendar, path: '/leave/holidays', allowedRoles: ['admin', 'hr'] },
        { name: 'Leave Reports', icon: TrendingUp, path: '/leave/reports', allowedRoles: ['admin', 'hr'] }
      ]
    },
    {
      name: 'Reports',
      icon: TrendingUp,
      allowedRoles: ['admin', 'hr'],
      submenu: [
        { name: 'Payroll Reports', icon: DollarSign, path: '/reports/payroll', allowedRoles: ['admin', 'hr'] },
        { name: 'Employee Reports', icon: Users, path: '/reports/employees', allowedRoles: ['admin', 'hr'] },
        { name: 'Tax Reports', icon: FileText, path: '/reports/tax', allowedRoles: ['admin', 'hr'] },
        { name: 'Attendance Reports', icon: Clock, path: '/reports/attendance', allowedRoles: ['admin', 'hr'] }
      ]
    },
    {
      name: 'Settings',
      icon: Settings,
      allowedRoles: ['admin'],
      submenu: [
        { name: 'Company Settings', icon: Building2, path: '/settings/company', allowedRoles: ['admin'] },
        { name: 'Tax Settings', icon: FileText, path: '/settings/tax', allowedRoles: ['admin'] },
        { name: 'Payroll Settings', icon: DollarSign, path: '/settings/payroll', allowedRoles: ['admin'] },
        { name: 'User Management', icon: UserCheck, path: '/settings/users', allowedRoles: ['admin'] },
        { name: 'Payslip Template', icon: FileText, path: '/settings/payslip', allowedRoles: ['admin'] }
      ]
    }
  ]

  const toggleSubmenu = (menuName: string) => {
    setExpandedMenus(prev => 
      prev.includes(menuName) 
        ? prev.filter(name => name !== menuName)
        : [...prev, menuName]
    )
  }

  const isMenuActive = (path?: string) => {
    if (!path) return false
    return location.pathname === path || location.pathname.startsWith(path + '/')
  }

  const hasAccess = (item: MenuItem) => {
    if (!item.allowedRoles || !user) return false
    return item.allowedRoles.includes(user.role)
  }

  const renderMenuItem = (item: MenuItem, level = 0) => {
    if (!hasAccess(item)) return null

    const hasSubmenu = item.submenu && item.submenu.length > 0
    const isExpanded = expandedMenus.includes(item.name)
    const isActive = isMenuActive(item.path)

    return (
      <div key={item.name}>
        {hasSubmenu ? (
          <button
            onClick={() => toggleSubmenu(item.name)}
            className={`w-full flex items-center justify-between px-4 py-2 text-sm font-medium rounded-lg hover:bg-gray-100 transition-colors ${
              level > 0 ? 'ml-4 pl-8' : ''
            }`}
          >
            <div className="flex items-center">
              <item.icon className="w-5 h-5 mr-3 text-gray-600" />
              <span className="text-gray-700">{item.name}</span>
            </div>
            <ChevronDown className={`w-4 h-4 text-gray-400 transition-transform ${isExpanded ? 'rotate-180' : ''}`} />
          </button>
        ) : (
          <Link
            to={item.path || '#'}
            onClick={onClose}
            className={`flex items-center px-4 py-2 text-sm font-medium rounded-lg transition-colors ${
              isActive
                ? 'bg-green-100 text-green-700'
                : 'text-gray-700 hover:bg-gray-100'
            } ${level > 0 ? 'ml-4 pl-8' : ''}`}
          >
            <item.icon className="w-5 h-5 mr-3 text-gray-600" />
            <span>{item.name}</span>
          </Link>
        )}

        {hasSubmenu && isExpanded && (
          <div className="mt-1">
            {item.submenu?.map(subItem => renderMenuItem(subItem, level + 1))}
          </div>
        )}
      </div>
    )
  }

  const handleLogout = async () => {
    await logout()
    onClose()
  }

  return (
    <>
      {/* Mobile overlay */}
      {isOpen && (
        <div
          className="fixed inset-0 bg-gray-600 bg-opacity-50 z-40 lg:hidden"
          onClick={onClose}
        />
      )}

      {/* Sidebar */}
      <div className={`fixed inset-y-0 left-0 z-50 w-64 bg-white shadow-lg transform transition-transform duration-300 ease-in-out lg:translate-x-0 lg:static lg:inset-0 ${
        isOpen ? 'translate-x-0' : '-translate-x-full'
      }`}>
        {/* Header */}
        <div className="flex items-center justify-between p-4 border-b border-gray-200">
          <div className="flex items-center">
            <div className="w-8 h-8 bg-gradient-to-r from-green-600 to-green-700 rounded-lg flex items-center justify-center mr-3">
              <Building2 className="w-5 h-5 text-white" />
            </div>
            <div>
              <h1 className="text-lg font-bold text-gray-900">GPTPayroll</h1>
              <p className="text-xs text-gray-500">Zambia Edition</p>
            </div>
          </div>
          <button
            onClick={onClose}
            className="lg:hidden p-1 rounded-md text-gray-400 hover:text-gray-600 hover:bg-gray-100"
          >
            <X className="w-6 h-6" />
          </button>
        </div>

        {/* Zambian Colors Strip */}
        <div className="h-1 bg-gradient-to-r from-green-500 via-yellow-500 via-red-500 to-black"></div>

        {/* User Info */}
        <div className="p-4 border-b border-gray-200">
          <div className="flex items-center">
            <div className="w-10 h-10 bg-green-100 rounded-full flex items-center justify-center">
              <span className="text-green-600 font-semibold">
                {user?.email?.charAt(0).toUpperCase()}
              </span>
            </div>
            <div className="ml-3">
              <p className="text-sm font-medium text-gray-900 truncate">
                {user?.email}
              </p>
              <p className="text-xs text-gray-500 capitalize">
                {user?.role}
              </p>
            </div>
          </div>
        </div>

        {/* Navigation */}
        <nav className="flex-1 px-4 py-4 space-y-1 overflow-y-auto">
          {menuItems.map(item => renderMenuItem(item))}
        </nav>

        {/* Logout Button */}
        <div className="p-4 border-t border-gray-200">
          <button
            onClick={handleLogout}
            className="w-full flex items-center px-4 py-2 text-sm font-medium text-red-600 hover:bg-red-50 rounded-lg transition-colors"
          >
            <LogOut className="w-5 h-5 mr-3" />
            Logout
          </button>
        </div>
      </div>
    </>
  )
}

export default Sidebar