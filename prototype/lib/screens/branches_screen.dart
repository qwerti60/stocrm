import 'package:flutter/material.dart';
import 'package:stocrm_mobile_app/data/mock.dart';
import 'package:stocrm_mobile_app/screens/booking_flow.dart';

class BranchesScreen extends StatelessWidget {
  const BranchesScreen({super.key, required this.store});
  final MockStore store;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Филиалы')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            color: const Color(0xFF0B1F33),
            child: SizedBox(
              height: 160,
              child: Stack(
                children: [
                  const Center(child: Icon(Icons.map_outlined, size: 64, color: Colors.white24)),
                  Positioned(
                    left: 16,
                    right: 16,
                    bottom: 14,
                    child: Text(
                      'Карта (Yandex / OSM) в боевой версии. Прототип — список точек.',
                      style: TextStyle(color: Colors.white.withValues(alpha: 0.9)),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          ...store.branches.map((b) => Card(
                margin: const EdgeInsets.only(bottom: 8),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(b.name, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
                      const SizedBox(height: 4),
                      Text('${b.address} · ${b.distanceKm} км'),
                      Text('${b.hours} · ${b.phone}'),
                      const SizedBox(height: 6),
                      Wrap(
                        spacing: 6,
                        children: b.services.map((s) => Chip(label: Text(s, style: const TextStyle(fontSize: 11)))).toList(),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          FilledButton(
                            onPressed: () => Navigator.of(context).push(MaterialPageRoute(
                              builder: (_) => BookingFlow(store: store, initialBranch: b),
                            )),
                            child: const Text('Записаться сюда'),
                          ),
                          const SizedBox(width: 8),
                          OutlinedButton(onPressed: () {}, child: const Text('Позвонить')),
                        ],
                      ),
                    ],
                  ),
                ),
              )),
        ],
      ),
    );
  }
}
