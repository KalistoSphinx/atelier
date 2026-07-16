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
  List<ArchiveFile> _imageFiles = [];
  bool _isLoading = true;
  String? _error;
  late PageController _pageController;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _loadArchive();
  }

  Future<void> _loadArchive() async {
    try {
      _inputStream = InputFileStream(widget.book.filePath);
      _archive = ZipDecoder().decodeBuffer(_inputStream);

      _imageFiles = _archive.where((file) {
        final ext = p.extension(file.name).toLowerCase();
        return file.isFile &&
            ['.jpg', '.jpeg', '.png', '.webp'].contains(ext) &&
            !file.name.startsWith('__MACOSX'); // Exclude macos hidden files
      }).toList();

      _imageFiles.sort((a, b) => a.name.compareTo(b.name));

      WidgetsBinding.instance.addPostFrameCallback((_) {
        ref.read(readerProvider.notifier).setTotalPages(_imageFiles.length);
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

    if (_imageFiles.isEmpty) {
      return const Center(child: Text("No images found in CBZ."));
    }

    // Listen to provider state changes to handle external page jumps (like from the slider)
    ref.listen<ReaderState>(readerProvider, (previous, next) {
      if (previous != null && previous.currentPage != next.currentPage) {
        if (_pageController.hasClients && _pageController.page?.round() != next.currentPage - 1) {
          _pageController.jumpToPage(next.currentPage - 1);
        }
      }
    });

    return InteractiveViewer(
      minScale: 1.0,
      maxScale: 4.0,
      child: PageView.builder(
        controller: _pageController,
        itemCount: _imageFiles.length,
        onPageChanged: (index) {
          ref.read(readerProvider.notifier).setPage(index + 1);
        },
        itemBuilder: (context, index) {
          final file = _imageFiles[index];
          final content = file.content as List<int>;
          final bytes = Uint8List.fromList(content);

          return Image.memory(
            bytes,
            fit: BoxFit.contain,
            gaplessPlayback: true,
          );
        },
      ),
    );
  }
}
