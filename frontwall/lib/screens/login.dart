import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:frontwall/routes/app_routes.dart';
import 'package:frontwall/services/authentication.dart';
import 'package:frontwall/services/forgot_password.dart';
import 'package:frontwall/services/google_auth.dart';
import 'package:frontwall/widget/custom_buttons.dart';
import 'package:frontwall/widget/custom_text_field.dart';
import 'package:frontwall/widget/snack_bar.dart';

/// Pantalla de inicio de sesión
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  /// Controlador para el campo de correo electrónico
  final TextEditingController _emailController = TextEditingController();

  /// Controlador para el campo de contraseña
  final TextEditingController _passwordController = TextEditingController();

  /// Indicador de estado de carga durante la autenticación
  bool _isLoading = false;

  @override
  void dispose() {
    // Liberar recursos de los controladores para evitar fugas de memoria
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  /// Ejecuta el inicio de sesión con email y contraseña
  Future<void> _loginUser() async {
    if (_isLoading) return; // Prevenir llamadas simultáneas

    setState(() => _isLoading = true);

    // Llamada al servicio de autenticación
    String result = await AuthService().loginUser(
      email: _emailController.text.trim(),
      password: _passwordController.text.trim(),
    );

    // Verificar si el usuario está autenticado en Firebase
    var user = FirebaseAuth.instance.currentUser;
    if (result == "éxito" && user != null) {
      setState(() => _isLoading = false);
      // Navegar a la pantalla principal, reemplazando la ruta actual
      Navigator.pushReplacementNamed(context, AppRoutes.mainScreen);
    } else {
      setState(() => _isLoading = false);
      // Ocultar posibles snackbars previos y mostrar error
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      showCustomSnackBar(
        context,
        "Error de autenticación. Verifica tus credenciales.",
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // Colores
    final backgroundColor = Colors.grey.shade100;
    final dividerColor = Colors.grey.shade300;
    final textColor = Colors.grey.shade900;
    final googleButtonColor = const Color(0xff246382);

    // Calcular altura de pantalla para dimensionar el logo
    double screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      resizeToAvoidBottomInset: true,
      backgroundColor: backgroundColor,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Logo de la aplicación en la parte superior
              SizedBox(
                height: screenHeight * 0.35,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Image.asset(
                    'assets/images/transparent_icon.png',
                    fit: BoxFit.contain,
                  ),
                ),
              ),

              // Campo de texto para correo electrónico
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                child: CustomTextField(
                  icon: Icons.person,
                  inputController: _emailController,
                  placeholderText: 'Ingresa tu correo electrónico',
                  inputType: TextInputType.emailAddress,
                ),
              ),

              // Campo de texto para contraseña
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                child: CustomTextField(
                  icon: Icons.lock,
                  inputController: _passwordController,
                  placeholderText: 'Ingresa tu contraseña',
                  inputType: TextInputType.text,
                  isPasswordField: true,
                ),
              ),

              // Enlace a pantalla de recuperación de contraseña
              const ForgotPasswordScreen(),

              // Botón principal de iniciar sesión
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                child: CustomButton(
                  onTap: _isLoading ? () {} : _loginUser,
                  buttonText: "Iniciar sesión",
                ),
              ),

              // Separador
              Padding(
                padding: const EdgeInsets.symmetric(
                    horizontal: 16.0, vertical: 12.0),
                child: Row(
                  children: [
                    Expanded(child: Container(height: 1, color: dividerColor)),
                    Text("  o  ", style: TextStyle(color: textColor)),
                    Expanded(child: Container(height: 1, color: dividerColor)),
                  ],
                ),
              ),

              // Botón para continuar con Google Sign-In
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 25, vertical: 10),
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: googleButtonColor,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  onPressed: () async {
                    if (_isLoading) return;
                    setState(() => _isLoading = true);

                    // Llamada al servicio de Google
                    await FirebaseAuthService().signInWithGoogle();

                    final user = FirebaseAuth.instance.currentUser;
                    setState(() => _isLoading = false);
                    if (user != null) {
                      // Navegar a pantalla principal
                      Navigator.pushReplacementNamed(
                          context, AppRoutes.mainScreen);
                    } else {
                      // Mostrar mensaje si se canceló la operación
                      showCustomSnackBar(context, 'Inicio de sesión cancelado');
                    }
                  },
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Icono de Google
                      Image.network(
                        "https://th.bing.com/th/id/R.a9fb17c908f1933ab901c2c3fd1cdc44?rik=gWdVqzzG8%2buUEA&pid=ImgRaw&r=0",
                        height: 28,
                      ),
                      const SizedBox(width: 10),
                      const Text(
                        "Continuar con Google",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Enlace a registro de nuevo usuario
              Padding(
                padding: const EdgeInsets.only(top: 10, bottom: 20),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      "¿No tienes una cuenta? ",
                      style: TextStyle(color: textColor),
                    ),
                    GestureDetector(
                      onTap: () {
                        if (_isLoading) return;
                        // Navegar a pantalla de registro
                        Navigator.pushNamed(context, AppRoutes.signUpScreen);
                      },
                      child: Text(
                        "Registrarse",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).primaryColor,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
