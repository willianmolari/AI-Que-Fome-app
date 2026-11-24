/// Catálogo local de alimentos brasileiros e de redes de fast food.
///
/// Os valores são aproximações obtidas de tabelas públicas de composição de
/// alimentos e de informações nutricionais divulgadas pelas próprias redes.
/// Não há cópia de banco proprietário: o catálogo é mantido aqui, em código,
/// e pode ser editado livremente.
library;

import '../models/food_item.dart';
import 'beverages.dart';
import 'common_brazilian_foods.dart';
import 'extra_foods.dart';
import 'taco_foods.dart';

class FoodCatalog {
  FoodCatalog._();

  static const categories = [
    'Todos',
    'Arroz e feijão',
    'Grãos e cereais',
    'Carnes',
    'Frutas',
    'Legumes e verduras',
    'Laticínios',
    'Padaria',
    'Pratos prontos',
    'Bebidas',
    'Líquidos',
    'Doces',
    'Fast food',
    'Suplementos',
    'Outros',
  ];

  static final List<FoodItem> all = <FoodItem>[
    ..._brazilian,
    ...commonBrazilianFoods,
    ...extraFoods,
    ..._fastFood,
    ..._supplements,
    ...tacoFoods,
    ...beverages,
  ];

  /// Itens exibidos quando o usuário ainda não digitou nada.
  static List<FoodItem> popular() {
    final names = {
      'Arroz branco cozido',
      'Feijão carioca cozido',
      'Peito de frango grelhado',
      'Pão francês',
      'Aveia em flocos',
      'Leite semidesnatado',
      'Banana',
      'Açaí (polpa)',
      'Big Mac',
      'Batata frita grande',
      'Whey Protein Concentrado',
      'Whey Isolado',
    };
    return all.where((item) => names.contains(item.name)).toList();
  }

  static List<FoodItem> search(
    String query, {
    Set<String> sources = const {
      'brasil',
      'fastfood',
      'suplemento',
      'taco',
    },
    String category = 'Todos',
    List<FoodItem> extras = const [],
  }) {
    final term = FoodItem.normalizeFoodText(query);
    return [...all, ...extras].where((item) {
      if (!sources.contains(item.source)) return false;
      if (category == 'Líquidos') {
        final isLiquid =
            item.servingUnit == 'ml' || item.category == 'Bebidas';
        if (!isLiquid) return false;
      } else if (category != 'Todos' && item.category != category) {
        return false;
      }
      if (term.isEmpty) return true;
      return item.matches(term);
    }).toList();
  }
}

int _nextId = -1000;

FoodItem _br(
  String name, {
  required double kcal,
  required double protein,
  required double carbs,
  required double fat,
  double fiber = 0,
  double sugars = 0,
  double servingSize = 100,
  String servingUnit = 'g',
  required String category,
  String? brand,
}) {
  return FoodItem(
    fdcId: _nextId--,
    name: name,
    brand: brand,
    dataType: 'Catálogo local',
    servingSize: servingSize,
    servingUnit: servingUnit,
    kcal: kcal,
    protein: protein,
    carbs: carbs,
    fat: fat,
    fiber: fiber,
    sugars: sugars,
    source: 'brasil',
    category: category,
  );
}

/// Converte valores de uma porção comercial em valores por 100 g.
FoodItem _fast(
  String name, {
  required String brand,
  required double servingGrams,
  required double kcal,
  required double protein,
  required double carbs,
  required double fat,
  double fiber = 0,
  double sugars = 0,
  String category = 'Fast food',
  String source = 'fastfood',
  String servingUnit = 'g',
}) {
  final f = 100 / servingGrams;
  return FoodItem(
    fdcId: _nextId--,
    name: name,
    brand: brand,
    dataType: 'Porção comercial',
    servingSize: servingGrams,
    servingUnit: servingUnit,
    kcal: kcal * f,
    protein: protein * f,
    carbs: carbs * f,
    fat: fat * f,
    fiber: fiber * f,
    sugars: sugars * f,
    source: source,
    category: category,
  );
}

