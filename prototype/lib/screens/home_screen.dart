import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:stocrm_mobile_app/data/mock.dart';
import 'package:stocrm_mobile_app/screens/chat_screen.dart';
import 'package:stocrm_mobile_app/screens/recommendations_screen.dart';
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
  });
  final MockStore store;
  final VoidCallback onOpenBook;
  final VoidCallback onOpenProfile;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String q = '';

  List<_Hit> get _hits {
    if (q.trim().isEmpty) return const [];
    final n = q.toLowerCase();
    final out = <_Hit>[];
    for (final s in widget.store.services) {
      if ('${s.title} ${s.subtitle}'.toLowerCase().contains(n)) {
        out.add(_Hit(s.title, s.subtitle, widget.onOpenBook));
      }
    }
    for (final b in widget.store.branches) {
      if ('${b.name} ${b.address}'.toLowerCase().contains(n)) {
        out.add(_Hit(b.name, b.address, widget.onOpenBook));
      }
    }
    for (final v in widget.store.visits) {
      final blob = '${v.serviceTitle} ${v.works.join(' ')} ${v.parts.join(' ')}'.toLowerCase();
      if (blob.contains(n)) {
        out.add(_Hit(v.serviceTitle, v.branchName, () {
          Navigator.of(context).push(MaterialPageRoute(builder: (_) => VisitsScreen(store: widget.store)));
        }));
      }
    }
    return out.take(6).toList();
  }

  @override
  Widget build(BuildContext context) {
    final store = widget.store;
    final next = store.nextVisit;
    final car = store.activeCar;
    final kmLeft = car == null ? 0 : (car.nextServiceKm ?? car.mileage) - car.mileage;
    return Scaffold(
      body: ListView(
        padding: EdgeInsets.zero,
        children: [
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF1A0A0C), vagBlack],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('VAG MARKET', style: TextStyle(color: vagRed, fontWeight: FontWeight.w900, fontSize: 22, letterSpacing: 0.4)),
                              Text('СЕРВИС · ЗАПЧАСТИ · ЗАБОТА О VAG', style: TextStyle(color: vagMuted, fontSize: 9, letterSpacing: 0.6, fontWeight: FontWeight.w600)),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(color: vagCard, borderRadius: BorderRadius.circular(20)),
                          child: const Row(
                            children: [
                              Icon(Icons.location_on_outlined, size: 14, color: vagRed),
                              SizedBox(width: 4),
                              Text('Тюмень', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        GestureDetector(
                          onTap: widget.onOpenProfile,
                          child: const CircleAvatar(radius: 14, backgroundColor: vagRed, child: Text('5', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800))),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        const Expanded(
                          child: Text('ВАШ VAG\nВ НАДЁЖНЫХ РУКАХ', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, height: 1.15)),
                        ),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.asset('assets/brand-home.png', width: 132, height: 88, fit: BoxFit.cover, alignment: Alignment.topRight),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    const Row(
                      children: [
                        _BrandDot(label: 'VW'),
                        _BrandDot(label: 'Audi'),
                        _BrandDot(label: 'SEAT'),
                        _BrandDot(label: 'Škoda'),
                      ],
                    ),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 28),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  decoration: const InputDecoration(prefixIcon: Icon(Icons.search), hintText: 'Поиск по услугам, филиалам, истории'),
                  onChanged: (v) => setState(() => q = v),
                ),
                if (_hits.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  ..._hits.map(
                    (h) => Card(
                      child: ListTile(
                        dense: true,
                        title: Text(h.title, style: const TextStyle(fontWeight: FontWeight.w700)),
                        subtitle: Text(h.subtitle, style: const TextStyle(color: vagMuted, fontSize: 12)),
                        onTap: h.onTap,
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: 12),
                _StatusCard(
                  carTitle: car?.title ?? 'Гараж пуст',
                  plate: car?.plate.isNotEmpty == true ? car!.plate : 'авто подтянется из CRM',
                  next: next,
                  kmLeft: kmLeft,
                  onStatus: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => StatusScreen(store: store))),
                  onBook: widget.onOpenBook,
                ),
                const SizedBox(height: 10),
                _Cta(
                  icon: Icons.search,
                  title: 'Подобрать запчасти по VIN',
                  subtitle: 'Заявка уходит менеджеру, не витрина склада',
                  filled: false,
                  onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => VinScreen(store: store))),
                ),
                const SizedBox(height: 10),
                _Cta(
                  icon: Icons.calendar_month,
                  title: 'Записаться на сервис',
                  subtitle: 'Авто → филиал → слот · ждите подтверждения',
                  filled: true,
                  onTap: widget.onOpenBook,
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    _Quick(icon: Icons.settings, label: 'Каталог\nзапчастей', onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => VinScreen(store: store)))),
                    _Quick(icon: Icons.build, label: 'Услуги\nсервиса', onTap: widget.onOpenBook),
                    _Quick(icon: Icons.fact_check_outlined, label: 'Техобслуживание', onTap: widget.onOpenBook),
                    _Quick(
                      icon: Icons.tips_and_updates_outlined,
                      label: 'Рекомендации',
                      onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => RecommendationsScreen(store: store))),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    const Text('//  РЕКОМЕНДАЦИИ ИЗ CRM', style: TextStyle(fontWeight: FontWeight.w800, letterSpacing: 0.6, fontSize: 13)),
                    const Spacer(),
                    GestureDetector(
                      onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => RecommendationsScreen(store: store))),
                      child: const Text('Все ›', style: TextStyle(color: vagMuted, fontSize: 12)),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                ...store.recommendations.take(2).map(
                      (r) => Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        child: ListTile(
                          leading: const Icon(Icons.tips_and_updates_outlined, color: vagRed),
                          title: Text(r, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                          trailing: const Icon(Icons.chevron_right, color: vagMuted),
                          onTap: widget.onOpenBook,
                        ),
                      ),
                    ),
                const SizedBox(height: 8),
                const Row(
                  children: [
                    Text('//  СПЕЦПРЕДЛОЖЕНИЯ', style: TextStyle(fontWeight: FontWeight.w800, letterSpacing: 0.6)),
                    Spacer(),
                    Text('Массовый push из админки', style: TextStyle(color: vagMuted, fontSize: 11)),
                  ],
                ),
                const SizedBox(height: 10),
                const SizedBox(
                  height: 148,
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        _OfferCard(title: 'Замена масла', price: 'от 4 990 ₽', note: 'Масло + фильтр + работа'),
                        _OfferCard(title: 'Тормозные колодки', price: 'от 6 900 ₽', note: 'Оригинал / аналог'),
                        _OfferCard(title: 'Замена ГРМ', price: 'от 14 900 ₽', note: 'Регламент VAG'),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(child: _Mini(icon: Icons.card_giftcard, title: 'Бонусная программа', subtitle: '5% с закрытого ЗН', color: vagRed, onTap: widget.onOpenProfile)),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _Mini(
                        icon: Icons.description_outlined,
                        title: 'Электронный сервисбук',
                        subtitle: 'История работ',
                        color: vagCard,
                        onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => VisitsScreen(store: store))),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _Mini(
                        icon: Icons.chat_bubble_outline,
                        title: 'Чат с менеджером',
                        subtitle: 'Егор, VAG Market',
                        color: vagCard,
                        onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => ChatScreen(store: store))),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                const _WidgetPreview(),
                const SizedBox(height: 12),
                ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(colors: [Color(0xFF2A0A10), vagRed]),
                    ),
                    child: const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('ДИАГНОСТИКА VAG\nБЕСПЛАТНО', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16, height: 1.15)),
                        SizedBox(height: 4),
                        Text('При первом визите · push по акциям из админки', style: TextStyle(color: Colors.white70, fontSize: 12)),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Hit {
  const _Hit(this.title, this.subtitle, this.onTap);
  final String title;
  final String subtitle;
  final VoidCallback onTap;
}

