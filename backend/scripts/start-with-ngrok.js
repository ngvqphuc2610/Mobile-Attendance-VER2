const { spawn } = require('child_process');
const fs = require('fs');
const path = require('path');

console.log('🚀 Starting server with ngrok...');

// Start the main server
const server = spawn('npm', ['run', 'dev'], {
  stdio: 'inherit',
  shell: true
});

// Wait a bit for server to start, then start ngrok
setTimeout(() => {
  console.log('🌐 Starting ngrok tunnel...');
  
  const ngrok = spawn('ngrok', ['http', '3000', '--log=stdout'], {
    stdio: 'pipe',
    shell: true
  });

  ngrok.stdout.on('data', (data) => {
    const output = data.toString();
    console.log(output);
    
    // Extract ngrok URL
    const urlMatch = output.match(/https:\/\/[a-z0-9-]+\.ngrok\.io/);
    if (urlMatch) {
      const ngrokUrl = urlMatch[0];
      console.log(`\n🎉 Ngrok URL: ${ngrokUrl}`);
      console.log(`📱 Update your Flutter app to use: ${ngrokUrl}/api`);
      
      // Optionally write to a file for easy access
      fs.writeFileSync(
        path.join(__dirname, '../ngrok-url.txt'), 
        `${ngrokUrl}/api`
      );
    }
  });

  ngrok.stderr.on('data', (data) => {
    console.error(`Ngrok error: ${data}`);
  });

}, 3000);

// Handle cleanup
process.on('SIGINT', () => {
  console.log('\n🛑 Shutting down...');
  server.kill();
  process.exit();
});