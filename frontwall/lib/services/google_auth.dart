import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

/// Servicio que encapsula autenticación con Firebase Auth y Google Sign-In
class FirebaseAuthService {
  /// Instancia de FirebaseAuth para manejar la sesión de usuario
  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Instancia de GoogleSignIn para flujo de autenticación de Google
  final GoogleSignIn _googleSignIn = GoogleSignIn();

  /// Obtiene el UID del usuario actualmente autenticado, o null si no hay sesión
  String? get currentUserId => _auth.currentUser?.uid;

  /// Realiza el flujo de inicio de sesión con Google:
  /// 1. Cierra sesiones previas de GoogleSignIn.
  /// 2. Lanza pantalla de selección de cuenta.
  /// 3. Obtiene credenciales (accessToken, idToken).
  /// 4. Inicia sesión en Firebase con GoogleAuthProvider.
  Future<void> signInWithGoogle() async {
    try {
      // Asegurar que no queden sesiones anteriores
      await _googleSignIn.signOut();

      // Iniciar flujo de selección de cuenta
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        // El usuario canceló el login
        return;
      }

      // Obtener tokens de autenticación
      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      // Crear credencial para Firebase
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // Iniciar sesión con Firebase usando la credencial de Google
      await _auth.signInWithCredential(credential);
    } on FirebaseAuthException catch (e) {
      // Manejo de errores específicos de FirebaseAuth
      print('Error en signInWithGoogle: \$e');
      rethrow;
    }
  }

  /// Cierra sesión de Google y Firebase
  Future<void> signOut() async {
    await _googleSignIn.signOut();
    await _auth.signOut();
  }

  /// Elimina la cuenta del usuario autenticado en Firebase Auth
  ///
  /// Si la operación falla por requerir reautenticación reciente,
  /// captura el error 'requires-recent-login'.
  Future<void> deleteAccount() async {
    try {
      final User? user = _auth.currentUser;
      if (user != null) {
        // Eliminar cuenta de Firebase
        await user.delete();
        // Cerrar sesión de Google
        await _googleSignIn.signOut();
      }
    } on FirebaseAuthException catch (e) {
      if (e.code == 'requires-recent-login') {
        // La operación requiere reautenticación
        print('La eliminación de la cuenta requiere reautenticación.');
      } else {
        print(e.toString());
      }
    }
  }
}
