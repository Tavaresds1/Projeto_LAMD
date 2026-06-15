import '../models/prestador.dart';
import 'api_client.dart';

/// Serviço de prestadores — encapsula o endpoint `/prestadores`.
class PrestadorService {
  final ApiClient _api;

  PrestadorService(this._api);

  /// GET /prestadores
  Future<List<Prestador>> listar() async {
    final resp = await _api.get('/prestadores');
    return (resp['dados'] as List)
        .map((e) => Prestador.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}
