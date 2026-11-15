import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:stocrm_mobile_app/data/mock.dart';
import 'package:stocrm_mobile_app/screens/reschedule_flow.dart';
import 'package:stocrm_mobile_app/theme.dart';

Future<void> confirmCancelBooking(BuildContext context, MockStore store, Visit visit) async {
  final df = DateFormat('d MMMM, HH:mm', 'ru');
  final ok = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: const Text('Отменить запись?'),
      content: Text(
        '${visit.serviceTitle}\n${visit.branchName}\n${df.format(visit.when)}',
        style: const TextStyle(height: 1.4),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Назад')),
        FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Отменить')),
      ],
    ),
  );
  if (ok != true || !context.mounted) return;
  try {
    final msg = await store.cancelBookingRemote(visit.id);
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  } catch (e) {
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
  }
}

void openRescheduleFlow(BuildContext context, MockStore store, Visit visit) {
  Navigator.of(context).push(
    MaterialPageRoute(builder: (_) => RescheduleFlow(store: store, visit: visit)),
  );
}

class BookingManageButtons extends StatelessWidget {
  const BookingManageButtons({super.key, required this.store, required this.visit, this.compact = false});

  final MockStore store;
  final Visit visit;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    if (!visit.canManageBooking) return const SizedBox.shrink();
    final gap = compact ? 8.0 : 10.0;
    return Row(
      children: [
        Expanded(
          child: OutlinedButton(
            onPressed: () => openRescheduleFlow(context, store, visit),
            child: const Text('Перенести'),
          ),
        ),
        SizedBox(width: gap),
        Expanded(
          child: OutlinedButton(
            onPressed: () => confirmCancelBooking(context, store, visit),
            style: OutlinedButton.styleFrom(foregroundColor: vagRed, side: const BorderSide(color: vagRed)),
            child: const Text('Отменить'),
          ),
        ),
      ],
    );
  }
}