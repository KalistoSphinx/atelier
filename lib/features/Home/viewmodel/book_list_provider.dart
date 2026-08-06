import 'dart:io';
import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

import 'package:image_app/core/services/drive_sync_service.dart';
import 'package:image_app/features/Home/viewmodel/cover_extractor.dart';
import 'package:image_app/features/Home/viewmodel/metadata_extractor.dart';
import 'package:image_app/features/Home/viewmodel/library_service.dart';

import 'package:file_picker/file_picker.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_app/features/Home/model/book_model.dart';
import 'package:path/path.dart' as p;

const _uuid = Uuid();

class BookListNotifier extends Notifier<List<Book>> {
  @override
  List<Book> build() {
    _loadBooks();
    return [];
  }

  Future<void> _loadBooks() async {
    final books = await LibraryService.instance.loadBooks();
    state = books;
  }

  Future<void> _persist() async {
    await LibraryService.instance.saveBooks(state);
  }

  Future<void> pickAndSaveImage(BuildContext context) async {
    FilePickerResult? result = await FilePicker.pickFiles(
      type: FileType.any,
    );

    if (result != null && result.files.single.path != null) {
      final originalPath = result.files.single.path!;
      final ext = p.extension(originalPath).toLowerCase();

      if (!['.pdf', '.epub', '.cbz', '.zip'].contains(ext)) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16)
              ),
              content: Text('Unsupported file format: $ext'),
              behavior: SnackBarBehavior.floating,
              backgroundColor: Colors.red.shade600,
            ),
          );
        }
        return;
      }

      final lib = LibraryService.instance;
      await lib.init();

      final originalFile = File(originalPath);
      final originalFileName = p.basename(originalFile.path);

      // Check for duplicate by original file name
      if (state.any((b) => b.originalFileName == originalFileName)) {
        return;
      }

      // Generate stable UUID for this book
      final bookId = _uuid.v4();
      final format = ext.substring(1); // remove the dot
      final fileName = '$bookId$ext';
      final localFilePath = lib.getBookPath(fileName);

      // Copy file to books/ directory
      final savedFile = await originalFile.copy(localFilePath);

      // Extract cover and save to covers/ directory
      final coverPath = await CoverExtractor.extractAndSaveCover(
        savedFile,
        bookId,
      );

      // Extract metadata (only done once at import time)
      final metadata = await MetadataExtractor.extractMetadata(savedFile);

      final newBook = Book(
        id: bookId,
        title: metadata.title ?? p.basenameWithoutExtension(originalFileName),
        author: metadata.author,
        format: format,
        fileName: fileName,
        originalFileName: originalFileName,
        filePath: localFilePath,
        coverImagePath: coverPath,
        dateAdded: DateTime.now(),
      );

      state = [...state, newBook];
      await _persist();
      ref.read(driveSyncServiceProvider).markDirty();
    }
  }

  Future<void> deleteBook(Book book) async {
    // Delete book file
    final file = File(book.filePath);
    if (await file.exists()) {
      await file.delete();
    }

    // Delete cover file
    if (book.coverImagePath != null) {
      final coverFile = File(book.coverImagePath!);
      if (await coverFile.exists()) {
        await coverFile.delete();
      }
    }

    state = state.where((b) => b.id != book.id).toList();
    await _persist();
    ref.read(driveSyncServiceProvider).markDirty();
  }

  Future<void> renameBook(Book targetBook, String newName) async {
    state = state.map((b) {
      if (b.id == targetBook.id) {
        return b.copyWith(title: newName);
      }
      return b;
    }).toList();
    await _persist();
    ref.read(driveSyncServiceProvider).markDirty();
  }

  Future<void> updateProgress(String bookId, int currentPage, int totalPages) async {
    state = state.map((b) {
      if (b.id == bookId) {
        return b.copyWith(currentPage: currentPage, totalPages: totalPages);
      }
      return b;
    }).toList();
    await _persist();
    ref.read(driveSyncServiceProvider).markDirty();
  }

  Future<void> updateLastOpened(String bookId) async {
    state = state.map((b) {
      if (b.id == bookId) {
        return b.copyWith(lastOpened: DateTime.now());
      }
      return b;
    }).toList();
    await _persist();
  }
}

final bookListProvider = NotifierProvider<BookListNotifier, List<Book>>(() {
  return BookListNotifier();
});
