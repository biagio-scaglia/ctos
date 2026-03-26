import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/theme/ctos_theme.dart';
import 'presentation/screens/splash/splash_screen.dart';
import 'presentation/screens/main_shell.dart';

final routerProvider = Provider<Map<String, WidgetBuilder>>((ref) => {
      '/': (context) => const SplashScreen(),
      '/main': (context) => const MainShell(),
    });

class CtosApp extends ConsumerWidget {
  const CtosApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp(
      title: 'CTOS Companion',
      debugShowCheckedModeBanner: false,
      theme: CtosTheme.dark(),
      initialRoute: '/',
      routes: ref.read(routerProvider),
    );
  }
}
