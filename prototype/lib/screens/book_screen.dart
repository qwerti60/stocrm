import 'package:flutter/material.dart';
import 'package:stocrm_mobile_app/data/mock.dart';
import 'package:stocrm_mobile_app/screens/booking_flow.dart';
import 'package:stocrm_mobile_app/theme.dart';

class BookScreen extends StatefulWidget {
  const BookScreen({super.key, required this.store});
  final MockStore store;

  @override
  State<BookScreen> createState() => _BookScreenState();
}

class _BookScreenState extends State<BookScreen> {
  String q = '';

  @override
  Widget build(BuildContext context) {
    final store = widget.store;
    final services = store.services.where((s) {
      if (q.isEmpty) return true;
      return '${s.title} ${s.subtitle}'.toLowerCase().contains(q.toLowerCase());
    }).toList();
    return Scaffold(
      appBar: AppBar(title: const Text('Запись', style: TextStyle(fontWeight: FontWeight.w800))),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
        children: [
          const Text('Авто → филиал → слот. После отправки: «ожидайте подтверждения звонка или сообщения».', style: TextStyle(color: vagMuted)),
          const SizedBox(height: 12),
          TextField(
            decoration: const InputDecoration(prefixIcon: Icon(Icons.search), hintText: 'Поиск услуги'),
            onChanged: (v) => setState(() => q = v),
          ),
          const SizedBox(height: 14),
          FilledButton(
            onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => BookingFlow(store: store))),
            child: const Text('Быстрая запись'),
          ),
          const SizedBox(height: 18),
          const Text('Или начните с услуги', style: TextStyle(fontWeight: FontWeight.w800)),
          const SizedBox(height: 8),
          ...services.map((s) => Card(
                margin: const EdgeInsets.only(bottom: 8),
                child: ListTile(
                  leading: CircleAvatar(backgroundColor: vagRed, child: Icon(_icon(s.icon), color: Colors.white, size: 20)),
                  title: Text(s.title, style: const TextStyle(fontWeight: FontWeight.w700)),
                  subtitle: Text('${s.subtitle}\n${s.durationMin} мин · ${s.priceFrom == 0 ? 'оценка' : 'от ${s.priceFrom} ₽'}', style: const TextStyle(color: vagMuted)),
                  isThreeLine: true,
                  trailing: const Icon(Icons.chevron_right, color: vagMuted),
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
