import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:image_app/features/Home/model/book_model.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

class LibraryService {
  static LibraryService? _instance;
  late final Directory _booksDir;
  late final Directory _coversDir;
  late final File _libraryFile;
  bool _initialized = false;

  LibraryService._();

  static LibraryService get instance {
    _instance ??= LibraryService._();
    return _instance!;
  }

  Directory get booksDir => _booksDir;
  Directory get coversDir => _coversDir;
  File get libraryFile => _libraryFile;

  Future<void> init() async {
    if (_initialized) return;

    final baseDir = await getApplicationDocumentsDirectory();
    _booksDir = Directory(p.join(baseDir.path, 'books'));
    _coversDir = Directory(p.join(baseDir.path, 'covers'));
    _libraryFile = File(p.join(baseDir.path, 'library.json'));

    if (!await _booksDir.exists()) await _booksDir.create(recursive: true);
    if (!await _coversDir.exists()) await _coversDir.create(recursive: true);

    _initialized = true;
  }

  String getBookPath(String fileName) => p.join(_booksDir.path, fileName);
  String getCoverPath(String bookId) => p.join(_coversDir.path, '$bookId.jpg');

  /// Load all books from the JSON index. Returns empty list if no file exists.
  Future<List<Book>> loadBooks() async {
    await init();

    if (!await _libraryFile.exists()) return [];

    try {
      final content = await _libraryFile.readAsString();
      final json = jsonDecode(content) as Map<String, dynamic>;
      final booksJson = json['books'] as List<dynamic>;

      return booksJson
          .map((b) => Book.fromJson(b as Map<String, dynamic>))
          .toList();
    } catch (e) {
      debugPrint('Error loading library.json: $e');
      return [];
    }
  }

  /// Persist the full book list to JSON using atomic write.
  Future<void> saveBooks(List<Book> books) async {
    await init();

    final data = {
      'version': 1,
      'books': books.map((b) => b.toJson()).toList(),
    };

    final jsonString = const JsonEncoder.withIndent('  ').convert(data);

    // Atomic write: write to temp file, then rename
    final tempFile = File('${_libraryFile.path}.tmp');
    await tempFile.writeAsString(jsonString, flush: true);
    await tempFile.rename(_libraryFile.path);
  }
}
