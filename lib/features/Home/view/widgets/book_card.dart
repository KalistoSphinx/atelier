import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_app/features/Home/model/book_model.dart';
import 'package:image_app/features/Home/viewmodel/book_list_provider.dart';
import 'package:image_app/features/Home/view/widgets/rename_image_sheet.dart';
import 'package:image_app/features/Reader/view/pages/reader_page.dart';

class BookCard extends ConsumerStatefulWidget {
  final Book book;
  final String bookName;
  final bool showProgressBar;
  final bool showChapterNum;
  final bool showAuthor;

  const BookCard({
    super.key,
    required this.book,
    required this.bookName,
    this.showProgressBar = true,
    this.showChapterNum = true,
    this.showAuthor = false,
  });

  @override
  ConsumerState<BookCard> createState() => _BookCardState();
}

class _BookCardState extends ConsumerState<BookCard> {
  Offset _tapPosition = Offset.zero;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(14),
            child: Stack(
              fit: StackFit.expand,
              children: [
                if (widget.book.coverImagePath != null &&
                    widget.book.coverImagePath!.isNotEmpty)
                  Image.file(
                    File(widget.book.coverImagePath!),
                    width: double.infinity,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        width: double.infinity,
                        color: Colors.grey[200],
                        child: const Center(
                          child: Icon(
                            Icons.broken_image,
                            size: 50,
                            color: Colors.grey,
                          ),
                        ),
                      );
                    },
                  )
                else
                  Container(
                    width: double.infinity,
                    color: Colors.grey[200],
                    child: const Center(
                      child: Icon(
                        Icons.image_not_supported,
                        size: 50,
                        color: Colors.grey,
                      ),
                    ),
                  ),
                Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () {
                      ref.read(bookListProvider.notifier).updateLastOpened(widget.book.id);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ReaderPage(book: widget.book),
                        ),
                      );
                    },
                    onTapDown: (details) {
                      _tapPosition = details.globalPosition;
                    },
                    onLongPress: () async {
                      final selected = await showMenu<String>(
                        context: context,
                        color: Colors.white,
                        elevation: 1,
                        constraints: const BoxConstraints(minWidth: 130),
                        position: RelativeRect.fromLTRB(
                          _tapPosition.dx,
                          _tapPosition.dy,
                          _tapPosition.dx,
                          _tapPosition.dy,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        items: [
                          const PopupMenuItem(
                            value: 'rename',
                            child: Row(
                              children: [
                                Icon(Icons.edit, size: 20),
                                SizedBox(width: 12),
                                Text("Rename"),
                              ],
                            ),
                          ),
                          const PopupMenuItem(
                            value: 'delete',
                            child: Row(
                              children: [
                                Icon(Icons.delete, color: Colors.red, size: 20),
                                SizedBox(width: 12),
                                Text(
                                  "Delete",
                                  style: TextStyle(color: Colors.red),
                                ),
                              ],
                            ),
                          ),
                        ],
                      );

                      if (selected == 'rename') {
                        if (context.mounted) {
                          showModalBottomSheet(
                            context: context,
                            isScrollControlled: true,
                            backgroundColor: Colors.white,
                            shape: const RoundedRectangleBorder(
                              borderRadius: BorderRadius.vertical(
                                top: Radius.circular(24),
                              ),
                            ),
                            builder: (context) {
                              return RenameBookSheet(
                                book: widget.book,
                                initialName: widget.book.title,
                              );
                            },
                          );
                        }
                      } else if (selected == 'delete') {
                        if (context.mounted) {
                          _showDeleteDialog(context, ref);
                        }
                      }
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 80,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              // Fixed-height title block — same height whether 1 or 2 lines render
              Text(
                widget.bookName,
                style: GoogleFonts.robotoMono(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Colors.black,
                  letterSpacing: -0.1,
                  height: 1.4,
                ),
                maxLines: widget.showAuthor ? 1 : 2,
                overflow: TextOverflow.ellipsis,
              ),
              if (widget.showAuthor)
                Padding(
                  padding: const EdgeInsets.only(top: 2),
                  child: Text(
                    widget.book.author?.isNotEmpty == true ? widget.book.author! : 'Unknown Author',
                    style: GoogleFonts.robotoMono(
                      fontSize: 12,
                      color: Colors.black54,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              if (!widget.showAuthor) const SizedBox(height: 18) else const SizedBox(height: 6),
              // Progress block
              if (widget.showProgressBar)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (widget.showChapterNum) ...[
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            widget.book.format == 'epub'
                                ? "Ch. ${widget.book.currentPage}"
                                : "Page ${widget.book.currentPage}",
                            style: GoogleFonts.robotoMono(
                              fontSize: 11,
                              color: Colors.black54,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          Text(
                            "${widget.book.totalPages > 1 ? ((widget.book.currentPage / widget.book.totalPages) * 100).toInt() : 0}%",
                            style: GoogleFonts.robotoMono(
                              fontSize: 11,
                              color: Colors.black54,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                    ],
                    LinearProgressIndicator(
                      value: widget.book.totalPages > 1
                          ? widget.book.currentPage / widget.book.totalPages
                          : 0.0,
                      backgroundColor: Colors.grey.shade200,
                      color: Colors.black,
                      minHeight: 5,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ],
                ),
            ],
          ),
        ),
      ],
    );
  }

  void _showDeleteDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          elevation: 1,
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Text(
            "Delete Book",
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.6,
            ),
          ),
          content: const Text(
            "Are you sure you want delete this book?",
            style: TextStyle(fontSize: 15, color: Colors.black87),
          ),
          actionsPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 12,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              style: TextButton.styleFrom(
                foregroundColor: Colors.black54,
                textStyle: const TextStyle(
                  fontFamily: "manrope",
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              child: const Text("Cancel"),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                ref.read(bookListProvider.notifier).deleteBook(widget.book);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red.shade600,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(100),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 18,
                  vertical: 8,
                ),
              ),
              child: const Text(
                "Delete",
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
              ),
            ),
          ],
        );
      },
    );
  }
}
