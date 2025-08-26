import 'package:flutter/material.dart';
import '../screens/main_screen.dart';
import '../screens/add_wallpaper.dart';
import '../screens/settings.dart';
import '../screens/wallpaper_detail.dart';
import '../screens/login.dart';
import '../screens/sign_up.dart';

/// Clase centralizada para definir rutas de navegación en la aplicación
class AppRoutes {
  /// Ruta principal (pantalla de inicio con lista de wallpapers)
  static const String mainScreen = '/main';

  /// Ruta para la pantalla de añadir nuevo wallpaper
  static const String addWallpaperScreen = '/add_wallpaper';

  /// Ruta para la pantalla de ajustes/ configuración
  static const String settingsScreen = '/settings';

  /// Ruta para la pantalla de detalle de un wallpaper
  static const String wallpaperDetail = '/wallpaper_detail';

  /// Ruta para la pantalla de login de usuarios existentes
  static const String loginScreen = '/login';

  /// Ruta para la pantalla de registro de nuevos usuarios
  static const String signUpScreen = '/sign_up';

  /// Mapa que asocia cada nombre de ruta con su constructor de Widget
  static final Map<String, WidgetBuilder> routes = {
    mainScreen: (context) => const MainScreen(),
    addWallpaperScreen: (context) => const AddWallpaperScreen(),
    settingsScreen: (context) => const SettingsScreen(),
    wallpaperDetail: (context) => const WallpaperDetailScreen(),
    loginScreen: (context) => const LoginScreen(),
    signUpScreen: (context) => const SignupScreen(),
  };
}
