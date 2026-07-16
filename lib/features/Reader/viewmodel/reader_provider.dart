import 'package:flutter_riverpod/flutter_riverpod.dart';

class ChapterInfo {
  final String title;
  final int pageNumber;
  final dynamic originalRef; // E.g., PdfBookmark or EpubChapter

  ChapterInfo({
    required this.title,
    required this.pageNumber,
    this.originalRef,
  });
}

class ReaderState {
  final int currentPage;
  final int totalPages;
  final bool isOverlayVisible;
  final List<ChapterInfo> chapters;
  final String chapterSearchQuery;

  ReaderState({
    this.currentPage = 1,
    this.totalPages = 1,
    this.isOverlayVisible = true,
    this.chapters = const [],
    this.chapterSearchQuery = '',
  });

  ReaderState copyWith({
    int? currentPage,
    int? totalPages,
    bool? isOverlayVisible,
    List<ChapterInfo>? chapters,
    String? chapterSearchQuery,
  }) {
    return ReaderState(
      currentPage: currentPage ?? this.currentPage,
      totalPages: totalPages ?? this.totalPages,
      isOverlayVisible: isOverlayVisible ?? this.isOverlayVisible,
      chapters: chapters ?? this.chapters,
      chapterSearchQuery: chapterSearchQuery ?? this.chapterSearchQuery,
    );
  }
}

class ReaderNotifier extends Notifier<ReaderState> {
  @override
  ReaderState build() {
    return ReaderState();
  }

  void reset() {
    state = ReaderState();
  }

  void setPage(int page) {
    if (page != state.currentPage) {
      state = state.copyWith(currentPage: page);
    }
  }

  void setTotalPages(int total) {
    if (total != state.totalPages) {
      state = state.copyWith(totalPages: total);
    }
  }

  void toggleOverlay() {
    state = state.copyWith(isOverlayVisible: !state.isOverlayVisible);
  }

  void setOverlayVisible(bool visible) {
    state = state.copyWith(isOverlayVisible: visible);
  }

  void setChapters(List<ChapterInfo> chapters) {
    state = state.copyWith(chapters: chapters);
  }

  void setChapterSearchQuery(String query) {
    state = state.copyWith(chapterSearchQuery: query);
  }
}

final readerProvider = NotifierProvider<ReaderNotifier, ReaderState>(() {
  return ReaderNotifier();
});
