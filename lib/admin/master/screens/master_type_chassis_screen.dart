// File: lib/admin/master/screens/master_type_chassis_screen.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/material.dart';
import '../widgets/c-chassis/type_chassis_form_card.dart';
import '../widgets/c-chassis/type_chassis_table.dart';
import '../providers/master_data_providers.dart';
import '../repository/master_data_repository.dart';
import '../widgets/recycle_bin/type_chassis_recycle_bin.dart';
import '../widgets/c-chassis/import_failed_dialog.dart';

class MasterTypeChassisScreen extends ConsumerStatefulWidget {
  const MasterTypeChassisScreen({super.key});
  @override
  ConsumerState<MasterTypeChassisScreen> createState() =>
      _MasterTypeChassisScreenState();
}

class _MasterTypeChassisScreenState
    extends ConsumerState<MasterTypeChassisScreen> {
  bool _isExporting = false;
  bool _isImporting = false;

  @override
  void initState() {
    super.initState();
    // --- RESET SEARCH & FILTER TYPE CHASSIS ---
    Future.microtask(() => ref.invalidate(typeChassisFilterProvider));
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(5.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              SizedBox(width: 10),
              const Text(
                'Manajemen Type Chassis',
                style: TextStyle(fontSize: 21, fontWeight: FontWeight.bold),
              ),
              const Spacer(),
              SizedBox(
                height: 33,
                child: OutlinedButton.icon(
                  onPressed: (_isExporting || _isImporting)
                      ? null
                      : () async {
                          setState(() => _isExporting = true);
                          try {
                            await ref
                                .read(masterDataRepositoryProvider)
                                .exportTypeChassisExcel();
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Export berhasil!'),
                                  backgroundColor: Colors.green,
                                  behavior: SnackBarBehavior.floating,
                                ),
                              );
                            }
                          } catch (e) {
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Gagal export: ${e.toString()}'),
                                  backgroundColor: Colors.red,
                                  behavior: SnackBarBehavior.floating,
                                ),
                              );
                            }
                          } finally {
                            if (mounted) setState(() => _isExporting = false);
                          }
                        },
                  icon: _isExporting
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.file_download, size: 18, color: Colors.green),
                  label: const Text(
                    'Export Excel',
                    style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Colors.green),
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              SizedBox(
                height: 33,
                child: ElevatedButton.icon(
                  onPressed: (_isExporting || _isImporting)
                      ? null
                      : () async {
                          setState(() => _isImporting = true);
                          try {
                            final result = await ref
                                .read(masterDataRepositoryProvider)
                                .importTypeChassisExcel();
                            if (result != null && context.mounted) {
                              final msg = result['message'] ?? 'Import berhasil!';
                              final failed = result['failed_rows'] as List<dynamic>? ?? [];
                              
                              if (failed.isEmpty) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(msg.toString()),
                                    backgroundColor: Colors.green,
                                    behavior: SnackBarBehavior.floating,
                                    duration: const Duration(seconds: 5),
                                  ),
                                );
                              } else {
                                // Tampilkan dialog gagal
                                showDialog(
                                  context: context,
                                  builder: (ctx) => ImportFailedDialog(
                                    failedRows: failed,
                                    message: msg.toString(),
                                  ),
                                );
                              }
                              ref.invalidate(typeChassisFilterProvider);
                            }
                          } catch (e) {
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Gagal import: ${e.toString()}'),
                                  backgroundColor: Colors.red,
                                  behavior: SnackBarBehavior.floating,
                                ),
                              );
                            }
                          } finally {
                            if (mounted) setState(() => _isImporting = false);
                          }
                        },
                  icon: _isImporting
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : const Icon(Icons.file_upload, size: 18, color: Colors.white),
                  label: const Text(
                    'Import Excel',
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green.shade700,
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              // Search Field
              SizedBox(
                width: 250,
                height: 31,
                child: TextField(
                  decoration: const InputDecoration(
                    labelStyle: TextStyle(fontSize: 14),
                    labelText: 'Search Type Chassis...',
                    prefixIcon: Icon(Icons.search),
                    isDense: true,
                    border: OutlineInputBorder(),
                  ),
                  onChanged: (value) => ref
                      .read(typeChassisFilterProvider.notifier)
                      .update((state) => {...state, 'search': value}),
                ),
              ),
              const SizedBox(width: 8),
              // Refresh Button
              IconButton(
                icon: const Icon(Icons.refresh),
                tooltip: 'Refresh Data',
                onPressed: () {
                  ref
                      .read(typeChassisFilterProvider.notifier)
                      .update((state) => Map.from(state));
                  ref
                      .read(typeChassisFilterProvider.notifier)
                      .update((state) => {...state, 'search': ''});
                },
              ),
              const SizedBox(width: 8),
              // Recycle Bin Button
              IconButton(
                icon: const Icon(Icons.delete_outline, color: Colors.orange),
                tooltip: 'Recycle Bin (Data Dihapus)',
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (_) => const TypeChassisRecycleBin(),
                  );
                },
              ),
            ],
          ),
          const SizedBox(height: 1),
          // Form Input
          const TypeChassisFormCard(),
          const SizedBox(height: 5),
          const Expanded(child: TypeChassisTable()),
        ],
      ),
    );
  }
}
