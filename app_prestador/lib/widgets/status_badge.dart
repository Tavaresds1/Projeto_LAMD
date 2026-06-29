import 'package:flutter/material.dart';

import '../core/utils/status_helper.dart';

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
        vertical: compacto ? 4 : 7,
      ),
      decoration: BoxDecoration(
        color: cor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(40),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: compacto ? 6 : 7,
            height: compacto ? 6 : 7,
            decoration: BoxDecoration(
              color: cor,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            StatusHelper.rotulo(status),
            style: TextStyle(
              color: cor,
              fontWeight: FontWeight.w700,
              fontSize: compacto ? 11 : 13,
              letterSpacing: 0.2,
            ),
          ),
        ],
      ),
    );
  }
}
