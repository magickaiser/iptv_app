/// Represents a live TV channel.
class Channel {
  final int streamId;
  final String name;
  final int categoryId;
  final String? streamIcon;
  final String? epgChannelId;

  const Channel({
    required this.streamId,
    required this.name,
    required this.categoryId,
    this.streamIcon,
    this.epgChannelId,
  });

  factory Channel.fromJson(Map<String, dynamic> json) {
    return Channel(
      streamId: json['stream_id'] as int,
      name: json['name'] as String,
      categoryId: int.tryParse(json['category_id'].toString()) ?? 0,
      streamIcon: json['stream_icon'] as String?,
      epgChannelId: json['epg_channel_id'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        'stream_id': streamId,
        'name': name,
        'category_id': categoryId,
        'stream_icon': streamIcon,
        'epg_channel_id': epgChannelId,
      };

  @override
  String toString() => 'Channel($streamId: $name)';
}
