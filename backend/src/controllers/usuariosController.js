const pool = require('../db/pool');
const bcrypt = require('bcryptjs');

// Remove o hash de senha antes de devolver o usuário ao cliente
function semSenha(usuario) {
  if (!usuario) return usuario;
  const { senha_hash, ...publico } = usuario;
  return publico;
}

// POST /usuarios/registrar
// Cadastra um novo usuário (cliente) com senha
async function registrar(req, res) {
  const { nome, email, telefone, senha } = req.body;

  try {
    const senha_hash = await bcrypt.hash(senha, 10);

    const result = await pool.query(
      `INSERT INTO usuarios (nome, email, telefone, senha_hash)
       VALUES ($1, $2, $3, $4)
       RETURNING id, nome, email, telefone, criado_em`,
      [nome, email, telefone || null, senha_hash]
    );

    return res.status(201).json({
      mensagem: 'Usuário cadastrado com sucesso.',
      dados: result.rows[0],
    });
  } catch (err) {
    if (err.code === '23505') {
      return res.status(409).json({ erro: 'E-mail já cadastrado.' });
    }
    console.error('[USUARIOS] Erro ao registrar:', err.message);
    return res.status(500).json({ erro: 'Erro interno ao cadastrar usuário.' });
  }
}

// POST /usuarios/login
// Autentica um usuário por e-mail e senha
async function login(req, res) {
  const { email, senha } = req.body;

  try {
    const result = await pool.query(
      'SELECT * FROM usuarios WHERE email = $1',
      [email]
    );

    if (result.rowCount === 0) {
      return res.status(401).json({ erro: 'E-mail ou senha inválidos.' });
    }

    const usuario = result.rows[0];

    // Usuários antigos (seed pré-Sprint 3) podem não ter senha definida
    if (!usuario.senha_hash) {
      return res.status(401).json({
        erro: 'Usuário sem senha cadastrada. Refaça o cadastro.',
      });
    }

    const confere = await bcrypt.compare(senha, usuario.senha_hash);
    if (!confere) {
      return res.status(401).json({ erro: 'E-mail ou senha inválidos.' });
    }

    return res.json({
      mensagem: 'Login realizado com sucesso.',
      dados: semSenha(usuario),
    });
  } catch (err) {
    console.error('[USUARIOS] Erro ao fazer login:', err.message);
    return res.status(500).json({ erro: 'Erro interno ao autenticar.' });
  }
}

// GET /usuarios/:id
// Consulta os dados públicos de um usuário
async function buscarPorId(req, res) {
  const { id } = req.params;
  try {
    const result = await pool.query(
      'SELECT id, nome, email, telefone, criado_em FROM usuarios WHERE id = $1',
      [id]
    );
    if (result.rowCount === 0) {
      return res.status(404).json({ erro: 'Usuário não encontrado.' });
    }
    return res.json({ dados: result.rows[0] });
  } catch (err) {
    console.error('[USUARIOS] Erro ao buscar por ID:', err.message);
    return res.status(500).json({ erro: 'Erro interno ao buscar usuário.' });
  }
}

module.exports = { registrar, login, buscarPorId };
