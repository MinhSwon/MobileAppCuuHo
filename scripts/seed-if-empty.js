import 'dotenv/config';
import { prisma } from '../src/lib/prisma.js';

async function main() {
  const userCount = await prisma.user.count();
  if (userCount > 0) {
    console.log(`Prisma seed skipped: ${userCount} users already exist.`);
    return;
  }

  console.log('Prisma seed required: users table is empty.');
  const { spawn } = await import('node:child_process');
  await new Promise((resolve, reject) => {
    const child = spawn('node', ['scripts/seed-prisma.js'], {
      stdio: 'inherit',
      shell: process.platform === 'win32',
    });

    child.on('exit', (code) => {
      if (code === 0) resolve();
      else reject(new Error(`seed-prisma exited with code ${code}`));
    });
  });
}

main()
  .catch(error => {
    console.error(error);
    process.exit(1);
  })
  .finally(async () => {
    await prisma.$disconnect();
  });
