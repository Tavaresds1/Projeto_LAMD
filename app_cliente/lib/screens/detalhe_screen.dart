import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../core/config/api_config.dart';
import '../core/utils/status_helper.dart';
import '../models/solicitacao.dart';
import '../repositories/solicitacao_repository.dart';
import '../services/api_client.dart';
import '../widgets/status_badge.dart';

/// Tela de detalhes de uma solicitação.
///
/// Também faz polling enquanto está aberta: se o prestador alterar o status
/// (ex.: aceitar ou concluir), a tela reflete a mudança automaticamente.
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
      appBar: AppBar(title: Text('Solicitação #${widget.id}')),
      body: _build(),
    );
  }

  Widget _build() {
    if (_carregando) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_erro != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(_erro!, textAlign: TextAlign.center),
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
      onRefresh: () => _carregar(inicial: false),
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  s.tipoServico,
                  style: const TextStyle(
                      fontSize: 20, fontWeight: FontWeight.bold),
                ),
              ),
              StatusBadge(status: s.status),
            ],
          ),
          const SizedBox(height: 20),
          _LinhaTempo(statusAtual: s.status),
          const SizedBox(height: 8),
          _secao('Descrição', [_texto(s.descricao)]),
          _secao('Endereço', [
            _itemIcone(Icons.place_outlined, s.endereco),
          ]),
          _secao('Datas', [
            _itemIcone(Icons.schedule, 'Criada em: $criado'),
            _itemIcone(Icons.update, 'Atualizada em: $atualizado'),
          ]),
          _secao('Prestador', [
            if (s.temPrestador) ...[
              _itemIcone(Icons.engineering, s.prestadorNome!),
              if (s.prestadorEspecialidade != null)
                _itemIcone(Icons.build_outlined, s.prestadorEspecialidade!),
              if (s.prestadorTelefone != null)
                _itemIcone(Icons.phone_outlined, s.prestadorTelefone!),
            ] else
              _texto('Aguardando um prestador aceitar a solicitação...'),
          ]),
          const SizedBox(height: 8),
          Center(
            child: Text(
              'Atualizando automaticamente a cada '
              '${ApiConfig.intervaloPolling.inSeconds}s',
              style: const TextStyle(fontSize: 12, color: Colors.black38),
            ),
          ),
        ],
      ),
    );
  }

  Widget _secao(String titulo, List<Widget> filhos) {
    return Padding(
      padding: const EdgeInsets.only(top: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            titulo.toUpperCase(),
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: Colors.black45,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 8),
          Card(
            margin: EdgeInsets.zero,
            elevation: 2,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: filhos,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _texto(String t) =>
      Text(t, style: const TextStyle(fontSize: 15, height: 1.4));

  Widget _itemIcone(IconData icone, String texto) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icone, size: 18, color: Colors.black45),
          const SizedBox(width: 10),
          Expanded(child: Text(texto, style: const TextStyle(fontSize: 15))),
        ],
      ),
    );
  }
}

/// Linha do tempo visual do ciclo de vida do status.
class _LinhaTempo extends StatelessWidget {
  final String statusAtual;
  const _LinhaTempo({required this.statusAtual});

  static const _fluxo = ['PENDENTE', 'ACEITO', 'EM_ANDAMENTO', 'CONCLUIDO'];

  @override
  Widget build(BuildContext context) {
    if (statusAtual.toUpperCase() == 'RECUSADO') {
      return Card(
        margin: EdgeInsets.zero,
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        color: StatusHelper.cor('RECUSADO').withOpacity(0.08),
        child: const Padding(
          padding: EdgeInsets.all(14),
          child: Row(
            children: [
              Icon(Icons.cancel_outlined, color: Color(0xFFC62828)),
              SizedBox(width: 10),
              Text('Solicitação recusada pelo prestador.'),
            ],
          ),
        ),
      );
    }

    final idxAtual = _fluxo.indexOf(statusAtual.toUpperCase());

    return Row(
      children: List.generate(_fluxo.length * 2 - 1, (i) {
        if (i.isOdd) {
          final feito = (i ~/ 2) < idxAtual;
          return Expanded(
            child: Container(
              height: 3,
              color: feito ? StatusHelper.cor('CONCLUIDO') : Colors.black12,
            ),
          );
        }
        final idx = i ~/ 2;
        final alcancado = idx <= idxAtual;
        final cor = alcancado ? StatusHelper.cor(_fluxo[idx]) : Colors.black26;
        return Column(
          children: [
            CircleAvatar(
              radius: 16,
              backgroundColor: cor.withOpacity(0.15),
              child: Icon(StatusHelper.icone(_fluxo[idx]), size: 18, color: cor),
            ),
            const SizedBox(height: 4),
            SizedBox(
              width: 64,
              child: Text(
                StatusHelper.rotulo(_fluxo[idx]),
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 10,
                  color: cor,
                  fontWeight:
                      idx == idxAtual ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            ),
          ],
        );
      }),
    );
  }
}
