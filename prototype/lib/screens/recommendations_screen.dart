import 'package:flutter/material.dart';
import 'package:stocrm_mobile_app/data/mock.dart';
import 'package:stocrm_mobile_app/screens/booking_flow.dart';
import 'package:stocrm_mobile_app/theme.dart';

class RecommendationsScreen extends StatelessWidget {
  const RecommendationsScreen({super.key, required this.store});
  final MockStore store;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Рекомендации', style: TextStyle(fontWeight: FontWeight.w800))),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text('То, что мастер указал в CRM после осмотра. Не ручной контент приложения.', style: TextStyle(color: vagMuted)),
          const SizedBox(height: 12),
          ...store.recommendations.map(
            (r) => Card(
              margin: const EdgeInsets.only(bottom: 8),
              child: ListTile(
                leading: const Icon(Icons.tips_and_updates_outlined, color: vagRed),
                title: Text(r),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => BookingFlow(store: store))),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
