import 'package:flutter/material.dart';

/// Muestra un SnackBar personalizado
void showCustomSnackBar(BuildContext context, String message) {
  // Obtener el ScaffoldMessenger del contexto y mostrar el SnackBar
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      // Contenido principal del SnackBar: un texto con el mensaje
      content: Text(
        message,
        style: const TextStyle(
          fontSize: 16,
        ),
      ),
      duration: const Duration(seconds: 3),
      behavior: SnackBarBehavior.floating,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
    ),
  );
}
