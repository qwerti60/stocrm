import 'package:flutter/material.dart';
import 'package:stocrm_mobile_app/data/mock.dart';
import 'package:stocrm_mobile_app/theme.dart';
import 'package:stocrm_mobile_app/widgets/app_page_scaffold.dart';
import 'package:stocrm_mobile_app/widgets/shell_page_title.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key, required this.store, this.inShell = false, this.active = true});
  final MockStore store;
  final bool inShell;
  /// Вкладка чата в нижнем меню выбрана (IndexedStack).
  final bool active;

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> with WidgetsBindingObserver {
  final ctrl = TextEditingController();
  final _scroll = ScrollController();
  bool sending = false;
  int _lastChatLen = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    widget.store.addListener(_onStore);
    _lastChatLen = widget.store.chat.length;
    widget.store.refreshChat().then((_) {
      if (mounted) {
        widget.store.markChatRead();
        _scrollToEnd();
      }
    });
  }

  @override
  void didUpdateWidget(covariant ChatScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.active && !oldWidget.active) {
      widget.store.refreshChat().then((_) {
        if (mounted) {
          widget.store.markChatRead();
          _scrollToEnd();
        }
      });
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    widget.store.removeListener(_onStore);
    ctrl.dispose();
    _scroll.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && (widget.active || !widget.inShell)) {
      widget.store.refreshChat();
    }
  }

  void _scrollToEnd() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_scroll.hasClients) return;
      final max = _scroll.position.maxScrollExtent;
      if (max <= 0) return;
      _scroll.jumpTo(max);
    });
  }

  void _onStore() {
    if (!mounted) return;
    final len = widget.store.chat.length;
    final grew = len > _lastChatLen;
    _lastChatLen = len;
    setState(() {});
    if (grew || (widget.active || !widget.inShell)) _scrollToEnd();
  }

  Future<void> send() async {
    final t = ctrl.text.trim();
    if (t.isEmpty || sending) return;
    setState(() => sending = true);
    ctrl.clear();
    try {
      await widget.store.sendChatRemote(t);
      _scrollToEnd();
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
    final chatBody = Column(
      children: [
        if (widget.inShell) const ShellPageTitle(title: 'Чат с менеджером'),
        Expanded(
          child: widget.store.chat.isEmpty
              ? const Center(child: Text('Напишите менеджеру — ответ придёт сюда', style: TextStyle(color: vagMutedInk)))
              : ListView.builder(
                  controller: _scroll,
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
                          color: staffMsg ? const Color(0xFFEFEFF2) : vagRed,
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (staffMsg)
                              Text(
                                m.staffName?.isNotEmpty == true ? m.staffName! : staff,
                                style: const TextStyle(color: vagRed, fontSize: 11, fontWeight: FontWeight.w700),
                              ),
                            Text(m.text, style: TextStyle(color: staffMsg ? vagInk : Colors.white, height: 1.35)),
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
                IconButton.filled(
                  onPressed: sending ? null : send,
                  icon: const Icon(Icons.send),
                  style: IconButton.styleFrom(backgroundColor: vagRed),
                ),
              ],
            ),
          ),
        ),
      ],
    );
    if (widget.inShell) {
      return Scaffold(backgroundColor: vagSurface, body: chatBody);
    }
    return AppPageScaffold(
      store: widget.store,
      title: 'Чат с менеджером',
      body: chatBody,
    );
  }
}