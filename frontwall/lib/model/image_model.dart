/// Modelo de datos para representar una imagen de wallpaper
class ImageModel {
  /// URL de la imagen en tamaño "portrait"
  String imageSrc;

  /// Nombre o crédito del creador/ fotógrafo de la imagen
  String imageName;

  /// Constructor principal
  /// [imageName]: nombre del fotógrafo o fuente de la imagen
  /// [imageSrc]: URL de la imagen en tamaño "portrait"
  ImageModel({
    required this.imageName,
    required this.imageSrc,
  });

  /// Fabrica una instancia de ImageModel a partir del JSON devuelto por la API de Pexels (u otra similar)
  ///
  /// Espera un mapa con al menos las claves:
  /// - 'photographer': String con el nombre del autor
  /// - 'src': Map<String, dynamic> con diferentes tamaños de imagen
  ///   - de este mapa, extrae 'portrait' para [imageSrc]
  ///
  /// Ejemplo de estructura esperada:
  /// {
  ///   "photographer": "Jane Doe",
  ///   "src": {
  ///     "original": "...",
  ///     "large2x": "...",
  ///     "large": "...",
  ///     "medium": "...",
  ///     "small": "...",
  ///     "portrait": "https://...",
  ///     "landscape": "...",
  ///     "tiny": "..."
  ///   }
  /// }
  static ImageModel fromAPIToApp(Map<String, dynamic> photoMap) {
    // Extraer el nombre del fotógrafo
    final photographer = photoMap["photographer"] as String;

    // Extraer la URL de la imagen en formato 'portrait'
    final srcMap = photoMap["src"] as Map<String, dynamic>;
    final portraitUrl = srcMap["portrait"] as String;

    return ImageModel(
      imageName: photographer,
      imageSrc: portraitUrl,
    );
  }
}
