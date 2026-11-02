import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:stocrm_mobile_app/data/mock.dart';
import 'package:stocrm_mobile_app/screens/booking_flow.dart';
import 'package:stocrm_mobile_app/screens/chat_screen.dart';
import 'package:stocrm_mobile_app/screens/popular_service_screen.dart';
import 'package:stocrm_mobile_app/screens/recommendations_screen.dart';
import 'package:stocrm_mobile_app/screens/search_sheet.dart';
import 'package:stocrm_mobile_app/screens/status_screen.dart';
import 'package:stocrm_mobile_app/screens/vin_screen.dart';
import 'package:stocrm_mobile_app/screens/visits_screen.dart';
import 'package:stocrm_mobile_app/theme.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({
    super.key,
    required this.store,
    required this.onOpenBook,
    required this.onOpenProfile,
    required this.onOpenGarage,
    required this.onOpenBranches,
    required this.onOpenChat,
  });
  final MockStore store;
  final VoidCallback onOpenBook;
  final VoidCallback onOpenProfile;
  final VoidCallback onOpenGarage;
  final VoidCallback onOpenBranches;
  final VoidCallback onOpenChat;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with SingleTickerProviderStateMixin {
  String? _shownAlert;
  final PageController _hero = PageController();
  int _heroPage = 0;
  late TabController _homeTabs;

  @override
  void initState() {
    super.initState();
    _homeTabs = TabController(length: 2, vsync: this);
    widget.store.addListener(_onStore);
  }

  void _onStore() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    widget.store.removeListener(_onStore);
    _homeTabs.dispose();
    _hero.dispose();
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _maybeAlert();
  }

  void _maybeAlert() {
    final alert = widget.store.pendingReadyAlert;
    if (alert == null || alert == _shownAlert) return;
    _shownAlert = alert;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(alert),
          action: SnackBarAction(
            label: 'Статус',
            onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => StatusScreen(store: widget.store))),
          ),
        ),
      );
      widget.store.clearReadyAlert();
    });
  }

  void _openNotes() {
    final store = widget.store;
    final notes = store.unreadNotes;
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: vagCard,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) {
        if (notes.isEmpty) {
          return const Padding(
            padding: EdgeInsets.fromLTRB(24, 28, 24, 40),
            child: Text('Нет новых уведомлений', style: TextStyle(color: vagMutedInk)),
          );
        }
        return SafeArea(
          child: ListView(
            shrinkWrap: true,
            padding: const EdgeInsets.fromLTRB(8, 12, 8, 24),
            children: [
              const Padding(
                padding: EdgeInsets.fromLTRB(16, 8, 16, 8),
                child: Text('Уведомления', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16, color: vagInk)),
              ),
              for (final note in notes)
                ListTile(
                  leading: const Icon(Icons.notifications_active, color: vagRed),
                  title: Text(note.title, style: const TextStyle(fontWeight: FontWeight.w800)),
                  subtitle: Text(note.body, style: const TextStyle(color: vagMutedInk, fontSize: 12)),
                  onTap: () {
                    Navigator.pop(ctx);
                    store.markNoteRead(note.id);
                    final kind = note.kind ?? '';
                    if (kind == 'chat' || kind == 'push') {
                      Navigator.of(context).push(MaterialPageRoute(builder: (_) => ChatScreen(store: store)));
                    } else if (kind == 'promo') {
                      Navigator.of(context).push(MaterialPageRoute(builder: (_) => RecommendationsScreen(store: store)));
                    } else {
                      Navigator.of(context).push(MaterialPageRoute(builder: (_) => StatusScreen(store: store)));
                    }
                  },
                ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    _maybeAlert();
    final store = widget.store;
    final next = store.nextVisit;
    final unread = store.unreadNotes.length;
    final car = store.activeCar;
    final recs = car == null ? store.recommendations.length : store.recommendationsForCar(car).length;

    return Scaffold(
      backgroundColor: vagSurface,
      body: Column(
        children: [
          _HeroBlock(
            controller: _hero,
            page: _heroPage,
            unread: unread,
            onCity: widget.onOpenBranches,
            onNotes: _openNotes,
            onPage: (i) => setState(() => _heroPage = i),
          ),
          Material(
            color: vagCard,
            elevation: 0,
            child: TabBar(
              controller: _homeTabs,
              labelColor: vagRed,
              unselectedLabelColor: vagMutedInk,
              indicatorColor: vagRed,
              indicatorWeight: 2.5,
              labelStyle: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13),
              tabs: const [
                Tab(text: 'Обзор'),
                Tab(text: 'Услуги'),
              ],
            ),
          ),
          Expanded(
            child: TabBarView(
              controller: _homeTabs,
              children: [
                _HomeOverviewTab(
                  store: store,
                  next: next,
                  car: car,
                  recs: recs,
                  onOpenGarage: widget.onOpenGarage,
                  onOpenBook: widget.onOpenBook,
                ),
                _HomeServicesTab(
                  store: store,
                  onOpenBook: widget.onOpenBook,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _HomeOverviewTab extends StatelessWidget {
  const _HomeOverviewTab({
    required this.store,
    required this.next,
    required this.car,
    required this.recs,
    required this.onOpenGarage,
    required this.onOpenBook,
  });

  final MockStore store;
  final Visit? next;
  final Vehicle? car;
  final int recs;
  final VoidCallback onOpenGarage;
  final VoidCallback onOpenBook;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 96),
      children: [
        if (next != null) ...[
          _AlertBanner(
            title: 'Авто в сервисе · ${next!.status}',
            subtitle: '${next!.serviceTitle} · ${DateFormat('d MMM, HH:mm', 'ru').format(next!.when)}',
            onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => StatusScreen(store: store, visit: next!))),
          ),
          const SizedBox(height: 14),
        ],
        Row(
          children: [
            const Text('Ваш автомобиль', style: vagSectionTitle),
            const Spacer(),
            GestureDetector(
              onTap: onOpenGarage,
              child: const Text('Гараж >', style: TextStyle(color: vagMutedInk, fontSize: 13, fontWeight: FontWeight.w600)),
            ),
          ],
        ),
        const SizedBox(height: 10),
        _CarBlock(
          car: car,
          recs: recs,
          onGarage: onOpenGarage,
          onHistory: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => VisitsScreen(store: store))),
          onRecs: () => Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => RecommendationsScreen(store: store, filterCar: car)),
          ),
          onService: onOpenBook,
        ),
        const SizedBox(height: 16),
        Text(
          'Запись, карта филиалов, гараж и чат — в нижнем меню, как в FIT SERVICE.',
          style: const TextStyle(color: vagMutedInk, fontSize: 12, height: 1.35),
        ),
      ],
    );
  }
}

class _HomeServicesTab extends StatelessWidget {
  const _HomeServicesTab({required this.store, required this.onOpenBook});

  final MockStore store;
  final VoidCallback onOpenBook;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 96),
      children: [
        FilledButton.icon(
          onPressed: onOpenBook,
          icon: const Icon(Icons.event_available),
          label: const Text('Запись на сервис'),
        ),
        const SizedBox(height: 16),
        _DiagPromoBanner(onTap: onOpenBook),
        const SizedBox(height: 18),
        const Text('Популярные услуги', style: vagSectionTitle),
        const SizedBox(height: 10),
        ...store.popularServices.asMap().entries.map((e) {
          final s = e.value;
          final priceRed = s.price.toLowerCase().contains('бесплат');
          return Padding(
            padding: EdgeInsets.only(bottom: e.key < store.popularServices.length - 1 ? 8 : 0),
            child: _PopularServiceRow(
              image: s.image.isNotEmpty ? s.image : 'assets/offer-oil.png',
              icon: _popularServiceIcon(s),
              title: s.title,
              price: s.price,
              priceRed: priceRed,
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => PopularServiceScreen(store: store, service: s)),
              ),
            ),
          );
        }),
        const SizedBox(height: 12),
        OutlinedButton(
          onPressed: () => openAppSearch(context, store),
          child: const Text('Поиск по услугам и истории'),
        ),
      ],
    );
  }
}

