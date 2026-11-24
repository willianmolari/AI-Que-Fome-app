import 'package:flutter/foundation.dart' show listEquals;
import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../data/food_catalog.dart';
import '../models/diary_entry.dart';
import '../models/food_item.dart';
import '../services/open_food_facts_client.dart';
import '../services/usda_client.dart';
import '../state/app_state.dart';
import '../theme/app_theme.dart';
import '../widgets/portion_editor.dart';

const _sourceFilters = [
  ('brasil', 'Brasil', Icons.flag_outlined),
  ('custom', 'Meus alimentos', Icons.person_add_outlined),
  ('taco', 'TACO', Icons.menu_book_outlined),
  ('fastfood', 'Fast food', Icons.fastfood_outlined),
  ('suplemento', 'Suplementos', Icons.fitness_center_outlined),
  ('openfoodfacts', 'Open Food Facts', Icons.qr_code_scanner_outlined),
  ('usda', 'USDA', Icons.public_outlined),
];

/// Modal de busca. A refeição já é conhecida por quem abriu o modal e não é
/// exibida: o usuário escolhe quantos alimentos quiser e confirma todos juntos.
class FoodSearchScreen extends StatefulWidget {
  final AppState state;
  final DateTime date;
  final String meal;

  const FoodSearchScreen({
    super.key,
    required this.state,
    required this.date,
    required this.meal,
  });

  @override
  State<FoodSearchScreen> createState() => _FoodSearchScreenState();
}

class _FoodSearchScreenState extends State<FoodSearchScreen> {
  final _controller = TextEditingController();
  late UsdaClient _client;
  late OpenFoodFactsClient _offClient;

  Set<String> _sources = const {
    'brasil',
    'custom',
    'taco',
    'fastfood',
    'suplemento',
  };
  String _category = 'Todos';
  final Map<int, PortionData> _selected = <int, PortionData>{};

  List<FoodItem> _localResults = [];
  List<FoodItem> _usdaResults = [];
  List<FoodItem> _offResults = [];
  bool _loadingUsda = false;
  bool _loadingOff = false;
  String? _error;
  String? _offError;

  @override
  void initState() {
    super.initState();
    _client = UsdaClient(apiKey: widget.state.apiKey);
    _offClient = OpenFoodFactsClient();
    _localResults = _localSearch('');
  }

  @override
  void didUpdateWidget(covariant FoodSearchScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.state.apiKey != widget.state.apiKey) {
      _client.dispose();
      _client = UsdaClient(apiKey: widget.state.apiKey);
    }
    if (!listEquals(oldWidget.state.customFoods, widget.state.customFoods)) {
      _refreshLocal();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _client.dispose();
    _offClient.dispose();
    super.dispose();
  }

  List<FoodItem> _localSearch(String query) {
    final extras = _sources.contains('custom')
        ? widget.state.customFoods
        : const <FoodItem>[];
    if (query.trim().isEmpty && _category == 'Todos') {
      return [...FoodCatalog.popular(), ...extras];
    }
    return FoodCatalog.search(
      query,
      sources: _sources,
      category: _category,
      extras: extras,
    );
  }

  void _refreshLocal() {
    setState(() => _localResults = _localSearch(_controller.text.trim()));
  }

  void _toggleSource(String source) {
    final next = Set<String>.from(_sources);
    if (next.contains(source)) {
      next.remove(source);
    } else {
      next.add(source);
    }
    if (next.isEmpty) next.add(source);

    setState(() => _sources = Set.unmodifiable(next));
    _refreshLocal();

    final query = _controller.text.trim();
    if (query.isNotEmpty) {
      if (_sources.contains('usda')) {
        _searchUsda(query);
      } else {
        setState(() {
          _usdaResults = [];
          _error = null;
        });
      }
      if (_sources.contains('openfoodfacts')) {
        _searchOpenFoodFacts(query);
      } else {
        setState(() {
          _offResults = [];
          _offError = null;
        });
      }
    }
  }

  void _selectCategory(String category) {
    setState(() => _category = category);
    _refreshLocal();
  }

  void _submit([String? term]) {
    final query = (term ?? _controller.text).trim();
    if (term != null) _controller.text = term;

    setState(() {
      _error = null;
      _offError = null;
      _usdaResults = [];
      _offResults = [];
      _localResults = _localSearch(query);
    });

    if (query.isEmpty) return;
    if (_sources.contains('usda')) _searchUsda(query);
    if (_sources.contains('openfoodfacts')) _searchOpenFoodFacts(query);
  }

