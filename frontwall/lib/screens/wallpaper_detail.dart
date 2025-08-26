import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:wallpaper_manager_flutter/wallpaper_manager_flutter.dart';

/// Pantalla para aplicar wallpaper
class WallpaperDetailScreen extends StatefulWidget {
  const WallpaperDetailScreen({super.key});

  @override
  State<WallpaperDetailScreen> createState() => _WallpaperDetailScreenState();
}

class _WallpaperDetailScreenState extends State<WallpaperDetailScreen> {
  bool _setting = false;

  /// Descarga la imagen si es una URL y aplica el wallpaper
  /// [pathOrUrl]: ruta local o URL de la imagen
  /// [location]: destino (home, lock o ambas pantallas)
  Future<void> _setWallpaper(String pathOrUrl, int location) async {
    setState(() => _setting = true);
    try {
      String filePath = pathOrUrl;

      // Si la ruta es una URL, descargar la imagen a un archivo temporal
      if (pathOrUrl.startsWith('http')) {
        final uri = Uri.parse(pathOrUrl);
        final response = await HttpClient().getUrl(uri).then((r) => r.close());
        final bytes = await consolidateHttpClientResponseBytes(response);
        final tmp = File(
          '${Directory.systemTemp.path}/wallpaper_${DateTime.now().millisecondsSinceEpoch}.jpg',
        );
        await tmp.writeAsBytes(bytes);
        filePath = tmp.path;
      }

      // Intentar aplicar el wallpaper usando la librería
      final success = await WallpaperManagerFlutter()
          .setWallpaper(File(filePath), location);

      if (!success) throw 'El sistema rechazó la operación';

      // Mostrar mensaje de éxito
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Fondo aplicado correctamente'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      // Mostrar mensaje de error
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al aplicar fondo: \$e'),
          backgroundColor: Colors.red.shade700,
        ),
      );
      // Imprimir en consola para debug
      if (kDebugMode) debugPrint('[_setWallpaper] Error: \$e');
    } finally {
      setState(() => _setting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Recuperar la URL de la imagen
    final args = ModalRoute.of(context)!.settings.arguments as Map?;
    final imageUrl = args?['imageUrl'] as String?;

    // Construir el widget que mostrará la imagen o un mensaje si no hay
    Widget imageWidget;
    if (imageUrl == null) {
      imageWidget = Center(
        child: Text(
          'No hay imagen para mostrar',
          style: TextStyle(
            fontSize: 16,
            color: Theme.of(context).brightness == Brightness.dark
                ? Colors.grey.shade300
                : Colors.black54,
          ),
        ),
      );
    } else if (imageUrl.startsWith('http')) {
      imageWidget = Image.network(imageUrl, fit: BoxFit.cover);
    } else {
      imageWidget = Image.file(File(imageUrl), fit: BoxFit.cover);
    }

    // Determinar colores según tema claro/oscuro
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor =
        isDarkMode ? Colors.grey.shade900 : Colors.grey.shade100;
    final appBarColor =
        isDarkMode ? Colors.grey.shade800 : Colors.grey.shade200;
    final buttonColor =
        isDarkMode ? Colors.grey.shade800 : Colors.grey.shade200;
    final textColor = isDarkMode ? Colors.grey.shade100 : Colors.grey.shade800;
    final borderColor =
        isDarkMode ? Colors.grey.shade700 : Colors.grey.shade300;

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        backgroundColor: appBarColor,
        elevation: 0,
        centerTitle: true,
        title: Text(
          'Detalle del fondo',
          style: TextStyle(color: textColor, fontWeight: FontWeight.w600),
        ),
        iconTheme: IconThemeData(color: textColor),
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Column(
          children: [
            // Contenedor que muestra la imagen con sombra y bordes redondeados
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: isDarkMode ? Colors.grey.shade800 : Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: isDarkMode
                          ? Colors.black.withOpacity(0.3)
                          : Colors.grey.shade400.withOpacity(0.3),
                      offset: const Offset(0, 4),
                      blurRadius: 6,
                    ),
                  ],
                ),
                clipBehavior: Clip.hardEdge,
                child: imageWidget,
              ),
            ),
            const SizedBox(height: 20),
            // Indicador de carga mientras se aplica el fondo
            if (_setting)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(8),
                  child: CircularProgressIndicator(),
                ),
              )
            else
              // Botones para aplicar en diferentes ubicaciones
              Column(
                children: [
                  _buildSettingButton(
                    icon: Icons.home,
                    label: 'Pantalla de inicio',
                    onPressed: imageUrl == null
                        ? null
                        : () => _setWallpaper(
                              imageUrl,
                              WallpaperManagerFlutter.homeScreen,
                            ),
                    buttonColor: buttonColor,
                    textColor: textColor,
                    borderColor: borderColor,
                    isDarkMode: isDarkMode,
                  ),
                  const SizedBox(height: 12),
                  _buildSettingButton(
                    icon: Icons.lock,
                    label: 'Pantalla de bloqueo',
                    onPressed: imageUrl == null
                        ? null
                        : () => _setWallpaper(
                              imageUrl,
                              WallpaperManagerFlutter.lockScreen,
                            ),
                    buttonColor: buttonColor,
                    textColor: textColor,
                    borderColor: borderColor,
                    isDarkMode: isDarkMode,
                  ),
                  const SizedBox(height: 12),
                  _buildSettingButton(
                    icon: Icons.smartphone,
                    label: 'Ambas pantallas',
                    onPressed: imageUrl == null
                        ? null
                        : () => _setWallpaper(
                              imageUrl,
                              WallpaperManagerFlutter.bothScreens,
                            ),
                    buttonColor: buttonColor,
                    textColor: textColor,
                    borderColor: borderColor,
                    isDarkMode: isDarkMode,
                  ),
                ],
              ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  /// Construye un botón con icono y texto para aplicar el wallpaper
  Widget _buildSettingButton({
    required IconData icon,
    required String label,
    required VoidCallback? onPressed,
    required Color buttonColor,
    required Color textColor,
    required Color borderColor,
    required bool isDarkMode,
  }) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        icon: Icon(icon, size: 22, color: textColor),
        label: Text(
          label,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: textColor,
          ),
        ),
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: buttonColor,
          elevation: 0,
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
            side: BorderSide(color: borderColor),
          ),
        ),
      ),
    );
  }
}
