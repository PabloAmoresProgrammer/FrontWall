import 'package:flutter/material.dart';
import 'package:frontwall/screens/add_category_dialog.dart';
import '../screens/home.dart';
import '../screens/search.dart';
import '../screens/categories.dart';
import '../routes/app_routes.dart';

/// Pantalla principal con navegación de pestañas: Inicio, Buscar y Categorías
class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  /// Índice de la pestaña seleccionada
  int _selectedIndex = 0;

  /// Clave global para acceder al estado de CategoriesScreen y recargarla
  final _categoriesKey = GlobalKey<CategoriesScreenState>();

  /// Lista de widgets que representan cada pestaña
  List<Widget> get _tabs => [
        const HomeScreen(),
        const SearchScreen(),
        CategoriesScreen(key: _categoriesKey),
      ];

  /// Títulos del AppBar según la pestaña activa
  static const List<String> _titles = [
    'Inicio',
    'Buscar fondo',
    'Categorías',
  ];

  /// Actualiza el índice de pestaña cuando se selecciona en el BottomNavigationBar
  void _onTap(int idx) => setState(() => _selectedIndex = idx);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    // Colores adaptativos
    final appBarColor = isDark ? Colors.grey.shade800 : Colors.grey.shade200;
    final bottomBarColor = isDark ? Colors.grey.shade900 : Colors.white;
    final unselectedColor =
        isDark ? Colors.grey.shade400 : Colors.grey.shade600;
    final selectedTextColor = theme.primaryColor;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: appBarColor,
        elevation: 1,
        centerTitle: true,
        automaticallyImplyLeading: false,
        // Título dinámico según pestaña
        title: Text(
          _titles[_selectedIndex],
          style: theme.textTheme.titleLarge?.copyWith(
            color: isDark ? Colors.white : Colors.black87,
            fontWeight: FontWeight.w600,
          ),
        ),
        iconTheme: IconThemeData(
          color: isDark ? Colors.white : Colors.black87,
        ),
        actions: [
          // Acciones específicas para cada pestaña
          if (_selectedIndex == 0) ...[
            // Pestaña Inicio: añadir fondo y ajustes
            IconButton(
              icon: const Icon(Icons.add),
              tooltip: 'Añadir fondo',
              onPressed: () =>
                  Navigator.pushNamed(context, AppRoutes.addWallpaperScreen),
            ),
            IconButton(
              icon: const Icon(Icons.settings),
              tooltip: 'Ajustes',
              onPressed: () =>
                  Navigator.pushNamed(context, AppRoutes.settingsScreen),
            ),
          ],
          if (_selectedIndex == 2)
            // Pestaña Categorías: abrir diálogo para nueva categoría
            IconButton(
              icon: const Icon(Icons.add),
              tooltip: 'Nueva categoría',
              onPressed: () async {
                final added = await showDialog<bool>(
                  context: context,
                  builder: (_) => const AddCategoryDialog(),
                );
                // Si se agregó, recargar lista de categorías
                if (added == true) {
                  _categoriesKey.currentState?.reload();
                }
              },
            ),
        ],
      ),
      // Mostrar contenido de la pestaña seleccionada
      body: _tabs[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onTap,
        type: BottomNavigationBarType.fixed,
        backgroundColor: bottomBarColor,
        selectedItemColor: selectedTextColor,
        unselectedItemColor: unselectedColor,
        selectedLabelStyle: theme.textTheme.bodySmall?.copyWith(
          fontWeight: FontWeight.w600,
          color: selectedTextColor,
        ),
        unselectedLabelStyle: theme.textTheme.bodySmall?.copyWith(
          color: unselectedColor,
        ),
        elevation: 4,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            activeIcon: Icon(Icons.home),
            label: 'Inicio',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.search_outlined),
            activeIcon: Icon(Icons.search),
            label: 'Buscar',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.category_outlined),
            activeIcon: Icon(Icons.category),
            label: 'Categorías',
          ),
        ],
      ),
    );
  }
}
