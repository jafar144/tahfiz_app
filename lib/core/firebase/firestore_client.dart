import 'package:cloud_firestore/cloud_firestore.dart';

class FirestoreClient {
  final FirebaseFirestore firestore;

  FirestoreClient(this.firestore);

  CollectionReference<Map<String, dynamic>> collection(String path) {
    return firestore.collection(path);
  }
}
