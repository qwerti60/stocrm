import 'package:flutter/material.dart';
import 'package:stocrm_mobile_app/theme.dart';

/// Нижняя панель как в FIT SERVICE: 4 вкладки + центральная «Запись».
class FitBottomBar extends StatelessWidget {
  const FitBottomBar({
    super.key,
    required this.index,
    required this.onSelect,
    required this.onBook,
    this.profileBadge = 0,
  });

  final int index;
  final ValueChanged<int> onSelect;
  final VoidCallback onBook;
  final int profileBadge;

  static const bookIndex = 2;

  @override
  Widget build(BuildContext context) {
    return BottomAppBar(
      height: 62,
      padding: const EdgeInsets.fromLTRB(4, 0, 4, 0),
      color: vagCard,
      surfaceTintColor: Colors.transparent,
      shadowColor: Colors.black26,
      elevation: 12,
      shape: const CircularNotchedRectangle(),
      notchMargin: 7,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _Item(
            label: 'Главная',
            icon: Icons.home_outlined,
            selectedIcon: Icons.home,
            selected: index == 0,
            onTap: () => onSelect(0),
          ),
          _Item(
            label: 'Карта',
            icon: Icons.map_outlined,
            selectedIcon: Icons.map,
            selected: index == 1,
            onTap: () => onSelect(1),
          ),
          const SizedBox(width: 52),
          _Item(
            label: 'Гараж',
            icon: Icons.directions_car_outlined,
            selectedIcon: Icons.directions_car,
            selected: index == 3,
            onTap: () => onSelect(3),
          ),
          _Item(
            label: 'Ещё',
            icon: Icons.person_outline,
            selectedIcon: Icons.person,
            selected: index == 4,
            badge: profileBadge,
            onTap: () => onSelect(4),
          ),
        ],
      ),
    );
  }
}

class FitBookFab extends StatelessWidget {
  const FitBookFab({super.key, required this.active, required this.onPressed});

  final bool active;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return FloatingActionButton.extended(
      onPressed: onPressed,
      elevation: active ? 8 : 4,
      backgroundColor: active ? vagRed : vagInk,
      foregroundColor: Colors.white,
      icon: const Icon(Icons.event_available),
      label: const Text('Запись', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13)),
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
    final color = selected ? vagRed : vagMutedInk;
    Widget iconWidget = Icon(selected ? selectedIcon : icon, color: color, size: 24);
    if (badge > 0) {
      iconWidget = Badge(
        label: Text('$badge'),
        isLabelVisible: badge > 0,
        child: iconWidget,
      );
    }
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            iconWidget,
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(fontSize: 10, fontWeight: selected ? FontWeight.w800 : FontWeight.w600, color: color),
            ),
          ],
        ),
      ),
    );
  }
}
