const pool = require('../db/pool');
const bcrypt = require('bcryptjs');

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

// POST /prestadores/login
async function login(req, res) {
  const { email, senha } = req.body;
  try {
    const result = await pool.query(
      'SELECT * FROM prestadores WHERE email = $1',
      [email]
    );
    if (result.rowCount === 0) {
      return res.status(401).json({ erro: 'E-mail ou senha inválidos.' });
    }
    const prestador = result.rows[0];
    if (!prestador.senha_hash) {
      return res.status(401).json({ erro: 'Conta sem senha configurada.' });
    }
    const ok = await bcrypt.compare(senha, prestador.senha_hash);
    if (!ok) {
      return res.status(401).json({ erro: 'E-mail ou senha inválidos.' });
    }
    const { senha_hash, ...dados } = prestador;
    return res.json({ mensagem: 'Login realizado.', dados });
  } catch (err) {
    console.error('[PRESTADORES] Erro ao fazer login:', err.message);
    return res.status(500).json({ erro: 'Erro interno ao autenticar.' });
  }
}

module.exports = { listar, buscarPorId, criar, login };
