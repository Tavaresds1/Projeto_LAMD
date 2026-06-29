import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/theme/app_theme.dart';
import '../core/utils/status_helper.dart';
import '../providers/auth_provider.dart';
import '../providers/solicitacoes_provider.dart';
import '../widgets/empty_state.dart';
import '../widgets/solicitacao_card.dart';
import 'detalhe_screen.dart';
import 'login_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with WidgetsBindingObserver {
  int _tabIndex = 0;
  int _prevNovasPendentes = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final auth = context.read<AuthProvider>();
      final prov = context.read<SolicitacoesProvider>();
      if (auth.prestador != null) {
        prov.configurarPrestador(auth.prestador!.id);
        prov.carregar();
        prov.iniciarPolling();
      }
      prov.addListener(_onNovasPendentes);
    });
  }

  void _onNovasPendentes() {
    if (!mounted) return;
    final prov = context.read<SolicitacoesProvider>();
    if (prov.novasPendentes > _prevNovasPendentes) {
      final novas = prov.novasPendentes - _prevNovasPendentes;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            novas == 1
                ? 'Nova chamada disponível!'
                : '$novas novas chamadas disponíveis!',
          ),
          backgroundColor: AppTheme.primariaEscura,
          behavior: SnackBarBehavior.floating,
          action: SnackBarAction(
            label: 'Ver',
            textColor: Colors.white,
            onPressed: () => setState(() => _tabIndex = 0),
          ),
        ),
      );
    }
    _prevNovasPendentes = prov.novasPendentes;
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
    final prov = context.read<SolicitacoesProvider>();
    prov.removeListener(_onNovasPendentes);
    prov.pararPolling();
    super.dispose();
  }

  Future<void> _sair() async {
    context.read<SolicitacoesProvider>().pararPolling();
    await context.read<AuthProvider>().logout();
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (route) => false,
    );
  }

  void _abrirDetalhe(int id) async {
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => DetalheScreen(id: id)),
    );
    if (mounted) context.read<SolicitacoesProvider>().carregar();
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final prov = context.watch<SolicitacoesProvider>();

    return Scaffold(
      backgroundColor: AppTheme.fundo,
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 30,
              height: 30,
              decoration: BoxDecoration(
                color: AppTheme.primaria,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.engineering, size: 18, color: Colors.white),
            ),
            const SizedBox(width: 10),
            const Text(
              'SOS Reparos',
              style: TextStyle(
                color: AppTheme.primaria,
                fontWeight: FontWeight.w800,
                fontSize: 18,
                letterSpacing: -0.3,
              ),
            ),
          ],
        ),
        actions: [
          if (prov.atualizando)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Center(
                child: SizedBox(
                  height: 16,
                  width: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: AppTheme.primaria.withOpacity(0.6),
                  ),
                ),
              ),
            ),
          _MenuPrestador(
            nome: auth.prestador?.nome ?? '',
            especialidade: auth.prestador?.especialidade ?? '',
            onSair: _sair,
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: prov.carregando
          ? const Center(
              child: CircularProgressIndicator(color: AppTheme.primaria),
            )
          : _tabIndex == 0
              ? _TabPendentes(prov: prov, onTap: _abrirDetalhe)
              : _TabMeusServicos(prov: prov, onTap: _abrirDetalhe),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _tabIndex,
        onTap: (i) {
          if (i == 0) context.read<SolicitacoesProvider>().limparNovasPendentes();
          setState(() => _tabIndex = i);
        },
        items: [
          BottomNavigationBarItem(
            icon: _BadgeIcon(
              icone: Icons.notifications_outlined,
              count: prov.novasPendentes,
            ),
            activeIcon: _BadgeIcon(
              icone: Icons.notifications,
              count: prov.novasPendentes,
            ),
            label: prov.pendentes.isEmpty
                ? 'Novas Chamadas'
                : 'Chamadas (${prov.pendentes.length})',
          ),
          BottomNavigationBarItem(
            icon: Stack(
              clipBehavior: Clip.none,
              children: [
                const Icon(Icons.work_outline),
                if (prov.minhasSolicitacoes
                    .where((s) =>
                        s.status == 'ACEITO' || s.status == 'EM_ANDAMENTO')
                    .isNotEmpty)
                  Positioned(
                    right: -4,
                    top: -4,
                    child: Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        color: Color(0xFF6A1B9A),
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
              ],
            ),
            activeIcon: const Icon(Icons.work),
            label: 'Meus Serviços',
          ),
        ],
      ),
    );
  }
}

