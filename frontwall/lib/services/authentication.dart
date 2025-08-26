import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// Servicio de autenticación que maneja registro, login y logout
class AuthService {
  /// Instancia de Firestore para operaciones CRUD
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Instancia de FirebaseAuth para autenticación de usuarios
  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Devuelve el UID del usuario actualmente autenticado, o null si no hay sesión
  String? get currentUserId {
    return _auth.currentUser?.uid;
  }

  /// Registra un nuevo usuario con email, contraseña y nombre de usuario
  ///
  /// Crea la cuenta en Firebase Auth y luego guarda un documento en
  /// la colección 'users' con uid, email y username.
  ///
  /// Retorna 'éxito' si todo sale bien, o el mensaje de error en caso contrario.
  Future<String> registerUser({
    required String email,
    required String password,
    required String username,
  }) async {
    String result = "Ocurrió un error";
    try {
      // Validar que los campos no estén vacíos
      if (email.isNotEmpty && password.isNotEmpty && username.isNotEmpty) {
        // Crear usuario en Firebase Auth
        UserCredential credentials = await _auth.createUserWithEmailAndPassword(
          email: email,
          password: password,
        );

        // Guardar información adicional en Firestore
        await _firestore.collection("users").doc(credentials.user!.uid).set({
          'username': username,
          'uid': credentials.user!.uid,
          'email': email,
        });
        result = "éxito";
      }
    } catch (error) {
      // Retornar el mensaje de error proporcionado por Firebase
      return error.toString();
    }
    return result;
  }

  /// Inicia sesión de un usuario existente con email y contraseña
  ///
  /// Retorna 'éxito' si el login fue correcto, un mensaje si faltan campos,
  /// o el mensaje de error en caso de excepción.
  Future<String> loginUser({
    required String email,
    required String password,
  }) async {
    String result = "Ocurrió un error";
    try {
      // Verificar que los campos estén completos
      if (email.isNotEmpty && password.isNotEmpty) {
        // Realizar login con Firebase Auth
        await _auth.signInWithEmailAndPassword(
          email: email,
          password: password,
        );
        result = "éxito";
      } else {
        // Mensaje para indicar campos faltantes
        result = "Por favor ingresa todos los campos";
      }
    } catch (error) {
      // Retornar el mensaje de error de Firebase
      return error.toString();
    }
    return result;
  }

  /// Cierra la sesión del usuario actual
  Future<void> signOut() async {
    await _auth.signOut();
  }
}
