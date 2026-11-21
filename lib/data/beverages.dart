/// Bebidas e refrigerantes comuns no Brasil, com valores por 100 ml.
///
/// Tabela própria, inspirada em informações nutricionais públicas de rótulos.
/// Nenhum dado proprietário é reutilizado.
library;

import '../models/food_item.dart';

int _beverageId = -9000;

FoodItem _liquid(
  String name, {
  required double kcal,
  required double carbs,
  double sugars = 0,
  double protein = 0,
  double fat = 0,
  String? brand,
  double servingSize = 100,
  String category = 'Bebidas',
}) {
  return FoodItem(
    fdcId: _beverageId--,
    name: name,
    brand: brand,
    dataType: 'Bebidas / rótulos públicos',
    servingSize: servingSize,
    servingUnit: 'ml',
    kcal: kcal,
    protein: protein,
    carbs: carbs,
    fat: fat,
    sugars: sugars,
    source: 'brasil',
    category: category,
  );
}

final List<FoodItem> beverages = <FoodItem>[
  // Refrigerantes de cola
  _liquid('Coca-Cola', kcal: 42, carbs: 10.6, sugars: 10.6, brand: 'Coca-Cola', servingSize: 350),
  _liquid('Coca-Cola Zero Açúcar', kcal: 0, carbs: 0, brand: 'Coca-Cola', servingSize: 350),
  _liquid('Coca-Cola Sem Açúcar', kcal: 0, carbs: 0, brand: 'Coca-Cola', servingSize: 350),
  _liquid('Pepsi Cola', kcal: 42, carbs: 10.5, sugars: 10.5, brand: 'Pepsi', servingSize: 350),
  _liquid('Pepsi Zero Açúcar', kcal: 0, carbs: 0, brand: 'Pepsi', servingSize: 350),
  _liquid('Pepsi Cola sem açúcar', kcal: 0, carbs: 0, brand: 'Pepsi', servingSize: 350),

  // Guaraná e outros refrigerantes brasileiros
  _liquid('Guaraná Antarctica', kcal: 45, carbs: 11.4, sugars: 11.4, brand: 'Antarctica', servingSize: 350),
  _liquid('Guaraná Antarctica Zero', kcal: 0, carbs: 0, brand: 'Antarctica', servingSize: 350),
  _liquid('Guaraná KaBu!', kcal: 44, carbs: 11.0, sugars: 11.0, brand: 'Antarctica', servingSize: 350),
  _liquid('Fanta Laranja', kcal: 45, carbs: 11.2, sugars: 11.2, brand: 'Fanta', servingSize: 350),
  _liquid('Fanta Uva', kcal: 46, carbs: 11.5, sugars: 11.5, brand: 'Fanta', servingSize: 350),
  _liquid('Fanta Zero Laranja', kcal: 0, carbs: 0, brand: 'Fanta', servingSize: 350),
  _liquid('Sprite', kcal: 40, carbs: 10.0, sugars: 10.0, brand: 'Sprite', servingSize: 350),
  _liquid('Sprite Zero', kcal: 0, carbs: 0, brand: 'Sprite', servingSize: 350),
  _liquid('Soda Antárctica', kcal: 0, carbs: 0, brand: 'Antarctica', servingSize: 350),
  _liquid('Refrigerante de limão', kcal: 41, carbs: 10.2, sugars: 10.2, servingSize: 350),
  _liquid('Refrigerante de guaraná', kcal: 45, carbs: 11.4, sugars: 11.4, servingSize: 350),

  // Águas
  _liquid('Água mineral', kcal: 0, carbs: 0, servingSize: 500),
  _liquid('Água com gás', kcal: 0, carbs: 0, servingSize: 500),
  _liquid('Água de coco natural', kcal: 19, carbs: 4.0, sugars: 2.6, servingSize: 300),
  _liquid('Água de coco industrializada', kcal: 25, carbs: 5.8, sugars: 4.5, servingSize: 300),

  // Sucos e néctares
  _liquid('Suco de laranja de caixa', kcal: 45, carbs: 10.4, sugars: 9.0, servingSize: 200),
  _liquid('Néctar de pêssego', kcal: 55, carbs: 13.5, sugars: 12.0, servingSize: 200),
  _liquid('Néctar de manga', kcal: 58, carbs: 14.0, sugars: 12.5, servingSize: 200),
  _liquid('Néctar de goiaba', kcal: 56, carbs: 13.8, sugars: 12.2, servingSize: 200),
  _liquid('Suco de caju', kcal: 49, carbs: 11.8, sugars: 10.5, servingSize: 200),
  _liquid('Suco de abacaxi de caixa', kcal: 50, carbs: 12.2, sugars: 11.0, servingSize: 200),
  _liquid('Refresco de frutas', kcal: 30, carbs: 7.5, sugars: 7.0, servingSize: 200),

  // Energéticos e isotônicos
  _liquid('Bebida energética Red Bull', kcal: 45, carbs: 11.0, sugars: 10.5, brand: 'Red Bull', servingSize: 250),
  _liquid('Bebida energética Monster', kcal: 45, carbs: 11.0, sugars: 10.5, brand: 'Monster', servingSize: 473),
  _liquid('Bebida energética sem açúcar', kcal: 2, carbs: 0.3, servingSize: 250),
  _liquid('Isotônico Gatorade', kcal: 25, carbs: 6.0, sugars: 5.5, brand: 'Gatorade', servingSize: 500),
  _liquid('Isotônico Powerade', kcal: 25, carbs: 6.0, sugars: 5.5, brand: 'Powerade', servingSize: 500),

  // Leites e bebidas vegetais líquidas
  _liquid('Leite integral (ml)', kcal: 61, carbs: 4.8, sugars: 4.8, protein: 3.2, fat: 3.3, servingSize: 200),
  _liquid('Leite semidesnatado (ml)', kcal: 46, carbs: 4.8, sugars: 4.8, protein: 3.2, fat: 1.5, servingSize: 200),
  _liquid('Leite desnatado (ml)', kcal: 34, carbs: 5.0, sugars: 5.0, protein: 3.4, fat: 0.2, servingSize: 200),
  _liquid('Bebida de soja adoçada', kcal: 45, carbs: 6.5, sugars: 5.5, protein: 2.8, fat: 1.5, servingSize: 200),
  _liquid('Bebida de aveia adoçada', kcal: 52, carbs: 9.0, sugars: 5.0, protein: 1.0, fat: 1.5, servingSize: 200),
];
