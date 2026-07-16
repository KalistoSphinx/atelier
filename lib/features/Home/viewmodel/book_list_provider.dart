import 'dart:io';
import 'package:flutter/material.dart';

import 'package:image_app/features/Home/viewmodel/cover_extractor.dart';
import 'package:image_app/features/Home/viewmodel/metadata_extractor.dart';

import 'package:file_picker/file_picker.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_app/features/Home/model/book_model.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

class BookListNotifier extends Notifier<List<Book>> {
  @override
  List<Book> build() {
    _loadSavedBooks();
    return [];
  }

  Future<void> _loadSavedBooks() async {
    final directory = await getApplicationDocumentsDirectory();
    final files = directory.listSync().whereType<File>().toList();

    List<Book> loadedBooks = [];

    for (var file in files) {
      final extension = p.extension(file.path).toLowerCase();
      if (['.pdf', '.epub', '.cbz', '.zip'].contains(extension)) {
        final docName = p.basenameWithoutExtension(file.path);
        final coverPath = p.join(directory.path, '${docName}_cover.jpg');
        String? finalCoverPath;
        if (File(coverPath).existsSync()) {
          finalCoverPath = coverPath;
        }

        final metadata = await MetadataExtractor.extractMetadata(file);

        loadedBooks.add(
          Book(
            id: file.path,
            title: metadata.title ?? docName,
            filePath: file.path,
            coverImagePath: finalCoverPath,
            author: metadata.author,
          ),
        );
      }
    }

    state = loadedBooks;
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
                borderRadius: .circular(16)
              ),
              content: Text('Unsupported file format: $ext'),
              behavior: SnackBarBehavior.floating,
              backgroundColor: Colors.red.shade600,
            ),
          );
        }
        return;
      }

      final originalFile = File(originalPath);
      final directory = await getApplicationDocumentsDirectory();

      final fileName = p.basename(originalFile.path);
      final localFilePath = p.join(directory.path, fileName);

      if (File(localFilePath).existsSync() ||
          state.any((b) => b.filePath == localFilePath)) {
        return; // Stop operation if file is duplicated
      }

      final savedFile = await originalFile.copy(localFilePath);
      final coverPath = await CoverExtractor.extractAndSaveCover(savedFile);
      final metadata = await MetadataExtractor.extractMetadata(savedFile);

      final newBook = Book(
        id: savedFile.path,
        title: metadata.title ?? p.basenameWithoutExtension(savedFile.path),
        filePath: savedFile.path,
        coverImagePath: coverPath,
        author: metadata.author,
      );

      state = [...state, newBook];
    }
  }

  Future<void> deleteBook(Book book) async {
    final file = File(book.filePath);
    if (await file.exists()) {
      await file.delete();
    }

    if (book.coverImagePath != null) {
      final coverFile = File(book.coverImagePath!);
      if (await coverFile.exists()) {
        await coverFile.delete();
      }
    }

    state = state.where((b) => b.id != book.id).toList();
  }

  Future<void> renameBook(Book targetBook, String newName) async {

    final oldFile = File(targetBook.filePath);

    if (await oldFile.exists()) {
      final dir = oldFile.parent;
      final ext = p.extension(oldFile.path);
      final newPath = p.join(dir.path, "$newName$ext");
      final newFile = await oldFile.rename(newPath);
      
      String? newCoverPath;
      if (targetBook.coverImagePath != null) {
        final coverFile = File(targetBook.coverImagePath!);
        if (await coverFile.exists()) {
          final newCoverName = p.join(dir.path, "${newName}_cover.jpg");
          final renamedCover = await coverFile.rename(newCoverName);
          newCoverPath = renamedCover.path;
        }
      }

      state = state.map((b) {
        if (b.filePath == oldFile.path) {
          return Book(
            id: newFile.path,
            title: newName,
            filePath: newFile.path,
            coverImagePath: newCoverPath ?? b.coverImagePath,
            author: b.author
          );
        }
        return b;
      }).toList();
    }
  }
}

final bookListProvider = NotifierProvider<BookListNotifier, List<Book>>(() {
  return BookListNotifier();
});
