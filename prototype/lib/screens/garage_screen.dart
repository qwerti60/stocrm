import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:stocrm_mobile_app/data/mock.dart';
import 'package:stocrm_mobile_app/screens/booking_flow.dart';
import 'package:stocrm_mobile_app/theme.dart';

class GarageScreen extends StatefulWidget {
  const GarageScreen({super.key, required this.store});
  final MockStore store;

  @override
  State<GarageScreen> createState() => _GarageScreenState();
}

class _GarageScreenState extends State<GarageScreen> {
  String q = '';

  @override
  Widget build(BuildContext context) {
    final cars = widget.store.cars.where((c) {
      if (q.isEmpty) return true;
      final s = '${c.make} ${c.model} ${c.plate} ${c.vin ?? ''}'.toLowerCase();
      return s.contains(q.toLowerCase());
    }).toList();
    return Scaffold(
      appBar: AppBar(
        title: const Text('Гараж', style: TextStyle(fontWeight: FontWeight.w800)),
        actions: [IconButton(onPressed: () => _addCar(context), icon: const Icon(Icons.add, color: vagRed))],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
        children: [
          TextField(
            decoration: const InputDecoration(prefixIcon: Icon(Icons.search), hintText: 'Поиск по авто, номеру, VIN'),
            onChanged: (v) => setState(() => q = v),
          ),
          const SizedBox(height: 8),
          const Text('Редактируйте пробег, VIN и госномер. Закрытые ЗН — только просмотр.', style: TextStyle(color: vagMuted, fontSize: 12)),
          const SizedBox(height: 12),
          if (cars.isEmpty)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('В CRM нет авто на этом контакте', style: TextStyle(fontWeight: FontWeight.w800)),
                    const SizedBox(height: 6),
                    const Text('Записаться можно без машины — менеджер уточнит на звонке.', style: TextStyle(color: vagMuted)),
                    const SizedBox(height: 12),
                    FilledButton(
                      onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => BookingFlow(store: widget.store))),
                      child: const Text('Записаться без авто'),
                    ),
                  ],
                ),
              ),
            ),
          ...cars.map((c) {
            final active = c.id == widget.store.activeCarId;
            final kmLeft = (c.nextServiceKm ?? c.mileage) - c.mileage;
            return Card(
              margin: const EdgeInsets.only(bottom: 10),
              child: InkWell(
                borderRadius: BorderRadius.circular(16),
                onTap: () {
                  widget.store.setActiveCar(c.id);
                  Navigator.of(context).push(MaterialPageRoute(builder: (_) => CarDetailScreen(store: widget.store, car: c)));
                },
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 26,
                        backgroundColor: active ? vagRed : const Color(0xFF2A2A2E),
                        child: const Icon(Icons.directions_car, color: Colors.white),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('${c.make} ${c.model}', style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
                            Text('${c.plate} · ${c.year} · ${NumberFormat.decimalPattern('ru').format(c.mileage)} км', style: const TextStyle(color: vagMuted, fontSize: 13)),
                            Text(kmLeft > 0 ? 'До ТО ≈ $kmLeft км' : 'Пора на ТО', style: TextStyle(color: kmLeft > 0 ? vagMuted : vagRed, fontSize: 12)),
                          ],
                        ),
                      ),
                      if (active) const Text('активно', style: TextStyle(color: vagRed, fontSize: 11, fontWeight: FontWeight.w700)),
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
    final make = TextEditingController(text: 'Volkswagen');
    final model = TextEditingController();
    final year = TextEditingController(text: '2020');
    final km = TextEditingController(text: '55000');
    final vin = TextEditingController();
    final ok = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: vagCard,
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
            TextField(controller: vin, decoration: const InputDecoration(labelText: 'VIN'), textCapitalization: TextCapitalization.characters),
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
      widget.store.addCar(Vehicle(
        id: 'c${widget.store.cars.length + 1}',
        plate: plate.text.trim().toUpperCase(),
        make: make.text.trim(),
        model: model.text.trim(),
        year: int.tryParse(year.text) ?? 2020,
        mileage: int.tryParse(km.text) ?? 0,
        vin: vin.text.trim().isEmpty ? null : vin.text.trim().toUpperCase(),
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
    final history = store.history.where((v) => v.carPlate == car.plate).toList();
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
                  Text('Год: ${car.year}', style: const TextStyle(color: vagMuted)),
                  Text('Пробег: ${NumberFormat.decimalPattern('ru').format(car.mileage)} км', style: const TextStyle(color: vagMuted)),
                  if (car.vin != null) Text('VIN: ${car.vin}', style: const TextStyle(color: vagMuted)),
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
          const Text('История (только закрытые ЗН)', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
          const SizedBox(height: 8),
          if (history.isEmpty) const Text('Пока нет закрытых заказ-нарядов', style: TextStyle(color: vagMuted)),
          ...history.map((v) => Card(
                child: ListTile(
                  title: Text(v.serviceTitle),
                  subtitle: Text(
                    '${DateFormat('d MMM yyyy', 'ru').format(v.when)} · ${v.branchName}'
                    '${v.mileage != null ? '\nПробег ${v.mileage} км' : ''}'
                    '${v.works.isNotEmpty ? '\n${v.works.join(' · ')}' : ''}'
                    '${v.parts.isNotEmpty ? '\nЗапчасти: ${v.parts.join(', ')}' : ''}',
                  ),
                  trailing: Text(v.amount != null ? '${v.amount} ₽' : '', style: const TextStyle(color: vagRed, fontWeight: FontWeight.w700)),
                ),
              )),
        ],
      ),
    );
  }
}
