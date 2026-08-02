import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:googleapis/drive/v3.dart' as drive;

class AuthRepository {
  final FirebaseAuth _firebaseAuth;
  static const scopes = [drive.DriveApi.driveFileScope];

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


  Future<String?> connectGoogleDrive() async {
    GoogleSignInAccount? googleUser = await GoogleSignIn.instance
        .attemptLightweightAuthentication();
    googleUser ??= await GoogleSignIn.instance.authenticate();

    await googleUser.authorizationClient
        .authorizationForScopes(scopes) ?? await googleUser.authorizationClient.authorizeScopes(scopes);

    return googleUser.email;
  }

  Future<void> disconnectGoogleDrive() async {
    await GoogleSignIn.instance.disconnect();
  }

  Future<void> signOut() async {
    await GoogleSignIn.instance.signOut();
    await _firebaseAuth.signOut();
  }
}
