import 'package:flutter/material.dart';
import 'package:stocrm_mobile_app/data/mock.dart';
import 'package:stocrm_mobile_app/screens/branches_screen.dart';
import 'package:stocrm_mobile_app/screens/chat_screen.dart';

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
              leading: const CircleAvatar(backgroundColor: Color(0xFFFFEDD5), child: Icon(Icons.person, color: Color(0xFFEA580C))),
              title: Text(store.clientName, style: const TextStyle(fontWeight: FontWeight.w800)),
              subtitle: Text('${store.phone} · контакт STOCRM'),
            ),
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              gradient: const LinearGradient(colors: [Color(0xFFEA580C), Color(0xFFC2410C)]),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Бонусы DRIVE', style: TextStyle(color: Colors.white70)),
                      const SizedBox(height: 4),
                      Text('${store.bonus} ₽', style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.w800)),
                      const Text('До 50% работ, кроме кузова', style: TextStyle(color: Colors.white70, fontSize: 12)),
                    ],
                  ),
                ),
                Icon(Icons.stars, color: Colors.white.withValues(alpha: 0.9), size: 40),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Card(
            child: Column(
              children: [
                SwitchListTile(
                  title: const Text('Push-уведомления'),
                  subtitle: const Text('Напоминание о записи и «авто готово»'),
                  value: true,
                  onChanged: (_) {},
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.chat_bubble_outline),
                  title: const Text('Написать в сервис'),
                  onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => ChatScreen(store: store))),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.place_outlined),
                  title: const Text('Филиалы и карта'),
                  onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => BranchesScreen(store: store))),
                ),
                const Divider(height: 1),
                const ListTile(
                  leading: Icon(Icons.privacy_tip_outlined),
                  title: Text('Политика ПДн · 152-ФЗ'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          OutlinedButton(onPressed: store.logout, child: const Text('Выйти')),
          const SizedBox(height: 12),
          Text(
            'Прототип Flutter. SID STOCRM на сервере, не в приложении.',
            style: TextStyle(color: Colors.grey.shade700, fontSize: 12),
          ),
        ],
      ),
    );
  }
}
