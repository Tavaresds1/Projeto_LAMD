import 'package:flutter/material.dart';

/// Utilitários de apresentação para o ciclo de vida do status de uma
/// solicitação:  PENDENTE → ACEITO → EM_ANDAMENTO → CONCLUIDO  (ou RECUSADO).
class StatusHelper {
  StatusHelper._();

  static String rotulo(String status) {
    switch (status.toUpperCase()) {
      case 'PENDENTE':
        return 'Pendente';
      case 'ACEITO':
        return 'Aceito';
      case 'EM_ANDAMENTO':
        return 'Em andamento';
      case 'CONCLUIDO':
        return 'Concluído';
      case 'RECUSADO':
        return 'Recusado';
      default:
        return status;
    }
  }

  static Color cor(String status) {
    switch (status.toUpperCase()) {
      case 'PENDENTE':
        return const Color(0xFFF9A825); // âmbar
      case 'ACEITO':
        return const Color(0xFF1E88E5); // azul
      case 'EM_ANDAMENTO':
        return const Color(0xFF6A1B9A); // roxo
      case 'CONCLUIDO':
        return const Color(0xFF2E7D32); // verde
      case 'RECUSADO':
        return const Color(0xFFC62828); // vermelho
      default:
        return Colors.grey;
    }
  }

  static IconData icone(String status) {
    switch (status.toUpperCase()) {
      case 'PENDENTE':
        return Icons.hourglass_empty;
      case 'ACEITO':
        return Icons.check_circle_outline;
      case 'EM_ANDAMENTO':
        return Icons.build_circle_outlined;
      case 'CONCLUIDO':
        return Icons.task_alt;
      case 'RECUSADO':
        return Icons.cancel_outlined;
      default:
        return Icons.help_outline;
    }
  }
}
