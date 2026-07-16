import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_app/features/Reader/viewmodel/reader_provider.dart';
import 'package:google_fonts/google_fonts.dart';

class PageSliderSheet extends ConsumerWidget {
  const PageSliderSheet({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(readerProvider);
    
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            "Jump to Page",
            style: GoogleFonts.robotoMono(
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Text(
                "1",
                style: GoogleFonts.robotoMono(fontWeight: FontWeight.w500),
              ),
              Expanded(
                child: Slider(
                  value: state.currentPage.toDouble().clamp(1.0, state.totalPages.toDouble() > 1 ? state.totalPages.toDouble() : 2.0),
                  min: 1,
                  max: state.totalPages.toDouble() > 1 ? state.totalPages.toDouble() : 2,
                  activeColor: Colors.black,
                  inactiveColor: Colors.grey.shade300,
                  onChanged: (val) {
                    ref.read(readerProvider.notifier).setPage(val.round());
                  },
                ),
              ),
              Text(
                "${state.totalPages}",
                style: GoogleFonts.robotoMono(fontWeight: FontWeight.w500),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            "Page ${state.currentPage} of ${state.totalPages}",
            style: GoogleFonts.robotoMono(
              fontSize: 14,
              color: Colors.black54,
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}
