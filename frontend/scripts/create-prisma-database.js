import 'dotenv/config';
import pg from 'pg';

const { Client } = pg;

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
  if (!databaseName) {
    throw new Error('DATABASE_URL must include a database name, for example /rescuevn_app.');
  }

  const client = new Client({
    connectionString: maintenanceUrl,
    ssl: process.env.PGSSL === 'true' ? { rejectUnauthorized: false } : false
  });

  await client.connect();

  const exists = await client.query('SELECT 1 FROM pg_database WHERE datname = $1', [databaseName]);
  if (exists.rowCount === 0) {
    await client.query(`CREATE DATABASE ${quoteIdentifier(databaseName)}`);
    console.log(`Created PostgreSQL database: ${databaseName}`);
  } else {
    console.log(`PostgreSQL database already exists: ${databaseName}`);
  }

  await client.end();
}

main().catch((error) => {
  console.error(error.message);
  process.exit(1);
});
