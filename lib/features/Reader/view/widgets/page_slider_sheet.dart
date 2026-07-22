import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_app/features/Reader/viewmodel/reader_provider.dart';
import 'package:google_fonts/google_fonts.dart';

class PageSliderSheet extends ConsumerStatefulWidget {
  const PageSliderSheet({super.key});

  @override
  ConsumerState<PageSliderSheet> createState() => _PageSliderSheetState();
}

class _PageSliderSheetState extends ConsumerState<PageSliderSheet> {
  /// Local slider value so we can update the UI instantly during drags
  /// without firing expensive page jumps on every tick.
  double? _localValue;

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(readerProvider);
    final maxPages = state.totalPages.toDouble();
    final safeMax = maxPages > 1 ? maxPages : 2.0;
    final displayValue = _localValue ?? state.currentPage.toDouble().clamp(1.0, safeMax);

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
                  value: displayValue.clamp(1.0, safeMax),
                  min: 1,
                  max: safeMax,
                  activeColor: Colors.black,
                  inactiveColor: Colors.grey.shade300,
                  // Only update the local visual value during drag — no page jumps
                  onChanged: (val) {
                    setState(() {
                      _localValue = val;
                    });
                  },
                  // Commit the actual page jump only when the user lifts their finger
                  onChangeEnd: (val) {
                    ref.read(readerProvider.notifier).setPage(val.round());
                    setState(() {
                      _localValue = null;
                    });
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
            "Page ${displayValue.round()} of ${state.totalPages}",
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
