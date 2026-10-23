import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'core/config/app_config.dart';
import 'app/app.dart';

Future<void> bootstrap() async {
  final config = AppConfig.fromEnvironment();

  await Supabase.initialize(
    url: config.supabaseUrl,
     publishableKey: config.supabaseAnonKey,
    debug: config.isDebug,
  );

  runApp(
    ProviderScope(
      child: SanketApp(config: config),
    ),
  );
}
