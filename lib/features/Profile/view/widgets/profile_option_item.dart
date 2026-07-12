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
      color:  const Color(0xFFF3F3F3),
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Row(
            children: [
              Icon(
                icon,
                color: isDestructive ? destructiveColor : textColor,
                size: 22,
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
            ],
          ),
        ),
      ),
    );
  }
}

