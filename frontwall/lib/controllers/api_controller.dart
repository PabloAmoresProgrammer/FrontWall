import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:frontwall/model/category_model.dart';
import 'package:frontwall/model/image_model.dart';
import 'package:http/http.dart' as http;

class ApiController {
  // Lista de claves para Stability AI
  static const List<String> _stabilityKeys = [
    "sk-C2ujWixhl0QfmCeExmB1m7P7NEoxLY0bHHdbmhWQQiAzmENa",
    "sk-Wiv85uQ96QejQGXHRO2g39jBG98BAHU22OxutJHxi98DmMgd",
    "sk-xYXUIBNIGEyKaGyqZrdpB3ami105Ek6l7rzHvvdeoFxN3ab9",
    "sk-zIalX3zpce4VVYwRwKz39jK27zQ1Id5ryr6pG7eMlbpk7CkH",
    "sk-HZXdsBiN7zp5E9GeMnnnQN91vsegnbRxPbQdMwrbZQuHceYv",
    "sk-xLsNUDl5QTDFgEmIxW21WNKCd1wv4GBLslE1rHZ4E5mHsHtE",
    "sk-mJoYv16Q68m8aJlGwadbfgtd8kygzFZqXkqJ4XtOuDZH0kDa",
    "sk-uvoOXF3TxAvWqSosZnPljv4KE7somhfWk5u9VYQG2nrO6Pyt",
    "sk-9LJoIfkIAkaGKz7ldwvYrhVCrZ3LVQpWcROjCBqvvVgRXHAE",
  ];
  // Índice actual en la rotación de claves de Stability AI
  static int _stabilityKeyIndex = 0;

  /// Obtiene la clave de Stability AI actualmente activa
  static String get _currentStabilityKey => _stabilityKeys[_stabilityKeyIndex];

  /// Rota al siguiente índice de clave de Stability AI en caso de límite o error
  static void _rotateStabilityKey() {
    _stabilityKeyIndex = (_stabilityKeyIndex + 1) % _stabilityKeys.length;
    if (kDebugMode) {
      debugPrint(
        "[Stability] Rotated key → índice $_stabilityKeyIndex "
        "(key=${_currentStabilityKey.substring(0, 10)}…)",
      );
    }
  }

  // Lista de claves de API para Pexels
  static const List<String> _apiKeys = [
    "dlAL7tDIuRXduDfLysu8Qswg3Ko2oF9qAbLn1qzRl5ByZmsmvHdslE9a",
    "khGjg2Hc7b8fjJ5KTwILrBNNwsagUvlqxzXYBKzc8DZPYCQx9XltqdrG",
    "SCki4na6Zih1Ch4Us1eQNCHry1MdXyYZdTDNBlUmCetJ4U9c40IpOzTn",
    "PN7RhnxinaR093Tw0kqVJ5FOIKZACluPmVuqHaaGzCeiTGxgibpkZrU0",
    "KXB0NswTptKdbHRNa9eTorIR7CTvZN88KkJ9X140HSzu4Gb2UAO3xS0j",
    "HX2btwgwrxZNP2etBhPyomz3txUi3FTtwN0xgudpiazk9sY9zdgKN8Jc",
  ];
  // Índice actual en la rotación de claves de Pexels
  static int _keyIndex = 0;

  /// Obtiene la clave de Pexels actualmente activa
  static String get _currentKey => _apiKeys[_keyIndex];

  /// Rota al siguiente índice de clave de Pexels en caso de límite (429)
  static void _rotateKey() {
    _keyIndex = (_keyIndex + 1) % _apiKeys.length;
    if (kDebugMode) debugPrint('Rotated Pexels key to index $_keyIndex');
  }

  /// Realiza una petición GET a Pexels con manejo de rotación de clave en caso de 429
  static Future<http.Response> _pexelsGet(Uri uri) async {
    var resp = await http.get(uri, headers: {"Authorization": _currentKey});
    if (resp.statusCode == 429) {
      // Si excede límite, rota la clave y reintenta
      _rotateKey();
      resp = await http.get(uri, headers: {"Authorization": _currentKey});
    }
    return resp;
  }

