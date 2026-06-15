# SOS dos Reparos – App Cliente (Sprint 3)

Aplicativo móvel **Flutter** do **cliente** da plataforma SOS dos Reparos.
Permite que o usuário se cadastre/faça login, solicite serviços hidráulicos,
acompanhe suas solicitações e veja **atualizações de estado em tempo real**
(quando o prestador aceita/conclui o serviço) sem precisar atualizar a tela.

**Stack:** Flutter · Dart · Provider · http · shared_preferences

---

## Funcionalidades (entregas da Sprint 3)

- **Autenticação completa** (login + cadastro) integrada ao backend REST.
- **Listagem** das solicitações do usuário, com filtros por status.
- **Detalhes** de uma solicitação, com linha do tempo do ciclo de vida.
- **Criação** de nova solicitação (ação principal).
- **Atualização assíncrona de estado** via *polling* periódico (a cada 5s),
  refletindo mudanças feitas pelo prestador automaticamente.

> Telas (≥3 exigidas): Login, Cadastro, **Lista**, **Detalhes**, **Nova solicitação**.

---

## Pré-requisitos

- Flutter SDK 3.10+ / Dart 3.x
- Backend (pasta `../backend`) em execução, com PostgreSQL e RabbitMQ no ar.

---

## Como executar

```bash
# 1. (uma única vez) gere os diretórios de plataforma (android/ios/web)
#    Este comando NÃO sobrescreve a pasta lib/.
flutter create .

# 2. Baixe as dependências
flutter pub get

# 3. Garanta que o backend está rodando (em ../backend):
#    docker-compose up -d  &&  npm run dev

# 4. Rode o app
flutter run
```

### Configuração do endereço da API

O app descobre a URL automaticamente:

| Ambiente            | URL usada                |
|---------------------|--------------------------|
| Emulador Android    | `http://10.0.2.2:3000`   |
| iOS / Web / Desktop | `http://localhost:3000`  |

Para um **dispositivo físico**, informe o IP da sua máquina:

```bash
flutter run --dart-define=API_URL=http://192.168.0.10:3000
```

### Login de teste (dados do seed)

| E-mail            | Senha   |
|-------------------|---------|
| joao@email.com    | 123456  |
| maria@email.com   | 123456  |

Ou crie uma conta nova pela tela de cadastro.

---

## Estrutura do projeto (Clean Architecture)

```
lib/
├── main.dart                  # Composição de dependências + MultiProvider
├── core/                      # Infra transversal
│   ├── config/api_config.dart # URL da API e intervalo de polling
│   ├── theme/app_theme.dart   # Tema visual
│   └── utils/status_helper.dart
├── models/                    # Entidades (Usuario, Solicitacao, Prestador)
├── services/                  # Acesso REST (ApiClient + serviços por domínio)
├── repositories/              # Orquestram services + persistência local
├── providers/                 # Estado da UI (ChangeNotifier) + polling
├── screens/                   # Telas
└── widgets/                   # Componentes reutilizáveis
```

O detalhamento das camadas está em [ARQUITETURA.md](ARQUITETURA.md).

---

## Atualização assíncrona de estado

A tela de lista (`HomeScreen`) e a de detalhes (`DetalheScreen`) iniciam um
`Timer.periodic` que refaz o `GET` no backend em segundo plano. Assim, quando o
**prestador** aceita ou conclui uma solicitação (alterando o status no servidor),
o app do **cliente** reflete a mudança sozinho, sem ação manual.

O polling é pausado quando o app vai para segundo plano e retomado ao voltar,
economizando rede e bateria.