class _HeroBlock extends StatelessWidget {
  const _HeroBlock({
    required this.controller,
    required this.page,
    required this.unread,
    required this.onCity,
    required this.onNotes,
    required this.onPage,
  });

  final PageController controller;
  final int page;
  final int unread;
  final VoidCallback onCity;
  final VoidCallback onNotes;
  final ValueChanged<int> onPage;

  static const _slides = [
    (
      title: 'ПОЛНЫЙ КОНТРОЛЬ\nНАД ВАШИМ ',
      accent: 'VAG',
      sub: 'Профессиональный сервис, оригинальные запчасти и честные цены.',
      image: 'assets/hero-car.png',
      tags: true,
    ),
    (
      title: 'КОМПЛЕКСНАЯ\n',
      accent: 'ДИАГНОСТИКА',
      sub: 'Бесплатно при записи на сервис — как на баннере ниже.',
      image: 'assets/diag-car.png',
      tags: false,
    ),
    (
      title: 'ИСТОРИЯ РЕМОНТА\nВ ',
      accent: 'СЕРВИСБУКЕ',
      sub: 'Заказ-наряды и PDF всегда под рукой в приложении.',
      image: 'assets/hero-car.png',
      tags: false,
    ),
  ];

  static ({double pad, double sliderH, double headline, double bannerH, bool wide}) _metrics(BuildContext context) {
    final w = MediaQuery.sizeOf(context).width;
    final wide = w >= 520;
    return (
      pad: wide ? 24.0 : 16.0,
      sliderH: wide ? 300.0 : 268.0,
      headline: wide ? 22.0 : 18.0,
      bannerH: wide ? 132.0 : 112.0,
      wide: wide,
    );
  }

