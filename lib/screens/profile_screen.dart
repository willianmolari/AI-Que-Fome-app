import 'package:flutter/material.dart';

import '../models/user_profile.dart';
import '../models/weight_record.dart';
import '../services/auth_service.dart';
import '../state/app_state.dart';
import '../theme/app_theme.dart';
import '../widgets/weight_chart.dart';

const _activityOptions = [
  (1.2, 'Sedentário'),
  (1.375, 'Levemente ativo'),
  (1.55, 'Moderadamente ativo'),
  (1.725, 'Muito ativo'),
  (1.9, 'Extra ativo'),
];

class ProfileScreen extends StatefulWidget {
  final AppState state;
  const ProfileScreen({super.key, required this.state});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  late UserProfile _profile;
  late TextEditingController _name;
  late TextEditingController _age;
  late TextEditingController _weight;
  late TextEditingController _targetWeight;
  late TextEditingController _height;
  late TextEditingController _bodyFat;
  late TextEditingController _kcal;
  late TextEditingController _protein;
  late TextEditingController _carbs;
  late TextEditingController _fat;
  late TextEditingController _apiKey;
  late double _activity;
  late bool _darkMode;

  AuthService? _auth;
  String? _authError;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _profile = widget.state.profile;
    _name = TextEditingController(text: _profile.name);
    _age = TextEditingController(text: '${_profile.age}');
    _weight = TextEditingController(text: '${_profile.weightKg}');
    _targetWeight = TextEditingController(text: '${_profile.targetWeightKg}');
    _height = TextEditingController(text: '${_profile.heightCm}');
    _bodyFat = TextEditingController(
      text: _profile.bodyFatPercent > 0
          ? _profile.bodyFatPercent.toStringAsFixed(1)
          : '',
    );
    _kcal = TextEditingController(text: '${_profile.goalKcal.round()}');
    _protein = TextEditingController(text: '${_profile.goalProtein.round()}');
    _carbs = TextEditingController(text: '${_profile.goalCarbs.round()}');
    _fat = TextEditingController(text: '${_profile.goalFat.round()}');
    _apiKey = TextEditingController(text: widget.state.apiKey ?? '');
    _activity = _profile.activityFactor;
    _darkMode = _profile.darkMode;

