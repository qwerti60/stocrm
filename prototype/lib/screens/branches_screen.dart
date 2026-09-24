import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:stocrm_mobile_app/data/mock.dart';
import 'package:stocrm_mobile_app/screens/booking_flow.dart';
import 'package:stocrm_mobile_app/theme.dart';
import 'package:url_launcher/url_launcher.dart';

class BranchesScreen extends StatefulWidget {
  const BranchesScreen({super.key, required this.store});
  final MockStore store;

  @override
  State<BranchesScreen> createState() => _BranchesScreenState();
}

class _BranchesScreenState extends State<BranchesScreen> {
  String q = '';
  String? selectedId;
  bool locating = false;
  String? locateHint;
  final mapController = MapController();

  @override
  void initState() {
    super.initState();
    widget.store.refreshBranches().then((_) {
      if (!mounted) return;
      final pts = widget.store.branches.where((b) => b.hasPoint);
      setState(() => selectedId ??= pts.isEmpty ? null : pts.first.id);
    });
  }

  @override
  void dispose() {
    mapController.dispose();
    super.dispose();
  }

  Future<void> _open(String url) async {
    final uri = Uri.parse(url);
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  String _maps(Branch b, {bool yandex = false}) {
    if (yandex && b.yandexUrl != null && b.yandexUrl!.isNotEmpty) return b.yandexUrl!;
    if (!yandex && b.mapsUrl != null && b.mapsUrl!.isNotEmpty) return b.mapsUrl!;
    final q = Uri.encodeComponent('${b.address.isEmpty ? b.name : b.address} ${b.city.isEmpty ? 'Тюмень' : b.city}');
    return yandex ? 'https://yandex.ru/maps/?text=$q' : 'https://2gis.ru/tyumen/search/$q';
  }

  String _tel(String phone) {
    final d = phone.replaceAll(RegExp(r'[^\d+]'), '');
    return 'tel:$d';
  }

  void _select(Branch b, {bool moveMap = true}) {
    setState(() => selectedId = b.id);
    if (moveMap && b.hasPoint) {
      try {
        mapController.move(LatLng(b.lat!, b.lng!), 14);
      } catch (_) {}
    }
  }

  Future<void> _nearest() async {
    setState(() {
      locating = true;
      locateHint = null;
    });
    final nearest = await widget.store.locateNearest();
    if (!mounted) return;
    setState(() => locating = false);
    if (nearest == null) {
      setState(() => locateHint = 'Нет геолокации или у филиала нет координат в CRM');
      return;
    }
    _select(nearest);
    setState(() => locateHint = 'Ближайший: ${nearest.name} · ${nearest.distanceLabel}');
  }

  @override
  Widget build(BuildContext context) {
    final branches = widget.store.branches.where((b) {
      if (q.isEmpty) return true;
      return '${b.name} ${b.address} ${b.services.join(' ')}'.toLowerCase().contains(q.toLowerCase());
    }).toList();
    final points = branches.where((b) => b.hasPoint).toList();
    final selected = branches.where((b) => b.id == selectedId).firstOrNull;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Адреса', style: TextStyle(fontWeight: FontWeight.w800)),
        actions: [
          TextButton.icon(
            onPressed: locating ? null : _nearest,
            icon: locating
                ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                : const Icon(Icons.near_me, color: vagRed),
            label: const Text('Ближайший', style: TextStyle(color: vagRed, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: TextField(
              decoration: const InputDecoration(prefixIcon: Icon(Icons.search), hintText: 'Поиск филиала'),
              onChanged: (v) => setState(() => q = v),
            ),
          ),
          if (locateHint != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              child: Text(locateHint!, style: const TextStyle(color: vagMuted, fontSize: 13)),
            ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: SizedBox(
                height: 240,
                child: points.isEmpty
                    ? Container(
                        color: vagCard,
                        alignment: Alignment.center,
                        child: const Text('Нет координат в CRM — список ниже', style: TextStyle(color: vagMuted)),
                      )
                    : FlutterMap(
                        mapController: mapController,
                        options: MapOptions(
                          initialCenter: LatLng(points.first.lat!, points.first.lng!),
                          initialZoom: 12,
                          onTap: (_, latlng) {
                            Branch? best;
                            var bestM = 400.0;
                            for (final b in points) {
                              final m = const Distance().as(LengthUnit.Meter, latlng, LatLng(b.lat!, b.lng!));
                              if (m < bestM) {
                                bestM = m;
                                best = b;
                              }
                            }
                            if (best != null) _select(best, moveMap: false);
                          },
                        ),
                        children: [
                          TileLayer(
                            urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                            userAgentPackageName: 'ru.app72.stocrm_mobile_app',
                          ),
                          MarkerLayer(
                            markers: [
                              for (final b in points)
                                Marker(
                                  point: LatLng(b.lat!, b.lng!),
                                  width: b.id == selectedId ? 48 : 36,
                                  height: b.id == selectedId ? 48 : 36,
                                  child: GestureDetector(
                                    onTap: () => _select(b, moveMap: false),
                                    child: Icon(
                                      Icons.location_on,
                                      size: b.id == selectedId ? 46 : 34,
                                      color: b.id == selectedId ? vagRed : Colors.white,
                                      shadows: const [Shadow(blurRadius: 6, color: Colors.black54)],
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ],
                      ),
              ),
            ),
          ),
          if (selected != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              child: Text(
                'Выбран: ${selected.name}',
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 28),
              children: [
                ...branches.map((b) => _card(b, selected: b.id == selectedId)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _card(Branch b, {required bool selected}) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: selected ? vagRed : Colors.transparent, width: 1.4),
      ),
      child: InkWell(
        onTap: () => _select(b),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(b.name, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
              const SizedBox(height: 4),
              Text(
                [b.address, if (b.distanceLabel.isNotEmpty) b.distanceLabel].join(' · '),
                style: const TextStyle(color: vagMuted),
              ),
              if (b.hours.isNotEmpty || b.phone.isNotEmpty)
                Text(
                  [if (b.hours.isNotEmpty) b.hours, if (b.phone.isNotEmpty) b.phone].join(' · '),
                  style: const TextStyle(color: vagMuted),
                ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  FilledButton(
                    onPressed: () => Navigator.of(context).push(MaterialPageRoute(
                      builder: (_) => BookingFlow(store: widget.store, initialBranch: b),
                    )),
                    child: const Text('Записаться сюда'),
                  ),
                  if (b.phone.isNotEmpty) OutlinedButton(onPressed: () => _open(_tel(b.phone)), child: const Text('Позвонить')),
                  OutlinedButton(onPressed: () => _open(_maps(b)), child: const Text('2ГИС')),
                  OutlinedButton(onPressed: () => _open(_maps(b, yandex: true)), child: const Text('Яндекс')),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
