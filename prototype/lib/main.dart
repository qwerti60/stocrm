import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:stocrm_mobile_app/data/mock.dart';
import 'package:stocrm_mobile_app/screens/auth_screen.dart';
import 'package:stocrm_mobile_app/screens/book_screen.dart';
import 'package:stocrm_mobile_app/screens/branches_screen.dart';
import 'package:stocrm_mobile_app/screens/chat_screen.dart';
import 'package:stocrm_mobile_app/screens/garage_screen.dart';
import 'package:stocrm_mobile_app/screens/home_screen.dart';
import 'package:stocrm_mobile_app/screens/profile_screen.dart';
import 'package:stocrm_mobile_app/screens/recommendations_screen.dart';
import 'package:stocrm_mobile_app/screens/shorts_screen.dart';
import 'package:stocrm_mobile_app/screens/status_screen.dart';
import 'package:stocrm_mobile_app/screens/vin_screen.dart';
import 'package:stocrm_mobile_app/theme.dart';

@pragma('vm:entry-point')
Future<void> _firebaseBackground(RemoteMessage message) async {
  await Firebase.initializeApp();
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
    await Firebase.initializeApp();
    FirebaseMessaging.onBackgroundMessage(_firebaseBackground);
  }
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
      title: 'VAG Market',
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
  bool booting = true;

  @override
  void initState() {
    super.initState();
    store.addListener(_onStore);
    store.bootstrap().whenComplete(() {
      if (mounted) setState(() => booting = false);
    });
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
    if (booting) {
      return const Scaffold(body: Center(child: CircularProgressIndicator(color: vagRed)));
    }
    if (!store.shortsDone) {
      return ShortsScreen(onDone: store.finishShorts);
    }
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
  void didUpdateWidget(covariant ShellScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    _openPending();
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _openPending());
  }

  void _openPending() {
    final screen = widget.store.pendingScreen;
    if (screen == null || screen.isEmpty) return;
    widget.store.clearPendingScreen();
    if (screen == 'garage') {
      setState(() => _index = 1);
    } else if (screen == 'book') {
      setState(() => _index = 2);
    } else if (screen == 'branches') {
      setState(() => _index = 3);
    } else if (screen == 'chat') {
      setState(() => _index = 4);
    } else if (screen == 'profile') {
      setState(() => _index = 5);
    } else if (screen == 'status') {
      Navigator.of(context).push(MaterialPageRoute(builder: (_) => StatusScreen(store: widget.store)));
    } else if (screen == 'recommendations') {
      Navigator.of(context).push(MaterialPageRoute(builder: (_) => RecommendationsScreen(store: widget.store)));
    } else if (screen == 'vin') {
      Navigator.of(context).push(MaterialPageRoute(builder: (_) => VinScreen(store: widget.store)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final store = widget.store;
    final pages = [
      HomeScreen(
        store: store,
        onOpenBook: () => setState(() => _index = 2),
        onOpenProfile: () => setState(() => _index = 5),
        onOpenGarage: () => setState(() => _index = 1),
        onOpenBranches: () => setState(() => _index = 3),
      ),
      GarageScreen(store: store),
      BookScreen(store: store),
      BranchesScreen(store: store),
      ChatScreen(store: store),
      ProfileScreen(store: store),
    ];

    return Scaffold(
      body: IndexedStack(index: _index, children: pages),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) {
          if (i == 4) widget.store.markChatRead();
          setState(() => _index = i);
        },
        destinations: [
          const NavigationDestination(icon: Icon(Icons.home_outlined), selectedIcon: Icon(Icons.home), label: 'Главная'),
          const NavigationDestination(icon: Icon(Icons.directions_car_outlined), selectedIcon: Icon(Icons.directions_car), label: 'Гараж'),
          const NavigationDestination(icon: Icon(Icons.event_available_outlined), selectedIcon: Icon(Icons.event_available), label: 'Запись'),
          const NavigationDestination(icon: Icon(Icons.location_on_outlined), selectedIcon: Icon(Icons.location_on), label: 'Адреса'),
          NavigationDestination(
            icon: Badge(
              isLabelVisible: store.unreadChat > 0 || store.unreadNotes.where((n) => n.kind == 'chat' || n.kind == 'push').isNotEmpty,
              label: Text('${store.unreadChat + store.unreadNotes.where((n) => n.kind == 'chat' || n.kind == 'push').length}'),
              child: const Icon(Icons.chat_bubble_outline),
            ),
            selectedIcon: const Icon(Icons.chat_bubble),
            label: 'Чаты',
          ),
          const NavigationDestination(icon: Icon(Icons.person_outline), selectedIcon: Icon(Icons.person), label: 'Профиль'),
        ],
      ),
    );
  }
}
