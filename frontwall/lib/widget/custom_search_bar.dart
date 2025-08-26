import 'package:flutter/material.dart';

/// Barra de búsqueda personalizada
class CustomSearchBar extends StatelessWidget {
  /// Controlador del TextField para la búsqueda
  final TextEditingController controller;

  /// Acción a ejecutar cuando se inicia la búsqueda
  final VoidCallback onSearch;

  /// Constructor principal
  const CustomSearchBar({
    super.key,
    required this.controller,
    required this.onSearch,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        color: const Color.fromARGB(66, 192, 192, 192),
        border: Border.all(color: const Color.fromARGB(33, 13, 5, 5)),
        borderRadius: BorderRadius.circular(25),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: controller,
              onSubmitted: (_) => onSearch(),
              decoration: const InputDecoration(
                hintText: "Buscar fondos",
                border: InputBorder.none,
              ),
            ),
          ),
          InkWell(
            onTap: onSearch,
            child: const Padding(
              padding: EdgeInsets.all(8.0),
              child: Icon(Icons.search),
            ),
          ),
        ],
      ),
    );
  }
}