final List<FoodItem> _brazilian = <FoodItem>[
  // Arroz, feijão e farinhas
  _br('Arroz branco cozido', kcal: 130, protein: 2.7, carbs: 28.2, fat: 0.3, fiber: 0.4, category: 'Arroz e feijão'),
  _br('Arroz integral cozido', kcal: 123, protein: 2.7, carbs: 25.6, fat: 1.0, fiber: 1.8, category: 'Arroz e feijão'),
  _br('Arroz com feijão (prato pronto)', kcal: 145, protein: 5.2, carbs: 25.0, fat: 1.6, fiber: 3.2, category: 'Arroz e feijão'),
  _br('Feijão carioca cozido', kcal: 77, protein: 4.5, carbs: 13.6, fat: 0.5, fiber: 3.6, category: 'Arroz e feijão'),
  _br('Feijão preto cozido', kcal: 85, protein: 4.5, carbs: 15.2, fat: 0.4, fiber: 3.8, category: 'Arroz e feijão'),
  _br('Farinha de mandioca', kcal: 360, protein: 1.2, carbs: 87.0, fat: 0.8, fiber: 4.5, category: 'Arroz e feijão'),
  _br('Farofa de bacon', kcal: 392, protein: 6.5, carbs: 36.0, fat: 24.0, fiber: 3.0, category: 'Arroz e feijão'),
  _br('Cuscuz de milho cozido', kcal: 122, protein: 3.0, carbs: 25.0, fat: 0.5, fiber: 1.5, category: 'Arroz e feijão'),
  _br('Tapioca cozida', kcal: 130, protein: 0.2, carbs: 32.0, fat: 0.1, category: 'Arroz e feijão'),
  _br('Polenta cozida', kcal: 92, protein: 2.3, carbs: 19.0, fat: 0.4, fiber: 1.2, category: 'Arroz e feijão'),

  // Carnes, ovos e peixes
  _br('Peito de frango grelhado', kcal: 165, protein: 31.0, carbs: 0, fat: 3.6, category: 'Carnes'),
  _br('Frango frito (sem farinha)', kcal: 246, protein: 25.0, carbs: 0, fat: 15.0, category: 'Carnes'),
  _br('Carne bovina grelhada', kcal: 250, protein: 26.0, carbs: 0, fat: 15.5, category: 'Carnes'),
  _br('Carne de sol grelhada', kcal: 210, protein: 29.0, carbs: 0, fat: 10.0, category: 'Carnes'),
  _br('Linguiça calabresa grelhada', kcal: 320, protein: 16.0, carbs: 1.5, fat: 27.0, category: 'Carnes'),
  _br('Hambúrguer caseiro (carne bovina)', kcal: 250, protein: 22.0, carbs: 0, fat: 18.0, category: 'Carnes'),
  _br('Ovo cozido', kcal: 155, protein: 12.6, carbs: 1.1, fat: 10.6, category: 'Carnes', servingSize: 50, servingUnit: 'g'),
  _br('Ovo frito', kcal: 196, protein: 13.0, carbs: 0.8, fat: 15.0, category: 'Carnes'),
  _br('Tilápia grelhada', kcal: 129, protein: 26.0, carbs: 0, fat: 2.7, category: 'Carnes'),
  _br('Salmão grelhado', kcal: 208, protein: 22.0, carbs: 0, fat: 13.0, category: 'Carnes'),
  _br('Atum em óleo (escorrido)', kcal: 198, protein: 25.0, carbs: 0, fat: 10.0, category: 'Carnes'),

  // Laticínios
  _br('Queijo minas frescal', kcal: 270, protein: 18.0, carbs: 2.0, fat: 21.0, category: 'Laticínios'),
  _br('Queijo prato', kcal: 356, protein: 22.0, carbs: 2.4, fat: 29.0, category: 'Laticínios'),
  _br('Queijo mussarela', kcal: 300, protein: 22.0, carbs: 2.0, fat: 23.0, category: 'Laticínios'),
  _br('Requeijão cremoso', kcal: 242, protein: 5.5, carbs: 6.0, fat: 22.0, category: 'Laticínios'),
  _br('Iogurte natural integral', kcal: 61, protein: 3.5, carbs: 4.7, fat: 3.3, category: 'Laticínios'),
  _br('Iogurte grego natural', kcal: 97, protein: 9.0, carbs: 3.6, fat: 5.0, category: 'Laticínios'),
  _br('Leite integral', kcal: 61, protein: 3.2, carbs: 4.8, fat: 3.3, sugars: 4.8, servingSize: 200, servingUnit: 'ml', category: 'Laticínios'),
  _br('Leite desnatado', kcal: 34, protein: 3.4, carbs: 5.0, fat: 0.2, sugars: 5.0, servingSize: 200, servingUnit: 'ml', category: 'Laticínios'),
  _br('Cream cheese', kcal: 342, protein: 6.0, carbs: 4.0, fat: 34.0, category: 'Laticínios'),

  // Frutas e verduras
  _br('Banana', kcal: 89, protein: 1.1, carbs: 22.8, fat: 0.3, fiber: 2.6, sugars: 12.2, category: 'Frutas'),
  _br('Maçã', kcal: 52, protein: 0.3, carbs: 13.8, fat: 0.2, fiber: 2.4, sugars: 10.4, category: 'Frutas'),
  _br('Laranja', kcal: 47, protein: 0.9, carbs: 11.8, fat: 0.1, fiber: 2.4, sugars: 9.4, category: 'Frutas'),
  _br('Mamão papaia', kcal: 45, protein: 0.5, carbs: 11.4, fat: 0.3, fiber: 1.8, sugars: 7.8, category: 'Frutas'),
  _br('Manga', kcal: 60, protein: 0.8, carbs: 15.0, fat: 0.4, fiber: 1.6, sugars: 13.7, category: 'Frutas'),
  _br('Abacaxi', kcal: 50, protein: 0.5, carbs: 13.1, fat: 0.1, fiber: 1.4, sugars: 9.3, category: 'Frutas'),
  _br('Açaí (polpa)', kcal: 70, protein: 1.0, carbs: 17.0, fat: 0.6, fiber: 2.3, sugars: 0.5, category: 'Frutas'),
  _br('Goiaba', kcal: 68, protein: 1.1, carbs: 17.4, fat: 1.0, fiber: 5.4, sugars: 9.0, category: 'Frutas'),
  _br('Morango', kcal: 32, protein: 0.7, carbs: 7.7, fat: 0.3, fiber: 2.0, sugars: 4.9, category: 'Frutas'),
  _br('Limão', kcal: 29, protein: 1.1, carbs: 9.3, fat: 0.3, fiber: 2.8, category: 'Frutas'),
  _br('Batata cozida', kcal: 87, protein: 1.9, carbs: 20.1, fat: 0.1, fiber: 1.8, category: 'Outros'),
  _br('Batata frita caseira', kcal: 312, protein: 3.4, carbs: 41.0, fat: 15.0, fiber: 3.8, category: 'Outros'),
  _br('Mandioca cozida', kcal: 130, protein: 1.2, carbs: 30.0, fat: 0.2, fiber: 1.5, category: 'Outros'),
  _br('Tomate', kcal: 18, protein: 0.9, carbs: 3.9, fat: 0.2, fiber: 1.2, category: 'Outros'),
  _br('Alface', kcal: 15, protein: 1.4, carbs: 2.9, fat: 0.2, fiber: 1.3, category: 'Outros'),
  _br('Brócolis cozido', kcal: 35, protein: 2.4, carbs: 7.2, fat: 0.4, fiber: 3.3, category: 'Outros'),

  // Bebidas
  _br('Café com açúcar', kcal: 42, protein: 0.2, carbs: 10.5, fat: 0, sugars: 10.5, servingSize: 100, servingUnit: 'ml', category: 'Bebidas'),
  _br('Refrigerante de cola', kcal: 42, protein: 0, carbs: 10.6, fat: 0, sugars: 10.6, servingSize: 100, servingUnit: 'ml', category: 'Bebidas'),
  _br('Suco de laranja natural', kcal: 45, protein: 0.7, carbs: 10.4, fat: 0.2, sugars: 8.4, servingSize: 100, servingUnit: 'ml', category: 'Bebidas'),
  _br('Suco de caixa (uva)', kcal: 60, protein: 0.1, carbs: 14.8, fat: 0, sugars: 13.5, servingSize: 100, servingUnit: 'ml', category: 'Bebidas'),
  _br('Água de coco', kcal: 19, protein: 0.5, carbs: 4.0, fat: 0.2, sugars: 2.6, servingSize: 100, servingUnit: 'ml', category: 'Bebidas'),
  _br('Cerveja lager', kcal: 43, protein: 0.4, carbs: 3.6, fat: 0, servingSize: 100, servingUnit: 'ml', category: 'Bebidas'),
  _br('Vinho tinto', kcal: 85, protein: 0.1, carbs: 2.6, fat: 0, servingSize: 100, servingUnit: 'ml', category: 'Bebidas'),

  // Doces e gorduras
  _br('Pão de queijo', kcal: 290, protein: 7.0, carbs: 38.0, fat: 12.0, fiber: 1.5, category: 'Doces'),
  _br('Bolo de cenoura com cobertura', kcal: 356, protein: 4.5, carbs: 55.0, fat: 13.0, sugars: 34.0, category: 'Doces'),
  _br('Brigadeiro', kcal: 402, protein: 3.5, carbs: 52.0, fat: 20.0, sugars: 45.0, category: 'Doces'),
  _br('Doce de leite', kcal: 321, protein: 4.0, carbs: 66.0, fat: 4.5, sugars: 60.0, category: 'Doces'),
  _br('Paçoca de amendoim', kcal: 450, protein: 12.0, carbs: 42.0, fat: 25.0, sugars: 30.0, category: 'Doces'),
  _br('Rapadura', kcal: 380, protein: 0.4, carbs: 92.0, fat: 0.1, sugars: 85.0, category: 'Doces'),
  _br('Mel', kcal: 304, protein: 0.3, carbs: 82.4, fat: 0, sugars: 82.1, category: 'Doces'),
  _br('Açúcar refinado', kcal: 387, protein: 0, carbs: 100, fat: 0, sugars: 100, category: 'Doces'),
  _br('Azeite de oliva', kcal: 884, protein: 0, carbs: 0, fat: 100, category: 'Outros'),
  _br('Manteiga', kcal: 717, protein: 0.9, carbs: 0.1, fat: 81.0, category: 'Outros'),
  _br('Margarina', kcal: 720, protein: 0.5, carbs: 1.0, fat: 80.0, category: 'Outros'),
  _br('Amendoim torrado', kcal: 567, protein: 25.0, carbs: 16.0, fat: 49.0, fiber: 8.5, category: 'Outros'),
];

