import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'features/auth/login_screen.dart';
import 'features/tasks/task_list_screen.dart';

// ✅ ANA RENK TEMA PROVIDER
final themeColorProvider = StateProvider<Color>((ref) => Colors.indigo);
final themeModeProvider = StateProvider<ThemeMode>((ref) => ThemeMode.light);

class SmartDayApp extends ConsumerWidget {
  const SmartDayApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);
    final themeColor = ref.watch(themeColorProvider);
    final isLoggedIn = ref.watch(authProvider);

    return MaterialApp(
      title: 'SmartDay',
      debugShowCheckedModeBanner: false,
      themeMode: themeMode,
      theme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: themeColor,
        brightness: Brightness.light,
      ),
      darkTheme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: themeColor,
        brightness: Brightness.dark,
      ),
      home: isLoggedIn ? const TaskListScreen() : const LoginScreen(),
    );
  }
}
