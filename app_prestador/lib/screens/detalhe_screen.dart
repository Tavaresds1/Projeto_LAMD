import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../core/config/api_config.dart';
import '../core/theme/app_theme.dart';
import '../core/utils/status_helper.dart';
import '../models/solicitacao.dart';
import '../providers/auth_provider.dart';
import '../providers/solicitacoes_provider.dart';
import '../repositories/solicitacao_repository.dart';
import '../services/api_client.dart';
import '../widgets/status_badge.dart';

class DetalheScreen extends StatefulWidget {
  final int id;
  const DetalheScreen({super.key, required this.id});

  @override
  State<DetalheScreen> createState() => _DetalheScreenState();
}

class _DetalheScreenState extends State<DetalheScreen> {
  late final SolicitacaoRepository _repo;
  Solicitacao? _solicitacao;
  String? _erro;
  bool _carregando = true;
  bool _executandoAcao = false;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _repo = context.read<SolicitacaoRepository>();
    _carregar(inicial: true);
    _timer = Timer.periodic(
      ApiConfig.intervaloPolling,
      (_) => _carregar(inicial: false),
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _carregar({required bool inicial}) async {
    try {
      final s = await _repo.detalhar(widget.id);
      if (!mounted) return;
      setState(() {
        _solicitacao = s;
        _erro = null;
        _carregando = false;
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _carregando = false;
        if (inicial) _erro = e.mensagem;
      });
    } catch (_) {
      if (!mounted) return;
      if (inicial) setState(() => _carregando = false);
    }
  }

  Future<(double, double)?> _mostrarDialogConclusao(BuildContext ctx) {
    return showDialog<(double, double)>(
      context: ctx,
      barrierDismissible: false,
      builder: (_) => const _DialogValoresConclusao(),
    );
  }

  Future<void> _executar(Future<void> Function() acao) async {
    if (_executandoAcao) return;
    setState(() => _executandoAcao = true);
    try {
      await acao();
      if (!mounted) return;
      await _carregar(inicial: false);
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.mensagem),
          backgroundColor: Colors.red.shade700,
        ),
      );
    } finally {
      if (mounted) setState(() => _executandoAcao = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.fundo,
      appBar: AppBar(
        title: Text('Chamada #${widget.id}'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 20),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: _build(),
    );
  }

  Widget _build() {
    if (_carregando) {
      return const Center(
        child: CircularProgressIndicator(color: AppTheme.primaria),
      );
    }
    if (_erro != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  color: AppTheme.primariaClara,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Icon(Icons.error_outline,
                    color: AppTheme.primaria, size: 36),
              ),
              const SizedBox(height: 16),
              Text(
                _erro!,
                textAlign: TextAlign.center,
                style: const TextStyle(
                    fontSize: 15, color: AppTheme.textoSecundario),
              ),
            ],
          ),
        ),
      );
    }

    final s = _solicitacao!;
    final criado = s.criadoEm != null
        ? DateFormat('dd/MM/yyyy • HH:mm').format(s.criadoEm!)
        : '—';
    final atualizado = s.atualizadoEm != null
        ? DateFormat('dd/MM/yyyy • HH:mm').format(s.atualizadoEm!)
        : '—';

    return RefreshIndicator(
      color: AppTheme.primaria,
      onRefresh: () => _carregar(inicial: false),
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _CartaoStatus(solicitacao: s),
          const SizedBox(height: 12),
          _CartaoCliente(solicitacao: s),
          const SizedBox(height: 12),
          _CartaoInfo(
            icone: Icons.description_outlined,
            titulo: 'Descrição',
            children: [
              Text(
                s.descricao,
                style: const TextStyle(
                    fontSize: 15, height: 1.5, color: Color(0xFF424242)),
              ),
            ],
          ),
          const SizedBox(height: 10),
          _CartaoInfo(
            icone: Icons.place_outlined,
            titulo: 'Endereço',
            children: [
              Text(
                s.endereco,
                style: const TextStyle(fontSize: 15, color: Color(0xFF424242)),
              ),
            ],
          ),
          const SizedBox(height: 10),
          _CartaoInfo(
            icone: Icons.schedule_outlined,
            titulo: 'Datas',
            children: [
              _DataItem(rotulo: 'Criada em', valor: criado),
              const SizedBox(height: 6),
              _DataItem(rotulo: 'Atualizada em', valor: atualizado),
            ],
          ),
          if (s.temValores) ...[
            const SizedBox(height: 10),
            _CartaoValores(solicitacao: s),
          ],
          const SizedBox(height: 16),
          _BotoesAcao(
            solicitacao: s,
            executando: _executandoAcao,
            onAceitar: () => _executar(
              () => context.read<SolicitacoesProvider>().aceitar(s.id),
            ),
            onRecusar: () => _executar(
              () => context.read<SolicitacoesProvider>().recusar(s.id),
            ),
            onIniciar: () => _executar(
              () => context.read<SolicitacoesProvider>().iniciarServico(s.id),
            ),
            onConcluir: () async {
              final valores = await _mostrarDialogConclusao(context);
              if (valores != null && mounted) {
                _executar(() => context.read<SolicitacoesProvider>().concluir(
                      s.id,
                      maoDeObra: valores.$1,
                      pecas: valores.$2,
                    ));
              }
            },
          ),
          const SizedBox(height: 16),
          Center(
            child: Text(
              'Atualizando a cada ${ApiConfig.intervaloPolling.inSeconds}s',
              style: const TextStyle(
                  fontSize: 11, color: AppTheme.textoSecundario),
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}

class _CartaoStatus extends StatelessWidget {
  final Solicitacao solicitacao;
  const _CartaoStatus({required this.solicitacao});

  @override
  Widget build(BuildContext context) {
    final cor = StatusHelper.cor(solicitacao.status);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.superficie,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFEEEEEE)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: cor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(
              StatusHelper.icone(solicitacao.status),
              color: cor,
              size: 26,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  solicitacao.tipoServico,
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF212121),
                    letterSpacing: -0.3,
                  ),
                ),
                const SizedBox(height: 4),
                StatusBadge(status: solicitacao.status),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CartaoCliente extends StatelessWidget {
  final Solicitacao solicitacao;
  const _CartaoCliente({required this.solicitacao});

  @override
  Widget build(BuildContext context) {
    return _CartaoInfo(
      icone: Icons.person_outline,
      titulo: 'Cliente',
      children: [
        if (solicitacao.usuarioNome != null)
          _InfoRow(
            icone: Icons.person,
            texto: solicitacao.usuarioNome!,
            destaque: true,
          ),
        if (solicitacao.usuarioTelefone != null) ...[
          const SizedBox(height: 8),
          _InfoRow(
            icone: Icons.phone_outlined,
            texto: solicitacao.usuarioTelefone!,
          ),
        ],
      ],
    );
  }
}

class _CartaoInfo extends StatelessWidget {
  final IconData icone;
  final String titulo;
  final List<Widget> children;

  const _CartaoInfo({
    required this.icone,
    required this.titulo,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.superficie,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFEEEEEE)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icone, size: 16, color: AppTheme.primaria),
              const SizedBox(width: 8),
              Text(
                titulo.toUpperCase(),
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  color: AppTheme.primaria,
                  letterSpacing: 0.8,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          const Divider(height: 1),
          const SizedBox(height: 10),
          ...children,
        ],
      ),
    );
  }
}

