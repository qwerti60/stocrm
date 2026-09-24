import 'package:flutter/material.dart';
import 'package:stocrm_mobile_app/data/api.dart';
import 'package:stocrm_mobile_app/theme.dart';

class BrandShort {
  const BrandShort({
    required this.title,
    required this.subtitle,
    this.url = '',
    this.gradient = const [Color(0xFF1A0508), Color(0xFFE10613)],
  });
  final String title;
  final String subtitle;
  final String url;
  final List<Color> gradient;
}

const brandShorts = [
  BrandShort(
    title: 'Ваш VAG в надёжных руках',
    subtitle: 'Сервис · запчасти · забота о VAG',
    gradient: [Color(0xFF1A0508), Color(0xFFE10613)],
  ),
  BrandShort(
    title: 'Машина готова!',
    subtitle: 'Push, когда статус в STOCRM сменится',
    gradient: [Color(0xFF0B0B0D), Color(0xFF3D0A12)],
  ),
  BrandShort(
    title: 'Замена масла от 4 990 ₽',
    subtitle: 'Масло + фильтр + работа',
    gradient: [Color(0xFF111111), Color(0xFF6B0F1A)],
  ),
  BrandShort(
    title: 'Подбор запчастей по VIN',
    subtitle: 'Заявка уходит менеджеру в админку',
    gradient: [Color(0xFF0D0D10), Color(0xFF4A0C14)],
  ),
];

class ShortsScreen extends StatefulWidget {
  const ShortsScreen({super.key, required this.onDone});
  final VoidCallback onDone;

  @override
  State<ShortsScreen> createState() => _ShortsScreenState();
}

class _ShortsScreenState extends State<ShortsScreen> {
  int index = 0;
  List<BrandShort> items = brandShorts;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final res = await ApiClient().get('/v1/shorts');
      final raw = res['items'];
      if (raw is! List) return;
      if (raw.isEmpty) {
        if (mounted) {
          setState(() {
            items = const [
              BrandShort(title: 'VAG Market', subtitle: 'Ролики появятся, когда менеджер добавит их в админке'),
            ];
          });
        }
        return;
      }
      final mapped = <BrandShort>[];
      const grads = [
        [Color(0xFF1A0508), Color(0xFFE10613)],
        [Color(0xFF0B0B0D), Color(0xFF3D0A12)],
        [Color(0xFF111111), Color(0xFF6B0F1A)],
        [Color(0xFF0D0D10), Color(0xFF4A0C14)],
      ];
      var i = 0;
      for (final item in raw) {
        if (item is! Map) continue;
        final title = '${item['title'] ?? ''}';
        if (title.isEmpty) continue;
        mapped.add(BrandShort(
          title: title,
          subtitle: '${item['subtitle'] ?? ''}',
          url: '${item['url'] ?? ''}',
          gradient: grads[i % grads.length],
        ));
        i++;
      }
      if (mapped.isNotEmpty && mounted) setState(() => items = mapped);
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: vagBlack,
      body: Stack(
        children: [
          PageView.builder(
            scrollDirection: Axis.vertical,
            itemCount: items.length,
            onPageChanged: (i) => setState(() => index = i),
            itemBuilder: (_, i) {
              final s = items[i];
              return Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: s.gradient,
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
                child: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(24, 56, 24, 48),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('VAG MARKET', style: TextStyle(color: vagRed, fontWeight: FontWeight.w900, fontSize: 18, letterSpacing: 1.2)),
                        const Spacer(),
                        const Icon(Icons.play_circle_fill, color: Colors.white70, size: 72),
                        const SizedBox(height: 18),
                        Text(s.title, style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.w800, height: 1.15)),
                        const SizedBox(height: 8),
                        Text(s.subtitle, style: const TextStyle(color: Colors.white70, fontSize: 16, height: 1.35)),
                        if (s.url.isNotEmpty) ...[
                          const SizedBox(height: 8),
                          Text(s.url, style: const TextStyle(color: Colors.white38, fontSize: 11)),
                        ],
                        const SizedBox(height: 24),
                        const Text('Листайте вверх · шортсы из админки', style: TextStyle(color: Colors.white38, fontSize: 12)),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
              child: Row(
                children: [
                  for (var i = 0; i < items.length; i++)
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 2),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: i <= index ? 1 : 0,
                            minHeight: 3,
                            backgroundColor: Colors.white24,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
          Positioned(
            top: 48,
            right: 12,
            child: TextButton(
              onPressed: widget.onDone,
              child: const Text('В приложение', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
            ),
          ),
        ],
      ),
    );
  }
}
