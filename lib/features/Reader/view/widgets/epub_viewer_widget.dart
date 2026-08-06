import 'dart:io';


import 'package:epubx/epubx.dart' hide Image;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
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
  final List<EpubChapter> _flatChapters = [];
  late PageController _pageController;

  @override
  void initState() {
    super.initState();
    final initialIndex = widget.book.currentPage > 0 ? widget.book.currentPage - 1 : 0;
    _pageController = PageController(initialPage: initialIndex);
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
        ref
            .read(readerProvider.notifier)
            .setTotalPages(chapterInfos.isNotEmpty ? chapterInfos.length : 1);
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

    if (_flatChapters.isEmpty || _epubBook == null) {
      return const Center(child: Text("No chapters found in EPUB."));
    }

    // Listen to external page changes (e.g., from slider or chapter list)
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
      itemCount: _flatChapters.length,
      allowImplicitScrolling: true,
      scrollCacheExtent: const ScrollCacheExtent.viewport(2.0),
      onPageChanged: (index) {
        ref.read(readerProvider.notifier).setPage(index + 1);
      },
      itemBuilder: (context, index) {
        return _ChapterPage(
          key: ValueKey('epub_ch_$index'),
          chapter: _flatChapters[index],
          epubBook: _epubBook!,
        );
      },
    );
  }
}

/// Extracted as a separate widget so each chapter page maintains its own
/// scroll state independently and Flutter can cache/dispose them efficiently.
class _ChapterPage extends StatelessWidget {
  final EpubChapter chapter;
  final EpubBook epubBook;

  const _ChapterPage({
    super.key,
    required this.chapter,
    required this.epubBook,
  });

  @override
  Widget build(BuildContext context) {
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
              if (src != null) {
                // Find image in the parsed epub content directly instead of caching them all
                final fileName = src.split('/').last;
                final images = epubBook.Content?.Images;
                
                if (images != null) {
                  // The map keys are full paths, so we need to match by filename
                  final match = images.entries.where((e) => e.key.endsWith(fileName)).firstOrNull;
                  if (match != null && match.value.Content != null) {
                    return Image.memory(
                      Uint8List.fromList(match.value.Content!),
                      fit: BoxFit.contain,
                      gaplessPlayback: true,
                    );
                  }
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
  }
}
