import 'package:flutter/material.dart';
import 'package:frontwall/routes/app_routes.dart';
import 'package:frontwall/services/authentication.dart';
import 'package:frontwall/widget/custom_buttons.dart';
import 'package:frontwall/widget/custom_text_field.dart';
import 'package:frontwall/widget/snack_bar.dart';
import 'package:email_validator/email_validator.dart';

/// Pantalla de registro
class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  /// Controlador de texto para el nombre de usuario
  final TextEditingController nameController = TextEditingController();

  /// Controlador de texto para el correo electrónico
  final TextEditingController emailController = TextEditingController();

  /// Controlador de texto para la contraseña
  final TextEditingController passwordController = TextEditingController();

  /// Controlador de texto para confirmar contraseña
  final TextEditingController confirmPasswordController =
      TextEditingController();

  /// Indicador de estado de carga durante el registro
  bool isLoading = false;

  @override
  void dispose() {
    // Liberar controladores para evitar fugas de memoria
    nameController.dispose();
    emailController.dispose();
    passwordController.dispose();
    confirmPasswordController.dispose();
    super.dispose();
  }

  /// Valida que todos los campos sean correctos antes de enviar
  bool validateFields() {
    // Función auxiliar para mostrar un mensaje de error
    void showError(String message) {
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      showCustomSnackBar(context, message);
    }

    // Verificar que el nombre no esté vacío
    if (nameController.text.trim().isEmpty) {
      showError("Por favor ingresa tu nombre");
      return false;
    }
    // Verificar que el correo no esté vacío
    if (emailController.text.trim().isEmpty) {
      showError("Por favor ingresa tu correo electrónico");
      return false;
    }
    // Verificar formato válido de correo
    if (!EmailValidator.validate(emailController.text.trim())) {
      showError("Ingresa un correo electrónico válido");
      return false;
    }
    // Verificar que la contraseña no esté vacía
    if (passwordController.text.isEmpty) {
      showError("Por favor ingresa una contraseña");
      return false;
    }
    // Verificar longitud mínima de la contraseña
    if (passwordController.text.length < 6) {
      showError("La contraseña debe tener al menos 6 caracteres");
      return false;
    }
    // Verificar confirmación de contraseña
    if (confirmPasswordController.text.isEmpty) {
      showError("Por favor, repite la contraseña");
      return false;
    }
    // Verificar que las contraseñas coincidan
    if (passwordController.text != confirmPasswordController.text) {
      showError("Las contraseñas no coinciden");
      return false;
    }
    return true; // Todos los campos son válidos
  }

  /// Ejecuta el proceso de registro tras validar campos
  Future<void> signupUser() async {
    if (isLoading) return; // Evitar múltiples taps
    if (!validateFields()) return; // No continuar si falla la validación

    setState(() => isLoading = true);

    // Llamada al servicio para crear usuario
    String res = await AuthService().registerUser(
      email: emailController.text.trim(),
      password: passwordController.text,
      username: nameController.text.trim(),
    );

    setState(() => isLoading = false);

    if (res == "éxito") {
      // Registro exitoso: navegar a la pantalla principal
      Navigator.pushReplacementNamed(context, AppRoutes.mainScreen);
    } else {
      // Mostrar error específico para correo duplicado o genérico
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      if (res.contains("email-already-in-use")) {
        showCustomSnackBar(context, "El correo electrónico ya está en uso");
      } else {
        showCustomSnackBar(context, res);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Colores
    final backgroundColor = Colors.grey.shade100;
    final textColor = Colors.grey.shade900;
    final hintColor = Colors.grey.shade600;
    final buttonColor = Colors.blue;
    final linkColor = Colors.blueAccent;

    // Altura de pantalla para ajustar el logo
    final double height = MediaQuery.of(context).size.height;

    return Scaffold(
      resizeToAvoidBottomInset: true,
      backgroundColor: backgroundColor,
      body: Stack(
        children: [
          SafeArea(
            child: SingleChildScrollView(
              child: SizedBox(
                width: double.infinity,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Logo
                    SizedBox(
                      height: height / 2.8,
                      child: Image.asset(
                        'assets/images/transparent_icon.png',
                        fit: BoxFit.contain,
                      ),
                    ),
                    // Campo para nombre
                    CustomTextField(
                      icon: Icons.person,
                      inputController: nameController,
                      placeholderText: 'Ingresa tu nombre',
                      inputType: TextInputType.text,
                      textColor: textColor,
                      hintColor: hintColor,
                    ),
                    // Campo para correo
                    CustomTextField(
                      icon: Icons.email,
                      inputController: emailController,
                      placeholderText: 'Ingresa tu correo electrónico',
                      inputType: TextInputType.emailAddress,
                      textColor: textColor,
                      hintColor: hintColor,
                    ),
                    // Campo para contraseña
                    CustomTextField(
                      icon: Icons.lock,
                      inputController: passwordController,
                      placeholderText: 'Ingresa tu contraseña',
                      inputType: TextInputType.text,
                      isPasswordField: true,
                      textColor: textColor,
                      hintColor: hintColor,
                    ),
                    // Campo para confirmar contraseña
                    CustomTextField(
                      icon: Icons.lock,
                      inputController: confirmPasswordController,
                      placeholderText: 'Repite tu contraseña',
                      inputType: TextInputType.text,
                      isPasswordField: true,
                      textColor: textColor,
                      hintColor: hintColor,
                    ),
                    const SizedBox(height: 12),
                    // Botón de registro
                    Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16.0, vertical: 12.0),
                      child: CustomButton(
                        onTap: isLoading ? () {} : signupUser,
                        buttonText: "Registrarse",
                        backgroundColor: buttonColor,
                        textColor: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 14),
                    // Enlace a pantalla de login si ya tiene cuenta
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          "¿Ya tienes una cuenta?",
                          style: TextStyle(color: textColor),
                        ),
                        GestureDetector(
                          onTap: isLoading
                              ? null
                              : () {
                                  Navigator.pushNamed(
                                      context, AppRoutes.loginScreen);
                                },
                          child: Text(
                            " Iniciar sesión",
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: linkColor,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                  ],
                ),
              ),
            ),
          ),
          // Overlay de carga cuando isLoading es true
          if (isLoading)
            Container(
              color: Colors.black45,
              child: const Center(
                child: CircularProgressIndicator(),
              ),
            ),
        ],
      ),
    );
  }
}
