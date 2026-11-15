import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:stocrm_mobile_app/data/api.dart';
import 'package:stocrm_mobile_app/data/mock.dart';
import 'package:stocrm_mobile_app/theme.dart';

class ProfileSetupScreen extends StatefulWidget {
  const ProfileSetupScreen({super.key, required this.store});

  final MockStore store;

  @override
  State<ProfileSetupScreen> createState() => _ProfileSetupScreenState();
}

class _ProfileSetupScreenState extends State<ProfileSetupScreen> {
  final lastCtrl = TextEditingController();
  final firstCtrl = TextEditingController();
  final middleCtrl = TextEditingController();
  DateTime? birthday;
  bool busy = false;
  String? error;

  @override
  void dispose() {
    lastCtrl.dispose();
    firstCtrl.dispose();
    middleCtrl.dispose();
    super.dispose();
  }

  Future<void> pickBirthday() async {
    final now = DateTime.now();
    final initial = birthday ?? DateTime(now.year - 30, now.month, now.day);
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(1925),
      lastDate: now,
      locale: const Locale('ru'),
      helpText: 'Дата рождения',
    );
    if (picked != null) setState(() => birthday = picked);
  }

  Future<void> save() async {
    final last = lastCtrl.text.trim();
    final first = firstCtrl.text.trim();
    if (last.isEmpty || first.isEmpty) {
      setState(() => error = 'Укажите фамилию и имя');
      return;
    }
    if (birthday == null) {
      setState(() => error = 'Укажите дату рождения');
      return;
    }
    setState(() {
      busy = true;
      error = null;
    });
    try {
      await widget.store.saveProfileRemote(
        lastName: last,
        firstName: first,
        middleName: middleCtrl.text.trim(),
        birthday: birthday!,
      );
    } on ApiException catch (e) {
      if (mounted) setState(() => error = e.message);
    } catch (e) {
      if (mounted) setState(() => error = '$e');
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final birthLabel = birthday == null ? 'Выберите дату' : DateFormat('d MMMM yyyy', 'ru').format(birthday!);
    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(24, 32, 24, 24),
          children: [
            const VagWordmark(size: 32, stacked: true),
            const SizedBox(height: 20),
            const Text(
              'Данные для CRM',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: vagInk),
            ),
            const SizedBox(height: 8),
            const Text(
              'В карточке STOCRM ещё нет ФИО. Укажите фамилию, имя, отчество (если есть) и дату рождения — так менеджеру проще вести заявки и бонусы.',
              style: TextStyle(color: vagMuted, height: 1.4),
            ),
            const SizedBox(height: 24),
            TextField(
              controller: lastCtrl,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(labelText: 'Фамилия *'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: firstCtrl,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(labelText: 'Имя *'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: middleCtrl,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(labelText: 'Отчество', hintText: 'Необязательно'),
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: busy ? null : pickBirthday,
              icon: const Icon(Icons.cake_outlined, color: vagRed),
              label: Align(
                alignment: Alignment.centerLeft,
                child: Text(birthLabel, style: TextStyle(color: birthday == null ? vagMuted : vagInk)),
              ),
            ),
            if (error != null) ...[
              const SizedBox(height: 12),
              Text(error!, style: const TextStyle(color: vagRed)),
            ],
            const SizedBox(height: 20),
            FilledButton(
              onPressed: busy ? null : save,
              child: busy
                  ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Text('Сохранить и продолжить'),
            ),
          ],
        ),
      ),
    );
  }
}