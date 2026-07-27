class Book {
  final String id;
  final String title;
  final String? author;
  final String format;
  final String fileName;
  final String originalFileName;
  final String filePath;
  final String? coverImagePath;
  final DateTime dateAdded;
  final DateTime? lastOpened;
  final int currentPage;
  final int totalPages;

  Book({
    required this.id,
    required this.title,
    this.author,
    required this.format,
    required this.fileName,
    required this.originalFileName,
    required this.filePath,
    this.coverImagePath,
    required this.dateAdded,
    this.lastOpened,
    this.currentPage = 1,
    this.totalPages = 1,
  });

  factory Book.fromJson(Map<String, dynamic> json) {
    return Book(
      id: json['id'] as String,
      title: json['title'] as String,
      author: json['author'] as String?,
      format: json['format'] as String,
      fileName: json['fileName'] as String,
      originalFileName: json['originalFileName'] as String,
      filePath: json['filePath'] as String,
      coverImagePath: json['coverImagePath'] as String?,
      dateAdded: DateTime.parse(json['dateAdded'] as String),
      lastOpened: json['lastOpened'] != null
          ? DateTime.parse(json['lastOpened'] as String)
          : null,
      currentPage: json['currentPage'] as int? ?? 1,
      totalPages: json['totalPages'] as int? ?? 1,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      if (author != null) 'author': author,
      'format': format,
      'fileName': fileName,
      'originalFileName': originalFileName,
      'filePath': filePath,
      if (coverImagePath != null) 'coverImagePath': coverImagePath,
      'dateAdded': dateAdded.toIso8601String(),
      if (lastOpened != null) 'lastOpened': lastOpened!.toIso8601String(),
      'currentPage': currentPage,
      'totalPages': totalPages,
    };
  }

  Book copyWith({
    String? id,
    String? title,
    String? author,
    String? format,
    String? fileName,
    String? originalFileName,
    String? filePath,
    String? coverImagePath,
    DateTime? dateAdded,
    DateTime? lastOpened,
    int? currentPage,
    int? totalPages,
  }) {
    return Book(
      id: id ?? this.id,
      title: title ?? this.title,
      author: author ?? this.author,
      format: format ?? this.format,
      fileName: fileName ?? this.fileName,
      originalFileName: originalFileName ?? this.originalFileName,
      filePath: filePath ?? this.filePath,
      coverImagePath: coverImagePath ?? this.coverImagePath,
      dateAdded: dateAdded ?? this.dateAdded,
      lastOpened: lastOpened ?? this.lastOpened,
      currentPage: currentPage ?? this.currentPage,
      totalPages: totalPages ?? this.totalPages,
    );
  }
}
