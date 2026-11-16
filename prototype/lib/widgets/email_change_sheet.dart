import 'package:flutter/material.dart';
import 'package:stocrm_mobile_app/data/api.dart';
import 'package:stocrm_mobile_app/data/mock.dart';
import 'package:stocrm_mobile_app/theme.dart';

class EmailChangeSheet extends StatefulWidget {
  const EmailChangeSheet({super.key, required this.store});

  final MockStore store;

  static Future<bool?> show(BuildContext context, MockStore store) {
    return showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      builder: (_) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
        child: EmailChangeSheet(store: store),
      ),
    );
  }

  @override
  State<EmailChangeSheet> createState() => _EmailChangeSheetState();
}

class _EmailChangeSheetState extends State<EmailChangeSheet> {
  final emailCtrl = TextEditingController();
  final codeCtrl = TextEditingController();
  bool sent = false;
  bool busy = false;
  String? error;

  @override
  void dispose() {
    emailCtrl.dispose();
    codeCtrl.dispose();
    super.dispose();
  }

  Future<void> sendCode() async {
    final email = emailCtrl.text.trim();
    if (email.isEmpty || !email.contains('@')) {
      setState(() => error = 'Введите корректный email');
      return;
    }
    setState(() {
      busy = true;
      error = null;
    });
    try {
      await widget.store.requestEmailChangeOtp(email);
      if (mounted) setState(() => sent = true);
    } on ApiException catch (e) {
      if (mounted) setState(() => error = e.message);
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  Future<void> confirm() async {
    setState(() {
      busy = true;
      error = null;
    });
    try {
      await widget.store.confirmEmailChange(newEmail: emailCtrl.text.trim(), code: codeCtrl.text.trim());
      if (mounted) Navigator.pop(context, true);
    } on ApiException catch (e) {
      if (mounted) setState(() => error = e.message);
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text('Смена email', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
            const SizedBox(height: 8),
            Text(
              sent
                  ? 'Код отправлен на ${emailCtrl.text.trim()}. Подтвердите новый адрес.'
                  : 'Сейчас: ${widget.store.email.isNotEmpty ? widget.store.email : "не указан"}. Код придёт на новый адрес, в STOCRM тоже обновим.',
              style: const TextStyle(color: vagMuted, height: 1.35),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: emailCtrl,
              keyboardType: TextInputType.emailAddress,
              readOnly: sent,
              decoration: const InputDecoration(labelText: 'Новый email'),
            ),
            if (sent) ...[
              const SizedBox(height: 10),
              TextField(
                controller: codeCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Код из письма'),
              ),
            ],
            if (error != null) ...[
              const SizedBox(height: 8),
              Text(error!, style: const TextStyle(color: vagRed)),
            ],
            const SizedBox(height: 14),
            FilledButton(
              onPressed: busy ? null : (sent ? confirm : sendCode),
              child: busy
                  ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : Text(sent ? 'Сохранить email' : 'Отправить код'),
            ),
            if (sent)
              TextButton(
                onPressed: busy ? null : () => setState(() => sent = false),
                child: const Text('Изменить адрес', style: TextStyle(color: vagMuted)),
              ),
          ],
        ),
      ),
    );
  }
}