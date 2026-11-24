/// Alimentos brasileiros adicionais, com valores nutricionais médios por 100 g.
///
/// Tabela própria, inspirada em tabelas públicas de composição de alimentos.
/// Nenhum dado proprietário é reutilizado.
library;

import '../models/food_item.dart';

int _extraFoodId = -11000;

FoodItem _food(
  String name, {
  required double kcal,
  required double protein,
  required double carbs,
  required double fat,
  double fiber = 0,
  double sugars = 0,
  double servingSize = 100,
  required String category,
}) {
  return FoodItem(
    fdcId: _extraFoodId--,
    name: name,
    dataType: 'Catálogo local',
    servingSize: servingSize,
    servingUnit: 'g',
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

final List<FoodItem> extraFoods = <FoodItem>[
  // Aves
  _food('Filé de sasami', kcal: 105, protein: 23.5, carbs: 0, fat: 0.7, category: 'Carnes'),
  _food('Filé de frango', kcal: 165, protein: 31.0, carbs: 0, fat: 3.6, category: 'Carnes'),
  _food('Coxa de frango (sem osso)', kcal: 177, protein: 25.0, carbs: 0, fat: 8.0, category: 'Carnes'),
  _food('Sobrecoxa de frango', kcal: 185, protein: 24.0, carbs: 0, fat: 9.5, category: 'Carnes'),
  _food('Asa de frango', kcal: 203, protein: 23.0, carbs: 0, fat: 12.0, category: 'Carnes'),
  _food('Frango assado com pele', kcal: 230, protein: 24.0, carbs: 0, fat: 14.0, category: 'Carnes'),
  _food('Moela de frango cozida', kcal: 120, protein: 21.0, carbs: 0, fat: 3.0, category: 'Carnes'),
  _food('Coração de galinha cozido', kcal: 153, protein: 16.0, carbs: 0.5, fat: 9.0, category: 'Carnes'),
  _food('Peito de peru', kcal: 135, protein: 24.0, carbs: 1.0, fat: 3.5, category: 'Carnes'),

  // Carne bovina
  _food('Carne moída bovina magra', kcal: 170, protein: 26.0, carbs: 0, fat: 7.0, category: 'Carnes'),
  _food('Carne moída bovina gorda', kcal: 250, protein: 22.0, carbs: 0, fat: 17.0, category: 'Carnes'),
  _food('Contrafilé', kcal: 217, protein: 26.0, carbs: 0, fat: 12.0, category: 'Carnes'),
  _food('Alcatra', kcal: 190, protein: 27.0, carbs: 0, fat: 9.0, category: 'Carnes'),
  _food('Picanha', kcal: 290, protein: 25.0, carbs: 0, fat: 20.0, category: 'Carnes'),
  _food('Cupim', kcal: 280, protein: 24.0, carbs: 0, fat: 19.0, category: 'Carnes'),
  _food('Costela bovina', kcal: 330, protein: 22.0, carbs: 0, fat: 26.0, category: 'Carnes'),
  _food('Acém', kcal: 190, protein: 27.0, carbs: 0, fat: 9.0, category: 'Carnes'),
  _food('Paleta bovina', kcal: 220, protein: 25.0, carbs: 0, fat: 13.0, category: 'Carnes'),
  _food('Maminha', kcal: 200, protein: 26.0, carbs: 0, fat: 11.0, category: 'Carnes'),
  _food('Fraldinha', kcal: 210, protein: 25.0, carbs: 0, fat: 12.0, category: 'Carnes'),
  _food('Chuletão', kcal: 240, protein: 24.0, carbs: 0, fat: 15.0, category: 'Carnes'),
  _food('Bife de fígado', kcal: 135, protein: 20.0, carbs: 3.0, fat: 4.5, category: 'Carnes'),
  _food('Carne seca dessalgada cozida', kcal: 210, protein: 28.0, carbs: 0, fat: 10.0, category: 'Carnes'),

  // Embutidos e carnes processadas
  _food('Linguiça calabresa', kcal: 320, protein: 16.0, carbs: 1.5, fat: 27.0, category: 'Carnes'),
  _food('Linguiça toscana', kcal: 305, protein: 17.0, carbs: 1.5, fat: 25.0, category: 'Carnes'),
  _food('Salsicha', kcal: 290, protein: 13.0, carbs: 3.0, fat: 25.0, category: 'Carnes'),
  _food('Hambúrguer de carne bovina', kcal: 250, protein: 22.0, carbs: 0, fat: 18.0, category: 'Carnes'),
  _food('Bacon', kcal: 540, protein: 30.0, carbs: 1.0, fat: 45.0, category: 'Carnes'),
  _food('Presunto', kcal: 145, protein: 18.0, carbs: 2.0, fat: 7.0, category: 'Carnes'),
  _food('Presunto de parma', kcal: 240, protein: 28.0, carbs: 0.5, fat: 13.0, category: 'Carnes'),

  // Carne suína
  _food('Costeleta de porco', kcal: 240, protein: 25.0, carbs: 0, fat: 15.0, category: 'Carnes'),
  _food('Lombo de porco', kcal: 215, protein: 27.0, carbs: 0, fat: 11.0, category: 'Carnes'),
  _food('Pernil de porco', kcal: 240, protein: 25.0, carbs: 0, fat: 15.0, category: 'Carnes'),
  _food('Carré de porco', kcal: 270, protein: 23.0, carbs: 0, fat: 19.0, category: 'Carnes'),
  _food('Costelinha de porco', kcal: 320, protein: 21.0, carbs: 0, fat: 25.0, category: 'Carnes'),
  _food('Toucinho', kcal: 700, protein: 5.0, carbs: 0, fat: 78.0, category: 'Carnes'),

  // Peixes e frutos do mar
  _food('Tilápia filé', kcal: 129, protein: 26.0, carbs: 0, fat: 2.7, category: 'Carnes'),
  _food('Salmão filé', kcal: 208, protein: 22.0, carbs: 0, fat: 13.0, category: 'Carnes'),
  _food('Atum em lata (drenado)', kcal: 132, protein: 28.0, carbs: 0, fat: 1.2, category: 'Carnes'),
  _food('Sardinha em lata (drenado)', kcal: 208, protein: 24.0, carbs: 0, fat: 12.0, category: 'Carnes'),
  _food('Camarão cozido', kcal: 99, protein: 24.0, carbs: 0.2, fat: 0.3, category: 'Carnes'),
  _food('Lula cozida', kcal: 92, protein: 16.0, carbs: 3.0, fat: 1.0, category: 'Carnes'),
  _food('Polvo cozido', kcal: 82, protein: 15.0, carbs: 2.0, fat: 1.0, category: 'Carnes'),
  _food('Caranguejo cozido', kcal: 87, protein: 18.0, carbs: 0, fat: 1.0, category: 'Carnes'),
  _food('Lagosta cozida', kcal: 90, protein: 19.0, carbs: 0, fat: 0.8, category: 'Carnes'),
  _food('Bacalhau dessalgado cozido', kcal: 105, protein: 24.0, carbs: 0, fat: 0.8, category: 'Carnes'),
  _food('Merluza filé cozida', kcal: 100, protein: 22.0, carbs: 0, fat: 1.0, category: 'Carnes'),
  _food('Dourado filé grelhado', kcal: 125, protein: 25.0, carbs: 0, fat: 2.5, category: 'Carnes'),

  // Ovos
  _food('Ovo de galinha (unidade ~50 g, use servingSize 50)', kcal: 155, protein: 12.6, carbs: 1.1, fat: 10.6, servingSize: 50, category: 'Carnes'),
  _food('Ovo caipira', kcal: 155, protein: 12.6, carbs: 1.1, fat: 10.6, servingSize: 50, category: 'Carnes'),
  _food('Ovo cru', kcal: 143, protein: 12.6, carbs: 0.7, fat: 9.5, servingSize: 50, category: 'Carnes'),

  // Queijos e iogurtes
  _food('Queijo gorgonzola', kcal: 353, protein: 21.0, carbs: 2.0, fat: 29.0, category: 'Laticínios'),
  _food('Queijo brie', kcal: 334, protein: 20.0, carbs: 2.0, fat: 27.0, category: 'Laticínios'),
  _food('Queijo gouda', kcal: 356, protein: 25.0, carbs: 2.0, fat: 27.0, category: 'Laticínios'),
  _food('Queijo provolone', kcal: 363, protein: 25.0, carbs: 1.5, fat: 28.0, category: 'Laticínios'),
  _food('Queijo catupiry', kcal: 320, protein: 6.0, carbs: 4.0, fat: 31.0, category: 'Laticínios'),
  _food('Queijo minas meia cura', kcal: 330, protein: 22.0, carbs: 2.0, fat: 25.0, category: 'Laticínios'),
  _food('Queijo de cabra', kcal: 364, protein: 21.0, carbs: 2.0, fat: 30.0, category: 'Laticínios'),
  _food('Iogurte grego com frutas', kcal: 110, protein: 7.0, carbs: 15.0, fat: 2.5, sugars: 13.0, category: 'Laticínios'),
  _food('Iogurte infantil', kcal: 75, protein: 3.0, carbs: 12.0, fat: 2.5, sugars: 11.0, category: 'Laticínios'),
  _food('Iogurte dietético', kcal: 45, protein: 3.5, carbs: 5.0, fat: 0.5, sugars: 4.0, category: 'Laticínios'),
  _food('Petit suisse', kcal: 120, protein: 4.0, carbs: 11.0, fat: 7.0, sugars: 10.0, category: 'Laticínios'),
  _food('Manteiga ghee', kcal: 900, protein: 0, carbs: 0, fat: 100, category: 'Laticínios'),
  _food('Doce de leite dietético', kcal: 230, protein: 5.0, carbs: 40.0, fat: 5.0, sugars: 12.0, category: 'Laticínios'),

  // Gorduras, óleos e castanhas
  _food('Azeite de oliva extravirgem', kcal: 884, protein: 0, carbs: 0, fat: 100, category: 'Outros'),
  _food('Óleo de canola', kcal: 884, protein: 0, carbs: 0, fat: 100, category: 'Outros'),
  _food('Óleo de coco', kcal: 862, protein: 0, carbs: 0, fat: 100, category: 'Outros'),
  _food('Óleo de linhaça', kcal: 884, protein: 0, carbs: 0, fat: 100, category: 'Outros'),
  _food('Castanha-do-pará', kcal: 656, protein: 14.0, carbs: 10.0, fat: 66.0, fiber: 5.0, category: 'Outros'),
  _food('Castanha portuguesa', kcal: 220, protein: 4.0, carbs: 45.0, fat: 2.0, fiber: 5.0, category: 'Outros'),
  _food('Pistache', kcal: 562, protein: 20.0, carbs: 27.0, fat: 45.0, fiber: 10.0, category: 'Outros'),
  _food('Semente de abóbora', kcal: 559, protein: 30.0, carbs: 10.0, fat: 49.0, fiber: 6.0, category: 'Outros'),
  _food('Tahine', kcal: 595, protein: 17.0, carbs: 21.0, fat: 53.0, fiber: 9.0, category: 'Outros'),
  _food('Manteiga de amêndoa', kcal: 614, protein: 21.0, carbs: 19.0, fat: 55.0, fiber: 12.0, category: 'Outros'),
  _food('Hummus', kcal: 166, protein: 8.0, carbs: 14.0, fat: 10.0, fiber: 6.0, category: 'Outros'),
  _food('Maionese', kcal: 680, protein: 1.0, carbs: 1.0, fat: 75.0, category: 'Outros'),
  _food('Mostarda', kcal: 66, protein: 4.0, carbs: 5.0, fat: 3.5, category: 'Outros'),
  _food('Molho de tomate', kcal: 32, protein: 1.5, carbs: 7.0, fat: 0.4, sugars: 4.0, category: 'Outros'),
  _food('Azeitona verde', kcal: 145, protein: 1.0, carbs: 4.0, fat: 15.0, fiber: 3.0, category: 'Outros'),
  _food('Azeitona preta', kcal: 115, protein: 1.0, carbs: 6.0, fat: 11.0, fiber: 3.0, category: 'Outros'),
  _food('Picles de pepino', kcal: 12, protein: 0.5, carbs: 2.0, fat: 0.3, category: 'Outros'),

  // Grãos, cereais e farinhas
  _food('Arroz branco cru', kcal: 365, protein: 7.0, carbs: 80.0, fat: 0.6, fiber: 1.5, category: 'Grãos e cereais'),
  _food('Arroz integral cru', kcal: 370, protein: 8.0, carbs: 77.0, fat: 2.8, fiber: 4.6, category: 'Grãos e cereais'),
  _food('Feijão carioca cru', kcal: 310, protein: 22.0, carbs: 55.0, fat: 1.5, fiber: 17.0, category: 'Grãos e cereais'),
  _food('Feijão preto cru', kcal: 300, protein: 21.0, carbs: 58.0, fat: 1.3, fiber: 16.0, category: 'Grãos e cereais'),
  _food('Grão-de-bico cru', kcal: 364, protein: 19.0, carbs: 61.0, fat: 6.0, fiber: 17.0, category: 'Grãos e cereais'),
  _food('Lentilha crua', kcal: 352, protein: 25.0, carbs: 60.0, fat: 1.0, fiber: 10.0, category: 'Grãos e cereais'),
  _food('Soja em grão crua', kcal: 446, protein: 37.0, carbs: 30.0, fat: 20.0, fiber: 9.0, category: 'Grãos e cereais'),
  _food('Trigo em grão', kcal: 340, protein: 13.0, carbs: 71.0, fat: 2.0, fiber: 12.0, category: 'Grãos e cereais'),
  _food('Cevada em grão', kcal: 354, protein: 12.0, carbs: 73.0, fat: 2.0, fiber: 15.0, category: 'Grãos e cereais'),
  _food('Painço', kcal: 378, protein: 11.0, carbs: 73.0, fat: 4.0, fiber: 8.0, category: 'Grãos e cereais'),
  _food('Amido de milho', kcal: 381, protein: 0.3, carbs: 91.0, fat: 0.1, category: 'Grãos e cereais'),
  _food('Polvilho doce', kcal: 360, protein: 0.2, carbs: 88.0, fat: 0.1, category: 'Grãos e cereais'),
  _food('Polvilho azedo', kcal: 355, protein: 0.3, carbs: 87.0, fat: 0.2, category: 'Grãos e cereais'),
  _food('Farinha de arroz', kcal: 366, protein: 7.0, carbs: 80.0, fat: 0.9, fiber: 1.5, category: 'Grãos e cereais'),

  // Padaria
  _food('Pão de forma branco', kcal: 265, protein: 8.5, carbs: 49.0, fat: 3.5, fiber: 2.8, category: 'Padaria'),
  _food('Pão integral caseiro', kcal: 250, protein: 10.0, carbs: 43.0, fat: 4.0, fiber: 7.0, category: 'Padaria'),
  _food('Pão de hambúrguer', kcal: 280, protein: 9.0, carbs: 50.0, fat: 5.0, fiber: 3.0, category: 'Padaria'),
  _food('Biscoito amanteigado', kcal: 480, protein: 6.0, carbs: 60.0, fat: 25.0, sugars: 25.0, category: 'Padaria'),

  // Doces
  _food('Açúcar mascavo', kcal: 383, protein: 0, carbs: 98.0, fat: 0, sugars: 95.0, category: 'Doces'),
  _food('Açúcar cristal', kcal: 387, protein: 0, carbs: 100, fat: 0, sugars: 100, category: 'Doces'),
  _food('Cacau em pó sem açúcar', kcal: 228, protein: 20.0, carbs: 28.0, fat: 14.0, fiber: 33.0, category: 'Doces'),
  _food('Biscoito de polvilho', kcal: 400, protein: 2.0, carbs: 70.0, fat: 12.0, category: 'Doces'),
  _food('Pudim de leite', kcal: 135, protein: 3.0, carbs: 20.0, fat: 5.0, sugars: 17.0, category: 'Doces'),
  _food('Quindim', kcal: 350, protein: 6.0, carbs: 45.0, fat: 16.0, sugars: 35.0, category: 'Doces'),
  _food('Bolo de chocolate', kcal: 380, protein: 5.0, carbs: 55.0, fat: 16.0, sugars: 35.0, category: 'Doces'),

  // Frutas
  _food('Banana verde', kcal: 71, protein: 1.2, carbs: 17.0, fat: 0.2, fiber: 2.4, category: 'Frutas'),
  _food('Açaí puro sem açúcar', kcal: 75, protein: 1.0, carbs: 16.0, fat: 1.0, fiber: 3.0, category: 'Frutas'),
  _food('Caju', kcal: 44, protein: 0.9, carbs: 10.0, fat: 0.2, fiber: 1.2, sugars: 6.0, category: 'Frutas'),
  _food('Murici', kcal: 50, protein: 0.8, carbs: 12.0, fat: 0.3, fiber: 2.0, category: 'Frutas'),
  _food('Pequi', kcal: 200, protein: 3.0, carbs: 15.0, fat: 15.0, fiber: 5.0, category: 'Frutas'),
  _food('Jatobá', kcal: 100, protein: 1.5, carbs: 22.0, fat: 0.5, fiber: 3.0, category: 'Frutas'),

  // Legumes e verduras
  _food('Cenoura crua', kcal: 41, protein: 0.9, carbs: 9.6, fat: 0.2, fiber: 2.8, sugars: 4.7, category: 'Legumes e verduras'),
  _food('Beterraba crua', kcal: 43, protein: 1.6, carbs: 9.6, fat: 0.2, fiber: 2.8, sugars: 6.8, category: 'Legumes e verduras'),
  _food('Couve fresca', kcal: 44, protein: 3.6, carbs: 6.3, fat: 1.1, fiber: 2.4, category: 'Legumes e verduras'),
  _food('Mandioquinha crua', kcal: 85, protein: 1.5, carbs: 20.0, fat: 0.2, fiber: 2.0, category: 'Legumes e verduras'),
  _food('Nabo', kcal: 28, protein: 1.0, carbs: 6.0, fat: 0.1, fiber: 1.8, category: 'Legumes e verduras'),
  _food('Rabanete', kcal: 16, protein: 0.7, carbs: 3.4, fat: 0.1, fiber: 1.2, category: 'Legumes e verduras'),
  _food('Couve-de-bruxelas', kcal: 43, protein: 3.4, carbs: 9.0, fat: 0.3, fiber: 3.8, category: 'Legumes e verduras'),
  _food('Alcachofra', kcal: 47, protein: 3.3, carbs: 11.0, fat: 0.2, fiber: 5.4, category: 'Legumes e verduras'),
  _food('Aipo', kcal: 16, protein: 0.7, carbs: 4.0, fat: 0.1, fiber: 1.6, category: 'Legumes e verduras'),

  // Pratos prontos
  _food('Frango à passarinho', kcal: 280, protein: 22.0, carbs: 10.0, fat: 17.0, category: 'Pratos prontos'),
  _food('Bife à parmegiana', kcal: 260, protein: 22.0, carbs: 12.0, fat: 14.0, category: 'Pratos prontos'),
  _food('Tutu de feijão', kcal: 130, protein: 7.0, carbs: 16.0, fat: 4.0, fiber: 3.0, category: 'Pratos prontos'),
  _food('Virado à paulista', kcal: 220, protein: 12.0, carbs: 20.0, fat: 10.0, fiber: 3.0, category: 'Pratos prontos'),
];
