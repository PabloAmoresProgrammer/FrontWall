import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:frontwall/widget/snack_bar.dart';

/// Widget para recuperar contraseña
class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  /// Controlador para el campo de email
  final TextEditingController emailController = TextEditingController();

  /// Instancia de FirebaseAuth para enviar el email de restablecimiento
  final FirebaseAuth auth = FirebaseAuth.instance;

  @override
  void dispose() {
    // Liberar controlador al destruir el widget
    emailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Widget principal: texto clicable que abre el diálogo
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 35),
      child: Align(
        alignment: Alignment.centerRight,
        child: InkWell(
          onTap: () => _showForgotPasswordDialog(context),
          child: const Text(
            "¿Olvidaste tu contraseña?",
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
              color: Color(0xff259AC5), // Color fijo en modo claro
            ),
          ),
        ),
      ),
    );
  }

  /// Muestra un diálogo para ingresar email y enviar link de reset
  void _showForgotPasswordDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return Dialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Título y botón de cerrar
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const SizedBox(width: 24),
                    const Text(
                      "Olvidaste tu contraseña",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                        color: Colors.black87,
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(dialogContext),
                      icon: const Icon(
                        Icons.close,
                        color: Colors.black87,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                // Campo de texto para ingresar email
                TextField(
                  controller: emailController,
                  keyboardType: TextInputType.emailAddress,
                  style: const TextStyle(color: Colors.black87),
                  decoration: InputDecoration(
                    labelText: "Ingresa tu correo electrónico",
                    labelStyle: const TextStyle(color: Colors.black87),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(color: Colors.grey),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(
                        color: Color(0xff259AC5),
                        width: 2,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                // Botón para enviar el email de restablecimiento
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xff259AC5),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    onPressed: () async {
                      try {
                        // Enviar email de reset a través de FirebaseAuth
                        await auth.sendPasswordResetEmail(
                          email: emailController.text.trim(),
                        );
                        // Mostrar snackbar de confirmación
                        showCustomSnackBar(
                          context,
                          "Enviamos el enlace de restablecimiento a tu email. Revisa tu bandeja de entrada.",
                        );
                      } catch (error) {
                        // Mostrar snackbar con mensaje de error
                        showCustomSnackBar(context, error.toString());
                      }
                      // Cerrar el diálogo y limpiar el campo
                      Navigator.pop(dialogContext);
                      emailController.clear();
                    },
                    child: const Text(
                      "Enviar",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
