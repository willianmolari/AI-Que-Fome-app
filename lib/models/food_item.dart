/// Alimento normalizado a partir do USDA FoodData Central.
///
/// Os valores nutricionais são sempre armazenados por 100 g para que o mesmo
/// registro possa ser reutilizado com qualquer porção informada pelo usuário.
class FoodItem {
  final int fdcId;
  final String name;
  final String? brand;
  final String dataType;
  final double servingSize;
  final String servingUnit;
  final double kcal;
  final double protein;
  final double fat;
  final double carbs;
  final double fiber;
  final double sugars;

  /// Origem do registro: `brasil`, `taco`, `fastfood`, `suplemento`,
  /// `openfoodfacts` ou `USDA`.
  final String source;

  /// Categoria usada nos filtros do catálogo local.
  final String? category;

  const FoodItem({
    required this.fdcId,
    required this.name,
    this.brand,
    required this.dataType,
    this.servingSize = 100,
    this.servingUnit = 'g',
    required this.kcal,
    required this.protein,
    required this.fat,
    required this.carbs,
    this.fiber = 0,
    this.sugars = 0,
    this.source = 'USDA',
    this.category,
  });

  String get displayName => brand == null || brand!.trim().isEmpty
      ? name
      : '$name • $brand';

  String get sourceLabel => switch (source) {
        'brasil' => 'Brasil',
        'taco' => 'TACO',
        'fastfood' => 'Fast food',
        'suplemento' => 'Suplemento',
        'openfoodfacts' => 'Open Food Facts',
        _ => 'USDA',
      };

  /// Busca tolerante a acentos, caixa e ordem das palavras.
  bool matches(String rawQuery) {
    final query = normalizeFoodText(rawQuery);
    if (query.isEmpty) return true;
    final haystack = normalizeFoodText('$name ${brand ?? ''} ${category ?? ''}');
    if (haystack.contains(query)) return true;
    return query
        .split(RegExp(r'\s+'))
        .every((part) => haystack.contains(part));
  }

  static String normalizeFoodText(String value) {
    return value
        .toLowerCase()
        .replaceAll(RegExp(r'[àáâãäå]'), 'a')
        .replaceAll(RegExp(r'[èéêë]'), 'e')
        .replaceAll(RegExp(r'[ìíîï]'), 'i')
        .replaceAll(RegExp(r'[òóôõö]'), 'o')
        .replaceAll(RegExp(r'[ùúûü]'), 'u')
        .replaceAll(RegExp(r'[çć]'), 'c')
        .replaceAll(RegExp(r'[^a-z0-9\s]'), ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }

  double get kcalForServing => _forServing(kcal);
  double get proteinForServing => _forServing(protein);
  double get fatForServing => _forServing(fat);
  double get carbsForServing => _forServing(carbs);

  double _forServing(double value) => servingSize <= 0
      ? 0
      : value * servingSize / 100;

  double kcalFor(double grams) => kcal * grams / 100;
  double proteinFor(double grams) => protein * grams / 100;
  double fatFor(double grams) => fat * grams / 100;
  double carbsFor(double grams) => carbs * grams / 100;

  Map<String, dynamic> toJson() => {
        'fdcId': fdcId,
        'name': name,
        'brand': brand,
        'dataType': dataType,
        'servingSize': servingSize,
        'servingUnit': servingUnit,
        'kcal': kcal,
        'protein': protein,
        'fat': fat,
        'carbs': carbs,
        'fiber': fiber,
        'sugars': sugars,
        'source': source,
        'category': category,
      };

  factory FoodItem.fromJson(Map<String, dynamic> json) => FoodItem(
        fdcId: (json['fdcId'] as num).toInt(),
        name: json['name'] as String? ?? 'Alimento',
        brand: json['brand'] as String?,
        dataType: json['dataType'] as String? ?? '',
        servingSize: (json['servingSize'] as num?)?.toDouble() ?? 100,
        servingUnit: json['servingUnit'] as String? ?? 'g',
        kcal: (json['kcal'] as num?)?.toDouble() ?? 0,
        protein: (json['protein'] as num?)?.toDouble() ?? 0,
        fat: (json['fat'] as num?)?.toDouble() ?? 0,
        carbs: (json['carbs'] as num?)?.toDouble() ?? 0,
        fiber: (json['fiber'] as num?)?.toDouble() ?? 0,
        sugars: (json['sugars'] as num?)?.toDouble() ?? 0,
        source: json['source'] as String? ?? 'USDA',
        category: json['category'] as String?,
      );
}
