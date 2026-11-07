import 'package:flutter/material.dart';
import 'package:stocrm_mobile_app/data/mock.dart';
import 'package:stocrm_mobile_app/screens/branches_screen.dart';
import 'package:stocrm_mobile_app/theme.dart';
import 'package:stocrm_mobile_app/widgets/app_top_bar.dart';

class AppPageScaffold extends StatefulWidget {
  const AppPageScaffold({
    super.key,
    required this.store,
    required this.body,
    this.title,
    this.actions,
    this.leading,
    this.showBack = true,
    this.bottomNavigationBar,
    this.floatingActionButton,
  });

  final MockStore store;
  final Widget body;
  final String? title;
  final List<Widget>? actions;
  final Widget? leading;
  final bool showBack;
  final Widget? bottomNavigationBar;
  final Widget? floatingActionButton;

  @override
  State<AppPageScaffold> createState() => _AppPageScaffoldState();
}

class _AppPageScaffoldState extends State<AppPageScaffold> {
  @override
  void initState() {
    super.initState();
    widget.store.addListener(_onStore);
  }

  @override
  void dispose() {
    widget.store.removeListener(_onStore);
    super.dispose();
  }

  void _onStore() {
    if (mounted) setState(() {});
  }

  void _openCity() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => BranchesScreen(store: widget.store, inShell: false)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final canPop = Navigator.of(context).canPop();
    final showHeader = widget.title != null || (widget.showBack && canPop) || widget.leading != null || (widget.actions?.isNotEmpty ?? false);

    return Scaffold(
      backgroundColor: vagSurface,
      floatingActionButton: widget.floatingActionButton,
      bottomNavigationBar: widget.bottomNavigationBar,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AppTopBar(
            unread: widget.store.unreadNotes.length,
            onCity: _openCity,
            onNotes: () => showAppNotificationsSheet(context, widget.store),
          ),
          if (showHeader)
            Padding(
              padding: const EdgeInsets.fromLTRB(4, 0, 8, 4),
              child: Row(
                children: [
                  if (widget.leading != null)
                    widget.leading!
                  else if (widget.showBack && canPop)
                    IconButton(
                      onPressed: () => Navigator.of(context).maybePop(),
                      icon: const Icon(Icons.arrow_back_ios_new, size: 20, color: vagInk),
                    ),
                  if (widget.title != null)
                    Expanded(
                      child: Text(
                        widget.title!,
                        style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 18, color: vagInk),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    )
                  else
                    const Spacer(),
                  ...?widget.actions,
                ],
              ),
            ),
          Expanded(child: widget.body),
        ],
      ),
    );
  }
}
