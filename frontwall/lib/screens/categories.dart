import 'package:flutter/material.dart';
import 'package:frontwall/controllers/api_controller.dart';
import 'package:frontwall/model/category_model.dart';
import 'search.dart';

/// Pantalla que muestra las categorías
class CategoriesScreen extends StatefulWidget {
  const CategoriesScreen({super.key});

  @override
  State<CategoriesScreen> createState() => CategoriesScreenState();
}

class CategoriesScreenState extends State<CategoriesScreen> {
  /// Future que resuelve la lista de categorías (genéricas + favoritas)
  late Future<List<CategoryModel>> _futureCats;

  @override
  void initState() {
    super.initState();
    // Cargar categorías al iniciar el estado
    _loadCategories();
  }

  /// Inicializa _futureCats
  void _loadCategories() {
    _futureCats = ApiController.getCategoriesWithFavorites();
  }

  /// Permite recargar el grid de categorías manualmente
  void reload() {
    setState(() => _loadCategories());
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    // Colores de fondo y texto según modo oscuro/claro
    final backgroundColor =
        isDark ? Colors.grey.shade900 : Colors.grey.shade100;
    final errorTextColor = isDark ? Colors.grey.shade200 : Colors.grey.shade900;
    final shadowColor =
        isDark ? Colors.black45 : Colors.grey.shade400.withOpacity(0.3);
    const overlayTextColor = Colors.white;

    return Scaffold(
      backgroundColor: backgroundColor,
      body: FutureBuilder<List<CategoryModel>>(
        // Construye UI basada en el estado de la Future
        future: _futureCats,
        builder: (context, snap) {
          // Mientras carga, mostrar spinner
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          // Si hubo error, mostrar mensaje
          if (snap.hasError) {
            return Center(
              child: Text(
                'Error: \${snap.error}',
                style: TextStyle(
                  color: errorTextColor,
                  fontSize: 16,
                ),
              ),
            );
          }
          // Una vez se obtienen categorías, construir grid
          final cats = snap.data!;
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: GridView.builder(
              itemCount: cats.length,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2, // Dos columnas
                crossAxisSpacing: 12, // Espacio horizontal
                mainAxisSpacing: 12, // Espacio vertical
                childAspectRatio: 1.0, // Proporción cuadrada
              ),
              itemBuilder: (context, i) {
                final cat = cats[i];
                return GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => SearchScreen(
                          initialQuery: cat.categoryName,
                          showSearchBar: false,
                        ),
                      ),
                    );
                  },
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: [
                        BoxShadow(
                          color: shadowColor,
                          offset: const Offset(0, 4),
                          blurRadius: 6,
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(14),
                      child: Stack(
                        children: [
                          // Imagen de fondo de la categoría
                          Positioned.fill(
                            child: Image.network(
                              cat.categoryImgUrl,
                              fit: BoxFit.cover,
                            ),
                          ),
                          // Overlay semitransparente para mejorar legibilidad
                          Positioned.fill(
                            child: Container(
                              color: Colors.black.withOpacity(0.25),
                            ),
                          ),
                          // Texto centrado con nombre de categoría
                          Center(
                            child: Text(
                              cat.categoryName,
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                color: overlayTextColor,
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          // Ícono de favorito en la esquina superior derecha
                          Positioned(
                            top: 8,
                            right: 8,
                            child: IconButton(
                              icon: Icon(
                                cat.isFavorite ? Icons.star : Icons.star_border,
                                color: cat.isFavorite
                                    ? Colors.amber
                                    : Colors.white,
                                size: 24,
                              ),
                              // Al presionar, alternar favorito y actualizar Firestore
                              onPressed: () async {
                                await ApiController.toggleFavorite(
                                  cat.categoryName,
                                  !cat.isFavorite,
                                );
                                setState(() {
                                  cat.isFavorite = !cat.isFavorite;
                                });
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}
