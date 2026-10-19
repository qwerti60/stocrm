import 'package:flutter/material.dart';
import 'package:stocrm_mobile_app/data/mock.dart';
import 'package:stocrm_mobile_app/screens/booking_flow.dart';
import 'package:stocrm_mobile_app/theme.dart';

class PopularServiceScreen extends StatelessWidget {
  const PopularServiceScreen({super.key, required this.store, required this.service});
  final MockStore store;
  final PopularService service;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(service.title, style: const TextStyle(fontWeight: FontWeight.w800))),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (service.image.isNotEmpty)
            ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: Image.asset(service.image, height: 160, width: double.infinity, fit: BoxFit.cover),
            ),
          const SizedBox(height: 12),
          Text(service.price, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 20, color: vagRed)),
          const SizedBox(height: 12),
          Text(
            service.description.isNotEmpty ? service.description : 'Описание скоро появится.',
            style: const TextStyle(height: 1.45, fontSize: 15),
          ),
          const SizedBox(height: 24),
          FilledButton(
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => BookingFlow(
                  store: store,
                  initialComment: '${service.title}. ${service.description}',
                ),
              ),
            ),
            child: const Text('Записаться'),
          ),
        ],
      ),
    );
  }
}
