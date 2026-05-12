# SOS dos Reparos – Backend REST (Sprint 1)

API RESTful para solicitação de serviços hidráulicos.  
**Stack:** Node.js · Express · PostgreSQL · Docker

---

## Pré-requisitos

- Node.js 18+
- Docker e Docker Compose

---

## Como executar

```bash
# 1. Suba o banco de dados
docker-compose up -d

# 2. Instale as dependências
npm install

# 3. Configure as variáveis de ambiente
cp .env.example .env

# 4. Inicie o servidor (desenvolvimento)
npm run dev
```

A API estará disponível em `http://localhost:3000`.  
As tabelas são criadas automaticamente na primeira execução.

---

## Endpoints

| Método | Rota                          | Descrição                        |
|--------|-------------------------------|----------------------------------|
| GET    | /health                       | Healthcheck da API               |
| POST   | /solicitacoes                 | Criar nova solicitação           |
| GET    | /solicitacoes                 | Listar solicitações (c/ filtros) |
| GET    | /solicitacoes/:id             | Detalhar uma solicitação         |
| PATCH  | /solicitacoes/:id/status      | Atualizar status                 |
| GET    | /prestadores                  | Listar prestadores               |
| GET    | /prestadores/:id              | Detalhar um prestador            |
| POST   | /prestadores                  | Cadastrar prestador              |

### Filtros disponíveis em GET /solicitacoes

| Query param   | Exemplo              |
|---------------|----------------------|
| status        | ?status=PENDENTE     |
| usuario_id    | ?usuario_id=1        |
| prestador_id  | ?prestador_id=2      |

### Ciclo de vida do status

```
PENDENTE → ACEITO → EM_ANDAMENTO → CONCLUIDO
         ↘ RECUSADO
```

---

## Schema do Banco de Dados

```sql
usuarios     (id, nome, email, telefone, criado_em)
prestadores  (id, nome, email, telefone, especialidade, disponivel, criado_em)
solicitacoes (id, usuario_id, prestador_id, tipo_servico, descricao,
              endereco, status, criado_em, atualizado_em)
```

---

## Estrutura do Projeto

```
src/
├── server.js                   # Entry point
├── db/
│   ├── pool.js                 # Conexão PostgreSQL
│   └── migrate.js              # Criação de tabelas e seed
├── controllers/
│   ├── solicitacoesController.js
│   └── prestadoresController.js
├── routes/
│   ├── solicitacoes.js
│   └── prestadores.js
└── middlewares/
    └── validacao.js
```
