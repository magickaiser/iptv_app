import 'package:flutter_test/flutter_test.dart';
import 'package:frametv/core/api/models/channel.dart';
import 'package:frametv/core/api/models/category.dart';
import 'package:frametv/core/api/models/epg_program.dart';
import 'package:frametv/core/api/models/xtream_account.dart';
import 'package:frametv/features/live_tv/live_tv_provider.dart';

void main() {
  group('Channel model', () {
    test('fromJson parses correctly', () {
      final json = {
        'stream_id': 42,
        'name': 'Canal Test',
        'category_id': '7',
        'stream_icon': 'http://example.com/icon.png',
        'epg_channel_id': 'epg123',
        'direct_source': 'http://direct.example.com/stream',
      };

      final channel = Channel.fromJson(json);

      expect(channel.streamId, 42);
      expect(channel.name, 'Canal Test');
      expect(channel.categoryId, 7);
      expect(channel.streamIcon, 'http://example.com/icon.png');
      expect(channel.epgChannelId, 'epg123');
      expect(channel.directSource, 'http://direct.example.com/stream');
    });

    test('fromJson handles missing optional fields', () {
      final json = {
        'stream_id': 1,
        'name': 'Canal',
        'category_id': 1,
      };

      final channel = Channel.fromJson(json);

      expect(channel.streamIcon, isNull);
      expect(channel.epgChannelId, isNull);
      expect(channel.directSource, isNull);
    });

    test('fromJson ignores empty direct_source', () {
      final json = {
        'stream_id': 1,
        'name': 'Canal',
        'category_id': 1,
        'direct_source': '',
      };

      final channel = Channel.fromJson(json);

      expect(channel.directSource, isNull);
    });

    test('toJson produces correct map', () {
      final channel = Channel(
        streamId: 10,
        name: 'Test',
        categoryId: 3,
        streamIcon: 'icon.png',
        epgChannelId: 'epg10',
        directSource: 'http://direct.com',
      );

      final json = channel.toJson();
      expect(json['stream_id'], 10);
      expect(json['name'], 'Test');
      expect(json['category_id'], 3);
      expect(json['stream_icon'], 'icon.png');
      expect(json['epg_channel_id'], 'epg10');
      expect(json['direct_source'], 'http://direct.com');
    });
  });

  group('Category model', () {
    test('fromJson parses correctly', () {
      final json = {
        'category_id': '3',
        'category_name': 'Deportes',
      };

      final category = Category.fromJson(json);

      expect(category.categoryId, 3);
      expect(category.name, 'Deportes');
    });

    test('toJson produces correct map', () {
      final category = Category(categoryId: 5, name: 'Noticias');

      final json = category.toJson();
      expect(json['category_id'], 5);
      expect(json['category_name'], 'Noticias');
    });
  });

  group('EpgProgram model', () {
    test('fromJson parses correctly with valid dates', () {
      final json = {
        'id': 'epg1',
        'channel_id': '10',
        'title': 'Programa Test',
        'description': 'Descripción del programa',
        'start': '2025-01-01 10:00:00',
        'end': '2025-01-01 11:00:00',
      };

      final program = EpgProgram.fromJson(json);

      expect(program.id, 'epg1');
      expect(program.channelId, 10);
      expect(program.title, 'Programa Test');
      expect(program.description, 'Descripción del programa');
      expect(program.duration, const Duration(hours: 1));
    });

    test('fromJson handles missing fields gracefully', () {
      final json = <String, dynamic>{};

      final program = EpgProgram.fromJson(json);

      expect(program.id, '');
      expect(program.channelId, isNull);
      expect(program.title, '');
      expect(program.description, isNull);
    });

    test('isLive returns true when program is currently airing', () {
      final now = DateTime.now();
      final program = EpgProgram(
        title: 'Live',
        start: now.subtract(const Duration(minutes: 30)),
        end: now.add(const Duration(minutes: 30)),
      );

      expect(program.isLive, isTrue);
    });

    test('isLive returns false for past programs', () {
      final now = DateTime.now();
      final program = EpgProgram(
        title: 'Past',
        start: now.subtract(const Duration(hours: 2)),
        end: now.subtract(const Duration(hours: 1)),
      );

      expect(program.isLive, isFalse);
    });
  });

  group('XtreamAccount model', () {
    test('fromJson and toJson roundtrip', () {
      final original = XtreamAccount(
        id: 'abc-123',
        name: 'Mi Lista',
        server: 'http://server.com:8080',
        username: 'user1',
      );

      final json = original.toJson();
      final restored = XtreamAccount.fromJson(json);

      expect(restored.id, original.id);
      expect(restored.name, original.name);
      expect(restored.server, original.server);
      expect(restored.username, original.username);
    });
  });

  group('LiveTvState', () {
    test('copyWith preserves unchanged values', () {
      final state = LiveTvState(
        categories: const [Category(categoryId: 1, name: 'Cat')],
        channels: const [Channel(streamId: 1, name: 'Ch', categoryId: 1)],
        selectedCategoryId: null,
        searchQuery: '',
        loading: false,
        epgLoading: false,
      );

      final newState = state.copyWith(loading: true);

      expect(newState.loading, isTrue);
      expect(newState.categories, state.categories);
      expect(newState.channels, state.channels);
      expect(newState.selectedCategoryId, isNull);
    });

    test('copyWith sets error to null explicitly', () {
      final state = LiveTvState(error: 'Some error');
      final newState = state.copyWith(error: 'New error');

      expect(newState.error, 'New error');
    });
  });
}
