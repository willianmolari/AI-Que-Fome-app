import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/food_item.dart';

/// Cliente para a API pública do USDA FoodData Central (FDC v1).
///
/// Nenhuma chave é embutida no binário. O usuário informa a própria chave na
/// tela de metas; quando não há chave, usa-se `DEMO_KEY` (limite baixo).
class UsdaClient {
  static const _baseUrl = 'https://api.nal.usda.gov/fdc/v1';
  static const _demoKey = 'DEMO_KEY';

  final http.Client _http;
  final String apiKey;

  UsdaClient({http.Client? client, String? apiKey})
      : _http = client ?? http.Client(),
        apiKey = (apiKey == null || apiKey.trim().isEmpty)
            ? _demoKey
            : apiKey.trim();

  bool get isUsingDemoKey => apiKey == _demoKey;

  Future<List<FoodItem>> search(String query, {int pageSize = 40}) async {
    final term = query.trim();
    if (term.isEmpty) return [];

    final uri = Uri.parse('$_baseUrl/foods/search').replace(queryParameters: {
      'api_key': apiKey,
      'query': term,
      'pageSize': '$pageSize',
      // Inclui dados analisados, industriais e da pesquisa de ingestão.
      'dataType': 'Foundation,SR Legacy,Branded,Survey (FNDDS)',
    });

    final response = await _http
        .get(uri)
        .timeout(const Duration(seconds: 20));

    if (response.statusCode == 401 || response.statusCode == 403) {
      throw const UsdaException(
        'Chave da API inválida. Abra "Metas" e informe uma chave do USDA.',
      );
    }
    if (response.statusCode == 429) {
      throw const UsdaException(
        'Limite de requisições do USDA atingido. Tente novamente mais tarde '
        'ou configure sua própria chave.',
      );
    }
    if (response.statusCode != 200) {
      throw UsdaException(
        'Falha ao consultar o USDA (HTTP ${response.statusCode}).',
      );
    }

    final Map<String, dynamic> body;
    try {
      body = jsonDecode(response.body) as Map<String, dynamic>;
    } catch (_) {
      throw const UsdaException('Resposta inesperada do USDA.');
    }

    final normalized = FoodItem.normalizeFoodText(term);
    final foods = body['foods'] as List<dynamic>? ?? [];
    final items = foods
        .whereType<Map<String, dynamic>>()
        .map(_parseFood)
        .where((item) => item.kcal > 0 || item.protein > 0)
        .toList();

    // O USDA ordena por relevância própria; aqui priorizamos correspondências
    // que começam com o termo digitado e itens com porção bem definida.
    items.sort((a, b) {
      final scoreA = _relevance(a, normalized);
      final scoreB = _relevance(b, normalized);
      return scoreB.compareTo(scoreA);
    });
    return items;
  }

  int _relevance(FoodItem item, String term) {
    final name = FoodItem.normalizeFoodText(item.name);
    var score = 0;
    if (name.startsWith(term)) score += 4;
    if (name == term) score += 3;
    if (item.servingSize > 0 && item.servingSize != 100) score += 1;
    if (item.dataType == 'Branded') score += 1;
    return score;
  }

  FoodItem _parseFood(Map<String, dynamic> json) {
    final nutrientIds = <int, double>{};
    for (final raw in json['foodNutrients'] as List<dynamic>? ?? []) {
      if (raw is! Map<String, dynamic>) continue;
      final id = raw['nutrientId'];
      final value = raw['value'];
      if (id is int && value is num) nutrientIds[id] = value.toDouble();
    }

    double n(int id) => nutrientIds[id] ?? 0;

    // Branded foods trazem os valores no campo "servingSize"; os demais usam 100 g.
    final servingSize = _readServingSize(json);
    final unit = (json['servingSizeUnit'] as String?)?.trim().toUpperCase();
    final isGrams = unit == null || unit.isEmpty || unit == 'G' || unit == 'GR';

    return FoodItem(
      fdcId: (json['fdcId'] as num?)?.toInt() ?? 0,
      name: (json['description'] as String?)?.trim().isEmpty ?? true
          ? 'Alimento sem nome'
          : (json['description'] as String).trim(),
      brand: (json['brandName'] as String?)?.trim().isNotEmpty ?? false
          ? json['brandName'] as String
          : json['brandOwner'] as String?,
      dataType: json['dataType'] as String? ?? '',
      servingSize: isGrams ? servingSize : 100,
      servingUnit: isGrams ? 'g' : unit,
      kcal: n(1008),
      protein: n(1003),
      fat: n(1004),
      carbs: n(1050),
      fiber: n(1079),
      sugars: n(2000),
    );
  }

  double _readServingSize(Map<String, dynamic> json) {
    final value = json['servingSize'];
    if (value is num && value > 0) return value.toDouble();

    // Fallback: alguns registros Brand trazem somente o texto da porção.
    final label = json['servingSizeText'] as String?;
    if (label != null) {
      final match = RegExp(r'([\d.,]+)').firstMatch(label);
      if (match != null) {
        return double.tryParse(
              match.group(1)!.replaceAll(',', '.'),
            ) ??
            100;
      }
    }
    return 100;
  }

  void dispose() => _http.close();
}

class UsdaException implements Exception {
  final String message;
  const UsdaException(this.message);

  @override
  String toString() => message;
}
