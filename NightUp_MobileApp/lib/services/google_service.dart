import 'package:google_sign_in/google_sign_in.dart';
import '../utils/logger.dart';

class GoogleSignInService {
  static final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: ['email', 'profile'],
    // Configuración específica para evitar problemas en web
    signInOption: SignInOption.standard,
  );

  // ================== SIGN IN ==================
  static Future<GoogleSignInAccount?> signIn() async {
    try {
      return await _googleSignIn.signIn();
    } catch (error) {
      logger.e('Google Sign-In Error: $error');
      return null;
    }
  }

  // ================== GET GOOGLE TOKEN ==================
  static Future<String?> getGoogleToken() async {
    try {
      final GoogleSignInAccount? account = await _googleSignIn.signInSilently();
      if (account != null) {
        final GoogleSignInAuthentication auth = await account.authentication;
        return auth.idToken;
      }
      return null;
    } catch (error) {
      logger.e('Google Token Error: $error');
      return null;
    }
  }

  // ================== SIGN OUT ==================
  static Future<void> signOut() async {
    try {
      await _googleSignIn.signOut();
    } catch (error) {
      logger.e('Google Sign-Out Error: $error');
    }
  }

  // ================== IS SIGNED IN ==================
  static Future<bool> isSignedIn() async {
    try {
      return await _googleSignIn.isSignedIn();
    } catch (error) {
      logger.e('Google isSignedIn Error: $error');
      return false;
    }
  }

  // ================== GET CURRENT USER ==================
  static Future<GoogleSignInAccount?> getCurrentUser() async {
    try {
      return _googleSignIn.currentUser;
    } catch (error) {
      logger.e('Google getCurrentUser Error: $error');
      return null;
    }
  }
}
