import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:stocrm_mobile_app/data/mock.dart';
import 'package:stocrm_mobile_app/theme.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key, required this.store});
  final MockStore store;

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final phoneCtrl = TextEditingController(text: '9139142994');
  final codeCtrl = TextEditingController();
  bool codeSent = false;
  bool pushOk = true;
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

  Future<void> sendCode() async {
    final d = phoneCtrl.text.replaceAll(RegExp(r'\D'), '');
    if (d.length != 10) {
      setState(() => error = 'Введите 10 цифр номера');
      return;
    }
    try {
      await widget.store.requestOtp(d);
    } catch (_) {
      // BFF ещё не поднят — локальный прототип, код 1234
    }
    setState(() {
      error = null;
      codeSent = true;
    });
  }

  Future<void> confirm() async {
    try {
      await widget.store.loginRemote(phoneCtrl.text, codeCtrl.text.trim());
      return;
    } catch (_) {
      if (codeCtrl.text.trim() != '1234') {
        setState(() => error = 'Код: 1234, либо поднимите BFF');
        return;
      }
      widget.store.login(formatted);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(24, 36, 24, 24),
          children: [
            const Text('VAG MARKET', style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900, letterSpacing: 0.4, color: vagRed)),
            const SizedBox(height: 4),
            const Text('СЕРВИС · ЗАПЧАСТИ · ЗАБОТА О VAG', style: TextStyle(color: vagMuted, fontSize: 10, letterSpacing: 0.8, fontWeight: FontWeight.w600)),
            const SizedBox(height: 16),
            const Text('Вход по телефону', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800)),
            const SizedBox(height: 8),
            const Text('Клиент находится в STOCRM по номеру. Согласие на пуши и рассылки — 152-ФЗ.', style: TextStyle(color: vagMuted, height: 1.4)),
            const SizedBox(height: 28),
            TextField(
              controller: phoneCtrl,
              keyboardType: TextInputType.phone,
              enabled: !codeSent,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(10)],
              decoration: const InputDecoration(labelText: 'Телефон', prefixText: '+7  ', hintText: '900 000-00-00'),
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
              Text(error!, style: const TextStyle(color: vagRed)),
            ],
            const SizedBox(height: 8),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Push и акции'),
              subtitle: const Text('Статус авто, «машина готова», спецпредложения'),
              value: pushOk,
              activeThumbColor: vagRed,
              onChanged: (v) => setState(() => pushOk = v),
            ),
            const SizedBox(height: 8),
            FilledButton(onPressed: codeSent ? () => confirm() : () => sendCode(), child: Text(codeSent ? 'Войти' : 'Получить код')),
            if (codeSent)
              TextButton(
                onPressed: () => setState(() {
                  codeSent = false;
                  error = null;
                }),
                child: const Text('Изменить номер', style: TextStyle(color: vagMuted)),
              ),
            const SizedBox(height: 16),
            const Text('Прототип: код 1234. Тестовый контакт CRM уже подставлен.', style: TextStyle(fontSize: 12, color: vagMuted, height: 1.35)),
          ],
        ),
      ),
    );
  }
}
