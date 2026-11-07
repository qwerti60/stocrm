import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:stocrm_mobile_app/data/mock.dart';
import 'package:stocrm_mobile_app/screens/popular_service_screen.dart';
import 'package:stocrm_mobile_app/screens/recommendations_screen.dart';
import 'package:stocrm_mobile_app/screens/search_sheet.dart';
import 'package:stocrm_mobile_app/screens/status_screen.dart';
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

class _HomeScreenState extends State<HomeScreen> {
  String? _shownAlert;

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

  @override
  Widget build(BuildContext context) {
    _maybeAlert();
    final store = widget.store;
    final next = store.nextVisit;
    final car = store.activeCar;
    final recCount = car == null ? store.recommendations.length : store.recommendationsForCar(car).length;
    final firstName = store.clientName.split(' ').first;

    return Scaffold(
      backgroundColor: vagSurface,
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        children: [
                _FitHomeHeader(
                  name: firstName,
                  onProfile: widget.onOpenProfile,
                  onSearch: () => openAppSearch(context, store),
                ),
                const SizedBox(height: 14),
            if (next != null) ...[
              _AlertBanner(
                title: 'Авто в сервисе · ${next.status}',
                subtitle: '${next.serviceTitle} · ${DateFormat('d MMM, HH:mm', 'ru').format(next.when)}',
                onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => StatusScreen(store: store, visit: next))),
              ),
              const SizedBox(height: 14),
            ],
            _BonusCard(
              points: store.bonus,
              freeServices: recCount,
              onTap: widget.onOpenProfile,
            ),
            const SizedBox(height: 12),
            _ServiceBookCard(
              onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => VisitsScreen(store: store))),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: FilledButton(
                onPressed: widget.onOpenBook,
                style: FilledButton.styleFrom(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  textStyle: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
                ),
                child: const Text('Записаться на СТО'),
              ),
            ),
            const SizedBox(height: 22),
            _HomeSectionTitle(title: 'Акции', onMore: widget.onOpenBook),
            const SizedBox(height: 10),
            _PromoCarousel(store: store, onBook: widget.onOpenBook),
            const SizedBox(height: 22),
            _HomeSectionTitle(
              title: 'Сервисы',
              onMore: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => RecommendationsScreen(store: store, filterCar: car)),
              ),
            ),
            const SizedBox(height: 10),
            _ServicesCarousel(store: store),
            const SizedBox(height: 8),
        ],
      ),
    );
  }
}

class _FitHomeHeader extends StatelessWidget {
  const _FitHomeHeader({
    required this.name,
    required this.onProfile,
    required this.onSearch,
  });

  final String name;
  final VoidCallback onProfile;
  final VoidCallback onSearch;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        GestureDetector(
          onTap: onProfile,
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: const BoxDecoration(color: vagRed, shape: BoxShape.circle),
                alignment: Alignment.center,
                child: const Text('VM', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 13)),
              ),
              const SizedBox(width: 10),
              Text(name, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 18, color: vagInk)),
              const Icon(Icons.chevron_right, color: vagMutedInk, size: 22),
            ],
          ),
        ),
        const Spacer(),
        IconButton(onPressed: onSearch, icon: const Icon(Icons.search, color: vagInk)),
      ],
    );
  }
}

class _BonusCard extends StatelessWidget {
  const _BonusCard({required this.points, required this.freeServices, required this.onTap});

  final int points;
  final int freeServices;
  final VoidCallback onTap;

  ({String tier, int nextGoal, String nextName, int step}) _tier() {
    if (points >= 5000) return (tier: 'Золото', nextGoal: 5000, nextName: 'Золото', step: 3);
    if (points >= 1000) return (tier: 'Серебро', nextGoal: 5000, nextName: 'Золото', step: 2);
    return (tier: 'Бронза', nextGoal: 1000, nextName: 'Серебро', step: 1);
  }

