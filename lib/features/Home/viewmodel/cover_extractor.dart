import 'dart:developer';
import 'dart:io';
import 'package:epubx/epubx.dart';
import 'package:image_app/features/Home/viewmodel/library_service.dart';
import 'package:image/image.dart' as img;

import 'package:archive/archive.dart';
import 'package:pdfx/pdfx.dart';

class CoverExtractor {
  /// Extract and save the cover image for a book, using its UUID as the filename.
  /// Returns the absolute path to the saved cover, or null if extraction fails.
  static Future<String?> extractAndSaveCover(File documentFile, String bookId) async {
    try {
      final extension = documentFile.path.split('.').last.toLowerCase();

      if (extension == 'cbz' || extension == 'zip') {
        return await _extractFromCbz(documentFile, bookId);
      } else if (extension == 'epub') {
        return await _extractFromEpub(documentFile, bookId);
      } else if (extension == 'pdf') {
        return await _extractFromPdf(documentFile, bookId);
      }
    } catch (e) {
      log('Error extracting cover: $e');
    }
    return null;
  }

  static Future<String?> _extractFromCbz(File file, String bookId) async {
    try {
      final bytes = await file.readAsBytes();
      final archive = ZipDecoder().decodeBytes(bytes);

      final imageFiles = archive.where((f) => f.isFile && 
        (f.name.toLowerCase().endsWith('.jpg') || 
         f.name.toLowerCase().endsWith('.jpeg') || 
         f.name.toLowerCase().endsWith('.png'))).toList();

      if (imageFiles.isNotEmpty) {
        imageFiles.sort((a, b) => a.name.compareTo(b.name));
        final coverImageFile = imageFiles.first;
        return await _saveImageBytes(coverImageFile.content as List<int>, bookId);
      }
    } catch (e) {
      log('Error extracting cbz cover: $e');
    }
    return null;
  }

  static Future<String?> _extractFromPdf(File file, String bookId) async {
    try {
      final document = await PdfDocument.openFile(file.path);
      final page = await document.getPage(1);
      
      final pageImage = await page.render(
        width: page.width * 2,
        height: page.height * 2,
        format: PdfPageImageFormat.jpeg,
      );
      
      await page.close();
      await document.close();

      if (pageImage != null) {
        return await _saveImageBytes(pageImage.bytes, bookId);
      }
    } catch (e) {
      log('Error extracting pdf cover: $e');
    }
    return null;
  }

  static Future<String?> _extractFromEpub(File file, String bookId) async {
    final bytes = await file.readAsBytes();
    
    final epubBook = await EpubReader.readBook(bytes);
    
    final coverImage = epubBook.CoverImage;
    if (coverImage != null) {
      final imageBytes = img.encodeJpg(coverImage);
      return await _saveImageBytes(imageBytes, bookId);
    }
    return null;
  }

  static Future<String> _saveImageBytes(List<int> bytes, String bookId) async {
    final lib = LibraryService.instance;
    await lib.init();
    final coverPath = lib.getCoverPath(bookId);

    final imageFile = File(coverPath);
    await imageFile.writeAsBytes(bytes);

    return coverPath;
  }
}
