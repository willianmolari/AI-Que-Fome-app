/// Uma porção de alimento registrada em um dia e refeição.
class DiaryEntry {
  final String id;
  final String date; // yyyy-MM-dd
  final String meal; // cafe, almoco, jantar, lanches
  final int fdcId;
  final String foodName;
  /// Quantidade da porção. Para líquidos, representa ml em vez de gramas.
  final double grams;

  /// Unidade da quantidade: `g` ou `ml`.
  final String unit;
  final double kcal;
  final double protein;
  final double carbs;
  final double fat;
  final DateTime createdAt;

  const DiaryEntry({
    required this.id,
    required this.date,
    required this.meal,
    required this.fdcId,
    required this.foodName,
    required this.grams,
    this.unit = 'g',
    required this.kcal,
    required this.protein,
    required this.carbs,
    required this.fat,
    required this.createdAt,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'date': date,
        'meal': meal,
        'fdcId': fdcId,
        'foodName': foodName,
        'grams': grams,
        'unit': unit,
        'kcal': kcal,
        'protein': protein,
        'carbs': carbs,
        'fat': fat,
        'createdAt': createdAt.toIso8601String(),
      };

  factory DiaryEntry.fromJson(Map<String, dynamic> json) => DiaryEntry(
        id: json['id'] as String,
        date: json['date'] as String,
        meal: json['meal'] as String,
        fdcId: (json['fdcId'] as num).toInt(),
        foodName: json['foodName'] as String? ?? '',
        grams: (json['grams'] as num?)?.toDouble() ?? 0,
        unit: json['unit'] as String? ?? 'g',
        kcal: (json['kcal'] as num?)?.toDouble() ?? 0,
        protein: (json['protein'] as num?)?.toDouble() ?? 0,
        carbs: (json['carbs'] as num?)?.toDouble() ?? 0,
        fat: (json['fat'] as num?)?.toDouble() ?? 0,
        createdAt: DateTime.tryParse(json['createdAt'] as String? ?? '') ??
            DateTime.now(),
      );
}
