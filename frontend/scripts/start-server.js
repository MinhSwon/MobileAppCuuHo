import { spawn } from 'node:child_process';

function run(command, args) {
  return new Promise((resolve, reject) => {
    const child = spawn(command, args, {
      stdio: 'inherit',
      shell: process.platform === 'win32',
    });

    child.on('exit', (code) => {
      if (code === 0) {
        resolve();
      } else {
        reject(new Error(`${command} ${args.join(' ')} exited with code ${code}`));
      }
    });
  });
}

if (process.env.DATABASE_URL && process.env.FORCE_JSON_DB !== 'true') {
  await run('npx', ['prisma', 'migrate', 'deploy']);
  await run('node', ['scripts/seed-if-empty.js']);
}

await import('../server.js');
