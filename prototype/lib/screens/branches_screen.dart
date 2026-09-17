import 'package:flutter/material.dart';
import 'package:stocrm_mobile_app/data/mock.dart';
import 'package:stocrm_mobile_app/screens/booking_flow.dart';
import 'package:stocrm_mobile_app/theme.dart';

class BranchesScreen extends StatefulWidget {
  const BranchesScreen({super.key, required this.store});
  final MockStore store;

  @override
  State<BranchesScreen> createState() => _BranchesScreenState();
}

class _BranchesScreenState extends State<BranchesScreen> {
  String q = '';

  @override
  Widget build(BuildContext context) {
    final branches = widget.store.branches.where((b) {
      if (q.isEmpty) return true;
      return '${b.name} ${b.address} ${b.services.join(' ')}'.toLowerCase().contains(q.toLowerCase());
    }).toList();
    return Scaffold(
      appBar: AppBar(title: const Text('Адреса', style: TextStyle(fontWeight: FontWeight.w800))),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          TextField(
            decoration: const InputDecoration(prefixIcon: Icon(Icons.search), hintText: 'Поиск филиала или услуги'),
            onChanged: (v) => setState(() => q = v),
          ),
          const SizedBox(height: 12),
          Card(
            child: SizedBox(
              height: 150,
              child: Stack(
                children: [
                  const Center(child: Icon(Icons.map_outlined, size: 64, color: vagMuted)),
                  Positioned(
                    left: 16,
                    right: 16,
                    bottom: 14,
                    child: Text('Карта 2ГИС или Яндекс. Филиалы из STOCRM, Тюмень.', style: TextStyle(color: Colors.white.withValues(alpha: 0.9))),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          ...branches.map((b) => Card(
                margin: const EdgeInsets.only(bottom: 8),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(b.name, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
                      const SizedBox(height: 4),
                      Text(b.distanceKm > 0 ? '${b.address} · ${b.distanceKm} км' : b.address, style: const TextStyle(color: vagMuted)),
                      Text('${b.hours} · ${b.phone}', style: const TextStyle(color: vagMuted)),
                      const SizedBox(height: 6),
                      Wrap(
                        spacing: 6,
                        children: b.services
                            .map((s) => Chip(label: Text(s, style: const TextStyle(fontSize: 11)), backgroundColor: const Color(0xFF2A2A2E), side: BorderSide.none))
                            .toList(),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          FilledButton(
                            onPressed: () => Navigator.of(context).push(MaterialPageRoute(
                              builder: (_) => BookingFlow(store: widget.store, initialBranch: b),
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
