import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:frontwall/controllers/api_controller.dart';
import 'package:frontwall/model/category_model.dart';

/// Diálogo para añadir una nueva categoría
///
/// Permite al usuario ingresar un nombre de categoría, busca una imagen
/// representativa y guarda la categoría en Firestore.
class AddCategoryDialog extends StatefulWidget {
  const AddCategoryDialog({super.key});

  @override
  State<AddCategoryDialog> createState() => _AddCategoryDialogState();
}

class _AddCategoryDialogState extends State<AddCategoryDialog> {
  // Controlador para el campo de texto de nombre de categoría
  final _nameCtrl = TextEditingController();

  // Indicadores de estado: carga en progreso y error en operación
  bool _loading = false;
  bool _error = false;

  /// Envía la nueva categoría a Firestore.
  /// Pasos:
  /// 1. Validar que el nombre no esté vacío.
  /// 2. Buscar imágenes con la palabra clave para obtener URL.
  /// 3. Guardar la categoría en la subcolección 'categories' del usuario.
  /// 4. Manejar estados de carga y errores.
  Future<void> _submit() async {
    final name = _nameCtrl.text.trim();
    if (name.isEmpty) return;

    // Mostrar indicador de carga
    setState(() {
      _loading = true;
      _error = false;
    });

    try {
      final imgs = await ApiController.searchWallpapers(name);
      final imgUrl = imgs.isNotEmpty ? imgs.first.imageSrc : '';

      // Obtener usuario autenticado
      final user = FirebaseAuth.instance.currentUser!;

      // Añadir nueva categoría a Firestore
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('categories')
          .add(
            CategoryModel(
              categoryImgUrl: imgUrl,
              categoryName: name,
            ).toFirestore(),
          );

      // Cerrar diálogo indicando éxito
      Navigator.of(context).pop(true);
    } catch (_) {
      // Mostrar mensaje de error
      setState(() {
        _error = true;
      });
    } finally {
      // Ocultar indicador de carga
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Tema actual para adaptar colores según modo oscuro/claro
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    // Definición de colores según modo
    final backgroundColor = isDark ? Colors.grey.shade800 : Colors.white;
    final titleColor = isDark ? Colors.grey.shade100 : Colors.grey.shade900;
    final textColor = isDark ? Colors.grey.shade200 : Colors.grey.shade800;
    final hintColor = isDark ? Colors.grey.shade400 : Colors.grey.shade500;
    final errorColor = isDark ? Colors.red.shade300 : Colors.red.shade700;
    final borderColor = isDark ? Colors.grey.shade600 : Colors.grey.shade400;
    final buttonColor = isDark ? Colors.grey.shade700 : Colors.grey.shade200;
    final buttonTextColor =
        isDark ? Colors.grey.shade100 : Colors.grey.shade800;

    return Dialog(
      backgroundColor: backgroundColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      insetPadding: const EdgeInsets.symmetric(horizontal: 40),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 24, 20, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Nueva categoría',
              style: TextStyle(
                color: titleColor,
                fontSize: 20,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 16),

            // Campo de texto para ingresar nombre de categoría
            TextField(
              controller: _nameCtrl,
              decoration: InputDecoration(
                hintText: 'Nombre de la categoría',
                hintStyle: TextStyle(
                  color: hintColor,
                  fontSize: 14,
                ),
                contentPadding:
                    const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: borderColor),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: titleColor),
                ),
                filled: isDark,
                fillColor: isDark ? Colors.grey.shade700 : null,
              ),
              style: TextStyle(color: textColor, fontSize: 16),
            ),

            // Texto de error si ocurrió un fallo al guardar
            if (_error)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  'Error al guardar',
                  style: TextStyle(
                    color: errorColor,
                    fontSize: 14,
                  ),
                ),
              ),

            const SizedBox(height: 24),

            // Botones Cancelar o Añadir
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                // Botón cancelar
                TextButton(
                  onPressed:
                      _loading ? null : () => Navigator.of(context).pop(false),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                        vertical: 10, horizontal: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    backgroundColor: buttonColor.withOpacity(0.5),
                  ),
                  child: Text(
                    'Cancelar',
                    style: TextStyle(
                      color: buttonTextColor,
                      fontSize: 16,
                    ),
                  ),
                ),

                const SizedBox(width: 12),

                // Botón añadir (muestra loading si está en proceso)
                TextButton(
                  onPressed: _loading ? null : _submit,
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                        vertical: 10, horizontal: 16),
                    backgroundColor: buttonColor,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: _loading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Text(
                          'Añadir',
                          style: TextStyle(
                            color: buttonTextColor,
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
