import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:stocrm_mobile_app/data/mock.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key, required this.store});
  final MockStore store;

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final phoneCtrl = TextEditingController(text: '9001234567');
  final codeCtrl = TextEditingController();
  bool codeSent = false;
  String? error;

  @override
  void dispose() {
    phoneCtrl.dispose();
    codeCtrl.dispose();
    super.dispose();
  }

  String get formatted {
    final d = phoneCtrl.text.replaceAll(RegExp(r'\D'), '');
    if (d.length < 10) return '+7 $d';
    return '+7 ${d.substring(0, 3)} ${d.substring(3, 6)}-${d.substring(6, 8)}-${d.substring(8)}';
  }

  void sendCode() {
    final d = phoneCtrl.text.replaceAll(RegExp(r'\D'), '');
    if (d.length != 10) {
      setState(() => error = 'Введите 10 цифр номера');
      return;
    }
    setState(() {
      error = null;
      codeSent = true;
    });
  }

  void confirm() {
    if (codeCtrl.text.trim() != '1234') {
      setState(() => error = 'В прототипе код: 1234');
      return;
    }
    widget.store.login(formatted);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(24, 36, 24, 24),
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: const Color(0xFFEA580C),
                borderRadius: BorderRadius.circular(18),
              ),
              child: const Icon(Icons.directions_car_filled, color: Colors.white, size: 34),
            ),
            const SizedBox(height: 20),
            const Text('DRIVE СТО', style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800, letterSpacing: -0.4)),
            const SizedBox(height: 8),
            Text(
              'Запись, гараж и история обслуживания.\nЗаявки уходят в STOCRM.',
              style: TextStyle(color: Colors.grey.shade700, height: 1.4),
            ),
            const SizedBox(height: 28),
            TextField(
              controller: phoneCtrl,
              keyboardType: TextInputType.phone,
              enabled: !codeSent,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(10)],
              decoration: const InputDecoration(
                labelText: 'Телефон',
                prefixText: '+7  ',
                hintText: '900 000-00-00',
              ),
            ),
            if (codeSent) ...[
              const SizedBox(height: 12),
              TextField(
                controller: codeCtrl,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(4)],
                decoration: const InputDecoration(labelText: 'Код из SMS', hintText: '1234'),
              ),
            ],
            if (error != null) ...[
              const SizedBox(height: 10),
              Text(error!, style: const TextStyle(color: Color(0xFFB91C1C))),
            ],
            const SizedBox(height: 20),
            FilledButton(
              onPressed: codeSent ? confirm : sendCode,
              child: Text(codeSent ? 'Войти' : 'Получить код'),
            ),
            if (codeSent)
              TextButton(
                onPressed: () => setState(() {
                  codeSent = false;
                  error = null;
                }),
                child: const Text('Изменить номер'),
              ),
            const SizedBox(height: 16),
            Text(
              'Прототип: код 1234. В бою — OTP и поиск контакта в STOCRM по телефону.',
              style: TextStyle(fontSize: 12, color: Colors.grey.shade600, height: 1.35),
            ),
          ],
        ),
      ),
    );
  }
}
