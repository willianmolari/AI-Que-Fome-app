import '../utils/skinfold_calculator.dart';

/// Avaliação de dobras salva no histórico local.
class SkinfoldRecord {
  final String id;
  final DateTime createdAt;
  final String sex;
  final int age;
  final double weightKg;
  final SkinfoldSites sites;
  final SkinfoldResult? threeSite;
  final SkinfoldResult sevenSite;
  final String notes;

  const SkinfoldRecord({
    required this.id,
    required this.createdAt,
    required this.sex,
    required this.age,
    required this.weightKg,
    required this.sites,
    required this.threeSite,
    required this.sevenSite,
    this.notes = '',
  });

  factory SkinfoldRecord.create({
    required String sex,
    required int age,
    required double weightKg,
    required SkinfoldSites sites,
    required SkinfoldCalculation calculation,
    String notes = '',
    DateTime? createdAt,
  }) {
    final now = createdAt ?? DateTime.now();
    return SkinfoldRecord(
      id: '${now.microsecondsSinceEpoch}',
      createdAt: now,
      sex: sex,
      age: age,
      weightKg: weightKg,
      sites: sites,
      threeSite: calculation.threeSite,
      sevenSite: calculation.sevenSite,
      notes: notes.trim(),
    );
  }

  SkinfoldRecord copyWith({String? notes}) => SkinfoldRecord(
        id: id,
        createdAt: createdAt,
        sex: sex,
        age: age,
        weightKg: weightKg,
        sites: sites,
        threeSite: threeSite,
        sevenSite: sevenSite,
        notes: notes ?? this.notes,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'createdAt': createdAt.toIso8601String(),
        'sex': sex,
        'age': age,
        'weightKg': weightKg,
        'sites': sites.toJson(),
        'threeSite': threeSite?.toJson(),
        'sevenSite': sevenSite.toJson(),
        'notes': notes,
      };

  factory SkinfoldRecord.fromJson(Map<String, dynamic> json) {
    final sites = SkinfoldSites.fromJson(
      (json['sites'] as Map<String, dynamic>? ?? const {}),
    );
    final three = json['threeSite'] as Map<String, dynamic>?;
    final seven = json['sevenSite'] as Map<String, dynamic>? ?? const {};
    return SkinfoldRecord(
      id: json['id'] as String? ?? '',
      createdAt: DateTime.tryParse(json['createdAt'] as String? ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(0),
      sex: json['sex'] as String? ?? 'male',
      age: (json['age'] as num?)?.toInt() ?? 0,
      weightKg: (json['weightKg'] as num?)?.toDouble() ?? 0,
      sites: sites,
      threeSite: three == null ? null : SkinfoldResult.fromJson(three),
      sevenSite: SkinfoldResult.fromJson(seven),
      notes: json['notes'] as String? ?? '',
    );
  }
}
