// File: lib/elements/home/widgets/skrb/skrb_history_dialog.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:master_gambar/data/models/skrb.dart';
import 'package:master_gambar/admin/master/widgets/pdf_viewer_dialog.dart';
import 'package:master_gambar/app/core/providers.dart';
import 'package:master_gambar/app/core/app_helpers.dart';
import '../../providers/skrb_providers.dart';
import '../../repository/skrb_repository.dart';

class SkrbHistoryDialog extends ConsumerStatefulWidget {
  final Skrb skrb;
  const SkrbHistoryDialog({super.key, required this.skrb});

  @override
  ConsumerState<SkrbHistoryDialog> createState() => _SkrbHistoryDialogState();
}

class _SkrbHistoryDialogState extends ConsumerState<SkrbHistoryDialog> {
  bool _isProcessing = false;
  int? _activeHistoryId;
  bool _isRefreshingStorage = false;
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.invalidate(skrbStorageInfoProvider(widget.skrb.id));
    });
  }

  @override
  Widget build(BuildContext context) {
    // Pantau skrbDetailProvider agar daftar riwayat selalu up to date saat dihapus
    final skrbAsync = ref.watch(skrbDetailProvider(widget.skrb.id));
    final isAdmin =
        (ref.watch(userRoleProvider) ?? '').toLowerCase() == 'admin';
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final colorScheme = Theme.of(context).colorScheme;

    return AlertDialog(
      title: Row(
        children: [
          const Icon(Icons.history, color: Colors.blue, size: 26),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Riwayat Dokumen SKRB (${widget.skrb.idSkrb})',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          if (isAdmin)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: isDark
                    ? Colors.purple.shade900.withAlpha(100)
                    : Colors.purple.shade50,
                border: Border.all(
                  color: isDark
                      ? Colors.purple.shade400
                      : Colors.purple.shade300,
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.admin_panel_settings,
                    size: 16,
                    color: isDark
                        ? Colors.purple.shade300
                        : Colors.purple.shade700,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'Mode Admin: Storage Inspector',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: isDark
                          ? Colors.purple.shade200
                          : Colors.purple.shade800,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
      content: SizedBox(
        width: isAdmin ? 1400 : 700,
        height: isAdmin ? 950 : 300,
        child: isAdmin
            ? Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Kiri: Daftar Riwayat SKRB normal
                  Expanded(flex: 11, child: _buildHistoryContent(skrbAsync)),
                  VerticalDivider(
                    width: 32,
                    thickness: 1,
                    color: colorScheme.outlineVariant,
                  ),
                  // Kanan: Panel Khusus Admin (Storage Inspector)
                  Expanded(flex: 10, child: _buildAdminStorageInspector()),
                ],
              )
            : _buildHistoryContent(skrbAsync),
      ),
      actions: [
        skrbAsync.maybeWhen(
          data: (skrb) {
            if (skrb.histories.isNotEmpty) {
              return TextButton.icon(
                style: TextButton.styleFrom(foregroundColor: Colors.red),
                icon: const Icon(Icons.delete_sweep),
                label: const Text('Hapus Semua dokumen History SKRB'),
                onPressed: _isProcessing ? null : () => _confirmDeleteAll(skrb),
              );
            }
            return const SizedBox.shrink();
          },
          orElse: () => const SizedBox.shrink(),
        ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Tutup'),
        ),
      ],
    );
  }

  Widget _buildHistoryContent(AsyncValue<Skrb> skrbAsync) {
    return skrbAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, _) => Center(child: Text('Error memuat riwayat: $err')),
      data: (skrb) {
        if (skrb.histories.isEmpty) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.folder_open, size: 64, color: Colors.grey),
                SizedBox(height: 12),
                Text(
                  'Belum ada file riwayat SKRB yang disatukan dan disimpan.',
                  style: TextStyle(fontSize: 15, color: Colors.grey),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          );
        }

        return ListView.separated(
          itemCount: skrb.histories.length,
          separatorBuilder: (_, __) => const Divider(height: 1),
          itemBuilder: (ctx, index) {
            final h = skrb.histories[index];
            final isLoadingThis = _isProcessing && _activeHistoryId == h.id;

            return ListTile(
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 8,
              ),
              leading: const Icon(
                Icons.picture_as_pdf,
                color: Colors.red,
                size: 32,
              ),
              title: Text(
                h.fileName,
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
              subtitle: Text(
                'Ukuran: ${formatFileSize(h.fileSize)}   |   Waktu: ${formatDateTime(h.createdAt)}',
                style: TextStyle(
                  fontSize: 12,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (isLoadingThis)
                    const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  else ...[
                    // Preview
                    IconButton(
                      icon: const Icon(Icons.visibility, color: Colors.blue),
                      tooltip: 'Preview PDF',
                      onPressed: () => _handlePreview(h),
                    ),
                    // Download
                    IconButton(
                      icon: const Icon(
                        Icons.download_rounded,
                        color: Colors.green,
                      ),
                      tooltip: 'Unduh File Ini',
                      onPressed: () => _handleDownload(h),
                    ),
                    // Hapus Single
                    IconButton(
                      icon: const Icon(Icons.delete_outline, color: Colors.red),
                      tooltip: 'Hapus dari Server',
                      onPressed: () => _handleDeleteSingle(h),
                    ),
                  ],
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildAdminStorageInspector() {
    final storageInfoAsync = ref.watch(skrbStorageInfoProvider(widget.skrb.id));
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final colorScheme = Theme.of(context).colorScheme;
    final isRefreshing =
        _isRefreshingStorage ||
        storageInfoAsync.isLoading ||
        storageInfoAsync.isRefreshing;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Icon(
                  Icons.folder_shared_rounded,
                  color: isDark
                      ? Colors.indigo.shade300
                      : Colors.indigo.shade700,
                  size: 22,
                ),
                const SizedBox(width: 8),
                Text(
                  'Inspeksi Direktori Server',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                    color: isDark
                        ? Colors.indigo.shade200
                        : Colors.indigo.shade900,
                  ),
                ),
              ],
            ),
            isRefreshing
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : IconButton(
                    icon: Icon(
                      Icons.refresh,
                      size: 20,
                      color: colorScheme.onSurfaceVariant,
                    ),
                    tooltip: 'Refresh Info Storage',
                    onPressed: () async {
                      setState(() => _isRefreshingStorage = true);
                      try {
                        final _ = await ref.refresh(
                          skrbStorageInfoProvider(widget.skrb.id).future,
                        );
                      } catch (_) {
                      } finally {
                        if (mounted) {
                          setState(() => _isRefreshingStorage = false);
                        }
                      }
                    },
                    constraints: const BoxConstraints(),
                    padding: const EdgeInsets.all(4),
                  ),
          ],
        ),
        const SizedBox(height: 10),
        Expanded(
          child: storageInfoAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (err, _) => Center(
              child: Text(
                'Gagal memuat info storage: $err',
                style: const TextStyle(color: Colors.red, fontSize: 13),
              ),
            ),
            data: (info) {
              final folder = info['folder'] ?? '-';
              final rootFiles = (info['root_files'] as List?) ?? [];
              // final guFiles = (info['gambar_utama_files'] as List?) ?? [];
              final savedFiles = (info['saved_files'] as List?) ?? [];
              final totalBytes = (info['total_bytes'] ?? 0);

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: isDark
                          ? Colors.indigo.shade900.withAlpha(120)
                          : Colors.indigo.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: isDark
                            ? Colors.indigo.shade700
                            : Colors.indigo.shade200,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'TOTAL PENYIMPANAN FOLDER SKRB',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: isDark
                                    ? Colors.indigo.shade200
                                    : Colors.indigo.shade800,
                              ),
                            ),
                            Text(
                              'Folder: $folder',
                              style: TextStyle(
                                fontSize: 11,
                                fontStyle: FontStyle.italic,
                                color: isDark
                                    ? Colors.indigo.shade300
                                    : Colors.indigo.shade700,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.baseline,
                          textBaseline: TextBaseline.alphabetic,
                          children: [
                            Text(
                              formatFileSize(totalBytes),
                              style: TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                                color: isDark
                                    ? Colors.white
                                    : Colors.indigo.shade900,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              '($totalBytes Bytes)',
                              style: TextStyle(
                                fontSize: 12,
                                color: isDark
                                    ? Colors.indigo.shade300
                                    : Colors.indigo.shade600,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  Expanded(
                    child: ListView(
                      children: [
                        // _buildStorageSection(
                        //   title: 'Folder: gambar_utama',
                        //   subtitle: 'File Gambar Utama',
                        //   icon: Icons.image_outlined,
                        //   iconColor: Colors.amber.shade800,
                        //   files: guFiles,
                        // ),
                        // const SizedBox(height: 10),
                        _buildStorageSection(
                          title: 'Folder: saved (History SKRB)',
                          subtitle: 'Arsip merger PDF yang telah disimpan',
                          icon: Icons.history_edu_outlined,
                          iconColor: Colors.blue.shade700,
                          files: savedFiles,
                        ),
                        const SizedBox(height: 10),
                        _buildStorageSection(
                          title: 'Dokumen Root (Sistem & Opsional)',
                          subtitle: 'Surat Permohonan & Dokumen Lainnya',
                          icon: Icons.description_outlined,
                          iconColor: Colors.teal.shade700,
                          files: rootFiles,
                        ),
                      ],
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildStorageSection({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color iconColor,
    required List files,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final colorScheme = Theme.of(context).colorScheme;
    num totalSectionBytes = 0;
    for (var f in files) {
      if (f is Map) {
        if (f['size_bytes'] != null && f['size_bytes'] is num) {
          totalSectionBytes += (f['size_bytes'] as num);
        } else if (f['size_kb'] != null && f['size_kb'] is num) {
          totalSectionBytes += (f['size_kb'] as num) * 1024;
        }
      }
    }

    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: colorScheme.outlineVariant),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: isDark
                  ? colorScheme.surfaceContainerHighest
                  : Colors.grey.shade100,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(7),
              ),
            ),
            child: Row(
              children: [
                Icon(icon, size: 20, color: iconColor),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                          color: colorScheme.onSurface,
                        ),
                      ),
                      Text(
                        subtitle,
                        style: TextStyle(
                          fontSize: 11,
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: isDark ? colorScheme.surface : Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: colorScheme.outlineVariant),
                  ),
                  child: Text(
                    '${files.length} File | ${formatFileSize(totalSectionBytes)}',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: colorScheme.onSurface,
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (files.isEmpty)
            Padding(
              padding: const EdgeInsets.all(12),
              child: Center(
                child: Text(
                  'Belum ada file di direktori ini',
                  style: TextStyle(
                    fontSize: 12,
                    fontStyle: FontStyle.italic,
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: files.length,
              separatorBuilder: (_, __) =>
                  Divider(height: 1, color: colorScheme.outlineVariant),
              itemBuilder: (context, idx) {
                final file = files[idx] as Map;
                final name = file['name'] ?? '-';
                final bytes =
                    file['size_bytes'] ??
                    ((file['size_kb'] ?? 0) is num
                        ? (file['size_kb'] as num) * 1024
                        : 0);
                return Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.picture_as_pdf,
                        size: 16,
                        color: Colors.red,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          name,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: colorScheme.onSurface,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Text(
                        formatFileSize(bytes),
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
        ],
      ),
    );
  }

  Future<void> _handlePreview(SkrbHistoryItem history) async {
    setState(() {
      _isProcessing = true;
      _activeHistoryId = history.id;
    });

    try {
      final repo = ref.read(skrbRepositoryProvider);
      final url = repo.getHistoryViewUrl(history.id);
      final bytes = await repo.getPdfBytes(url);

      if (mounted) {
        showDialog(
          context: context,
          builder: (_) => PdfViewerDialog(
            pdfData: bytes,
            title: 'Preview Arsip: ${history.fileName}',
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Gagal membuka preview: $e')));
      }
    } finally {
      if (mounted) {
        setState(() {
          _isProcessing = false;
          _activeHistoryId = null;
        });
      }
    }
  }

  Future<void> _handleDownload(SkrbHistoryItem history) async {
    setState(() {
      _isProcessing = true;
      _activeHistoryId = history.id;
    });

    try {
      await ref
          .read(skrbRepositoryProvider)
          .downloadHistory(history.id, history.fileName);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('File riwayat berhasil diunduh.'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Gagal mengunduh: $e')));
      }
    } finally {
      if (mounted) {
        setState(() {
          _isProcessing = false;
          _activeHistoryId = null;
        });
      }
    }
  }

  Future<void> _handleDeleteSingle(SkrbHistoryItem history) async {
    setState(() {
      _isProcessing = true;
      _activeHistoryId = history.id;
    });

    try {
      await ref.read(skrbRepositoryProvider).deleteHistory(history.id);
      final _ = await ref.refresh(skrbDetailProvider(widget.skrb.id).future);
      ref.invalidate(skrbListProvider);
      ref.invalidate(skrbStorageInfoProvider(widget.skrb.id));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('File riwayat telah dihapus.')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    } finally {
      if (mounted) {
        setState(() {
          _isProcessing = false;
          _activeHistoryId = null;
        });
      }
    }
  }

  void _confirmDeleteAll(Skrb skrb) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Konfirmasi Bersihkan Semua Riwayat'),
        content: const Text(
          'Apakah Anda yakin ingin menghapus seluruh file merger PDF riwayat yang tersimpan di server untuk SKRB ini?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              Navigator.of(ctx).pop();
              try {
                await ref
                    .read(skrbRepositoryProvider)
                    .deleteAllHistories(skrb.id);
                final _ = await ref.refresh(
                  skrbDetailProvider(widget.skrb.id).future,
                );
                ref.invalidate(skrbListProvider);
                ref.invalidate(skrbStorageInfoProvider(widget.skrb.id));
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Seluruh riwayat berhasil dihapus.'),
                    ),
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(
                    context,
                  ).showSnackBar(SnackBar(content: Text('Error: $e')));
                }
              }
            },
            child: const Text(
              'Hapus Semua',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}
