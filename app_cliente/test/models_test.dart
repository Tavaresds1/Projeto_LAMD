import 'package:flutter_test/flutter_test.dart';
import 'package:sos_reparos_cliente/core/utils/status_helper.dart';
import 'package:sos_reparos_cliente/models/solicitacao.dart';

void main() {
  group('Solicitacao.fromJson', () {
    test('mapeia os campos básicos da listagem', () {
      final json = {
        'id': 1,
        'tipo_servico': 'Vazamento',
        'descricao': 'Vazamento na pia da cozinha',
        'endereco': 'Rua X, 100',
        'status': 'PENDENTE',
        'criado_em': '2026-06-15T10:00:00.000Z',
        'atualizado_em': '2026-06-15T10:00:00.000Z',
        'usuario_nome': 'João',
        'prestador_nome': null,
      };

      final s = Solicitacao.fromJson(json);

      expect(s.id, 1);
      expect(s.tipoServico, 'Vazamento');
      expect(s.status, 'PENDENTE');
      expect(s.temPrestador, isFalse);
      expect(s.criadoEm, isNotNull);
    });

    test('temPrestador é verdadeiro quando há prestador', () {
      final s = Solicitacao.fromJson({
        'id': 2,
        'tipo_servico': 'Desentupimento',
        'descricao': 'Ralo entupido no banheiro',
        'endereco': 'Rua Y, 200',
        'status': 'ACEITO',
        'prestador_nome': 'Carlos Encanador',
      });

      expect(s.temPrestador, isTrue);
      expect(s.prestadorNome, 'Carlos Encanador');
    });
  });

  group('StatusHelper', () {
    test('rotula os status conhecidos', () {
      expect(StatusHelper.rotulo('EM_ANDAMENTO'), 'Em andamento');
      expect(StatusHelper.rotulo('CONCLUIDO'), 'Concluído');
    });

    test('retorna o próprio valor para status desconhecido', () {
      expect(StatusHelper.rotulo('XPTO'), 'XPTO');
    });
  });
}
