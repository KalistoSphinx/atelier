import 'package:flutter/material.dart';

Widget profileOption({
  required IconData icon,
  required String title,
  required VoidCallback onTap,
  required BuildContext context,
  Widget? trailing,
  bool isDestructive = false,
}) {
  final theme = Theme.of(context).colorScheme;

  return ListTile(
    onTap: onTap,
    trailing: trailing,
    contentPadding: const .symmetric(horizontal: 24, vertical: 0),
    leading: Icon(
      icon,
      size: 22,
      color: isDestructive ? theme.error : theme.onSurface,
    ),
    title: Text(
      title,
      style: TextStyle(
        fontSize: 16,
        color: isDestructive ? theme.error : theme.onSurface,
        fontWeight: .w600,
        letterSpacing: 0,
      ),
    ),
  );
}
