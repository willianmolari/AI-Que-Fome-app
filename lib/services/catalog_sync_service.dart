import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/food_item.dart';

/// Baixa o catálogo mantido em um JSON público no GitHub.
///
/// É um arquivo estático, sem API ou chave: basta editar o JSON no repositório
/// para ampliar o catálogo sem gerar um novo APK.
class CatalogSyncService {
  static const url =
      'https://raw.githubusercontent.com/willianmolari/AI-Que-Fome-app/main/'
      '.food_catalog.json';

  final http.Client _client;

  CatalogSyncService({http.Client? client}) : _client = client ?? http.Client();

  void dispose() => _client.close();

  Future<List<FoodItem>> fetch() async {
    final response = await _client
        .get(Uri.parse(url))
        .timeout(const Duration(seconds: 12));
    if (response.statusCode != 200) {
      throw Exception('Catálogo remoto indisponível (${response.statusCode}).');
    }

    final decoded = jsonDecode(response.body);
    final raw = decoded is List
        ? decoded
        : decoded is Map<String, dynamic>
        ? decoded['foods']
        : null;
    if (raw is! List) {
      throw const FormatException('JSON de catálogo inválido.');
    }

    final foods = <FoodItem>[];
    for (final entry in raw) {
      if (entry is! Map<String, dynamic>) continue;
      try {
        foods.add(FoodItem.fromJson(entry));
      } catch (_) {
        // Ignora registros malformados sem descartar o arquivo inteiro.
      }
    }
    return foods;
  }
}
