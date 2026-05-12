const { Pool } = require('pg');
require('dotenv').config();

const pool = new Pool({
  host: process.env.DB_HOST || 'localhost',
  port: process.env.DB_PORT || 5432,
  database: process.env.DB_NAME || 'sos_reparos',
  user: process.env.DB_USER || 'postgres',
  password: process.env.DB_PASSWORD || 'postgres',
});

pool.on('connect', () => {
  console.log('[DB] Conectado ao PostgreSQL');
});

pool.on('error', (err) => {
  console.error('[DB] Erro inesperado no pool:', err.message);
});

module.exports = pool;
