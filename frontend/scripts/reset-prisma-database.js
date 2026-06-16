import 'dotenv/config';
import pg from 'pg';

const { Client } = pg;
const SAFE_DATABASE_NAME = 'rescuevn_app';

function quoteIdentifier(value) {
  return `"${value.replaceAll('"', '""')}"`;
}

function getMaintenanceUrl(databaseUrl) {
  const url = new URL(databaseUrl);
  const databaseName = url.pathname.replace(/^\//, '');
  url.pathname = '/postgres';
  return { maintenanceUrl: url.toString(), databaseName };
}

async function main() {
  if (!process.env.DATABASE_URL) {
    throw new Error('DATABASE_URL is missing. Create a .env file first.');
  }

  const { maintenanceUrl, databaseName } = getMaintenanceUrl(process.env.DATABASE_URL);
  if (databaseName !== SAFE_DATABASE_NAME) {
    throw new Error(`Refusing to reset "${databaseName}". This script only resets "${SAFE_DATABASE_NAME}".`);
  }

  const client = new Client({
    connectionString: maintenanceUrl,
    ssl: process.env.PGSSL === 'true' ? { rejectUnauthorized: false } : false
  });

  await client.connect();

  await client.query(
    `SELECT pg_terminate_backend(pid)
     FROM pg_stat_activity
     WHERE datname = $1 AND pid <> pg_backend_pid()`,
    [databaseName]
  );
  await client.query(`DROP DATABASE IF EXISTS ${quoteIdentifier(databaseName)}`);
  await client.query(`CREATE DATABASE ${quoteIdentifier(databaseName)}`);
  await client.end();

  console.log(`Reset PostgreSQL database: ${databaseName}`);
}

main().catch((error) => {
  console.error(error.message);
  process.exit(1);
});
