import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/solicitacao.dart';
import 'status_badge.dart';

/// Card que resume uma solicitação na listagem (Home).
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

    return Card(
      elevation: 2,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      solicitacao.tipoServico,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  StatusBadge(status: solicitacao.status, compacto: true),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                solicitacao.descricao,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: Colors.black87),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  const Icon(Icons.place_outlined,
                      size: 16, color: Colors.black45),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      solicitacao.endereco,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          fontSize: 13, color: Colors.black54),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Row(
                children: [
                  const Icon(Icons.schedule, size: 16, color: Colors.black45),
                  const SizedBox(width: 4),
                  Text(
                    dataFmt,
                    style:
                        const TextStyle(fontSize: 13, color: Colors.black54),
                  ),
                  const Spacer(),
                  if (solicitacao.temPrestador)
                    Row(
                      children: [
                        const Icon(Icons.engineering,
                            size: 16, color: Colors.black45),
                        const SizedBox(width: 4),
                        Text(
                          solicitacao.prestadorNome!,
                          style: const TextStyle(
                              fontSize: 13, color: Colors.black54),
                        ),
                      ],
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
