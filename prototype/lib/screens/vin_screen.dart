import 'package:flutter/material.dart';
import 'package:stocrm_mobile_app/data/mock.dart';
import 'package:stocrm_mobile_app/theme.dart';
import 'package:stocrm_mobile_app/ticket_ui.dart';

class VinScreen extends StatefulWidget {
  const VinScreen({super.key, required this.store});
  final MockStore store;

  @override
  State<VinScreen> createState() => _VinScreenState();
}

class _VinScreenState extends State<VinScreen> {
  late final vinCtrl = TextEditingController(text: widget.store.activeCar?.vin ?? '');
  final partCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    widget.store.refreshTickets();
  }

  @override
  void dispose() {
    vinCtrl.dispose();
    partCtrl.dispose();
    super.dispose();
  }

  Future<void> send() async {
    if (vinCtrl.text.trim().length < 11 || partCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Укажите VIN и наименование запчасти')));
      return;
    }
    try {
      await widget.store.sendVinRemote(vinCtrl.text.trim(), partCtrl.text.trim());
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
      return;
    }
    if (!mounted) return;
    partCtrl.clear();
    setState(() {});
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Заявка ушла отдельным тикетом менеджеру.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final vinTickets = widget.store.tickets.where((t) => t.kind == 'vin').toList();
    final bookTickets = widget.store.tickets.where((t) => t.kind == 'book').toList();
    final open = widget.store.openTicketCount;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Подбор запчастей по VIN'),
        actions: [
          if (open > 0)
            Padding(
              padding: const EdgeInsets.only(right: 16),
              child: Center(child: CircleAvatar(radius: 12, backgroundColor: vagRed, child: Text('$open', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800)))),
            ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text('Каждая заявка уходит отдельно в админку, не в общий чат.', style: TextStyle(color: vagMuted, height: 1.4)),
          const SizedBox(height: 16),
          TextField(controller: vinCtrl, decoration: const InputDecoration(labelText: 'VIN'), textCapitalization: TextCapitalization.characters),
          const SizedBox(height: 12),
          TextField(controller: partCtrl, decoration: const InputDecoration(labelText: 'Наименование запчасти'), minLines: 2, maxLines: 4),
          const SizedBox(height: 20),
          FilledButton(onPressed: send, child: const Text('Отправить заявку')),
          const SizedBox(height: 24),
          Text('Мои заявки VIN (${vinTickets.length})', style: const TextStyle(fontWeight: FontWeight.w800)),
          const SizedBox(height: 8),
          if (vinTickets.isEmpty) const Text('Пока нет заявок по VIN', style: TextStyle(color: vagMuted)),
          ...vinTickets.map((t) => _ticketTile(t, Icons.search)),
          const SizedBox(height: 16),
          Text('Заявки на запись (${bookTickets.length})', style: const TextStyle(fontWeight: FontWeight.w800)),
          const SizedBox(height: 8),
          if (bookTickets.isEmpty) const Text('Пока нет заявок на запись', style: TextStyle(color: vagMuted)),
          ...bookTickets.map((t) => _ticketTile(t, Icons.event_available)),
        ],
      ),
    );
  }

  Widget _ticketTile(AppTicket t, IconData icon) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Icon(icon, color: vagRed),
        title: Text(t.title, style: const TextStyle(fontWeight: FontWeight.w700)),
        subtitle: Text(t.subtitle, style: const TextStyle(color: vagMuted)),
        trailing: ticketStatusChip(t.status, label: t.statusLabel),
      ),
    );
  }
}
