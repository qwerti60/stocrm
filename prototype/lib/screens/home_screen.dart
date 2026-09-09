import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:stocrm_mobile_app/data/mock.dart';
import 'package:stocrm_mobile_app/screens/booking_flow.dart';
import 'package:stocrm_mobile_app/screens/branches_screen.dart';
import 'package:stocrm_mobile_app/screens/chat_screen.dart';
import 'package:stocrm_mobile_app/screens/status_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key, required this.store, required this.onOpenBook});
  final MockStore store;
  final VoidCallback onOpenBook;

  @override
  Widget build(BuildContext context) {
    final car = store.activeCar;
    final next = store.nextVisit;
    final df = DateFormat('d MMM, HH:mm', 'ru');
    final kmLeft = (car.nextServiceKm ?? car.mileage) - car.mileage;

    return Scaffold(
      appBar: AppBar(
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('DRIVE СТО', style: TextStyle(fontWeight: FontWeight.w800)),
            Text('Онлайн-запись · STOCRM', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w400)),
          ],
        ),
        actions: [
          IconButton(
            onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => ChatScreen(store: store))),
            icon: const Icon(Icons.chat_bubble_outline),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(22),
              gradient: const LinearGradient(
                colors: [Color(0xFF0B1F33), Color(0xFF1E3A5F), Color(0xFFEA580C)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('${car.make} ${car.model} · ${car.plate}', style: TextStyle(color: Colors.white.withValues(alpha: 0.85), fontSize: 13)),
                const SizedBox(height: 6),
                const Text('Запись за пару минут', style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w800)),
                const SizedBox(height: 6),
                Text(
                  kmLeft > 0 ? 'До ТО ≈ ${NumberFormat.decimalPattern('ru').format(kmLeft)} км' : 'Пора на ТО',
                  style: TextStyle(color: Colors.white.withValues(alpha: 0.9)),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    FilledButton.tonal(
                      style: FilledButton.styleFrom(backgroundColor: Colors.white, foregroundColor: const Color(0xFFEA580C)),
                      onPressed: onOpenBook,
                      child: const Text('Записаться'),
                    ),
                    const SizedBox(width: 10),
                    OutlinedButton(
                      style: OutlinedButton.styleFrom(foregroundColor: Colors.white, side: const BorderSide(color: Colors.white70)),
                      onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => BranchesScreen(store: store))),
                      child: const Text('На карте'),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          if (next != null)
            Card(
              child: ListTile(
                contentPadding: const EdgeInsets.all(14),
                leading: CircleAvatar(
                  backgroundColor: const Color(0xFFFFEDD5),
                  foregroundColor: const Color(0xFFEA580C),
                  child: const Icon(Icons.event_available),
                ),
                title: const Text('Ближайшая запись', style: TextStyle(fontWeight: FontWeight.w700)),
                subtitle: Text('${next.serviceTitle}\n${next.branchName} · ${df.format(next.when)}'),
                isThreeLine: true,
                trailing: Chip(label: Text(next.status, style: const TextStyle(fontSize: 11))),
                onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => StatusScreen(store: store))),
              ),
            ),
          const SizedBox(height: 14),
          Text('Популярные услуги', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800)),
          const SizedBox(height: 8),
          SizedBox(
            height: 118,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: store.services.length,
              separatorBuilder: (_, _) => const SizedBox(width: 10),
              itemBuilder: (_, i) {
                final s = store.services[i];
                return SizedBox(
                  width: 168,
                  child: Card(
                    child: InkWell(
                      borderRadius: BorderRadius.circular(16),
                      onTap: () => Navigator.of(context).push(MaterialPageRoute(
                        builder: (_) => BookingFlow(store: store, initialService: s),
                      )),
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(_serviceIcon(s.icon), color: const Color(0xFFEA580C)),
                            const Spacer(),
                            Text(s.title, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w700)),
                            Text(s.priceFrom == 0 ? 'по осмотру' : 'от ${s.priceFrom} ₽', style: TextStyle(fontSize: 12, color: Colors.grey.shade700)),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 16),
          Text('Рекомендации', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800)),
          const SizedBox(height: 8),
          ...store.recommendations.map(
            (r) => Card(
              margin: const EdgeInsets.only(bottom: 8),
              child: ListTile(
                leading: const Icon(Icons.tips_and_updates_outlined, color: Color(0xFFEA580C)),
                title: Text(r, style: const TextStyle(fontSize: 14)),
                trailing: const Icon(Icons.chevron_right),
                onTap: onOpenBook,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text('Акции', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800)),
          const SizedBox(height: 8),
          ...store.promos.map(
            (p) => Card(
              margin: const EdgeInsets.only(bottom: 8),
              color: const Color(0xFFFFF7ED),
              child: ListTile(
                title: Text(p.title, style: const TextStyle(fontWeight: FontWeight.w700)),
                subtitle: Text(p.subtitle),
                trailing: Chip(label: Text(p.badge, style: const TextStyle(fontSize: 11))),
              ),
            ),
          ),
          Card(
            color: const Color(0xFFECFDF5),
            child: const Padding(
              padding: EdgeInsets.all(14),
              child: Text(
                'Прототип на mock-данных. В продакшене заявка создаёт сделку в вашей STOCRM (источник «Онлайн-запись»).',
                style: TextStyle(height: 1.4),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

IconData _serviceIcon(String key) {
  switch (key) {
    case 'search':
      return Icons.search;
    case 'oil':
      return Icons.water_drop_outlined;
    case 'tire':
      return Icons.tire_repair;
    case 'brake':
      return Icons.disc_full_outlined;
    case 'body':
      return Icons.car_crash_outlined;
    default:
      return Icons.build_outlined;
  }
}
