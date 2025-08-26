import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:frontwall/routes/app_routes.dart';
import 'package:frontwall/screens/login.dart';
import 'package:frontwall/screens/main_screen.dart';

/// Main
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(const MyApp());
}

/// Widget raíz que controla el tema y la navegación según estado de autenticación
class MyApp extends StatefulWidget {
  const MyApp({super.key});

  /// Notifier para cambiar dinámicamente el tema claro/oscuro
  static final ValueNotifier<ThemeMode> themeNotifier =
      ValueNotifier(ThemeMode.light);

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  /// Carga la preferencia de tema oscuro del usuario desde Firestore
  Future<ThemeMode?> _loadUserTheme() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return null;
    final doc = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .get();
    final data = doc.data();
    if (data != null && data['darkMode'] is bool) {
      return data['darkMode'] as bool ? ThemeMode.dark : ThemeMode.light;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    // Escucha cambios en la sesión de autenticación
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (ctx, authSnap) {
        // Mientras se determina el estado de sesión, mostrar spinner
        if (authSnap.connectionState == ConnectionState.waiting) {
          return const MaterialApp(
            home: Scaffold(body: Center(child: CircularProgressIndicator())),
          );
        }

        // Si el usuario está autenticado
        if (authSnap.hasData) {
          // Cargar tema del usuario antes de mostrar MainScreen
          return FutureBuilder<ThemeMode?>(
            future: _loadUserTheme(),
            builder: (ctx2, themeSnap) {
              if (themeSnap.connectionState == ConnectionState.waiting) {
                return const MaterialApp(
                  home: Scaffold(
                    body: Center(child: CircularProgressIndicator()),
                  ),
                );
              }

              // Si el usuario tiene una preferencia, aplicarla
              if (themeSnap.data != null) {
                MyApp.themeNotifier.value = themeSnap.data!;
              }

              // Reconstruir MaterialApp cuando cambie el notifier
              return ValueListenableBuilder<ThemeMode>(
                valueListenable: MyApp.themeNotifier,
                builder: (_, currentMode, __) {
                  return MaterialApp(
                    debugShowCheckedModeBanner: false,
                    // Configuración para tema claro
                    theme: ThemeData(
                      brightness: Brightness.light,
                      primaryColor: Colors.blue,
                      scaffoldBackgroundColor: Colors.grey.shade100,
                      appBarTheme: AppBarTheme(
                        backgroundColor: Colors.grey.shade200,
                        iconTheme: const IconThemeData(color: Colors.black87),
                        titleTextStyle: const TextStyle(
                          color: Colors.black87,
                          fontSize: 20,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      bottomNavigationBarTheme: BottomNavigationBarThemeData(
                        backgroundColor: Colors.white,
                        selectedItemColor: Colors.blue,
                        unselectedItemColor: Colors.grey.shade600,
                      ),
                      cardTheme: const CardThemeData(
                        color: Colors.white,
                        elevation: 2,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.all(Radius.circular(12)),
                        ),
                      ),
                      dialogTheme: const DialogThemeData(
                        backgroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.all(Radius.circular(12)),
                        ),
                      ),
                    ),
                    // Configuración para tema oscuro
                    darkTheme: ThemeData(
                      brightness: Brightness.dark,
                      primaryColor: Colors.blueAccent,
                      scaffoldBackgroundColor: Colors.grey.shade900,
                      appBarTheme: AppBarTheme(
                        backgroundColor: Colors.grey.shade800,
                        iconTheme: const IconThemeData(color: Colors.white),
                        titleTextStyle: const TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      bottomNavigationBarTheme: BottomNavigationBarThemeData(
                        backgroundColor: Colors.grey.shade800,
                        selectedItemColor: Colors.blueAccent,
                        unselectedItemColor: Colors.grey.shade500,
                      ),
                      cardTheme: CardThemeData(
                        color: Colors.grey.shade800,
                        elevation: 2,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      dialogTheme: DialogThemeData(
                        backgroundColor: Colors.grey.shade800,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                    themeMode: currentMode,
                    home:
                        const MainScreen(), // Pantalla principal al estar logueado
                    routes: AppRoutes.routes, // Rutas nombradas
                  );
                },
              );
            },
          );
        }

        // Si no está autenticado, dirigir a LoginScreen
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          theme: ThemeData(
            brightness: Brightness.light,
            primaryColor: Colors.blue,
            scaffoldBackgroundColor: Colors.grey.shade100,
            appBarTheme: AppBarTheme(
              backgroundColor: Colors.grey.shade200,
              iconTheme: const IconThemeData(color: Colors.black87),
              titleTextStyle: const TextStyle(
                color: Colors.black87,
                fontSize: 20,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          home: const LoginScreen(),
          routes: AppRoutes.routes,
        );
      },
    );
  }
}
