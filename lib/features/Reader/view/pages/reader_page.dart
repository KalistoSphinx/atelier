import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_app/features/Home/model/book_model.dart';
import 'package:image_app/features/Reader/viewmodel/reader_provider.dart';
import 'package:path/path.dart' as p;
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:image_app/features/Reader/view/widgets/pdf_viewer_widget.dart';
import 'package:image_app/features/Reader/view/widgets/epub_viewer_widget.dart';
import 'package:image_app/features/Reader/view/widgets/cbz_viewer_widget.dart';
import 'package:image_app/features/Reader/view/widgets/chapter_list_sheet.dart';
import 'package:image_app/features/Reader/view/widgets/page_slider_sheet.dart';

class ReaderPage extends ConsumerStatefulWidget {
  final Book book;

  const ReaderPage({super.key, required this.book});

  @override
  ConsumerState<ReaderPage> createState() => _ReaderPageState();
}

class _ReaderPageState extends ConsumerState<ReaderPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(readerProvider.notifier).reset();
    });
  }

  @override
  Widget build(BuildContext context) {
    final readerState = ref.watch(readerProvider);
    final ext = p.extension(widget.book.filePath).toLowerCase();

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Stack(
          children: [
            // The Reader Content
            Positioned.fill(
              child: GestureDetector(
                onTap: () => ref.read(readerProvider.notifier).toggleOverlay(),
                child: _buildReader(ext),
              ),
            ),

            // Top Bar
            if (readerState.isOverlayVisible)
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: _buildTopBar(),
              ),

            // Bottom Bar
            if (readerState.isOverlayVisible)
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: _buildBottomBar(readerState, ext),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildReader(String ext) {
    if (ext == '.pdf') {
      return PdfViewerWidget(book: widget.book);
    } else if (ext == '.epub') {
      return EpubViewerWidget(book: widget.book);
    } else if (ext == '.cbz' || ext == '.zip') {
      return CbzViewerWidget(book: widget.book);
    }
    return const Center(child: Text("Unsupported format"));
  }

  Widget _buildTopBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.95),
        border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: const Icon(LucideIcons.arrowLeft, color: Colors.black),
            onPressed: () => Navigator.pop(context),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  widget.book.title,
                  style: GoogleFonts.robotoMono(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.black,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (widget.book.author != null && widget.book.author!.isNotEmpty)
                  Text(
                    widget.book.author!,
                    style: GoogleFonts.robotoMono(
                      fontSize: 12,
                      fontWeight: FontWeight.w400,
                      color: Colors.black54,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(LucideIcons.list, color: Colors.black),
            onPressed: () {
              ref.read(readerProvider.notifier).setChapterSearchQuery('');
              showModalBottomSheet(
                context: context,
                isScrollControlled: true,
                backgroundColor: Colors.transparent,
                builder: (context) => const ChapterListSheet(),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildBottomBar(ReaderState state, String ext) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.95),
        border: Border(top: BorderSide(color: Colors.grey.shade200)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: .center,
            spacing: 20,
            children: [
              Material(
                elevation: 1,
                color: Colors.white,
                borderRadius: .circular(100),
                child: InkWell(
                  borderRadius: .circular(100),
                  onTap: (){
                    if (state.currentPage > 1) {
                      ref.read(readerProvider.notifier).setPage(state.currentPage - 1);
                    }
                  },
                  child: Container(
                    padding: const .all(8),
                    child: const Icon(LucideIcons.chevronLeft, color: Colors.black,),
                  ),
                ),
              ),
              
              GestureDetector(
                onTap: () {
                  showModalBottomSheet(
                    context: context,
                    isScrollControlled: true,
                    backgroundColor: Colors.transparent,
                    builder: (context) => const PageSliderSheet(),
                  );
                },
                child: Material(
                  color: Colors.grey.shade200,
                    borderRadius: BorderRadius.circular(100),
                    elevation: 1,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
                    child: Text(
                      ext == '.epub' 
                        ? "Ch. ${state.currentPage} / ${state.totalPages}"
                        : "${state.currentPage} / ${state.totalPages}",
                      style: GoogleFonts.robotoMono(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                    ),
                  ),
                ),
              ),

              Material(
                elevation: 1,
                color: Colors.white,
                borderRadius: .circular(100),
                child: InkWell(
                  borderRadius: .circular(100),
                  onTap: (){
                    if (state.currentPage < state.totalPages) {
                    ref.read(readerProvider.notifier).setPage(state.currentPage + 1);
                  }
                  },
                  child: Container(
                    padding: const .all(8),
                    child: const Icon(LucideIcons.chevronRight, color: Colors.black,),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
