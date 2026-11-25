/// Refeição adicional criada pelo usuário.
///
/// As refeições padrão (café, almoço, jantar e lanches) continuam fixas.
/// Estes slots só aparecem no diário depois de nomeados e ativados.
class CustomMeal {
  final String key;
  final String name;
  final bool enabled;

  const CustomMeal({
    required this.key,
    required this.name,
    required this.enabled,
  });

  CustomMeal copyWith({String? name, bool? enabled}) => CustomMeal(
    key: key,
    name: name ?? this.name,
    enabled: enabled ?? this.enabled,
  );

  bool get isAvailable => enabled && name.trim().isNotEmpty;

  Map<String, dynamic> toJson() => {
    'key': key,
    'name': name,
    'enabled': enabled,
  };

  factory CustomMeal.fromJson(Map<String, dynamic> json) => CustomMeal(
    key: json['key'] as String? ?? '',
    name: json['name'] as String? ?? '',
    enabled: json['enabled'] as bool? ?? false,
  );
}
