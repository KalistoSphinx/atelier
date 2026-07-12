import 'dart:io';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class ImageCard extends StatelessWidget {
  final File image;
  final String imageName;
  final String date;

  const ImageCard({
    super.key,
    required this.image,
    required this.imageName,
    required this.date,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: ClipRRect(
            borderRadius: .circular(16),
            child: Image.file(
              width: .infinity,
              image,
              fit: .cover,
            ),
          )
        ),  
        const SizedBox(height: 12),
        Text(
          imageName,
          style: GoogleFonts.robotoMono(
            fontSize: 15,
            fontWeight: FontWeight.w500,
            color: Colors.black,
            letterSpacing: -0.1
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 4),
        Text(
          date,
          style: GoogleFonts.robotoMono(
            fontSize: 13,
            color: Colors.black54, // Muted text color
            fontWeight: FontWeight.w500,
            letterSpacing: -0.3
          ),
        ),
      ],
    );
  }
}
