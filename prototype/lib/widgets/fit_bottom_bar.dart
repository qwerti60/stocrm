import 'package:flutter/material.dart';
import 'package:stocrm_mobile_app/theme.dart';

/// Нижнее меню как в FIT SERVICE: 5 равных вкладок.
class FitBottomBar extends StatelessWidget {
  const FitBottomBar({
    super.key,
    required this.index,
    required this.onSelect,
    this.chatBadge = 0,
  });

  final int index;
  final ValueChanged<int> onSelect;
  final int chatBadge;

  static const homeIndex = 0;
  static const garageIndex = 1;
  static const mapIndex = 2;
  static const recommendationsIndex = 3;
  static const chatIndex = 4;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: vagCard,
        border: Border(top: BorderSide(color: vagBorder.withValues(alpha: 0.9))),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 12, offset: const Offset(0, -2))],
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 56,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _Item(
                label: 'Главная',
                icon: Icons.home_outlined,
                selectedIcon: Icons.home,
                selected: index == homeIndex,
                onTap: () => onSelect(homeIndex),
              ),
              _Item(
                label: 'Гараж',
                icon: Icons.directions_car_outlined,
                selectedIcon: Icons.directions_car,
                selected: index == garageIndex,
                onTap: () => onSelect(garageIndex),
              ),
              _Item(
                label: 'Карта',
                icon: Icons.location_on_outlined,
                selectedIcon: Icons.location_on,
                selected: index == mapIndex,
                onTap: () => onSelect(mapIndex),
              ),
              _Item(
                label: 'Рекомендации',
                icon: Icons.build_outlined,
                selectedIcon: Icons.build,
                selected: index == recommendationsIndex,
                onTap: () => onSelect(recommendationsIndex),
              ),
              _Item(
                label: 'Чаты',
                icon: Icons.chat_bubble_outline,
                selectedIcon: Icons.chat_bubble,
                selected: index == chatIndex,
                badge: chatBadge,
                onTap: () => onSelect(chatIndex),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Item extends StatelessWidget {
  const _Item({
    required this.label,
    required this.icon,
    required this.selectedIcon,
    required this.selected,
    required this.onTap,
    this.badge = 0,
  });

  final String label;
  final IconData icon;
  final IconData selectedIcon;
  final bool selected;
  final VoidCallback onTap;
  final int badge;

  @override
  Widget build(BuildContext context) {
    final color = selected ? vagInk : vagMutedInk;
    Widget iconWidget = Icon(selected ? selectedIcon : icon, color: color, size: 22);
    if (badge > 0) {
      iconWidget = Badge(
        label: Text('$badge'),
        isLabelVisible: badge > 0,
        child: iconWidget,
      );
    }
    return Expanded(
      child: InkWell(
        onTap: onTap,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            iconWidget,
            const SizedBox(height: 2),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(fontSize: 9, fontWeight: selected ? FontWeight.w800 : FontWeight.w600, color: color),
            ),
          ],
        ),
      ),
    );
  }
}
