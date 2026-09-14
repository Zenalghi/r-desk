// File: lib/elements/auth/presentation/screens/login_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../app/core/providers.dart';
import '../../home/home_screen.dart';
import 'auth_provider.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Otomatis buka dialog konfigurasi server jika dibuka pertama kali di GitHub Pages
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final prefs = await SharedPreferences.getInstance();
      final hasSavedUrl = prefs.getString('custom_base_url') != null;
      if (kIsWeb &&
          Uri.base.host.contains('github.io') &&
          !hasSavedUrl &&
          mounted) {
        _showServerConfigDialog(isFirstTimeGitHub: true);
      }
    });
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _submitLogin() {
    if (_formKey.currentState!.validate()) {
      ref
          .read(authNotifierProvider.notifier)
          .login(_usernameController.text, _passwordController.text, ref);
    }
  }

  // Helper untuk membersihkan dan memformat URL
  static String _formatBaseUrl(String input) {
    String url = input.trim();
    if (url.isEmpty) return url;
    if (!url.startsWith('http://') && !url.startsWith('https://')) {
      url = 'http://$url';
    }
    // Hapus trailing slash
    while (url.endsWith('/')) {
      url = url.substring(0, url.length - 1);
    }
    if (!url.endsWith('/api')) {
      url = '$url/api';
    }
    return url;
  }

  // Dialog Konfigurasi Koneksi Server
  void _showServerConfigDialog({bool isFirstTimeGitHub = false}) {
    final currentUrl = ref.read(baseUrlProvider);
    final urlController = TextEditingController(text: currentUrl);
    bool isTesting = false;
    String? testMessage;
    bool? testSuccess;

    showDialog(
      context: context,
      barrierDismissible: !isFirstTimeGitHub,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (dialogContext, setDialogState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              title: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Theme.of(
                        ctx,
                      ).colorScheme.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Icons.dns_rounded,
                      color: Theme.of(ctx).colorScheme.primary,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      'Koneksi ke Server',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              content: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 440),
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (isFirstTimeGitHub) ...[
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.blue.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: Colors.blue.withValues(alpha: 0.3),
                            ),
                          ),
                          child: const Row(
                            children: [
                              Icon(
                                Icons.info_outline,
                                color: Colors.blue,
                                size: 20,
                              ),
                              SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  'Aplikasi dibuka dari GitHub Pages. Tentukan alamat IP/Host backend Laravel Anda terlebih dahulu.',
                                  style: TextStyle(fontSize: 12),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],

                      const Text(
                        'Pilihan Cepat (Presets):',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 6,
                        children: [
                          ActionChip(
                            avatar: const Icon(
                              Icons.developer_mode_rounded,
                              size: 16,
                            ),
                            label: const Text('Laragon (.test)'),
                            onPressed: () {
                              setDialogState(() {
                                urlController.text =
                                    'http://master-gambar.test/api';
                                testMessage = null;
                                testSuccess = null;
                              });
                            },
                          ),
                          ActionChip(
                            avatar: const Icon(
                              Icons.home_work_outlined,
                              size: 16,
                            ),
                            label: const Text('LAN (192.168.100.111)'),
                            onPressed: () {
                              setDialogState(() {
                                urlController.text =
                                    'http://192.168.100.111/api';
                                testMessage = null;
                                testSuccess = null;
                              });
                            },
                          ),
                          ActionChip(
                            avatar: const Icon(
                              Icons.vpn_lock_outlined,
                              size: 16,
                            ),
                            label: const Text('Tailscale (100.116.54.6)'),
                            onPressed: () {
                              setDialogState(() {
                                urlController.text = 'http://100.116.54.6/api';
                                testMessage = null;
                                testSuccess = null;
                              });
                            },
                          ),
                          if (kIsWeb && !Uri.base.host.contains('github.io'))
                            ActionChip(
                              avatar: const Icon(
                                Icons.auto_mode_rounded,
                                size: 16,
                              ),
                              label: const Text('Otomatis Browser'),
                              onPressed: () {
                                setDialogState(() {
                                  urlController.text = '${Uri.base.origin}/api';
                                  testMessage = null;
                                  testSuccess = null;
                                });
                              },
                            ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      TextField(
                        controller: urlController,
                        decoration: InputDecoration(
                          labelText: 'Alamat API Backend',
                          hintText: 'http://192.168.100.111/api',
                          prefixIcon: const Icon(Icons.link_rounded),
                          suffixIcon: IconButton(
                            icon: const Icon(Icons.clear, size: 18),
                            onPressed: () => setDialogState(() {
                              urlController.clear();
                              testMessage = null;
                              testSuccess = null;
                            }),
                          ),
                          border: const OutlineInputBorder(),
                          helperText:
                              'Contoh: http://192.168.100.111/api atau http://100.116.54.6/api',
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Baris Tombol Uji Koneksi & Indikator Hasil
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          OutlinedButton.icon(
                            icon: isTesting
                                ? const SizedBox(
                                    width: 14,
                                    height: 14,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  )
                                : const Icon(
                                    Icons.network_check_rounded,
                                    size: 18,
                                  ),
                            label: const Text('Uji Koneksi'),
                            onPressed: isTesting
                                ? null
                                : () async {
                                    final formatted = _formatBaseUrl(
                                      urlController.text,
                                    );
                                    if (formatted.isEmpty) return;

                                    setDialogState(() {
                                      isTesting = true;
                                      testMessage = null;
                                      testSuccess = null;
                                    });

                                    try {
                                      final dio = Dio(
                                        BaseOptions(
                                          connectTimeout: const Duration(
                                            seconds: 4,
                                          ),
                                          receiveTimeout: const Duration(
                                            seconds: 4,
                                          ),
                                        ),
                                      );

                                      // Cek endpoint health atau base api
                                      final hostRoot = formatted.replaceAll(
                                        '/api',
                                        '',
                                      );
                                      final res = await dio.get(
                                        '$hostRoot/health',
                                      );

                                      setDialogState(() {
                                        isTesting = false;
                                        testSuccess = (res.statusCode == 200);
                                        testMessage =
                                            '✅ Server Online & Siap Digunakan!';
                                      });
                                    } catch (e) {
                                      setDialogState(() {
                                        isTesting = false;
                                        testSuccess = false;
                                        testMessage =
                                            '❌ Gagal Terhubung: Server offline atau izin jaringan ditolak.';
                                      });
                                    }
                                  },
                          ),
                          const SizedBox(width: 10),
                          if (testMessage != null)
                            Expanded(
                              child: Text(
                                testMessage!,
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: (testSuccess ?? false)
                                      ? Colors.green[700]
                                      : Colors.red[700],
                                ),
                              ),
                            ),
                        ],
                      ),

                      // Petunjuk browser jika di Web
                      if (kIsWeb) ...[
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Colors.amber.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: Colors.amber.withValues(alpha: 0.3),
                            ),
                          ),
                          child: const Text(
                            '💡 Catatan Browser: Jika muncul peringatan izin jaringan lokal (Private Network Access / Insecure Content), silakan pilih "Allow" / "Izinkan" pada pop-up atau ikon gembok browser.',
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.black87,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              actions: [
                if (!isFirstTimeGitHub)
                  TextButton(
                    onPressed: () => Navigator.pop(ctx),
                    child: const Text('Batal'),
                  ),
                ElevatedButton(
                  onPressed: () async {
                    final raw = urlController.text.trim();
                    if (raw.isEmpty) return;
                    final formatted = _formatBaseUrl(raw);

                    // Simpan ke SharedPreferences
                    final prefs = await SharedPreferences.getInstance();
                    await prefs.setString('custom_base_url', formatted);

                    // Update Provider secara dinamis
                    ref.read(baseUrlProvider.notifier).state = formatted;

                    if (!ctx.mounted) return;
                    Navigator.pop(ctx);

                    if (!mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Server aktif: $formatted'),
                        backgroundColor: Colors.green[700],
                        duration: const Duration(seconds: 3),
                      ),
                    );
                  },
                  child: const Text('Simpan & Terapkan'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authNotifierProvider);
    final versionAsync = ref.watch(packageInfoProvider);
    final currentServerUrl = ref.watch(baseUrlProvider);

    // Ambil host saja untuk ditampilkan di teks ringkas
    String serverHostDisplay = currentServerUrl
        .replaceAll('http://', '')
        .replaceAll('https://', '')
        .replaceAll('/api', '');

    ref.listen<AsyncValue<void>>(authNotifierProvider, (previous, next) {
      if (next is AsyncError) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(next.error.toString()),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
      if (next is AsyncData && previous is AsyncLoading) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const HomeScreen()),
        );
      }
    });

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          if (kIsWeb) ...[
            IconButton(
              icon: const Icon(Icons.settings_ethernet_rounded),
              tooltip: 'Pengaturan Koneksi Server',
              onPressed: () => _showServerConfigDialog(),
            ),
            const SizedBox(width: 8),
          ],
        ],
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 400),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text(
                    'Login',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 32.0),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          TextFormField(
                            controller: _usernameController,
                            autofocus: true,
                            textInputAction: TextInputAction.next,
                            decoration: const InputDecoration(
                              labelText: 'Username',
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Username tidak boleh kosong';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 16.0),
                          TextFormField(
                            controller: _passwordController,
                            obscureText: true,
                            textInputAction: TextInputAction.done,
                            onFieldSubmitted: (_) => _submitLogin(),
                            decoration: const InputDecoration(
                              labelText: 'Password',
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Password tidak boleh kosong';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 24.0),
                          authState.isLoading
                              ? const Center(child: CircularProgressIndicator())
                              : ElevatedButton(
                                  onPressed: _submitLogin,
                                  child: const Text('Login'),
                                ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16.0),

                  if (kIsWeb) ...[
                    Center(
                      child: TextButton.icon(
                        onPressed: () => _showServerConfigDialog(),
                        icon: const Icon(Icons.dns_outlined, size: 15),
                        label: Text(
                          'Server: $serverHostDisplay',
                          style: TextStyle(
                            fontSize: 12,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8.0),
                  ],
                  versionAsync.when(
                    data: (packageInfo) {
                      return Text(
                        'Versi ${packageInfo.version}',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.grey[600], fontSize: 12),
                      );
                    },
                    loading: () => const SizedBox.shrink(),
                    error: (err, stack) => const SizedBox.shrink(),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
