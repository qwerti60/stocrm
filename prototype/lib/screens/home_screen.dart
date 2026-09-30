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
            child: Text('Нет новых уведомлений', style: TextStyle(color: vagMuted)),
          );
        }
        return SafeArea(
          child: ListView(
            shrinkWrap: true,
            padding: const EdgeInsets.fromLTRB(8, 12, 8, 24),
            children: [
              const Padding(
                padding: EdgeInsets.fromLTRB(16, 8, 16, 8),
                child: Text('Уведомления', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
              ),
              for (final note in notes)
                ListTile(
                  leading: const Icon(Icons.notifications_active, color: vagRed),
                  title: Text(note.title, style: const TextStyle(fontWeight: FontWeight.w800)),
                  subtitle: Text(note.body, style: const TextStyle(color: vagMuted, fontSize: 12)),
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
    return Scaffold(
      body: ListView(
        padding: EdgeInsets.zero,
        children: [
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF141018), vagBlack],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 6, 16, 4),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              VagWordmark(size: 24),
                              SizedBox(height: 4),
                              Text(
                                'СЕРВИС · ЗАПЧАСТИ · ЗАБОТА О VAG',
                                style: TextStyle(color: vagMuted, fontSize: 8, letterSpacing: 0.5, fontWeight: FontWeight.w600),
                              ),
                            ],
                          ),
                        ),
                        GestureDetector(
                          onTap: widget.onOpenBranches,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                            decoration: BoxDecoration(color: vagCard, borderRadius: BorderRadius.circular(20)),
                            child: const Row(
                              children: [
                                Icon(Icons.location_on, size: 14, color: vagRed),
                                SizedBox(width: 4),
                                Text('Тюмень', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                                SizedBox(width: 2),
                                Icon(Icons.keyboard_arrow_down, size: 16, color: vagMuted),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        GestureDetector(
                          onTap: _openNotes,
                          child: Stack(
                            clipBehavior: Clip.none,
                            children: [
                              Container(
                                width: 36,
                                height: 36,
                                decoration: BoxDecoration(color: vagCard, borderRadius: BorderRadius.circular(18)),
                                child: const Icon(Icons.notifications_none, size: 20),
                              ),
                              if (unread > 0)
                                Positioned(
                                  right: -2,
                                  top: -2,
                                  child: CircleAvatar(
                                    radius: 8,
                                    backgroundColor: vagRed,
                                    child: Text('$unread', style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w800)),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    SizedBox(
                      height: 168,
                      child: Stack(
                        clipBehavior: Clip.none,
                        children: [
                          Positioned(
                            right: -20,
                            top: -8,
                            bottom: 0,
                            width: 230,
                            child: Image.asset('assets/hero-car.png', fit: BoxFit.cover, alignment: Alignment.centerRight),
                          ),
                          const Positioned(
                            right: 0,
                            bottom: 10,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text('БОЛЬШЕ', style: TextStyle(fontSize: 8, fontWeight: FontWeight.w800, letterSpacing: 0.8)),
                                Padding(
                                  padding: EdgeInsets.symmetric(vertical: 3),
                                  child: SizedBox(width: 46, height: 2, child: ColoredBox(color: vagRed)),
                                ),
                                Text('ЧЕМ СЕРВИС', style: TextStyle(fontSize: 8, fontWeight: FontWeight.w800, letterSpacing: 0.5)),
                              ],
                            ),
                          ),
                          const Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Padding(
                                    padding: EdgeInsets.only(top: 4),
                                    child: Text('//', style: TextStyle(color: vagRed, fontWeight: FontWeight.w900, fontSize: 16, fontStyle: FontStyle.italic)),
                                  ),
                                  SizedBox(width: 8),
                                  Text(
                                    'ВАШ VAG\nВ НАДЁЖНЫХ РУКАХ',
                                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, height: 1.15),
                                  ),
                                ],
                              ),
                              SizedBox(height: 18),
                              Row(
                                children: [
                                  _MakerAsset('assets/brand-vw.png'),
                                  _MakerAsset('assets/brand-audi.png'),
                                  _MakerAsset('assets/brand-seat.png'),
                                  _MakerAsset('assets/brand-skoda.png'),
                                ],
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (next != null) ...[
                  _ServiceChip(
                    title: 'Авто в сервисе · ${next.status}',
                    subtitle: '${next.serviceTitle} · ${DateFormat('d MMM, HH:mm', 'ru').format(next.when)}',
                    onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => StatusScreen(store: store, visit: next))),
                  ),
                  const SizedBox(height: 10),
                ],
                if (store.recommendations.isNotEmpty) ...[
                  _ServiceChip(
                    title: 'Рекомендации по ремонту · ${store.recommendations.length}',
                    subtitle: 'Лампа активна, пока есть работы по вашим авто',
                    onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => RecommendationsScreen(store: store))),
                  ),
                  const SizedBox(height: 10),
                ],
                _Cta(
                  icon: Icons.directions_car_outlined,
                  overlay: Icons.search,
                  title: 'Подобрать запчасти по VIN',
                  subtitle: store.vinTicketCount > 0 ? 'Заявок: ${store.vinTicketCount}' : 'Точные детали для вашего автомобиля',
                  filled: false,
                  badge: store.vinTicketCount,
                  onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => VinScreen(store: store))),
                ),
                const SizedBox(height: 10),
                _Cta(
                  icon: Icons.calendar_today_outlined,
                  title: 'Записаться на сервис',
                  subtitle: 'Быстро, удобно, онлайн',
                  filled: true,
                  onTap: widget.onOpenBook,
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    _Quick(
                      icon: Icons.settings_outlined,
                      title: 'Каталог\nзапчастей',
                      subtitle: 'Оригинал и аналоги',
                      onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => VinScreen(store: store))),
                    ),
                    _Quick(icon: Icons.build_outlined, title: 'Услуги\nсервиса', subtitle: 'Полный спектр', onTap: widget.onOpenBook),
                    _Quick(icon: Icons.fact_check_outlined, title: 'Техобслуживание', subtitle: 'Регламент VAG', onTap: widget.onOpenBook),
                    _Quick(
                      icon: store.recommendations.isEmpty ? Icons.lightbulb_outline : Icons.lightbulb,
                      title: 'Рекомендации\nпо ремонту',
                      subtitle: store.recommendations.isEmpty ? 'Пока нет' : '${store.recommendations.length} активных',
                      badge: store.recommendations.length,
                      onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => RecommendationsScreen(store: store))),
                    ),
                  ],
                ),
                const SizedBox(height: 22),
                Row(
                  children: [
                    const Text('//  ', style: TextStyle(color: vagRed, fontWeight: FontWeight.w900, fontStyle: FontStyle.italic)),
                    const Text('СПЕЦПРЕДЛОЖЕНИЯ', style: TextStyle(fontWeight: FontWeight.w800, letterSpacing: 0.6, fontSize: 13)),
                    const Spacer(),
                    const Text('Все акции', style: TextStyle(color: vagMuted, fontSize: 12)),
                  ],
                ),
                const SizedBox(height: 12),
                SizedBox(
                  height: 196,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    children: [
                      for (final p in store.promos) _OfferCard(promo: p, onTap: widget.onOpenBook),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: _Mini(
                        icon: Icons.card_giftcard,
                        title: 'Бонусная программа',
                        subtitle: 'Копите баллы и получайте выгоду',
                        color: vagRed,
                        onTap: widget.onOpenProfile,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _Mini(
                        icon: Icons.description_outlined,
                        title: 'Электронный сервисбук',
                        subtitle: 'Вся история работ в вашем телефоне',
                        color: vagCard,
                        onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => VisitsScreen(store: store))),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _Mini(
                        icon: Icons.chat_bubble_outline,
                        title: 'ЧАТ С МЕНЕДЖЕРОМ',
                        subtitle: 'Онлайн-чат',
                        color: const Color(0xFFF3F3F5),
                        dark: true,
                        badge: store.unreadChat,
                        onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => ChatScreen(store: store))),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: GestureDetector(
                    onTap: widget.onOpenBook,
                    child: SizedBox(
                      height: 108,
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          const ColoredBox(color: Color(0xFF1A0508)),
                          Positioned(
                            right: 0,
                            top: 0,
                            bottom: 0,
                            width: 220,
                            child: Image.asset('assets/diag-car.png', fit: BoxFit.cover, alignment: Alignment.centerRight),
                          ),
                          const Positioned(
                            left: 0,
                            top: 0,
                            bottom: 0,
                            width: 18,
                            child: ColoredBox(color: vagRed),
                          ),
                          const Padding(
                            padding: EdgeInsets.fromLTRB(28, 18, 120, 16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('ДИАГНОСТИКА VAG', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 15, letterSpacing: 0.2)),
                                Text('БЕСПЛАТНО', style: TextStyle(color: vagRed, fontWeight: FontWeight.w900, fontSize: 20, height: 1.05)),
                                Spacer(),
                                Text('При первом визите', style: TextStyle(color: Colors.white70, fontSize: 12)),
                              ],
                            ),
                          ),
                        ],
                      ),
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

