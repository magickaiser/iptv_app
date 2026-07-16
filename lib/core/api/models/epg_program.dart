/// Represents a single EPG program entry.
class EpgProgram {
  final String id;
  final int? channelId;
  final String title;
  final String? description;
  final DateTime start;
  final DateTime end;

  const EpgProgram({
    this.id = '',
    this.channelId,
    required this.title,
    this.description,
    required this.start,
    required this.end,
  });

  factory EpgProgram.fromJson(Map<String, dynamic> json) {
    return EpgProgram(
      id: json['id']?.toString() ?? '',
      channelId: json['channel_id'] is int
          ? json['channel_id']
          : int.tryParse(json['channel_id']?.toString() ?? ''),
      title: json['title'] as String? ?? '',
      description: json['description'] as String?,
      start: DateTime.tryParse(json['start']?.toString() ?? '') ?? DateTime.now(),
      end: DateTime.tryParse(json['end']?.toString() ?? '') ?? DateTime.now(),
    );
  }

  Duration get duration => end.difference(start);

  bool get isLive => start.isBefore(DateTime.now()) && end.isAfter(DateTime.now());
}
