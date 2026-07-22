import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_app/features/Reader/viewmodel/reader_provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

class ChapterListSheet extends ConsumerWidget {
  const ChapterListSheet({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(readerProvider);
    final chapters = state.chapters;

    return Container(
      height: MediaQuery.of(context).size.height * 0.75,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        children: [
          const SizedBox(height: 12),

          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          const SizedBox(height: 20),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Row(
              children: [
                Text(
                  "Chapters",
                  style: GoogleFonts.robotoMono(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: Colors.black,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(width: 10),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(100),
                  ),
                  child: Text(
                    "${chapters.length}",
                    style: GoogleFonts.robotoMono(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Colors.black54,
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Divider
          Divider(color: Colors.grey.shade100, height: 1, thickness: 1),

          // Chapter list
          Expanded(
            child: chapters.isEmpty
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(LucideIcons.bookOpen,
                            size: 40, color: Colors.grey.shade300),
                        const SizedBox(height: 12),
                        Text(
                          "No chapters found",
                          style: GoogleFonts.robotoMono(
                            color: Colors.black38,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    itemCount: chapters.length,
                    separatorBuilder: (_, _) => Divider(
                      color: Colors.grey.shade100,
                      height: 1,
                      indent: 24,
                      endIndent: 24,
                    ),
                    itemBuilder: (context, index) {
                      final chapter = chapters[index];
                      final isCurrent =
                          chapter.pageNumber == state.currentPage;

                      return Material(
                        color: isCurrent
                            ? Colors.grey.shade50
                            : Colors.transparent,
                        child: InkWell(
                          onTap: () {
                            ref
                                .read(readerProvider.notifier)
                                .setPage(chapter.pageNumber);
                            Navigator.pop(context);
                          },
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 24, vertical: 14),
                            child: Row(
                              children: [
                                // Chapter index — large, muted number for visual hierarchy
                                SizedBox(
                                  width: 36,
                                  child: Text(
                                    "${index + 1}",
                                    style: GoogleFonts.robotoMono(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w700,
                                      color: isCurrent
                                          ? Colors.black
                                          : Colors.black12,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),

                                // Chapter title + page number
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        chapter.title,
                                        style: GoogleFonts.robotoMono(
                                          fontSize: 14,
                                          fontWeight: isCurrent
                                              ? FontWeight.w700
                                              : FontWeight.w500,
                                          color: isCurrent
                                              ? Colors.black
                                              : Colors.black87,
                                        ),
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        "Page ${chapter.pageNumber}",
                                        style: GoogleFonts.robotoMono(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w400,
                                          color: Colors.black38,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),

                                // Current chapter indicator
                                if (isCurrent)
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 10, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: Colors.black,
                                      borderRadius: BorderRadius.circular(100),
                                    ),
                                    child: Text(
                                      "Current",
                                      style: GoogleFonts.robotoMono(
                                        fontSize: 10,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
