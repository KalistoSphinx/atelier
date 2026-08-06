import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_app/features/Home/model/book_model.dart';
import 'package:image_app/features/Reader/viewmodel/reader_provider.dart';
import 'package:pdfx/pdfx.dart';

class PdfViewerWidget extends ConsumerStatefulWidget {
  final Book book;
  final bool isVerticalMode;

  const PdfViewerWidget({
    super.key,
    required this.book,
    this.isVerticalMode = false,
  });

  @override
  ConsumerState<PdfViewerWidget> createState() => _PdfViewerWidgetState();
}

class _PdfViewerWidgetState extends ConsumerState<PdfViewerWidget> {
  PdfDocument? _document;
  bool _isLoading = true;
  int _pageCount = 0;

  late PageController _pageController;
  late ScrollController _scrollController;
  final Map<int, double> _pageAspectRatios = {};
  double _screenWidth = 0;
  int _currentVisiblePage = 0;
  bool _isProgrammaticScroll = false;

  final TransformationController _transformationController = TransformationController();
  bool _isZoomed = false;

  @override
  void initState() {
    super.initState();
    final initialIndex = widget.book.currentPage > 0 ? widget.book.currentPage - 1 : 0;
    _pageController = PageController(initialPage: initialIndex);
    _scrollController = ScrollController();
    _transformationController.addListener(_onZoomChange);
    _initPdf();
  }

  void _onZoomChange() {
    final isZoomed = _transformationController.value.getMaxScaleOnAxis() > 1.01;
    if (isZoomed != _isZoomed) {
      setState(() {
        _isZoomed = isZoomed;
      });
    }
  }

  Future<void> _initPdf() async {
    await Future.delayed(const Duration(milliseconds: 300));
    if (!mounted) return;

    _document = await PdfDocument.openFile(widget.book.filePath);
    _pageCount = _document!.pagesCount;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(readerProvider.notifier).setTotalPages(_pageCount);
    });

    for (int i = 0; i < _pageCount; i++) {
      final page = await _document!.getPage(i + 1);
      _pageAspectRatios[i] = page.width / page.height;
      await page.close();
    }

    setState(() {
      _isLoading = false;
    });

    if (widget.isVerticalMode) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _scrollToPage(widget.book.currentPage > 0 ? widget.book.currentPage - 1 : 0, animate: false);
        _scrollController.addListener(_onVerticalScroll);
      });
    }
  }

  void _onVerticalScroll() {
    if (_isProgrammaticScroll || _screenWidth == 0) return;

    final viewportCenter = _scrollController.offset + _scrollController.position.viewportDimension / 2;
    double cumulativeOffset = 0;
    
    for (int i = 0; i < _pageCount; i++) {
      final pageHeight = _getPageHeight(i);
      if (cumulativeOffset + pageHeight > viewportCenter) {
        if (i != _currentVisiblePage) {
          _currentVisiblePage = i;
          ref.read(readerProvider.notifier).setPage(i + 1);
        }
        break;
      }
      cumulativeOffset += pageHeight + 8;
    }
  }

  double _getPageHeight(int index) {
    return _screenWidth / (_pageAspectRatios[index] ?? 0.707);
  }

  void _scrollToPage(int index, {bool animate = true}) {
    if (!_scrollController.hasClients || _screenWidth == 0) return;

    double offset = 0;
    for (int i = 0; i < index; i++) {
      offset += _getPageHeight(i) + 8;
    }

    _isProgrammaticScroll = true;
    if (animate) {
      _scrollController.animateTo(offset, duration: const Duration(milliseconds: 300), curve: Curves.easeInOut)
          .then((_) => _isProgrammaticScroll = false);
    } else {
      _scrollController.jumpTo(offset);
      _isProgrammaticScroll = false;
    }
  }

  @override
  void dispose() {
    _transformationController.dispose();
    _pageController.dispose();
    _scrollController.dispose();
    _document?.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    _screenWidth = MediaQuery.of(context).size.width;

    ref.listen<ReaderState>(readerProvider, (previous, next) {
      if (previous != null && previous.currentPage != next.currentPage) {
        final targetIndex = next.currentPage - 1;
        if (widget.isVerticalMode) {
          if (_currentVisiblePage != targetIndex) {
            _scrollToPage(targetIndex);
          }
        } else {
          if (_pageController.hasClients && _pageController.page?.round() != targetIndex) {
            _pageController.jumpToPage(targetIndex);
          }
        }
      }
    });

    return widget.isVerticalMode ? _buildVerticalReader() : _buildHorizontalReader();
  }

  Widget _buildHorizontalReader() {
    return PageView.builder(
      controller: _pageController,
      itemCount: _pageCount,
      physics: _isZoomed ? const NeverScrollableScrollPhysics() : null,
      allowImplicitScrolling: true,
      scrollCacheExtent: const ScrollCacheExtent.viewport(2.0),
      onPageChanged: (index) {
        ref.read(readerProvider.notifier).setPage(index + 1);
      },
      itemBuilder: (context, index) {
        return InteractiveViewer(
          transformationController: _transformationController,
          minScale: 1.0,
          maxScale: 4.0,
          child: Center(
            child: _PdfPageItem(
              document: _document!,
              pageIndex: index,
              aspectRatio: _pageAspectRatios[index] ?? 0.707,
            ),
          ),
        );
      },
    );
  }

  Widget _buildVerticalReader() {
    return InteractiveViewer(
      transformationController: _transformationController,
      minScale: 1.0,
      maxScale: 4.0,
      panAxis: PanAxis.free,
      child: ListView.separated(
        controller: _scrollController,
        physics: _isZoomed ? const NeverScrollableScrollPhysics() : const ClampingScrollPhysics(),
        scrollCacheExtent: ScrollCacheExtent.pixels(_screenWidth * 3),
        itemCount: _pageCount,
        separatorBuilder: (context, index) => const SizedBox(height: 8),
        itemBuilder: (context, index) {
          return _PdfPageItem(
            document: _document!,
            pageIndex: index,
            aspectRatio: _pageAspectRatios[index] ?? 0.707,
          );
        },
      ),
    );
  }
}

class _PdfPageItem extends StatefulWidget {
  final PdfDocument document;
  final int pageIndex;
  final double aspectRatio;

  const _PdfPageItem({
    required this.document,
    required this.pageIndex,
    required this.aspectRatio,
  });

  @override
  State<_PdfPageItem> createState() => _PdfPageItemState();
}

class _PdfPageItemState extends State<_PdfPageItem> {
  Uint8List? _imageBytes;

  @override
  void initState() {
    super.initState();
    _renderPage();
  }

  Future<void> _renderPage() async {
    try {
      final page = await widget.document.getPage(widget.pageIndex + 1);
      final image = await page.render(
        width: page.width * 2,
        height: page.height * 2,
        format: PdfPageImageFormat.jpeg,
        backgroundColor: '#ffffff',
        quality: 100,
      );
      await page.close();

      if (mounted && image != null) {
        setState(() {
          _imageBytes = Uint8List.fromList(image.bytes);
        });
      }
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    if (_imageBytes != null) {
      return AspectRatio(
        aspectRatio: widget.aspectRatio,
        child: Image.memory(
          _imageBytes!,
          fit: BoxFit.contain,
          gaplessPlayback: true,
        ),
      );
    }
    
    return AspectRatio(
      aspectRatio: widget.aspectRatio,
      child: Container(
        color: Colors.grey.shade100,
        child: const Center(
          child: SizedBox(
            width: 24,
            height: 24,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
      ),
    );
  }
}