class _StatusCard extends StatelessWidget {
  const _StatusCard({
    required this.carTitle,
    required this.plate,
    required this.next,
    required this.kmLeft,
    required this.onStatus,
    required this.onBook,
  });
  final String carTitle;
  final String plate;
  final Visit? next;
  final int kmLeft;
  final VoidCallback onStatus;
  final VoidCallback onBook;

  @override
  Widget build(BuildContext context) {
    final inService = next != null;
    final title = inService ? 'Авто в сервисе · ${next!.status}' : (kmLeft <= 0 ? 'Пора на ТО' : 'Всё в порядке');
    final sub = inService
        ? '${next!.serviceTitle} · ${DateFormat('d MMM, HH:mm', 'ru').format(next!.when)}'
        : (kmLeft <= 0 ? 'Рекомендация из CRM: запишитесь на обслуживание' : 'До ТО ≈ $kmLeft км · $carTitle');
    return Material(
      color: inService ? vagRed : vagCard,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: inService ? onStatus : onBook,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Icon(inService ? Icons.directions_car : Icons.check_circle_outline, color: Colors.white),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: const TextStyle(fontWeight: FontWeight.w800)),
                    Text('$plate · $sub', style: TextStyle(fontSize: 12, color: Colors.white.withValues(alpha: 0.75))),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right),
            ],
          ),
        ),
      ),
    );
  }
}

