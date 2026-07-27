import 'dart:typed_data';

import 'package:archive/archive_io.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_app/features/Home/model/book_model.dart';
import 'package:image_app/features/Reader/viewmodel/reader_provider.dart';
import 'package:path/path.dart' as p;

class CbzViewerWidget extends ConsumerStatefulWidget {
  final Book book;

  const CbzViewerWidget({super.key, required this.book});

  @override
  ConsumerState<CbzViewerWidget> createState() => _CbzViewerWidgetState();
}

class _CbzViewerWidgetState extends ConsumerState<CbzViewerWidget> {
  late InputFileStream _inputStream;
  late Archive _archive;

  /// Pre-decoded image bytes for every page in the CBZ.
  /// Built once at load so pageview items get instant Uint8List access.
  final List<Uint8List> _decodedPages = [];

  bool _isLoading = true;
  String? _error;
  late PageController _pageController;

  final TransformationController _transformationController = TransformationController();
  bool _isZoomed = false;

  @override
  void initState() {
    super.initState();
    final initialIndex = widget.book.currentPage > 0 ? widget.book.currentPage - 1 : 0;
    _pageController = PageController(initialPage: initialIndex);
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

      final imageFiles = _archive.where((file) {
        final ext = p.extension(file.name).toLowerCase();
        return file.isFile &&
            ['.jpg', '.jpeg', '.png', '.webp'].contains(ext) &&
            !file.name.startsWith('__MACOSX'); // Exclude macos hidden files
      }).toList();

      imageFiles.sort((a, b) => a.name.compareTo(b.name));

      // Pre-decode all image bytes up front so pageview items never
      // have to do any conversion work — they get raw Uint8List instantly.
      for (final file in imageFiles) {
        final content = file.content as List<int>;
        _decodedPages.add(Uint8List.fromList(content));
      }

      WidgetsBinding.instance.addPostFrameCallback((_) {
        ref.read(readerProvider.notifier).setTotalPages(_decodedPages.length);
      });

      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = "Error loading CBZ: $e";
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _transformationController.dispose();
    _pageController.dispose();
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

    if (_decodedPages.isEmpty) {
      return const Center(child: Text("No images found in CBZ."));
    }

    // Listen to provider state changes to handle external page jumps (like from the slider)
    ref.listen<ReaderState>(readerProvider, (previous, next) {
      if (previous != null && previous.currentPage != next.currentPage) {
        if (_pageController.hasClients &&
            _pageController.page?.round() != next.currentPage - 1) {
          _pageController.jumpToPage(next.currentPage - 1);
        }
      }
    });

    return PageView.builder(
      controller: _pageController,
      itemCount: _decodedPages.length,
      physics: _isZoomed ? const NeverScrollableScrollPhysics() : null,
      // Pre-build adjacent pages so swiping feels zero-delay
      allowImplicitScrolling: true,
      onPageChanged: (index) {
        ref.read(readerProvider.notifier).setPage(index + 1);
      },
      itemBuilder: (context, index) {
        return InteractiveViewer(
          transformationController: _transformationController,
          minScale: 1.0,
          maxScale: 4.0,
          child: Center(
            child: Image.memory(
              _decodedPages[index],
              fit: BoxFit.contain,
              gaplessPlayback: true,
            ),
          ),
        );
      },
    );
  }
}
