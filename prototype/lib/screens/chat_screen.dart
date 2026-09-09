import 'package:flutter/material.dart';
import 'package:stocrm_mobile_app/data/mock.dart';

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
      appBar: AppBar(title: const Text('Чат со специалистом')),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: widget.store.chat.length,
              itemBuilder: (_, i) {
                final m = widget.store.chat[i];
                final align = m.fromStaff ? Alignment.centerLeft : Alignment.centerRight;
                return Align(
                  alignment: align,
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    constraints: const BoxConstraints(maxWidth: 320),
                    decoration: BoxDecoration(
                      color: m.fromStaff ? Colors.white : const Color(0xFFFFEDD5),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: Colors.black.withValues(alpha: 0.06)),
                    ),
                    child: Text(m.text),
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
                      decoration: const InputDecoration(hintText: 'Сообщение…'),
                      onSubmitted: (_) => send(),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton.filled(onPressed: send, icon: const Icon(Icons.send)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
