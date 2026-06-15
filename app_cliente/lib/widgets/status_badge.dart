import 'package:flutter/material.dart';

import '../core/utils/status_helper.dart';

/// Selo colorido que representa o status atual de uma solicitação.
class StatusBadge extends StatelessWidget {
  final String status;
  final bool compacto;

  const StatusBadge({super.key, required this.status, this.compacto = false});

  @override
  Widget build(BuildContext context) {
    final cor = StatusHelper.cor(status);
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compacto ? 8 : 12,
        vertical: compacto ? 4 : 6,
      ),
      decoration: BoxDecoration(
        color: cor.withOpacity(0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: cor.withOpacity(0.4)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(StatusHelper.icone(status), size: compacto ? 14 : 16, color: cor),
          const SizedBox(width: 6),
          Text(
            StatusHelper.rotulo(status),
            style: TextStyle(
              color: cor,
              fontWeight: FontWeight.w600,
              fontSize: compacto ? 12 : 13,
            ),
          ),
        ],
      ),
    );
  }
}
