import 'package:firebase_auth/firebase_auth.dart';

class AuthService {
  static Future<bool> logeado() async {
    return FirebaseAuth.instance.currentUser != null;
  }
}
