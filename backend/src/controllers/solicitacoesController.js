const pool = require('../db/pool');
const { publicar } = require('../mq/publisher');

// POST /solicitacoes
// Cria uma nova solicitação de serviço hidráulico
async function criar(req, res) {
  const { usuario_id, tipo_servico, descricao, endereco } = req.body;

  try {
    const result = await pool.query(
      `INSERT INTO solicitacoes (usuario_id, tipo_servico, descricao, endereco)
       VALUES ($1, $2, $3, $4)
       RETURNING *`,
      [usuario_id, tipo_servico, descricao, endereco]
    );

    const nova = result.rows[0];
    await publicar('solicitacao.criada', {
      id: nova.id,
      usuario_id: nova.usuario_id,
      tipo_servico: nova.tipo_servico,
      endereco: nova.endereco,
      status: nova.status,
      criado_em: nova.criado_em,
    });

    return res.status(201).json({
      mensagem: 'Solicitação criada com sucesso.',
      dados: nova,
    });
  } catch (err) {
    console.error('[SOLICITACOES] Erro ao criar:', err.message);
    return res.status(500).json({ erro: 'Erro interno ao criar solicitação.' });
  }
}

// GET /solicitacoes
// Lista solicitações com filtro opcional por status e usuario_id
async function listar(req, res) {
  const { status, usuario_id, prestador_id } = req.query;

  let query = `
    SELECT
      s.id, s.tipo_servico, s.descricao, s.endereco, s.status,
      s.criado_em, s.atualizado_em,
      s.valor_mao_de_obra, s.valor_pecas,
      u.nome AS usuario_nome, u.telefone AS usuario_telefone,
      p.nome AS prestador_nome, p.telefone AS prestador_telefone
    FROM solicitacoes s
    JOIN usuarios u ON u.id = s.usuario_id
    LEFT JOIN prestadores p ON p.id = s.prestador_id
    WHERE 1=1
  `;
  const params = [];

  if (status) {
    params.push(status.toUpperCase());
    query += ` AND s.status = $${params.length}`;
  }
  if (usuario_id) {
    params.push(usuario_id);
    query += ` AND s.usuario_id = $${params.length}`;
  }
  if (prestador_id) {
    params.push(prestador_id);
    query += ` AND s.prestador_id = $${params.length}`;
  }

  // Exclui solicitações já recusadas por este prestador específico
  if (req.query.disponivel_para) {
    params.push(req.query.disponivel_para);
    query += ` AND s.id NOT IN (
      SELECT solicitacao_id FROM recusas WHERE prestador_id = $${params.length}
    )`;
  }

  query += ' ORDER BY s.criado_em DESC';

  try {
    const result = await pool.query(query, params);
    return res.json({ total: result.rowCount, dados: result.rows });
  } catch (err) {
    console.error('[SOLICITACOES] Erro ao listar:', err.message);
    return res.status(500).json({ erro: 'Erro interno ao listar solicitações.' });
  }
}

// GET /solicitacoes/:id
// Retorna uma solicitação específica pelo ID
async function buscarPorId(req, res) {
  const { id } = req.params;

  try {
    const result = await pool.query(
      `SELECT
        s.id, s.tipo_servico, s.descricao, s.endereco, s.status,
        s.criado_em, s.atualizado_em,
        s.valor_mao_de_obra, s.valor_pecas,
        u.nome AS usuario_nome, u.email AS usuario_email, u.telefone AS usuario_telefone,
        p.nome AS prestador_nome, p.email AS prestador_email, p.telefone AS prestador_telefone,
        p.especialidade AS prestador_especialidade
       FROM solicitacoes s
       JOIN usuarios u ON u.id = s.usuario_id
       LEFT JOIN prestadores p ON p.id = s.prestador_id
       WHERE s.id = $1`,
      [id]
    );

    if (result.rowCount === 0) {
      return res.status(404).json({ erro: 'Solicitação não encontrada.' });
    }

    return res.json({ dados: result.rows[0] });
  } catch (err) {
    console.error('[SOLICITACOES] Erro ao buscar por ID:', err.message);
    return res.status(500).json({ erro: 'Erro interno ao buscar solicitação.' });
  }
}

