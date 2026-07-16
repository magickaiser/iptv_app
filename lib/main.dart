import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:media_kit/media_kit.dart';
import 'core/storage/account_storage.dart';
import 'app.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize media_kit (libmpv from media_kit_libs_video).
  MediaKit.ensureInitialized();

  // Initialize Hive for local cache.
  await Hive.initFlutter();

  // Migrate old single-account to new multi-account storage.
  await AccountStorage.migrateIfNeeded(AccountStorage());

  runApp(
    const ProviderScope(
      child: IptvApp(),
    ),
  );
}
