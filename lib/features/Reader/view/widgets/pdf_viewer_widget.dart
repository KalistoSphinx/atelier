import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_app/features/Home/model/book_model.dart';
import 'package:image_app/features/Reader/viewmodel/reader_provider.dart';
import 'package:pdfx/pdfx.dart';

class PdfViewerWidget extends ConsumerStatefulWidget {
  final Book book;

  const PdfViewerWidget({super.key, required this.book});

  @override
  ConsumerState<PdfViewerWidget> createState() => _PdfViewerWidgetState();
}

class _PdfViewerWidgetState extends ConsumerState<PdfViewerWidget> {
  late PdfController _pdfController;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _initPdf();
  }

  Future<void> _initPdf() async {
    // Delay initialization until the page route transition animation completes
    // to prevent jitter and lag when opening a large PDF.
    await Future.delayed(const Duration(milliseconds: 300));
    
    if (!mounted) return;

    _pdfController = PdfController(
      document: PdfDocument.openFile(widget.book.filePath),
    );
    
    setState(() {
      _isLoading = false;
    });
  }

  @override
  void dispose() {
    _pdfController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    ref.listen<ReaderState>(readerProvider, (previous, next) {
      if (previous != null && previous.currentPage != next.currentPage) {
        if (_pdfController.page != next.currentPage) {
          _pdfController.jumpToPage(next.currentPage);
        }
      }
    });

    return PdfView(
      controller: _pdfController,
      scrollDirection: Axis.horizontal,
      onDocumentLoaded: (document) async {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          ref.read(readerProvider.notifier).setTotalPages(document.pagesCount);
        });
      },
      onPageChanged: (page) {
        ref.read(readerProvider.notifier).setPage(page);
      },
    );
  }
}
