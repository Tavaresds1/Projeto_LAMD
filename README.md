# SOS dos Reparos

Plataforma distribuída para solicitação de serviços hidráulicos, no modelo
cliente/prestador, orientada a eventos.

**Stack:** Node.js · Express · PostgreSQL · RabbitMQ (MOM) · Flutter · Docker

## Componentes do repositório

| Pasta           | Sprint | Descrição |
|-----------------|--------|-----------|
| [`backend/`](backend/)         | 1–2 | API REST + integração com o MOM (RabbitMQ) |
| [`app_cliente/`](app_cliente/) | 3   | App Flutter do **cliente** (este sprint) |
| [`docs/`](docs/)               | 1–2 | Proposta, diagrama de arquitetura e docs de eventos |
| [`postman/`](postman/)         | 1   | Coleção de testes da API |

> A documentação do app cliente está em
> [`app_cliente/README.md`](app_cliente/README.md) e
> [`app_cliente/ARQUITETURA.md`](app_cliente/ARQUITETURA.md).

---

## Backend REST

API RESTful para solicitação de serviços hidráulicos.  
**Stack:** Node.js · Express · PostgreSQL · Docker

---

## Pré-requisitos

- Node.js 18+
- Docker e Docker Compose

---

## Como executar

```bash
cd backend

# 1. Suba o banco de dados e o RabbitMQ (MOM)
docker-compose up -d

# 2. Instale as dependências
npm install

# 3. Inicie o servidor (desenvolvimento)
npm run dev

# (opcional) em outro terminal, suba o consumidor de eventos
npm run consumer
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
| POST   | /usuarios/registrar           | Cadastrar usuário (cliente)      |
| POST   | /usuarios/login               | Autenticar usuário               |
| GET    | /usuarios/:id                 | Detalhar um usuário              |

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
usuarios     (id, nome, email, telefone, senha_hash, criado_em)
prestadores  (id, nome, email, telefone, especialidade, disponivel, criado_em)
solicitacoes (id, usuario_id, prestador_id, tipo_servico, descricao,
              endereco, status, criado_em, atualizado_em)
```

---

## Estrutura do Backend

```
backend/src/
├── server.js                   # Entry point
├── db/
│   ├── pool.js                 # Conexão PostgreSQL
│   └── migrate.js              # Criação de tabelas e seed
├── controllers/
│   ├── solicitacoesController.js
│   ├── prestadoresController.js
│   └── usuariosController.js   # cadastro/login (Sprint 3)
├── routes/
│   ├── solicitacoes.js
│   ├── prestadores.js
│   └── usuarios.js
├── mq/                         # Middleware Orientado a Mensagens (Sprint 2)
│   ├── publisher.js
│   └── consumer.js
└── middlewares/
    └── validacao.js
```