class _DataItem extends StatelessWidget {
  final String rotulo;
  final String valor;

  const _DataItem({required this.rotulo, required this.valor});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          '$rotulo: ',
          style: const TextStyle(
              fontSize: 13, color: AppTheme.textoSecundario),
        ),
        Text(
          valor,
          style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Color(0xFF424242)),
        ),
      ],
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icone;
  final String texto;
  final bool destaque;

  const _InfoRow({
    required this.icone,
    required this.texto,
    this.destaque = false,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(
          icone,
          size: 16,
          color: destaque ? AppTheme.primaria : AppTheme.textoSecundario,
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            texto,
            style: TextStyle(
              fontSize: 14,
              fontWeight:
                  destaque ? FontWeight.w700 : FontWeight.normal,
              color: destaque
                  ? const Color(0xFF212121)
                  : const Color(0xFF424242),
            ),
          ),
        ),
      ],
    );
  }
}

class _BotoesAcao extends StatelessWidget {
  final Solicitacao solicitacao;
  final bool executando;
  final VoidCallback onAceitar;
  final VoidCallback onRecusar;
  final VoidCallback onIniciar;
  final Future<void> Function() onConcluir;

  const _BotoesAcao({
    required this.solicitacao,
    required this.executando,
    required this.onAceitar,
    required this.onRecusar,
    required this.onIniciar,
    required this.onConcluir,
  });

