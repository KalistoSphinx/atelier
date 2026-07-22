import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_app/features/Reader/viewmodel/reader_provider.dart';
import 'package:google_fonts/google_fonts.dart';

class ChapterListSheet extends ConsumerStatefulWidget {
  const ChapterListSheet({super.key});

  @override
  ConsumerState<ChapterListSheet> createState() => _ChapterListSheetState();
}

class _ChapterListSheetState extends ConsumerState<ChapterListSheet> {
  @override
  Widget build(BuildContext context) {
    final state = ref.watch(readerProvider);
    final chapters = state.chapters;

    return Container(
      height: MediaQuery.of(context).size.height * 0.7,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
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
          const SizedBox(height: 16),
          const Padding(
            padding:  EdgeInsets.symmetric(horizontal: 24),
            child: Text(
              "Chapters",
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.6,
              ),
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: chapters.isEmpty
                ? Center(
                    child: Text(
                      "No chapters found",
                      style: GoogleFonts.robotoMono(color: Colors.black54),
                    ),
                  )
                : ListView.builder(
                    itemCount: chapters.length,
                    itemBuilder: (context, index) {
                      final chapter = chapters[index];
                      final isCurrent = chapter.pageNumber == state.currentPage; 
                      
                      return ListTile(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 4),
                        title: Text(
                          chapter.title,
                          style: GoogleFonts.robotoMono(
                            fontWeight: isCurrent ? FontWeight.w700 : FontWeight.w500,
                            color: isCurrent ? Colors.black : Colors.black87,
                          ),
                        ),
                        trailing: Text(
                          "p. ${chapter.pageNumber}",
                          style: GoogleFonts.robotoMono(
                            color: Colors.black45,
                            fontSize: 12,
                          ),
                        ),
                        onTap: () {
                          ref.read(readerProvider.notifier).setPage(chapter.pageNumber);
                          Navigator.pop(context);
                        },
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
