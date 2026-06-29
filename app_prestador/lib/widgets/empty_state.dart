import 'package:flutter/material.dart';

import '../core/theme/app_theme.dart';

class EmptyState extends StatelessWidget {
  final IconData icone;
  final String titulo;
  final String? mensagem;
  final String? rotuloAcao;
  final VoidCallback? aoTocarAcao;

  const EmptyState({
    super.key,
    required this.icone,
    required this.titulo,
    this.mensagem,
    this.rotuloAcao,
    this.aoTocarAcao,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 88,
              height: 88,
              decoration: BoxDecoration(
                color: AppTheme.primariaClara,
                borderRadius: BorderRadius.circular(24),
              ),
              child: Icon(icone, size: 44, color: AppTheme.primaria),
            ),
            const SizedBox(height: 20),
            Text(
              titulo,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: Color(0xFF212121),
                letterSpacing: -0.3,
              ),
            ),
            if (mensagem != null) ...[
              const SizedBox(height: 8),
              Text(
                mensagem!,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: AppTheme.textoSecundario,
                  fontSize: 14,
                  height: 1.5,
                ),
              ),
            ],
            if (rotuloAcao != null && aoTocarAcao != null) ...[
              const SizedBox(height: 24),
              OutlinedButton.icon(
                onPressed: aoTocarAcao,
                icon: const Icon(Icons.refresh, size: 18),
                label: Text(rotuloAcao!),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
