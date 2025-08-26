import 'package:flutter/material.dart';
import 'package:frontwall/controllers/api_controller.dart';
import 'package:frontwall/model/image_model.dart';
import '../routes/app_routes.dart';
import 'package:frontwall/widget/custom_search_bar.dart';

/// Pantalla de búsqueda
class SearchScreen extends StatefulWidget {
  final String? initialQuery;

  /// Controlar si se muestra la barra de búsqueda en pantalla
  final bool showSearchBar;

  const SearchScreen({
    super.key,
    this.initialQuery,
    this.showSearchBar = true,
  });

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  /// Controlador para obtener el texto ingresado en la búsqueda
  final TextEditingController _searchController = TextEditingController();

  /// Lista de resultados obtenidos desde la API
  List<ImageModel> _results = [];

  /// Lista de URLs de wallpapers marcados como favoritos por el usuario
  List<String> _favWallpapers = [];

  /// Indicador de estado de carga durante la operación de búsqueda
  bool _isLoading = false;

  /// Mensaje de error en caso de fallo durante la búsqueda
  String? _error;

  @override
  void initState() {
    super.initState();
    // Cargar wallpapers favoritos del usuario
    _loadFavorites();
    // Si se proporciona un initialQuery, establecer el texto y ejecutar búsqueda
    if (widget.initialQuery != null) {
      _searchController.text = widget.initialQuery!;
      _doSearch();
    }
  }

  @override
  void dispose() {
    // Disposición del controlador para evitar memory leaks
    _searchController.dispose();
    super.dispose();
  }

  /// Obtiene la lista de wallpapers favoritos desde Firestore
  Future<void> _loadFavorites() async {
    _favWallpapers = await ApiController.getUserFavoriteWallpapers();
    setState(() {}); // Actualizar UI con los favoritos cargados
  }

  /// Realiza la búsqueda de wallpapers usando el texto actual
  Future<void> _doSearch() async {
    final query = _searchController.text.trim();
    if (query.isEmpty) return; // No iniciar búsqueda si está vacío

    // Establecer estado de carga y limpiar previos resultados/errores
    setState(() {
      _isLoading = true;
      _error = null;
      _results = [];
    });

    try {
      // Llamada a la API para buscar wallpapers
      final list = await ApiController.searchWallpapers(query);
      setState(() {
        _results = list; // Guardar resultados
      });
    } catch (e) {
      setState(() {
        _error = e.toString(); // Guardar mensaje de error
      });
    } finally {
      setState(() => _isLoading = false); // Finalizar estado de carga
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    // Colores adaptativos según tema
    final backgroundColor = isDark ? Colors.grey.shade900 : Colors.grey.shade50;
    final textColor = isDark ? Colors.white : Colors.grey.shade900;
    final hintColor = isDark ? Colors.grey.shade400 : Colors.grey.shade600;
    final errorContainerColor =
        isDark ? Colors.grey.shade800 : Colors.grey.shade200;
    final shadowColor = isDark ? Colors.black45 : Colors.grey.withOpacity(0.3);

    return Scaffold(
      backgroundColor: backgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 10),
            // Mostrar la barra de búsqueda si showSearchBar es true
            if (widget.showSearchBar) ...[
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: CustomSearchBar(
                  controller: _searchController,
                  onSearch: _doSearch, // Ejecutar búsqueda al presionar icono
                ),
              ),
              const SizedBox(height: 10),
            ],
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _error != null
                      // Mostrar error
                      ? Container(
                          color: errorContainerColor,
                          alignment: Alignment.center,
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Text(
                            'Error: $_error',
                            style: TextStyle(color: textColor, fontSize: 16),
                            textAlign: TextAlign.center,
                          ),
                        )
                      : _results.isEmpty
                          // Mostrar mensaje si no hay resultados
                          ? Container(
                              color: backgroundColor,
                              alignment: Alignment.center,
                              child: Text(
                                'No hay resultados',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontStyle: FontStyle.italic,
                                  color: hintColor,
                                ),
                              ),
                            )
                          // Mostrar grid de resultados
                          : GridView.builder(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 8),
                              gridDelegate:
                                  const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 2,
                                mainAxisSpacing: 12,
                                crossAxisSpacing: 12,
                                childAspectRatio: 0.7,
                              ),
                              itemCount: _results.length,
                              itemBuilder: (context, index) {
                                final imgUrl = _results[index].imageSrc;
                                final isFav = _favWallpapers.contains(imgUrl);
                                return ClipRRect(
                                  borderRadius: BorderRadius.circular(12),
                                  child: Stack(
                                    children: [
                                      // 1. Contenedor con la imagen de fondo y sombra
                                      Positioned.fill(
                                        child: Container(
                                          decoration: BoxDecoration(
                                            color: errorContainerColor,
                                            boxShadow: [
                                              BoxShadow(
                                                color: shadowColor,
                                                offset: const Offset(0, 2),
                                                blurRadius: 4,
                                              ),
                                            ],
                                          ),
                                          child: Image.network(
                                            imgUrl,
                                            fit: BoxFit.cover,
                                            loadingBuilder:
                                                (ctx, child, progress) {
                                              if (progress == null)
                                                return child;
                                              return const Center(
                                                  child:
                                                      CircularProgressIndicator());
                                            },
                                            errorBuilder: (ctx, error, stack) {
                                              return Center(
                                                child: Icon(
                                                  Icons.broken_image,
                                                  color: hintColor,
                                                  size: 40,
                                                ),
                                              );
                                            },
                                          ),
                                        ),
                                      ),
                                      // 2. Capa táctil para entrar al fondo
                                      Positioned.fill(
                                        child: Material(
                                          color: Colors.transparent,
                                          child: InkWell(
                                            onTap: () {
                                              Navigator.pushNamed(
                                                context,
                                                AppRoutes.wallpaperDetail,
                                                arguments: {'imageUrl': imgUrl},
                                              );
                                            },
                                          ),
                                        ),
                                      ),
                                      // 3. Botón de favorito
                                      Positioned(
                                        top: 8,
                                        right: 8,
                                        child: IconButton(
                                          icon: Icon(
                                            isFav
                                                ? Icons.star
                                                : Icons.star_border,
                                            color: isFav
                                                ? Colors.amber
                                                : (isDark
                                                    ? Colors.grey.shade200
                                                    : Colors.white),
                                            size: 24,
                                          ),
                                          onPressed: () async {
                                            // Alternar favorito en Firestore y actualización local
                                            await ApiController
                                                .toggleFavoriteWallpaper(
                                                    imgUrl, !isFav);
                                            setState(() {
                                              if (isFav) {
                                                _favWallpapers.remove(imgUrl);
                                              } else {
                                                _favWallpapers.add(imgUrl);
                                              }
                                            });
                                          },
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),
            ),
          ],
        ),
      ),
    );
  }
}
