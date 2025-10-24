#!/usr/bin/env node

/**
 * Migration Runner
 * Chạy các migration SQL để cập nhật database schema
 */

const fs = require('fs');
const path = require('path');
const mysql = require('mysql2/promise');
require('dotenv').config({ path: path.join(__dirname, '../../.env') });

const DB_CONFIG = {
  host: process.env.DB_HOST || 'localhost',
  user: process.env.DB_USER || 'root',
  password: process.env.DB_PASSWORD || '',
  database: process.env.DB_NAME ,
};

async function runMigration() {
  let connection;
  try {
    console.log('🔄 Connecting to database...');
    connection = await mysql.createConnection(DB_CONFIG);
    console.log('✅ Connected to database');

    // Read migration file
    const migrationPath = path.join(__dirname, '../../database/migrations/001_add_sms_id_to_phone_otp_requests.sql');
    const sql = fs.readFileSync(migrationPath, 'utf8');

    console.log('\n📝 Running migration...');
    console.log('---');

    // Split by semicolon and execute each statement
    const statements = sql
      .split(';')
      .map(s => s.trim())
      .filter(s => s && !s.startsWith('--'));

    for (const statement of statements) {
      console.log(`\n▶️  ${statement.substring(0, 80)}...`);
      try {
        await connection.execute(statement);
        console.log('✅ Success');
      } catch (error) {
        if (error.code === 'ER_DUP_FIELDNAME') {
          console.log('⚠️  Column already exists (skipping)');
        } else if (error.code === 'ER_DUP_KEYNAME') {
          console.log('⚠️  Index already exists (skipping)');
        } else {
          throw error;
        }
      }
    }

    console.log('\n---');
    console.log('✅ Migration completed successfully!');

    // Verify the column
    console.log('\n📊 Verifying column...');
    const [rows] = await connection.execute(
      `SELECT COLUMN_NAME, COLUMN_TYPE, IS_NULLABLE 
       FROM INFORMATION_SCHEMA.COLUMNS 
       WHERE TABLE_NAME = 'phone_otp_requests' AND COLUMN_NAME = 'sms_id'`
    );

    if (rows.length > 0) {
      console.log('✅ Column verified:');
      console.log(rows[0]);
    } else {
      console.log('❌ Column not found!');
    }

  } catch (error) {
    console.error('❌ Migration failed:', error.message);
    process.exit(1);
  } finally {
    if (connection) {
      await connection.end();
    }
  }
}

runMigration();

