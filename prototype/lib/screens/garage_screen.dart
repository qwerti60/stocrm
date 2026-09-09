import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:stocrm_mobile_app/data/mock.dart';
import 'package:stocrm_mobile_app/screens/booking_flow.dart';

class GarageScreen extends StatelessWidget {
  const GarageScreen({super.key, required this.store});
  final MockStore store;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Гараж', style: TextStyle(fontWeight: FontWeight.w800)),
        actions: [
          IconButton(
            onPressed: () => _addCar(context),
            icon: const Icon(Icons.add),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
        children: [
          Text('Авто в STOCRM привязываются к контакту по телефону', style: TextStyle(color: Colors.grey.shade700)),
          const SizedBox(height: 12),
          ...store.cars.map((c) {
            final active = c.id == store.activeCarId;
            final kmLeft = (c.nextServiceKm ?? c.mileage) - c.mileage;
            return Card(
              margin: const EdgeInsets.only(bottom: 10),
              child: InkWell(
                borderRadius: BorderRadius.circular(16),
                onTap: () {
                  store.setActiveCar(c.id);
                  Navigator.of(context).push(MaterialPageRoute(builder: (_) => CarDetailScreen(store: store, car: c)));
                },
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 26,
                        backgroundColor: active ? const Color(0xFFFFEDD5) : const Color(0xFFF1F5F9),
                        child: Icon(Icons.directions_car, color: active ? const Color(0xFFEA580C) : Colors.blueGrey),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('${c.make} ${c.model}', style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
                            Text('${c.plate} · ${c.year} · ${NumberFormat.decimalPattern('ru').format(c.mileage)} км'),
                            Text(kmLeft > 0 ? 'До ТО ≈ $kmLeft км' : 'Пора на ТО', style: TextStyle(color: kmLeft > 0 ? Colors.grey.shade700 : const Color(0xFFEA580C), fontSize: 12)),
                          ],
                        ),
                      ),
                      if (active) const Chip(label: Text('активно', style: TextStyle(fontSize: 11))),
                    ],
                  ),
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  Future<void> _addCar(BuildContext context) async {
    final plate = TextEditingController();
    final make = TextEditingController(text: 'Hyundai');
    final model = TextEditingController(text: 'Solaris');
    final year = TextEditingController(text: '2020');
    final km = TextEditingController(text: '55000');
    final ok = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => Padding(
        padding: EdgeInsets.fromLTRB(16, 16, 16, 16 + MediaQuery.of(ctx).viewInsets.bottom),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text('Добавить авто', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18)),
            const SizedBox(height: 12),
            TextField(controller: plate, decoration: const InputDecoration(labelText: 'Госномер'), textCapitalization: TextCapitalization.characters),
            const SizedBox(height: 8),
            TextField(controller: make, decoration: const InputDecoration(labelText: 'Марка')),
            const SizedBox(height: 8),
            TextField(controller: model, decoration: const InputDecoration(labelText: 'Модель')),
            const SizedBox(height: 8),
            TextField(controller: year, decoration: const InputDecoration(labelText: 'Год'), keyboardType: TextInputType.number),
            const SizedBox(height: 8),
            TextField(controller: km, decoration: const InputDecoration(labelText: 'Пробег, км'), keyboardType: TextInputType.number),
            const SizedBox(height: 14),
            FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Сохранить')),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
    if (ok == true && plate.text.trim().isNotEmpty) {
      store.addCar(Vehicle(
        id: 'c${store.cars.length + 1}',
        plate: plate.text.trim().toUpperCase(),
        make: make.text.trim(),
        model: model.text.trim(),
        year: int.tryParse(year.text) ?? 2020,
        mileage: int.tryParse(km.text) ?? 0,
        nextServiceKm: (int.tryParse(km.text) ?? 0) + 10000,
      ));
    }
  }
}

class CarDetailScreen extends StatelessWidget {
  const CarDetailScreen({super.key, required this.store, required this.car});
  final MockStore store;
  final Vehicle car;

  @override
  Widget build(BuildContext context) {
    final history = store.visits.where((v) => v.carPlate == car.plate).toList();
    return Scaffold(
      appBar: AppBar(title: Text('${car.make} ${car.model}')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(car.plate, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800)),
                  const SizedBox(height: 8),
                  Text('Год: ${car.year}'),
                  Text('Пробег: ${NumberFormat.decimalPattern('ru').format(car.mileage)} км'),
                  if (car.vin != null) Text('VIN: ${car.vin}'),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),
          FilledButton(
            onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => BookingFlow(store: store))),
            child: const Text('Записать это авто'),
          ),
          const SizedBox(height: 16),
          const Text('История обслуживания', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
          const SizedBox(height: 8),
          if (history.isEmpty) const Text('Пока нет заказ-нарядов'),
          ...history.map((v) => Card(
                child: ListTile(
                  title: Text(v.serviceTitle),
                  subtitle: Text('${DateFormat('d MMM yyyy', 'ru').format(v.when)} · ${v.branchName}'),
                  trailing: Text(v.amount != null ? '${v.amount} ₽' : v.status),
                ),
              )),
        ],
      ),
    );
  }
}
