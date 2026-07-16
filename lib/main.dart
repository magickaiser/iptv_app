import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:media_kit/media_kit.dart';
import 'app.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize media_kit (libmpv from media_kit_libs_android)
  MediaKit.ensureInitialized();

  // Initialize Hive for local cache.
  await Hive.initFlutter();

  runApp(
    const ProviderScope(
      child: IptvApp(),
    ),
  );
}
