import 'dart:developer';
import 'dart:io';
import 'package:epubx/epubx.dart';
import 'package:path/path.dart' as p;
import 'package:syncfusion_flutter_pdf/pdf.dart' as sync_pdf;

class MetadataExtractor {
  static Future<({String? title, String? author})> extractMetadata(File documentFile) async {
    try {
      final extension = p.extension(documentFile.path).toLowerCase();
      if (extension == '.epub') {
        return await _extractEpubMetadata(documentFile);
      } else if (extension == '.pdf') {
        return await _extractPdfMetadata(documentFile);
      }
    } catch (e) {
      log('Error extracting metadata: $e');
    }
    return (title: null, author: null);
  }

  static Future<({String? title, String? author})> _extractEpubMetadata(File file) async {
    try {
      final bytes = await file.readAsBytes();
      final epubBook = await EpubReader.readBook(bytes);
      return (title: epubBook.Title, author: epubBook.Author);
    } catch (e) {
      log('Error extracting epub metadata: $e');
      return (title: null, author: null);
    }
  }

  static Future<({String? title, String? author})> _extractPdfMetadata(File file) async {
    try {
      final bytes = await file.readAsBytes();
      final document = sync_pdf.PdfDocument(inputBytes: bytes);
      final title = document.documentInformation.title;
      final author = document.documentInformation.author;
      document.dispose();
      
      return (
        title: title.trim().isNotEmpty ? title : null,
        author: author.trim().isNotEmpty ? author : null,
      );
    } catch (e) {
      log('Error extracting pdf metadata: $e');
    }
    return (title: null, author: null);
  }
}
