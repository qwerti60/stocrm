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
  });
  final MockStore store;
  final VoidCallback onOpenBook;
  final VoidCallback onOpenProfile;
  final VoidCallback onOpenGarage;
  final VoidCallback onOpenBranches;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String? _shownAlert;
  final PageController _hero = PageController();
  int _heroPage = 0;

  @override
  void initState() {
    super.initState();
    widget.store.addListener(_onStore);
  }

  void _onStore() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    widget.store.removeListener(_onStore);
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
    final recs = store.recommendations.length;

    return Scaffold(
      backgroundColor: vagSurface,
      body: ListView(
        padding: EdgeInsets.zero,
        children: [
          _HeroBlock(
            controller: _hero,
            page: _heroPage,
            unread: unread,
            onCity: widget.onOpenBranches,
            onNotes: _openNotes,
            onPage: (i) => setState(() => _heroPage = i),
          ),
          Transform.translate(
            offset: const Offset(0, -22),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 28),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      _QuickTile(icon: Icons.search, label: 'Поиск\nпо VIN', badge: store.openTicketCount, onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => VinScreen(store: store)))),
                      _QuickTile(icon: Icons.event_available_outlined, label: 'Запись\nна сервис', onTap: widget.onOpenBook),
                      _QuickTile(icon: Icons.directions_car_outlined, label: 'Моё\nавто', onTap: widget.onOpenGarage),
                      _QuickTile(icon: Icons.settings_outlined, label: 'Каталог\nзапчастей', onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => VinScreen(store: store)))),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Material(
                    color: vagCard,
                    borderRadius: BorderRadius.circular(14),
                    child: InkWell(
                      onTap: () => openAppSearch(context, store),
                      borderRadius: BorderRadius.circular(14),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: vagBorder),
                        ),
                        child: const Row(
                          children: [
                            Icon(Icons.search, color: vagMutedInk, size: 22),
                            SizedBox(width: 10),
                            Expanded(child: Text('Поиск по услугам, филиалам, истории', style: TextStyle(color: vagMutedInk, fontSize: 14))),
                            Icon(Icons.chevron_right, color: vagMutedInk),
                          ],
                        ),
                      ),
                    ),
                  ),
                  if (next != null) ...[
                    const SizedBox(height: 12),
                    _AlertBanner(
                      title: 'Авто в сервисе · ${next.status}',
                      subtitle: '${next.serviceTitle} · ${DateFormat('d MMM, HH:mm', 'ru').format(next.when)}',
                      onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => StatusScreen(store: store, visit: next))),
                    ),
                  ],
                  const SizedBox(height: 18),
                  Row(
                    children: [
                      const Text('Популярные услуги', style: vagSectionTitle),
                      const Spacer(),
                      GestureDetector(
                        onTap: widget.onOpenBook,
                        child: const Text('Все услуги >', style: TextStyle(color: vagMutedInk, fontSize: 13, fontWeight: FontWeight.w600)),
                      ),
                    ],
                  ),
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
                  const SizedBox(height: 16),
                  _DiagPromoBanner(onTap: widget.onOpenBook),
                  const SizedBox(height: 18),
                  Row(
                    children: [
                      const Text('Ваш автомобиль', style: vagSectionTitle),
                      const Spacer(),
                      GestureDetector(
                        onTap: widget.onOpenGarage,
                        child: const Text('Все авто >', style: TextStyle(color: vagMutedInk, fontSize: 13, fontWeight: FontWeight.w600)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  _CarBlock(
                    car: car,
                    recs: recs,
                    onGarage: widget.onOpenGarage,
                    onHistory: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => VisitsScreen(store: store))),
                    onRecs: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => RecommendationsScreen(store: store))),
                    onService: widget.onOpenBook,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
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
      image: 'assets/brand-home.png',
      tags: false,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(colors: [Color(0xFF1A1014), vagBlack], begin: Alignment.topCenter, end: Alignment.bottomCenter),
      ),
      child: SafeArea(
        bottom: false,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
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
              height: 210,
              child: PageView.builder(
                controller: controller,
                itemCount: _slides.length,
                onPageChanged: onPage,
                itemBuilder: (_, i) {
                  final s = _slides[i];
                  return Padding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                    child: Stack(
                      clipBehavior: Clip.none,
                      children: [
                        Positioned(
                          right: -24,
                          top: -6,
                          bottom: 28,
                          width: 240,
                          child: Image.asset(s.image, fit: BoxFit.cover, alignment: Alignment.centerRight),
                        ),
                        if (s.tags) ...[
                          Positioned(right: 0, top: 36, child: _HeroTag(icon: Icons.medical_services_outlined, label: 'ДИАГНОСТИКА')),
                          Positioned(right: 8, top: 72, child: _HeroTag(icon: Icons.settings, label: 'ЗАПЧАСТИ')),
                          Positioned(right: 40, top: 108, child: _HeroTag(icon: Icons.build, label: 'СЕРВИС')),
                          Positioned(right: 0, top: 144, child: _HeroTag(icon: Icons.fact_check_outlined, label: 'ТЕХОБСЛУЖИВАНИЕ')),
                        ],
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            RichText(
                              text: TextSpan(
                                style: vagHeroHeadline,
                                children: [
                                  TextSpan(text: s.title),
                                  TextSpan(text: s.accent, style: const TextStyle(color: vagRed)),
                                ],
                              ),
                            ),
                            const SizedBox(height: 10),
                            SizedBox(
                              width: 210,
                              child: Text(s.sub, style: vagHeroSub.copyWith(color: Colors.white.withValues(alpha: 0.78))),
                            ),
                          ],
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 22),
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

class _HeroTag extends StatelessWidget {
  const _HeroTag({required this.icon, required this.label});
  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.45),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.white12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: vagRed),
          const SizedBox(width: 4),
          Text(label, style: const TextStyle(fontSize: 8, fontWeight: FontWeight.w800, color: Colors.white, letterSpacing: 0.3)),
        ],
      ),
    );
  }
}

