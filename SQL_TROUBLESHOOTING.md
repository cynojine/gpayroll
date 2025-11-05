# 🚨 SQL Troubleshooting Guide for GPTPayroll

## Quick Fix Summary

### **Issue 1: "syntax error at or near DEFAULT" (RESOLVED)**
- **Problem:** Line 407 had invalid syntax: `UNIQUE(id) DEFAULT gen_random_uuid()`
- **Fix:** Use `CORRECTED_DATABASE_SCHEMA.sql` instead of the original

### **Issue 2: "column nhima_rate does not exist" (RESOLVED)**  
- **Problem:** `nhima_rate` column missing from `company_settings` table
- **Fix:** Run `NHIMA_RATE_FIX.sql` or use `COMPLETE_MIGRATION.sql`

## 🛠️ Step-by-Step Fixes

### **Option A: Quick Column Fix**
If you already have the database schema but missing columns:

```sql
-- Run this in Supabase SQL Editor
-- Copy and paste NHIMA_RATE_FIX.sql content
```

### **Option B: Complete Migration (RECOMMENDED)**
If you want to ensure everything is properly set up:

```sql
-- Run this comprehensive script
-- Copy and paste COMPLETE_MIGRATION.sql content
-- This handles all common issues automatically
```

## 📋 What the Migration Script Does

✅ **Checks for existing tables** (won't duplicate)  
✅ **Adds missing columns** (like `nhima_rate`)  
✅ **Creates essential functions** (updated_at triggers, etc.)  
✅ **Sets up RLS policies** (security)  
✅ **Inserts default data** (departments, holidays, settings)  
✅ **Verifies everything works** (status checks)  

## 🔍 Verification Commands

After running any fix, verify with these commands:

```sql
-- Check all required tables exist
SELECT table_name FROM information_schema.tables 
WHERE table_schema = 'public' 
AND table_type = 'BASE TABLE'
ORDER BY table_name;

-- Check RLS is enabled
SELECT tablename, rowsecurity as rls_enabled
FROM pg_tables WHERE schemaname = 'public'
AND tablename IN ('users', 'employees', 'company_settings');

-- Check default data exists
SELECT 
  'company_settings' as table_name, COUNT(*) as records 
FROM public.company_settings
UNION ALL
SELECT 
  'departments' as table_name, COUNT(*) as records 
FROM public.departments;
```

## 🎯 Expected Results After Fix

**Tables Created:**
- ✅ users (with roles: admin, hr, employee)
- ✅ employees (with Zambian fields: NRC, TPIN)
- ✅ company_settings (with nhima_rate column)
- ✅ departments (with 4 default departments)
- ✅ payroll_records (with tax calculations)

**Default Data:**
- ✅ Company settings with 2025 Zambian tax rates
- ✅ 4 default departments
- ✅ 9 Zambian public holidays for 2025

**Security:**
- ✅ Row Level Security (RLS) enabled
- ✅ Basic RLS policies created
- ✅ User authentication support

## 🚀 Next Steps After Fix

1. **Test the Database:**
   ```sql
   -- Should return no errors
   SELECT * FROM public.company_settings;
   ```

2. **Create Your First Admin User:**
   - Either via Supabase Dashboard > Authentication > Users
   - Or through your React application

3. **Follow the Full Deployment Guide:**
   - Use `DEPLOYMENT_SETUP_CHECKLIST.md`
   - Complete all phases for production setup

## 🆘 If You Still Get Errors

### Error: "relation does not exist"
**Solution:** Run `COMPLETE_MIGRATION.sql` to create all tables

### Error: "permission denied"
**Solution:** Ensure you're running in Supabase SQL Editor with proper permissions

### Error: "function does not exist"
**Solution:** Functions are created automatically in the migration script

### Error: "trigger does not exist"
**Solution:** Triggers are created in the migration script

## 📞 Support

If issues persist:
1. Run `COMPLETE_MIGRATION.sql` (handles 95% of issues)
2. Check the verification commands
3. Review the full `DEPLOYMENT_SETUP_CHECKLIST.md`
4. Verify your Supabase project is active and accessible

---

**🎉 Goal:** Get a fully functional GPTPayroll database with Zambian compliance ready for React app integration!