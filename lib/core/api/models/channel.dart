/// Represents a live TV channel.
class Channel {
  final int streamId;
  final String name;
  final int categoryId;
  final String? streamIcon;
  final String? epgChannelId;
  final String? directSource;

  const Channel({
    required this.streamId,
    required this.name,
    required this.categoryId,
    this.streamIcon,
    this.epgChannelId,
    this.directSource,
  });

  factory Channel.fromJson(Map<String, dynamic> json) {
    final rawDirect = json['direct_source'];
    return Channel(
      streamId: _parseInt(json['stream_id']),
      name: json['name'] as String,
      categoryId: _parseInt(json['category_id']),
      streamIcon: json['stream_icon'] as String?,
      epgChannelId: json['epg_channel_id'] as String?,
      directSource: (rawDirect is String && rawDirect.isNotEmpty) ? rawDirect : null,
    );
  }

  static int _parseInt(dynamic value) {
    if (value is int) return value;
    if (value is String) return int.tryParse(value) ?? 0;
    return 0;
  }

  Map<String, dynamic> toJson() => {
        'stream_id': streamId,
        'name': name,
        'category_id': categoryId,
        'stream_icon': streamIcon,
        'epg_channel_id': epgChannelId,
        'direct_source': directSource,
      };

  @override
  String toString() => 'Channel($streamId: $name)';
}
