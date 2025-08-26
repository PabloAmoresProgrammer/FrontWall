import 'package:cloud_firestore/cloud_firestore.dart';

/// Modelo de datos para representar una categoría de wallpapers
class CategoryModel {
  /// Nombre de la categoría
  final String categoryName;

  /// URL de la imagen representativa de la categoría
  final String categoryImgUrl;

  /// ID del documento en Firestore (opcional)
  final String? docId;

  /// Indicador de si la categoría está marcada como favorita por el usuario
  bool isFavorite;

  /// Constructor principal
  /// [categoryImgUrl] y [categoryName] son obligatorios. [isFavorite] por defecto es false.
  CategoryModel({
    required this.categoryImgUrl,
    required this.categoryName,
    this.docId,
    this.isFavorite = false,
  });

  /// Fabrica una instancia de CategoryModel a partir de un JSON
  ///
  /// Espera claves:
  /// - 'categoryName': String
  /// - 'imgUrl': String
  factory CategoryModel.fromApiToApp(Map<String, dynamic> json) {
    return CategoryModel(
      categoryName: json['categoryName'] as String,
      categoryImgUrl: json['imgUrl'] as String,
      isFavorite: false, // Inicialmente no se marca como favorita
    );
  }

  /// Fabrica una instancia de CategoryModel a partir de un documento de Firestore
  ///
  /// Obtiene 'categoryName' e 'imgUrl' desde los campos del documento,
  /// y guarda el ID del documento en [docId]
  factory CategoryModel.fromFirestore(
      QueryDocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data();
    return CategoryModel(
      categoryName: data['categoryName'] as String,
      categoryImgUrl: data['imgUrl'] as String,
      docId: doc.id, // ID para operaciones futuras (actualizar, borrar)
    );
  }

  /// Convierte la instancia actual en un Map para enviar a Firestore
  ///
  /// Utilizado en operaciones de escritura (set, update)
  Map<String, dynamic> toFirestore() => {
        'categoryName': categoryName,
        'imgUrl': categoryImgUrl,
      };
}
