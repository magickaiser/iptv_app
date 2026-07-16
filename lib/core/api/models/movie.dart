/// Represents a VOD movie. (Future feature)
class Movie {
  final int streamId;
  final String name;
  final int categoryId;
  final String? streamIcon;
  final String? plot;
  final String? cast;
  final String? director;
  final String? genre;
  final String? releaseDate;
  final double? rating;

  const Movie({
    required this.streamId,
    required this.name,
    required this.categoryId,
    this.streamIcon,
    this.plot,
    this.cast,
    this.director,
    this.genre,
    this.releaseDate,
    this.rating,
  });

  factory Movie.fromJson(Map<String, dynamic> json) {
    return Movie(
      streamId: json['stream_id'] as int,
      name: json['name'] as String,
      categoryId: int.tryParse(json['category_id'].toString()) ?? 0,
      streamIcon: json['stream_icon'] as String?,
      plot: json['plot'] as String?,
      cast: json['cast'] as String?,
      director: json['director'] as String?,
      genre: json['genre'] as String?,
      releaseDate: json['releaseDate'] as String? ?? json['release_date'] as String?,
      rating: (json['rating'] as num?)?.toDouble(),
    );
  }
}
