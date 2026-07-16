/// Represents a saved Xtream Codes account.
class XtreamAccount {
  final String id; // UUID
  final String name; // User-friendly name
  final String server;
  final String username;

  const XtreamAccount({
    required this.id,
    required this.name,
    required this.server,
    required this.username,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'server': server,
        'username': username,
      };

  factory XtreamAccount.fromJson(Map<String, dynamic> json) {
    return XtreamAccount(
      id: json['id'] as String,
      name: json['name'] as String,
      server: json['server'] as String,
      username: json['username'] as String,
    );
  }

  @override
  String toString() => 'XtreamAccount($name @ $server)';
}
