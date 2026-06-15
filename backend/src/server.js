require('dotenv').config();
const express = require('express');
const cors = require('cors');
const migrate = require('./db/migrate');

const solicitacoesRouter = require('./routes/solicitacoes');
const prestadoresRouter  = require('./routes/prestadores');
const usuariosRouter     = require('./routes/usuarios');

const app = express();

// ── Middlewares globais ─────────────────────────────────────
app.use(cors());
app.use(express.json());

// ── Healthcheck ─────────────────────────────────────────────
app.get('/health', (req, res) => {
  res.json({ status: 'ok', servico: 'SOS dos Reparos API', versao: '1.0.0' });
});

// ── Rotas ───────────────────────────────────────────────────
app.use('/solicitacoes', solicitacoesRouter);
app.use('/prestadores',  prestadoresRouter);
app.use('/usuarios',     usuariosRouter);

// ── 404 ─────────────────────────────────────────────────────
app.use((req, res) => {
  res.status(404).json({ erro: `Rota "${req.method} ${req.path}" não encontrada.` });
});

// ── Handler de erros global ──────────────────────────────────
app.use((err, req, res, next) => {
  console.error('[SERVER] Erro não tratado:', err.message);
  res.status(500).json({ erro: 'Erro interno do servidor.' });
});

// ── Inicialização ────────────────────────────────────────────
const PORT = process.env.PORT || 3000;

migrate()
  .then(() => {
    app.listen(PORT, () => {
      console.log(`[SERVER] SOS dos Reparos API rodando em http://localhost:${PORT}`);
      console.log(`[SERVER] Endpoints disponíveis:`);
      console.log(`         GET    /health`);
      console.log(`         POST   /solicitacoes`);
      console.log(`         GET    /solicitacoes`);
      console.log(`         GET    /solicitacoes/:id`);
      console.log(`         PATCH  /solicitacoes/:id/status`);
      console.log(`         GET    /prestadores`);
      console.log(`         GET    /prestadores/:id`);
      console.log(`         POST   /prestadores`);
      console.log(`         POST   /usuarios/registrar`);
      console.log(`         POST   /usuarios/login`);
      console.log(`         GET    /usuarios/:id`);
    });
  })
  .catch((err) => {
    console.error('[SERVER] Falha ao inicializar:', err.message);
    process.exit(1);
  });
