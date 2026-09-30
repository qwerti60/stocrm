import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:stocrm_mobile_app/data/api.dart';
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
  final emailCtrl = TextEditingController();
  final codeCtrl = TextEditingController();
  bool codeSent = false;
  bool needEmail = false;
  bool pushOk = true;
  bool busy = false;
  String? maskedEmail;
  String? hint;
  String? error;

  @override
  void dispose() {
    phoneCtrl.dispose();
    emailCtrl.dispose();
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
    setState(() {
      error = null;
      busy = true;
    });
    try {
      if (!needEmail) {
        final look = await widget.store.lookupAuth(d);
        final missing = look['need_email'] == true;
        setState(() {
          needEmail = missing;
          maskedEmail = look['email_masked'] as String?;
          hint = look['is_new'] == true ? 'Новый клиент — укажите email для кода' : null;
        });
        if (missing) {
          if (emailCtrl.text.trim().isEmpty) {
            setState(() => error = 'В STOCRM нет почты. Введите email — привяжем к этому телефону.');
            return;
          }
        }
      }
      final res = await widget.store.requestOtp(d, email: emailCtrl.text.trim().isEmpty ? null : emailCtrl.text.trim());
      setState(() {
        error = null;
        codeSent = true;
        maskedEmail = (res['email_masked'] as String?) ?? maskedEmail;
        hint = res['hint'] as String?;
      });
    } on ApiException catch (e) {
      final msg = e.message;
      if (msg.contains('нет email') || e.status == 409) {
        setState(() {
          needEmail = true;
          error = 'Введите email. Код придёт на почту, телефон останется ключом входа.';
        });
      } else {
        setState(() => error = msg);
      }
    } catch (_) {
      setState(() {
        error = null;
        codeSent = true;
        hint = 'BFF недоступен — локальный прототип, код 1234';
      });
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
      await widget.store.loginRemote(
        phoneCtrl.text,
        codeCtrl.text.trim(),
        email: emailCtrl.text.trim().isEmpty ? null : emailCtrl.text.trim(),
      );
      return;
    } on ApiException catch (e) {
      setState(() => error = e.message);
    } catch (_) {
      if (codeCtrl.text.trim() != '1234') {
        setState(() => error = 'Код из письма, либо 1234 если SMTP ещё не настроен');
        return;
      }
      widget.store.login(formatted);
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(24, 36, 24, 24),
          children: [
            const VagWordmark(size: 36, stacked: true),
            const SizedBox(height: 8),
            const Text('СЕРВИС · ЗАПЧАСТИ · ЗАБОТА О VAG', style: TextStyle(color: vagMuted, fontSize: 10, letterSpacing: 0.8, fontWeight: FontWeight.w600)),
            const SizedBox(height: 16),
            const Text('Вход и регистрация', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800)),
            const SizedBox(height: 8),
            const Text(
              'Телефон ищем в STOCRM. Код подтверждения приходит на email. Если почты в карточке нет — её нужно указать, она сохранится вместе с номером.',
              style: TextStyle(color: vagMuted, height: 1.4),
            ),
            const SizedBox(height: 28),
            TextField(
              controller: phoneCtrl,
              keyboardType: TextInputType.phone,
              enabled: !codeSent,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(10)],
              decoration: const InputDecoration(labelText: 'Телефон', prefixText: '+7  ', hintText: '900 000-00-00'),
            ),
            if (needEmail && !codeSent) ...[
              const SizedBox(height: 12),
              TextField(
                controller: emailCtrl,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(
                  labelText: 'Email',
                  hintText: 'name@mail.ru',
                ),
              ),
            ],
            if (codeSent) ...[
              const SizedBox(height: 12),
              TextField(
                controller: codeCtrl,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(4)],
                decoration: InputDecoration(
                  labelText: 'Код с почты',
                  hintText: '1234',
                  helperText: maskedEmail?.isNotEmpty == true ? 'Отправлен на $maskedEmail' : null,
                ),
              ),
            ],
            if (error != null) ...[
              const SizedBox(height: 10),
              Text(error!, style: const TextStyle(color: vagRed)),
            ],
            if (hint != null && error == null) ...[
              const SizedBox(height: 10),
              Text(hint!, style: const TextStyle(color: vagMuted, fontSize: 12, height: 1.35)),
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
            FilledButton(
              onPressed: busy ? null : (codeSent ? confirm : sendCode),
              child: busy
                  ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : Text(codeSent ? 'Войти' : (needEmail ? 'Получить код на почту' : 'Продолжить')),
            ),
            if (codeSent)
              TextButton(
                onPressed: busy
                    ? null
                    : () => setState(() {
                          codeSent = false;
                          error = null;
                          hint = null;
                        }),
                child: const Text('Изменить данные', style: TextStyle(color: vagMuted)),
              ),
            const SizedBox(height: 16),
            const Text(
              'Пока SMTP на сервере не настроен, код 1234. После настройки письма уходят на email из CRM или указанный при регистрации.',
              style: TextStyle(fontSize: 12, color: vagMuted, height: 1.35),
            ),
          ],
        ),
      ),
    );
  }
}