final List<FoodItem> _fastFood = <FoodItem>[
  // McDonald's
  _fast('Big Mac', brand: "McDonald's", servingGrams: 219, kcal: 550, protein: 25, carbs: 45, fat: 30, fiber: 3, sugars: 9),
  _fast('Quarter Pounder com queijo', brand: "McDonald's", servingGrams: 171, kcal: 520, protein: 30, carbs: 42, fat: 26, fiber: 3, sugars: 10),
  _fast('McChicken', brand: "McDonald's", servingGrams: 139, kcal: 370, protein: 14, carbs: 39, fat: 18, fiber: 2, sugars: 5),
  _fast('Chicken McNuggets (10 unidades)', brand: "McDonald's", servingGrams: 170, kcal: 410, protein: 23, carbs: 22, fat: 24, fiber: 1, sugars: 1),
  _fast('Batata frita grande', brand: "McDonald's", servingGrams: 154, kcal: 510, protein: 7, carbs: 66, fat: 24, fiber: 6, sugars: 1),
  _fast('Batata frita média', brand: "McDonald's", servingGrams: 117, kcal: 375, protein: 5, carbs: 48, fat: 18, fiber: 4),
  _fast('McFlurry Oreo', brand: "McDonald's", servingGrams: 190, kcal: 510, protein: 9, carbs: 70, fat: 22, sugars: 55),
  _fast('Sundae de chocolate', brand: "McDonald's", servingGrams: 170, kcal: 430, protein: 7, carbs: 62, fat: 17, sugars: 52),
  _fast('Pão de queijo do McCafé', brand: "McDonald's", servingGrams: 85, kcal: 270, protein: 6, carbs: 34, fat: 12),

  // Burger King
  _fast('Whopper', brand: 'Burger King', servingGrams: 290, kcal: 660, protein: 31, carbs: 55, fat: 39, fiber: 4, sugars: 12),
  _fast('Whopper Duplo', brand: 'Burger King', servingGrams: 360, kcal: 860, protein: 48, carbs: 56, fat: 55, fiber: 4, sugars: 12),
  _fast('BK Double Burger', brand: 'Burger King', servingGrams: 219, kcal: 590, protein: 34, carbs: 46, fat: 31, fiber: 3, sugars: 9),
  _fast('Chicken Crisper', brand: 'Burger King', servingGrams: 190, kcal: 520, protein: 22, carbs: 51, fat: 26, fiber: 3, sugars: 6),
  _fast('Batata frita grande BK', brand: 'Burger King', servingGrams: 170, kcal: 540, protein: 7, carbs: 68, fat: 27, fiber: 6),
  _fast('Onion Rings (8 unidades)', brand: 'Burger King', servingGrams: 130, kcal: 420, protein: 5, carbs: 47, fat: 24, fiber: 3),

  // KFC
  _fast('Frango frito Original (2 pedaços)', brand: 'KFC', servingGrams: 220, kcal: 550, protein: 38, carbs: 28, fat: 32, fiber: 2),
  _fast('Sanduíche de frango crocante', brand: 'KFC', servingGrams: 205, kcal: 540, protein: 25, carbs: 52, fat: 27, fiber: 3),
  _fast('Batata frita KFC grande', brand: 'KFC', servingGrams: 150, kcal: 470, protein: 6, carbs: 60, fat: 23, fiber: 5),
  _fast('Salada de frango KFC', brand: 'KFC', servingGrams: 260, kcal: 240, protein: 25, carbs: 12, fat: 10, fiber: 5),

  // Subway
  _fast('Sanduíche de peito de frango', brand: 'Subway', servingGrams: 250, kcal: 380, protein: 29, carbs: 46, fat: 9, fiber: 5),
  _fast('Sanduíche Italian BMT', brand: 'Subway', servingGrams: 280, kcal: 480, protein: 24, carbs: 48, fat: 22, fiber: 5),
  _fast('Sanduíche de atum', brand: 'Subway', servingGrams: 250, kcal: 410, protein: 23, carbs: 45, fat: 16, fiber: 5),
  _fast('Salada de frango Subway', brand: 'Subway', servingGrams: 280, kcal: 210, protein: 25, carbs: 12, fat: 8, fiber: 6),

  // Pizza Hut
  _fast('Pizza Margherita (fatia)', brand: 'Pizza Hut', servingGrams: 120, kcal: 300, protein: 12, carbs: 34, fat: 13, fiber: 2, sugars: 4),
  _fast('Pizza Calabresa (fatia)', brand: 'Pizza Hut', servingGrams: 120, kcal: 340, protein: 14, carbs: 33, fat: 17, fiber: 2, sugars: 4),
  _fast('Pizza Frango com catupiry (fatia)', brand: 'Pizza Hut', servingGrams: 120, kcal: 360, protein: 15, carbs: 34, fat: 19, fiber: 2, sugars: 5),

  // Redes brasileiras
  _fast('Esfirra de carne', brand: "Habib's", servingGrams: 120, kcal: 260, protein: 10, carbs: 30, fat: 12, fiber: 2),
  _fast('Kibe frito (4 unidades)', brand: "Habib's", servingGrams: 160, kcal: 360, protein: 14, carbs: 36, fat: 18, fiber: 4),
  _fast('Milk shake de chocolate', brand: "Bob's", servingGrams: 400, kcal: 520, protein: 10, carbs: 78, fat: 18, sugars: 68, servingUnit: 'ml'),
  _fast('Batata frita Bob\'s grande', brand: "Bob's", servingGrams: 150, kcal: 470, protein: 6, carbs: 60, fat: 23, fiber: 5),
  _fast('Sanduíche de frango grelhado', brand: 'Giraffas', servingGrams: 240, kcal: 420, protein: 28, carbs: 44, fat: 15, fiber: 4),
  _fast('Massa ao sugo (porção)', brand: 'Spoleto', servingGrams: 320, kcal: 480, protein: 16, carbs: 82, fat: 9, fiber: 6, sugars: 8),
];

