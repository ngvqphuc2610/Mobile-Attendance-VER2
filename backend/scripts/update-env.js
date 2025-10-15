const fs = require('fs');
const path = require('path');
const fetch = require('node-fetch');

const NGROK_API = 'http://127.0.0.1:4040/api/tunnels';
const ROOT_ENV_PATH = path.resolve(__dirname, '..', '..', '.env');

async function fetchHttpsTunnel() {
  const response = await fetch(NGROK_API);

  if (!response.ok) {
    throw new Error(`Unable to query ngrok API: ${response.status} ${response.statusText}`);
  }

  const data = await response.json();
  const httpsTunnel = data.tunnels?.find((tunnel) =>
    typeof tunnel.public_url === 'string' && tunnel.public_url.startsWith('https://'),
  );

  if (!httpsTunnel) {
    throw new Error('No https ngrok tunnel is currently running.');
  }

  return httpsTunnel.public_url;
}

function updateEnvFile(envPath, key, value) {
  let content = '';
  if (fs.existsSync(envPath)) {
    content = fs.readFileSync(envPath, 'utf8');
  }

  const pattern = new RegExp(`^${key}=.*$`, 'm');
  const replacement = `${key}=${value}`;

  if (pattern.test(content)) {
    content = content.replace(pattern, replacement);
  } else {
    const trimmed = content.trimEnd();
    content = trimmed.length > 0 ? `${trimmed}\n${replacement}\n` : `${replacement}\n`;
  }

  fs.writeFileSync(envPath, content);
}

function updateEnvWithUrl(publicUrl) {
  if (typeof publicUrl !== 'string' || publicUrl.trim().length === 0) {
    throw new Error('Invalid public URL provided to updateEnvWithUrl.');
  }

  const apiUrl = `${publicUrl.replace(/\/$/, '')}/api`;
  updateEnvFile(ROOT_ENV_PATH, 'API_URL', apiUrl);
  console.log(`Updated ${ROOT_ENV_PATH} with API_URL=${apiUrl}`);
  return apiUrl;
}

async function runStandalone() {
  const publicUrl = await fetchHttpsTunnel();
  updateEnvWithUrl(publicUrl);
}

if (require.main === module) {
  runStandalone().catch((error) => {
    console.error('Failed to update .env with ngrok URL:', error.message);
    process.exitCode = 1;
  });
}

module.exports = {
  fetchHttpsTunnel,
  updateEnvFile,
  updateEnvWithUrl,
};
