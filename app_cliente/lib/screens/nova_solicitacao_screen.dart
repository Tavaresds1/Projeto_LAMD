import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/theme/app_theme.dart';
import '../providers/solicitacoes_provider.dart';
import '../services/api_client.dart';

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
    "Manutenção de Caixa d'água",
    'Outro',
  ];

  static const _iconesTipo = <String, IconData>{
    'Vazamento': Icons.water_drop_outlined,
    'Desentupimento': Icons.plumbing,
    'Instalação Hidráulica': Icons.settings_outlined,
    'Reparo de Torneira': Icons.hardware_outlined,
    'Troca de Registro': Icons.rotate_right_outlined,
    "Manutenção de Caixa d'água": Icons.water_outlined,
    'Outro': Icons.handyman_outlined,
  };

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
        SnackBar(
          content: const Row(
            children: [
              Icon(Icons.check_circle_outline, color: Colors.white, size: 20),
              SizedBox(width: 10),
              Text('Solicitação criada com sucesso!'),
            ],
          ),
          backgroundColor: const Color(0xFF2E7D32),
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
      SnackBar(
        content: Text(msg),
        backgroundColor: AppTheme.primariaEscura,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.fundo,
      appBar: AppBar(
        title: const Text('Nova solicitação'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 20),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _InfoBanner(),
                const SizedBox(height: 24),
                _SecaoLabel(
                  icone: Icons.category_outlined,
                  titulo: 'Tipo de serviço',
                ),
                const SizedBox(height: 10),
                _SeletorTipo(
                  tipos: _tiposServico,
                  icones: _iconesTipo,
                  selecionado: _tipoSelecionado,
                  onSelecionar: (v) =>
                      setState(() => _tipoSelecionado = v),
                ),
                const SizedBox(height: 20),
                _SecaoLabel(
                  icone: Icons.description_outlined,
                  titulo: 'Descrição do problema',
                ),
                const SizedBox(height: 10),
                TextFormField(
                  controller: _descricaoCtrl,
                  maxLines: 4,
                  decoration: const InputDecoration(
                    hintText:
                        'Ex.: Vazamento embaixo da pia da cozinha, água escorrendo pelo armário...',
                    alignLabelWithHint: true,
                  ),
                  validator: (v) {
                    if (v == null || v.trim().length < 10) {
                      return 'Descreva com pelo menos 10 caracteres.';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 20),
                _SecaoLabel(
                  icone: Icons.place_outlined,
                  titulo: 'Endereço',
                ),
                const SizedBox(height: 10),
                TextFormField(
                  controller: _enderecoCtrl,
                  decoration: const InputDecoration(
                    hintText: 'Rua, número, bairro',
                    prefixIcon: Icon(Icons.place_outlined),
                  ),
                  validator: (v) => (v == null || v.trim().isEmpty)
                      ? 'Informe o endereço.'
                      : null,
                ),
                const SizedBox(height: 32),
                ElevatedButton.icon(
                  onPressed: _enviando ? null : _enviar,
                  icon: _enviando
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.send_outlined, size: 20),
                  label:
                      Text(_enviando ? 'Enviando...' : 'Solicitar serviço'),
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _InfoBanner extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.primariaClara,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: AppTheme.primaria.withOpacity(0.2),
        ),
      ),
      child: const Row(
        children: [
          Icon(Icons.info_outline, color: AppTheme.primaria, size: 20),
          SizedBox(width: 12),
          Expanded(
            child: Text(
              'Descreva o serviço hidráulico que você precisa com o máximo de detalhes.',
              style: TextStyle(
                color: AppTheme.primariaEscura,
                fontSize: 13,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SecaoLabel extends StatelessWidget {
  final IconData icone;
  final String titulo;

  const _SecaoLabel({required this.icone, required this.titulo});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icone, size: 18, color: AppTheme.primaria),
        const SizedBox(width: 8),
        Text(
          titulo,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: Color(0xFF212121),
            letterSpacing: 0.1,
          ),
        ),
      ],
    );
  }
}

class _SeletorTipo extends StatelessWidget {
  final List<String> tipos;
  final Map<String, IconData> icones;
  final String selecionado;
  final ValueChanged<String> onSelecionar;

  const _SeletorTipo({
    required this.tipos,
    required this.icones,
    required this.selecionado,
    required this.onSelecionar,
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: tipos.map((t) {
        final ativo = t == selecionado;
        return GestureDetector(
          onTap: () => onSelecionar(t),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: ativo ? AppTheme.primaria : AppTheme.superficie,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: ativo
                    ? AppTheme.primaria
                    : const Color(0xFFE0E0E0),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  icones[t] ?? Icons.handyman_outlined,
                  size: 16,
                  color: ativo ? Colors.white : AppTheme.textoSecundario,
                ),
                const SizedBox(width: 6),
                Text(
                  t,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: ativo ? Colors.white : const Color(0xFF424242),
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}
