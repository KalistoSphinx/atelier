import 'dart:io';

import 'package:epubx/epubx.dart' hide Image;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_app/features/Home/model/book_model.dart';
import 'package:image_app/features/Reader/viewmodel/reader_provider.dart';

class EpubViewerWidget extends ConsumerStatefulWidget {
  final Book book;

  const EpubViewerWidget({super.key, required this.book});

  @override
  ConsumerState<EpubViewerWidget> createState() => _EpubViewerWidgetState();
}

class _EpubViewerWidgetState extends ConsumerState<EpubViewerWidget> {
  bool _isLoading = true;
  String? _error;
  EpubBook? _epubBook;
  List<EpubChapter> _flatChapters = [];
  late PageController _pageController;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _loadEpub();
  }

  Future<void> _loadEpub() async {
    try {
      // Delay to avoid jitter during navigation transitions
      await Future.delayed(const Duration(milliseconds: 300));

      final bytes = await File(widget.book.filePath).readAsBytes();
      
      // Parse epub book in a separate isolate to keep UI smooth
      _epubBook = await compute(EpubReader.readBook, bytes);
      
      _extractChapters(_epubBook!.Chapters ?? []);

      final List<ChapterInfo> chapterInfos = [];
      for (int i = 0; i < _flatChapters.length; i++) {
        chapterInfos.add(
          ChapterInfo(
            title: _flatChapters[i].Title ?? 'Chapter ${i + 1}',
            pageNumber: i + 1,
            originalRef: _flatChapters[i],
          ),
        );
      }

      WidgetsBinding.instance.addPostFrameCallback((_) {
        ref.read(readerProvider.notifier).setChapters(chapterInfos);
        ref.read(readerProvider.notifier).setTotalPages(chapterInfos.isNotEmpty ? chapterInfos.length : 1);
      });

      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = "Error loading EPUB: $e";
          _isLoading = false;
        });
      }
    }
  }

  void _extractChapters(List<EpubChapter> chapters) {
    for (var ch in chapters) {
      _flatChapters.add(ch);
      if (ch.SubChapters != null && ch.SubChapters!.isNotEmpty) {
        _extractChapters(ch.SubChapters!);
      }
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
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

    if (_flatChapters.isEmpty) {
      return const Center(child: Text("No chapters found in EPUB."));
    }

    // Listen to external page changes (e.g., from slider or chapter list)
    ref.listen<ReaderState>(readerProvider, (previous, next) {
      if (previous != null && previous.currentPage != next.currentPage) {
        if (_pageController.hasClients && _pageController.page?.round() != next.currentPage - 1) {
          _pageController.jumpToPage(next.currentPage - 1);
        }
      }
    });

    return PageView.builder(
      controller: _pageController,
      itemCount: _flatChapters.length,
      onPageChanged: (index) {
        ref.read(readerProvider.notifier).setPage(index + 1);
      },
      itemBuilder: (context, index) {
        final chapter = _flatChapters[index];
        final htmlContent = chapter.HtmlContent ?? '';

        return SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 60),
          child: Html(
            data: htmlContent,
            extensions: [
              TagExtension(
                tagsToExtend: {"img"},
                builder: (extensionContext) {
                  final src = extensionContext.attributes['src'];
                  if (src != null && _epubBook?.Content?.Images != null) {
                    // Try to match the image source in the EPUB images map
                    final fileName = src.split('/').last;
                    final imageEntry = _epubBook!.Content!.Images!.entries
                        .where((e) => e.key.endsWith(fileName))
                        .firstOrNull;

                    if (imageEntry != null && imageEntry.value.Content != null) {
                      final bytes = Uint8List.fromList(imageEntry.value.Content!);
                      return Image.memory(
                        bytes,
                        fit: BoxFit.contain,
                        gaplessPlayback: true,
                      );
                    }
                  }
                  return const Icon(Icons.broken_image);
                },
              ),
            ],
            style: {
              "body": Style(
                fontSize: FontSize(18.0),
                lineHeight: const LineHeight(1.6),
                margin: Margins.zero,
                padding: HtmlPaddings.zero,
              ),
            },
          ),
        );
      },
    );
  }
}
