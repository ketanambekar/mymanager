import 'package:get/get.dart';
import 'package:google_sign_in/google_sign_in.dart';

class AuthService extends GetxService {
  AuthService._();

  static Future<void> initialize() async {
    Get.put<AuthService>(AuthService._());
  }

  static AuthService get to => Get.find<AuthService>();

  final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: <String>['email'],
  );

  final Rxn<GoogleSignInAccount> currentUser = Rxn<GoogleSignInAccount>();

  bool get isLoggedIn => currentUser.value != null;

  Future<GoogleSignInAccount?> signInWithGoogle() async {
    try {
      final GoogleSignInAccount? user = await _googleSignIn.signIn();
      currentUser.value = user;
      return user;
    } catch (error) {
      Get.snackbar('Login failed', error.toString());
      return null;
    }
  }

  Future<void> signOutFromGoogle() async {
    try {
      await _googleSignIn.signOut();
      currentUser.value = null;
    } catch (error) {
      Get.snackbar('Logout failed', error.toString());
    }
  }
}