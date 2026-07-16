/// Represents a series episode. (Future feature)
class Episode {
  final int id;
  final int seasonNumber;
  final int episodeNumber;
  final String title;
  final String? plot;
  final Duration? duration;
  final String? containerExtension;

  const Episode({
    required this.id,
    required this.seasonNumber,
    required this.episodeNumber,
    required this.title,
    this.plot,
    this.duration,
    this.containerExtension,
  });

  factory Episode.fromJson(Map<String, dynamic> json) {
    return Episode(
      id: json['id'] is int ? json['id'] : int.tryParse(json['id'].toString()) ?? 0,
      seasonNumber: int.tryParse(json['season'].toString()) ?? json['season'] ?? 1,
      episodeNumber: int.tryParse(json['episode_num'].toString()) ?? 0,
      title: json['title'] as String? ?? '',
      plot: json['plot'] as String? ?? json['info']?['plot'] as String?,
      duration: json['duration_secs'] is int
          ? Duration(seconds: json['duration_secs'])
          : null,
      containerExtension: json['container_extension'] as String?,
    );
  }
}
