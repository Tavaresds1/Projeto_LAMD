import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/solicitacoes_provider.dart';
import '../services/api_client.dart';

/// Tela de ação principal: criação de uma nova solicitação de serviço.
class NovaSolicitacaoScreen extends StatefulWidget {
  const NovaSolicitacaoScreen({super.key});

  @override
  State<NovaSolicitacaoScreen> createState() => _NovaSolicitacaoScreenState();
}

class _NovaSolicitacaoScreenState extends State<NovaSolicitacaoScreen> {
  final _formKey = GlobalKey<FormState>();
  final _descricaoCtrl = TextEditingController();
  final _enderecoCtrl = TextEditingController();

  static const _tiposServico = [
    'Vazamento',
    'Desentupimento',
    'Instalação Hidráulica',
    'Reparo de Torneira',
    'Troca de Registro',
    'Manutenção de Caixa d\'água',
    'Outro',
  ];
  String _tipoSelecionado = _tiposServico.first;
  bool _enviando = false;

  @override
  void dispose() {
    _descricaoCtrl.dispose();
    _enderecoCtrl.dispose();
    super.dispose();
  }

  Future<void> _enviar() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _enviando = true);

    final prov = context.read<SolicitacoesProvider>();
    try {
      await prov.criar(
        tipoServico: _tipoSelecionado,
        descricao: _descricaoCtrl.text.trim(),
        endereco: _enderecoCtrl.text.trim(),
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Solicitação criada com sucesso!'),
          backgroundColor: Color(0xFF2E7D32),
        ),
      );
      Navigator.of(context).pop();
    } on ApiException catch (e) {
      _falha(e.mensagem);
    } catch (_) {
      _falha('Erro ao criar solicitação. Tente novamente.');
    } finally {
      if (mounted) setState(() => _enviando = false);
    }
  }

  void _falha(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: Colors.red.shade700),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Nova solicitação')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  'Descreva o serviço hidráulico que você precisa.',
                  style: TextStyle(color: Colors.black54),
                ),
                const SizedBox(height: 20),
                DropdownButtonFormField<String>(
                  value: _tipoSelecionado,
                  decoration: const InputDecoration(
                    labelText: 'Tipo de serviço',
                    prefixIcon: Icon(Icons.handyman_outlined),
                  ),
                  items: _tiposServico
                      .map((t) =>
                          DropdownMenuItem(value: t, child: Text(t)))
                      .toList(),
                  onChanged: (v) =>
                      setState(() => _tipoSelecionado = v ?? _tiposServico.first),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _descricaoCtrl,
                  maxLines: 4,
                  decoration: const InputDecoration(
                    labelText: 'Descrição',
                    alignLabelWithHint: true,
                    hintText: 'Ex.: Vazamento embaixo da pia da cozinha...',
                    prefixIcon: Padding(
                      padding: EdgeInsets.only(bottom: 60),
                      child: Icon(Icons.description_outlined),
                    ),
                  ),
                  validator: (v) {
                    if (v == null || v.trim().length < 10) {
                      return 'Descreva com pelo menos 10 caracteres.';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _enderecoCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Endereço',
                    hintText: 'Rua, número, bairro',
                    prefixIcon: Icon(Icons.place_outlined),
                  ),
                  validator: (v) => (v == null || v.trim().isEmpty)
                      ? 'Informe o endereço.'
                      : null,
                ),
                const SizedBox(height: 28),
                ElevatedButton.icon(
                  onPressed: _enviando ? null : _enviar,
                  icon: _enviando
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.send),
                  label: Text(_enviando ? 'Enviando...' : 'Solicitar serviço'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