  @override
  Widget build(BuildContext context) {
    final m = _metrics(context);
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(colors: [Color(0xFF1A1014), vagBlack], begin: Alignment.topCenter, end: Alignment.bottomCenter),
      ),
      width: double.infinity,
      child: SafeArea(
        bottom: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: EdgeInsets.fromLTRB(m.pad, 4, m.pad, 0),
              child: Row(
                children: [
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        VagWordmark(size: 22, onDark: true),
                        SizedBox(height: 4),
                        Text(
                          'СЕРВИС · ЗАПЧАСТИ · ЗАБОТА О VAG',
                          style: TextStyle(color: Color(0xFFB0B0B5), fontSize: 8, letterSpacing: 0.6, fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                  ),
                  GestureDetector(
                    onTap: onCity,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                      decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(20)),
                      child: const Row(
                        children: [
                          Icon(Icons.location_on, size: 14, color: vagRed),
                          SizedBox(width: 4),
                          Text('Тюмень', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.white)),
                          Icon(Icons.keyboard_arrow_down, size: 16, color: Colors.white70),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: onNotes,
                    child: Stack(
                      clipBehavior: Clip.none,
                      children: [
                        Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(18)),
                          child: const Icon(Icons.notifications_none, size: 20, color: Colors.white),
                        ),
                        if (unread > 0)
                          Positioned(
                            right: -2,
                            top: -2,
                            child: CircleAvatar(
                              radius: 8,
                              backgroundColor: vagRed,
                              child: Text('$unread', style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w800, color: Colors.white)),
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(
              height: m.sliderH,
              child: PageView.builder(
                controller: controller,
                itemCount: _slides.length,
                onPageChanged: onPage,
                itemBuilder: (_, i) {
                  final s = _slides[i];
                  return Padding(
                    padding: EdgeInsets.fromLTRB(m.pad, 8, m.pad, 0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        RichText(
                          text: TextSpan(
                            style: vagHeroHeadline.copyWith(fontSize: m.headline, height: 1.12),
                            children: [
                              TextSpan(text: s.title),
                              TextSpan(text: s.accent, style: const TextStyle(color: vagRed)),
                            ],
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          s.sub,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: vagHeroSub.copyWith(
                            color: Colors.white.withValues(alpha: 0.78),
                            fontSize: 12,
                            height: 1.35,
                          ),
                        ),
                        if (s.tags) ...[
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 6,
                            runSpacing: 6,
                            children: const [
                              _HeroChip(label: 'Диагностика', icon: Icons.medical_services_outlined),
                              _HeroChip(label: 'Запчасти', icon: Icons.settings_outlined),
                              _HeroChip(label: 'Сервис', icon: Icons.build_outlined),
                              _HeroChip(label: 'ТО', icon: Icons.fact_check_outlined),
                            ],
                          ),
                        ],
                        const SizedBox(height: 10),
                        Expanded(
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(14),
                            child: ColoredBox(
                              color: const Color(0xFF252528),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                                child: Image.asset(
                                  s.image,
                                  fit: BoxFit.contain,
                                  alignment: Alignment.bottomCenter,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
            Padding(
              padding: EdgeInsets.fromLTRB(m.pad, 0, m.pad, m.wide ? 14 : 18),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Text(
                    '${(page + 1).toString().padLeft(2, '0')} / ${_slides.length.toString().padLeft(2, '0')}',
                    style: const TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(width: 8),
                  ...List.generate(_slides.length, (i) {
                    final on = i == page;
                    return Container(
                      width: on ? 16 : 6,
                      height: 6,
                      margin: const EdgeInsets.only(left: 4),
                      decoration: BoxDecoration(
                        color: on ? vagRed : Colors.white24,
                        borderRadius: BorderRadius.circular(99),
                      ),
                    );
                  }),
                  IconButton(
                    onPressed: () {
                      final next = (page + 1) % _slides.length;
                      controller.animateToPage(next, duration: const Duration(milliseconds: 320), curve: Curves.easeOut);
                    },
                    icon: const Icon(Icons.arrow_forward, color: Colors.white, size: 20),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HeroChip extends StatelessWidget {
  const _HeroChip({required this.label, required this.icon});
  final String label;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.white24),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: vagRed),
          const SizedBox(width: 4),
          Text(label, style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w700, color: Colors.white)),
        ],
      ),
    );
  }
}


IconData _popularServiceIcon(PopularService s) {
  switch (s.id) {
    case 'oil':
      return Icons.opacity;
    case 'diag':
      return Icons.speed;
    case 'ac':
      return Icons.ac_unit;
  }
  final t = s.title.toLowerCase();
  if (t.contains('масл')) return Icons.opacity;
  if (t.contains('диагност')) return Icons.speed;
  if (t.contains('кондицион') || t.contains('климат')) return Icons.ac_unit;
  return Icons.build_outlined;
}

class _PopularServiceRow extends StatelessWidget {
  const _PopularServiceRow({
    required this.image,
    required this.icon,
    required this.title,
    required this.price,
    required this.onTap,
    this.priceRed = false,
  });

  final String image;
  final IconData icon;
  final String title;
  final String price;
  final bool priceRed;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: vagCard,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          decoration: lightPanelDecoration(radius: 14),
          padding: const EdgeInsets.all(10),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: SizedBox(
                  width: 68,
                  height: 68,
                  child: Image.asset(
                    image,
                    fit: BoxFit.contain,
                    errorBuilder: (_, __, ___) => ColoredBox(
                      color: vagBorder,
                      child: Icon(icon, color: vagRed, size: 28),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(title, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15, color: vagInk)),
                    const SizedBox(height: 4),
                    Text(
                      price,
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 13,
                        color: priceRed ? vagRed : vagMutedInk,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: vagMutedInk),
            ],
          ),
        ),
      ),
    );
  }
}

class _DiagPromoBanner extends StatelessWidget {
  const _DiagPromoBanner({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: Material(
        color: const Color(0xFF1A0508),
        child: InkWell(
          onTap: onTap,
          child: SizedBox(
            height: 100,
            child: Row(
              children: [
                Container(width: 4, color: vagRed),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(12, 12, 8, 12),
                    child: Row(
                      children: [
                        const Expanded(
                          child: Text(
                            'КОМПЛЕКСНАЯ ДИАГНОСТИКА\nБЕСПЛАТНО ПРИ ЗАПИСИ НА СЕРВИС',
                            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 11, height: 1.3),
                          ),
                        ),
                        Container(
                          width: 36,
                          height: 36,
                          decoration: const BoxDecoration(color: vagRed, shape: BoxShape.circle),
                          child: const Icon(Icons.arrow_forward, color: Colors.white, size: 20),
                        ),
                      ],
                    ),
                  ),
                ),
                SizedBox(
                  width: 112,
                  child: ColoredBox(
                    color: const Color(0xFF2a1518),
                    child: Padding(
                      padding: const EdgeInsets.all(6),
                      child: Image.asset('assets/diag-car.png', fit: BoxFit.contain, alignment: Alignment.center),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _CarBlock extends StatelessWidget {
  const _CarBlock({
    required this.car,
    required this.recs,
    required this.onGarage,
    required this.onHistory,
    required this.onRecs,
    required this.onService,
  });

  final Vehicle? car;
  final int recs;
  final VoidCallback onGarage;
  final VoidCallback onHistory;
  final VoidCallback onRecs;
  final VoidCallback onService;

  @override
  Widget build(BuildContext context) {
    if (car == null) {
      return Container(
        decoration: lightPanelDecoration(),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Добавьте автомобиль в гараже', style: TextStyle(fontWeight: FontWeight.w800, color: vagInk)),
            const SizedBox(height: 8),
            FilledButton(onPressed: onGarage, child: const Text('Открыть гараж')),
          ],
        ),
      );
    }
    return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Container(
              decoration: lightPanelDecoration(),
              clipBehavior: Clip.antiAlias,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    height: 108,
                    width: double.infinity,
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        ColoredBox(
                          color: const Color(0xFFEFEFF1),
                          child: Image.asset(
                            'assets/hero-car.png',
                            fit: BoxFit.contain,
                            alignment: Alignment.center,
                          ),
                        ),
                        DecoratedBox(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [Colors.transparent, Colors.black.withValues(alpha: 0.35)],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('${car!.make} ${car!.model}', style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16, color: vagInk)),
                        if (car!.year > 0)
                          Text('${car!.year} · ${NumberFormat.decimalPattern('ru').format(car!.mileage)} км', style: const TextStyle(color: vagMutedInk, fontSize: 12)),
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(border: Border.all(color: vagBorder), borderRadius: BorderRadius.circular(8), color: vagSurface),
                          child: Text(car!.plate, style: const TextStyle(fontWeight: FontWeight.w800, letterSpacing: 1.1, color: vagInk)),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 8),
          SizedBox(
            width: 76,
            child: Column(
              children: [
                _SideAction(icon: Icons.menu_book_outlined, label: 'Сервисбук', onTap: onHistory),
                const SizedBox(height: 8),
                _SideAction(icon: Icons.insights_outlined, label: 'Советы', badge: recs, onTap: onRecs),
                const SizedBox(height: 8),
                _SideAction(icon: Icons.notifications_active_outlined, label: 'Напомнить', onTap: onService, dot: true),
              ],
            ),
          ),
        ],
    );
  }
}

class _SideAction extends StatelessWidget {
  const _SideAction({required this.icon, required this.label, required this.onTap, this.badge = 0, this.dot = false});
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final int badge;
  final bool dot;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: vagCard,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          width: 76,
          height: 76,
          decoration: lightPanelDecoration(radius: 12),
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(icon, color: vagRed, size: 24),
                  const SizedBox(height: 6),
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      label,
                      maxLines: 1,
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: vagInk),
                    ),
                  ),
                ],
              ),
              if (badge > 0)
                Positioned(
                  right: 0,
                  top: 0,
                  child: CircleAvatar(radius: 8, backgroundColor: vagRed, child: Text('$badge', style: const TextStyle(fontSize: 8, color: Colors.white, fontWeight: FontWeight.w800))),
                ),
              if (dot && badge == 0)
                const Positioned(right: 6, top: 6, child: CircleAvatar(radius: 4, backgroundColor: vagRed)),
            ],
          ),
        ),
      ),
    );
  }
}

class _AlertBanner extends StatelessWidget {
  const _AlertBanner({required this.title, required this.subtitle, required this.onTap});
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: vagRed,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Row(
            children: [
              const Icon(Icons.directions_car, color: Colors.white, size: 20),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13, color: Colors.white)),
                    Text(subtitle, style: TextStyle(fontSize: 11, color: Colors.white.withValues(alpha: 0.85))),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: Colors.white70),
            ],
          ),
        ),
      ),
    );
  }
}