  Future<void> _searchUsda(String query) async {
    setState(() => _loadingUsda = true);
    try {
      final results = await _client.search(query, pageSize: 15);
      if (!mounted) return;
      setState(() {
        _usdaResults = results;
        _error = null;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() => _error = 'USDA: $error');
    } finally {
      if (mounted) setState(() => _loadingUsda = false);
    }
  }

  Future<void> _searchOpenFoodFacts(String query) async {
    setState(() => _loadingOff = true);
    try {
      final results = await _offClient.search(query, pageSize: 15);
      if (!mounted) return;
      setState(() {
        _offResults = results;
        _offError = null;
      });
    } on OpenFoodFactsException catch (error) {
      if (!mounted) return;
      setState(() => _offError = error.message);
    } catch (_) {
      if (!mounted) return;
      setState(() => _offError = 'Não foi possível consultar o Open Food Facts.');
    } finally {
      if (mounted) setState(() => _loadingOff = false);
    }
  }

  PortionData _initialPortion(FoodItem food) => PortionData(
        name: food.displayName,
        amount: food.servingSize,
        unit: food.servingUnit,
        kcal: food.kcalForServing,
        protein: food.proteinForServing,
        carbs: food.carbsForServing,
        fat: food.fatForServing,
      );

  Future<void> _toggleFood(FoodItem food) async {
    if (_selected.containsKey(food.fdcId)) {
      setState(() => _selected.remove(food.fdcId));
      return;
    }
    final edited = await showPortionEditor(
      context,
      _initialPortion(food),
      title: 'Ajustar porção',
    );
    if (edited == null || !mounted) return;
    setState(() => _selected[food.fdcId] = edited);
  }

  Future<void> _editSelected(int fdcId) async {
    final current = _selected[fdcId];
    if (current == null) return;
    final edited = await showPortionEditor(context, current);
    if (edited == null || !mounted) return;
    setState(() => _selected[fdcId] = edited);
  }

  Future<void> _confirm() async {
    if (_selected.isEmpty) return;
    final navigator = Navigator.of(context);
    final now = DateTime.now();
    var index = 0;
    final entries = _selected.entries.map((item) {
      final portion = item.value;
      final created = now.add(Duration(microseconds: index++));
      return DiaryEntry(
        id: '${now.microsecondsSinceEpoch}_${item.key}',
        date: dateKey(widget.date),
        meal: widget.meal,
        fdcId: item.key,
        foodName: portion.name,
        grams: portion.amount,
        unit: portion.unit,
        kcal: portion.kcal,
        protein: portion.protein,
        carbs: portion.carbs,
        fat: portion.fat,
        createdAt: created,
      );
    }).toList();

    await widget.state.addEntries(entries);
    if (!mounted) return;
    navigator.pop(entries.length);
  }

  Future<void> _deleteCustomFood(FoodItem food) async {
    final messenger = ScaffoldMessenger.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Excluir alimento?'),
        content: Text('“${food.name}” será removido de Meus alimentos.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Excluir'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    _selected.remove(food.fdcId);
    await widget.state.removeCustomFood(food.fdcId);
    messenger.showSnackBar(
      SnackBar(content: Text('${food.name} excluído.')),
    );
  }

  Future<void> _openBarcodeScanner() async {
    final controller = MobileScannerController(
      detectionSpeed: DetectionSpeed.noDuplicates,
      facing: CameraFacing.back,
    );
    var handled = false;

    final code = await Navigator.push<String>(
      context,
      MaterialPageRoute(
        builder: (scannerContext) => Scaffold(
          appBar: AppBar(
            title: const Text('Ler código de barras'),
            actions: [
              IconButton(
                tooltip: 'Lanterna',
                onPressed: () => controller.toggleTorch(),
                icon: const Icon(Icons.flashlight_on_outlined),
              ),
            ],
          ),
          body: MobileScanner(
            controller: controller,
            onDetect: (capture) {
              if (handled) return;
              for (final barcode in capture.barcodes) {
                final value = barcode.rawValue;
                if (value != null && value.isNotEmpty) {
                  handled = true;
                  Navigator.pop(scannerContext, value);
                  return;
                }
              }
            },
          ),
        ),
      ),
    );
    await controller.dispose();
    if (code == null || !mounted) return;
    await _lookupBarcode(code);
  }

  Future<void> _lookupBarcode(String code) async {
    final messenger = ScaffoldMessenger.of(context);
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => const AlertDialog(
        content: Row(
          children: [
            CircularProgressIndicator(),
            SizedBox(width: 16),
            Text('Buscando produto...'),
          ],
        ),
      ),
    );

    FoodItem? food;
    String? error;
    try {
      food = await _offClient.fetchByBarcode(code);
    } on OpenFoodFactsException catch (e) {
      error = e.message;
    } catch (_) {
      error = 'Não foi possível consultar o Open Food Facts.';
    }

    if (!mounted) return;
    Navigator.of(context).pop();

    if (food != null) {
      await _toggleFood(food);
      return;
    }

    final register = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Produto não encontrado'),
        content: Text(
          'Nenhum produto foi localizado para o código $code.$error\n\n'
          'Deseja cadastrar manualmente?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Cadastrar'),
          ),
        ],
      ),
    );
    if (register == true && mounted) {
      await _openCustomFoodDialog(barcode: code);
    } else if (error != null) {
      messenger.showSnackBar(SnackBar(content: Text(error)));
    }
  }

  Future<void> _openCustomFoodDialog({String barcode = ''}) async {
    final nameController = TextEditingController();
    final brandController = TextEditingController();
    final servingController = TextEditingController(text: '100');
    final kcalController = TextEditingController();
    final proteinController = TextEditingController();
    final carbsController = TextEditingController();
    final fatController = TextEditingController();
    final fiberController = TextEditingController();
    final sugarsController = TextEditingController();
    String unit = 'g';
    String category = 'Outros';

    final categoryOptions = FoodCatalog.categories
        .where((c) => c != 'Todos' && c != 'Líquidos')
        .toList();

    try {
      final saved = await showDialog<bool>(
        context: context,
        builder: (dialogContext) => StatefulBuilder(
          builder: (context, setDialogState) => AlertDialog(
            title: const Text('Cadastrar alimento'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (barcode.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: Text(
                        'Código de barras: $barcode',
                        style: TextStyle(fontSize: 11, color: muted(context)),
                      ),
                    ),
                  TextField(
                    controller: nameController,
                    textCapitalization: TextCapitalization.words,
                    decoration: const InputDecoration(
                      labelText: 'Nome do alimento',
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: brandController,
                    decoration: const InputDecoration(
                      labelText: 'Marca (opcional)',
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: servingController,
                          keyboardType: TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                          decoration: const InputDecoration(
                            labelText: 'Porção',
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      DropdownButton<String>(
                        value: unit,
                        onChanged: (value) =>
                            setDialogState(() => unit = value ?? 'g'),
                        items: const [
                          DropdownMenuItem(value: 'g', child: Text('g')),
                          DropdownMenuItem(value: 'ml', child: Text('ml')),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  DropdownButtonFormField<String>(
                    initialValue: category,
                    decoration: const InputDecoration(labelText: 'Categoria'),
                    items: categoryOptions
                        .map(
                          (c) => DropdownMenuItem(value: c, child: Text(c)),
                        )
                        .toList(),
                    onChanged: (value) =>
                        setDialogState(() => category = value ?? 'Outros'),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    'Valores nutricionais por 100 $unit:',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: kcalController,
                          keyboardType: TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                          decoration: const InputDecoration(
                            labelText: 'Calorias',
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: TextField(
                          controller: proteinController,
                          keyboardType: TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                          decoration: const InputDecoration(
                            labelText: 'Proteína (g)',
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
                          controller: carbsController,
                          keyboardType: TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                          decoration: const InputDecoration(
                            labelText: 'Carboidrato (g)',
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: TextField(
                          controller: fatController,
                          keyboardType: TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                          decoration: const InputDecoration(
                            labelText: 'Gordura (g)',
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
                          controller: fiberController,
                          keyboardType: TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                          decoration: const InputDecoration(
                            labelText: 'Fibra (g)',
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: TextField(
                          controller: sugarsController,
                          keyboardType: TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                          decoration: const InputDecoration(
                            labelText: 'Açúcar (g)',
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
                onPressed: () => Navigator.pop(dialogContext, false),
                child: const Text('Cancelar'),
              ),
              FilledButton(
                onPressed: () {
                  if (nameController.text.trim().isEmpty) return;
                  Navigator.pop(dialogContext, true);
                },
                child: const Text('Salvar'),
              ),
            ],
          ),
        ),
      );
      if (saved != true || !mounted) return;

      double num(TextEditingController c) =>
          double.tryParse(c.text.replaceAll(',', '.')) ?? 0;
      final food = FoodItem(
        fdcId: DateTime.now().microsecondsSinceEpoch,
        name: nameController.text.trim(),
        brand: brandController.text.trim().isEmpty
            ? null
            : brandController.text.trim(),
        dataType: barcode.isEmpty
            ? 'Cadastro manual'
            : 'Cadastro manual · EAN $barcode',
        servingSize: num(servingController) > 0
            ? num(servingController)
            : 100,
        servingUnit: unit,
        kcal: num(kcalController),
        protein: num(proteinController),
        carbs: num(carbsController),
        fat: num(fatController),
        fiber: num(fiberController),
        sugars: num(sugarsController),
        source: 'custom',
        category: category,
      );
      await widget.state.addCustomFood(food);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${food.name} salvo em Meus alimentos.')),
      );
      await _toggleFood(food);
    } finally {
      nameController.dispose();
      brandController.dispose();
      servingController.dispose();
      kcalController.dispose();
      proteinController.dispose();
      carbsController.dispose();
      fatController.dispose();
      fiberController.dispose();
      sugarsController.dispose();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Adicionar alimentos'),
            Text(
              'Selecione um ou vários',
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.normal),
            ),
          ],
        ),
        centerTitle: false,
        actions: [
          if (_selected.isNotEmpty)
            TextButton(
              onPressed: () => setState(_selected.clear),
              child: const Text('Limpar'),
            ),
          IconButton(
            tooltip: 'Fechar',
            onPressed: () => Navigator.of(context).pop(0),
            icon: const Icon(Icons.close),
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Divider(height: 1, color: outlineSoft(context)),
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 14, 20, 6),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: _controller,
                  textInputAction: TextInputAction.search,
                  onSubmitted: (_) => _submit(),
                  onChanged: (_) => setState(() {}),
                  decoration: InputDecoration(
                    hintText: 'Ex.: filé de sasami, feijão, Coca-Cola',
                    prefixIcon: const Icon(Icons.search),
                    fillColor: softSurface(context),
                    suffixIcon: _controller.text.isEmpty
                        ? null
                        : IconButton(
                            tooltip: 'Limpar busca',
                            onPressed: () {
                              _controller.clear();
                              _submit('');
                            },
                            icon: const Icon(Icons.close),
                          ),
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _openBarcodeScanner,
                        icon: const Icon(Icons.qr_code_scanner_outlined, size: 18),
                        label: const Text('Ler código'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _openCustomFoodDialog,
                        icon: const Icon(Icons.add_circle_outline, size: 18),
                        label: const Text('Cadastrar alimento'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  children: [
                    for (final source in _sourceFilters)
                      FilterChip(
                        avatar: Icon(source.$3, size: 16),
                        label: Text(source.$2),
                        selected: _sources.contains(source.$1),
                        onSelected: (_) => _toggleSource(source.$1),
                        visualDensity: VisualDensity.compact,
                      ),
                    if (_loadingUsda || _loadingOff)
                      const Padding(
                        padding: EdgeInsets.all(8),
                        child: SizedBox(
                          width: 14,
                          height: 14,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 8),
                SizedBox(
                  height: 34,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    children: [
                      for (final category in FoodCatalog.categories)
                        Padding(
                          padding: const EdgeInsets.only(right: 6),
                          child: ChoiceChip(
                            label: Text(category),
                            selected: _category == category,
                            onSelected: (_) => _selectCategory(category),
                            visualDensity: VisualDensity.compact,
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Divider(height: 1, color: outlineSoft(context)),
          Expanded(child: _buildBody(context)),
        ],
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          border: Border(top: BorderSide(color: outlineSoft(context))),
        ),
        padding: EdgeInsets.fromLTRB(
          20,
          10,
          20,
          10 + MediaQuery.viewPaddingOf(context).bottom,
        ),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: theme.colorScheme.primaryContainer,
              child: Text(
                '${_selected.length}',
                style: TextStyle(
                  color: theme.colorScheme.onPrimaryContainer,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    _selected.isEmpty
                        ? 'Nenhum alimento selecionado'
                        : '${_selected.length} ${_selected.length == 1 ? 'alimento selecionado' : 'alimentos selecionados'}',
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    '${_selected.values.fold<double>(0, (s, p) => s + p.kcal).round()} kcal',
                    style: TextStyle(fontSize: 11, color: muted(context)),
                  ),
                ],
              ),
            ),
            FilledButton.icon(
              onPressed: _selected.isEmpty ? null : _confirm,
              icon: const Icon(Icons.check, size: 18),
              label: const Text('Adicionar'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _foodTile(FoodItem food) {
    final selected = _selected.containsKey(food.fdcId);
    return _FoodTile(
      food: food,
      selected: selected,
      portion: selected ? _selected[food.fdcId] : null,
      onToggle: () => _toggleFood(food),
      onEdit: selected ? () => _editSelected(food.fdcId) : null,
      onDelete: food.source == 'custom' ? () => _deleteCustomFood(food) : null,
    );
  }

  Widget _buildBody(BuildContext context) {
    final query = _controller.text.trim();
    if (query.isEmpty) return _buildSuggestions(context);

    final hasLocal = _localResults.isNotEmpty;
    final hasUsda = _usdaResults.isNotEmpty;
    final hasOff = _offResults.isNotEmpty;
    final searching = _loadingUsda || _loadingOff;

    if (!hasLocal && !hasUsda && !hasOff && !searching) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.search_off, size: 42, color: Colors.orange.shade700),
              const SizedBox(height: 12),
              Text('Nada encontrado para “$query”.', textAlign: TextAlign.center),
              const SizedBox(height: 6),
              Text(
                'Tente outro termo ou ative os filtros USDA / Open Food Facts.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 12, color: muted(context)),
              ),
            ],
          ),
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      children: [
        if (hasLocal) ...[
          _SectionTitle(
            title: 'Catálogo local',
            count: _localResults.length,
            icon: Icons.inventory_2_outlined,
          ),
          const SizedBox(height: 8),
          ..._localResults.map((food) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: _foodTile(food),
              )),
        ],
        if (_error != null) ...[
          const SizedBox(height: 8),
          _Notice(text: _error!),
        ],
        if (_offError != null) ...[
          const SizedBox(height: 8),
          _Notice(text: _offError!),
        ],
        if (hasOff) ...[
          const SizedBox(height: 12),
          _SectionTitle(
            title: 'Open Food Facts (Brasil)',
            count: _offResults.length,
            icon: Icons.qr_code_scanner_outlined,
          ),
          const SizedBox(height: 8),
          ..._offResults.map((food) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: _foodTile(food),
              )),
        ],
        if (hasUsda) ...[
          const SizedBox(height: 12),
          _SectionTitle(
            title: 'USDA FoodData Central',
            count: _usdaResults.length,
            icon: Icons.public_outlined,
          ),
          const SizedBox(height: 8),
          ..._usdaResults.map((food) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: _foodTile(food),
              )),
        ],
        if (searching) ...[
          const SizedBox(height: 14),
          const Center(child: CircularProgressIndicator()),
        ],
      ],
    );
  }

  Widget _buildSuggestions(BuildContext context) {
    final shortcuts = [
      ('Arroz e feijão', Icons.soup_kitchen_outlined, 'Arroz e feijão'),
      ('Grãos', Icons.grain_outlined, 'Grãos e cereais'),
      ('Carnes', Icons.kebab_dining_outlined, 'Carnes'),
      ('Frutas', Icons.apple_outlined, 'Frutas'),
      ('Verduras', Icons.eco_outlined, 'Legumes e verduras'),
      ('Laticínios', Icons.local_dining_outlined, 'Laticínios'),
      ('Padaria', Icons.bakery_dining_outlined, 'Padaria'),
      ('Pratos prontos', Icons.restaurant_menu_outlined, 'Pratos prontos'),
      ('Fast food', Icons.fastfood_outlined, 'Fast food'),
      ('Suplementos', Icons.fitness_center_outlined, 'Suplementos'),
      ('Doces', Icons.cake_outlined, 'Doces'),
      ('Bebidas', Icons.local_drink_outlined, 'Bebidas'),
      ('Líquidos', Icons.water_drop_outlined, 'Líquidos'),
    ];

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      children: [
        Text(
          'Atalhos',
          style: Theme.of(context).textTheme.titleMedium
              ?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 10),
        GridView.count(
          crossAxisCount: 3,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 8,
          crossAxisSpacing: 8,
          childAspectRatio: 1.05,
          children: [
            for (final shortcut in shortcuts)
              InkWell(
                onTap: () => _selectCategory(shortcut.$3),
                borderRadius: BorderRadius.circular(14),
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surfaceContainerLow,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: outlineSoft(context)),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        shortcut.$2,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      const SizedBox(height: 6),
                      Text(
                        shortcut.$1,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 18),
        Row(
          children: [
            Text(
              _category == 'Todos' ? 'Mais usados' : _category,
              style: Theme.of(context).textTheme.titleMedium
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
            const Spacer(),
            if (_category != 'Todos')
              TextButton(
                onPressed: () => _selectCategory('Todos'),
                child: const Text('Ver todos'),
              ),
          ],
        ),
        const SizedBox(height: 6),
        if (_localResults.isEmpty)
          Padding(
            padding: const EdgeInsets.all(20),
            child: Text(
              'Nenhum item nesta categoria com os filtros atuais.',
              style: TextStyle(color: muted(context)),
            ),
          )
        else
          ..._localResults.take(40).map(
                (food) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: _foodTile(food),
                ),
              ),
        const SizedBox(height: 10),
        const _Notice(
          text: 'Selecione vários alimentos, ajuste as porções e confirme '
              'todos de uma vez.',
        ),
      ],
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;
  final int count;
  final IconData icon;

  const _SectionTitle({
    required this.title,
    required this.count,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 18, color: Theme.of(context).colorScheme.primary),
        const SizedBox(width: 8),
        Text(
          title,
          style: Theme.of(context).textTheme.titleSmall
              ?.copyWith(fontWeight: FontWeight.bold),
        ),
        const Spacer(),
        Text('$count itens', style: TextStyle(fontSize: 11, color: muted(context))),
      ],
    );
  }
}

class _FoodTile extends StatelessWidget {
  final FoodItem food;
  final bool selected;
  final PortionData? portion;
  final VoidCallback onToggle;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  const _FoodTile({
    required this.food,
    required this.selected,
    required this.portion,
    required this.onToggle,
    this.onEdit,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = switch (food.source) {
      'brasil' => const Color(0xFF007AFF),
      'fastfood' => const Color(0xFFD98C3F),
      'custom' => const Color(0xFF8A6BB0),
      _ => const Color(0xFF3F72AF),
    };

    return Card(
      child: ListTile(
        onTap: onToggle,
        selected: selected,
        selectedTileColor: theme.colorScheme.primary.withValues(alpha: 0.06),
        leading: Checkbox(
          value: selected,
          onChanged: (_) => onToggle(),
        ),
        title: Text(
          food.displayName,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                selected && portion != null
                    ? '${portion!.amount.toStringAsFixed(0)} ${portion!.unit} • '
                        '${portion!.kcal.round()} kcal • '
                        'P ${portion!.protein.round()} • C ${portion!.carbs.round()} • G ${portion!.fat.round()}'
                    : '${food.kcalForServing.round()} kcal por '
                        '${food.servingSize.toStringAsFixed(0)} ${food.servingUnit} • '
                        'P ${food.proteinForServing.round()} • '
                        'C ${food.carbsForServing.round()} • '
                        'G ${food.fatForServing.round()}',
                style: TextStyle(
                  fontSize: 11,
                  color: selected ? theme.colorScheme.primary : muted(context),
                ),
              ),
              const SizedBox(height: 3),
              _SourceBadge(source: food.source, color: color),
            ],
          ),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (onEdit != null)
              IconButton(
                tooltip: 'Editar porção',
                onPressed: onEdit,
                icon: const Icon(Icons.tune_outlined, size: 19),
              ),
            if (onDelete != null)
              IconButton(
                tooltip: 'Excluir alimento',
                onPressed: onDelete,
                icon: Icon(
                  Icons.delete_outline,
                  size: 18,
                  color: theme.colorScheme.error,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _SourceBadge extends StatelessWidget {
  final String source;
  final Color? color;

  const _SourceBadge({required this.source, this.color});

  @override
  Widget build(BuildContext context) {
    final label = switch (source) {
      'brasil' => 'BRASIL',
      'custom' => 'MEU ALIMENTO',
      'taco' => 'TACO',
      'fastfood' => 'FAST FOOD',
      'suplemento' => 'SUPLEMENTO',
      'openfoodfacts' => 'OPEN FOOD FACTS',
      _ => 'USDA',
    };
    final badgeColor = color ?? const Color(0xFF3F72AF);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: badgeColor.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(5),
        border: Border.all(color: badgeColor.withValues(alpha: 0.25)),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 8,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.6,
          color: badgeColor,
        ),
      ),
    );
  }
}

class _Notice extends StatelessWidget {
  final String text;

  const _Notice({required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: outlineSoft(context)),
      ),
      child: Row(
        children: [
          Icon(Icons.info_outline, size: 16, color: muted(context)),
          const SizedBox(width: 8),
          Expanded(
            child: Text(text, style: TextStyle(fontSize: 11, color: muted(context))),
          ),
        ],
      ),
    );
  }
}
