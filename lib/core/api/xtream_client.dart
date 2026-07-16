import 'package:dio/dio.dart';
import 'models/channel.dart';
import 'models/category.dart';
import 'models/epg_program.dart';

/// Client for the Xtream Codes API.
/// Base URL format: http://server:port
class XtreamClient {
  final Dio _dio;
  final String _baseUrl;
  final String _username;
  final String _password;

  XtreamClient({
    required String serverUrl,
    required String username,
    required String password,
    Dio? dio,
  })  : _baseUrl = serverUrl.endsWith('/')
            ? serverUrl.substring(0, serverUrl.length - 1)
            : serverUrl,
        _username = username,
        _password = password,
        _dio = dio ??
            Dio(BaseOptions(
              connectTimeout: const Duration(seconds: 10),
              receiveTimeout: const Duration(seconds: 15),
            ));

  String get _playerApi => '$_baseUrl/player_api.php';

  Map<String, dynamic> get _authParams => {
        'username': _username,
        'password': _password,
      };

  /// Authenticate against the server.
  Future<Map<String, dynamic>> authenticate() async {
    try {
      final response = await _dio.get(_playerApi, queryParameters: _authParams);
      final data = response.data as Map<String, dynamic>;

      if (data['user_info'] == null || data['server_info'] == null) {
        throw Exception('Credenciales inválidas');
      }
      return data;
    } on DioException catch (e) {
      throw Exception('Error de conexión: ${e.message}');
    }
  }

  /// Fetch live TV categories.
  Future<List<Category>> fetchLiveCategories() async {
    final params = Map<String, dynamic>.from(_authParams)..['action'] = 'get_live_categories';
    final response = await _dio.get(_playerApi, queryParameters: params);
    final rawList = response.data is List ? response.data as List : [];
    return rawList.map((e) => Category.fromJson(e as Map<String, dynamic>)).toList();
  }

  /// Fetch live TV channels.
  Future<List<Channel>> fetchLiveChannels() async {
    final params = Map<String, dynamic>.from(_authParams)..['action'] = 'get_live_streams';
    final response = await _dio.get(_playerApi, queryParameters: params);
    final rawList = response.data is List ? response.data as List : [];
    return rawList.map((e) => Channel.fromJson(e as Map<String, dynamic>)).toList();
  }

  /// Fetch short EPG for a single stream.
  Future<List<EpgProgram>> fetchShortEpg(int streamId, {int limit = 4}) async {
    final params = Map<String, dynamic>.from(_authParams)
      ..['action'] = 'get_short_epg'
      ..['stream_id'] = streamId
      ..['limit'] = limit;

    final response = await _dio.get(_playerApi, queryParameters: params);
    final data = response.data;

    if (data is Map && data.containsKey('epg_listings')) {
      final rawList = data['epg_listings'];
      if (rawList is List) {
        return rawList.map((e) => EpgProgram.fromJson(e as Map<String, dynamic>)).toList();
      }
    }
    return [];
  }

  /// Build the stream URL for a given stream ID.
  String buildStreamUrl(int streamId, {String extension = '.m3u8'}) {
    return '$_baseUrl/live/$_username/$_password/$streamId$extension';
  }

  /// Fetch all EPG data via XMLTV.
  Future<String> fetchXmltv() async {
    final params = Map<String, dynamic>.from(_authParams);
    final response = await _dio.get(
      '$_baseUrl/xmltv.php',
      queryParameters: params,
      options: Options(responseType: ResponseType.plain),
    );
    return response.data.toString();
  }
}
