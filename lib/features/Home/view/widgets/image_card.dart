import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class ImageCard extends StatelessWidget {
  final String? imageUrl;
  final String imageName;
  final String date;

  const ImageCard({
    super.key,
    this.imageUrl,
    required this.imageName,
    required this.date,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: Container(
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(20),
              image: imageUrl != null
                  ? const DecorationImage(
                      image: NetworkImage("https://images.pexels.com/photos/38083493/pexels-photo-38083493/free-photo-of-stunning-coastal-cliff-view-in-pembrokeshire.jpeg?cs=tinysrgb&dpr=1&w=500"),
                      fit: BoxFit.cover,
                    )
                  : null,
            ),
          ),
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
