import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'dart:math' as math;

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
import 'package:stocrm_mobile_app/widgets/app_top_bar.dart';
import 'package:stocrm_mobile_app/screens/status_screen.dart';
import 'package:stocrm_mobile_app/screens/vin_screen.dart';
import 'package:stocrm_mobile_app/app_badge.dart';
import 'package:stocrm_mobile_app/local_push.dart';
import 'package:stocrm_mobile_app/push_permissions.dart';
import 'package:stocrm_mobile_app/theme.dart';
import 'package:stocrm_mobile_app/widgets/fit_bottom_bar.dart';

@pragma('vm:entry-point')
Future<void> _firebaseBackground(RemoteMessage message) async {
  await Firebase.initializeApp();
  final raw = message.data['badge'];
  if (raw != null) {
    final n = int.tryParse('$raw');
    if (n != null) {
      await syncAppIconBadge(n);
    }
  }
  if (!kIsWeb && defaultTargetPlatform == TargetPlatform.iOS) {
    await initLocalPush();
    await ensureLocalPushPermissions();
    final title = message.notification?.title ?? message.data['title']?.toString() ?? 'VAG Market';
    final body = message.notification?.body ?? message.data['body']?.toString() ?? '';
    if (title.trim().isNotEmpty) {
      await showBannerPush(id: message.hashCode, title: title, body: body);
    }
  }
}

Future<void> _setupPushPermissions() async {
  try {
    final messaging = FirebaseMessaging.instance;
    await messaging.requestPermission(alert: true, badge: true, sound: true);
    if (defaultTargetPlatform == TargetPlatform.iOS) {
      await messaging.setForegroundNotificationPresentationOptions(
        alert: true,
        badge: true,
        sound: true,
      );
    }
  } catch (_) {}
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  if (!kIsWeb && defaultTargetPlatform == TargetPlatform.iOS) {
    await ensureIosNotificationRegistration();
  }
  await initLocalPush();
  if (!kIsWeb && (defaultTargetPlatform == TargetPlatform.android || defaultTargetPlatform == TargetPlatform.iOS)) {
    try {
      await Firebase.initializeApp();
      FirebaseMessaging.onBackgroundMessage(_firebaseBackground);
      await _setupPushPermissions();
    } catch (_) {}
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
      return const Scaffold(
        backgroundColor: vagBlack,
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              VagWordmark(size: 44, onDark: true),
              SizedBox(height: 28),
              CircularProgressIndicator(color: vagRed, strokeWidth: 2.5),
            ],
          ),
        ),
      );
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
    widget.store.addListener(_onStore);
    WidgetsBinding.instance.addPostFrameCallback((_) => _openPending());
  }

  @override
  void dispose() {
    widget.store.removeListener(_onStore);
    super.dispose();
  }

  void _onStore() {
    if (mounted) setState(() {});
  }

  void _openPending() {
    final screen = widget.store.pendingScreen;
    if (screen == null || screen.isEmpty) return;
    widget.store.clearPendingScreen();
    if (screen == 'garage') {
      setState(() => _index = FitBottomBar.garageIndex);
    } else if (screen == 'book') {
      Navigator.of(context).push(MaterialPageRoute(builder: (_) => BookScreen(store: widget.store)));
    } else if (screen == 'branches') {
      setState(() => _index = FitBottomBar.mapIndex);
    } else if (screen == 'chat') {
      setState(() => _index = FitBottomBar.chatIndex);
    } else if (screen == 'profile') {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => ProfileScreen(
            store: widget.store,
            onOpenBranches: () => setState(() => _index = FitBottomBar.mapIndex),
            onOpenBook: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => BookScreen(store: widget.store))),
          ),
        ),
      );
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
    void openBook() {
      Navigator.of(context).push(MaterialPageRoute(builder: (_) => BookScreen(store: store)));
    }

    void openProfile() {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => ProfileScreen(
            store: store,
            onOpenBranches: () => setState(() => _index = FitBottomBar.mapIndex),
            onOpenBook: openBook,
          ),
        ),
      );
    }

    final pages = [
      HomeScreen(
        store: store,
        onOpenBook: openBook,
        onOpenProfile: openProfile,
        onOpenGarage: () => setState(() => _index = FitBottomBar.garageIndex),
        onOpenBranches: () => setState(() => _index = FitBottomBar.mapIndex),
        onOpenChat: () {
          store.markChatRead();
          setState(() => _index = FitBottomBar.chatIndex);
        },
      ),
      GarageScreen(store: store),
      BranchesScreen(store: store, inShell: true),
      RecommendationsScreen(store: store, inShell: true),
      ChatScreen(store: store, inShell: true),
    ];

    final unread = store.unreadNotes.length;
    final shell = Scaffold(
      backgroundColor: vagSurface,
      body: Column(
        children: [
          AppTopBar(
            unread: unread,
            onCity: () => setState(() => _index = FitBottomBar.mapIndex),
            onNotes: () => showAppNotificationsSheet(context, store),
          ),
          Expanded(child: IndexedStack(index: _index, children: pages)),
        ],
      ),
      bottomNavigationBar: FitBottomBar(
        index: _index,
        chatBadge: store.unreadChat,
        onSelect: (i) {
          if (i == FitBottomBar.chatIndex) store.markChatRead();
          setState(() => _index = i);
        },
      ),
    );

    if (kIsWeb) {
      final w = MediaQuery.sizeOf(context).width;
      if (w > 520) {
        final maxW = math.min(w, 1080.0);
        return ColoredBox(
          color: vagSurface,
          child: Center(child: SizedBox(width: maxW, child: shell)),
        );
      }
    }
    return shell;
  }
}
