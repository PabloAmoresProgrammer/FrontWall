import 'package:flutter/material.dart';

/// Widget de campo de texto personalizado
class CustomTextField extends StatelessWidget {
  /// Controlador para el texto ingresado
  final TextEditingController inputController;

  /// Determina si el campo oculta el texto (para contraseñas)
  final bool isPasswordField;

  /// Texto de sugerencia mostrado cuando el campo está vacío
  final String placeholderText;

  /// Ícono opcional que aparece al inicio del campo
  final IconData? icon;

  /// Tipo de entrada
  final TextInputType inputType;

  /// Color opcional para el texto ingresado
  final Color? textColor;

  /// Color opcional para el texto de sugerencia
  final Color? hintColor;

  /// Color opcional de fondo del campo
  final Color? fillColor;

  const CustomTextField({
    super.key,
    required this.inputController,
    this.isPasswordField = false,
    required this.placeholderText,
    this.icon,
    required this.inputType,
    this.textColor,
    this.hintColor,
    this.fillColor,
  });

  @override
  Widget build(BuildContext context) {
    // Determinar si está en modo oscuro
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Colores
    final effectiveFillColor =
        fillColor ?? (isDark ? Colors.grey.shade800 : Colors.white);
    final effectiveTextColor =
        textColor ?? (isDark ? Colors.grey.shade100 : Colors.black);
    final effectiveHintColor =
        hintColor ?? (isDark ? Colors.grey.shade400 : Colors.black45);

    final prefixIconColor = isDark ? Colors.grey.shade300 : Colors.black54;

    // Color de borde al enfocar
    final focusedBorderColor = Theme.of(context).primaryColor;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 20),
      child: TextField(
        controller: inputController,
        keyboardType: inputType,
        obscureText: isPasswordField,
        style: TextStyle(
          fontSize: 20,
          color: effectiveTextColor,
        ),
        decoration: InputDecoration(
          // Ícono al inicio
          prefixIcon: icon != null ? Icon(icon, color: prefixIconColor) : null,
          hintText: placeholderText,
          hintStyle: TextStyle(
            color: effectiveHintColor,
            fontSize: 18,
          ),
          enabledBorder: OutlineInputBorder(
            borderSide: BorderSide.none,
            borderRadius: BorderRadius.circular(30),
          ),
          border: InputBorder.none,
          // Borde al enfocar con color primario
          focusedBorder: OutlineInputBorder(
            borderSide: BorderSide(color: focusedBorderColor, width: 2),
            borderRadius: BorderRadius.circular(30),
          ),
          filled: true,
          fillColor: effectiveFillColor,
          contentPadding: const EdgeInsets.symmetric(
            vertical: 15,
            horizontal: 20,
          ),
        ),
      ),
    );
  }
}
