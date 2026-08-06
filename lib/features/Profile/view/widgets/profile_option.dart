import 'package:flutter/material.dart';

Widget profileOption({
  required IconData icon,
  required String title,
  required VoidCallback onTap,
  Widget? trailing,
  bool isDestructive = false,
}) {
  const destructiveColor = Color(0xFFDC2626);

  return ListTile(
    onTap: onTap,
    trailing: trailing,
    contentPadding: const .symmetric(horizontal: 24, vertical: 0),
    leading: Icon(
      icon,
      size: 22,
      color: isDestructive ? destructiveColor : Colors.black,
    ),
    title: Text(
      title,
      style: TextStyle(
        fontSize: 16,
        color: isDestructive ? destructiveColor : Colors.black,
        fontWeight: .w600,
        letterSpacing: 0,
      ),
    ),
  );
}
