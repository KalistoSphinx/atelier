import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

class AuthRepository {
  final FirebaseAuth _firebaseAuth;

  AuthRepository(this._firebaseAuth);

  Stream<User?> authStateChanges() => _firebaseAuth.userChanges();
  User? get currentUser => _firebaseAuth.currentUser;

  Future<void> updateDisplayName(String name) async {
    await _firebaseAuth.currentUser?.updateDisplayName(name);
    await _firebaseAuth.currentUser?.reload();
  }

  Future<UserCredential> signIn() async {
    final googleUser = await GoogleSignIn.instance.authenticate();

    final googleAuth = googleUser.authentication;

    final credential = GoogleAuthProvider.credential(
      idToken: googleAuth.idToken,
    );

    return _firebaseAuth.signInWithCredential(credential);
  }

  Future<void> signOut() async {
    await GoogleSignIn.instance.signOut();
    await _firebaseAuth.signOut();
  }

}
