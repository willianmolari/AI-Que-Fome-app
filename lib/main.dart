import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'screens/diary_screen.dart';
import 'screens/food_search_screen.dart';
import 'screens/profile_screen.dart';
import 'screens/skinfold_screen.dart';
import 'services/storage_service.dart';
import 'services/update_service.dart';
import 'state/app_state.dart';
import 'theme/app_theme.dart';
import 'widgets/update_dialog.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  try {
    await Firebase.initializeApp();
  } catch (error) {
    debugPrint('Firebase não inicializado: $error');
  }

  final storage = await StorageService.create();
  final state = AppState(storage);
  await state.load();

  runApp(
    ListenableBuilder(
      listenable: state,
      builder: (context, _) => NutriDobraApp(state: state),
    ),
  );
}

class NutriDobraApp extends StatelessWidget {
  final AppState state;
  const NutriDobraApp({super.key, required this.state});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Ai que fome',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: state.themeMode,
      home: HomePage(state: state),
    );
  }
}

class HomePage extends StatefulWidget {
  final AppState state;
  const HomePage({super.key, required this.state});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _tab = 0;
  DateTime _date = DateTime.now();
  String _pendingMeal = 'cafe';
  late final UpdateService _updateService;

  @override
  void initState() {
    super.initState();
    _updateService = UpdateService();
    WidgetsBinding.instance.addPostFrameCallback((_) => _checkUpdate());
  }

  @override
  void dispose() {
    _updateService.dispose();
    super.dispose();
  }

  Future<void> _checkUpdate() async {
    final info = await _updateService.check();
    if (info == null || !mounted) return;
    await showUpdateDialog(context, info);
  }

  void _changeDate(DateTime value) => setState(() => _date = value);

  void _goToSearch([String? meal]) => setState(() {
        _pendingMeal = meal ?? 'cafe';
        _tab = 1;
      });

  @override
  Widget build(BuildContext context) {
    final pages = [
      DiaryScreen(
        state: widget.state,
        date: _date,
        onDateChanged: _changeDate,
        onAddFood: _goToSearch,
      ),
      FoodSearchScreen(
        state: widget.state,
        date: _date,
        initialMeal: _pendingMeal,
        onDateChanged: _changeDate,
        onAdded: () => setState(() => _tab = 0),
      ),
      ProfileScreen(state: widget.state),
      SkinfoldScreen(state: widget.state),
    ];

    return Scaffold(
      body: SafeArea(child: pages[_tab]),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _tab,
        onDestinationSelected: (i) => setState(() => _tab = i),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.receipt_long_outlined),
            selectedIcon: Icon(Icons.receipt_long),
            label: 'Diário',
          ),
          NavigationDestination(
            icon: Icon(Icons.search_outlined),
            selectedIcon: Icon(Icons.search),
            label: 'Alimentos',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person),
            label: 'Perfil',
          ),
          NavigationDestination(
            icon: Icon(Icons.monitor_heart_outlined),
            selectedIcon: Icon(Icons.monitor_heart),
            label: 'Dobras',
          ),
        ],
      ),
    );
  }
}
