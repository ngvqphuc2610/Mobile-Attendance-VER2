#!/usr/bin/env node

/**
 * Test eSMS API Directly
 * Gửi SMS trực tiếp để kiểm tra eSMS API
 */

const axios = require('axios');
require('dotenv').config();

const ESMS_SEND_ENDPOINT =
  process.env.ESMS_SEND_ENDPOINT ||
  'https://rest.esms.vn/MainService.svc/json/SendMultipleMessage_V4_post_json/';

const config = {
  apiKey: process.env.ESMS_API_KEY,
  secretKey: process.env.ESMS_API_SECRET_KEY,
  brandName: process.env.ESMS_BRAND_NAME,
  smsType: Number.parseInt(process.env.ESMS_SMS_TYPE ?? '1', 10),
};

async function testEsms() {
  console.log('🧪 eSMS API Direct Test');
  console.log('=======================\n');

  console.log('📋 Configuration:');
  console.log(`  API Key: ${config.apiKey}`);
  console.log(`  Secret Key: ${config.secretKey}`);
  console.log(`  Brand Name: ${config.brandName}`);
  console.log(`  SMS Type: ${config.smsType}`);
  console.log(`  Endpoint: ${ESMS_SEND_ENDPOINT}\n`);

  const params = {
    ApiKey: config.apiKey,
    SecretKey: config.secretKey,
    Phone: '84393102373',
    Content: 'Test OTP: 123456',
    SmsType: config.smsType,
    IsUnicode: 0,
    BrandName: config.brandName,
  };

  console.log('📤 Sending SMS...');
  console.log(`  Phone: ${params.Phone}`);
  console.log(`  Content: ${params.Content}`);
  console.log(`  SmsType: ${params.SmsType}\n`);

  try {
    const response = await axios.post(ESMS_SEND_ENDPOINT, params, {
      timeout: 10000,
      headers: {
        'Content-Type': 'application/json',
      },
    });

    console.log('✅ Response received:');
    console.log(JSON.stringify(response.data, null, 2));

    const data = response.data ?? {};
    if (`${data.CodeResult}` === '100') {
      console.log('\n✅ SMS sent successfully!');
      console.log(`  SMSID: ${data.SMSID || data.RefId}`);
    } else {
      console.log(`\n❌ eSMS error: CodeResult=${data.CodeResult}`);
      console.log(`  ErrorMessage: ${data.ErrorMessage}`);
    }
  } catch (error) {
    console.log('❌ Error:');
    if (error.response) {
      console.log(`  Status: ${error.response.status}`);
      console.log(`  Data: ${JSON.stringify(error.response.data, null, 2)}`);
    } else {
      console.log(`  Message: ${error.message}`);
    }
  }
}

testEsms();