class _TabPendentes extends StatelessWidget {
  final SolicitacoesProvider prov;
  final ValueChanged<int> onTap;

  const _TabPendentes({required this.prov, required this.onTap});

  @override
  Widget build(BuildContext context) {
    if (prov.erro != null && prov.pendentes.isEmpty) {
      return EmptyState(
        icone: Icons.cloud_off_outlined,
        titulo: 'Sem conexão',
        mensagem: prov.erro,
        rotuloAcao: 'Tentar novamente',
        aoTocarAcao: prov.carregar,
      );
    }

    if (prov.pendentes.isEmpty) {
      return const EmptyState(
        icone: Icons.check_circle_outline,
        titulo: 'Sem chamadas pendentes',
        mensagem:
            'Nenhuma solicitação aguardando atendimento no momento.\nO app verifica automaticamente.',
      );
    }

    return RefreshIndicator(
      color: AppTheme.primaria,
      onRefresh: prov.atualizarSilencioso,
      child: ListView.builder(
        padding: const EdgeInsets.only(top: 8, bottom: 16),
        itemCount: prov.pendentes.length,
        itemBuilder: (_, i) {
          final s = prov.pendentes[i];
          return SolicitacaoCard(
            solicitacao: s,
            onTap: () => onTap(s.id),
          );
        },
      ),
    );
  }
}

class _TabMeusServicos extends StatelessWidget {
  final SolicitacoesProvider prov;
  final ValueChanged<int> onTap;

  const _TabMeusServicos({required this.prov, required this.onTap});

  static const _filtros = <String, String?>{
    'Todos': null,
    'Aceito': 'ACEITO',
    'Em andamento': 'EM_ANDAMENTO',
    'Concluído': 'CONCLUIDO',
    'Recusado': 'RECUSADO',
  };

  @override
  Widget build(BuildContext context) {
    if (prov.minhasSolicitacoes.isEmpty) {
      return const EmptyState(
        icone: Icons.inbox_outlined,
        titulo: 'Nenhum serviço atribuído',
        mensagem: 'Aceite chamadas na aba "Novas Chamadas" para vê-las aqui.',
      );
    }

    return RefreshIndicator(
      color: AppTheme.primaria,
      onRefresh: prov.atualizarSilencioso,
      child: ListView.builder(
        padding: const EdgeInsets.only(top: 8, bottom: 16),
        itemCount: prov.minhasSolicitacoes.length,
        itemBuilder: (_, i) {
          final s = prov.minhasSolicitacoes[i];
          return SolicitacaoCard(
            solicitacao: s,
            onTap: () => onTap(s.id),
            mostrarCliente: true,
          );
        },
      ),
    );
  }
}

class _BadgeIcon extends StatelessWidget {
  final IconData icone;
  final int count;

  const _BadgeIcon({required this.icone, required this.count});

  @override
  Widget build(BuildContext context) {
    if (count == 0) return Icon(icone);
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Icon(icone),
        Positioned(
          right: -6,
          top: -4,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
            decoration: BoxDecoration(
              color: Colors.red,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              count > 9 ? '9+' : '$count',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 9,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _MenuPrestador extends StatelessWidget {
  final String nome;
  final String especialidade;
  final VoidCallback onSair;

  const _MenuPrestador({
    required this.nome,
    required this.especialidade,
    required this.onSair,
  });

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<String>(
      onSelected: (v) {
        if (v == 'sair') onSair();
      },
      offset: const Offset(0, 48),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        child: CircleAvatar(
          radius: 18,
          backgroundColor: AppTheme.primariaClara,
          child: Text(
            nome.isNotEmpty ? nome[0].toUpperCase() : '?',
            style: const TextStyle(
              color: AppTheme.primaria,
              fontWeight: FontWeight.w800,
              fontSize: 15,
            ),
          ),
        ),
      ),
      itemBuilder: (_) => [
        PopupMenuItem(
          enabled: false,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                nome,
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF212121),
                ),
              ),
              Text(
                especialidade,
                style: const TextStyle(
                  fontSize: 12,
                  color: AppTheme.textoSecundario,
                ),
              ),
            ],
          ),
        ),
        const PopupMenuDivider(),
        PopupMenuItem(
          value: 'sair',
          child: Row(
            children: const [
              Icon(Icons.logout, size: 18, color: AppTheme.primaria),
              SizedBox(width: 12),
              Text('Sair', style: TextStyle(color: AppTheme.primaria)),
            ],
          ),
        ),
      ],
    );
  }
}
