import 'package:flutter/material.dart';

/// Botón personalizado
class CustomButton extends StatelessWidget {
  /// Callback que se ejecuta al presionar el botón
  final VoidCallback onTap;

  /// Texto a mostrar dentro del botón
  final String buttonText;

  /// Color de fondo opcional.
  final Color? backgroundColor;

  /// Color de texto opcional.
  final Color? textColor;

  const CustomButton({
    super.key,
    required this.onTap,
    required this.buttonText,
    this.backgroundColor,
    this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    // Determinar si la app está en modo oscuro
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Color de fondo efectivo: personalizado o por defecto según tema
    final effectiveBgColor = backgroundColor ??
        (isDark ? Theme.of(context).primaryColor : const Color(0xff259AC5));

    // Color de texto efectivo: personalizado o blanco siempre
    final effectiveTextColor = textColor ?? Colors.white;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 10),
      child: Container(
        // Bordes redondeados
        decoration: ShapeDecoration(
          color: effectiveBgColor,
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(30)),
          ),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(30),
          onTap: onTap,
          child: Container(
            alignment: Alignment.center,
            height: 50,
            child: Text(
              buttonText,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: effectiveTextColor,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
