const pool = require('./pool');
const bcrypt = require('bcryptjs');

async function migrate() {
  const client = await pool.connect();
  try {
    await client.query('BEGIN');

    // Tabela de usuários (clientes)
    await client.query(`
      CREATE TABLE IF NOT EXISTS usuarios (
        id          SERIAL PRIMARY KEY,
        nome        VARCHAR(100) NOT NULL,
        email       VARCHAR(150) NOT NULL UNIQUE,
        telefone    VARCHAR(20),
        senha_hash  VARCHAR(255),
        criado_em   TIMESTAMP DEFAULT NOW()
      );
    `);

    // Garante a coluna senha_hash em bancos criados antes da Sprint 3
    await client.query(`
      ALTER TABLE usuarios ADD COLUMN IF NOT EXISTS senha_hash VARCHAR(255);
    `);

    // Tabela de prestadores de serviço
    await client.query(`
      CREATE TABLE IF NOT EXISTS prestadores (
        id              SERIAL PRIMARY KEY,
        nome            VARCHAR(100) NOT NULL,
        email           VARCHAR(150) NOT NULL UNIQUE,
        telefone        VARCHAR(20),
        especialidade   VARCHAR(100) DEFAULT 'Hidráulica Geral',
        disponivel      BOOLEAN DEFAULT TRUE,
        criado_em       TIMESTAMP DEFAULT NOW()
      );
    `);

    // Tabela de solicitações de serviço
    await client.query(`
      CREATE TABLE IF NOT EXISTS solicitacoes (
        id              SERIAL PRIMARY KEY,
        usuario_id      INTEGER NOT NULL REFERENCES usuarios(id),
        prestador_id    INTEGER REFERENCES prestadores(id),
        tipo_servico    VARCHAR(100) NOT NULL,
        descricao       TEXT NOT NULL,
        endereco        VARCHAR(255) NOT NULL,
        status          VARCHAR(30) NOT NULL DEFAULT 'PENDENTE'
                          CHECK (status IN ('PENDENTE','ACEITO','EM_ANDAMENTO','CONCLUIDO','RECUSADO')),
        criado_em       TIMESTAMP DEFAULT NOW(),
        atualizado_em   TIMESTAMP DEFAULT NOW()
      );
    `);

    // Seed: alguns registros de exemplo
    // Senha padrão dos usuários de exemplo: "123456"
    const senhaSeed = await bcrypt.hash('123456', 10);
    await client.query(
      `INSERT INTO usuarios (nome, email, telefone, senha_hash)
       VALUES
        ('João Silva', 'joao@email.com', '31999990001', $1),
        ('Maria Souza', 'maria@email.com', '31999990002', $1)
       ON CONFLICT (email) DO UPDATE
         SET senha_hash = COALESCE(usuarios.senha_hash, EXCLUDED.senha_hash);`,
      [senhaSeed]
    );

    await client.query(`
      INSERT INTO prestadores (nome, email, telefone, especialidade)
      VALUES
        ('Carlos Encanador', 'carlos@sos.com', '31988880001', 'Desentupimento'),
        ('Ana Hidráulica', 'ana@sos.com', '31988880002', 'Instalações Hidráulicas')
      ON CONFLICT (email) DO NOTHING;
    `);

    await client.query('COMMIT');
    console.log('[MIGRATE] Tabelas criadas e seed inserido com sucesso.');
  } catch (err) {
    await client.query('ROLLBACK');
    console.error('[MIGRATE] Erro:', err.message);
    throw err;
  } finally {
    client.release();
  }
}

module.exports = migrate;
