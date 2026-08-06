import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_app/features/Home/viewmodel/book_list_provider.dart';
import 'package:image_app/features/Home/view/widgets/book_card.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

class LibraryPage extends ConsumerWidget {
  const LibraryPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final books = ref.watch(bookListProvider);
    
    // Sort books by recently added
    final sortedBooks = List.of(books)
      ..sort((a, b) => b.dateAdded.compareTo(a.dateAdded));

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(LucideIcons.arrowLeft, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          "Library",
          style: TextStyle(
            color: Colors.black,
            fontSize: 20,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.5,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: sortedBooks.isEmpty
            ? Center(
                child: Text(
                  "No books saved",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey.shade400,
                    letterSpacing: -0.3,
                  ),
                ),
              )
            : Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: GridView.builder(
                  padding: const EdgeInsets.only(top: 20, bottom: 40),
                  itemCount: sortedBooks.length,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 30,
                    childAspectRatio: 0.48,
                  ),
                  itemBuilder: (context, index) {
                    final book = sortedBooks[index];
                    return BookCard(
                      book: book,
                      bookName: book.title,
                      showAuthor: true,
                    );
                  },
                ),
              ),
      ),
    );
  }
}
