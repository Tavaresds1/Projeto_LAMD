# SOS dos Reparos

Plataforma distribuída para solicitação de serviços hidráulicos, no modelo
cliente/prestador, orientada a eventos.

**Stack:** Node.js · Express · PostgreSQL · RabbitMQ (MOM) · Flutter · Docker

## Componentes do repositório

| Pasta              | Sprint | Descrição |
|--------------------|--------|-----------|
| [`backend/`](backend/)           | 1–2 | API REST + integração com o MOM (RabbitMQ) |
| [`app_cliente/`](app_cliente/)   | 3   | App Flutter do **cliente** |
| [`app_prestador/`](app_prestador/) | 4 | App Flutter do **prestador de serviços** |
| [`docs/`](docs/)                 | 1–2 | Proposta, diagrama de arquitetura e docs de eventos |
| [`postman/`](postman/)           | 1   | Coleção de testes da API |

> Documentação dos apps:
> [`app_cliente/README.md`](app_cliente/README.md) ·
> [`app_cliente/ARQUITETURA.md`](app_cliente/ARQUITETURA.md)

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
| POST   | /prestadores/login            | Autenticar prestador (Sprint 4)  |
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
prestadores  (id, nome, email, telefone, especialidade, disponivel, senha_hash, criado_em)
solicitacoes (id, usuario_id, prestador_id, tipo_servico, descricao,
              endereco, status, criado_em, atualizado_em)
```

**Credenciais de teste:**

| Perfil     | E-mail            | Senha  |
|------------|-------------------|--------|
| Cliente    | joao@email.com    | 123456 |
| Cliente    | maria@email.com   | 123456 |
| Prestador  | carlos@sos.com    | 123456 |
| Prestador  | ana@sos.com       | 123456 |

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

---

## App Prestador (Sprint 4)

App Flutter para o prestador de serviços, com arquitetura limpa espelhando o app do cliente.

### Como executar

```bash
cd app_prestador

# 1. Gera os arquivos de plataforma (Android, iOS etc.) — necessário na primeira vez
flutter create --project-name sos_reparos_prestador .

# 2. Instala as dependências
flutter pub get

# 3. Executa o app
flutter run
```

> Para Android: `flutter run --dart-define=API_URL=http://10.0.2.2:3000`  
> Para dispositivo físico: `flutter run --dart-define=API_URL=http://<IP_DA_MAQUINA>:3000`

### Funcionalidades

- Login do prestador (`carlos@sos.com` / `ana@sos.com` — senha `123456`)
- **Aba "Novas Chamadas"**: lista todas as solicitações PENDENTE em tempo real (polling a cada 5s), com badge de notificação para novas chegadas
- **Aba "Meus Serviços"**: lista as solicitações atribuídas a este prestador
- **Tela de detalhe**: exibe dados completos da chamada + botões de ação conforme o status:
  - `PENDENTE` → **Aceitar** / **Recusar**
  - `ACEITO` → **Iniciar serviço**
  - `EM_ANDAMENTO` → **Concluir**

### Fluxo completo de ponta a ponta

```
Cliente cria solicitação (app_cliente)
    ↓ POST /solicitacoes → backend publica em solicitacao.criada (RabbitMQ)
Prestador vê a chamada aparecer na aba "Novas Chamadas" (polling 5s)
    ↓ Prestador toca em "Aceitar"
    ↓ PATCH /solicitacoes/:id/status {status: ACEITO, prestador_id}
    ↓ backend publica em solicitacao.aceita + status.atualizado (RabbitMQ)
Cliente vê o status mudar para "Aceito" (polling 5s no app_cliente)
    ↓ Prestador inicia o serviço → EM_ANDAMENTO
    ↓ Prestador conclui → CONCLUIDO
Cliente vê "Concluído" no app
```

### Estrutura

```
app_prestador/lib/
├── core/
│   ├── config/api_config.dart    # URL da API + intervalo de polling
│   ├── theme/app_theme.dart      # Tema azul (diferencia do app cliente)
│   └── utils/status_helper.dart
├── models/          prestador.dart · solicitacao.dart
├── services/        api_client.dart · auth_service.dart · solicitacao_service.dart
├── repositories/    auth_repository.dart · solicitacao_repository.dart
├── providers/       auth_provider.dart · solicitacoes_provider.dart
├── screens/         splash · login · home (2 abas) · detalhe
└── widgets/         solicitacao_card · status_badge · empty_state
```
