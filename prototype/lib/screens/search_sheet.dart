import 'package:flutter/material.dart';
import 'package:stocrm_mobile_app/data/mock.dart';
import 'package:stocrm_mobile_app/theme.dart';

Future<void> openAppSearch(BuildContext context, MockStore store) async {
  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: vagSurface,
    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
    builder: (ctx) => _SearchSheet(store: store),
  );
}

class _SearchSheet extends StatefulWidget {
  const _SearchSheet({required this.store});
  final MockStore store;

  @override
  State<_SearchSheet> createState() => _SearchSheetState();
}

class _SearchSheetState extends State<_SearchSheet> {
  String q = '';

  @override
  Widget build(BuildContext context) {
    final needle = q.trim().toLowerCase();
    final services = widget.store.services.where((s) {
      if (needle.isEmpty) return true;
      return '${s.title} ${s.subtitle}'.toLowerCase().contains(needle);
    });
    final branches = widget.store.branches.where((b) {
      if (needle.isEmpty) return true;
      return '${b.name} ${b.address}'.toLowerCase().contains(needle);
    });
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            Container(width: 40, height: 4, decoration: BoxDecoration(color: vagBorder, borderRadius: BorderRadius.circular(99))),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: TextField(
                autofocus: true,
                decoration: const InputDecoration(
                  prefixIcon: Icon(Icons.search, color: vagMutedInk),
                  hintText: 'Поиск по услугам, филиалам, истории',
                  suffixIcon: Icon(Icons.chevron_right, color: vagMutedInk),
                ),
                onChanged: (v) => setState(() => q = v),
              ),
            ),
            Flexible(
              child: ListView(
                shrinkWrap: true,
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                children: [
                  if (services.isNotEmpty) ...[
                    const Text('Услуги', style: TextStyle(fontWeight: FontWeight.w800, color: vagInk)),
                    const SizedBox(height: 8),
                    ...services.map(
                      (s) => ListTile(
                        tileColor: vagCard,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        leading: const Icon(Icons.build_outlined, color: vagRed),
                        title: Text(s.title, style: const TextStyle(fontWeight: FontWeight.w700)),
                        subtitle: Text(s.subtitle, style: const TextStyle(color: vagMutedInk, fontSize: 12)),
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],
                  if (branches.isNotEmpty) ...[
                    const Text('Филиалы', style: TextStyle(fontWeight: FontWeight.w800, color: vagInk)),
                    const SizedBox(height: 8),
                    ...branches.map(
                      (b) => ListTile(
                        tileColor: vagCard,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        leading: const Icon(Icons.location_on_outlined, color: vagRed),
                        title: Text(b.name, style: const TextStyle(fontWeight: FontWeight.w700)),
                        subtitle: Text(b.address, style: const TextStyle(color: vagMutedInk, fontSize: 12)),
                      ),
                    ),
                  ],
                  if (services.isEmpty && branches.isEmpty)
                    const Padding(
                      padding: EdgeInsets.all(24),
                      child: Text('Ничего не найдено', style: TextStyle(color: vagMutedInk)),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
