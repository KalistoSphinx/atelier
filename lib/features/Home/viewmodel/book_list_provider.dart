import 'dart:io';

import 'package:image_app/features/Home/viewmodel/cover_extractor.dart';

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
      if (['.pdf', '.epub', '.cbz'].contains(extension)) {
        final docName = p.basenameWithoutExtension(file.path);
        final coverPath = p.join(directory.path, '${docName}_cover.jpg');
        String? finalCoverPath;
        if (File(coverPath).existsSync()) {
          finalCoverPath = coverPath;
        }

        loadedBooks.add(
          Book(
            id: file.path,
            title: docName,
            filePath: file.path,
            coverImagePath: finalCoverPath,
          ),
        );
      }
    }

    state = loadedBooks;
  }

  Future<void> pickAndSaveImage() async {
    FilePickerResult? result = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'epub', 'cbz'],
    );

    if (result != null && result.files.single.path != null) {
      final originalFile = File(result.files.single.path!);
      final directory = await getApplicationDocumentsDirectory();

      final fileName = p.basename(originalFile.path);
      final localFilePath = p.join(directory.path, fileName);
      final savedFile = await originalFile.copy(localFilePath);
      final coverPath = await CoverExtractor.extractAndSaveCover(savedFile);

      final newBook = Book(
        id: savedFile.path,
        title: p.basenameWithoutExtension(savedFile.path),
        filePath: savedFile.path,
        coverImagePath: coverPath,
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

  Future<void> renameBook(File oldFile, String newName) async {
    if (await oldFile.exists()) {
      final dir = oldFile.parent;
      final ext = p.extension(oldFile.path);
      final newPath = p.join(dir.path, "$newName$ext");
      final newFile = await oldFile.rename(newPath);

      state = state.map((book) {
        if (book.filePath == oldFile.path) {
          return Book(
            id: newFile.path,
            title: newName,
            filePath: newFile.path,
            coverImagePath: book.coverImagePath,
          );
        }
        return book;
      }).toList();
    }
  }
}

final bookListProvider = NotifierProvider<BookListNotifier, List<Book>>(() {
  return BookListNotifier();
});