  /// Obtiene los wallpapers de tendencia desde Pexels
  static Future<List<ImageModel>> getTrendingWallpapers() async {
    final uri = Uri.parse("https://api.pexels.com/v1/curated");
    final resp = await _pexelsGet(uri);
    if (resp.statusCode != 200) {
      // En caso de error, escribir en consola y devolver lista vacía
      debugPrint('Pexels error \${resp.statusCode}: \${resp.body}');
      return [];
    }
    final data = jsonDecode(resp.body) as Map<String, dynamic>;
    final photos = (data['photos'] as List<dynamic>?) ?? [];
    // Convertir respuesta API a lista de ImageModel
    return photos
        .map((p) => ImageModel.fromAPIToApp(p as Map<String, dynamic>))
        .toList();
  }

  /// Busca wallpapers por palabra clave en Pexels
  static Future<List<ImageModel>> searchWallpapers(String query) async {
    final uri = Uri.parse(
        "https://api.pexels.com/v1/search?query=$query&per_page=30&page=1");
    final resp = await _pexelsGet(uri);
    if (resp.statusCode != 200) {
      debugPrint('Pexels error \${resp.statusCode}: \${resp.body}');
      return [];
    }
    final data = jsonDecode(resp.body) as Map<String, dynamic>;
    final photos = (data['photos'] as List<dynamic>?) ?? [];
    return photos
        .map((p) => ImageModel.fromAPIToApp(p as Map<String, dynamic>))
        .toList();
  }

  /// Genera una lista de categorías genéricas
  static Future<List<CategoryModel>> getCategoriesList() async {
    // Nombres de categorías predefinidas
    final names = [
      "Nature",
      "Cars",
      "City",
      "Animals",
      "Space",
      "Abstract",
      "Flowers",
      "Technology",
      "Minimal",
      "Street",
      "Bikes",
      "Mountains",
      "Ocean",
      "Architecture",
      "Food",
      "Art"
    ];
    final List<CategoryModel> list = [];
    final rand = Random();
    for (final name in names) {
      // Buscar imágenes para cada categoría
      final results = await searchWallpapers(name);
      if (results.isEmpty) continue;
      final img = results[rand.nextInt(min(10, results.length))];
      list.add(CategoryModel(
        categoryImgUrl: img.imageSrc,
        categoryName: name,
      ));
    }
    return list;
  }

