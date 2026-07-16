import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:media_kit/media_kit.dart';
import 'app.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize media_kit for video playback.
  MediaKit.ensureInitialized();

  // Initialize Hive for local cache.
  await Hive.initFlutter();

  runApp(
    const ProviderScope(
      child: IptvApp(),
    ),
  );
}
