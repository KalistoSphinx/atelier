import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_app/features/Home/view/widgets/book_card.dart';
import 'package:image_app/features/Home/viewmodel/book_list_provider.dart';
import 'package:image_app/features/Home/model/book_model.dart';
import '../widgets/custom_bottom_nav_bar.dart';
import '../widgets/fade_in_drop.dart';
import '../../../../features/Profile/view/pages/profile_page.dart';
import 'library_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      body: Stack(
        fit: .expand,
        children: [
          IndexedStack(
            index: currentIndex,
            children: const [_HomeContent(), ProfilePage()],
          ),

          Positioned(
            left: 0,
            right: 0,
            bottom: 40,
            child: CustomBottomNavBar(
              currentIndex: currentIndex,
              onTap: (index) {
                setState(() {
                  currentIndex = index;
                });
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _HomeContent extends ConsumerStatefulWidget {
  const _HomeContent();

  @override
  ConsumerState<_HomeContent> createState() => _HomeContentState();
}

class _HomeContentState extends ConsumerState<_HomeContent> {
  String _searchQuery = '';
  Timer? _debounce;

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final allBooks = ref.watch(bookListProvider);
    final theme = Theme.of(context).colorScheme;
    final books = _searchQuery.isEmpty
        ? allBooks
        : allBooks.where((book) {
            return book.title.toLowerCase().contains(_searchQuery.toLowerCase());
          }).toList();

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: .max,
            children: [
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    "Home",
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.6,
                    ),
                  ),
                  CupertinoButton(
                    onPressed: () {
                      ref.read(bookListProvider.notifier).pickAndSaveImage(context);
                    },
                    padding: EdgeInsets.zero,
                    child:   Icon(Icons.add, size: 28, color: theme.onSurface,),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              // Search Bar
              TextField(
                onChanged: (value) {
                  if (_debounce?.isActive ?? false) _debounce?.cancel();
                  _debounce = Timer(const Duration(milliseconds: 300), () {
                    if (mounted) {
                      setState(() {
                        _searchQuery = value;
                      });
                    }
                  });
                },
                decoration: InputDecoration(
                  hintText: 'Search...',
                  hintStyle:  TextStyle(
                    color: theme.onSurfaceVariant,
                    fontSize: 15,
                    letterSpacing: -0.2,
                    fontWeight: .w500,
                  ),
                  prefixIcon: Icon(
                    Icons.search,
                    color: theme.onSurfaceVariant,
                    size: 22,
                  ),
                  filled: true,
                  fillColor: theme.surfaceContainerHighest,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: .none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 16,
                  ),
                ),
              ),
              const SizedBox(height: 24),

              books.isEmpty
                  ? Padding(
                      padding: const EdgeInsets.only(top: 175),
                      child: Column(
                        children: [
                          Icon(
                            _searchQuery.isNotEmpty
                                ? CupertinoIcons.search
                                : CupertinoIcons.photo_on_rectangle,
                            size: 64,
                            color: Colors.grey.shade300,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            _searchQuery.isNotEmpty
                                ? "No results found"
                                : "No books saved",
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              color: Colors.grey.shade400,
                              letterSpacing: -0.3,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            _searchQuery.isNotEmpty
                                ? "Try a different search term"
                                : "Tap + to add your first book",
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey.shade400,
                            ),
                          ),
                        ],
                      ),
                    )
                  : _searchQuery.isNotEmpty
                      ? GridView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: books.length,
                          gridDelegate:
                              const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 2,
                                crossAxisSpacing: 16,
                                mainAxisSpacing: 30,
                                childAspectRatio: 0.48,
                              ),
                          itemBuilder: (context, index) {
                            final book = books[index];
                            return FadeInDrop(
                              delayInMilliseconds: index * 100,
                              child: BookCard(
                                book: book,
                                bookName: book.title,
                                showAuthor: true,
                                showChapterNum: true,
                                showProgressBar: true,
                              ),
                            );
                          },
                        )
                      : Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildContinueReadingSection(books),
                            const SizedBox(height: 20),
                            _buildRecentlyAddedSection(books),
                            SizedBox(
                              width: double.infinity,
                              height: 56,
                              child: OutlinedButton(
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => const LibraryPage(),
                                    ),
                                  );
                                },
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: theme.onSurface,
                                  backgroundColor: theme.surfaceContainerHighest,
                                  side: .none,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                ),
                                child: const Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(CupertinoIcons.book, size: 20),
                                    SizedBox(width: 8),
                                    Text(
                                      "Browse Library",
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),

              const SizedBox(height: 120), // Spacer for floating bottom nav bar
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildContinueReadingSection(List<Book> allBooks) {
    // Filter books opened at least once and not completely finished
    final continueReading = allBooks.where((b) {
      if (b.lastOpened == null) return false;
      if (b.currentPage >= b.totalPages && b.totalPages > 0) return false;
      return true;
    }).toList()
      ..sort((a, b) => b.lastOpened!.compareTo(a.lastOpened!));

    if (continueReading.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Reading Now",
          style: TextStyle(
            fontSize: 20,
            fontWeight: .bold,
            letterSpacing: -0.2,
          ),
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 280,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: continueReading.length,
            separatorBuilder: (context, index) => const SizedBox(width: 16),
            itemBuilder: (context, index) {
              final book = continueReading[index];
              return FadeInDrop(
                delayInMilliseconds: index * 100,
                child: SizedBox(
                  width: 130, // Scale down the card horizontally
                  child: BookCard(
                    book: book,
                    bookName: book.title,
                    showAuthor: true,
                    showChapterNum: false,
                    showProgressBar: true,
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildRecentlyAddedSection(List<Book> allBooks) {
    final recentBooks = List.of(allBooks)
      ..sort((a, b) => b.dateAdded.compareTo(a.dateAdded));

    if (recentBooks.isEmpty) return const SizedBox.shrink();

    // Show up to 10 most recent books
    final displayBooks = recentBooks.take(10).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Recently Added",
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            letterSpacing: -0.2,
          ),
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 280,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: displayBooks.length,
            separatorBuilder: (context, index) => const SizedBox(width: 16),
            itemBuilder: (context, index) {
              final book = displayBooks[index];
              return FadeInDrop(
                delayInMilliseconds: index * 100,
                child: SizedBox(
                  width: 130, // Scale down the card horizontally
                  child: BookCard(
                    book: book,
                    bookName: book.title,
                    showAuthor: true,
                    showChapterNum: false,
                    showProgressBar: false,
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
