import 'dart:io';
import 'package:epubx/epubx.dart';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:image/image.dart' as img;

import 'package:archive/archive.dart';
import 'package:pdfx/pdfx.dart';

class CoverExtractor {
  static Future<String?> extractAndSaveCover(File documentFile) async {
    try {
      final extension = p.extension(documentFile.path).toLowerCase();
      final documentName = p.basenameWithoutExtension(documentFile.path);

      if (extension == '.cbz' || extension == '.zip') {
        return await _extractFromCbz(documentFile, documentName);
      } else if (extension == '.epub') {
        return await _extractFromEpub(documentFile, documentName);
      } else if (extension == '.pdf') {
        return await _extractFromPdf(documentFile, documentName);
      }
    } catch (e) {
      debugPrint('Error extracting cover: $e');
    }
    return null;
  }

  static Future<String?> _extractFromCbz(File file, String docName) async {
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
        return await _saveImageBytes(coverImageFile.content as List<int>, '${docName}_cover.jpg');
      }
    } catch (e) {
      debugPrint('Error extracting cbz cover: $e');
    }
    return null;
  }

  static Future<String?> _extractFromPdf(File file, String docName) async {
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
        return await _saveImageBytes(pageImage.bytes, '${docName}_cover.jpg');
      }
    } catch (e) {
      debugPrint('Error extracting pdf cover: $e');
    }
    return null;
  }

  static Future<String?> _extractFromEpub(File file, String docName) async {
    final bytes = await file.readAsBytes();
    
    final epubBook = await EpubReader.readBook(bytes);
    
    final coverImage = epubBook.CoverImage;
    if (coverImage != null) {
      final imageBytes = img.encodeJpg(coverImage);
      return await _saveImageBytes(imageBytes, '${docName}_cover.jpg');
    }
    return null;
  }

  static Future<String> _saveImageBytes(
    List<int> bytes,
    String fileName,
  ) async {
    final directory = await getApplicationDocumentsDirectory();
    final imagePath = p.join(directory.path, fileName);

    final imageFile = File(imagePath);
    await imageFile.writeAsBytes(bytes);

    return imagePath;
  }
}
