/// Cálculo de composição corporal por dobras cutâneas (Jackson & Pollock).
///
/// Referências:
/// - Jackson & Pollock (1978), equações generalizadas para homens.
/// - Jackson, Pollock & Ward (1980), equações generalizadas para mulheres.
/// - Siri (1956): BF% = (4.95 / densidade - 4.50) * 100.
library;

class SkinfoldSites {
  final double chest;
  final double axilla;
  final double triceps;
  final double subscapular;
  final double abdomen;
  final double suprailiac;
  final double thigh;

  const SkinfoldSites({
    required this.chest,
    required this.axilla,
    required this.triceps,
    required this.subscapular,
    required this.abdomen,
    required this.suprailiac,
    required this.thigh,
  });

  double get sum7 => chest +
      axilla +
      triceps +
      subscapular +
      abdomen +
      suprailiac +
      thigh;

  double get sum3Male => chest + abdomen + thigh;
  double get sum3Female => triceps + thigh + suprailiac;

  List<double> get values => [
        chest,
        axilla,
        triceps,
        subscapular,
        abdomen,
        suprailiac,
        thigh,
      ];

  Map<String, dynamic> toJson() => {
        'chest': chest,
        'axilla': axilla,
        'triceps': triceps,
        'subscapular': subscapular,
        'abdomen': abdomen,
        'suprailiac': suprailiac,
        'thigh': thigh,
      };

  factory SkinfoldSites.fromJson(Map<String, dynamic> json) => SkinfoldSites(
        chest: (json['chest'] as num?)?.toDouble() ?? 0,
        axilla: (json['axilla'] as num?)?.toDouble() ?? 0,
        triceps: (json['triceps'] as num?)?.toDouble() ?? 0,
        subscapular: (json['subscapular'] as num?)?.toDouble() ?? 0,
        abdomen: (json['abdomen'] as num?)?.toDouble() ?? 0,
        suprailiac: (json['suprailiac'] as num?)?.toDouble() ?? 0,
        thigh: (json['thigh'] as num?)?.toDouble() ?? 0,
      );
}

class SkinfoldResult {
  final double density;
  final double bodyFatPercent;
  final double fatMassKg;
  final double leanMassKg;
  final String sitesDescription;
  final String category;

  const SkinfoldResult({
    required this.density,
    required this.bodyFatPercent,
    required this.fatMassKg,
    required this.leanMassKg,
    required this.sitesDescription,
    required this.category,
  });

  Map<String, dynamic> toJson() => {
        'density': density,
        'bodyFatPercent': bodyFatPercent,
        'fatMassKg': fatMassKg,
        'leanMassKg': leanMassKg,
        'sitesDescription': sitesDescription,
        'category': category,
      };

  factory SkinfoldResult.fromJson(Map<String, dynamic> json) => SkinfoldResult(
        density: (json['density'] as num?)?.toDouble() ?? 0,
        bodyFatPercent: (json['bodyFatPercent'] as num?)?.toDouble() ?? 0,
        fatMassKg: (json['fatMassKg'] as num?)?.toDouble() ?? 0,
        leanMassKg: (json['leanMassKg'] as num?)?.toDouble() ?? 0,
        sitesDescription: json['sitesDescription'] as String? ?? '',
        category: json['category'] as String? ?? '',
      );
}

class SkinfoldCalculation {
  final SkinfoldResult? threeSite;
  final SkinfoldResult sevenSite;

  const SkinfoldCalculation({
    required this.threeSite,
    required this.sevenSite,
  });
}

class SkinfoldCalculator {
  SkinfoldCalculator._();

  static const List<String> siteLabels = [
    'Peito',
    'Axila (média)',
    'Tríceps',
    'Subescapular',
    'Abdome',
    'Supra-ilíaco',
    'Coxa',
  ];

  /// Todas as medidas em mm, idade em anos e peso em kg.
  static SkinfoldCalculation calculate({
    required String sex,
    required int age,
    required double weightKg,
    required SkinfoldSites sites,
  }) {
    if (age < 15 || age > 80) {
      throw ArgumentError('Idade deve estar entre 15 e 80 anos.');
    }
    if (weightKg <= 0 || weightKg > 400) {
      throw ArgumentError('Peso deve estar entre 0 e 400 kg.');
    }
    for (final value in sites.values) {
      if (value < 1 || value > 80) {
        throw ArgumentError('Cada dobra deve estar entre 1 e 80 mm.');
      }
    }

    final isMale = sex == 'male';
    final s7 = sites.sum7;
    final density7 = isMale
        ? 1.112 -
            0.00043499 * s7 +
            0.00000055 * s7 * s7 -
            0.00028826 * age
        : 1.097 -
            0.00046971 * s7 +
            0.00000056 * s7 * s7 -
            0.00012828 * age;

    final s3 = isMale ? sites.sum3Male : sites.sum3Female;
    final density3 = isMale
        ? 1.10938 -
            0.0008267 * s3 +
            0.0000016 * s3 * s3 -
            0.0002574 * age
        : 1.0994921 -
            0.0009929 * s3 +
            0.0000023 * s3 * s3 -
            0.0001392 * age;

    final seven = _buildResult(
      density: density7,
      weightKg: weightKg,
      isMale: isMale,
      sitesDescription: isMale
          ? '7 sítios: peito, axila, tríceps, subescapular, abdome, supra-ilíaco e coxa'
          : '7 sítios: peito, axila, tríceps, subescapular, abdome, supra-ilíaco e coxa',
    );

    return SkinfoldCalculation(
      threeSite: _buildResult(
        density: density3,
        weightKg: weightKg,
        isMale: isMale,
        sitesDescription: isMale
            ? '3 sítios: peito, abdome e coxa'
            : '3 sítios: tríceps, coxa e supra-ilíaco',
      ),
      sevenSite: seven,
    );
  }

  static SkinfoldResult _buildResult({
    required double density,
    required double weightKg,
    required bool isMale,
    required String sitesDescription,
  }) {
    if (density <= 0.9 || density >= 1.3) {
      throw ArgumentError(
        'As medidas geraram uma densidade fora da faixa válida '
        '(${(density).toStringAsFixed(3)} g/cm³). Revise as dobras.',
      );
    }
    final bf = (4.95 / density - 4.50) * 100;
    if (bf < 1 || bf > 70) {
      throw ArgumentError(
        'O resultado (${bf.toStringAsFixed(1)}%) ficou fora da faixa plausível. '
        'Revise as medidas e a idade.',
      );
    }
    final fatMass = weightKg * bf / 100;
    return SkinfoldResult(
      density: density,
      bodyFatPercent: bf,
      fatMassKg: fatMass,
      leanMassKg: weightKg - fatMass,
      sitesDescription: sitesDescription,
      category: _category(bf, isMale),
    );
  }

  static String _category(double bf, bool isMale) {
    if (isMale) {
      if (bf < 6) return 'Essencial';
      if (bf < 14) return 'Atlético';
      if (bf < 18) return 'Fitness';
      if (bf < 25) return 'Médio';
      return 'Elevado';
    }
    if (bf < 14) return 'Essencial';
    if (bf < 21) return 'Atlético';
    if (bf < 25) return 'Fitness';
    if (bf < 32) return 'Médio';
    return 'Elevado';
  }
}
