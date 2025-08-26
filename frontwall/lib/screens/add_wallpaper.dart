import 'dart:io';
import 'package:flutter/material.dart';
import 'package:frontwall/routes/app_routes.dart';
import 'package:image_picker/image_picker.dart';
import 'package:frontwall/controllers/api_controller.dart';
import 'package:image_gallery_saver/image_gallery_saver.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:translator/translator.dart';

/// Pantalla para añadir un nuevo wallpaper
///
/// Permite al usuario:
/// 1. Seleccionar una imagen de la galería o cámara.
/// 2. Generar una imagen usando IA (Stability AI) con un prompt traducido.
/// 3. Previsualizar la imagen seleccionada o generada.
/// 4. Guardar la imagen resultante en la galería del dispositivo.
class AddWallpaperScreen extends StatefulWidget {
  const AddWallpaperScreen({super.key});

  @override
  State<AddWallpaperScreen> createState() => _AddWallpaperScreenState();
}

class _AddWallpaperScreenState extends State<AddWallpaperScreen> {
  /// Archivo de imagen local seleccionado por el usuario (galería o cámara)
  File? _pickedImage;

  /// URL de imagen generada por IA
  String? _aiImageUrl;

  /// Instancia de ImagePicker para elegir imágenes
  final _picker = ImagePicker();

  /// Controlador de texto para el prompt de IA
  final _promptCtrl = TextEditingController();

  /// Indicadores de estado: generando con IA y guardando en galería
  bool _isGenerating = false;
  bool _isSaving = false;

