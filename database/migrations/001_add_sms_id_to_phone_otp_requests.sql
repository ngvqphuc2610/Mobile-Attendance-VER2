-- Migration: Add sms_id column to phone_otp_requests table
-- Purpose: Track eSMS SMSID for SMS delivery report checking
-- Date: 2025-10-24

ALTER TABLE `phone_otp_requests` 
ADD COLUMN `sms_id` varchar(255) DEFAULT NULL AFTER `verified_at`;

-- Add index for faster lookups
CREATE INDEX `idx_sms_id` ON `phone_otp_requests` (`sms_id`);

-- Verify the column was added
SELECT COLUMN_NAME, COLUMN_TYPE, IS_NULLABLE 
FROM INFORMATION_SCHEMA.COLUMNS 
WHERE TABLE_NAME = 'phone_otp_requests' AND COLUMN_NAME = 'sms_id';

