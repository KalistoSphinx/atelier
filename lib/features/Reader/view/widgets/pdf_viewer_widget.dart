import 'dart:typed_data';

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
  PdfDocument? _document;
  bool _isLoading = true;
  int _pageCount = 0;
  late PageController _pageController;

  /// Pre-rendered page images keyed by 0-based page index.
  final Map<int, Uint8List> _pageCache = {};

  /// Tracks which pages are currently being rendered to avoid duplicate work.
  final Set<int> _renderingPages = {};

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _initPdf();
  }

  Future<void> _initPdf() async {
    // Delay to let page transition animation finish
    await Future.delayed(const Duration(milliseconds: 300));
    if (!mounted) return;

    _document = await PdfDocument.openFile(widget.book.filePath);
    _pageCount = _document!.pagesCount;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(readerProvider.notifier).setTotalPages(_pageCount);
    });

    setState(() {
      _isLoading = false;
    });

    // Pre-render the first page and its neighbor immediately
    _precacheAround(0);
  }

  /// Render a single page to JPEG bytes and store in cache.
  Future<void> _renderPage(int index) async {
    if (_pageCache.containsKey(index)) return;
    if (_renderingPages.contains(index)) return;
    if (index < 0 || index >= _pageCount) return;

    _renderingPages.add(index);
    try {
      final page = await _document!.getPage(index + 1);
      final image = await page.render(
        width: page.width * 2,
        height: page.height * 2,
        format: PdfPageImageFormat.jpeg,
        backgroundColor: '#ffffff',
        quality: 100
      );
      await page.close();

      if (image != null && mounted) {
        _pageCache[index] = Uint8List.fromList(image.bytes);
        // Trigger rebuild only if this page is near the current view
        final currentIndex = _pageController.hasClients
            ? (_pageController.page?.round() ?? 0)
            : 0;
        if ((index - currentIndex).abs() <= 1) {
          setState(() {});
        }
      }
    } finally {
      _renderingPages.remove(index);
    }
  }

  /// Pre-render current page and ±2 neighbors for butter-smooth swiping.
  void _precacheAround(int index) {
    for (int i = index - 2; i <= index + 2; i++) {
      if (i >= 0 && i < _pageCount && !_pageCache.containsKey(i)) {
        _renderPage(i);
      }
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    _document?.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    ref.listen<ReaderState>(readerProvider, (previous, next) {
      if (previous != null && previous.currentPage != next.currentPage) {
        final targetIndex = next.currentPage - 1;
        if (_pageController.hasClients &&
            _pageController.page?.round() != targetIndex) {
          _pageController.jumpToPage(targetIndex);
        }
        _precacheAround(targetIndex);
      }
    });

    return PageView.builder(
      controller: _pageController,
      itemCount: _pageCount,
      allowImplicitScrolling: true,
      onPageChanged: (index) {
        ref.read(readerProvider.notifier).setPage(index + 1);
        _precacheAround(index);
      },
      itemBuilder: (context, index) {
        final cached = _pageCache[index];

        if (cached != null) {
          return InteractiveViewer(
            minScale: 1.0,
            maxScale: 4.0,
            child: Center(
              child: Image.memory(
                cached,
                fit: BoxFit.contain,
                gaplessPlayback: true,
              ),
            ),
          );
        }

        // Page not yet rendered — kick off render and show a subtle loader
        _renderPage(index);
        return const Center(
          child: SizedBox(
            width: 24,
            height: 24,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        );
      },
    );
  }
}
