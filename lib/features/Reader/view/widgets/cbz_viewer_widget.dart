import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:archive/archive_io.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_app/features/Home/model/book_model.dart';
import 'package:image_app/features/Reader/viewmodel/reader_provider.dart';
import 'package:path/path.dart' as p;

class CbzViewerWidget extends ConsumerStatefulWidget {
  final Book book;
  final bool isVerticalMode;

  const CbzViewerWidget({
    super.key,
    required this.book,
    this.isVerticalMode = false,
  });

  @override
  ConsumerState<CbzViewerWidget> createState() => _CbzViewerWidgetState();
}

class _CbzViewerWidgetState extends ConsumerState<CbzViewerWidget> {
  late InputFileStream _inputStream;
  late Archive _archive;
  List<ArchiveFile> _imageFiles = [];

  bool _isLoading = true;
  String? _error;

  late PageController _pageController;
  late ScrollController _scrollController;
  double _screenWidth = 0;
  int _currentVisiblePage = 0;
  bool _isProgrammaticScroll = false;

  final TransformationController _transformationController = TransformationController();
  bool _isZoomed = false;
  
  double _globalAspectRatio = 0.707; // Default aspect ratio, updated by first page

  @override
  void initState() {
    super.initState();
    final initialIndex = widget.book.currentPage > 0 ? widget.book.currentPage - 1 : 0;
    _pageController = PageController(initialPage: initialIndex);
    _scrollController = ScrollController();
    _transformationController.addListener(_onZoomChange);
    _loadArchive();
  }

  void _onZoomChange() {
    final isZoomed = _transformationController.value.getMaxScaleOnAxis() > 1.01;
    if (isZoomed != _isZoomed) {
      setState(() {
        _isZoomed = isZoomed;
      });
    }
  }

  Future<void> _loadArchive() async {
    try {
      _inputStream = InputFileStream(widget.book.filePath);
      _archive = ZipDecoder().decodeBuffer(_inputStream);

      _imageFiles = _archive.where((file) {
        final ext = p.extension(file.name).toLowerCase();
        return file.isFile &&
            ['.jpg', '.jpeg', '.png', '.webp'].contains(ext) &&
            !file.name.startsWith('__MACOSX');
      }).toList();

      _imageFiles.sort((a, b) => a.name.compareTo(b.name));
      
      // Calculate aspect ratio from the first image to use for all images in vertical mode
      // This prevents jitter without having to decode all images on load
      if (widget.isVerticalMode && _imageFiles.isNotEmpty) {
        try {
          final content = _imageFiles.first.content as List<int>;
          final bytes = Uint8List.fromList(content);
          final codec = await ui.instantiateImageCodec(bytes);
          final frame = await codec.getNextFrame();
          _globalAspectRatio = frame.image.width / frame.image.height;
          frame.image.dispose();
          codec.dispose();
        } catch (_) {}
      }

      WidgetsBinding.instance.addPostFrameCallback((_) {
        ref.read(readerProvider.notifier).setTotalPages(_imageFiles.length);
      });

      setState(() {
        _isLoading = false;
      });

      if (widget.isVerticalMode) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _scrollToPage(widget.book.currentPage > 0 ? widget.book.currentPage - 1 : 0, animate: false);
          _scrollController.addListener(_onVerticalScroll);
        });
      }
    } catch (e) {
      setState(() {
        _error = "Error loading CBZ: $e";
        _isLoading = false;
      });
    }
  }

  void _onVerticalScroll() {
    if (_isProgrammaticScroll || _screenWidth == 0 || _imageFiles.isEmpty) return;

    final viewportCenter = _scrollController.offset + _scrollController.position.viewportDimension / 2;
    double cumulativeOffset = 0;
    
    for (int i = 0; i < _imageFiles.length; i++) {
      final pageHeight = _getPageHeight();
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

  double _getPageHeight() {
    return _screenWidth / _globalAspectRatio;
  }

  void _scrollToPage(int index, {bool animate = true}) {
    if (!_scrollController.hasClients || _screenWidth == 0 || _imageFiles.isEmpty) return;

    double offset = 0;
    for (int i = 0; i < index; i++) {
      offset += _getPageHeight() + 8;
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
    _inputStream.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(child: Text(_error!));
    }

    if (_imageFiles.isEmpty) {
      return const Center(child: Text("No images found in CBZ."));
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
      itemCount: _imageFiles.length,
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
            child: _CbzPageItem(
              archiveFile: _imageFiles[index],
              aspectRatio: _globalAspectRatio,
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
        itemCount: _imageFiles.length,
        separatorBuilder: (context, index) => const SizedBox(height: 8),
        itemBuilder: (context, index) {
          return _CbzPageItem(
            archiveFile: _imageFiles[index],
            aspectRatio: _globalAspectRatio,
          );
        },
      ),
    );
  }
}

class _CbzPageItem extends StatefulWidget {
  final ArchiveFile archiveFile;
  final double aspectRatio;

  const _CbzPageItem({
    required this.archiveFile,
    required this.aspectRatio,
  });

  @override
  State<_CbzPageItem> createState() => _CbzPageItemState();
}

class _CbzPageItemState extends State<_CbzPageItem> {
  Uint8List? _imageBytes;

  @override
  void initState() {
    super.initState();
    _loadImage();
  }

  void _loadImage() {
    // Lazily load image content to prevent blocking the UI heavily on startup
    // and to save memory by only holding visible/cached pages
    Future.microtask(() {
      if (!mounted) return;
      try {
        final content = widget.archiveFile.content as List<int>;
        setState(() {
          _imageBytes = Uint8List.fromList(content);
        });
      } catch (_) {}
    });
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