class _MakerAsset extends StatelessWidget {
  const _MakerAsset(this.asset);
  final String asset;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 10),
      child: Image.asset(asset, height: 48, filterQuality: FilterQuality.high),
    );
  }
}

class _ServiceChip extends StatelessWidget {
  const _ServiceChip({required this.title, required this.subtitle, required this.onTap});
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
              const Icon(Icons.directions_car, size: 20),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13)),
                    Text(subtitle, style: TextStyle(fontSize: 11, color: Colors.white.withValues(alpha: 0.75))),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, size: 18),
            ],
          ),
        ),
      ),
    );
  }
}

class _Cta extends StatelessWidget {
  const _Cta({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.filled,
    required this.onTap,
    this.overlay,
    this.badge = 0,
  });
  final IconData icon;
  final IconData? overlay;
  final String title;
  final String subtitle;
  final bool filled;
  final VoidCallback onTap;
  final int badge;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: filled ? vagRed : vagCard,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          child: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: filled ? Colors.white.withValues(alpha: 0.14) : const Color(0xFF222226),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Icon(icon, color: Colors.white, size: 22),
                    if (overlay != null)
                      const Positioned(
                        right: 5,
                        bottom: 5,
                        child: Icon(Icons.search, size: 12, color: Colors.white70),
                      ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14)),
                    Text(subtitle, style: TextStyle(fontSize: 11, color: Colors.white.withValues(alpha: 0.7))),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: Colors.white54),
              if (badge > 0) ...[
                const SizedBox(width: 4),
                CircleAvatar(radius: 10, backgroundColor: filled ? Colors.white : vagRed, child: Text('$badge', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: filled ? vagRed : Colors.white))),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _Quick extends StatelessWidget {
  const _Quick({required this.icon, required this.title, required this.subtitle, required this.onTap, this.badge = 0});
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final int badge;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 3),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Container(
            height: 108,
            decoration: BoxDecoration(color: vagCard, borderRadius: BorderRadius.circular(16)),
            padding: const EdgeInsets.fromLTRB(6, 12, 6, 8),
            child: Column(
              children: [
                Icon(icon, color: badge > 0 ? vagRed : Colors.white, size: 22),
                if (badge > 0)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: CircleAvatar(radius: 9, backgroundColor: vagRed, child: Text('$badge', style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w800))),
                  ),
                const SizedBox(height: 8),
                Text(title, textAlign: TextAlign.center, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, height: 1.15)),
                const Spacer(),
                Text(subtitle, textAlign: TextAlign.center, style: const TextStyle(fontSize: 9, color: vagMuted, height: 1.15)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Mini extends StatelessWidget {
  const _Mini({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.onTap,
    this.dark = false,
    this.badge = 0,
  });
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final bool dark;
  final int badge;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final fg = dark ? vagBlack : Colors.white;
    return Material(
      color: color,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: SizedBox(
          height: 124,
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(icon, size: 22, color: fg),
                    const Spacer(),
                    if (badge > 0)
                      CircleAvatar(radius: 9, backgroundColor: vagRed, child: Text('$badge', style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: Colors.white))),
                  ],
                ),
                const SizedBox(height: 10),
                Text(title, style: TextStyle(fontWeight: FontWeight.w800, fontSize: 12, height: 1.15, color: fg)),
                const Spacer(),
                Text(subtitle, style: TextStyle(fontSize: 10, height: 1.25, color: dark ? const Color(0xFF5A5A5A) : Colors.white70)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _OfferCard extends StatelessWidget {
  const _OfferCard({required this.promo, required this.onTap});
  final Promo promo;
  final VoidCallback onTap;

  String? get _asset {
    final t = promo.title.toLowerCase();
    if (t.contains('масл')) return 'assets/offer-oil.png';
    if (t.contains('колод') || t.contains('тормоз')) return 'assets/offer-brakes.png';
    if (t.contains('грм') || t.contains('ремн')) return 'assets/offer-timing.png';
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final asset = _asset;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 158,
        margin: const EdgeInsets.only(right: 10),
        decoration: BoxDecoration(color: const Color(0xFFF4F4F6), borderRadius: BorderRadius.circular(16)),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              height: 92,
              width: double.infinity,
              child: asset == null && promo.imageUrl == null
                  ? const ColoredBox(color: Color(0xFF1A1A1E), child: Icon(Icons.local_offer, color: Colors.white54))
                  : Image(
                      image: promo.imageUrl != null ? NetworkImage(promo.imageUrl!) : AssetImage(asset!) as ImageProvider,
                      fit: BoxFit.cover,
                      alignment: Alignment.bottomCenter,
                    ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(10, 8, 8, 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(promo.title, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(color: vagBlack, fontWeight: FontWeight.w800, fontSize: 12, height: 1.15)),
                    const Spacer(),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            promo.badge,
                            style: const TextStyle(color: vagRed, fontWeight: FontWeight.w800, fontSize: 13),
                          ),
                        ),
                        Container(
                          width: 22,
                          height: 22,
                          decoration: const BoxDecoration(color: vagRed, shape: BoxShape.circle),
                          child: const Icon(Icons.chevron_right, size: 16, color: Colors.white),
                        ),
                      ],
                    ),
                    if (promo.subtitle.isNotEmpty)
                      Text(promo.subtitle, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 9, color: Color(0xFF6A6A6A))),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