class _QuickTile extends StatelessWidget {
  const _QuickTile({required this.icon, required this.label, required this.onTap, this.badge = 0});
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final int badge;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4),
        child: Material(
          color: vagCard,
          elevation: 0,
          shadowColor: Colors.black26,
          borderRadius: BorderRadius.circular(14),
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(14),
            child: Container(
              height: 92,
              decoration: lightPanelDecoration(radius: 14),
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 10),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Stack(
                    clipBehavior: Clip.none,
                    children: [
                      Icon(icon, color: vagRed, size: 26),
                      if (badge > 0)
                        Positioned(
                          right: -10,
                          top: -6,
                          child: CircleAvatar(
                            radius: 8,
                            backgroundColor: vagRed,
                            child: Text('$badge', style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w800, color: Colors.white)),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(label, textAlign: TextAlign.center, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700, height: 1.15, color: vagInk)),
                ],
              ),
            ),
          ),
        ),
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
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: Image.asset(
                  image,
                  width: 72,
                  height: 56,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                    width: 72,
                    height: 56,
                    color: vagBorder,
                    child: Icon(icon, color: vagRed),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Icon(icon, color: vagRed, size: 22),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14, color: vagInk)),
                    const SizedBox(height: 2),
                    Text(
                      price,
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 13,
                        color: priceRed ? vagRed : vagInk,
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
            height: 96,
            child: Stack(
              fit: StackFit.expand,
              children: [
                Positioned(right: 0, top: 0, bottom: 0, width: 200, child: Image.asset('assets/diag-car.png', fit: BoxFit.cover, alignment: Alignment.centerRight)),
                const Positioned(left: 0, top: 0, bottom: 0, width: 6, child: ColoredBox(color: vagRed)),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 14, 100, 12),
                  child: Row(
                    children: [
                      const Expanded(
                        child: Text(
                          'КОМПЛЕКСНАЯ ДИАГНОСТИКА\nБЕСПЛАТНО ПРИ ЗАПИСИ НА СЕРВИС',
                          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 11, height: 1.25),
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
                  height: 100,
                  width: double.infinity,
                  child: Image.asset('assets/brand-home.png', fit: BoxFit.cover, alignment: Alignment.center),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('${car!.make} ${car!.model}', style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15, color: vagInk)),
                      if (car!.year > 0) Text('${car!.year} · ${car!.mileage} км', style: const TextStyle(color: vagMutedInk, fontSize: 12)),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(border: Border.all(color: vagBorder), borderRadius: BorderRadius.circular(8)),
                        child: Text(car!.plate, style: const TextStyle(fontWeight: FontWeight.w800, letterSpacing: 1.2, color: vagInk)),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 8),
        Column(
          children: [
            _SideAction(icon: Icons.description_outlined, label: 'История\nработ', onTap: onHistory),
            const SizedBox(height: 8),
            _SideAction(icon: Icons.insights_outlined, label: 'Рекомен-\nдации', badge: recs, onTap: onRecs),
            const SizedBox(height: 8),
            _SideAction(icon: Icons.notifications_active_outlined, label: 'Следующее\nТО', onTap: onService, dot: true),
          ],
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
          width: 72,
          height: 72,
          decoration: lightPanelDecoration(radius: 12),
          padding: const EdgeInsets.all(8),
          child: Stack(
            children: [
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(icon, color: vagRed, size: 22),
                  const SizedBox(height: 4),
                  Text(label, textAlign: TextAlign.center, style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w700, height: 1.1, color: vagInk)),
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
