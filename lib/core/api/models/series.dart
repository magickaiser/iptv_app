/// Represents a VOD series. (Future feature)
class Series {
  final int seriesId;
  final String name;
  final int categoryId;
  final String? cover;
  final String? plot;
  final String? cast;
  final String? director;
  final String? genre;
  final String? releaseDate;
  final double? rating;

  const Series({
    required this.seriesId,
    required this.name,
    required this.categoryId,
    this.cover,
    this.plot,
    this.cast,
    this.director,
    this.genre,
    this.releaseDate,
    this.rating,
  });

  factory Series.fromJson(Map<String, dynamic> json) {
    return Series(
      seriesId: _parseInt(json['series_id']),
      name: json['name'] as String,
      categoryId: _parseInt(json['category_id']),
      cover: json['cover'] as String?,
      plot: json['plot'] as String?,
      cast: json['cast'] as String?,
      director: json['director'] as String?,
      genre: json['genre'] as String?,
      releaseDate: json['releaseDate'] as String? ?? json['release_date'] as String?,
      rating: (json['rating'] as num?)?.toDouble(),
    );
  }

  static int _parseInt(dynamic value) {
    if (value is int) return value;
    if (value is String) return int.tryParse(value) ?? 0;
    return 0;
  }
}
