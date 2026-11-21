/// Uma medição de peso registrada pelo usuário.
class WeightRecord {
  final String id;
  final DateTime date;
  final double weightKg;

  const WeightRecord({
    required this.id,
    required this.date,
    required this.weightKg,
  });

  factory WeightRecord.create({
    required DateTime date,
    required double weightKg,
  }) {
    final day = DateTime(date.year, date.month, date.day);
    return WeightRecord(
      id: '${day.year}-${day.month.toString().padLeft(2, '0')}-'
          '${day.day.toString().padLeft(2, '0')}',
      date: day,
      weightKg: weightKg,
    );
  }

  String get dateKey =>
      '${date.year.toString().padLeft(4, '0')}-'
      '${date.month.toString().padLeft(2, '0')}-'
      '${date.day.toString().padLeft(2, '0')}';

  Map<String, dynamic> toJson() => {
        'id': id,
        'date': date.toIso8601String(),
        'weightKg': weightKg,
      };

  factory WeightRecord.fromJson(Map<String, dynamic> json) => WeightRecord(
        id: json['id'] as String? ?? '',
        date: DateTime.tryParse(json['date'] as String? ?? '') ??
            DateTime.fromMillisecondsSinceEpoch(0),
        weightKg: (json['weightKg'] as num?)?.toDouble() ?? 0,
      );
}