/// Suplementos populares no Brasil. Valores por scoop informado no rótulo.
final List<FoodItem> _supplements = <FoodItem>[
  // Growth Supplements
  _fast('Whey Protein Concentrado', brand: 'Growth Supplements', servingGrams: 30, kcal: 120, protein: 24, carbs: 3, fat: 2, category: 'Suplementos', source: 'suplemento'),
  _fast('Whey Protein Isolado', brand: 'Growth Supplements', servingGrams: 30, kcal: 110, protein: 26, carbs: 1, fat: 1, category: 'Suplementos', source: 'suplemento'),
  _fast('Whey Protein Hidrolisado', brand: 'Growth Supplements', servingGrams: 30, kcal: 115, protein: 25, carbs: 2, fat: 1.5, category: 'Suplementos', source: 'suplemento'),
  _fast('Creatina Monoidratada', brand: 'Growth Supplements', servingGrams: 5, kcal: 0, protein: 0, carbs: 0, fat: 0, category: 'Suplementos', source: 'suplemento'),
  _fast('BCAA 2:1:1', brand: 'Growth Supplements', servingGrams: 5, kcal: 20, protein: 5, carbs: 0, fat: 0, category: 'Suplementos', source: 'suplemento'),
  _fast('Caseína Micelar', brand: 'Growth Supplements', servingGrams: 30, kcal: 110, protein: 24, carbs: 2, fat: 1, category: 'Suplementos', source: 'suplemento'),

  // Integral Médica
  _fast('Whey Protein Concentrado', brand: 'Integral Médica', servingGrams: 30, kcal: 118, protein: 23, carbs: 3.5, fat: 2, category: 'Suplementos', source: 'suplemento'),
  _fast('Whey Isolado', brand: 'Integral Médica', servingGrams: 30, kcal: 108, protein: 25, carbs: 1.5, fat: 0.8, category: 'Suplementos', source: 'suplemento'),
  _fast('Whey 3W', brand: 'Integral Médica', servingGrams: 30, kcal: 120, protein: 24, carbs: 3, fat: 2, category: 'Suplementos', source: 'suplemento'),
  _fast('Creatina', brand: 'Integral Médica', servingGrams: 5, kcal: 0, protein: 0, carbs: 0, fat: 0, category: 'Suplementos', source: 'suplemento'),

  // Black Skull
  _fast('Whey Protein Concentrado', brand: 'Black Skull', servingGrams: 30, kcal: 120, protein: 22, carbs: 4, fat: 2.5, category: 'Suplementos', source: 'suplemento'),
  _fast('Whey Isolado', brand: 'Black Skull', servingGrams: 30, kcal: 110, protein: 25, carbs: 1.5, fat: 1, category: 'Suplementos', source: 'suplemento'),
  _fast('Whey Hidrolisado', brand: 'Black Skull', servingGrams: 30, kcal: 115, protein: 24, carbs: 2, fat: 1.5, category: 'Suplementos', source: 'suplemento'),
  _fast('Creatina Hardcore', brand: 'Black Skull', servingGrams: 5, kcal: 0, protein: 0, carbs: 0, fat: 0, category: 'Suplementos', source: 'suplemento'),

  // Outras marcas brasileiras
  _fast('Whey Protein Concentrado', brand: 'Max Titanium', servingGrams: 30, kcal: 119, protein: 23, carbs: 3, fat: 2.2, category: 'Suplementos', source: 'suplemento'),
  _fast('Whey Isolado', brand: 'Max Titanium', servingGrams: 30, kcal: 110, protein: 26, carbs: 1, fat: 0.9, category: 'Suplementos', source: 'suplemento'),
  _fast('Whey Protein', brand: 'Dux Nutrition', servingGrams: 30, kcal: 120, protein: 24, carbs: 3, fat: 2, category: 'Suplementos', source: 'suplemento'),
  _fast('Whey Protein', brand: 'New Millen', servingGrams: 30, kcal: 118, protein: 23, carbs: 3.5, fat: 2, category: 'Suplementos', source: 'suplemento'),
  _fast('Whey Protein', brand: 'Bodytech', servingGrams: 30, kcal: 120, protein: 24, carbs: 3, fat: 2, category: 'Suplementos', source: 'suplemento'),
  _fast('Whey Protein', brand: 'Probiótica', servingGrams: 30, kcal: 118, protein: 23, carbs: 3, fat: 2, category: 'Suplementos', source: 'suplemento'),
  _fast('Whey Protein', brand: 'Absolute Nutrition', servingGrams: 30, kcal: 120, protein: 24, carbs: 3, fat: 2, category: 'Suplementos', source: 'suplemento'),
  _fast('Whey Protein', brand: 'Infinit Nutrition', servingGrams: 30, kcal: 119, protein: 24, carbs: 3, fat: 2, category: 'Suplementos', source: 'suplemento'),
  _fast('Whey Protein', brand: 'Healthy Time', servingGrams: 30, kcal: 118, protein: 23, carbs: 3, fat: 2, category: 'Suplementos', source: 'suplemento'),
  _fast('Whey Protein', brand: 'Otto Nutri', servingGrams: 30, kcal: 120, protein: 24, carbs: 3, fat: 2, category: 'Suplementos', source: 'suplemento'),
  _fast('Barra de Proteína', brand: 'Growth Supplements', servingGrams: 60, kcal: 220, protein: 20, carbs: 22, fat: 7, category: 'Suplementos', source: 'suplemento'),
  _fast('Barra de Proteína', brand: 'Integral Médica', servingGrams: 60, kcal: 230, protein: 20, carbs: 24, fat: 8, category: 'Suplementos', source: 'suplemento'),
  _fast('Massa Gainer', brand: 'Growth Supplements', servingGrams: 100, kcal: 390, protein: 25, carbs: 65, fat: 4, category: 'Suplementos', source: 'suplemento'),
  _fast('Massa Gainer', brand: 'Black Skull', servingGrams: 100, kcal: 400, protein: 24, carbs: 68, fat: 5, category: 'Suplementos', source: 'suplemento'),
];