  @override
  Widget build(BuildContext context) {
    final t = _tier();
    final toNext = (t.nextGoal - points).clamp(0, 999999);
    final money = NumberFormat.decimalPattern('ru');
    return Material(
      color: vagCard,
      borderRadius: BorderRadius.circular(16),
      elevation: 0,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: vagBorder),
            boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 10, offset: const Offset(0, 3))],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Expanded(
                    child: Text('Бонусный счёт', style: TextStyle(color: vagMutedInk, fontSize: 13, fontWeight: FontWeight.w600)),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(color: vagSurface, borderRadius: BorderRadius.circular(20), border: Border.all(color: vagBorder)),
                    child: Text(t.tier, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 12)),
                  ),
                ],
              ),
              Text('${money.format(points)} баллов', style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 28, height: 1.05, color: vagInk)),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(3, (i) {
                  final filled = i < t.step;
                  return Container(
                    width: 10,
                    height: 10,
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: filled ? vagRed : vagBorder,
                    ),
                  );
                }),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      toNext > 0 ? '${money.format(toNext)} ₽ до статуса «${t.nextName}»' : 'Максимальный статус',
                      style: const TextStyle(fontSize: 12, color: vagMutedInk, fontWeight: FontWeight.w600),
                    ),
                  ),
                  if (freeServices > 0)
                    Row(
                      children: [
                        const Icon(Icons.card_giftcard, color: vagRed, size: 18),
                        const SizedBox(width: 4),
                        Text(
                          'Вас ждут $freeServices ${freeServices == 1 ? 'услуга' : 'услуги'}',
                          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: vagRed),
                        ),
                      ],
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ServiceBookCard extends StatelessWidget {
  const _ServiceBookCard({required this.onTap});

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
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: vagBorder),
          ),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(color: const Color(0xFFE8F5E9), borderRadius: BorderRadius.circular(20)),
                child: const Icon(Icons.description_outlined, color: Color(0xFF2E7D32)),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Электронный сервисбук', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14)),
                    SizedBox(height: 2),
                    Text('Заказ-наряды и PDF', style: TextStyle(color: vagMutedInk, fontSize: 12)),
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

class _HomeSectionTitle extends StatelessWidget {
  const _HomeSectionTitle({required this.title, required this.onMore});

  final String title;
  final VoidCallback onMore;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(title, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 18, color: vagInk)),
        const Spacer(),
        IconButton(onPressed: onMore, icon: const Icon(Icons.chevron_right, color: vagMutedInk), padding: EdgeInsets.zero),
      ],
    );
  }
}

class _PromoCarousel extends StatelessWidget {
  const _PromoCarousel({required this.store, required this.onBook});

  final MockStore store;
  final VoidCallback onBook;

  static const _colors = [vagRed, Color(0xFF1E3A5F), Color(0xFF5B8DEF)];

  @override
  Widget build(BuildContext context) {
    final items = store.promos;
    return SizedBox(
      height: 148,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: items.length,
        separatorBuilder: (_, __) => const SizedBox(width: 10),
        itemBuilder: (_, i) {
          final p = items[i];
          final bg = _colors[i % _colors.length];
          return GestureDetector(
            onTap: onBook,
            child: Container(
              width: 168,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: bg,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [BoxShadow(color: bg.withValues(alpha: 0.35), blurRadius: 8, offset: const Offset(0, 4))],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(p.title, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 14, height: 1.2)),
                  const Spacer(),
                  if (p.badge.isNotEmpty)
                    Text(p.badge, style: TextStyle(color: Colors.white.withValues(alpha: 0.9), fontWeight: FontWeight.w700, fontSize: 12)),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _ServicesCarousel extends StatelessWidget {
  const _ServicesCarousel({required this.store});

  final MockStore store;

  @override
  Widget build(BuildContext context) {
    final services = store.popularServices;
    return SizedBox(
      height: 120,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: services.length,
        separatorBuilder: (_, __) => const SizedBox(width: 10),
        itemBuilder: (_, i) {
          final s = services[i];
          return GestureDetector(
            onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => PopularServiceScreen(store: store, service: s))),
            child: Container(
              width: 260,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: vagCard,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: vagBorder),
              ),
              child: Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.asset(
                      s.image.isNotEmpty ? s.image : 'assets/offer-oil.png',
                      width: 72,
                      height: 72,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => ColoredBox(color: vagSurface, child: Icon(_popularServiceIcon(s), color: vagRed)),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(s.title, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14)),
                        const SizedBox(height: 4),
                        Text(s.price, style: TextStyle(fontWeight: FontWeight.w700, color: s.price.toLowerCase().contains('бесплат') ? vagRed : vagMutedInk, fontSize: 13)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
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
