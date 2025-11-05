-- ==========================================
-- QUICK FIX FOR MISSING NHIMA_RATE COLUMN
-- Run this to add the missing nhima_rate column to company_settings
-- ==========================================

-- First, check if the column exists
DO $$
BEGIN
    -- Check if nhima_rate column exists
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'company_settings' 
        AND column_name = 'nhima_rate'
    ) THEN
        -- Add the missing nhima_rate column
        ALTER TABLE public.company_settings 
        ADD COLUMN nhima_rate DECIMAL(5,4) DEFAULT 0.01;
        
        RAISE NOTICE 'Added nhima_rate column to company_settings table';
    ELSE
        RAISE NOTICE 'nhima_rate column already exists';
    END IF;
END $$;

-- Update existing records to have the default nhima_rate if NULL
UPDATE public.company_settings 
SET nhima_rate = 0.01 
WHERE nhima_rate IS NULL;

-- Verify the column was added successfully
SELECT 
    column_name, 
    data_type, 
    column_default,
    is_nullable
FROM information_schema.columns 
WHERE table_name = 'company_settings' 
AND column_name = 'nhima_rate';

-- Now insert the default settings with nhima_rate
INSERT INTO public.company_settings (
  company_name,
  registration_number,
  tax_id,
  address,
  phone,
  email,
  website,
  paye_tax_bands,
  napsa_cap,
  nhima_rate
) VALUES (
  'GPTPayroll Demo Company Ltd',
  '2019001234',
  '1234567890',
  'Plot 123, Business District, Lusaka, Zambia',
  '+260 211 123456',
  'info@gptpayrolldemo.com',
  'www.gptpayrolldemo.com',
  '{
    "bands": [
      {"min": 0, "max": 5100, "rate": 0.00},
      {"min": 5100, "max": 7100, "rate": 0.20},
      {"min": 7100, "max": 9200, "rate": 0.30},
      {"min": 9200, "max": null, "rate": 0.37}
    ]
  }',
  1149.60,
  0.01
) ON CONFLICT (company_name) DO NOTHING;

-- Show current company_settings structure
SELECT 'nhima_rate column fix completed successfully' as status;