    try {
      _auth = AuthService();
    } catch (error) {
      _authError = 'Firebase indisponível: $error';
    }
  }

  @override
  void didUpdateWidget(covariant ProfileScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.state.profile == widget.state.profile) return;
    final profile = widget.state.profile;
    final previous = oldWidget.state.profile;
    setState(() {
      _profile = profile;
      _darkMode = profile.darkMode;
      final bodyFatText = profile.bodyFatPercent > 0
          ? profile.bodyFatPercent.toStringAsFixed(1)
          : '';
      if (_bodyFat.text != bodyFatText) _bodyFat.text = bodyFatText;
      if (_name.text.isEmpty || _name.text == 'Usuário') {
        _name.text = profile.name;
      }
      final targetText = '${profile.targetWeightKg}';
      if (_targetWeight.text.isEmpty ||
          _targetWeight.text == '${previous.targetWeightKg}') {
        _targetWeight.text = targetText;
      }
    });
  }

  @override
  void dispose() {
    _name.dispose();
    _age.dispose();
    _weight.dispose();
    _targetWeight.dispose();
    _height.dispose();
    _bodyFat.dispose();
    _kcal.dispose();
    _protein.dispose();
    _carbs.dispose();
    _fat.dispose();
    _apiKey.dispose();
    super.dispose();
  }

  double _num(TextEditingController c, [double fallback = 0]) {
    return double.tryParse(c.text.replaceAll(',', '.')) ?? fallback;
  }

  UserProfile _buildProfile() => UserProfile(
        name: _name.text.trim().isEmpty ? 'Usuário' : _name.text.trim(),
        sex: _profile.sex,
        age: _num(_age, 30).round().clamp(10, 100),
        weightKg: _num(_weight, 70).clamp(20, 400),
        targetWeightKg: _num(_targetWeight, 70).clamp(20, 400),
        heightCm: _num(_height, 170).clamp(100, 230),
        activityFactor: _activity,
        goalKcal: _num(_kcal, 2000).clamp(800, 10000),
        goalProtein: _num(_protein).clamp(0, 500),
        goalCarbs: _num(_carbs).clamp(0, 1000),
        goalFat: _num(_fat).clamp(0, 400),
        bodyFatPercent: _num(_bodyFat).clamp(0, 70),
        darkMode: _darkMode,
      );

  Future<void> _save() async {
    final profile = _buildProfile();
    final previousWeight = widget.state.profile.weightKg;
    await widget.state.updateProfile(profile);
    if ((profile.weightKg - previousWeight).abs() > 0.01) {
      await widget.state.addWeightRecord(
        WeightRecord.create(date: DateTime.now(), weightKg: profile.weightKg),
      );
    }
    await widget.state.setApiKey(_apiKey.text);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Perfil e preferências salvos.')),
    );
  }

  Future<void> _registerWeight() async {
    final weight = _buildProfile().weightKg;
    await widget.state.updateProfile(_buildProfile());
    await widget.state.addWeightRecord(
      WeightRecord.create(date: DateTime.now(), weightKg: weight),
    );
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Peso registrado no histórico.')),
    );
  }

  void _suggest() {
    final candidate = _profile.copyWith(
      age: _num(_age, 30).round(),
      weightKg: _num(_weight, 70),
      heightCm: _num(_height, 170),
      activityFactor: _activity,
    );
    setState(() {
      _kcal.text = candidate.suggestedKcal.round().toString();
      _protein.text = (candidate.weightKg * 1.6).round().toString();
      _fat.text = (candidate.weightKg * 0.9).round().toString();
      final remaining = candidate.suggestedKcal -
          (candidate.weightKg * 1.6 * 4) -
          (candidate.weightKg * 0.9 * 9);
      _carbs.text = (remaining / 4).clamp(0, 10000).round().toString();
    });
  }

  Future<void> _signIn() async {
    final auth = _auth;
    if (auth == null) {
      setState(
        () => _authError = 'Configure o google-services.json para usar o login.',
      );
      return;
    }
    setState(() {
      _busy = true;
      _authError = null;
    });
    try {
      final account = await auth.signInWithGoogle();
      await widget.state.setAccount(account);
      if (!mounted) return;
      if (_name.text == 'Usuário' || _name.text.isEmpty) {
        setState(() => _name.text = account.displayName);
      }
      await widget.state.updateProfile(
        widget.state.profile.copyWith(name: account.displayName),
      );
    } on AuthFailure catch (e) {
      if (!mounted) return;
      setState(() => _authError = e.message);
    } catch (e) {
      if (!mounted) return;
      setState(() => _authError = 'Erro inesperado no login: $e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _signOut() async {
    final auth = _auth;
    if (auth == null) return;
    setState(() => _busy = true);
    try {
      await auth.signOut();
      await widget.state.setAccount(null);
    } catch (e) {
      if (!mounted) return;
      setState(() => _authError = 'Não foi possível sair: $e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _toggleDark(bool value) async {
    setState(() => _darkMode = value);
    await widget.state.setDarkMode(value);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bmi = _num(_weight) / (_num(_height) / 100 * _num(_height) / 100);
    final account = widget.state.account;

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
      children: [
        Text(
          'Perfil',
          style: theme.textTheme.labelLarge?.copyWith(
            color: theme.colorScheme.primary,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.2,
          ),
        ),
        Text(
          'Seus dados e preferências',
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 14),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      radius: 26,
                      backgroundColor: theme.colorScheme.primaryContainer,
                      child: Text(
                        account == null
                            ? '?'
                            : account.displayName.isNotEmpty
                                ? account.displayName[0].toUpperCase()
                                : 'U',
                        style: TextStyle(
                          color: theme.colorScheme.onPrimaryContainer,
                          fontWeight: FontWeight.bold,
                          fontSize: 20,
                        ),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            account?.displayName ?? 'Não conectado',
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            account?.email ?? 'Entre com sua conta Google',
                            style: TextStyle(fontSize: 12, color: muted(context)),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                SizedBox(
                  width: double.infinity,
                  child: _busy
                      ? const Center(child: CircularProgressIndicator())
                      : FilledButton.tonalIcon(
                          onPressed: account == null ? _signIn : _signOut,
                          icon: Icon(
                            account == null ? Icons.login : Icons.logout,
                            size: 18,
                          ),
                          label: Text(
                            account == null ? 'Entrar com Google' : 'Sair da conta',
                          ),
                        ),
                ),
                if (_authError != null) ...[
                  const SizedBox(height: 10),
                  Text(
                    _authError!,
                    style: TextStyle(fontSize: 11, color: Colors.orange.shade700),
                  ),
                ],
              ],
            ),
          ),
        ),
        const SizedBox(height: 14),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.monitor_weight_outlined,
                      size: 20,
                      color: theme.colorScheme.primary,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Peso',
                      style: theme.textTheme.titleMedium
                          ?.copyWith(fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _weight,
                        keyboardType: TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        onChanged: (_) => setState(() {}),
                        decoration: const InputDecoration(
                          labelText: 'Peso atual (kg)',
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextField(
                        controller: _targetWeight,
                        keyboardType: TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        decoration: const InputDecoration(
                          labelText: 'Peso alvo (kg)',
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.tonalIcon(
                    onPressed: _registerWeight,
                    icon: const Icon(Icons.add_chart_outlined, size: 18),
                    label: const Text('Registrar peso de hoje'),
                  ),
                ),
                if (bmi.isFinite && bmi > 10 && bmi < 70)
                  Padding(
                    padding: const EdgeInsets.only(top: 12),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Chip(
                        label: Text('IMC estimado: ${bmi.toStringAsFixed(1)}'),
                        visualDensity: VisualDensity.compact,
                      ),
                    ),
                  ),
                const SizedBox(height: 16),
                Text(
                  'Evolução do peso',
                  style: theme.textTheme.titleSmall
                      ?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 6),
                WeightChart(
                  records: widget.state.weightHistory,
                  targetKg: _num(_targetWeight),
                  lineColor: theme.colorScheme.primary,
                  targetColor: theme.colorScheme.tertiary,
                  gridColor: theme.colorScheme.onSurface.withValues(alpha: 0.12),
                  labelColor: muted(context),
                ),
                if (widget.state.weightHistory.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  const Divider(height: 1),
                  const SizedBox(height: 8),
                  for (final record
                      in widget.state.weightHistory.reversed.take(5))
                    ListTile(
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                      leading: Icon(
                        Icons.monitor_weight_outlined,
                        size: 18,
                        color: muted(context),
                      ),
                      title: Text(
                        '${record.date.day.toString().padLeft(2, '0')}/'
                        '${record.date.month.toString().padLeft(2, '0')}/'
                        '${record.date.year}',
                        style: const TextStyle(fontSize: 13),
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            '${record.weightKg.toStringAsFixed(1)} kg',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          IconButton(
                            icon: Icon(
                              Icons.delete_outline,
                              size: 18,
                              color: theme.colorScheme.error,
                            ),
                            tooltip: 'Excluir medição',
                            onPressed: () => widget.state
                                .removeWeightRecord(record.id),
                          ),
                        ],
                      ),
                    ),
                ],
              ],
            ),
          ),
        ),
        const SizedBox(height: 14),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Dados pessoais',
                  style: theme.textTheme.titleMedium
                      ?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: _name,
                  textCapitalization: TextCapitalization.words,
                  decoration: const InputDecoration(
                    labelText: 'Nome',
                    prefixIcon: Icon(Icons.person_outline),
                  ),
                ),
                const SizedBox(height: 12),
                SegmentedButton<String>(
                  segments: const [
                    ButtonSegment(value: 'male', label: Text('Masculino')),
                    ButtonSegment(value: 'female', label: Text('Feminino')),
                  ],
                  selected: {_profile.sex},
                  onSelectionChanged: (value) => setState(
                    () => _profile = _profile.copyWith(sex: value.first),
                  ),
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _age,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(labelText: 'Idade'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextField(
                        controller: _height,
                        keyboardType: TextInputType.number,
                        onChanged: (_) => setState(() {}),
                        decoration: const InputDecoration(
                          labelText: 'Altura (cm)',
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _bodyFat,
                  keyboardType: TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(
                    labelText: 'Gordura (%)',
                    suffixText: '%',
                  ),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<double>(
                  initialValue: _activity,
                  decoration: const InputDecoration(
                    labelText: 'Nível de atividade',
                  ),
                  items: _activityOptions
                      .map(
                        (option) => DropdownMenuItem<double>(
                          value: option.$1,
                          child: Text(option.$2),
                        ),
                      )
                      .toList(),
                  onChanged: (value) {
                    if (value != null) setState(() => _activity = value);
                  },
                ),
                if (bmi.isFinite && bmi > 10 && bmi < 70)
                  Padding(
                    padding: const EdgeInsets.only(top: 14),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Chip(
                        label: Text('IMC estimado: ${bmi.toStringAsFixed(1)}'),
                        visualDensity: VisualDensity.compact,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 14),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      'Metas diárias',
                      style: theme.textTheme.titleMedium
                          ?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const Spacer(),
                    TextButton.icon(
                      onPressed: _suggest,
                      icon: const Icon(Icons.auto_awesome_outlined, size: 18),
                      label: const Text('Sugerir'),
                    ),
                  ],
                ),
                TextField(
                  controller: _kcal,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Calorias (kcal)'),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _protein,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Proteína (g)',
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextField(
                        controller: _carbs,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Carboidrato (g)',
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _fat,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Gordura (g)'),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 14),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Configurações',
                  style: theme.textTheme.titleMedium
                      ?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 6),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Modo escuro'),
                  subtitle: Text(
                    'Alterna o tema do aplicativo',
                    style: TextStyle(fontSize: 12, color: muted(context)),
                  ),
                  value: _darkMode,
                  onChanged: _toggleDark,
                ),
                const Divider(height: 18),
                TextField(
                  controller: _apiKey,
                  obscureText: true,
                  decoration: const InputDecoration(
                    labelText: 'Chave da API do USDA (opcional)',
                    prefixIcon: Icon(Icons.key_outlined),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Sem chave, a busca USDA usa DEMO_KEY. O catálogo local '
                  'funciona normalmente.',
                  style: TextStyle(fontSize: 11, color: muted(context)),
                ),
                const SizedBox(height: 8),
                Text(
                  'Tudo fica salvo neste dispositivo: diário, metas, perfil, '
                  'dobras e histórico de peso.',
                  style: TextStyle(fontSize: 11, color: muted(context)),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 20),
        SizedBox(
          width: double.infinity,
          child: FilledButton.icon(
            onPressed: _save,
            icon: const Icon(Icons.save_outlined),
            label: const Text('Salvar alterações'),
          ),
        ),
      ],
    );
  }
}