// PATCH /solicitacoes/:id/status
// Atualiza o status de uma solicitação (fluxo de estados)
async function atualizarStatus(req, res) {
  const { id } = req.params;
  const { status, prestador_id, valor_mao_de_obra, valor_pecas } = req.body;

  const statusValidos = ['ACEITO', 'EM_ANDAMENTO', 'CONCLUIDO', 'RECUSADO'];
  if (!statusValidos.includes(status)) {
    return res.status(400).json({
      erro: `Status inválido. Valores aceitos: ${statusValidos.join(', ')}.`,
    });
  }

  try {
    // Verifica se a solicitação existe
    const check = await pool.query('SELECT * FROM solicitacoes WHERE id = $1', [id]);
    if (check.rowCount === 0) {
      return res.status(404).json({ erro: 'Solicitação não encontrada.' });
    }

    const atual = check.rows[0];

    // Regra de negócio: não pode regredir status
    const ordem = ['PENDENTE', 'ACEITO', 'EM_ANDAMENTO', 'CONCLUIDO', 'RECUSADO'];
    const idxAtual = ordem.indexOf(atual.status);
    const idxNovo = ordem.indexOf(status);
    if (idxNovo < idxAtual && status !== 'RECUSADO') {
      return res.status(409).json({
        erro: `Não é possível regredir o status de "${atual.status}" para "${status}".`,
      });
    }

    let updateQuery, updateParams;
    if (status === 'CONCLUIDO') {
      updateQuery = `
        UPDATE solicitacoes
        SET status            = $1,
            prestador_id      = COALESCE($2, prestador_id),
            valor_mao_de_obra = COALESCE($4, valor_mao_de_obra),
            valor_pecas       = COALESCE($5, valor_pecas),
            atualizado_em     = NOW()
        WHERE id = $3
        RETURNING *`;
      updateParams = [
        status,
        prestador_id || null,
        id,
        valor_mao_de_obra != null ? parseFloat(valor_mao_de_obra) : null,
        valor_pecas       != null ? parseFloat(valor_pecas)       : null,
      ];
    } else {
      updateQuery = `
        UPDATE solicitacoes
        SET status        = $1,
            prestador_id  = COALESCE($2, prestador_id),
            atualizado_em = NOW()
        WHERE id = $3
        RETURNING *`;
      updateParams = [status, prestador_id || null, id];
    }

    const result = await pool.query(updateQuery, updateParams);

    const atualizada = result.rows[0];
    await publicar('status.atualizado', {
      id: atualizada.id,
      status: atualizada.status,
      prestador_id: atualizada.prestador_id,
      atualizado_em: atualizada.atualizado_em,
    });

    if (status === 'ACEITO') {
      await publicar('solicitacao.aceita', {
        id: atualizada.id,
        prestador_id: atualizada.prestador_id,
        atualizado_em: atualizada.atualizado_em,
      });
    }

    return res.json({
      mensagem: `Status atualizado para "${status}".`,
      dados: atualizada,
    });
  } catch (err) {
    console.error('[SOLICITACOES] Erro ao atualizar status:', err.message);
    return res.status(500).json({ erro: 'Erro interno ao atualizar status.' });
  }
}

// POST /solicitacoes/:id/recusar
// Registra a recusa de um prestador específico.
// A solicitação permanece PENDENTE até que todos os prestadores disponíveis recusem.
async function recusar(req, res) {
  const { id } = req.params;
  const { prestador_id } = req.body;

  if (!prestador_id) {
    return res.status(400).json({ erro: 'prestador_id é obrigatório.' });
  }

  try {
    const check = await pool.query(
      'SELECT status FROM solicitacoes WHERE id = $1',
      [id]
    );
    if (check.rowCount === 0) {
      return res.status(404).json({ erro: 'Solicitação não encontrada.' });
    }
    if (check.rows[0].status !== 'PENDENTE') {
      return res.status(409).json({
        erro: 'Só é possível recusar solicitações com status PENDENTE.',
      });
    }

    // Registra a recusa (ignora duplicata silenciosamente)
    await pool.query(
      `INSERT INTO recusas (solicitacao_id, prestador_id)
       VALUES ($1, $2) ON CONFLICT DO NOTHING`,
      [id, prestador_id]
    );

    // Verifica se todos os prestadores disponíveis já recusaram
    const totalResult = await pool.query(
      'SELECT COUNT(*) FROM prestadores WHERE disponivel = true'
    );
    const recusasResult = await pool.query(
      'SELECT COUNT(*) FROM recusas WHERE solicitacao_id = $1',
      [id]
    );

    const totalPrestadores = parseInt(totalResult.rows[0].count, 10);
    const totalRecusas = parseInt(recusasResult.rows[0].count, 10);

    if (totalRecusas >= totalPrestadores) {
      await pool.query(
        `UPDATE solicitacoes SET status = 'RECUSADO', atualizado_em = NOW() WHERE id = $1`,
        [id]
      );
      await publicar('status.atualizado', {
        id: parseInt(id, 10),
        status: 'RECUSADO',
        atualizado_em: new Date(),
      });
      return res.json({
        mensagem: 'Todos os prestadores recusaram. Solicitação encerrada.',
        status: 'RECUSADO',
      });
    }

    await publicar('solicitacao.recusada_por_prestador', {
      solicitacao_id: parseInt(id, 10),
      prestador_id,
      total_recusas: totalRecusas,
      total_prestadores: totalPrestadores,
    });

    return res.json({
      mensagem: 'Recusa registrada. Solicitação ainda disponível para outros prestadores.',
      status: 'PENDENTE',
    });
  } catch (err) {
    console.error('[SOLICITACOES] Erro ao recusar:', err.message);
    return res.status(500).json({ erro: 'Erro interno ao registrar recusa.' });
  }
}

module.exports = { criar, listar, buscarPorId, atualizarStatus, recusar };