  /// Abre selector de galería y guarda el archivo seleccionado en [_pickedImage]
  Future<void> _pickFromGallery() async {
    final XFile? file = await _picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 800,
    );
    if (file != null) {
      setState(() => _pickedImage = File(file.path));
    }
  }

  /// Abre cámara y guarda la foto tomada en [_pickedImage]
  Future<void> _pickFromCamera() async {
    final XFile? file = await _picker.pickImage(
      source: ImageSource.camera,
      maxWidth: 800,
    );
    if (file != null) {
      setState(() => _pickedImage = File(file.path));
    }
  }

  /// Genera una imagen con Stability AI usando el prompt traducido al inglés
  Future<void> _generateWithAI() async {
    final rawPrompt = _promptCtrl.text.trim();
    if (rawPrompt.isEmpty) return;

    setState(() => _isGenerating = true);

    try {
      // Traducir prompt al inglés para mayor compatibilidad con modelo AI
      final translator = GoogleTranslator();
      final translation = await translator.translate(rawPrompt, to: 'en');
      final promptEn = translation.text;

      // Generar imagen y obtener ruta local
      final localPath =
          await ApiController.generateImageWithStabilityAI(promptEn);

      // Actualizar estado con archivo generado
      setState(() {
        _pickedImage = File(localPath);
        _aiImageUrl = null;
      });
    } catch (e) {
      // Manejo de errores específicos de créditos o fallos de API
      final errorText = e.toString();
      if (errorText.contains('402') ||
          errorText.contains('todas las API keys de Stability AI')) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'No hay más créditos / todas las API keys de Stability AI fallaron.',
            ),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error IA: $e')),
        );
      }
    } finally {
      setState(() => _isGenerating = false);
    }
  }

  /// Guarda la imagen actual (seleccionada o generada) en la galería del dispositivo
  Future<void> _saveToGallery() async {
    // Determinar ruta a guardar (archivo local o URL IA)
    final displayPath = _pickedImage?.path ?? _aiImageUrl;
    if (displayPath == null) return;

    // Solicitar permiso en Android
    if (Platform.isAndroid) {
      final status = await Permission.storage.request();
      if (!status.isGranted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Permiso denegado para guardar imagen.')),
        );
        return;
      }
    }

    setState(() => _isSaving = true);

    try {
      final String pathToSave =
          _pickedImage != null ? _pickedImage!.path : _aiImageUrl!;
      // Guardar usando ImageGallerySaver
      final result = await ImageGallerySaver.saveFile(pathToSave);

      if (result['isSuccess'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('✅ Imagen guardada en la galería')),
        );
        Navigator.of(context).pop(true);
      } else {
        throw Exception('Error desconocido al guardar en galería');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al guardar: $e')),
      );
    } finally {
      setState(() => _isSaving = false);
    }
  }

  @override
  void dispose() {
    // Liberar recursos del controlador de texto
    _promptCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;

    // Colores UI clara/oscura
    final bgColor = isDarkMode ? Colors.grey.shade900 : Colors.grey.shade100;
    final appBarBg = isDarkMode ? Colors.grey.shade800 : Colors.grey.shade200;
    final textFieldBorder =
        isDarkMode ? Colors.grey.shade600 : Colors.grey.shade400;
    final buttonBg = isDarkMode ? Colors.grey.shade700 : Colors.grey.shade200;
    final buttonTextClr =
        isDarkMode ? Colors.grey.shade100 : Colors.grey.shade800;
    final hintColor = isDarkMode ? Colors.grey.shade300 : Colors.grey.shade800;

    // Ruta o archivo a mostrar en previsualización
    final displayUrl = _pickedImage?.path ?? _aiImageUrl;
    Widget preview;
    if (displayUrl != null) {
      preview = GestureDetector(
        onTap: () {
          Navigator.pushNamed(
            context,
            AppRoutes.wallpaperDetail,
            arguments: {'imageUrl': displayUrl},
          );
        },
        child: displayUrl.startsWith('http')
            ? Image.network(displayUrl, fit: BoxFit.contain)
            : Image.file(File(displayUrl), fit: BoxFit.contain),
      );
    } else {
      preview = Center(
        child: Text(
          'Selecciona o genera una imagen',
          style: TextStyle(color: hintColor),
        ),
      );
    }

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: appBarBg,
        elevation: 0,
        centerTitle: true,
        title: Text(
          'Añadir fondo',
          style: TextStyle(
            color: buttonTextClr,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
          ),
        ),
        iconTheme: IconThemeData(color: buttonTextClr),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Botones para elegir galería o cámara
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildSourceButton(
                  icon: Icons.photo_library,
                  label: 'Galería',
                  onPressed: _pickFromGallery,
                  bgColor: buttonBg,
                  textColor: buttonTextClr,
                ),
                _buildSourceButton(
                  icon: Icons.camera_alt,
                  label: 'Cámara',
                  onPressed: _pickFromCamera,
                  bgColor: buttonBg,
                  textColor: buttonTextClr,
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Campo para introducir prompt de IA
            TextField(
              controller: _promptCtrl,
              decoration: InputDecoration(
                labelText: 'Prompt IA',
                labelStyle: TextStyle(color: hintColor),
                border: OutlineInputBorder(
                  borderSide: BorderSide(color: textFieldBorder),
                  borderRadius: BorderRadius.circular(8),
                ),
                focusedBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: appBarBg),
                  borderRadius: BorderRadius.circular(8),
                ),
                contentPadding:
                    const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                filled: isDarkMode,
                fillColor: isDarkMode ? Colors.grey.shade800 : null,
              ),
              style: TextStyle(color: hintColor),
            ),
            const SizedBox(height: 16),

            // Botón para generar imagen IA
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                icon: _isGenerating
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2))
                    : const Icon(Icons.auto_fix_high, size: 20),
                label: const Text('Generar Imagen'),
                onPressed: _isGenerating ? null : _generateWithAI,
                style: ElevatedButton.styleFrom(
                  backgroundColor: buttonBg,
                  foregroundColor: buttonTextClr,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  textStyle: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.w500),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8)),
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Área de previsualización de imagen
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  color: appBarBg,
                  alignment: Alignment.center,
                  child: preview,
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Botón para guardar en galería
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                icon: _isSaving
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2))
                    : const Icon(Icons.save, size: 20),
                label: const Text('Guardar en Mi Galería'),
                onPressed:
                    (displayUrl == null || _isSaving) ? null : _saveToGallery,
                style: ElevatedButton.styleFrom(
                  backgroundColor: buttonBg,
                  foregroundColor: buttonTextClr,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  textStyle: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.w500),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Construye un botón con icono y estilo unificado
  Widget _buildSourceButton({
    required IconData icon,
    required String label,
    required VoidCallback onPressed,
    required Color bgColor,
    required Color textColor,
  }) {
    return ElevatedButton.icon(
      icon: Icon(icon, size: 20, color: textColor),
      label: Text(label, style: TextStyle(color: textColor)),
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: bgColor,
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        textStyle: const TextStyle(fontSize: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }
}
