import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:frontwall/services/google_auth.dart';
import '../routes/app_routes.dart';
import '../main.dart';

/// Pantalla de ajustes de la aplicación
///
/// Permite al usuario:
/// - Ver su información básica (email, foto).
/// - Cambiar entre modo claro y oscuro.
/// - Cerrar sesión o eliminar cuenta.
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Usuario actualmente autenticado en Firebase
    final User? user = FirebaseAuth.instance.currentUser;

    // Determinar si el tema actual es oscuro
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    // Colores adaptativos según el modo de tema
    final backgroundColor =
        isDarkMode ? Colors.grey.shade900 : Colors.grey.shade100;
    final cardColor = isDarkMode ? Colors.grey.shade800 : Colors.white;
    final primaryTextColor = isDarkMode ? Colors.white : Colors.grey.shade900;
    final secondaryTextColor =
        isDarkMode ? Colors.grey.shade400 : Colors.grey.shade600;
    final accentColor = isDarkMode ? Colors.red.shade300 : Colors.red.shade700;
    final appBarColor =
        isDarkMode ? Colors.grey.shade800 : Colors.grey.shade200;

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        backgroundColor: appBarColor,
        elevation: 0,
        centerTitle: true,
        title: Text(
          'Ajustes',
          style: TextStyle(
            color: primaryTextColor,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
          ),
        ),
        iconTheme: IconThemeData(color: primaryTextColor),
      ),
      body: ListView(
        padding: EdgeInsets.zero,
        children: [
          // Sección de perfil del usuario
          Container(
            color: cardColor,
            padding: const EdgeInsets.symmetric(vertical: 32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Logo
                SizedBox(
                  height: 200,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Image.asset(
                      'assets/images/transparent_icon.png',
                      fit: BoxFit.contain,
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                // Avatar del usuario: foto si existe o icono genérico
                CircleAvatar(
                  radius: 50,
                  backgroundColor:
                      isDarkMode ? Colors.grey.shade700 : Colors.grey.shade200,
                  backgroundImage: (user != null && user.photoURL != null)
                      ? NetworkImage(user.photoURL!)
                      : null,
                  child: (user == null || user.photoURL == null)
                      ? Icon(
                          Icons.person,
                          size: 48,
                          color: secondaryTextColor,
                        )
                      : null,
                ),
                const SizedBox(height: 12),
                // Mostrar email o texto por defecto
                Text(
                  user?.email ?? 'Sin correo',
                  style: TextStyle(
                    color: primaryTextColor,
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),

          const SizedBox(height: 32),

          // Switch para modo oscuro
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Card(
              color: cardColor,
              margin: EdgeInsets.zero,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(
                    color: isDarkMode
                        ? Colors.grey.shade700
                        : Colors.grey.shade300),
              ),
              child: SwitchListTile(
                title: Text(
                  'Modo oscuro',
                  style: TextStyle(
                    color: primaryTextColor,
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                secondary: Icon(
                  isDarkMode ? Icons.dark_mode : Icons.light_mode,
                  color: isDarkMode ? Colors.white : Colors.grey.shade900,
                ),
                value: isDarkMode,
                activeColor: accentColor,
                onChanged: (val) async {
                  // Cambiar tema en la app y guardar en Firestore
                  MyApp.themeNotifier.value =
                      val ? ThemeMode.dark : ThemeMode.light;
                  final uid = FirebaseAuth.instance.currentUser?.uid;
                  if (uid != null) {
                    await FirebaseFirestore.instance
                        .collection('users')
                        .doc(uid)
                        .set({'darkMode': val}, SetOptions(merge: true));
                  }
                },
                contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                dense: true,
              ),
            ),
          ),

          const SizedBox(height: 24),

          // Opciones de cerrar sesión y eliminar cuenta
          Card(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            elevation: 0,
            color: cardColor,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(
                  color:
                      isDarkMode ? Colors.grey.shade700 : Colors.grey.shade300),
            ),
            child: Column(
              children: [
                // ListTile para cerrar sesión
                ListTile(
                  tileColor:
                      isDarkMode ? Colors.grey.shade800 : Colors.grey.shade50,
                  leading: Icon(Icons.logout, color: primaryTextColor),
                  title: Text(
                    'Cerrar sesión',
                    style: TextStyle(
                      color: primaryTextColor,
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  trailing: Icon(Icons.arrow_forward_ios,
                      size: 16, color: secondaryTextColor),
                  onTap: () async {
                    // Confirmación antes de cerrar sesión
                    final bool? confirm = await showDialog<bool>(
                      context: context,
                      builder: (ctx) => AlertDialog(
                        backgroundColor: cardColor,
                        title: Text(
                          'Cerrar sesión',
                          style: TextStyle(color: primaryTextColor),
                        ),
                        content: Text(
                          '¿Seguro que deseas cerrar sesión?',
                          style: TextStyle(color: secondaryTextColor),
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.of(ctx).pop(false),
                            child: Text(
                              'Cancelar',
                              style: TextStyle(color: secondaryTextColor),
                            ),
                          ),
                          TextButton(
                            onPressed: () => Navigator.of(ctx).pop(true),
                            child: Text(
                              'Aceptar',
                              style: TextStyle(color: accentColor),
                            ),
                          ),
                        ],
                      ),
                    );
                    if (confirm == true) {
                      // Cerrar sesión y volver a login
                      await FirebaseAuthService().signOut();
                      Navigator.pushReplacementNamed(
                          context, AppRoutes.loginScreen);
                    }
                  },
                ),
                const Divider(height: 1, thickness: 0.5),
                // ListTile para eliminar cuenta
                ListTile(
                  tileColor:
                      isDarkMode ? Colors.grey.shade800 : Colors.grey.shade50,
                  leading: Icon(Icons.delete, color: accentColor),
                  title: Text(
                    'Eliminar cuenta',
                    style: TextStyle(
                      color: accentColor,
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  trailing: Icon(Icons.arrow_forward_ios,
                      size: 16, color: secondaryTextColor),
                  onTap: () async {
                    // Confirmación antes de eliminar cuenta
                    final bool? confirm = await showDialog<bool>(
                      context: context,
                      builder: (ctx) => AlertDialog(
                        backgroundColor: cardColor,
                        title: Text(
                          'Eliminar cuenta',
                          style: TextStyle(color: primaryTextColor),
                        ),
                        content: Text(
                          '¿Estás seguro de que deseas eliminar tu cuenta? '
                          'Esta acción es irreversible.',
                          style: TextStyle(color: secondaryTextColor),
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.of(ctx).pop(false),
                            child: Text(
                              'Cancelar',
                              style: TextStyle(color: secondaryTextColor),
                            ),
                          ),
                          TextButton(
                            onPressed: () => Navigator.of(ctx).pop(true),
                            child: Text(
                              'Eliminar',
                              style: TextStyle(color: accentColor),
                            ),
                          ),
                        ],
                      ),
                    );
                    if (confirm == true) {
                      // Eliminar cuenta y volver a login
                      await FirebaseAuthService().deleteAccount();
                      Navigator.pushReplacementNamed(
                          context, AppRoutes.loginScreen);
                    }
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }
}
