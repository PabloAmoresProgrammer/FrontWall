import 'dart:io';
import 'package:flutter/material.dart';
import 'package:frontwall/controllers/api_controller.dart';
import 'package:frontwall/model/image_model.dart';
import '../routes/app_routes.dart';

/// Pantalla principal con secciones de wallpapers: destacados, recomendados y favoritos
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  /// Future para obtener wallpapers recomendados basados en categorías favoritas
  late Future<List<ImageModel>> _futureRecommended;

  /// Lista de URLs de wallpapers marcados como favoritos por el usuario
  List<String> _favWallpapers = [];

  @override
  void initState() {
    super.initState();
    // Cargar recomendaciones y favoritos al iniciar la pantalla
    _futureRecommended = ApiController.getRecommendedWallpapers();
    _loadFavorites();
  }

  /// Carga las URLs de wallpapers favoritos desde Firestore y actualiza el estado
  Future<void> _loadFavorites() async {
    final favs = await ApiController.getUserFavoriteWallpapers();
    if (!mounted) return;
    setState(() => _favWallpapers = favs);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    // Colores
    final backgroundColor =
        isDark ? Colors.grey.shade900 : Colors.grey.shade100;
    final sectionTitleColor = isDark ? Colors.white : Colors.grey.shade900;
    final italicTextColor =
        isDark ? Colors.grey.shade400 : Colors.grey.shade700;
    final shadowColor = isDark
        ? Colors.black.withOpacity(0.6)
        : Colors.grey.shade400.withOpacity(0.3);

    return Scaffold(
      backgroundColor: backgroundColor,
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
        children: [
          // Sección: Fondos destacados
          Text(
            'Fondos destacados',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: sectionTitleColor,
            ),
          ),
          const SizedBox(height: 12),
          FutureBuilder<List<ImageModel>>(
            // Future para wallpapers en tendencia
            future: ApiController.getTrendingWallpapers(),
            builder: (ctx, snap) {
              if (snap.connectionState == ConnectionState.waiting) {
                // Mostrar indicador mientras carga
                return const SizedBox(
                  height: 160,
                  child: Center(child: CircularProgressIndicator()),
                );
              }
              final list = snap.data ?? [];
              // Renderizar carrusel horizontal
              return _buildHorizontalCarousel(
                list.map((i) => i.imageSrc).toList(),
                showFavorite: true,
                shadowColor: shadowColor,
                isDark: isDark,
              );
            },
          ),
          const SizedBox(height: 28),

          // Sección: Recomendados para ti
          Text(
            'Recomendados para ti',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: sectionTitleColor,
            ),
          ),
          const SizedBox(height: 12),
          FutureBuilder<List<ImageModel>>(
            // Future cargado en initState para recomendaciones
            future: _futureRecommended,
            builder: (ctx, snap) {
              if (snap.connectionState == ConnectionState.waiting) {
                return const SizedBox(
                  height: 160,
                  child: Center(child: CircularProgressIndicator()),
                );
              }
              final list = snap.data ?? [];
              if (list.isEmpty) {
                // Mensaje si no hay recomendaciones (sin categorías favoritas)
                return Container(
                  height: 100,
                  alignment: Alignment.center,
                  child: Text(
                    'Añade alguna categoría a favoritos',
                    style: TextStyle(
                      fontSize: 16,
                      fontStyle: FontStyle.italic,
                      color: italicTextColor,
                    ),
                    textAlign: TextAlign.center,
                  ),
                );
              }
              return _buildHorizontalCarousel(
                list.map((i) => i.imageSrc).toList(),
                showFavorite: true,
                shadowColor: shadowColor,
                isDark: isDark,
              );
            },
          ),
          const SizedBox(height: 28),

          // Sección: Tus favoritos
          Text(
            'Tus favoritos',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: sectionTitleColor,
            ),
          ),
          const SizedBox(height: 12),
          if (_favWallpapers.isEmpty)
            // Mensaje si el usuario no tiene favoritos
            Container(
              height: 100,
              alignment: Alignment.center,
              child: Text(
                'No tienes fondos guardados como favoritos',
                style: TextStyle(
                  fontSize: 16,
                  fontStyle: FontStyle.italic,
                  color: italicTextColor,
                ),
                textAlign: TextAlign.center,
              ),
            )
          else
            // Carrusel de favoritos guardados localmente
            _buildHorizontalCarousel(
              _favWallpapers,
              showFavorite: true,
              shadowColor: shadowColor,
              isDark: isDark,
            ),
        ],
      ),
    );
  }

  /// Construye un carrusel horizontal de imágenes
  /// [urls]: lista de rutas o URLs de imagen
  /// [showFavorite]: indica si muestra botón de favorito sobre la imagen
  /// [shadowColor]: color de sombra bajo la tarjeta
  /// [isDark]: modo oscuro para adaptar estilos de ícono
  Widget _buildHorizontalCarousel(
    List<String> urls, {
    required bool showFavorite,
    required Color shadowColor,
    required bool isDark,
  }) {
    return SizedBox(
      height: 160,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: urls.length,
        itemBuilder: (_, i) {
          final img = urls[i];
          final isFav = _favWallpapers.contains(img);
          return Stack(
            children: [
              GestureDetector(
                onTap: () {
                  Navigator.pushNamed(
                    context,
                    AppRoutes.wallpaperDetail,
                    arguments: {'imageUrl': img},
                  );
                },
                child: Container(
                  margin: const EdgeInsets.only(right: 12),
                  width: 120,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: shadowColor,
                        offset: const Offset(0, 4),
                        blurRadius: 6,
                      ),
                    ],
                    image: DecorationImage(
                      image: img.startsWith('http')
                          ? NetworkImage(img)
                          : FileImage(File(img)) as ImageProvider,
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
              ),
              if (showFavorite)
                // Botón de favorito sobre la imagen
                Positioned(
                  top: 8,
                  right: 8,
                  child: IconButton(
                    icon: Icon(
                      isFav ? Icons.star : Icons.star_border,
                      color: isFav
                          ? Colors.amber
                          : (isDark ? Colors.grey.shade200 : Colors.white),
                      size: 24,
                    ),
                    onPressed: () async {
                      // Alternar favorito en Firestore y estado local
                      await ApiController.toggleFavoriteWallpaper(img, !isFav);
                      if (!mounted) return;
                      setState(() {
                        if (isFav) {
                          _favWallpapers.remove(img);
                        } else {
                          _favWallpapers.add(img);
                        }
                      });
                    },
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}
