/// Dados usados tanto pelas metas quanto pelo cálculo de dobras cutâneas.
class UserProfile {
  final String name;
  final String sex; // 'male' | 'female'
  final int age;
  /// Peso atual informado pelo usuário.
  final double weightKg;

  /// Peso que o usuário quer alcançar.
  final double targetWeightKg;

  final double heightCm;
  final double activityFactor;
  final double goalKcal;
  final double goalProtein;
  final double goalCarbs;
  final double goalFat;

  /// Percentual de gordura informado ou preenchido pela aba de dobras.
  final double bodyFatPercent;

  /// Meta diária de água em mililitros.
  final double waterGoalMl;

  /// Preferência de tema. `true` = escuro.
  final bool darkMode;

  const UserProfile({
    this.name = 'Usuário',
    this.sex = 'male',
    this.age = 30,
    this.weightKg = 70,
    this.targetWeightKg = 70,
    this.heightCm = 170,
    this.activityFactor = 1.375,
    this.goalKcal = 2000,
    this.goalProtein = 120,
    this.goalCarbs = 250,
    this.goalFat = 65,
    this.bodyFatPercent = 0,
    this.waterGoalMl = 2000,
    this.darkMode = false,
  });

  /// Mifflin-St Jeor + fator de atividade. Usado como sugestão de meta.
  double get suggestedKcal {
    final base = 10 * weightKg + 6.25 * heightCm - 5 * age;
    final bmr = sex == 'female' ? base - 161 : base + 5;
    return bmr * activityFactor;
  }

  UserProfile copyWith({
    String? name,
    String? sex,
    int? age,
    double? weightKg,
    double? targetWeightKg,
    double? heightCm,
    double? activityFactor,
    double? goalKcal,
    double? goalProtein,
    double? goalCarbs,
    double? goalFat,
    double? bodyFatPercent,
    double? waterGoalMl,
    bool? darkMode,
  }) {
    return UserProfile(
      name: name ?? this.name,
      sex: sex ?? this.sex,
      age: age ?? this.age,
      weightKg: weightKg ?? this.weightKg,
      targetWeightKg: targetWeightKg ?? this.targetWeightKg,
      heightCm: heightCm ?? this.heightCm,
      activityFactor: activityFactor ?? this.activityFactor,
      goalKcal: goalKcal ?? this.goalKcal,
      goalProtein: goalProtein ?? this.goalProtein,
      goalCarbs: goalCarbs ?? this.goalCarbs,
      goalFat: goalFat ?? this.goalFat,
      bodyFatPercent: bodyFatPercent ?? this.bodyFatPercent,
      waterGoalMl: waterGoalMl ?? this.waterGoalMl,
      darkMode: darkMode ?? this.darkMode,
    );
  }

  Map<String, dynamic> toJson() => {
        'name': name,
        'sex': sex,
        'age': age,
        'weightKg': weightKg,
        'targetWeightKg': targetWeightKg,
        'heightCm': heightCm,
        'activityFactor': activityFactor,
        'goalKcal': goalKcal,
        'goalProtein': goalProtein,
        'goalCarbs': goalCarbs,
        'goalFat': goalFat,
        'bodyFatPercent': bodyFatPercent,
        'waterGoalMl': waterGoalMl,
        'darkMode': darkMode,
      };

  factory UserProfile.fromJson(Map<String, dynamic> json) => UserProfile(
        name: json['name'] as String? ?? 'Usuário',
        sex: json['sex'] as String? ?? 'male',
        age: (json['age'] as num?)?.toInt() ?? 30,
        weightKg: (json['weightKg'] as num?)?.toDouble() ?? 70,
        targetWeightKg: (json['targetWeightKg'] as num?)?.toDouble() ?? 70,
        heightCm: (json['heightCm'] as num?)?.toDouble() ?? 170,
        activityFactor: (json['activityFactor'] as num?)?.toDouble() ?? 1.375,
        goalKcal: (json['goalKcal'] as num?)?.toDouble() ?? 2000,
        goalProtein: (json['goalProtein'] as num?)?.toDouble() ?? 120,
        goalCarbs: (json['goalCarbs'] as num?)?.toDouble() ?? 250,
        goalFat: (json['goalFat'] as num?)?.toDouble() ?? 65,
        bodyFatPercent: (json['bodyFatPercent'] as num?)?.toDouble() ?? 0,
        waterGoalMl: (json['waterGoalMl'] as num?)?.toDouble() ?? 2000,
        darkMode: json['darkMode'] as bool? ?? false,
      );
}
