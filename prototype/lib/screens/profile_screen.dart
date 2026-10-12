import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:stocrm_mobile_app/data/mock.dart';
import 'package:stocrm_mobile_app/screens/visits_screen.dart';
import 'package:stocrm_mobile_app/theme.dart';
import 'package:url_launcher/url_launcher.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key, required this.store});
  final MockStore store;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Профиль', style: TextStyle(fontWeight: FontWeight.w800))),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: ListTile(
              leading: const CircleAvatar(backgroundColor: vagRed, child: Icon(Icons.person, color: Colors.white)),
              title: Text(store.clientName, style: const TextStyle(fontWeight: FontWeight.w800)),
              subtitle: Text(
                store.email.isNotEmpty ? '${store.phone} · ${store.email}' : '${store.phone} · STOCRM',
                style: const TextStyle(color: vagMuted),
              ),
            ),
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(borderRadius: BorderRadius.circular(16), color: vagRed),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Бонусы', style: TextStyle(color: Colors.white70)),
                const SizedBox(height: 4),
                Text('${store.bonus}', style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.w800)),
                Text('Текущий баланс · накоплено ${store.bonusAccrued}', style: const TextStyle(color: Colors.white70, fontSize: 12)),
              ],
            ),
          ),
          const SizedBox(height: 16),
          const Text('Мои автомобили', style: TextStyle(fontWeight: FontWeight.w800)),
          const SizedBox(height: 8),
          if (store.cars.isEmpty) const Text('В гараже пока пусто', style: TextStyle(color: vagMuted)),
          ...store.cars.map(
            (c) => Card(
              margin: const EdgeInsets.only(bottom: 8),
              child: ListTile(
                leading: const Icon(Icons.directions_car, color: vagRed),
                title: Text(c.title, style: const TextStyle(fontWeight: FontWeight.w700)),
                subtitle: Text('${c.plate}${c.vin != null ? ' · ${c.vin}' : ''}', style: const TextStyle(color: vagMuted)),
              ),
            ),
          ),
          const SizedBox(height: 8),
          const Text('История обслуживания', style: TextStyle(fontWeight: FontWeight.w800)),
          const SizedBox(height: 8),
          Card(
            child: ListTile(
              leading: const Icon(Icons.menu_book_outlined, color: vagRed),
              title: const Text('Электронный сервисбук'),
              subtitle: Text('${store.history.length} заказ-нарядов', style: const TextStyle(color: vagMuted)),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => VisitsScreen(store: store))),
            ),
          ),
          if (store.openTicketCount > 0) ...[
            const Text('Открытые заявки', style: TextStyle(fontWeight: FontWeight.w800)),
            const SizedBox(height: 8),
            Card(
              child: ListTile(
                leading: const Icon(Icons.inbox_outlined, color: vagRed),
                title: Text('${store.openTicketCount} в обработке'),
                subtitle: const Text('VIN и запись в сервис', style: TextStyle(color: vagMuted)),
              ),
            ),
            const SizedBox(height: 12),
          ],
          if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) ...[
            const Text('Виджет на главном экране', style: TextStyle(fontWeight: FontWeight.w800)),
            const SizedBox(height: 8),
            const Card(
              child: Padding(
                padding: EdgeInsets.all(14),
                child: Text(
                  'Android: долгое нажатие на рабочий стол → Виджеты → VAG Market. Виджет подскажет о рекомендациях и готовности авто.',
                  style: TextStyle(color: vagMuted, height: 1.4),
                ),
              ),
            ),
            const SizedBox(height: 12),
          ],
          Card(
            child: ListTile(
              leading: const Icon(Icons.privacy_tip_outlined),
              title: const Text('Политика ПДн · 152-ФЗ'),
              onTap: () => launchUrl(Uri.parse(store.privacyUrl), mode: LaunchMode.externalApplication),
            ),
          ),
          const SizedBox(height: 12),
          OutlinedButton(onPressed: store.logout, child: const Text('Выйти')),
        ],
      ),
    );
  }
}