  @override
  Widget build(BuildContext context) {
    final status = solicitacao.status.toUpperCase();

    // Sem ação para solicitações já concluídas ou recusadas
    if (status == 'CONCLUIDO' || status == 'RECUSADO') {
      return _CartaoEstadoFinal(status: status);
    }

    if (status == 'PENDENTE') {
      return Column(
        children: [
          _BotaoAcao(
            rotulo: 'Aceitar chamada',
            icone: Icons.check_circle_outline,
            cor: const Color(0xFF1E88E5),
            executando: executando,
            onPressed: onAceitar,
          ),
          const SizedBox(height: 10),
          _BotaoAcaoComConfirmacao(
            rotulo: 'Recusar chamada',
            icone: Icons.cancel_outlined,
            cor: const Color(0xFFC62828),
            executando: executando,
            onConfirmado: onRecusar,
            tituloDial: 'Recusar chamada?',
            mensagemDial:
                'Tem certeza que deseja recusar esta solicitação? Ela será marcada como recusada.',
            rotuloBotaoDial: 'Sim, recusar',
          ),
        ],
      );
    }

    if (status == 'ACEITO') {
      return _BotaoAcao(
        rotulo: 'Iniciar serviço',
        icone: Icons.build_circle_outlined,
        cor: const Color(0xFF6A1B9A),
        executando: executando,
        onPressed: onIniciar,
      );
    }

    if (status == 'EM_ANDAMENTO') {
      return _BotaoAcao(
        rotulo: 'Concluir serviço',
        icone: Icons.task_alt,
        cor: const Color(0xFF2E7D32),
        executando: executando,
        onPressed: onConcluir,
      );
    }

    return const SizedBox.shrink();
  }
}

class _BotaoAcao extends StatelessWidget {
  final String rotulo;
  final IconData icone;
  final Color cor;
  final bool executando;
  final VoidCallback onPressed;
  final bool outline;

  const _BotaoAcao({
    required this.rotulo,
    required this.icone,
    required this.cor,
    required this.executando,
    required this.onPressed,
    this.outline = false,
  });

  @override
  Widget build(BuildContext context) {
    final child = executando
        ? const SizedBox(
            height: 22,
            width: 22,
            child: CircularProgressIndicator(
                strokeWidth: 2.5, color: Colors.white),
          )
        : Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icone, size: 20),
              const SizedBox(width: 10),
              Text(rotulo),
            ],
          );

    if (outline) {
      return SizedBox(
        width: double.infinity,
        child: OutlinedButton(
          onPressed: executando ? null : onPressed,
          style: OutlinedButton.styleFrom(
            foregroundColor: cor,
            side: BorderSide(color: cor),
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            textStyle: const TextStyle(
                fontSize: 16, fontWeight: FontWeight.w700),
          ),
          child: child,
        ),
      );
    }

    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: executando ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: cor,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          textStyle:
              const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
        ),
        child: child,
      ),
    );
  }
}

class _BotaoAcaoComConfirmacao extends StatelessWidget {
  final String rotulo;
  final IconData icone;
  final Color cor;
  final bool executando;
  final VoidCallback onConfirmado;
  final String tituloDial;
  final String mensagemDial;
  final String rotuloBotaoDial;

  const _BotaoAcaoComConfirmacao({
    required this.rotulo,
    required this.icone,
    required this.cor,
    required this.executando,
    required this.onConfirmado,
    required this.tituloDial,
    required this.mensagemDial,
    required this.rotuloBotaoDial,
  });

  Future<void> _confirmar(BuildContext context) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          tituloDial,
          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 17),
        ),
        content: Text(
          mensagemDial,
          style: const TextStyle(
              fontSize: 14, color: AppTheme.textoSecundario, height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: cor,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(rotuloBotaoDial),
          ),
        ],
      ),
    );
    if (confirmar == true) onConfirmado();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton(
        onPressed: executando ? null : () => _confirmar(context),
        style: OutlinedButton.styleFrom(
          foregroundColor: cor,
          side: BorderSide(color: cor),
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          textStyle:
              const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
        ),
        child: executando
            ? SizedBox(
                height: 22,
                width: 22,
                child: CircularProgressIndicator(
                    strokeWidth: 2.5, color: cor),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(icone, size: 20),
                  const SizedBox(width: 10),
                  Text(rotulo),
                ],
              ),
      ),
    );
  }
}

class _CartaoValores extends StatelessWidget {
  final Solicitacao solicitacao;
  const _CartaoValores({required this.solicitacao});

  String _fmt(double? v) =>
      v != null ? 'R\$ ${v.toStringAsFixed(2).replaceAll('.', ',')}' : '—';

