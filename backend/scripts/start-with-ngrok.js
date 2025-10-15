const { spawn } = require('child_process');
const { updateEnvWithUrl } = require('./update-env');

console.log('🚀 Starting server with ngrok...');

// Start the backend in development mode
const server = spawn('npm', ['run', 'dev'], {
  stdio: 'inherit',
  shell: true,
});

// Give the server a moment to boot, then launch ngrok
setTimeout(() => {
  console.log('🌐 Starting ngrok tunnel...');

  const ngrok = spawn('ngrok', ['http', '3000', '--log=stdout'], {
    stdio: 'pipe',
    shell: true,
  });

  let lastPublicUrl = null;

  ngrok.stdout.on('data', (data) => {
    const output = data.toString();
    process.stdout.write(output);

    // Capture the https ngrok URL from the logs (supports ngrok-free.app & ngrok.io)
    const urlMatch = output.match(/https:\/\/[a-z0-9.-]+\.ngrok[-\w]*\.[a-z]+/);
    if (urlMatch) {
      const publicUrl = urlMatch[0];

      if (publicUrl !== lastPublicUrl) {
        lastPublicUrl = publicUrl;
        console.log(`\n🔗 Ngrok URL detected: ${publicUrl}`);
        console.log(`📝 Writing ${publicUrl}/api to Flutter .env...`);

        try {
          updateEnvWithUrl(publicUrl);
        } catch (error) {
          console.error('Failed to update .env with ngrok URL:', error.message);
        }
      }
    }
  });

  ngrok.stderr.on('data', (data) => {
    process.stderr.write(`Ngrok error: ${data}`);
  });

  ngrok.on('close', (code) => {
    console.log(`ngrok exited with code ${code}`);
  });
}, 3000);

process.on('SIGINT', () => {
  console.log('\n👋 Shutting down...');
  server.kill();
  process.exit();
});
