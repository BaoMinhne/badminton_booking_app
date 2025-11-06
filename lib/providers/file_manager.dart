import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';

class FileManager with ChangeNotifier {
  FileManager() : _picker = ImagePicker();

  final ImagePicker _picker;
  final List<XFile> _pickedImages = [];

  List<XFile> get pickedImages => List.unmodifiable(_pickedImages);

  bool get hasImages => _pickedImages.isNotEmpty;

  Future<void> pickImages() async {
    final images = await _picker.pickMultiImage(imageQuality: 85);
    if (images.isEmpty) {
      return;
    }
    _pickedImages
      ..clear()
      ..addAll(images);
    notifyListeners();
  }

  Future<void> pickFromCamera() async {
    final image = await _picker.pickImage(source: ImageSource.camera);
    if (image == null) {
      return;
    }
    _pickedImages
      ..clear()
      ..add(image);
    notifyListeners();
  }

  void removeAt(int index) {
    if (index < 0 || index >= _pickedImages.length) {
      return;
    }
    _pickedImages.removeAt(index);
    notifyListeners();
  }

  void clear() {
    if (_pickedImages.isEmpty) {
      return;
    }
    _pickedImages.clear();
    notifyListeners();
  }

  List<File> toFiles() {
    return _pickedImages
        .where((xfile) => xfile.path.isNotEmpty)
        .map((xfile) => File(xfile.path))
        .toList(growable: false);
  }
}
