import 'dart:convert';
import 'package:http/http.dart' as http;

import '../core/config/api_config.dart';

/// Exceção padronizada para falhas de comunicação com a API.
class ApiException implements Exception {
  final String mensagem;
  final int? statusCode;

  ApiException(this.mensagem, {this.statusCode});

  @override
  String toString() => mensagem;
}

/// Cliente HTTP genérico responsável por:
/// - montar a URL a partir da [ApiConfig];
/// - serializar/desserializar JSON;
/// - traduzir erros HTTP em [ApiException] com a mensagem do backend.
///
/// É a única classe que conhece o pacote `http`, isolando os detalhes de
/// transporte das camadas superiores (services → repositories → providers).
class ApiClient {
  final http.Client _http;
  final String baseUrl;

  ApiClient({http.Client? client, String? baseUrl})
      : _http = client ?? http.Client(),
        baseUrl = baseUrl ?? ApiConfig.baseUrl;

  static const _headers = {'Content-Type': 'application/json'};
  static const _timeout = Duration(seconds: 15);

  Uri _uri(String path, [Map<String, dynamic>? query]) {
    final limpos = query?..removeWhere((_, v) => v == null || v == '');
    return Uri.parse('$baseUrl$path').replace(
      queryParameters: limpos?.map((k, v) => MapEntry(k, v.toString())),
    );
  }

  Future<dynamic> get(String path, {Map<String, dynamic>? query}) async {
    return _enviar(() => _http.get(_uri(path, query), headers: _headers));
  }

  Future<dynamic> post(String path, Map<String, dynamic> body) async {
    return _enviar(
      () => _http.post(_uri(path), headers: _headers, body: jsonEncode(body)),
    );
  }

  Future<dynamic> patch(String path, Map<String, dynamic> body) async {
    return _enviar(
      () => _http.patch(_uri(path), headers: _headers, body: jsonEncode(body)),
    );
  }

  Future<dynamic> _enviar(Future<http.Response> Function() requisicao) async {
    http.Response resp;
    try {
      resp = await requisicao().timeout(_timeout);
    } catch (e) {
      throw ApiException(
        'Não foi possível conectar ao servidor. Verifique sua conexão '
        'e se a API está rodando.',
      );
    }

    final corpo = resp.body.isNotEmpty ? jsonDecode(resp.body) : null;

    if (resp.statusCode >= 200 && resp.statusCode < 300) {
      return corpo;
    }

    final msg = (corpo is Map && corpo['erro'] != null)
        ? corpo['erro'].toString()
        : 'Erro ${resp.statusCode} ao processar a requisição.';
    throw ApiException(msg, statusCode: resp.statusCode);
  }
}
