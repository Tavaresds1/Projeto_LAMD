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
import 'nova_solicitacao_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with WidgetsBindingObserver {
  // null = Ativas | 'HISTORICO' = Histórico | string = status exato
  static const _filtros = <String, String?>{
    'Ativas': null,
    'Pendente': 'PENDENTE',
    'Aceito': 'ACEITO',
    'Em andamento': 'EM_ANDAMENTO',
    'Histórico': 'HISTORICO',
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
    context.read<SolicitacoesProvider>().pararPolling();
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
              child: const Icon(Icons.plumbing, size: 18, color: Colors.white),
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
          _MenuUsuario(nome: auth.usuario?.nome ?? '', onSair: _sair),
          const SizedBox(width: 4),
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
        label: const Text(
          'Nova solicitação',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _BannerResumo(prov: prov),
          _BarraFiltros(
            filtros: _filtros,
            selecionado: prov.filtroLocal,
            onSelecionar: prov.definirFiltro,
          ),
          Expanded(child: _corpo(prov)),
        ],
      ),
    );
  }

  Widget _corpo(SolicitacoesProvider prov) {
    if (prov.carregando) {
      return const Center(
        child: CircularProgressIndicator(color: AppTheme.primaria),
      );
    }

    if (prov.erro != null && prov.itens.isEmpty) {
      return EmptyState(
        icone: Icons.cloud_off_outlined,
        titulo: 'Sem conexão',
        mensagem: prov.erro,
        rotuloAcao: 'Tentar novamente',
        aoTocarAcao: prov.carregar,
      );
    }

    if (prov.vazio) {
      return _emptyStatePorFiltro(prov);
    }

    return RefreshIndicator(
      color: AppTheme.primaria,
      onRefresh: prov.atualizarSilencioso,
      child: ListView.builder(
        padding: const EdgeInsets.only(top: 8, bottom: 100),
        itemCount: prov.itensFiltrados.length,
        itemBuilder: (_, i) {
          final s = prov.itensFiltrados[i];
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

  Widget _emptyStatePorFiltro(SolicitacoesProvider prov) {
    if (prov.filtroLocal == 'HISTORICO') {
      return const EmptyState(
        icone: Icons.history,
        titulo: 'Sem histórico',
        mensagem: 'Seus serviços concluídos e recusados aparecerão aqui.',
      );
    }
    if (prov.filtroLocal == null && prov.totalHistorico > 0) {
      return EmptyState(
        icone: Icons.check_circle_outline,
        titulo: 'Nenhuma solicitação ativa',
        mensagem:
            'Você tem ${prov.totalHistorico} serviço${prov.totalHistorico > 1 ? 's' : ''} '
            'no Histórico.\nToque em "Nova solicitação" para pedir um novo serviço.',
      );
    }
    if (prov.filtroLocal == null) {
      return const EmptyState(
        icone: Icons.inbox_outlined,
        titulo: 'Nenhuma solicitação',
        mensagem: 'Toque em "Nova solicitação" para pedir um serviço.',
      );
    }
    return EmptyState(
      icone: Icons.inbox_outlined,
      titulo: 'Nenhuma solicitação',
      mensagem: 'Nenhuma solicitação com status '
          '"${StatusHelper.rotulo(prov.filtroLocal!)}".',
    );
  }
}

class _BannerResumo extends StatelessWidget {
  final SolicitacoesProvider prov;
  const _BannerResumo({required this.prov});

  @override
  Widget build(BuildContext context) {
    if (prov.carregando || prov.itens.isEmpty) return const SizedBox.shrink();

    final pendentes =
        prov.itens.where((s) => s.status == 'PENDENTE').length;
    final emAndamento =
        prov.itens.where((s) => s.status == 'EM_ANDAMENTO').length;
    final aceitos =
        prov.itens.where((s) => s.status == 'ACEITO').length;

    if (pendentes == 0 && emAndamento == 0 && aceitos == 0) {
      return const SizedBox.shrink();
    }

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppTheme.superficie,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFEEEEEE)),
      ),
      child: Row(
        children: [
          if (pendentes > 0)
            _ContadorItem(
              count: pendentes,
              rotulo: 'Aguardando',
              cor: const Color(0xFFF9A825),
            ),
          if (pendentes > 0 && (aceitos > 0 || emAndamento > 0))
            const _Divisor(),
          if (aceitos > 0)
            _ContadorItem(
              count: aceitos,
              rotulo: 'Aceito',
              cor: const Color(0xFF1E88E5),
            ),
          if (aceitos > 0 && emAndamento > 0) const _Divisor(),
          if (emAndamento > 0)
            _ContadorItem(
              count: emAndamento,
              rotulo: 'Em andamento',
              cor: const Color(0xFF6A1B9A),
            ),
        ],
      ),
    );
  }
}

class _ContadorItem extends StatelessWidget {
  final int count;
  final String rotulo;
  final Color cor;

  const _ContadorItem({
    required this.count,
    required this.rotulo,
    required this.cor,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Text(
            '$count',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: cor,
              height: 1.1,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            rotulo,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 11,
              color: AppTheme.textoSecundario,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

class _Divisor extends StatelessWidget {
  const _Divisor();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 32,
      width: 1,
      color: const Color(0xFFEEEEEE),
      margin: const EdgeInsets.symmetric(horizontal: 4),
    );
  }
}

class _MenuUsuario extends StatelessWidget {
  final String nome;
  final VoidCallback onSair;

  const _MenuUsuario({required this.nome, required this.onSair});

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
              const Text(
                'Cliente',
                style: TextStyle(fontSize: 12, color: AppTheme.textoSecundario),
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
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        children: filtros.entries.map((e) {
          final ativo = selecionado == e.value;
          final isHistorico = e.value == 'HISTORICO';
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ChoiceChip(
              label: Text(e.key),
              selected: ativo,
              onSelected: (_) => onSelecionar(e.value),
              selectedColor: isHistorico && ativo
                  ? const Color(0xFF424242)
                  : AppTheme.primaria,
              backgroundColor: AppTheme.superficie,
              side: BorderSide(
                color: ativo
                    ? (isHistorico
                        ? const Color(0xFF424242)
                        : AppTheme.primaria)
                    : const Color(0xFFE0E0E0),
              ),
              labelStyle: TextStyle(
                color: ativo ? Colors.white : const Color(0xFF424242),
                fontWeight: ativo ? FontWeight.w700 : FontWeight.w500,
                fontSize: 13,
              ),
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              showCheckmark: false,
            ),
          );
        }).toList(),
      ),
    );
  }
}
