import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/utils/status_helper.dart';
import '../providers/auth_provider.dart';
import '../providers/solicitacoes_provider.dart';
import '../widgets/empty_state.dart';
import '../widgets/solicitacao_card.dart';
import 'detalhe_screen.dart';
import 'login_screen.dart';
import 'nova_solicitacao_screen.dart';

/// Tela principal (Home): lista as solicitações do usuário logado.
///
/// Implementa a **atualização assíncrona de estado (Sprint 3)** iniciando o
/// polling do provider ao entrar e pausando-o quando o app vai para segundo
/// plano, refletindo automaticamente mudanças feitas pelo prestador.
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with WidgetsBindingObserver {
  static const _filtros = <String, String?>{
    'Todas': null,
    'Pendente': 'PENDENTE',
    'Aceito': 'ACEITO',
    'Em andamento': 'EM_ANDAMENTO',
    'Concluído': 'CONCLUIDO',
  };

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final auth = context.read<AuthProvider>();
      final prov = context.read<SolicitacoesProvider>();
      if (auth.usuario != null) {
        prov.configurarUsuario(auth.usuario!.id);
        prov.carregar();
        prov.iniciarPolling();
      }
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final prov = context.read<SolicitacoesProvider>();
    if (state == AppLifecycleState.resumed) {
      prov.iniciarPolling();
      prov.atualizarSilencioso();
    } else if (state == AppLifecycleState.paused) {
      prov.pararPolling();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    context.read<SolicitacoesProvider>().pararPolling();
    super.dispose();
  }

  Future<void> _sair() async {
    final prov = context.read<SolicitacoesProvider>();
    prov.pararPolling();
    await context.read<AuthProvider>().logout();
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final prov = context.watch<SolicitacoesProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Minhas Solicitações'),
        actions: [
          // Indicador discreto de atualização em segundo plano (polling).
          if (prov.atualizando)
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: Center(
                child: SizedBox(
                  height: 18,
                  width: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          PopupMenuButton<String>(
            onSelected: (v) {
              if (v == 'sair') _sair();
            },
            itemBuilder: (_) => [
              PopupMenuItem(
                enabled: false,
                child: Text(
                  auth.usuario?.nome ?? '',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
              const PopupMenuDivider(),
              const PopupMenuItem(
                value: 'sair',
                child: ListTile(
                  leading: Icon(Icons.logout),
                  title: Text('Sair'),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
            ],
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          await Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const NovaSolicitacaoScreen()),
          );
          if (mounted) context.read<SolicitacoesProvider>().carregar();
        },
        icon: const Icon(Icons.add),
        label: const Text('Nova solicitação'),
      ),
      body: Column(
        children: [
          _BarraFiltros(
            filtros: _filtros,
            selecionado: prov.filtroStatus,
            onSelecionar: prov.definirFiltro,
          ),
          Expanded(child: _corpo(prov)),
        ],
      ),
    );
  }

  Widget _corpo(SolicitacoesProvider prov) {
    if (prov.carregando) {
      return const Center(child: CircularProgressIndicator());
    }

    if (prov.erro != null && prov.itens.isEmpty) {
      return EmptyState(
        icone: Icons.cloud_off,
        titulo: 'Não foi possível carregar',
        mensagem: prov.erro,
        rotuloAcao: 'Tentar novamente',
        aoTocarAcao: prov.carregar,
      );
    }

    if (prov.vazio) {
      return EmptyState(
        icone: Icons.inbox_outlined,
        titulo: 'Nenhuma solicitação',
        mensagem: prov.filtroStatus == null
            ? 'Toque em "Nova solicitação" para pedir um serviço.'
            : 'Nenhuma solicitação com status "'
                '${StatusHelper.rotulo(prov.filtroStatus!)}".',
      );
    }

    return RefreshIndicator(
      onRefresh: prov.atualizarSilencioso,
      child: ListView.builder(
        padding: const EdgeInsets.only(top: 8, bottom: 88),
        itemCount: prov.itens.length,
        itemBuilder: (_, i) {
          final s = prov.itens[i];
          return SolicitacaoCard(
            solicitacao: s,
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => DetalheScreen(id: s.id)),
            ),
          );
        },
      ),
    );
  }
}

class _BarraFiltros extends StatelessWidget {
  final Map<String, String?> filtros;
  final String? selecionado;
  final ValueChanged<String?> onSelecionar;

  const _BarraFiltros({
    required this.filtros,
    required this.selecionado,
    required this.onSelecionar,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 56,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        children: filtros.entries.map((e) {
          final ativo = selecionado == e.value;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ChoiceChip(
              label: Text(e.key),
              selected: ativo,
              onSelected: (_) => onSelecionar(e.value),
            ),
          );
        }).toList(),
      ),
    );
  }
}
