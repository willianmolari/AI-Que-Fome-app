import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nutridobra/data/food_catalog.dart';
import 'package:nutridobra/models/diary_entry.dart';
import 'package:nutridobra/screens/diary_screen.dart';
import 'package:nutridobra/services/storage_service.dart';
import 'package:nutridobra/state/app_state.dart';
import 'package:nutridobra/widgets/portion_editor.dart';
import 'package:shared_preferences/shared_preferences.dart';

DiaryEntry _entry({
  required String id,
  required String date,
  required String meal,
  String name = 'Alimento',
}) {
  return DiaryEntry(
    id: id,
    date: date,
    meal: meal,
    fdcId: -1,
    foodName: name,
    grams: 100,
    unit: 'g',
    kcal: 100,
    protein: 10,
    carbs: 10,
    fat: 2,
    createdAt: DateTime(2026, 11, 20),
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() => SharedPreferences.setMockInitialValues({}));

  group('v1.2 - catálogo ampliado', () {
    test('inclui filé de sasami e outras carnes', () {
      final sasami = FoodCatalog.search('sasami');
      expect(sasami, isNotEmpty);
      expect(
        sasami.any((f) => f.name.toLowerCase().contains('filé de sasami')),
        isTrue,
      );

      for (final term in ['contrafilé', 'picanha', 'tilápia', 'linguiça']) {
        expect(FoodCatalog.search(term), isNotEmpty, reason: term);
      }
    });

    test('catálogo local tem mais de 600 itens', () {
      expect(FoodCatalog.all.length, greaterThan(600));
    });

    test('auditoria inclui pratos, doces, bebidas e molhos que faltavam', () {
      for (final term in [
        'strogonoff de carne',
        'bobó de camarão',
        'bolo de fubá',
        'caipirinha',
        'molho de soja',
      ]) {
        expect(FoodCatalog.search(term), isNotEmpty, reason: term);
      }
    });
  });

  group('v1.2 - edição de porção', () {
    test('PortionData escala macros proporcionalmente', () {
      const original = PortionData(
        name: 'Arroz',
        amount: 100,
        kcal: 130,
        protein: 2.5,
        carbs: 28,
        fat: 0.4,
      );

      final doubled = original.scaledTo(200);
      expect(doubled.amount, 200);
      expect(doubled.kcal, 260);
      expect(doubled.protein, 2.5 * 2);
      expect(doubled.carbs, 56);
      expect(doubled.fat, 0.8);
    });

    test('DiaryEntry.copyWith preserva os demais campos', () {
      final entry = _entry(id: '1', date: '2026-11-21', meal: 'almoco');
      final updated = entry.copyWith(grams: 150, kcal: 150);

      final json = jsonDecode(jsonEncode(updated.toJson())) as Map<String, dynamic>;
      final restored = DiaryEntry.fromJson(json);
      expect(restored.id, '1');
      expect(restored.date, '2026-11-21');
      expect(restored.meal, 'almoco');
      expect(restored.grams, 150);
      expect(restored.kcal, 150);
      expect(restored.protein, 10);
      expect(restored.unit, 'g');
    });

    test('AppState atualiza uma porção já salva', () async {
      final state = AppState(await StorageService.create());
      await state.load();
      final entry = _entry(id: 'a', date: '2026-11-21', meal: 'almoco');
      await state.addEntry(entry);

      await state.updateEntry(entry.copyWith(grams: 250, kcal: 250));

      expect(state.entries.single.grams, 250);
      expect(state.entries.single.kcal, 250);
    });

    testWidgets('toque no alimento da refeição abre a edição', (tester) async {
      final state = AppState(await StorageService.create());
      await state.load();
      final date = DateTime(2026, 11, 21);
      await state.addEntry(
        _entry(
          id: 'a',
          date: '2026-11-21',
          meal: 'almoco',
          name: 'Filé de sasami',
        ),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DiaryScreen(
              state: state,
              date: date,
              onDateChanged: (_) {},
              onAddFood: (_) {},
            ),
          ),
        ),
      );
      await tester.pump();
      await tester.scrollUntilVisible(
        find.text('Filé de sasami'),
        400,
        scrollable: find.byType(Scrollable).last,
      );
      await tester.tap(find.text('Filé de sasami'));
      await tester.pumpAndSettle();

      expect(find.text('Editar alimento'), findsOneWidget);
      expect(find.text('Quantidade'), findsOneWidget);
    });
  });

  group('v1.2 - múltiplos alimentos e cópia', () {
    test('AppState adiciona vários alimentos de uma vez', () async {
      final state = AppState(await StorageService.create());
      await state.load();

      await state.addEntries([
        _entry(id: '1', date: '2026-11-21', meal: 'almoco', name: 'Arroz'),
        _entry(id: '2', date: '2026-11-21', meal: 'almoco', name: 'Feijão'),
      ]);

      expect(state.entriesFor('2026-11-21'), hasLength(2));
      expect(
        state.entriesFor('2026-11-21').map((e) => e.foodName),
        containsAll(['Arroz', 'Feijão']),
      );
    });

    test('copia refeição do dia anterior para outra refeição', () async {
      final state = AppState(await StorageService.create());
      await state.load();
      await state.addEntries([
        _entry(id: '1', date: '2026-11-20', meal: 'almoco', name: 'Arroz'),
        _entry(id: '2', date: '2026-11-20', meal: 'almoco', name: 'Feijão'),
      ]);

      final count = await state.copyMeal(
        fromDate: '2026-11-20',
        fromMeal: 'almoco',
        toDate: '2026-11-21',
        toMeal: 'jantar',
      );

      expect(count, 2);
      final copied = state.entriesFor('2026-11-21');
      expect(copied, hasLength(2));
      expect(copied.every((e) => e.meal == 'jantar'), isTrue);
      expect(copied.every((e) => e.id != '1' && e.id != '2'), isTrue);
      expect(state.entriesFor('2026-11-20'), hasLength(2));
    });

    test('cópia com substituição troca os itens existentes', () async {
      final state = AppState(await StorageService.create());
      await state.load();
      await state.addEntries([
        _entry(id: 'old', date: '2026-11-21', meal: 'jantar', name: 'Antigo'),
        _entry(id: 'src', date: '2026-11-20', meal: 'almoco', name: 'Novo'),
      ]);

      await state.copyMeal(
        fromDate: '2026-11-20',
        fromMeal: 'almoco',
        toDate: '2026-11-21',
        toMeal: 'jantar',
        replace: true,
      );

      final target = state.entriesFor('2026-11-21');
      expect(target, hasLength(1));
      expect(target.single.foodName, 'Novo');
    });

    test('cópia de refeição vazia não altera o diário', () async {
      final state = AppState(await StorageService.create());
      await state.load();
      final count = await state.copyMeal(
        fromDate: '2026-11-20',
        fromMeal: 'cafe',
        toDate: '2026-11-21',
        toMeal: 'almoco',
      );
      expect(count, 0);
      expect(state.entries, isEmpty);
    });
  });
}
