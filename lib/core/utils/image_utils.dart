import 'dart:io';

import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';
import 'package:firebase_storage/firebase_storage.dart';

class ImageUtils {
  static final ImagePicker _picker = ImagePicker();

  /// Picks an image from the given source (camera or gallery)
  static Future<File?> pickImage(ImageSource source) async {
    final XFile? pickedFile = await _picker.pickImage(source: source);
    if (pickedFile != null) {
      return File(pickedFile.path);
    }
    return null;
  }

  /// Compresses the image and returns a File under 1MB if possible
  static Future<File?> compressImage(File file) async {
    final directory = await getTemporaryDirectory();
    final targetPath = '${directory.path}/${const Uuid().v4()}.jpg';

    // Compress with high quality but smaller dimension and size limit
    final result = await FlutterImageCompress.compressAndGetFile(
      file.absolute.path,
      targetPath,
      quality: 75,
      minWidth: 800,
      minHeight: 800,
      format: CompressFormat.jpeg,
    );

    if (result != null) {
      return File(result.path);
    }
    return null;
  }

  /// Uploads file to Firebase Storage under the given path
  static Future<String?> uploadImageToFirebase(File file, String path, {String? fileName}) async {
    try {
      final String name = fileName ?? const Uuid().v4();
      final destination = '$path/$name.jpg';
      final ref = FirebaseStorage.instance.ref().child(destination);
      await ref.putFile(file);
      final url = await ref.getDownloadURL();
      return url;
    } catch (e) {
      return null;
    }
  }

  /// Menghapus file dari Firebase Storage berdasarkan download URL
  static Future<void> deleteImageFromFirebase(String url) async {
    try {
      final ref = FirebaseStorage.instance.refFromURL(url);
      await ref.delete();
    } catch (_) {}
  }
}
