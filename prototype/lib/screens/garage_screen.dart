import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:stocrm_mobile_app/data/mock.dart';
import 'package:stocrm_mobile_app/screens/booking_flow.dart';
import 'package:stocrm_mobile_app/screens/recommendations_screen.dart';
import 'package:stocrm_mobile_app/screens/status_screen.dart';
import 'package:stocrm_mobile_app/screens/visits_screen.dart';
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
  void initState() {
    super.initState();
    widget.store.addListener(_onStore);
  }

  @override
  void dispose() {
    widget.store.removeListener(_onStore);
    super.dispose();
  }

  void _onStore() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final store = widget.store;
    final next = store.nextVisit;
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
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
        children: [
          TextField(
            decoration: const InputDecoration(prefixIcon: Icon(Icons.search), hintText: 'Поиск по авто, номеру, VIN'),
            onChanged: (v) => setState(() => q = v),
          ),
          const SizedBox(height: 8),
          const Text('Авто, сервисная книжка и история обслуживания — как в FIT SERVICE.', style: TextStyle(color: vagMuted, fontSize: 12)),
          if (next != null) ...[
            const SizedBox(height: 12),
            Card(
              color: vagRed.withValues(alpha: 0.08),
              child: ListTile(
                leading: const Icon(Icons.build_circle_outlined, color: vagRed),
                title: Text('Статус ремонта · ${next.status}', style: const TextStyle(fontWeight: FontWeight.w800)),
                subtitle: Text('${next.serviceTitle} · ${DateFormat('d MMM, HH:mm', 'ru').format(next.when)}'),
                trailing: const Icon(Icons.chevron_right, color: vagRed),
                onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => StatusScreen(store: store, visit: next))),
              ),
            ),
          ],
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: FilledButton(
                  onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => BookingFlow(store: store))),
                  child: const Text('Запись'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => VisitsScreen(store: store))),
                  child: const Text('Сервисбук'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => RecommendationsScreen(store: store))),
            icon: const Icon(Icons.lightbulb_outline, size: 20),
            label: Text('Рекомендации (${store.recommendations.length})'),
          ),
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
                        backgroundColor: active ? vagRed : vagBorder,
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
      try {
        await widget.store.addCarRemote(
          plate: plate.text.trim().toUpperCase(),
          make: make.text.trim().isEmpty ? 'Volkswagen' : make.text.trim(),
          model: model.text.trim().isEmpty ? 'авто' : model.text.trim(),
          year: int.tryParse(year.text) ?? 2020,
          mileage: int.tryParse(km.text) ?? 0,
          vin: vin.text.trim().isEmpty ? null : vin.text.trim().toUpperCase(),
        );
        if (context.mounted) setState(() {});
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
        }
      }
    }
  }
}

class CarDetailScreen extends StatefulWidget {
  const CarDetailScreen({super.key, required this.store, required this.car});
  final MockStore store;
  final Vehicle car;

  @override
  State<CarDetailScreen> createState() => _CarDetailScreenState();
}

class _CarDetailScreenState extends State<CarDetailScreen> {
  bool loading = true;

  @override
  void initState() {
    super.initState();
    widget.store.addListener(_onStore);
    Future.wait([
      widget.store.refreshVisits(),
      widget.store.refreshRecommendations(),
    ]).whenComplete(() {
      if (mounted) setState(() => loading = false);
    });
  }

  @override
  void dispose() {
    widget.store.removeListener(_onStore);
    super.dispose();
  }

  void _onStore() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final store = widget.store;
    final car = widget.car;
    final history = store.visitsForCar(car);
    final recs = store.recommendationsForCar(car);
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
          const SizedBox(height: 8),
          OutlinedButton(
            onPressed: () async {
              final ok = await showDialog<bool>(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: const Text('Убрать авто из гаража?'),
                  content: const Text('В STOCRM машина помечается как проданная / скрывается из приложения.'),
                  actions: [
                    TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Отмена')),
                    FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Удалить')),
                  ],
                ),
              );
              if (ok != true) return;
              try {
                await store.deleteCarRemote(car.id);
                if (context.mounted) Navigator.pop(context);
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
                }
              }
            },
            child: const Text('Удалить из гаража'),
          ),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => RecommendationsScreen(store: store, filterCar: car)),
            ),
            icon: const Icon(Icons.lightbulb_outline, size: 20),
            label: Text('Рекомендации для этого авто (${recs.length})'),
          ),
          const SizedBox(height: 16),
          const Text('История обслуживания', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
          const SizedBox(height: 8),
          if (loading) const Center(child: Padding(padding: EdgeInsets.all(12), child: CircularProgressIndicator(color: vagRed, strokeWidth: 2))),
          if (!loading && history.isEmpty)
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Нет закрытых заказ-нарядов с привязкой к этому авто. Часть сделок в CRM без машины — смотрите полный сервисбук.',
                  style: TextStyle(color: vagMuted),
                ),
                TextButton(
                  onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => VisitsScreen(store: store))),
                  child: Text('Весь сервисбук (${store.serviceBookVisits.length})'),
                ),
              ],
            ),
          ...history.map((v) => Card(
                child: ListTile(
                  title: Text(v.serviceTitle),
                  subtitle: Text(
                    'Сделка #${v.id} · ${DateFormat('d MMM yyyy', 'ru').format(v.when)} · ${v.branchName}'
                    '${v.mileage != null ? '\nПробег ${v.mileage} км' : ''}'
                    '${v.works.isNotEmpty ? '\n${v.works.join(' · ')}' : ''}'
                    '${v.parts.isNotEmpty ? '\nЗапчасти: ${v.parts.join(', ')}' : ''}',
                  ),
                  trailing: Text(v.amount != null ? '${v.amount} ₽' : 'PDF', style: const TextStyle(color: vagRed, fontWeight: FontWeight.w700)),
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => WorkOrderScreen(store: store, visit: v)),
                  ),
                ),
              )),
        ],
      ),
    );
  }
}
