/// Circunferências corporais medidas com fita, no estilo ISAK.
///
/// Os valores são centímetros e ficam no histórico local, da mesma forma que
/// as avaliações de dobras Jackson & Pollock.
class BodyMeasureRecord {
  final String id;
  final DateTime createdAt;
  final Map<String, double> values;
  final String notes;

  const BodyMeasureRecord({
    required this.id,
    required this.createdAt,
    required this.values,
    this.notes = '',
  });

  factory BodyMeasureRecord.create({
    required Map<String, double> values,
    String notes = '',
    DateTime? createdAt,
  }) {
    final now = createdAt ?? DateTime.now();
    return BodyMeasureRecord(
      id: '${now.microsecondsSinceEpoch}',
      createdAt: now,
      values: Map.unmodifiable(values),
      notes: notes.trim(),
    );
  }

  BodyMeasureRecord copyWith({String? notes}) => BodyMeasureRecord(
    id: id,
    createdAt: createdAt,
    values: values,
    notes: notes ?? this.notes,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'createdAt': createdAt.toIso8601String(),
    'values': values,
    'notes': notes,
  };

  factory BodyMeasureRecord.fromJson(Map<String, dynamic> json) {
    final raw = json['values'] as Map<String, dynamic>? ?? const {};
    return BodyMeasureRecord(
      id: json['id'] as String? ?? '',
      createdAt:
          DateTime.tryParse(json['createdAt'] as String? ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(0),
      values: raw.map((key, value) => MapEntry(key, (value as num).toDouble())),
      notes: json['notes'] as String? ?? '',
    );
  }
}

/// Sítios de circunferência usados pelo app (rótulos em português).
const bodyMeasureSites = <(String, String)>[
  ('neck', 'Pescoço'),
  ('chest', 'Peito'),
  ('abdomen', 'Abdômen'),
  ('hip', 'Quadril'),
  ('thighLeftFlexed', 'Coxa esq. flexionada'),
  ('thighLeftRelaxed', 'Coxa esq. relaxada'),
  ('thighRightFlexed', 'Coxa dir. flexionada'),
  ('thighRightRelaxed', 'Coxa dir. relaxada'),
  ('armLeftFlexed', 'Braço esq. flexionado'),
  ('armLeftRelaxed', 'Braço esq. relaxado'),
  ('armRightFlexed', 'Braço dir. flexionado'),
  ('armRightRelaxed', 'Braço dir. relaxado'),
];

String bodyMeasureLabel(String key) {
  for (final site in bodyMeasureSites) {
    if (site.$1 == key) return site.$2;
  }
  return key;
}

String formatMeasureDate(DateTime date) {
  const months = [
    'jan',
    'fev',
    'mar',
    'abr',
    'mai',
    'jun',
    'jul',
    'ago',
    'set',
    'out',
    'nov',
    'dez',
  ];
  return '${date.day.toString().padLeft(2, '0')} ${months[date.month - 1]} ${date.year}';
}
