import 'package:firebase_auth/firebase_auth.dart';

class AuthClient {
  final FirebaseAuth auth;

  AuthClient(this.auth);

  User? get currentUser => auth.currentUser;
}
