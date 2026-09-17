import 'package:flutter/material.dart';
import 'package:stocrm_mobile_app/data/mock.dart';
import 'package:stocrm_mobile_app/theme.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key, required this.store});
  final MockStore store;

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final ctrl = TextEditingController();

  @override
  void dispose() {
    ctrl.dispose();
    super.dispose();
  }

  void send() {
    final t = ctrl.text.trim();
    if (t.isEmpty) return;
    widget.store.sendChat(t);
    ctrl.clear();
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Чат с сервисом'),
            Text('Менеджер: Егор', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w400, color: vagMuted)),
          ],
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: widget.store.chat.length,
              itemBuilder: (_, i) {
                final m = widget.store.chat[i];
                final staff = m.fromStaff;
                return Align(
                  alignment: staff ? Alignment.centerLeft : Alignment.centerRight,
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    constraints: const BoxConstraints(maxWidth: 320),
                    decoration: BoxDecoration(
                      color: staff ? vagCard : vagRed,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (staff) const Text('Егор', style: TextStyle(color: vagRed, fontSize: 11, fontWeight: FontWeight.w700)),
                        Text(m.text, style: const TextStyle(color: Colors.white, height: 1.35)),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: ctrl,
                      decoration: const InputDecoration(hintText: 'Сообщение менеджеру…'),
                      onSubmitted: (_) => send(),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton.filled(onPressed: send, icon: const Icon(Icons.send), style: IconButton.styleFrom(backgroundColor: vagRed)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
