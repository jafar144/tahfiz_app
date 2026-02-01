import 'package:firebase_storage/firebase_storage.dart';

class StorageClient {
  final FirebaseStorage storage;

  StorageClient(this.storage);

  Reference ref(String path) {
    return storage.ref(path);
  }
}
