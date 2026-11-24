import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Dados editáveis de uma porção, usados tanto no buscador quanto no diário.
class PortionData {
  final String name;
  final double amount;
  final String unit;
  final double kcal;
  final double protein;
  final double carbs;
  final double fat;

  const PortionData({
    required this.name,
    required this.amount,
    this.unit = 'g',
    required this.kcal,
    required this.protein,
    required this.carbs,
    required this.fat,
  });

  PortionData copyWith({
    String? name,
    double? amount,
    String? unit,
    double? kcal,
    double? protein,
    double? carbs,
    double? fat,
  }) {
    return PortionData(
      name: name ?? this.name,
      amount: amount ?? this.amount,
      unit: unit ?? this.unit,
      kcal: kcal ?? this.kcal,
      protein: protein ?? this.protein,
      carbs: carbs ?? this.carbs,
      fat: fat ?? this.fat,
    );
  }

  /// Reescala os macros proporcionalmente à nova quantidade.
  PortionData scaledTo(double newAmount) {
    if (amount <= 0) return copyWith(amount: newAmount);
    final ratio = newAmount / amount;
    return PortionData(
      name: name,
      amount: newAmount,
      unit: unit,
      kcal: kcal * ratio,
      protein: protein * ratio,
      carbs: carbs * ratio,
      fat: fat * ratio,
    );
  }
}

/// Dialog reutilizável para editar nome, quantidade e valores nutricionais.
Future<PortionData?> showPortionEditor(
  BuildContext context,
  PortionData initial, {
  String title = 'Editar porção',
}) {
  final name = TextEditingController(text: initial.name);
  final amount = TextEditingController(
    text: initial.amount.toStringAsFixed(0),
  );
  final kcal = TextEditingController(text: initial.kcal.toStringAsFixed(0));
  final protein = TextEditingController(
    text: initial.protein.toStringAsFixed(1),
  );
  final carbs = TextEditingController(text: initial.carbs.toStringAsFixed(1));
  final fat = TextEditingController(text: initial.fat.toStringAsFixed(1));
  var unit = initial.unit;

  double parse(TextEditingController c) =>
      double.tryParse(c.text.replaceAll(',', '.')) ?? 0;

  void rescaleFromInitial() {
    final value = parse(amount);
    if (value <= 0) return;
    final scaled = initial.scaledTo(value);
    kcal.text = scaled.kcal.toStringAsFixed(0);
    protein.text = scaled.protein.toStringAsFixed(1);
    carbs.text = scaled.carbs.toStringAsFixed(1);
    fat.text = scaled.fat.toStringAsFixed(1);
  }

  return showDialog<PortionData>(
    context: context,
    builder: (dialogContext) => StatefulBuilder(
      builder: (context, setState) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.tune_outlined),
            const SizedBox(width: 10),
            Expanded(child: Text(title)),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(
                controller: name,
                textCapitalization: TextCapitalization.words,
                decoration: const InputDecoration(labelText: 'Nome'),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: amount,
                      keyboardType: TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      onChanged: (_) => rescaleFromInitial(),
                      decoration: const InputDecoration(
                        labelText: 'Quantidade',
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  DropdownButton<String>(
                    value: unit,
                    onChanged: (value) =>
                        setState(() => unit = value ?? 'g'),
                    items: const [
                      DropdownMenuItem(value: 'g', child: Text('g')),
                      DropdownMenuItem(value: 'ml', child: Text('ml')),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                'Valores para a quantidade informada:',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: muted(context),
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: kcal,
                      keyboardType: TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      decoration: const InputDecoration(
                        labelText: 'Calorias',
                        suffixText: 'kcal',
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TextField(
                      controller: protein,
                      keyboardType: TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      decoration: const InputDecoration(
                        labelText: 'Proteína',
                        suffixText: 'g',
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: carbs,
                      keyboardType: TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      decoration: const InputDecoration(
                        labelText: 'Carboidrato',
                        suffixText: 'g',
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TextField(
                      controller: fat,
                      keyboardType: TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      decoration: const InputDecoration(
                        labelText: 'Gordura',
                        suffixText: 'g',
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () {
              final value = parse(amount);
              if (value <= 0 || name.text.trim().isEmpty) return;
              Navigator.pop(
                dialogContext,
                PortionData(
                  name: name.text.trim(),
                  amount: value,
                  unit: unit,
                  kcal: parse(kcal),
                  protein: parse(protein),
                  carbs: parse(carbs),
                  fat: parse(fat),
                ),
              );
            },
            child: const Text('Salvar'),
          ),
        ],
      ),
    ),
  );
}
