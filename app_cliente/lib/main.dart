import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'core/theme/app_theme.dart';
import 'providers/auth_provider.dart';
import 'providers/solicitacoes_provider.dart';
import 'repositories/auth_repository.dart';
import 'repositories/solicitacao_repository.dart';
import 'screens/splash_screen.dart';
import 'services/api_client.dart';
import 'services/auth_service.dart';
import 'services/solicitacao_service.dart';

void main() {
  // ── Composição das dependências (Clean Architecture) ────────────────
  // services  → repositories → providers (UI)
  final apiClient = ApiClient();

  final authRepository = AuthRepository(AuthService(apiClient));
  final solicitacaoRepository =
      SolicitacaoRepository(SolicitacaoService(apiClient));

  runApp(SosReparosApp(
    authRepository: authRepository,
    solicitacaoRepository: solicitacaoRepository,
  ));
}

class SosReparosApp extends StatelessWidget {
  final AuthRepository authRepository;
  final SolicitacaoRepository solicitacaoRepository;

  const SosReparosApp({
    super.key,
    required this.authRepository,
    required this.solicitacaoRepository,
  });

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        // Repositório exposto para telas que carregam dados pontuais
        // (ex.: detalhe da solicitação).
        Provider<SolicitacaoRepository>.value(value: solicitacaoRepository),
        ChangeNotifierProvider(
          create: (_) => AuthProvider(authRepository),
        ),
        ChangeNotifierProvider(
          create: (_) => SolicitacoesProvider(solicitacaoRepository),
        ),
      ],
      child: MaterialApp(
        title: 'SOS dos Reparos',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light,
        home: const SplashScreen(),
      ),
    );
  }
}
