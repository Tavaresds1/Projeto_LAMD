const pool = require('../db/pool');

// GET /prestadores
async function listar(req, res) {
  try {
    const result = await pool.query(
      `SELECT id, nome, email, telefone, especialidade, disponivel, criado_em
       FROM prestadores
       ORDER BY nome ASC`
    );
    return res.json({ total: result.rowCount, dados: result.rows });
  } catch (err) {
    console.error('[PRESTADORES] Erro ao listar:', err.message);
    return res.status(500).json({ erro: 'Erro interno ao listar prestadores.' });
  }
}

// GET /prestadores/:id
async function buscarPorId(req, res) {
  const { id } = req.params;
  try {
    const result = await pool.query(
      'SELECT id, nome, email, telefone, especialidade, disponivel, criado_em FROM prestadores WHERE id = $1',
      [id]
    );
    if (result.rowCount === 0) {
      return res.status(404).json({ erro: 'Prestador não encontrado.' });
    }
    return res.json({ dados: result.rows[0] });
  } catch (err) {
    console.error('[PRESTADORES] Erro ao buscar:', err.message);
    return res.status(500).json({ erro: 'Erro interno ao buscar prestador.' });
  }
}

// POST /prestadores
async function criar(req, res) {
  const { nome, email, telefone, especialidade } = req.body;
  try {
    const result = await pool.query(
      `INSERT INTO prestadores (nome, email, telefone, especialidade)
       VALUES ($1, $2, $3, $4) RETURNING *`,
      [nome, email, telefone, especialidade || 'Hidráulica Geral']
    );
    return res.status(201).json({ mensagem: 'Prestador cadastrado.', dados: result.rows[0] });
  } catch (err) {
    if (err.code === '23505') {
      return res.status(409).json({ erro: 'E-mail já cadastrado.' });
    }
    console.error('[PRESTADORES] Erro ao criar:', err.message);
    return res.status(500).json({ erro: 'Erro interno ao cadastrar prestador.' });
  }
}

module.exports = { listar, buscarPorId, criar };
