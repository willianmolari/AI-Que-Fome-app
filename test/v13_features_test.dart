import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:nutridobra/data/food_catalog.dart';
import 'package:nutridobra/models/body_measure_record.dart';
import 'package:nutridobra/models/food_item.dart';
import 'package:nutridobra/screens/diary_screen.dart';
import 'package:nutridobra/screens/skinfold_screen.dart';
import 'package:nutridobra/services/catalog_sync_service.dart';
import 'package:nutridobra/services/storage_service.dart';
import 'package:nutridobra/state/app_state.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() => SharedPreferences.setMockInitialValues({}));

  group('v1.3 - catálogo com marcas', () {
    test('catálogo local passa de mil itens', () {
      expect(FoodCatalog.all.length, greaterThan(1000));
    });

    test('inclui marcas, lanchonetes e féculas pedidas', () {
      for (final term in [
        'iogurte natural danone',
        'leite em pó ninho',
        'suco cutrale',
        'whopper',
        'demeter',
        'pelanda',
        'fécula de batata',
        'polvilho doce',
      ]) {
        expect(FoodCatalog.search(term), isNotEmpty, reason: term);
      }
    });

    test('não repete IDs nem nomes no catálogo', () {
      final ids = FoodCatalog.all.map((f) => f.fdcId).toList();
      expect(ids.toSet(), hasLength(ids.length));

      final names = FoodCatalog.all
          .map((f) => f.name.toLowerCase().trim())
          .toList();
      expect(names.toSet(), hasLength(names.length));
    });

    test('arquivo oculto do GitHub contém um catálogo válido', () {
      final file = File('.food_catalog.json');
      expect(file.existsSync(), isTrue, reason: '.food_catalog.json');

      final decoded = jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;
      final foods = decoded['foods'] as List<dynamic>;
      expect(foods.length, greaterThan(1200));

      final names = foods
          .map((e) => FoodItem.fromJson(e as Map<String, dynamic>).name)
          .toList();
      expect(names.toSet(), hasLength(names.length));
    });
  });

  group('v1.3 - catálogo remoto', () {
    FoodItem food(int id, String name) => FoodItem(
      fdcId: id,
      name: name,
      dataType: 'Catálogo remoto',
      kcal: 100,
      protein: 5,
      fat: 2,
      carbs: 15,
      source: 'brasil',
    );

    test(
      'baixa JSON público, ignora duplicatas e guarda cache offline',
      () async {
        final client = MockClient((request) async {
          expect(request.url.toString(), CatalogSyncService.url);
          return http.Response(
            jsonEncode({
              'version': 1,
              'foods': [
                food(-1000, 'Arroz branco cozido').toJson(),
                food(900001, 'Iogurte remoto de teste').toJson(),
              ],
            }),
            200,
          );
        });

        final state = AppState(await StorageService.create());
        await state.load();
        await state.refreshCatalog(service: CatalogSyncService(client: client));

        expect(state.remoteFoods, hasLength(1));
        expect(state.remoteFoods.single.name, 'Iogurte remoto de teste');

        final reloaded = AppState(await StorageService.create());
        await reloaded.load();
        expect(reloaded.remoteFoods.single.name, 'Iogurte remoto de teste');
      },
    );

    test('mantém o cache quando o GitHub está indisponível', () async {
      final storage = await StorageService.create();
      await storage.saveRemoteCatalog(
        jsonEncode([food(900002, 'Biscoito remoto salvo').toJson()]),
      );

      final state = AppState(storage);
      await state.load();
      await state.refreshCatalog(
        service: CatalogSyncService(
          client: MockClient((_) async => http.Response('erro', 503)),
        ),
      );

      expect(state.remoteFoods.single.name, 'Biscoito remoto salvo');
    });
  });

  group('v1.3 - refeições personalizadas', () {
    test('slots extras ficam ocultos até serem nomeados e ativados', () async {
      final state = AppState(await StorageService.create());
      await state.load();

      expect(state.customMeals, hasLength(4));
      expect(state.availableMeals, hasLength(4));

      final meals = state.customMeals
          .map(
            (m) => m.key == 'custom1'
                ? m.copyWith(name: 'Lanche da tarde', enabled: true)
                : m,
          )
          .toList();
      await state.updateCustomMeals(meals);

      expect(state.availableMeals, hasLength(5));
      expect(
        state.availableMeals.map((m) => m.$2),
        contains('Lanche da tarde'),
      );
      expect(state.labelForMeal('custom1'), 'Lanche da tarde');

      final reloaded = AppState(await StorageService.create());
      await reloaded.load();
      expect(reloaded.availableMeals, hasLength(5));
    });

    testWidgets('diário mostra a refeição ativada e abre a configuração',
        (tester) async {
      final state = AppState(await StorageService.create());
      await state.load();
      await state.updateCustomMeals(
        state.customMeals
            .map(
              (m) => m.key == 'custom2'
                  ? m.copyWith(name: 'Lanche da tarde', enabled: true)
                  : m,
            )
            .toList(),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DiaryScreen(
              state: state,
              date: DateTime(2026, 11, 25),
              onDateChanged: (_) {},
              onAddFood: (_) {},
            ),
          ),
        ),
      );
      await tester.pump();

      await tester.scrollUntilVisible(
        find.byTooltip('Refeições personalizadas'),
        400,
        scrollable: find.byType(Scrollable).last,
      );
      await tester.tap(find.byTooltip('Refeições personalizadas'));
      await tester.pumpAndSettle();

      expect(find.text('Refeições personalizadas'), findsOneWidget);
      expect(find.text('Refeição 2'), findsOneWidget);

      await tester.tap(find.text('Cancelar'));
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(
        find.text('Lanche da tarde'),
        400,
        scrollable: find.byType(Scrollable).last,
      );
      expect(find.text('Lanche da tarde'), findsOneWidget);
    });
  });

  group('v1.3 - medidas corporais', () {
    BodyMeasureRecord record() => BodyMeasureRecord.create(
      values: const {
        'neck': 36.5,
        'chest': 100.0,
        'abdomen': 88.0,
        'armLeftFlexed': 34.0,
      },
      notes: 'Fita nova',
      createdAt: DateTime(2026, 11, 25, 10),
    );

    test('serializa e restaura medidas', () {
      final original = record();
      final decoded = jsonDecode(jsonEncode(original.toJson()));
      final restored = BodyMeasureRecord.fromJson(
        decoded as Map<String, dynamic>,
      );

      expect(restored.id, original.id);
      expect(restored.values['neck'], 36.5);
      expect(restored.values['armLeftFlexed'], 34.0);
      expect(restored.notes, 'Fita nova');
    });

    test('AppState persiste o histórico de medidas', () async {
      final state = AppState(await StorageService.create());
      await state.load();
      expect(state.bodyMeasures, isEmpty);

      await state.addBodyMeasure(record());
      expect(state.bodyMeasures, hasLength(1));

      final reloaded = AppState(await StorageService.create());
      await reloaded.load();
      expect(reloaded.bodyMeasures.single.values['chest'], 100);

      await reloaded.clearBodyMeasures();
      expect(reloaded.bodyMeasures, isEmpty);
    });

    testWidgets('tela de medidas mantém dobras minimizadas e fita visível', (
      tester,
    ) async {
      final state = AppState(await StorageService.create());
      await state.load();

      await tester.pumpWidget(MaterialApp(home: SkinfoldScreen(state: state)));
      await tester.pump();

      expect(find.text('Medidas'), findsOneWidget);
      expect(find.text('Jackson & Pollock (dobras)'), findsOneWidget);
      expect(find.text('Medidas com fita (ISAK)'), findsOneWidget);
      expect(find.text('Pescoço'), findsOneWidget);
      expect(find.text('Coxa esq. flexionada'), findsOneWidget);
    });
  });
}