class _WidgetPreview extends StatelessWidget {
  const _WidgetPreview();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: vagCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF2A2A2E)),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Виджет на главном экране', style: TextStyle(fontWeight: FontWeight.w800)),
          SizedBox(height: 4),
          Text('Состояния: всё в порядке · пора на ТО · авто в сервисе · машина готова. Тап открывает запись / статус.', style: TextStyle(color: vagMuted, fontSize: 12, height: 1.35)),
        ],
      ),
    );
  }
}

class _BrandDot extends StatelessWidget {
  const _BrandDot({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 10),
      child: Column(
        children: [
          const CircleAvatar(radius: 14, backgroundColor: vagCard, child: Icon(Icons.directions_car, size: 14)),
          const SizedBox(height: 4),
          Text(label, style: const TextStyle(fontSize: 8, color: vagMuted)),
        ],
      ),
    );
  }
}

class _Cta extends StatelessWidget {
  const _Cta({required this.icon, required this.title, required this.subtitle, required this.filled, required this.onTap});
  final IconData icon;
  final String title;
  final String subtitle;
  final bool filled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: filled ? vagRed : vagCard,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          child: Row(
            children: [
              Icon(icon, color: Colors.white),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: const TextStyle(fontWeight: FontWeight.w800)),
                    Text(subtitle, style: TextStyle(fontSize: 12, color: Colors.white.withValues(alpha: 0.75))),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right),
            ],
          ),
        ),
      ),
    );
  }
}

class _Quick extends StatelessWidget {
  const _Quick({required this.icon, required this.label, required this.onTap});
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(14),
          child: Container(
            height: 88,
            decoration: BoxDecoration(color: vagCard, borderRadius: BorderRadius.circular(14)),
            padding: const EdgeInsets.all(8),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, color: Colors.white, size: 22),
                const SizedBox(height: 6),
                Text(label, textAlign: TextAlign.center, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600, height: 1.15)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Mini extends StatelessWidget {
  const _Mini({required this.icon, required this.title, required this.subtitle, required this.color, required this.onTap});
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: color,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, size: 20),
              const SizedBox(height: 8),
              Text(title, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 11, height: 1.2)),
              const SizedBox(height: 4),
              Text(subtitle, style: const TextStyle(fontSize: 10, color: Colors.white70)),
            ],
          ),
        ),
      ),
    );
  }
}

class _OfferCard extends StatelessWidget {
  const _OfferCard({required this.title, required this.price, required this.note});
  final String title;
  final String price;
  final String note;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 168,
      height: 148,
      margin: const EdgeInsets.only(right: 10),
      decoration: BoxDecoration(color: vagCard, borderRadius: BorderRadius.circular(16)),
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontWeight: FontWeight.w800)),
          const Spacer(),
          Text(price, style: const TextStyle(color: vagRed, fontWeight: FontWeight.w800)),
          Text(note, style: const TextStyle(fontSize: 11, color: vagMuted)),
        ],
      ),
    );
  }
}
