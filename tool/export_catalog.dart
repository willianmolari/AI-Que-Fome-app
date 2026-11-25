// Exporta o catálogo local para o JSON público usado pelo app.
// Uso: dart run tool/export_catalog.dart [caminho]
// Padrão: .food_catalog.json (raiz do repositório).
import 'dart:convert';
import 'dart:io';

import 'package:nutridobra/data/food_catalog.dart';

void main(List<String> args) {
  final payload = <String, dynamic>{
    'version': 1,
    'foods': FoodCatalog.all.map((food) => food.toJson()).toList(),
  };
  final path = args.isEmpty ? '.food_catalog.json' : args.first;
  final json = JsonEncoder.withIndent('  ').convert(payload);
  File(path).writeAsStringSync('$json\n');
  stdout.writeln('${FoodCatalog.all.length} alimentos exportados para $path');
}
