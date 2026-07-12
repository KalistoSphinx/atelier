import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

class ImageListNotifier extends Notifier<List<File>> {
  @override
  List<File> build() {
    _loadSavedImages();
    return [];
  }

  Future<void> _loadSavedImages() async {
    final directory = await getApplicationDocumentsDirectory();

    final files = directory.listSync().whereType<File>().where(
      (file) => [
        ".jpg",
        ".jpeg",
        ".png",
        ".heic",
        ".webp",
      ].contains(p.extension(file.path).toLowerCase())
    ).toList();

    state = files;
  }

  Future<void> pickAndSaveImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if(pickedFile != null){
      final directory = await getApplicationDocumentsDirectory();
      final fileName = p.basename(pickedFile.path);
      final localImagePath = p.join(directory.path, fileName);
      final savedImage = await File(pickedFile.path).copy(localImagePath);

      state = [...state, savedImage];
    }
  }
}

final imageListProvider = NotifierProvider<ImageListNotifier, List<File>>((){
  return ImageListNotifier();
});
