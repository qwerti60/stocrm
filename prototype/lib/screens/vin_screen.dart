import 'package:flutter/material.dart';
import 'package:stocrm_mobile_app/data/mock.dart';
import 'package:stocrm_mobile_app/theme.dart';

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
  void dispose() {
    vinCtrl.dispose();
    partCtrl.dispose();
    super.dispose();
  }

  void send() {
    if (vinCtrl.text.trim().length < 11 || partCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Укажите VIN и наименование запчасти')));
      return;
    }
    widget.store.sendVinRequest(vinCtrl.text.trim(), partCtrl.text.trim());
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Заявка ушла менеджеру. Ожидайте звонка или сообщения в чате.')),
    );
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Подбор запчастей по VIN')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text('Точные детали для вашего автомобиля. Заявка приходит менеджеру в веб-админку — не витрина склада.', style: TextStyle(color: vagMuted, height: 1.4)),
          const SizedBox(height: 16),
          TextField(controller: vinCtrl, decoration: const InputDecoration(labelText: 'VIN'), textCapitalization: TextCapitalization.characters),
          const SizedBox(height: 12),
          TextField(controller: partCtrl, decoration: const InputDecoration(labelText: 'Наименование запчасти'), minLines: 2, maxLines: 4),
          const SizedBox(height: 20),
          FilledButton(onPressed: send, child: const Text('Отправить менеджеру')),
        ],
      ),
    );
  }
}
