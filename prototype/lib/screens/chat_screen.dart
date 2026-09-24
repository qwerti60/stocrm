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
  bool sending = false;

  @override
  void initState() {
    super.initState();
    widget.store.addListener(_onStore);
    widget.store.refreshChat();
  }

  @override
  void dispose() {
    widget.store.removeListener(_onStore);
    ctrl.dispose();
    super.dispose();
  }

  void _onStore() {
    if (mounted) setState(() {});
  }

  Future<void> send() async {
    final t = ctrl.text.trim();
    if (t.isEmpty || sending) return;
    setState(() => sending = true);
    ctrl.clear();
    try {
      await widget.store.sendChatRemote(t);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
      }
    }
    if (mounted) setState(() => sending = false);
  }

  @override
  Widget build(BuildContext context) {
    final staff = widget.store.staffName;
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Чат с сервисом'),
            Text('Менеджер: $staff', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w400, color: vagMuted)),
          ],
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: widget.store.chat.isEmpty
                ? const Center(child: Text('Напишите менеджеру — ответ придёт сюда', style: TextStyle(color: vagMuted)))
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: widget.store.chat.length,
                    itemBuilder: (_, i) {
                      final m = widget.store.chat[i];
                      final staffMsg = m.fromStaff;
                      return Align(
                        alignment: staffMsg ? Alignment.centerLeft : Alignment.centerRight,
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                          constraints: const BoxConstraints(maxWidth: 320),
                          decoration: BoxDecoration(
                            color: staffMsg ? vagCard : vagRed,
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (staffMsg)
                                Text(m.staffName?.isNotEmpty == true ? m.staffName! : staff, style: const TextStyle(color: vagRed, fontSize: 11, fontWeight: FontWeight.w700)),
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
                  IconButton.filled(onPressed: sending ? null : send, icon: const Icon(Icons.send), style: IconButton.styleFrom(backgroundColor: vagRed)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
