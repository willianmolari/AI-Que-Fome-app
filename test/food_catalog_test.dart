import 'package:flutter_test/flutter_test.dart';
import 'package:nutridobra/data/food_catalog.dart';

void main() {
  test('busca alimentos brasileiros sem considerar acentos', () {
    final results = FoodCatalog.search(
      'feijao carioca',
      sources: const {'brasil'},
    );
    expect(results, isNotEmpty);
    expect(
      results.first.name.toLowerCase(),
      contains('feijão carioca'),
    );
  });

  test('busca fast food por marca e produto', () {
    final results = FoodCatalog.search(
      'big mac',
      sources: const {'fastfood'},
    );
    expect(results, isNotEmpty);
    expect(results.first.brand, "McDonald's");
    expect(results.first.source, 'fastfood');
  });

  test('filtro por categoria limita os resultados', () {
    final results = FoodCatalog.search(
      '',
      sources: const {'brasil'},
      category: 'Frutas',
    );
    expect(results, isNotEmpty);
    expect(results.every((item) => item.category == 'Frutas'), isTrue);
  });

  test('busca whey das marcas brasileiras', () {
    final results = FoodCatalog.search(
      'whey',
      sources: const {'suplemento'},
    );
    expect(results.length, greaterThan(10));
    final brands = results.map((item) => item.brand).toSet();
    expect(brands, contains('Growth Supplements'));
    expect(brands, contains('Integral Médica'));
    expect(brands, contains('Black Skull'));
    expect(results.every((item) => item.category == 'Suplementos'), isTrue);
  });

  test('catálogo TACO está disponível offline', () {
    final results = FoodCatalog.search(
      'arroz',
      sources: const {'taco'},
    );
    expect(results, isNotEmpty);
    expect(results.first.source, 'taco');
  });

  test('inclui aveia e leite semidesnatado', () {
    final oats = FoodCatalog.search('aveia', sources: const {'brasil', 'taco'});
    final milk = FoodCatalog.search(
      'leite semidesnatado',
      sources: const {'brasil', 'taco'},
    );
    expect(oats, isNotEmpty);
    expect(milk, isNotEmpty);
    expect(
      oats.map((item) => item.name).toList(),
      contains('Aveia em flocos'),
    );
    expect(
      milk.map((item) => item.name).toList(),
      contains('Leite semidesnatado'),
    );
  });

  test('catálogo comum cobre categorias brasileiras', () {
    final results = FoodCatalog.search('', sources: const {'brasil'});
    expect(results.length, greaterThan(180));
    final categories = results.map((item) => item.category).toSet();
    expect(categories, contains('Grãos e cereais'));
    expect(categories, contains('Legumes e verduras'));
    expect(categories, contains('Padaria'));
    expect(categories, contains('Pratos prontos'));
  });
}
