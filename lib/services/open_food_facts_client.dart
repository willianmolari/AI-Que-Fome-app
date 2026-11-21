import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/food_item.dart';

/// Cliente para a API aberta do Open Food Facts, limitada a produtos
/// comercializados no Brasil. Não exige chave de API.
class OpenFoodFactsClient {
  static const _host = 'world.openfoodfacts.org';
  static const _path = '/cgi/search.pl';

  final http.Client _http;

  OpenFoodFactsClient({http.Client? client}) : _http = client ?? http.Client();

  Future<List<FoodItem>> search(String query, {int pageSize = 20}) async {
    final term = query.trim();
    if (term.isEmpty) return [];

    final uri = Uri.https(_host, _path, {
      'search_terms': term,
      'countries_tags': 'br',
      'json': '1',
      'page_size': '$pageSize',
      'page': '1',
      'sort_by': 'unique_scans_n',
    });

    final response = await _http.get(uri).timeout(const Duration(seconds: 20));
    if (response.statusCode != 200) {
      throw OpenFoodFactsException(
        'Falha ao consultar o Open Food Facts (HTTP ${response.statusCode}).',
      );
    }

    final Map<String, dynamic> body;
    try {
      body = jsonDecode(response.body) as Map<String, dynamic>;
    } catch (_) {
      throw const OpenFoodFactsException(
        'Resposta inesperada do Open Food Facts.',
      );
    }

    final products = body['products'] as List<dynamic>? ?? [];
    final normalized = FoodItem.normalizeFoodText(term);
    final items = <FoodItem>[];

    for (final raw in products) {
      if (raw is! Map<String, dynamic>) continue;
      final item = _parse(raw);
      if (item == null) continue;
      if (item.kcal <= 0 && item.protein <= 0) continue;
      if (!_matches(item, normalized)) continue;
      items.add(item);
    }

    return items.take(pageSize).toList();
  }

  FoodItem? _parse(Map<String, dynamic> product) {
    final name = (product['product_name'] ??
            product['product_name_pt'] ??
            product['generic_name'] ??
            '')
        .toString()
        .trim();
    if (name.isEmpty) return null;

    final nutriments =
        product['nutriments'] as Map<String, dynamic>? ?? const {};
    final kcal = _nutriment(nutriments, 'energy-kcal_100g') ??
        (_nutriment(nutriments, 'energy_100g') ?? 0) / 4.184;
    final brand = (product['brands'] ?? '').toString().trim();
    final code = (product['code'] ?? '').toString();

    return FoodItem(
      fdcId: code.hashCode,
      name: name,
      brand: brand.isEmpty ? null : brand,
      dataType: 'Open Food Facts',
      servingSize: _servingSize(product),
      kcal: kcal,
      protein: _nutriment(nutriments, 'proteins_100g') ?? 0,
      carbs: _nutriment(nutriments, 'carbohydrates_100g') ?? 0,
      fat: _nutriment(nutriments, 'fat_100g') ?? 0,
      fiber: _nutriment(nutriments, 'fiber_100g') ?? 0,
      sugars: _nutriment(nutriments, 'sugars_100g') ?? 0,
      source: 'openfoodfacts',
      category: _category(product, name),
    );
  }

  double? _nutriment(Map<String, dynamic> nutriments, String key) {
    final raw = nutriments[key];
    if (raw == null) return null;
    if (raw is num) return raw.toDouble();
    return double.tryParse(raw.toString().replaceAll(',', '.'));
  }

  double _servingSize(Map<String, dynamic> product) {
    final quantity = _nutriment(product, 'serving_quantity');
    if (quantity != null && quantity > 0 && quantity <= 2000) return quantity;
    return 100;
  }

  String _category(Map<String, dynamic> product, String name) {
    final tags = (product['categories_tags'] as List<dynamic>? ?? [])
        .join(' ')
        .toLowerCase();
    final text = '$tags ${name.toLowerCase()}';
    if (text.contains('whey') ||
        text.contains('prote') ||
        text.contains('suplement')) {
      return 'Suplementos';
    }
    if (text.contains('bebida') ||
        text.contains('refrigerant') ||
        text.contains('suco') ||
        text.contains('drink')) {
      return 'Bebidas';
    }
    if (text.contains('doce') ||
        text.contains('chocolate') ||
        text.contains('biscoit') ||
        text.contains('bolo')) {
      return 'Doces';
    }
    if (text.contains('latic') ||
        text.contains('queijo') ||
        text.contains('leite') ||
        text.contains('iogurt')) {
      return 'Laticínios';
    }
    if (text.contains('carne') ||
        text.contains('frango') ||
        text.contains('peixe')) {
      return 'Carnes';
    }
    if (text.contains('fruta') || text.contains('banana')) return 'Frutas';
    return 'Outros';
  }

  bool _matches(FoodItem item, String normalizedQuery) {
    if (normalizedQuery.isEmpty) return true;
    return item.matches(normalizedQuery);
  }

  void dispose() => _http.close();
}

class OpenFoodFactsException implements Exception {
  final String message;
  const OpenFoodFactsException(this.message);

  @override
  String toString() => message;
}
