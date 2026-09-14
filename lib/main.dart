import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:window_manager/window_manager.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'app/theme/app_theme.dart';
import 'app/core/auth_wrapper.dart';
import 'package:flutter/foundation.dart'; // Import ini penting untuk kIsWeb dan kReleaseMode
import 'dart:io';
import 'dart:convert';
import 'package:path/path.dart' as path;
import 'package:shared_preferences/shared_preferences.dart';
import 'app/core/providers.dart';

// Try the provided URLs sequentially and return the first one that is reachable.
Future<String?> _pickWorkingUrl(
  List<String> urls, {
  int timeoutMs = 3000,
}) async {
  final client = HttpClient();
  final timeout = Duration(milliseconds: timeoutMs);
  for (final u in urls) {
    try {
      final uri = Uri.parse(u);
      final request = await client.getUrl(uri).timeout(timeout);
      final response = await request.close().timeout(timeout);
      debugPrint('Tried $u -> ${response.statusCode}');
      return u;
    } catch (e) {
      debugPrint('Failed to reach $u: $e');
      continue;
    }
  }
  return null;
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final prefs = await SharedPreferences.getInstance();
  final isDarkMode = prefs.getBool('isDarkMode') ?? false;

  // 1. Cadangan Default URL: Laragon untuk development
  const String fallbackDevUrl = 'http://master-gambar.test/api';
  String baseUrl = fallbackDevUrl;

  // 2. Cek preferensi custom_base_url dari penyimpanan pengguna jika pernah diubah manual
  final savedUrl = kIsWeb ? prefs.getString('custom_base_url') : null;

  if (savedUrl != null && savedUrl.trim().isNotEmpty) {
    baseUrl = savedUrl.trim();
    debugPrint("Menggunakan URL server dari penyimpanan: $baseUrl");
  } else if (kIsWeb) {
    // === LOGIKA KHUSUS WEB ===
    if (Uri.base.host.contains('github.io')) {
      // Default awal GitHub Pages (sebelum diisi oleh user)
      baseUrl = "http://192.168.100.111/api";
    } else if (kReleaseMode) {
      // Di Production Docker Server SOHO:
      // Menggunakan Uri.base.origin secara dinamis agar otomatis mengikuti IP/Domain browser (192.168.100.111 / 100.116.54.6)
      baseUrl = "${Uri.base.origin}/api";
    } else {
      // Saat Web Development (Debug), pakai Laragon
      baseUrl = fallbackDevUrl;
    }

    debugPrint("Running on WEB. Base URL: $baseUrl");
  } else {
    // === LOGIKA KHUSUS DESKTOP (WINDOWS) ===
    // Utama/Release: Baca config.json jika ada.
    // Cadangan/Development: Fallback ke Laragon (http://master-gambar.test/api).
    try {
      String configPath = 'config.json';

      // Ambil path executable
      final appDir = path.dirname(Platform.resolvedExecutable);
      configPath = path.join(appDir, 'config.json');

      final file = File(configPath);
      File? activeConfigFile;
      if (await file.exists()) {
        activeConfigFile = file;
      } else {
        // Cek juga di folder root project (saat debugging di VS Code/terminal)
        final localProjectConfig = File('config.json');
        if (await localProjectConfig.exists()) {
          activeConfigFile = localProjectConfig;
        }
      }

      if (activeConfigFile != null) {
        final content = await activeConfigFile.readAsString();
        final config = json.decode(content) as Map<String, dynamic>;

        List<String> urls = [];
        if (config.containsKey('baseUrls') && config['baseUrls'] is List) {
          urls = List<String>.from(config['baseUrls']);
        } else if (config.containsKey('baseUrl') &&
            config['baseUrl'] is String) {
          urls = [config['baseUrl'] as String];
        }

        if (urls.isNotEmpty) {
          int timeoutMs = 3000;
          if (config.containsKey('timeoutMs')) {
            try {
              timeoutMs = (config['timeoutMs'] is int)
                  ? config['timeoutMs'] as int
                  : int.parse('${config['timeoutMs']}');
            } catch (_) {
              debugPrint(
                'Invalid timeoutMs in config, using default $timeoutMs ms',
              );
            }
          }

          final chosen = await _pickWorkingUrl(urls, timeoutMs: timeoutMs);
          if (chosen != null) {
            baseUrl = chosen;
            debugPrint('Selected working baseUrl from config: $baseUrl');
          } else {
            debugPrint(
              'No reachable URL from config, using first entry as fallback.',
            );
            baseUrl = urls.first;
          }
        }

        debugPrint("Config loaded from ${activeConfigFile.path}");
      } else {
        // config.json tidak ditemukan (misal saat development) -> pakai Laragon
        baseUrl = fallbackDevUrl;
        debugPrint(
          "Config file tidak ditemukan, fallback ke Laragon: $baseUrl",
        );
      }
    } catch (e) {
      debugPrint("Error membaca config.json: $e");
      // Fallback jika config gagal dibaca di desktop -> pakai Laragon
      baseUrl = fallbackDevUrl;
    }

    // Window Manager hanya untuk Desktop
    await windowManager.ensureInitialized();

    WindowOptions windowOptions = const WindowOptions(
      size: Size(1024, 700),
      center: true,
      backgroundColor: Colors.transparent,
      skipTaskbar: false,
      titleBarStyle: TitleBarStyle.normal,
    );

    windowManager.waitUntilReadyToShow(windowOptions, () async {
      await windowManager.setMinimumSize(const Size(1024, 600));
      await windowManager.maximize();
      await windowManager.show();
      await windowManager.focus();
    });
  }

  final container = ProviderContainer();
  container.read(baseUrlProvider.notifier).state = baseUrl;
  container.read(darkModeProvider.notifier).state = isDarkMode;

  runApp(UncontrolledProviderScope(container: container, child: const MyApp()));
}

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDarkMode = ref.watch(darkModeProvider);

    return MaterialApp(
      title: 'Rekayasa Desk',
      theme: createAppTheme(darkMode: false),
      darkTheme: createAppTheme(darkMode: true),
      themeMode: isDarkMode ? ThemeMode.dark : ThemeMode.light,
      debugShowCheckedModeBanner: false,
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [Locale('id', 'ID'), Locale('en', 'US')],
      locale: const Locale('id', 'ID'),
      builder: (context, child) {
        final mediaQueryData = MediaQuery.of(context);
        return MediaQuery(
          data: mediaQueryData.copyWith(
            // textScaler: const TextScaler.linear(0.90),
          ),
          child: child!,
        );
      },
      home: const AuthWrapper(),
    );
  }
}
