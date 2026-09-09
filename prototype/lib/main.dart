import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:stocrm_mobile_app/data/mock.dart';
import 'package:stocrm_mobile_app/screens/auth_screen.dart';
import 'package:stocrm_mobile_app/screens/book_screen.dart';
import 'package:stocrm_mobile_app/screens/garage_screen.dart';
import 'package:stocrm_mobile_app/screens/home_screen.dart';
import 'package:stocrm_mobile_app/screens/profile_screen.dart';
import 'package:stocrm_mobile_app/screens/visits_screen.dart';
import 'package:stocrm_mobile_app/theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  if (kIsWeb) {
    WidgetsBinding.instance.ensureSemantics();
  }
  await initializeDateFormatting('ru');
  runApp(const DriveStoApp());
}

class DriveStoApp extends StatelessWidget {
  const DriveStoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'DRIVE СТО · STOCRM',
      debugShowCheckedModeBanner: false,
      theme: buildAppTheme(),
      locale: const Locale('ru'),
      supportedLocales: const [Locale('ru'), Locale('en')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      home: const RootScreen(),
    );
  }
}

class RootScreen extends StatefulWidget {
  const RootScreen({super.key});

  @override
  State<RootScreen> createState() => _RootScreenState();
}

class _RootScreenState extends State<RootScreen> {
  final MockStore store = MockStore();

  @override
  void initState() {
    super.initState();
    store.addListener(_onStore);
  }

  @override
  void dispose() {
    store.removeListener(_onStore);
    store.dispose();
    super.dispose();
  }

  void _onStore() => setState(() {});

  @override
  Widget build(BuildContext context) {
    if (!store.loggedIn) return AuthScreen(store: store);
    return ShellScreen(store: store);
  }
}

class ShellScreen extends StatefulWidget {
  const ShellScreen({super.key, required this.store});
  final MockStore store;

  @override
  State<ShellScreen> createState() => _ShellScreenState();
}

class _ShellScreenState extends State<ShellScreen> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    final store = widget.store;
    final pages = [
      HomeScreen(store: store, onOpenBook: () => setState(() => _index = 2)),
      GarageScreen(store: store),
      BookScreen(store: store),
      VisitsScreen(store: store),
      ProfileScreen(store: store),
    ];

    return Scaffold(
      body: IndexedStack(index: _index, children: pages),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home_outlined), selectedIcon: Icon(Icons.home), label: 'Главная'),
          NavigationDestination(icon: Icon(Icons.directions_car_outlined), selectedIcon: Icon(Icons.directions_car), label: 'Гараж'),
          NavigationDestination(icon: Icon(Icons.event_available_outlined), selectedIcon: Icon(Icons.event_available), label: 'Запись'),
          NavigationDestination(icon: Icon(Icons.receipt_long_outlined), selectedIcon: Icon(Icons.receipt_long), label: 'Визиты'),
          NavigationDestination(icon: Icon(Icons.person_outline), selectedIcon: Icon(Icons.person), label: 'Профиль'),
        ],
      ),
    );
  }
}
