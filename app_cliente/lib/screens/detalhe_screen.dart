import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../core/config/api_config.dart';
import '../core/theme/app_theme.dart';
import '../core/utils/status_helper.dart';
import '../models/solicitacao.dart';
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.fundo,
      appBar: AppBar(
        title: Text('Solicitação #${widget.id}'),
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
                  fontSize: 15,
                  color: AppTheme.textoSecundario,
                ),
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
          _LinhaTempo(statusAtual: s.status),
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
                style: const TextStyle(
                    fontSize: 15, color: Color(0xFF424242)),
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
          const SizedBox(height: 10),
          _CartaoPrestador(solicitacao: s),
          if (s.temValores) ...[
            const SizedBox(height: 10),
            _CartaoValores(solicitacao: s),
          ],
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
            fontSize: 13,
            color: AppTheme.textoSecundario,
          ),
        ),
        Text(
          valor,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: Color(0xFF424242),
          ),
        ),
      ],
    );
  }
}

class _CartaoPrestador extends StatelessWidget {
  final Solicitacao solicitacao;
  const _CartaoPrestador({required this.solicitacao});

  @override
  Widget build(BuildContext context) {
    return _CartaoInfo(
      icone: Icons.engineering_outlined,
      titulo: 'Prestador',
      children: [
        if (solicitacao.temPrestador) ...[
          _ItemPrestador(
            icone: Icons.person_outline,
            texto: solicitacao.prestadorNome!,
            destaque: true,
          ),
          if (solicitacao.prestadorEspecialidade != null) ...[
            const SizedBox(height: 8),
            _ItemPrestador(
              icone: Icons.build_outlined,
              texto: solicitacao.prestadorEspecialidade!,
            ),
          ],
          if (solicitacao.prestadorTelefone != null) ...[
            const SizedBox(height: 8),
            _ItemPrestador(
              icone: Icons.phone_outlined,
              texto: solicitacao.prestadorTelefone!,
            ),
          ],
        ] else
          Row(
            children: [
              const Icon(
                Icons.hourglass_empty,
                size: 16,
                color: AppTheme.textoSecundario,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Aguardando um prestador aceitar...',
                  style: const TextStyle(
                    fontSize: 14,
                    color: AppTheme.textoSecundario,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),
            ],
          ),
      ],
    );
  }
}

class _ItemPrestador extends StatelessWidget {
  final IconData icone;
  final String texto;
  final bool destaque;

  const _ItemPrestador({
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

class _LinhaTempo extends StatelessWidget {
  final String statusAtual;
  const _LinhaTempo({required this.statusAtual});

  static const _fluxo = ['PENDENTE', 'ACEITO', 'EM_ANDAMENTO', 'CONCLUIDO'];

  @override
  Widget build(BuildContext context) {
    if (statusAtual.toUpperCase() == 'RECUSADO') {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFFFFEBEE),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: const Color(0xFFEF9A9A),
          ),
        ),
        child: const Row(
          children: [
            Icon(Icons.cancel_outlined,
                color: Color(0xFFC62828), size: 22),
            SizedBox(width: 12),
            Expanded(
              child: Text(
                'Solicitação recusada pelo prestador.',
                style: TextStyle(
                  color: Color(0xFFB71C1C),
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
            ),
          ],
        ),
      );
    }

    final idxAtual = _fluxo.indexOf(statusAtual.toUpperCase());

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
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
      child: Row(
        children: List.generate(_fluxo.length * 2 - 1, (i) {
          if (i.isOdd) {
            final feito = (i ~/ 2) < idxAtual;
            return Expanded(
              child: Container(
                height: 3,
                decoration: BoxDecoration(
                  color: feito
                      ? AppTheme.primaria
                      : const Color(0xFFEEEEEE),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            );
          }
          final idx = i ~/ 2;
          final alcancado = idx <= idxAtual;
          final ativo = idx == idxAtual;
          return _PassoLinhaTempo(
            status: _fluxo[idx],
            alcancado: alcancado,
            ativo: ativo,
          );
        }),
      ),
    );
  }
}

class _PassoLinhaTempo extends StatelessWidget {
  final String status;
  final bool alcancado;
  final bool ativo;

  const _PassoLinhaTempo({
    required this.status,
    required this.alcancado,
    required this.ativo,
  });

  @override
  Widget build(BuildContext context) {
    final cor = alcancado
        ? (ativo ? AppTheme.primaria : AppTheme.primaria.withOpacity(0.6))
        : const Color(0xFFBDBDBD);

    return Column(
      children: [
        AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          width: ativo ? 36 : 30,
          height: ativo ? 36 : 30,
          decoration: BoxDecoration(
            color: alcancado
                ? AppTheme.primaria.withOpacity(0.1)
                : const Color(0xFFF5F5F5),
            shape: BoxShape.circle,
            border: Border.all(
              color: cor,
              width: ativo ? 2.5 : 1.5,
            ),
          ),
          child: Icon(
            StatusHelper.icone(status),
            size: ativo ? 18 : 15,
            color: cor,
          ),
        ),
        const SizedBox(height: 6),
        SizedBox(
          width: 58,
          child: Text(
            StatusHelper.rotulo(status),
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 10,
              color: cor,
              fontWeight:
                  ativo ? FontWeight.w800 : FontWeight.w500,
              letterSpacing: 0.1,
            ),
          ),
        ),
      ],
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
                'R\$ ${solicitacao.valorTotal.toStringAsFixed(2).replaceAll('.', ',')}',
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
    final cor = AppTheme.textoSecundario;
    return Row(
      children: [
        Icon(icone, size: 15, color: cor),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            rotulo,
            style: TextStyle(fontSize: 14, color: cor),
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
