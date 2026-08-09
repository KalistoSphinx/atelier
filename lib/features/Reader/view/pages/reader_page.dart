import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_app/features/Home/model/book_model.dart';
import 'package:image_app/features/Reader/viewmodel/reader_provider.dart';
import 'package:image_app/features/Home/viewmodel/book_list_provider.dart';
import 'package:path/path.dart' as p;
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:image_app/features/Reader/view/widgets/pdf_viewer_widget.dart';
import 'package:image_app/features/Reader/view/widgets/epub_viewer_widget.dart';
import 'package:image_app/features/Reader/view/widgets/cbz_viewer_widget.dart';
import 'package:image_app/features/Reader/view/widgets/chapter_list_sheet.dart';
import 'package:image_app/features/Reader/view/widgets/page_slider_sheet.dart';
import 'package:image_app/core/services/shared_prefs_service.dart';

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
      ref.read(readerProvider.notifier).setPage(widget.book.currentPage);
      ref.read(readerProvider.notifier).setTotalPages(widget.book.totalPages);
    });
  }

  @override
  Widget build(BuildContext context) {
    final readerState = ref.watch(readerProvider);
    final ext = p.extension(widget.book.filePath).toLowerCase();

    ref.listen<ReaderState>(readerProvider, (previous, next) {
      if ((previous?.currentPage != next.currentPage ||
              previous?.totalPages != next.totalPages) &&
          next.totalPages > 1) {
        ref.read(bookListProvider.notifier).updateProgress(
            widget.book.id, next.currentPage, next.totalPages);
      }
    });

    return Scaffold(
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
    final isVertical = ref.read(sharedPrefsServiceProvider).isVerticalReadingMode;
    if (ext == '.pdf') {
      return PdfViewerWidget(book: widget.book, isVerticalMode: isVertical);
    } else if (ext == '.epub') {
      return EpubViewerWidget(book: widget.book);
    } else if (ext == '.cbz' || ext == '.zip') {
      return CbzViewerWidget(book: widget.book, isVerticalMode: isVertical);
    }
    return const Center(child: Text("Unsupported format"));
  }

  Widget _buildTopBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          // Back button — circular with elevation
          Material(
            elevation: 2,
            color: Theme.of(context).colorScheme.tertiaryContainer,
            shape: const CircleBorder(),
            clipBehavior: Clip.antiAlias,
            child: InkWell(
              customBorder: const CircleBorder(),
              onTap: () => Navigator.pop(context),
              child: const Padding(
                padding: EdgeInsets.all(10),
                child: Icon(LucideIcons.arrowLeft, size: 22),
              ),
            ),
          ),

          const SizedBox(width: 12),

          // Title container — elevated rounded pill
          Expanded(
            child: Material(
              elevation: 2,
              color: Theme.of(context).colorScheme.tertiaryContainer,
              borderRadius: BorderRadius.circular(100),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      widget.book.title,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                         letterSpacing: 0,
                  height: 1.4,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                    ),
                    if (widget.book.author != null && widget.book.author!.isNotEmpty)
                      Text(
                        widget.book.author!,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                          letterSpacing: 0
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.center,
                      ),
                  ],
                ),
              ),
            ),
          ),

          const SizedBox(width: 12),

          // Chapter list button — circular with elevation
          Material(
            elevation: 2,
            color: Theme.of(context).colorScheme.tertiaryContainer,
            shape: const CircleBorder(),
            clipBehavior: Clip.antiAlias,
            child: InkWell(
              customBorder: const CircleBorder(),
              onTap: () {
                ref.read(readerProvider.notifier).setChapterSearchQuery('');
                showModalBottomSheet(
                  context: context,
                  isScrollControlled: true,
                  builder: (context) => const ChapterListSheet(),
                );
              },
              child: const Padding(
                padding: EdgeInsets.all(10),
                child: Icon(LucideIcons.list, size: 22),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomBar(ReaderState state, String ext) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 28),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Material(
            elevation: 6,
            shadowColor: Colors.black.withValues(alpha: 0.4),
            color: Theme.of(context).colorScheme.tertiaryContainer,
            borderRadius: BorderRadius.circular(100),
            clipBehavior: Clip.antiAlias,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Previous button
                InkWell(
                  onTap: () {
                    if (state.currentPage > 1) {
                      ref.read(readerProvider.notifier).setPage(state.currentPage - 1);
                    }
                  },
                  child: const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    child: Icon(LucideIcons.chevronLeft, size: 22),
                  ),
                ),

                // Page tracker
                InkWell(
                  onTap: () {
                    showModalBottomSheet(
                      context: context,
                      isScrollControlled: true,
                      builder: (context) => const PageSliderSheet(),
                    );
                  },
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    child: Text(
                      ext == '.epub' 
                        ? "Ch. ${state.currentPage} / ${state.totalPages}"
                        : "${state.currentPage} / ${state.totalPages}",
                      style: GoogleFonts.robotoMono(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                  ),
                ),

                // Next button
                InkWell(
                  onTap: () {
                    if (state.currentPage < state.totalPages) {
                      ref.read(readerProvider.notifier).setPage(state.currentPage + 1);
                    }
                  },
                  child: const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    child: Icon(LucideIcons.chevronRight, size: 22),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
