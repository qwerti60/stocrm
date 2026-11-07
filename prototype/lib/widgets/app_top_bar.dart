import 'package:flutter/material.dart';
import 'package:stocrm_mobile_app/data/mock.dart';
import 'package:stocrm_mobile_app/screens/chat_screen.dart';
import 'package:stocrm_mobile_app/screens/recommendations_screen.dart';
import 'package:stocrm_mobile_app/screens/status_screen.dart';
import 'package:stocrm_mobile_app/theme.dart';

void showAppNotificationsSheet(BuildContext context, MockStore store) {
  final notes = store.unreadNotes;
  showModalBottomSheet<void>(
    context: context,
    backgroundColor: vagCard,
    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
    builder: (ctx) {
      if (notes.isEmpty) {
        return const Padding(
          padding: EdgeInsets.fromLTRB(24, 28, 24, 40),
          child: Text('Нет новых уведомлений', style: TextStyle(color: vagMutedInk)),
        );
      }
      return SafeArea(
        child: ListView(
          shrinkWrap: true,
          padding: const EdgeInsets.fromLTRB(8, 12, 8, 24),
          children: [
            const Padding(
              padding: EdgeInsets.fromLTRB(16, 8, 16, 8),
              child: Text('Уведомления', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16, color: vagInk)),
            ),
            for (final note in notes)
              ListTile(
                leading: const Icon(Icons.notifications_active, color: vagRed),
                title: Text(note.title, style: const TextStyle(fontWeight: FontWeight.w800)),
                subtitle: Text(note.body, style: const TextStyle(color: vagMutedInk, fontSize: 12)),
                onTap: () {
                  Navigator.pop(ctx);
                  store.markNoteRead(note.id);
                  final kind = note.kind ?? '';
                  if (kind == 'chat' || kind == 'push') {
                    Navigator.of(context).push(MaterialPageRoute(builder: (_) => ChatScreen(store: store)));
                  } else if (kind == 'promo') {
                    Navigator.of(context).push(MaterialPageRoute(builder: (_) => RecommendationsScreen(store: store)));
                  } else {
                    Navigator.of(context).push(MaterialPageRoute(builder: (_) => StatusScreen(store: store)));
                  }
                },
              ),
          ],
        ),
      );
    },
  );
}

class AppTopBar extends StatelessWidget {
  const AppTopBar({
    super.key,
    required this.unread,
    required this.onCity,
    required this.onNotes,
  });

  final int unread;
  final VoidCallback onCity;
  final VoidCallback onNotes;

  @override
  Widget build(BuildContext context) {
    final pad = MediaQuery.sizeOf(context).width >= 520 ? 24.0 : 16.0;
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(colors: [Color(0xFF1A1014), vagBlack], begin: Alignment.topCenter, end: Alignment.bottomCenter),
      ),
      width: double.infinity,
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: EdgeInsets.fromLTRB(pad, 4, pad, 12),
          child: Row(
            children: [
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    VagWordmark(size: 22, onDark: true),
                    SizedBox(height: 4),
                    Text(
                      'СЕРВИС · ЗАПЧАСТИ · ЗАБОТА О VAG',
                      style: TextStyle(color: Color(0xFFB0B0B5), fontSize: 8, letterSpacing: 0.6, fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ),
              GestureDetector(
                onTap: onCity,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                  decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(20)),
                  child: const Row(
                    children: [
                      Icon(Icons.location_on, size: 14, color: vagRed),
                      SizedBox(width: 4),
                      Text('Тюмень', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.white)),
                      Icon(Icons.keyboard_arrow_down, size: 16, color: Colors.white70),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: onNotes,
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(18)),
                      child: const Icon(Icons.notifications_none, size: 20, color: Colors.white),
                    ),
                    if (unread > 0)
                      Positioned(
                        right: -2,
                        top: -2,
                        child: CircleAvatar(
                          radius: 8,
                          backgroundColor: vagRed,
                          child: Text('$unread', style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w800, color: Colors.white)),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
