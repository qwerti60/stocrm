import 'package:flutter/material.dart';
import 'package:stocrm_mobile_app/theme.dart';

class ShellPageTitle extends StatelessWidget {
  const ShellPageTitle({super.key, required this.title, this.trailing});

  final String title;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 8, 8),
      child: Row(
        children: [
          Expanded(
            child: Text(title, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 20, color: vagInk)),
          ),
          if (trailing != null) trailing!,
        ],
      ),
    );
  }
}
