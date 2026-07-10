import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class ProfileOptionItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final bool isDestructive;
  final VoidCallback onTap;

  const ProfileOptionItem({super.key, 
    required this.icon,
    required this.title,
    this.isDestructive = false,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    const textColor = Color(0xFF222222);
    
    const destructiveColor = Color(0xFFDC2626); 

    return Material(
      color: const Color(0xFFF6F6F6),
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(7),
                decoration: BoxDecoration(
                  color: isDestructive ? destructiveColor.withValues(alpha: 0.15) : const Color(0xFFE8E8E8),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  icon,
                  color: isDestructive ? destructiveColor : Colors.grey.shade800,
                  size: 20,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: isDestructive ? destructiveColor : textColor,
                    letterSpacing: -0.2,
                  ),
                ),
              ),
              Icon(
                CupertinoIcons.chevron_right,
                color: isDestructive ? destructiveColor : Colors.grey.shade900,
                size: 18,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