  /// Obtiene las categorías guardadas por el usuario desde Firestore
  static Future<List<CategoryModel>> getUserCategories() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return [];
    final snap = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('categories')
        .get();
    return snap.docs.map((d) => CategoryModel.fromFirestore(d)).toList();
  }

  /// Combina categorías genéricas y las del usuario en una sola lista
  static Future<List<CategoryModel>>
      getCategoriesListWithUserCategories() async {
    final generic = await getCategoriesList();
    final userCats = await getUserCategories();
    return [...generic, ...userCats];
  }

  /// Obtiene nombres de categorías favoritas del usuario
  static Future<List<String>> _getUserFavoriteNames() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return [];
    final doc = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .get();
    final data = doc.data();
    return data == null
        ? []
        : List<String>.from(data['favoriteCategories'] ?? []);
  }

  /// Marca o desmarca una categoría como favorita en Firestore
  static Future<void> toggleFavorite(String categoryName, bool makeFav) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    final ref = FirebaseFirestore.instance.collection('users').doc(user.uid);
    if (makeFav) {
      // Añadir al array de favoritos
      await ref.set({
        'favoriteCategories': FieldValue.arrayUnion([categoryName])
      }, SetOptions(merge: true));
    } else {
      // Eliminar del array de favoritos
      await ref.set({
        'favoriteCategories': FieldValue.arrayRemove([categoryName])
      }, SetOptions(merge: true));
    }
  }

  /// Devuelve todas las categorías combinadas, marcando las favoritas primero
  static Future<List<CategoryModel>> getCategoriesWithFavorites() async {
    final all = await getCategoriesListWithUserCategories();
    final favNames = await _getUserFavoriteNames();
    for (var cat in all) {
      cat.isFavorite = favNames.contains(cat.categoryName);
    }
    // Ordenar: favoritas al inicio
    all.sort((a, b) => (b.isFavorite ? 1 : 0) - (a.isFavorite ? 1 : 0));
    return all;
  }

  /// Genera recomendaciones basadas en categorías favoritas del usuario
  static Future<List<ImageModel>> getRecommendedWallpapers({
    int maxResults = 30,
  }) async {
    final favNames = await _getUserFavoriteNames();
    if (favNames.isEmpty) return [];

    final List<ImageModel> results = [];
    final perCategory = (maxResults / favNames.length).ceil();
    for (final name in favNames) {
      final list = await searchWallpapers(name);
      results.addAll(list.take(perCategory));
    }

    // Eliminar duplicados por URL
    final uniqueByUrl = <String, ImageModel>{};
    for (var img in results) {
      uniqueByUrl[img.imageSrc] = img;
    }
    return uniqueByUrl.values.take(maxResults).toList();
  }

  /// Obtiene URLs de wallpapers favoritas del usuario desde Firestore
  static Future<List<String>> getUserFavoriteWallpapers() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return [];
    final doc = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .get();
    final data = doc.data();
    return data == null
        ? []
        : List<String>.from(data['favoriteWallpapers'] ?? []);
  }

  /// Marca o desmarca un wallpaper como favorito en Firestore
  static Future<void> toggleFavoriteWallpaper(
      String imageUrl, bool makeFav) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    final ref = FirebaseFirestore.instance.collection('users').doc(user.uid);
    if (makeFav) {
      await ref.set({
        'favoriteWallpapers': FieldValue.arrayUnion([imageUrl])
      }, SetOptions(merge: true));
    } else {
      await ref.set({
        'favoriteWallpapers': FieldValue.arrayRemove([imageUrl])
      }, SetOptions(merge: true));
    }
  }

  /// Genera una imagen usando Stability AI con reintentos y rotación de claves
  static Future<String> generateImageWithStabilityAI(String prompt) async {
    final int maxAttempts = _stabilityKeys.length;
    Exception? lastException;

    // Intentar con cada clave hasta éxito o agotar intentos
    for (var attempt = 0; attempt < maxAttempts; attempt++) {
      final apiKey = _currentStabilityKey;
      try {
        final uri = Uri.parse(
          "https://api.stability.ai/v2beta/stable-image/generate/sd3",
        );
        // Construir petición multipart para enviar prompt
        final req = http.MultipartRequest("POST", uri)
          ..headers["Authorization"] = "Bearer $apiKey"
          ..headers["Accept"] = "image/*"
          ..fields["prompt"] = prompt
          ..fields["output_format"] = "jpeg";

        final streamed = await req.send();
        final resp = await http.Response.fromStream(streamed);

        if (resp.statusCode == 200) {
          // Guardar imagen en archivo temporal y devolver ruta
          final bytes = resp.bodyBytes;
          final tmpPath =
              "${Directory.systemTemp.path}/stability_${DateTime.now().millisecondsSinceEpoch}.jpg";
          await File(tmpPath).writeAsBytes(bytes);
          return tmpPath;
        }

        if (resp.statusCode == 402 || resp.statusCode == 401) {
          // Clave inválida o sin crédito, rotar a la siguiente
          _rotateStabilityKey();
          lastException = Exception(
              "Stability API returned \${resp.statusCode}: \${resp.body}");
          continue;
        }

        // Otros errores: parsear mensaje si es JSON o usar cuerpo
        String msg;
        try {
          final err = jsonDecode(resp.body) as Map<String, dynamic>;
          msg = (err["errors"] as List<dynamic>).join(", ");
        } catch (_) {
          msg = resp.body;
        }
        throw Exception("Stability API error \${resp.statusCode}: \$msg");
      } catch (e) {
        // En caso de excepción, rotar clave y guardar última excepción
        lastException = Exception(e.toString());
        _rotateStabilityKey();
        continue;
      }
    }

    // Si todas las claves fallan, lanzar excepción final
    throw Exception(
        "Todas las API keys de Stability AI fallaron: ${lastException.toString()}");
  }
}
