import 'package:flutter/material.dart';
import 'package:stocrm_mobile_app/data/mock.dart';
import 'package:stocrm_mobile_app/screens/booking_flow.dart';

class BookScreen extends StatelessWidget {
  const BookScreen({super.key, required this.store});
  final MockStore store;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Запись', style: TextStyle(fontWeight: FontWeight.w800))),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
        children: [
          const Text('Выберите услугу — слот уйдёт в STOCRM как сделка «Онлайн-запись».'),
          const SizedBox(height: 12),
          ...store.services.map((s) => Card(
                margin: const EdgeInsets.only(bottom: 8),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: const Color(0xFFFFEDD5),
                    child: Icon(_icon(s.icon), color: const Color(0xFFEA580C)),
                  ),
                  title: Text(s.title, style: const TextStyle(fontWeight: FontWeight.w700)),
                  subtitle: Text('${s.subtitle}\n${s.durationMin} мин · ${s.priceFrom == 0 ? 'оценка' : 'от ${s.priceFrom} ₽'}'),
                  isThreeLine: true,
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => Navigator.of(context).push(MaterialPageRoute(
                    builder: (_) => BookingFlow(store: store, initialService: s),
                  )),
                ),
              )),
        ],
      ),
    );
  }
}

IconData _icon(String key) {
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
