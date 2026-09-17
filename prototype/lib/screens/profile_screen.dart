import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:stocrm_mobile_app/data/mock.dart';
import 'package:stocrm_mobile_app/screens/visits_screen.dart';
import 'package:stocrm_mobile_app/theme.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key, required this.store});
  final MockStore store;

  @override
  Widget build(BuildContext context) {
    final df = DateFormat('d MMM yyyy', 'ru');
    return Scaffold(
      appBar: AppBar(title: const Text('Профиль', style: TextStyle(fontWeight: FontWeight.w800))),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: ListTile(
              leading: const CircleAvatar(backgroundColor: vagRed, child: Icon(Icons.person, color: Colors.white)),
              title: Text(store.clientName, style: const TextStyle(fontWeight: FontWeight.w800)),
              subtitle: Text('${store.phone} · STOCRM', style: const TextStyle(color: vagMuted)),
            ),
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(borderRadius: BorderRadius.circular(16), color: vagRed),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Бонусы 5% с закрытого ЗН', style: TextStyle(color: Colors.white70)),
                const SizedBox(height: 4),
                Text('${store.bonus} ₽', style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.w800)),
                const Text('Списание до 50% суммы · push за 5 дней до сгорания', style: TextStyle(color: Colors.white70, fontSize: 12)),
              ],
            ),
          ),
          const SizedBox(height: 14),
          const Text('История начислений и списаний', style: TextStyle(fontWeight: FontWeight.w800)),
          const SizedBox(height: 8),
          ...store.bonusLog.map((e) => Card(
                child: ListTile(
                  title: Text(e.title, style: const TextStyle(fontWeight: FontWeight.w700)),
                  subtitle: Text('${df.format(e.when)} · ${e.note ?? ''}', style: const TextStyle(color: vagMuted)),
                  trailing: Text(e.delta > 0 ? '+${e.delta}' : '${e.delta}', style: TextStyle(color: e.delta > 0 ? Colors.white : vagRed, fontWeight: FontWeight.w800)),
                ),
              )),
          const SizedBox(height: 12),
          Card(
            child: Column(
              children: [
                SwitchListTile(
                  title: const Text('Push-уведомления'),
                  subtitle: const Text('Статус, «машина готова», акции, сгорание бонусов'),
                  value: true,
                  activeThumbColor: vagRed,
                  onChanged: (_) {},
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.menu_book_outlined, color: vagRed),
                  title: const Text('Электронный сервисбук'),
                  onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => VisitsScreen(store: store))),
                ),
                const Divider(height: 1),
                const ListTile(leading: Icon(Icons.privacy_tip_outlined), title: Text('Политика ПДн · 152-ФЗ')),
              ],
            ),
          ),
          const SizedBox(height: 12),
          OutlinedButton(onPressed: store.logout, child: const Text('Выйти')),
        ],
      ),
    );
  }
}
