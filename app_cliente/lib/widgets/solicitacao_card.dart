import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../core/theme/app_theme.dart';
import '../core/utils/status_helper.dart';
import '../models/solicitacao.dart';
import 'status_badge.dart';

class SolicitacaoCard extends StatelessWidget {
  final Solicitacao solicitacao;
  final VoidCallback onTap;

  const SolicitacaoCard({
    super.key,
    required this.solicitacao,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final data = solicitacao.criadoEm;
    final dataFmt =
        data != null ? DateFormat('dd/MM/yyyy • HH:mm').format(data) : '—';
    final corStatus = StatusHelper.cor(solicitacao.status);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Material(
          color: AppTheme.superficie,
          child: InkWell(
            onTap: onTap,
            child: IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Container(width: 5, color: corStatus),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(14, 14, 10, 12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  solicitacao.tipoServico,
                                  style: const TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w700,
                                    color: Color(0xFF212121),
                                    letterSpacing: -0.2,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              StatusBadge(
                                  status: solicitacao.status, compacto: true),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Text(
                            solicitacao.descricao,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 13,
                              color: AppTheme.textoSecundario,
                              height: 1.4,
                            ),
                          ),
                          const SizedBox(height: 10),
                          Wrap(
                            spacing: 12,
                            runSpacing: 4,
                            children: [
                              _MetaItem(
                                icone: Icons.place_outlined,
                                texto: solicitacao.endereco,
                                maxWidth: 160,
                              ),
                              _MetaItem(
                                icone: Icons.schedule_outlined,
                                texto: dataFmt,
                              ),
                              if (solicitacao.temPrestador)
                                _MetaItem(
                                  icone: Icons.engineering_outlined,
                                  texto: solicitacao.prestadorNome!,
                                  cor: AppTheme.primaria,
                                ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  const Center(
                    child: Padding(
                      padding: EdgeInsets.only(right: 8),
                      child: Icon(
                        Icons.chevron_right,
                        color: Color(0xFFBDBDBD),
                        size: 20,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _MetaItem extends StatelessWidget {
  final IconData icone;
  final String texto;
  final Color? cor;
  final double? maxWidth;

  const _MetaItem({
    required this.icone,
    required this.texto,
    this.cor,
    this.maxWidth,
  });

  @override
  Widget build(BuildContext context) {
    final itemColor = cor ?? AppTheme.textoSecundario;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icone, size: 13, color: itemColor),
        const SizedBox(width: 4),
        ConstrainedBox(
          constraints: BoxConstraints(maxWidth: maxWidth ?? 200),
          child: Text(
            texto,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 12,
              color: itemColor,
              fontWeight:
                  cor != null ? FontWeight.w600 : FontWeight.normal,
            ),
          ),
        ),
      ],
    );
  }
}
