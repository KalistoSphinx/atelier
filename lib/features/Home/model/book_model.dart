class Book {
  final String id;
  final String title;
  final String filePath;
  final String? coverImagePath;

  Book({
    required this.id,
    required this.title,
    required this.filePath,
    this.coverImagePath,
  });
}