  @override
  Widget build(BuildContext context) {
    final total = solicitacao.valorTotal;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.superficie,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFEEEEEE)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: const [
              Icon(Icons.receipt_long_outlined,
                  size: 16, color: AppTheme.primaria),
              SizedBox(width: 8),
              Text(
                'VALORES DO SERVIÇO',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  color: AppTheme.primaria,
                  letterSpacing: 0.8,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          const Divider(height: 1),
          const SizedBox(height: 10),
          _LinhaValor(
            icone: Icons.handyman_outlined,
            rotulo: 'Mão de obra',
            valor: _fmt(solicitacao.valorMaoDeObra),
          ),
          const SizedBox(height: 8),
          _LinhaValor(
            icone: Icons.build_outlined,
            rotulo: 'Peças',
            valor: _fmt(solicitacao.valorPecas),
          ),
          const SizedBox(height: 10),
          const Divider(height: 1),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Total',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF212121),
                ),
              ),
              Text(
                'R\$ ${total.toStringAsFixed(2).replaceAll('.', ',')}',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: AppTheme.primaria,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _LinhaValor extends StatelessWidget {
  final IconData icone;
  final String rotulo;
  final String valor;

  const _LinhaValor({
    required this.icone,
    required this.rotulo,
    required this.valor,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icone, size: 15, color: AppTheme.textoSecundario),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            rotulo,
            style: const TextStyle(
                fontSize: 14, color: AppTheme.textoSecundario),
          ),
        ),
        Text(
          valor,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Color(0xFF424242),
          ),
        ),
      ],
    );
  }
}

class _CartaoEstadoFinal extends StatelessWidget {
  final String status;
  const _CartaoEstadoFinal({required this.status});

  @override
  Widget build(BuildContext context) {
    final concluido = status == 'CONCLUIDO';
    final cor =
        concluido ? const Color(0xFF2E7D32) : const Color(0xFFC62828);
    final bgCor =
        concluido ? const Color(0xFFE8F5E9) : const Color(0xFFFFEBEE);
    final icone =
        concluido ? Icons.task_alt : Icons.cancel_outlined;
    final msg = concluido
        ? 'Serviço concluído com sucesso.'
        : 'Chamada recusada.';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: bgCor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: cor.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(icone, color: cor, size: 22),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              msg,
              style: TextStyle(
                color: cor,
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// Dialog extraído como StatefulWidget para que os TextEditingControllers
// sejam criados e descartados corretamente pelo ciclo de vida do widget,
// evitando o erro "used after being disposed".
class _DialogValoresConclusao extends StatefulWidget {
  const _DialogValoresConclusao();

  @override
  State<_DialogValoresConclusao> createState() =>
      _DialogValoresConclusaoState();
}

class _DialogValoresConclusaoState extends State<_DialogValoresConclusao> {
  final _maoCtrl = TextEditingController();
  final _pecasCtrl = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _maoCtrl.dispose();
    _pecasCtrl.dispose();
    super.dispose();
  }

  void _confirmar() {
    if (!_formKey.currentState!.validate()) return;
    final mao =
        double.tryParse(_maoCtrl.text.trim().replaceAll(',', '.')) ?? 0.0;
    final pec =
        double.tryParse(_pecasCtrl.text.trim().replaceAll(',', '.')) ?? 0.0;
    Navigator.of(context).pop((mao, pec));
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: const Row(
        children: [
          Icon(Icons.receipt_long_outlined,
              color: AppTheme.primaria, size: 22),
          SizedBox(width: 10),
          Text(
            'Registrar valores',
            style: TextStyle(fontWeight: FontWeight.w700, fontSize: 17),
          ),
        ],
      ),
      // SizedBox com largura fixa evita que o Column tente expandir
      // infinitamente em contextos sem constrangimento lateral (web/Chrome).
      content: SizedBox(
        width: 320,
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Informe os valores cobrados neste serviço:',
                style: TextStyle(
                  fontSize: 13,
                  color: AppTheme.textoSecundario,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _maoCtrl,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(
                  labelText: 'Mão de obra (R\$)',
                  prefixIcon: Icon(Icons.handyman_outlined),
                ),
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return null;
                  if (double.tryParse(v.trim().replaceAll(',', '.')) == null) {
                    return 'Valor inválido.';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _pecasCtrl,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(
                  labelText: 'Peças (R\$)',
                  prefixIcon: Icon(Icons.build_outlined),
                ),
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return null;
                  if (double.tryParse(v.trim().replaceAll(',', '.')) == null) {
                    return 'Valor inválido.';
                  }
                  return null;
                },
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancelar'),
        ),
        ElevatedButton(
          onPressed: _confirmar,
          child: const Text('Concluir serviço'),
        ),
      ],
    );
  }
}
