import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_app/features/Home/model/book_model.dart';
import 'package:image_app/features/Home/viewmodel/book_list_provider.dart';
import 'package:image_app/features/Home/view/widgets/rename_image_sheet.dart';

class BookCard extends ConsumerStatefulWidget {
  final Book book;
  final String bookName;
  final String date;

  const BookCard({
    super.key,
    required this.book,
    required this.bookName,
    required this.date,
  });

  @override
  ConsumerState<BookCard> createState() => _BookCardState();
}

class _BookCardState extends ConsumerState<BookCard> {
  Offset _tapPosition = Offset.zero;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Stack(
              fit: StackFit.expand,
              children: [
                Image.file(
                  File(widget.book.coverImagePath!),
                  width: double.infinity,
                  fit: .cover,
                ),
                Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTapDown: (details) {
                      _tapPosition = details.globalPosition;
                    },
                    onLongPress: () async {
                      final selected = await showMenu<String>(
                        context: context,
                        color: Colors.white,
                        elevation: 1,
                        constraints: const BoxConstraints(
                          minWidth: 130
                        ),
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
                              return RenameImageSheet(
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
        Text(
          widget.bookName,
          style: GoogleFonts.robotoMono(
            fontSize: 15,
            fontWeight: FontWeight.w500,
            color: Colors.black,
            letterSpacing: -0.1,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 4),
        Text(
          widget.date,
          style: GoogleFonts.robotoMono(
            fontSize: 13,
            color: Colors.black54, // Muted text color
            fontWeight: FontWeight.w500,
            letterSpacing: -0.3,
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
            "Delete Image",
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.5,
            ),
          ),
          content: const Text(
            "Are you sure you want delete this image?",
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
